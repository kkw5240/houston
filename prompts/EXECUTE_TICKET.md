# Ticket Execution Prompt

생성된 티켓을 AI 에이전트에게 실행 요청할 때 사용합니다.

---

## Prompt Template

### 기본 (전체 티켓 실행)
```
T-{ProjectCode}-{IssueID} 처리해줘.
workspace/README.md 프로세스 따라서.
```

### 부분 실행 / 세션 재개

세션이 비정상 종료되거나 특정 작업만 실행할 때 사용합니다.

```
# 특정 CS부터 실행
T-{ProjectCode}-{IssueID}의 CS-02부터 진행해.

# 특정 CS 내 IP부터 실행 (세션 재개 시 유용)
T-{ProjectCode}-{IssueID}의 CS-01 IP-03부터 진행해.
```

**용어 참고:**
- **CS (Change Set)**: 작업 그룹 단위 ([Pre] → [Tasks] → [Post] 구조)
- **IP (Implementation Plan item)**: CS 내 [Tasks]의 개별 작업 항목

---

## 예시

### 전체 티켓 실행
```
T-YY-100 처리해줘.
workspace/README.md 프로세스 따라서.
```

### 세션 재개 (특정 IP부터)
```
T-ZZ-100의 CS-01 IP-03부터 진행해.
# → CS-01의 [Tasks] 중 3번째 항목(예: Repository 코드)부터 재개
```

### 특정 CS만 실행
```
T-XX-100의 CS-02만 처리해줘.
# → CS-02의 [Pre]부터 [Post]까지 실행
```

---

## AI Agent 참고사항

티켓 실행 시 다음 순서로 진행:

1. **Checklist**: [`tasks/START_TASK_CHECKLIST.md`](../tasks/START_TASK_CHECKLIST.md) 확인 (필수)
2. `workspace/README.md` 읽기 (프로세스 확인)
3. 티켓 파일 읽기 (`tickets/T-{ProjectCode}-{IssueID}-*.md`)
4. 티켓의 Implementation Plan 순서대로 진행
   - CS 순서: CS-01 → CS-02 → ...
   - 각 CS 내부: [Pre] → [Tasks] → [Post]
4. 완료 시 `tasks/CHANGESETS.md` 업데이트

### 세션 재개 시

1. 티켓 Evidence 섹션에서 마지막 완료 CS 확인
2. `tasks/CHANGESETS.md`에서 진행 상태 확인
3. 중단된 지점부터 재개

> 상세 가이드: [`docs/guides/AI_AGENT_GUIDE.md`](../docs/guides/AI_AGENT_GUIDE.md)
