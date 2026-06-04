#!/usr/bin/env bash
# ============================================================
#  sync-push.sh — Stop 훅 (+ /remember 가 직접 호출)
#  메모리 저장소에 변경이 있으면 commit + push (자동 백업).
#  변경 없으면 즉시 종료. fail-soft: 네트워크 실패해도 조용히.
#  exit 0 항상.
# ============================================================
cat >/dev/null 2>&1   # hook JSON 소진

STORE="${CLAUDE_MEMORY_STORE:-$HOME/.claude-memory}"
[ -d "$STORE/.git" ] || exit 0
cd "$STORE" || exit 0
git remote get-url origin >/dev/null 2>&1 || exit 0

# 변경 없으면 끝
[ -z "$(git status --porcelain 2>/dev/null)" ] && exit 0

git add -A
git commit -q -m "memory: sync $(date '+%Y-%m-%d %H:%M')" >/dev/null 2>&1 || exit 0

# 1차 push 시도
if git push --quiet >/dev/null 2>&1; then
  echo "[claude-memory] 기억 백업됨 (push ok)" >&2
  exit 0
fi

# 1차 실패: 다른 PC가 먼저 올렸을 수 있음 → 병합 후 재시도 (#2 동시 작업 대응)
if git pull --rebase --quiet >/dev/null 2>&1 && git push --quiet >/dev/null 2>&1; then
  echo "[claude-memory] 기억 백업됨 (다른 PC 변경 병합 후 push ok)" >&2
  exit 0
fi

# 진짜 실패 → 조용히 넘기지 않고 시끄럽게 알림 (#1 조용한 백업 실패 방지)
git rebase --abort >/dev/null 2>&1 || true
echo "[claude-memory] ⚠️ 백업 실패 — 기억은 이 PC($STORE)에 저장됐지만 GitHub에는 아직 안 올라감." >&2
echo "[claude-memory]    네트워크 확인 후 수동 백업: cd \"$STORE\" && git push" >&2
exit 0
