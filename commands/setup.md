---
description: 최초 1회 — 내 메모리 저장소를 내 GitHub에 연결해 PC 간 동기화 켜기
allowed-tools: Bash, Read
---

너는 지금 `claude-memory` 플러그인의 **최초 설정(setup)** 을 수행한다.
목표: 사용자 본인의 GitHub에 개인 메모리 저장소를 연결해, **다른 PC에서도 기억이 이어지게** 한다.

## 할 일

1. **설정 스크립트 실행**: 플러그인의 `scripts/setup-store.sh` 를 실행한다.
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/setup-store.sh"
   ```
   - `${CLAUDE_PLUGIN_ROOT}` 가 비어있으면, 이 명령어 파일 기준 상위의 `scripts/setup-store.sh` 경로를 찾아 실행.

2. **출력 첫 줄의 `STATUS=` 표식을 읽고 분기** (스크립트는 항상 exit 0 — 에러로 취급하지 말 것):
   - `STATUS=connected` → 연결 완료. 어느 계정/어떤 repo인지 한 줄로 알리고,
     "이제 `/claude-memory:remember` 로 저장하면 자동 백업됩니다" 안내.
   - `STATUS=needs-confirmation` → 새 private repo를 만들기 전 **동의 단계**(에러 아님).
     출력의 `ACCOUNT=` / `REPO=` 를 사용자에게 보여주고 **"이 계정에 만들까요?"** 라고 물어본다.
     - ⚠️ `ACCOUNT=` 가 사용자가 의도한 계정이 맞는지 꼭 확인하게 한다 (회사/개인 계정 혼동 방지).
     - 동의하면 → `bash "${CLAUDE_PLUGIN_ROOT}/scripts/setup-store.sh" --yes` 로 재실행.
     - 거절/계정이 틀리면 → 만들지 말고, `gh auth switch` 등으로 계정을 바꾸도록 안내.
   - `STATUS=manual` → gh 미설치/미로그인. 출력의 A/B 방법을 그대로 전달하고
     `gh auth login` 또는 repo URL 직접 연결을 도와준다.

3. **확인**: 연결 후 `cd ~/.claude-memory && git remote -v` 로 origin이 사용자 본인 계정인지 확인해 보여준다.

## 주의
- 이 저장소는 **반드시 private**. 개인 작업 기억이므로 공개 금지.
- 친구·타인의 GitHub가 아니라 **현재 로그인된 사용자 본인** 계정이어야 한다 (스크립트가 보장).
- 이미 연결돼 있으면 새로 만들지 말고 기존 연결을 그대로 쓴다 (멱등).
