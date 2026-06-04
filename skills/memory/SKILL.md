---
name: memory
description: Claude Code의 세션 간 영속 메모리. 사용자가 "저장해/기억해/이어서 하자/그때 어떻게 됐지" 류로 작업을 기록하거나 과거 맥락을 회상하려 할 때 자동 적용. 기억은 ~/.claude-memory/ 에 md로 저장되고 사용자 본인 GitHub로 동기화됨.
---

# claude-memory — 영속 메모리 스킬 (핵심 규약)

이 파일은 `/remember`·`/recall` 두 명령어가 공유하는 **단일 규약**.
저장 위치·파일 형식·동작 원칙이 여기 한 곳에 정의됨.

## 데이터 저장소 (store)

- 기본 경로: **`~/.claude-memory/`** (사용자 홈, 코드 repo와 분리된 별도 git repo)
- 프로젝트별 폴더: `~/.claude-memory/<project>/`
- `<project>` 판별: 현재 작업 디렉터리(`cwd`)의 basename. 모호하면 사용자에게 1회 확인.

```
~/.claude-memory/
├── <project-A>/
│   ├── 20260604-1530-memory-plugin-design.md
│   └── 20260605-0900-github-setup.md
└── <project-B>/
    └── ...
```

> **왜 코드와 분리?** 이 플러그인 코드는 공개(이력서용), 사용자 기억은 비공개·개인 소유.
> 섞으면 안 됨. store는 각자 자기 GitHub private repo로만 동기화됨.

## 기억 파일 형식 (필수 frontmatter)

```markdown
# <제목>

- **date**: YYYY-MM-DD HH:mm
- **project**: <slug>
- **summary**: <한 줄 요약>
- **keywords**: [kw1, kw2, ... 최소 3개 — 나중에 검색용. 한/영 음차 같이]
- **next**: <다음에 할 일 1~3줄 — 재개 시 제일 중요>

## 한 일
- ...

## 결정/맥락
- ...
```

- `summary`·`keywords`·`next` 는 **회상 품질을 좌우하는 핵심 필드**. 빠뜨리지 말 것.
- `next`(다음 할 일)가 재개의 심장 — "어디까지 했고 다음은 뭐"를 여기서 복원.

## 동작 원칙

1. **저장(`/remember`)**: 지금 세션에서 *의미있게* 한 일을 요약해 위 형식으로 store에 1파일 작성.
   - 날것 대화 복붙 금지. **요약**이 핵심 (내장 resume과의 차별점).
2. **회상(`/recall`)**: store에서 관련 기억을 찾아 "개요 → 마지막 상태(next) → 더 볼 것" 순으로 브리핑.
   - 검색은 `grep` 으로 keywords/제목 매칭. 0건이면 동의어로 1회 재시도 후 사용자에게 물음.
3. **항상 사용자 본인 데이터만** 다룸. 외부로 새지 않음 (동기화는 사용자 자기 repo로만).

## 동기화 (훅이 담당 — 4단계에서 연결)

- 세션 시작: store `git pull` (다른 PC 기억 받기)
- 저장 후: store `git add/commit/push` (자기 GitHub 백업)
- store가 아직 git 연결 안 됐으면(=`/memory-setup` 전) 로컬 저장만 하고 조용히 넘어감.
