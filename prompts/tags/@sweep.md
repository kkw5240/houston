# @sweep — ADHD-ready Sweep / 다건 반복 작업 Template

> `@adhd` 는 본 태그의 alias (별도 파일 없음).

큰 **반복 작업**(다건 CVE/보안 sweep, lint sweep, 일괄 마이그레이션, 다건 cleanup, audit 후속 일괄수정)에 사용.
§4 Implementation Plan 을 작은 **quest 단위**로 미리 분할해 작성한다(ADHD-ready). 실행은 `/houston-adhd-mode`
명시 발동 — **작성 ≠ 실행**. 상세: RFC-HOU-TICKET-ADHD-001.

> **언제 쓰나**: type/keyword ∈ {sweep, audit, multi-CVE, bulk/다건 migration, lint sweep, 다건 cleanup,
> dependency bump 다건, TechDebt sweep} 또는 요청문구 "반복/다건/일괄/전수". 단일 hotfix · RFC/사고형 plan ·
> 단건 bug-fix 는 대상 아님(@hotfix / @bug-fix / 일반 사용).

## Required Sections

- **Summary**: 반복 단위의 정체 + 규모(예상 quest 수) + 공통 패턴.
- **Metadata**: `| **Execution Mode** | ⚡ ADHD-ready |` 행 추가 (ticket-level existence flag).
- **Implementation Plan**: per-CS quest (아래 IP Pattern).
- **Scenarios / Acceptance**: quest leaf 마다 1 scenario = 1 test (+ regression). test-strategy 와 합성.

## Process (ADHD 5 Phase 요약)

1. CS-01 = **진단 quest** (전수 스캔 → 지금/나중/버리기 분류 → backlog 외부화).
2. CS-02.. = **quest leaf** (1 quest ≈ 1 PR), 가능하면 parallel worker.
3. 매 quest: `[Pre]` → `[Tasks]`(`(N분)` 추정) → `[Post]`. 실행 시 35분 도파민 메뉴.
4. running state(quest-log / time-map / discoveries) → `.houston/scratch/<mission>/` (ticket 에 안 넣음).
5. 5 운영 게이트 적용 (scope / context budget / manager-leaf / external-change / discovery).

## Implementation Plan Pattern

```
### CS-01: 진단 → `repo`
**[Pre]** worktree / branch / 산출물 placeholder
**[Tasks]**
- [ ] (5분) <전수 스캔 명령>
- [ ] (20분) 결과 분석 + 지금/나중/버리기 분류 → backlog 외부화
**[Post]** 산출물 commit+push / 상위 보고

### CS-02 Q2 — <대상> — **parallel worker**  ⚡ ADHD-ready
**Worktree** / **Branch** / **Base** / **Spec**(파일:line) / **Acceptance**(1 scenario=1 test) / **Constraint**(reviewer)

### CS-02 ✅ Q2 (Done) — <대상>
- PR #xxx (+ follow-up #yyy) / expert-review N×R APPROVED / N quest points
```

> **quest ≈ 1 PR** — review 발견이 follow-up PR 을 파생할 수 있다. 1:1 로 고정하지 말고 파생 PR 은
> in-place Evidence row / Flight-N quest 로 적층한다.
> **Wave 분할(G2)** = 수동 추정(quest 수 ÷ ~6). (`houston adhd plan` CLI 는 advisory·현재 미배포.)

## Commit Convention

- per-CS 표준 커밋 타입 그대로: `📝 docs` / `✨ feat` / `🐛 fix` / `🔧 chore` (작업 종류대로).
  ADHD 는 commit type 이 아니다.

## Checklist

- [ ] quest = per-CS, quest ≈ 1 PR (파생 PR 은 Evidence row 적층)
- [ ] Metadata `| **Execution Mode** | ⚡ ADHD-ready |` 행 + CS 별 `⚡ ADHD-ready` blockquote
- [ ] running state → `.houston/scratch/<mission>/` (ticket 에 안 넣음)
- [ ] 실행은 `/houston-adhd-mode` 명시 / 외부변경(G4) 게이트 보존
- [ ] quest leaf 마다 1 scenario = 1 test (+ Bug/회귀 시 regression)
- [ ] design + rollout 혼합 ticket 이면 design CS = coarse / rollout CS = ADHD-ready (per-CS)
