# 🧠 claude-memory — Cross-PC Persistent Memory for Claude Code

> Claude Code가 세션·PC를 넘어 맥락을 기억하게 하는 메모리 플러그인.
> 각 사용자는 자신의 GitHub에 연결되어, 어느 컴퓨터에서든 이어서 작업할 수 있습니다.

---

## 문제 (Why)

Claude Code(및 모든 LLM)는 **세션이 끝나면 맥락을 잃습니다.** 다음 날, 다른 PC에서 다시 켜면
"내가 뭘 하고 있었는지"부터 매번 설명해야 합니다.

내장 `claude --resume` 이 있지만:
- **단일 PC에 묶임** — 집에서 한 작업이 회사 PC에 없음
- **대화 날것 복원** — 토큰 무겁고, 핵심만 골라 못 봄

## 해결 (What)

`claude-memory` 는 **요약된 기억을 md 파일로 저장하고, git으로 PC 간 동기화**합니다.

- `/remember` — 지금까지 한 작업을 요약 1장으로 저장
- `/recall` — 관련 기억을 불러와 "어디까지 했는지" 브리핑
- `/memory-setup` — 최초 1회, **당신의 GitHub**에 전용 메모리 저장소 연결

## 설계 원칙

| 원칙 | 이유 |
|---|---|
| **md 파일 저장** | 사람·기계 둘 다 읽음, 의존성 0, git 친화, 검색 쉬움 |
| **코드 ≠ 데이터 분리** | 이 repo는 공개 코드, 기억은 각자 비공개 저장소로 |
| **각자 자기 GitHub** | 멀티유저 — 누가 설치하든 자기 데이터는 자기 계정에 |

## 작동 방식 (How)

```
세션 시작 ──▶ [hook] 내 메모리 저장소 git pull (다른 PC 기억 받기)
작업 ...
/remember ──▶ 요약 md 저장 ──▶ [hook] git push (내 GitHub 백업)
다음 날/다른 PC ──▶ /recall ──▶ 이어서 작업
```

## 설치

### 필요 조건
- [Claude Code](https://claude.com/claude-code)
- [GitHub CLI (`gh`)](https://cli.github.com/) — 로그인 상태 (`gh auth login`). PC 간 동기화에 사용.

### 설치 (Claude Code 안에서)

```text
/plugin marketplace add shimeeuisuk/claude-memory-plugin
/plugin install claude-memory
```

> 로컬에서 먼저 시험해보려면 repo 경로를 직접 등록해도 됩니다:
> `/plugin marketplace add ~/claude-memory-plugin`

## 사용법

```text
# 1. 최초 1회 — 내 GitHub에 개인 메모리 저장소 연결 (자동 생성)
/claude-memory:setup

# 2. 작업하다가 — 지금까지 한 일을 저장
/claude-memory:remember

# 3. 다음 날 / 다른 PC에서 — 이어서
/claude-memory:recall
```

| 명령어 | 하는 일 |
|---|---|
| `/claude-memory:setup` | 내 GitHub에 private 메모리 저장소 생성·연결 (최초 1회) |
| `/claude-memory:remember` | 지금까지의 작업을 요약해 저장 + 자동 백업 |
| `/claude-memory:recall` | 과거 기억을 불러와 "어디까지 했는지" 브리핑 |

세션 시작 시 자동으로 다른 PC의 기억을 받아오고(pull), 작업 후 자동 백업(push)됩니다.

## 데이터는 어디에?

- **플러그인 코드** (이 repo) — 공개. 누구나 설치 가능.
- **당신의 기억** — `~/.claude-memory/` 에 저장되고, **당신 소유의 private GitHub repo**로만 동기화됨.
  코드와 데이터는 완전히 분리되어 있어, 이 플러그인을 설치해도 당신의 기억이 외부로 새지 않습니다.

---

*Built as a study of agent memory design for Claude Code.*
