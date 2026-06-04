#!/usr/bin/env bash
# ============================================================
#  sync-pull.sh — SessionStart 훅
#  세션 시작 시 메모리 저장소를 당겨와 "다른 PC가 올린 기억"을 받는다.
#  fail-soft: 네트워크 없거나 충돌해도 조용히 (작업 흐름 방해 X).
#  exit 0 항상.
# ============================================================
cat >/dev/null 2>&1   # Claude Code가 보내는 hook JSON 소진

STORE="${CLAUDE_MEMORY_STORE:-$HOME/.claude-memory}"
[ -d "$STORE/.git" ] || exit 0
cd "$STORE" || exit 0
git remote get-url origin >/dev/null 2>&1 || exit 0

# 로컬 미커밋 변경 있으면 stash 후 pull, 이후 pop (충돌 방어)
STASHED=0
if ! git diff --quiet || ! git diff --cached --quiet; then
  git stash push -q -m "auto-stash-before-pull" >/dev/null 2>&1 && STASHED=1
fi

if git pull --rebase --quiet >/dev/null 2>&1; then
  echo "[claude-memory] 기억 동기화됨 (pull ok)" >&2
else
  # 충돌로 실패 → 조용히 넘기지 않고 경고 (#3: 원격 기억을 못 받았음을 알림)
  git rebase --abort >/dev/null 2>&1 || true
  echo "[claude-memory] ⚠️ 동기화 충돌 — 다른 PC 기억을 자동 병합하지 못했습니다." >&2
  echo "[claude-memory]    수동 확인: cd \"$STORE\" && git pull --rebase" >&2
fi

[ "$STASHED" -eq 1 ] && git stash pop -q >/dev/null 2>&1 || true
exit 0
