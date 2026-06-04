---
description: 지금까지 한 작업을 요약해서 내 메모리 저장소에 저장 (세션이 끝나도 남음)
argument-hint: [선택: 제목이나 강조할 내용]
allowed-tools: Bash, Write, Read
---

너는 지금 `claude-memory` 플러그인의 **저장(remember)** 동작을 수행한다.
규약은 `skills/memory/SKILL.md` 를 따른다. 핵심만 다시 적으면:

## 할 일

1. **프로젝트 판별**: 현재 작업 디렉터리(`pwd`)의 basename 을 `<project>` 로 사용.
2. **이번 세션 요약**: 지금까지 사용자와 한 작업 중 *의미있는 것*을 요약한다.
   - ⚠️ 대화 날것을 복붙하지 말 것. **핵심만 요약** (이게 내장 resume과의 차별점).
   - 사용자가 인자(`$ARGUMENTS`)로 제목/강조점을 줬으면 반영.
3. **저장 경로 보장**: `~/.claude-memory/<project>/` 폴더가 없으면 `mkdir -p` 로 생성.
4. **파일 작성**: `~/.claude-memory/<project>/<YYYYMMDD-HHmm>-<짧은제목>.md` 로 아래 형식 저장.

```markdown
# <제목>

- **date**: <YYYY-MM-DD HH:mm>
- **project**: <project>
- **summary**: <한 줄 요약>
- **keywords**: [최소 3개, 한/영 음차 포함]
- **next**: <다음에 할 일 1~3줄>

## 한 일
- ...

## 결정/맥락
- ...
```

5. **동기화 시도**: 플러그인의 `scripts/sync-push.sh` 를 실행해 백업한다.
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/sync-push.sh"
   ```
   - 이 스크립트는 store가 git repo이고 remote가 있을 때만 commit+push (멱등·fail-soft).
   - 아직 연결 안 됐으면 조용히 넘어가므로, 그 경우 끝에 한 줄로
     "💡 `/claude-memory:setup` 하면 다른 PC에서도 이어집니다" 안내.
6. **보고**: 저장한 파일 경로 + summary + next 를 사용자에게 1줄씩 보여준다.

현재 날짜·시간은 `date '+%Y-%m-%d %H:%M'` 로 실제 확인한다.
