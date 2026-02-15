# Ticket Creation Prompt

GitHub Issue, Slack 메시지 등 다양한 소스에서 표준화된 티켓을 생성할 때 사용합니다.

---

## Prompt Template

### 기본 (GitHub Issue 기반)
```
다음 요청을 기반으로 티켓을 생성해줘.

## 소스
{GitHub Issue URL}

## 지시사항
1. `workspace/tickets/TEMPLATE.md` 형식을 따를 것
2. BDD 시나리오 필수 작성 (Section 5)
3. 정보 부족 시: 코드 탐색 → 유사 사례 확인 → 나에게 질문
4. 추론한 내용은 [추론] 태그로 표시
5. 파일명: `T-{ProjectCode}-{IssueID}-{간단설명}.md`
```

### Slack/구두 요청 기반
```
다음 요청을 기반으로 티켓을 생성해줘.

## 소스
"{요청 내용}"
- 요청자: @name
- 채널: #channel (또는 구두)

## 지시사항
(위와 동일)
```

---

## Task Tags (템플릿)

티켓 유형별 표준 패턴을 `prompts/tags/`에서 참조할 수 있습니다.
티켓 생성 시 해당 태그 파일을 읽고, 포함된 패턴(필수 섹션, IP 패턴, 체크리스트)을 적용하세요.

| Tag | 파일 | 용도 |
|:---|:---|:---|
| `@bug-fix` | `prompts/tags/@bug-fix.md` | 버그 수정 (regression test 필수) |
| `@feature` | `prompts/tags/@feature.md` | 신규 기능 (acceptance test 필수) |
| `@refactor` | `prompts/tags/@refactor.md` | 리팩토링 (기존 테스트 불변) |
| `@hotfix` | `prompts/tags/@hotfix.md` | 긴급 핫픽스 (fast-track) |

**사용 예시**:
```
다음 요청을 기반으로 @bug-fix 티켓을 생성해줘.
```

→ Agent는 `prompts/tags/@bug-fix.md`를 읽고 해당 패턴을 적용하여 티켓을 생성합니다.

---

## AI Agent 참고사항

### 티켓 생성 순서
1. 소스 정보 분석
2. 정보 부족 시 코드 탐색 (관련 기능, 유사 사례)
3. 그래도 불명확하면 질문 목록 제시
4. `workspace/tickets/TEMPLATE.md` 형식으로 티켓 작성
5. `workspace/tickets/`에 저장

### BDD 시나리오 필수 규칙
- **1 Scenario = 1 인수 테스트** (Given-When-Then)
- Happy Path 최소 1개 필수
- 버그 수정: 1개 / 단순 기능: 1-2개 / 복잡한 기능: 3-5개

> 상세 가이드: [`workspace/README.md`](../README.md) Section 10

### 정보 부족 시 질문 예시
```markdown
## 티켓 생성 전 확인 필요

### 필수 질문
1. [ ] 영향받는 Repository가 `third-project-backend` 맞나요?
2. [ ] 구체적 증상은? (에러 메시지, 빈 파일 등)

### 선택 질문
3. [ ] 재현 조건이 있나요?
4. [ ] 언제부터 발생했나요?
```

---

## 생성 예시

**입력**: "Third Project 주문목록에서 엑셀 다운로드 안됨" (Slack)

**출력**: `T-XX-500-Excel-Download-Fix.md`

```markdown
# Ticket: T-XX-500 Excel Download Fix

| Metadata | Value |
| :--- | :--- |
| **Status** | Draft |
| **Created** | 2026-01-19 |
| **Owner** | @kwkim |
| **Source** | Slack #procsy-버그 |
| **GitHub Issue** | [#500](https://github.com/org/third-project-backend/issues/500) |

## 1. Summary
Third Project 주문목록 페이지에서 엑셀 다운로드 기능이 동작하지 않는 버그 수정.

## 2. Scope
### In Scope
- 주문목록 엑셀 다운로드 기능 복구

### Out of Scope
- 다른 페이지의 엑셀 다운로드
- 엑셀 양식 변경

## 3. Affected Repositories
- [ ] `third-project-backend`

## 4. Implementation Plan

> [Pre] → [Tasks] → [Post] 순서로 진행.

### CS-01: 엑셀 다운로드 API 버그 수정 → `third-project-backend`

**[Pre]**
- [ ] 브랜치 생성: `fix/T-XX-500--CS-01`
- [ ] [추론] 관련 코드 분석 (`order_router.py`, `export_use_case.py`)
- [ ] 에러 재현 및 원인 파악

**[Tasks]**
- [ ] [추론] 버그 수정
- [ ] 인수 테스트 작성

**[Post]**
- [ ] 인수 테스트 통과 확인
- [ ] Commit & Push
- [ ] PR 생성
- [ ] `tasks/CHANGESETS.md` 기록

## 5. Scenarios (BDD)

### Scenario 1: 주문목록 엑셀 다운로드 성공
```gherkin
Given 주문 데이터가 존재하고 사용자가 로그인된 상태일 때
When GET /orders/export 호출
Then 응답 200, 엑셀 파일이 다운로드됨
And 파일에 주문 데이터가 포함되어 있음
```

## 6. Acceptance Criteria
- [ ] Scenario 1 인수 테스트 통과
- [ ] 기존 테스트 회귀 없음

## 7. References
### Related Code (Optional)
- [추론] `app/interfaces/order/order_router.py` - 주문 관련 API
- [추론] `app/use_cases/order/export_use_case.py` - 엑셀 export 로직

## 8. Ticket-Specific Constraints (Optional)
- (없음)

## 9. Evidence
| CS | Proof |
| :--- | :--- |

## 10. Notes
- 버그 재현 조건 확인 필요
- 최근 배포 이력 확인 필요
```
