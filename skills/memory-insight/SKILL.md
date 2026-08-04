---
name: memory-insight
description: claude-memory에 저장된 기억들이 프로젝트를 가로질러 어떻게 연결되는지 keyword 기반 그래프로 시각화한다. 결과는 임시 폴더에 self-contained HTML로 만들어 연다 (read-only). 사용자가 "내 기억들 어떻게 연결돼 있어", "전체 그림 보여줘", "프로젝트 간 공통 주제", "기억 그래프", "메모 지도/overview" 처럼 저장된 기억을 가로질러 보거나 탐색·이해하려 할 때면 — 명시적으로 "그래프"라고 말하지 않아도 — 이 스킬을 적극적으로 사용할 것. 단일 프로젝트를 이어서 작업하려는 평범한 recall(재개)이나 저장(remember)에는 쓰지 않는다.
---

# memory-insight — keyword 기반 기억 그래프 (ephemeral view)

## Overview

claude-memory의 기억은 프로젝트 폴더별로 격리돼 있어, 프로젝트를 가로지르는
연결(공통 주제·반복되는 결정)이 잘 안 보인다. 이 스킬은 각 일기 frontmatter의
`keywords`를 재활용해 **keyword ↔ project bipartite 그래프**를 만들어,
"어떤 keyword가 여러 프로젝트를 잇는가(bridge)"를 한눈에 보여준다.

핵심 성격을 기억할 것 — 이건 **발견(discovery) view**다. recall처럼 맥락을
대화에 주입하지 않는다. 사람이 큰 그림을 보도록 돕는 read-only 도구다.

## 언제 / 언제 안 쓰나

- **쓴다**: 저장된 기억을 *가로질러* 보려는 의도 — 연결·공통점·전체 현황·"지도".
- **안 쓴다**: 한 프로젝트를 이어서 하려는 재개(→ recall), 새 기억 저장(→ remember /
  auto-memory). 헷갈리면 보류한다. 잘못 끼어들어 그래프를 띄우면 방해가 된다.

## Workflow

deterministic한 생성은 모델이 아니라 **build script**가 한다. 모델은 실행하고,
열고, 결과를 한 줄로 풀어주는 역할만 한다.

1. **그래프 생성** — 스크립트를 실행하고 마지막 줄의 `OUTPUT=<경로>`를 받는다.
   ```bash
   python3 "${CLAUDE_PLUGIN_ROOT}/skills/memory-insight/scripts/build-graph.py"
   ```
   - read-only다. store(`~/.claude-memory`)를 수정·commit·push하지 않는다.
   - stderr에 `docs=.. projects=.. keywords=.. edges=.. bridges=..` 요약이 나온다.
   - 노드는 개별 문서(일기, 프로젝트별 색)이고, keyword가 문서들을 잇는다.

2. **열기** — 생성된 HTML을 연다.
   ```bash
   open "<OUTPUT 경로>"      # macOS
   ```
   - macOS가 아니면 경로를 그대로 알려주고 브라우저로 열게 안내한다.

3. **보고** — 사용자에게 한 줄로 풀어준다: 프로젝트/​keyword 수,
   그리고 **프로젝트를 잇는 주요 keyword(bridge)** 몇 개. bridge가 0이면
   "아직 프로젝트 간 공통 keyword가 없다(기억이 더 쌓이면 보인다)"고 알린다.

## 동작·전제

- **전제**: `python3`(stdlib만 사용, 추가 설치 불필요), 그리고 기억이 쌓인
  `~/.claude-memory`. 비어 있으면 그래프는 empty 상태로 뜬다.
- **프라이버시**: HTML은 self-contained다. 렌더링 라이브러리(cytoscape)만
  CDN에서 오고, **기억 데이터(노드·엣지)는 HTML 안에 inline**으로만 들어가
  네트워크로 나가지 않는다.
- **수명**: 결과는 OS 임시 폴더에 생성되는 일회성 산출물이다. store/sync와 무관.
- **정규화**: keyword는 읽을 때만 정리한다(lowercase·trim, `한글(english)`는
  둘로 분리해 연결을 넓힌다). 저장 포맷·write path는 건드리지 않는다.

## 더 보기

- 그래프 데이터 생성 로직: `scripts/build-graph.py`
- HTML 셸(디자인·접근성): `assets/template.html`
