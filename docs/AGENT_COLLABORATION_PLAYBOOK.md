# Agent Collaboration Playbook: Claude + Codex in Houston

> **Purpose**: Houston workspace에서 여러 AI Agent를 함께 사용할 때 역할 분리, handoff, evidence 정리 원칙을 표준화한다.
> **Audience**: Claude, Codex, Gemini, Cursor, Copilot 등 Houston 규칙을 읽는 모든 에이전트 및 운영자.
> **Scope**: 실행 전략. 절대 규칙은 [`workspace/README.md`](../../README.md) 및 generated adapter (`AGENTS.md`, `CLAUDE.md`, `GEMINI.md` 등)를 따른다.

---

## 1. Core Principle

Houston의 핵심은 **"어떤 에이전트를 쓰느냐"가 아니라 "어떤 truth를 남기느냐"** 다.

에이전트를 여러 개 쓰더라도 다음은 바뀌지 않는다:
- Ticket = `tickets/`
- Status/Evidence = `tasks/CHANGESETS.md`
- Governance = `workspace/README.md`
- Agent bootstrap = generated adapter (`AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, etc.)
- Repo implementation rules = `{repo}/CLAUDE.md` 및 repo docs

> **Rule**: Agent를 섞어 써도 Source of Truth는 항상 Houston 문서 체계에 남아 있어야 한다.

---

## 2. Recommended Role Split

### Claude — Control Tower / Deep Context

Claude는 아래 작업에 가장 적합하다:
- Ticket / CS / IP 해석
- 긴 문맥 유지
- 문서 설계 및 작업 순서 정리
- 범위 통제
- 완료 조건 정의
- Evidence 누락 점검

### Codex — Execution Engine / Fast Iteration

Codex는 아래 작업에 가장 적합하다:
- 국소 코드 수정
- 테스트 작성 및 반복 실행
- lint / typecheck / build fix
- review comment 반영
- 좁은 범위 구현 자동화

### Gemini / 기타 Agent

Gemini나 다른 Agent는 보조 탐색, 대안 비교, second opinion 역할로 사용할 수 있다. 다만 Houston의 truth는 동일한 문서 체계에 반영해야 한다.

---

## 3. Default Operating Model

### Recommended Default

- **Default launcher**: `claude`
- **Selective execution override**: `codex`

즉, 기본 흐름은 다음과 같다:

```bash
houston work T-XX-100
```

필요 시 실행기만 Codex로 바꾼다:

```bash
houston work --agent codex T-XX-100
```

> **Recommendation**: Houston의 기본 agent 설정은 안정적인 주력 도구(예: Claude)로 유지하고, Codex는 구현/검증 특화 lane으로 투입한다.

---

## 4. Best Collaboration Pattern

가장 권장하는 구조는 다음과 같다:

1. **Claude가 Houston 맥락을 장악**
   - `README.md`
   - ticket
   - `tasks/CHANGESETS.md`
   - repo `CLAUDE.md`
   - repo docs
2. **Claude가 실행 단위를 좁게 정의**
3. **Codex가 해당 단위만 구현/검증**
4. **최종 evidence 정리는 Houston 기준으로 다시 반영**

### Good Example

- Claude: "CS-02 IP-03은 `auth/service.py`의 validation 분기 수정과 acceptance test green이 목표다. 다른 파일은 건드리지 말 것."
- Codex: 해당 파일 수정, 테스트 실행, 결과 보고
- Claude 또는 주 실행 주체: `CHANGESETS.md`와 ticket evidence 정리

### Why this works

- 긴 문맥은 한 agent가 책임진다
- 실행은 좁은 lane으로 분리된다
- Source of Truth가 끊기지 않는다

---

## 5. Anti-Patterns

다음 패턴은 피한다.

### Anti-Pattern A — Same-context duplication

Claude가 이미 읽은 긴 문맥을 Codex에 그대로 다시 대량 전달하는 것.

문제:
- token 중복
- 설명 비용 증가
- handoff 품질 저하

### Anti-Pattern B — Parallel edits on same file

Claude와 Codex가 같은 파일을 동시에 독립 수정하는 것.

문제:
- 충돌
- 책임 경계 불명확
- review/evidence 혼선

### Anti-Pattern C — Agent finishes but Houston is not updated

코드는 바뀌었지만 ticket / `CHANGESETS.md` / docs에 반영하지 않는 것.

문제:
- Houston 기준으로 Done이 아님
- 세션 종료 후 재개 비용 증가

---

## 6. Token-Efficient Handoff Rule

토큰 절약은 **Agent를 많이 쓰느냐**가 아니라 **컨텍스트를 몇 번 반복 주입하느냐**에 달려 있다.

### Efficient

- Claude가 큰 문맥을 한 번 읽는다
- Codex에는 실행에 필요한 최소 요약만 넘긴다
- 왕복을 짧게 유지한다

### Inefficient

- Ticket / docs / repo 구조 / 판단 근거를 매번 두 agent에 모두 복제한다
- 분석과 구현을 두 agent가 중복 수행한다

### Rule of Thumb

> **Read context once, delegate execution narrowly.**

---

## 7. Handoff Template (Claude → Codex)

Codex에 일을 넘길 때는 아래 형식을 권장한다.

```text
[Task]
Implement CS-02 IP-03 for T-XX-100.

[Goal]
Make acceptance tests pass for the validation fix.

[Scope]
- Allowed: auth/service.py, tests/acceptance/test_auth_validation.py
- Avoid: API contract changes, unrelated refactors

[Constraints]
- Follow workspace README + repo CLAUDE.md
- Do not edit source/ directly
- Keep docs/evidence assumptions unchanged unless explicitly requested

[Done when]
- Acceptance test is green
- No new failing lint/typecheck in touched scope
- Report changed files + test output summary
```

핵심은:
- 목표
- 허용 범위
- 금지 범위
- 완료 조건
을 명확히 주는 것이다.

---

## 8. Session Cleanliness Checklist

세션 종료 전, 아래를 확인한다.

- [ ] Ticket / CS / IP 상태가 최신인가?
- [ ] `tasks/CHANGESETS.md`에 evidence가 반영되었는가?
- [ ] 문서화할 지식이 `docs/` 또는 ticket에 남았는가?
- [ ] worktree에 의도하지 않은 변경이 남아있지 않은가?
- [ ] 다음 agent가 이어받아도 모호하지 않은가?

> **Rule**: "채팅에만 존재하는 운영 지식"이 남아 있으면 세션은 clean하지 않다.

---

## 9. Where to Write Down New Knowledge

새로 얻은 지식은 성격에 따라 아래 위치에 기록한다.

| Knowledge Type | Recommended Location |
|:---|:---|
| Ticket-specific decision | `tickets/T-*.md` |
| Cross-agent workflow rule | `docs/AGENT_COLLABORATION_PLAYBOOK.md` |
| Verification routine | `docs/guides/VERIFICATION_PROCESS.md` |
| Repo-specific implementation rule | `{repo}/CLAUDE.md` or repo docs |
| Houston build/adapter behavior | `README.md` or `.houston/*` source docs |

---

## 10. Practical Recommendation

Houston에서 가장 현실적인 운영 방식은 다음이다:

- **Claude** = 관제탑, 문맥 관리자, 완료 판정 보조
- **Codex** = 빠른 구현/검증 엔진
- **Houston docs** = 장기 기억 장치

즉:

> **Claude가 분석하고, Codex가 실행하고, Houston이 기억한다.**

이 구조를 지키면 agent를 섞어 써도 프로세스는 흔들리지 않는다.
