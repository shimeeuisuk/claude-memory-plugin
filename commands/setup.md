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

2. **결과 해석 후 사용자에게 보고**:
   - 성공(exit 0) → 어느 계정의 어떤 repo에 연결됐는지 한 줄로 알리고,
     "이제 `/claude-memory:remember` 로 저장하면 자동으로 백업됩니다" 안내.
   - **확인 대기(exit 3)** → 새 private repo를 만들기 전 사용자 동의를 받는 단계.
     스크립트가 출력한 repo 이름·계정을 보여주고 **"여기에 만들까요?"** 라고 물어본다.
     - 사용자가 동의하면 → `bash "${CLAUDE_PLUGIN_ROOT}/scripts/setup-store.sh" --yes` 로 재실행.
     - 거절하면 → 만들지 않고 멈춘다 (수동 연결 방법 안내).
   - 수동 안내(exit 1) → 스크립트가 출력한 A/B 방법을 사용자에게 그대로 전달하고,
     사용자가 `gh auth login` 을 할지, repo URL을 직접 줄지 물어 도와준다.

3. **확인**: 연결 후 `cd ~/.claude-memory && git remote -v` 로 origin이 사용자 본인 계정인지 확인해 보여준다.

## 주의
- 이 저장소는 **반드시 private**. 개인 작업 기억이므로 공개 금지.
- 친구·타인의 GitHub가 아니라 **현재 로그인된 사용자 본인** 계정이어야 한다 (스크립트가 보장).
- 이미 연결돼 있으면 새로 만들지 말고 기존 연결을 그대로 쓴다 (멱등).
