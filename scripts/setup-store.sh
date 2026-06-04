#!/usr/bin/env bash
# ============================================================
#  setup-store.sh — 메모리 저장소를 "사용자 본인" GitHub에 연결
#
#  핵심: 우리는 사용자 계정을 미리 모른다. 그래서 설치한 사람의
#        gh(GitHub CLI) 로그인 정보를 이용해 그 사람 계정에
#        private repo 를 즉석에서 생성·연결한다. (= 각자 자기 깃헙)
#
#  멱등(idempotent): 여러 번 실행해도 안전. 이미 연결돼 있으면 알림만.
#  exit 0 = 성공/이미됨, exit 1 = 수동 연결 필요(안내 출력)
# ============================================================
set -euo pipefail

STORE="${CLAUDE_MEMORY_STORE:-$HOME/.claude-memory}"
REPO_NAME="${CLAUDE_MEMORY_REPO:-claude-memory}"

# 1. 저장소 폴더 + git init
mkdir -p "$STORE"
cd "$STORE"
if [ ! -d .git ]; then
  git init -q
  git branch -M main 2>/dev/null || true   # #5 브랜치 이름 main 으로 고정 (master/main 엇갈림 방지)
  echo "[setup] git 저장소 초기화: $STORE (branch: main)"
fi

# 최소 파일 보장 (빈 repo push 방지)
[ -f README.md ] || printf '# My Claude Memory (private)\n\n개인 작업 기억 저장소. claude-memory 플러그인이 동기화함.\n' > README.md
[ -f .gitignore ] || printf '.DS_Store\n' > .gitignore

# 2. 이미 연결돼 있으면 멈춤 (멱등)
if git remote get-url origin >/dev/null 2>&1; then
  echo "[setup] 이미 연결됨 → $(git remote get-url origin)"
  echo "[setup] 다른 PC라면 'git pull' 로 기존 기억을 받아올 수 있음."
  exit 0
fi

# 3. gh CLI 로 그 사람 계정에 private repo 생성·연결·push
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  USER_LOGIN="$(gh api user --jq .login 2>/dev/null || echo '?')"

  # repo 생성 전 확인 (--yes 또는 CLAUDE_MEMORY_YES=1 이면 건너뜀)
  if [ "${1:-}" != "--yes" ] && [ "${CLAUDE_MEMORY_YES:-}" != "1" ]; then
    if ! gh repo view "$USER_LOGIN/$REPO_NAME" >/dev/null 2>&1; then
      echo "[setup] '$USER_LOGIN' 계정에 private repo '$REPO_NAME' 를 새로 만들려고 합니다."
      echo "[setup] 동의하면 다시 실행: bash setup-store.sh --yes   (또는 setup 명령에 동의 전달)"
      echo "[setup] 이미 있는 repo에 연결만 하려면 먼저 GitHub에서 '$REPO_NAME' 를 만들어 두세요."
      exit 3   # exit 3 = 사용자 확인 대기
    fi
  fi

  git add -A
  git commit -q -m "init: claude memory store" || true
  # 이미 같은 이름 repo 있으면 새로 만들지 않고 그것에 연결
  if gh repo view "$USER_LOGIN/$REPO_NAME" >/dev/null 2>&1; then
    git remote add origin "$(gh repo view "$USER_LOGIN/$REPO_NAME" --json sshUrl --jq .sshUrl)"
    git branch -M main
    git pull --rebase origin main 2>/dev/null || true
    git push -u origin main -q
    echo "[setup] ✅ 기존 repo '$USER_LOGIN/$REPO_NAME' 에 연결 완료 (다른 PC와 공유됨)"
  else
    gh repo create "$REPO_NAME" --private --source=. --remote=origin --push
    echo "[setup] ✅ '$USER_LOGIN' 계정에 private repo '$REPO_NAME' 생성 + 연결 완료"
  fi
  exit 0
fi

# 4. gh 없으면 수동 연결 안내 (fail-soft)
cat <<EOF
[setup] GitHub CLI(gh) 미설치 또는 미로그인 → 수동 연결이 필요합니다.

  방법 A) gh 설치 후 자동:
     brew install gh && gh auth login
     그 다음 이 명령을 다시 실행

  방법 B) 직접 연결:
     1) GitHub 에서 빈 'private' repo '$REPO_NAME' 생성
     2) 아래 실행:
        cd "$STORE"
        git add -A && git commit -m "init: claude memory store"
        git branch -M main
        git remote add origin <복사한-repo-URL>
        git push -u origin main
EOF
exit 1
