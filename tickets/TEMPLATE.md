# Ticket: T-{ProjectCode}-{GitHubIssueID} [Title]

> **Naming Convention**: `T-{ProjectCode}-{GitHubIssueID}-{Description}.md`
>
> **Project Codes**:
> - `BW`: My Project (`my-project-*`)
> - `BD`: Fourth Project (`fourth-project-*`)
> - `PR`: Third Project (`third-project-*`)
> - `EH`: Another Project (`another-project-*`)
> - `IM`: Fifth Project (`lines-imdr-*`)
> - `INFRA`: Infrastructure / General
>
> **GitHub Issue Policy**: All tickets MUST have a GitHub Issue.
> For cross-repo scope, use `all_issue` repository.

| Metadata | Value |
| :--- | :--- |
| **Status** | Draft / Active / Review / Done |
| **Created** | YYYY-MM-DD |
| **Owner** | @user |
| **Source** | GitHub Issue / Slack / Other |
| **GitHub Issue** | [#IssueID](https://github.com/org/{repo}/issues/{IssueID}) |

## 1. Summary
**What** is being done and **Why**.

## 2. Scope
### In Scope
- Item 1

### Out of Scope
- Item 2

## 3. Affected Repositories
- [ ] `repo-name-1`
- [ ] `repo-name-2`

## 4. Implementation Plan

> 세부 구현 계획. [Pre] → [Tasks] → [Post] 순서로 진행.
> [Tasks]는 티켓 유형에 맞게 자유롭게 정의. 필요 시 subtask로 tree 구조 가능.
> 완료된 Change Set은 `tasks/CHANGESETS.md`에 기록.

### CS-01: {구현 계획 제목} → `repo-name`

**[Pre]**
- [ ] 브랜치 생성: `feat/T-{ProjectCode}-{IssueID}--CS-01`
- [ ] 관련 문서/코드 분석
- [ ] 영향 범위 확인

**[Tasks]**
- [ ] {task 1}
  - [ ] {subtask 1-1}
  - [ ] {subtask 1-2}
- [ ] {task 2}
- [ ] {task 3}

**[Post]**
- [ ] 관련 문서 업데이트 (해당 시)
- [ ] 최종 인수 테스트 통과 확인
- [ ] Commit & Push
- [ ] PR 생성
- [ ] `tasks/CHANGESETS.md` 기록

### CS-02: {다른 repo 구현 계획} → `repo-name-2` (해당 시)
...

## 5. Scenarios (BDD)

> **규칙**: 시나리오 1개 = 인수 테스트 1개. 여기 정의된 시나리오만 테스트로 작성됨.
>
> 일반적으로 1-3개, 최대 5개. Happy Path 필수, 핵심 실패 케이스만 선택적 추가.

### Scenario 1: {Happy Path 시나리오 제목}
```gherkin
Given {사전 조건 - 데이터 상태, 사용자 권한 등}
When {행동 - API 호출, 사용자 액션}
Then {기대 결과 - 응답 코드, 상태 변화}
And {추가 검증} (선택)
```

### Scenario 2: {주요 실패 케이스} (선택)
```gherkin
Given {사전 조건}
When {행동}
Then {기대하는 에러/결과}
```

## 6. Acceptance Criteria
- [ ] Scenario 1 인수 테스트 통과
- [ ] Scenario 2 인수 테스트 통과 (해당 시)
- [ ] 기존 테스트 회귀 없음

## 7. References

> 티켓 작성 시 알고 있는 참고 파일을 기재.
> 비어있으면 AI Agent가 Implementation Plan의 Analysis 단계에서 직접 탐색.
>
> 프로젝트 공통 제약은 각 Repository의 `CLAUDE.md`, `docs/` 참조.

### Related Code (Optional)
- (예) `app/order/use_case/export_excel.py` - 유사 구현

### Related Docs (Optional)
- (예) `docs/api/order.md` - API 스펙

### Search Hints (Optional)
> AI가 탐색할 때 참고할 키워드나 패턴. 모르면 비워둬도 됨.

- 키워드: `keyword1`, `keyword2`
- 유사 기능: 참고할 만한 기존 기능 설명

## 8. Ticket-Specific Constraints (Optional)
> 프로젝트 공통 규칙의 **예외**나 이 티켓만의 특수 제약이 있을 때만 작성.

- (예) 레거시 호환을 위해 기존 응답 형식 유지 필요
- (예) 긴급 핫픽스로 최소 변경만, 리팩토링 금지

## 9. Evidence
> 완료된 작업 증거. `tasks/CHANGESETS.md` 참조.

| CS | Proof |
| :--- | :--- |
| CS-01 | PR #123, commit `abc1234` |

## 10. Notes
<!-- 진행 중 메모, 블로커, 논의 사항 등 -->
