# Daily Scrum Workflow: Sync & Update (Incremental)

Use this prompt to synchronize GitHub Issues and **update** the Daily Scrum report incrementally.

> **Target Assignee**: `{GITHUB_USERNAME}` (기본값: `your-org`)
> **Language**: Korean (Report only)

---

## 🟢 Phase 1: Ticket Synchronization (Heavier Load)

**Instruction**: Execute the following steps for each project.

            milestone { title dueOn }
            projectItems(first:5) {
              nodes {
                fieldValues(first:10) {
                  nodes {
                    ... on ProjectV2ItemFieldDateValue {
                      date
                      field { ... on ProjectV2FieldCommon { name } }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }'
    ```

2.  **Check Existence & Create Tickets**:
    *   Iterate through the GraphQL results.
    *   Identify **New Issues** (not tracked in `workspace/tickets/` or `task.md`).
    *   **IF Missing**: Create Ticket file OR add to `task.md`.

3.  **Sync Status**:
    *   **IF Issue is Closed**: Update Ticket to `Done` in `tasks/CHANGESETS.md`.
    *   (PR Links are not in this query for speed, check strictly if needed or add `timelineItems` if critical, but usually optional).

4.  **Extract Priority & Activity Metadata**:
    *   **DueDate**: **Project `Target Date`** (Primary) > `Milestone` (Secondary).
    *   **Labels**: `priority:P0`, `qa`, `bug`...
    *   **Activity**: `updatedAt` < Today 00:00 -> **Idle**.

5.  **Review Discrepancies (Manual)**:
    *   **IF Ticket is Done but GitHub Issue is Open**: Report for manual review.
    *   **Do NOT auto-close Issues** - 수동 확인 후 처리합니다.

---

## 🟡 Phase 1.5: Priority Scoring (NEW)

각 티켓에 대해 **Priority Score**를 산정합니다.

### Priority Matrix

| Factor | Weight | Scoring |
| :--- | :--- | :--- |
| **Urgency (Label)** | 40% | P0=100, P1=70, P2=40, P3=20, None=30 |
| **Due Date** | 30% | 오늘=100, 내일=80, 이번주=60, 다음주=40, 미정=20 |
| **Quick Win** | 20% | 1시간 이내=100, 반나절=70, 하루=50, 이틀+=30 |
| **Dependency** | 10% | 블로커 없음=100, FE 대기=50, 외부 의존=30 |
| **Category** | Bonus | **QA/Bug**=+10 (가시성 확보) |

### Quick Win 판단 기준

| 조건 | Quick Win 점수 |
| :--- | :--- |
| 코드 변경 1-2 파일, 로직 단순 | 100 (1시간 이내) |
| 코드 변경 3-5 파일, 테스트 필요 | 70 (반나절) |
| 여러 서비스 연동, DB 마이그레이션 | 50 (하루) |
| 설계 검토 필요, 대규모 리팩토링 | 30 (이틀+) |

### Dependency 판단 기준

| 상태 | 점수 | 설명 |
| :--- | :--- | :--- |
| **독립 실행 가능** | 100 | 즉시 착수 가능 |
| **FE 배포 대기** | 50 | BE 완료 후 FE 작업 필요 |
| **외부 의존** | 30 | 타팀/고객사 확인 필요 |
| **Blocked** | 0 | 선행 작업 미완료 |

### Final Priority 계산

```
Score = (Urgency × 0.4) + (DueDate × 0.3) + (QuickWin × 0.2) + (Dependency × 0.1) + Bonus
```

| Score Range | Priority Tag | 의미 |
| :--- | :--- | :--- |
| 80-100 | `[🔴 긴급]` | 오늘 반드시 처리 |
| 60-79 | `[🟠 높음]` | 오늘 중 착수 |
| 40-59 | `[🟡 보통]` | 이번 주 내 처리 |
| 0-39 | `[🟢 낮음]` | 여유 있을 때 처리 |

---

## 🔵 Phase 2: Updating Daily Scrum (Incremental Reporting)

**Instruction**: Update the report without overwriting manual entries.

### 1. Document Strategy
- **Path**: `daily_scrum/{YYYY}/{MM}/{YYYY.MM.DD}.md` (workspace 기준 상대경로)
- **Language**: **Korean (한국어)**
- **Action**:
    - **IF New File**: Create from scratch.
    - **IF Exists**: **Read content first**. Identify changes vs existing content. **Append/Merge** new progress.

### 2. Update Rules (Smart Merge)
1.  **Preserve Manual Entries**: Never delete 'Special Notes' or manually added tasks unless explicitly told.
2.  **Move Completed**: If a ticket moved from 'Planned' to 'Done' during the day, move the line.
3.  **Append New**: Add newly synchronized tickets to the appropriate section.
4.  **Sort by Priority**:
    - **1순위**: `🚨 장기 미결 (Overdue)` (Idle 중 Target Date 지남 OR P0)
    - **2순위**: `Planned Work` (Priority Score 내림차순)
    - **3순위**: `QA 대응 및 기타` (New QA/Bug 리포트)
    - **4순위**: `Idle (Low)` (단순 미활동, 하단 배치)

### 3. Content Structure

#### A. 금일 수행 업무 (Work Done)
- List Tickets that are **Done** or **merged** today.
- Format: `[#{IssueID}] {GitHub Title}: {Brief Status} (PR Link or Commit)`
- 프로젝트별 그룹핑, 완료 시간순 정렬

#### B. 익일 계획 (Planned Work)

**1. 🚨 장기 미결 및 지연 (Overdue & High Risk)**
- **Target**: Overdue items OR P0/P1 items inactive for 3+ days.

**2. {Project} - Main Track**
- **Target**: Active tasks sorted by Priority Score.

**3. QA 대응 및 기타 (New Reported)**
- **Target**: `label:qa` OR `label:bug` items established recently.

**4. Idle (Low Priority)**
- **Target**: Active items with no updates today (excluding Overdue/High Risk).

### 4. Idle State Logic (NEW)
- **Definition**: Status is 'Active'/'In Progress' BUT `updated_at` < Today 00:00.
- **Action**: Add `(Idle)` marker in Blocker/Note column or Title.
- **Meaning**: 개발 진행 중이지만, 금일 실질적인 업데이트가 없었던 건.
```

#### C. 특이 사항 (Special Notes)
- Critical Issues (P0) 및 Blockers
- 의존성 이슈 (Frontend waiting, DB migration check, etc.)
- 일정 리스크 (Due date 임박 but 착수 불가)

---

## ⚡️ Execution & Sync

### Claude Code 호출 예시
```
Execute daily scrum update based on prompts/DAILY_SCRUM.md
```

### 실행 흐름
1. Claude가 각 프로젝트의 GitHub Issue를 검색 (`first: 100`)
2. Issue의 labels, milestone에서 priority/due date 추출
3. `Task Board` (`task.md`)와 대조하여 누락된 티켓 식별 및 업데이트
4. 각 티켓의 **Priority Score** 산정 (Overdue/QA 여부 판단)
5. Daily Scrum 문서를 **Priority 순으로 정렬**하여 생성/업데이트
6. **`task.md` 업데이트**: Scrum 내용을 바탕으로 `task.md`의 진행 상태(Progress)를 동기화

### 사용 가능한 MCP Tools
| Tool | 용도 |
| :--- | :--- |
| `mcp__github__search_issues` | Issue 검색 (assignee, repo, state 필터) |
| `mcp__github__get_issue` | 개별 Issue 상세 조회 (labels, milestone, PR 링크) |
| `mcp__github__list_pull_requests` | PR 목록 조회 |
| `Glob` | 티켓 파일 검색 |
| `Read` / `Write` / `Edit` | 문서 생성/수정 |

---

## 📋 Quick Reference

### Project Codes

| Project | Code | Ticket Prefix Example |
| :--- | :--- | :--- |
| My Project | BW | `T-BW-1465` |
| Fourth Project | BD | `T-BD-160` |
| Third Project | PR | `T-ZZ-100` |
| Another Project | EH | `T-YY-100` |
| Fifth Project | IM | `T-IM-100` |
| Infrastructure | INFRA | `T-INFRA-001` |

### Priority Labels (GitHub)

| Label | Urgency Score |
| :--- | :--- |
| `priority:P0`, `critical`, `urgent` | 100 |
| `priority:P1`, `high` | 70 |
| `priority:P2`, `medium` | 40 |
| `priority:P3`, `low` | 20 |
| (no label) | 30 |

### Due Date Keywords

| Keyword | DueDate Score |
| :--- | :--- |
| 오늘, today, ASAP | 100 |
| 내일, tomorrow | 80 |
| 이번 주, this week | 60 |
| 다음 주, next week | 40 |
| 미정, TBD | 20 |
