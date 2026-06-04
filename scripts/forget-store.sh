#!/usr/bin/env bash
# ============================================================
#  forget-store.sh — 기억(.md)을 로컬 + GitHub 에서 함께 삭제
#
#  핵심: 로컬만 지우면 다음 세션 pull 에서 되살아남 (GitHub 가 원본).
#        그래서 삭제는 반드시 git 에도 반영(commit+push)해야 진짜 사라진다.
#
#  사용:
#    forget-store.sh list                  → 기억 목록 출력
#    forget-store.sh remove <상대경로...>   → 지정 파일 삭제 + 동기화
#
#  항상 exit 0. 결과는 STATUS= 로 알린다.
# ============================================================
set -euo pipefail

STORE="${CLAUDE_MEMORY_STORE:-$HOME/.claude-memory}"
[ -d "$STORE" ] || { echo "STATUS=empty"; echo "[forget] 저장된 기억이 없습니다."; exit 0; }
cd "$STORE"

CMD="${1:-list}"

# --- 목록 --- (자동관리 파일 _digest/_INDEX 와 README 는 제외)
if [ "$CMD" = "list" ]; then
  echo "STATUS=list"
  find . -type f -name '*.md' -not -path './.git/*' ! -name 'README.md' ! -name '_*.md' 2>/dev/null \
    | sed 's|^\./||' | sort || true
  exit 0
fi

# --- 삭제 ---
if [ "$CMD" = "remove" ]; then
  shift
  [ "$#" -gt 0 ] || { echo "STATUS=error"; echo "[forget] 지울 파일을 지정하세요."; exit 0; }

  DELETED=0
  for f in "$@"; do
    # 안전: store 밖 경로·상위 이동(..) 차단 + 자동관리 파일(_digest/_INDEX) 보호
    case "$f" in
      /*|*..*) echo "[forget] 거부(잘못된 경로): $f"; continue ;;
      _*.md|*/_*.md) echo "[forget] 거부(자동관리 파일): $f"; continue ;;
    esac
    if [ -f "$f" ]; then
      rm -f "$f"; DELETED=$((DELETED+1)); echo "[forget] 삭제: $f"
    else
      echo "[forget] 없음(건너뜀): $f"
    fi
  done

  [ "$DELETED" -gt 0 ] || { echo "STATUS=nothing"; echo "[forget] 삭제된 파일이 없습니다."; exit 0; }

  # git 반영 — 로컬과 GitHub 양쪽에서 사라지게 (안 그러면 pull 시 되살아남)
  if [ -d .git ] && git remote get-url origin >/dev/null 2>&1; then
    git add -A
    git commit -q -m "memory: forget ${DELETED} file(s) $(date '+%Y-%m-%d %H:%M')" >/dev/null 2>&1 || true
    if git push --quiet >/dev/null 2>&1; then
      echo "[forget] ✅ 로컬 + GitHub 에서 삭제 동기화됨 (${DELETED}개)"
    else
      echo "[forget] ⚠️ 로컬은 삭제됐으나 GitHub push 실패 — 나중에: cd \"$STORE\" && git push"
    fi
  else
    echo "[forget] 로컬에서만 삭제됨 (아직 git 미연결 — /claude-memory:setup 후 동기화됨)."
  fi
  echo "STATUS=done"
  echo "[forget] 참고: git 히스토리에 남아 실수 시 복구 가능."
  exit 0
fi

echo "STATUS=unknown"
echo "[forget] 사용법: list | remove <경로...>"
exit 0
