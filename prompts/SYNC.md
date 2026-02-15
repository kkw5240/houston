# Houston Sync: Houston <-> GitHub Issue Synchronization

Houston 문서와 GitHub Issue 간 양방향 동기화를 수행합니다.
Sync는 Daily Scrum과 독립적으로 실행 가능한 데이터 정합성 도구입니다.

> **Assignee**: `{GITHUB_USERNAME}` (기본값: `your-org`)
> **Language**: Korean (Report)
> **Sync Policy**: GitHub -> Houston = 자동 적용 | Houston -> GitHub = Dry-run (제안만)

---

## Phase 1: Data Collection

### 1-1. fleet.yaml에서 issue_repo 매핑 읽기

```
.houston/fleet.yaml의 각 프로젝트 항목에서 issue_repo 필드를 읽는다.
issue_repo가 없는 프로젝트는 동기화 대상에서 제외한다.
```

| Project Code | issue_repo |
|:---|:---|
| BW | `org/all_issue` |
| EH | `org/another-project-backend` |
| EH-Flutter | `org/another-project-backend` |
| PR | `org/lines-customer-request` |
| BD | `org/all_issue` |
| BD-Parser | `org/all_issue` |
| IM | `org/all_issue` |
| IM-Go | `org/all_issue` |
| INFRA | `your-org/houston` |

> 이 표는 참고용. 실제 실행 시 fleet.yaml에서 동적으로 읽는다.

### 1-2. GitHub Issue 스캔

각 **고유 issue_repo**에 대해 (중복 제거 후):

```bash
# MCP Tool 사용
mcp__github__search_issues:
  query: "assignee:{GITHUB_USERNAME} is:issue repo:{issue_repo}"
  # state: open + recently closed (최근 14일)
```

수집 항목:
- Issue number, title, state (open/closed)
- Labels (priority, qa, bug 등)
- Milestone (due date)
- Updated at
- Linked PR (있으면)

### 1-3. Houston 로컬 문서 읽기

| 파일 | 수집 내용 |
|:---|:---|
| `tasks/TASK_BOARD.md` | 각 티켓의 현재 상태 (Backlog/Active/Hold/Stage/Done) |
| `tickets/*.md` | 티켓 존재 여부, 메타데이터 (Status, GitHub Issue 번호) |
| `tasks/CHANGESETS.md` | CS 상태 (WIP/Review/Staged/Done), PR 링크 |

---

## Phase 2: Houston -> GitHub 불일치 감지 (Dry-run)

Houston 문서 기준으로 GitHub Issue 상태가 맞지 않는 경우를 감지한다.
**이 방향은 제안만 출력하고, 자동 변경하지 않는다.**

| Houston 상태 | GitHub 상태 | 제안 Action | 사유 |
|:---|:---|:---|:---|
| TASK_BOARD: Done | Issue: Open | `close issue` 제안 | 작업 완료인데 이슈 미닫힘 |
| TASK_BOARD: Hold | Issue: no hold label | `add label` 제안 | Hold 상태 미반영 |
| CHANGESETS: Done + PR merged | Issue: Open | `close issue` 제안 | PR 머지 완료인데 이슈 미닫힘 |
| TASK_BOARD: Active | Issue: Closed | 리포트 기록 | 수동 확인 필요 (재오픈?) |

### 감지 로직

```
1. TASK_BOARD.md에서 Done 섹션의 모든 티켓을 추출한다.
2. 각 티켓의 GitHub Issue 번호를 tickets/ 파일에서 찾는다.
3. 해당 Issue가 아직 Open이면 -> close 제안 목록에 추가한다.
4. TASK_BOARD.md에서 Active 섹션의 티켓 중, GitHub에서 Closed인 건 -> 수동 확인 목록에 추가한다.
```

---

## Phase 3: GitHub -> Houston 불일치 감지 (자동 적용)

GitHub Issue 기준으로 Houston 문서가 맞지 않는 경우를 감지하고 **자동 수정한다.**

| GitHub 상태 | Houston 상태 | Action | 자동 여부 |
|:---|:---|:---|:---|
| Issue: Closed | TASK_BOARD: Active/WIP | TASK_BOARD -> Done 이동 | **자동** |
| Issue: Open (assigned) | TASK_BOARD에 없음 | TASK_BOARD에 추가 | **자동** |
| Issue: New (no ticket) | tickets/에 없음 | 신규 등록 제안 | 제안 (리포트) |
| Issue: label 변경 | ticket 미반영 | ticket 메타데이터 갱신 | **자동** |

**Label → Ticket Metadata 매핑 규칙**:

| GitHub Label | Ticket Metadata Field | 값 |
|:---|:---|:---|
| `priority:P0` ~ `priority:P3` | Priority | P0 / P1 / P2 / P3 |
| `critical`, `urgent` | Priority | P0 |
| `high` | Priority | P1 |
| `qa`, `bug` | Category | QA / Bug |
| `hold` | Status | Hold |

### Idempotency (반복 실행 안전성)

Sync는 하루에 여러 번 실행될 수 있다. 중복 적용을 방지하기 위해:
- **추가 전 존재 확인**: TASK_BOARD.md에 항목을 추가하기 전, Issue 번호(`#{number}`)가 이미 존재하는지 검색한다. 이미 있으면 skip.
- **이동 전 위치 확인**: Done 섹션으로 이동하기 전, 해당 항목이 이미 Done에 있는지 확인한다. 이미 있으면 skip.
- **Label 갱신**: ticket 파일의 현재 메타데이터와 비교 후 변경이 있을 때만 수정한다.

### 자동 적용 규칙

**TASK_BOARD.md 갱신**:
```
- GitHub Issue Closed → TASK_BOARD의 해당 항목을 Done 섹션으로 이동
- GitHub Issue Open (assigned, TASK_BOARD에 없음) → Active 섹션에 추가:
  - [ ] [T-{Project}-{IssueID} {Title}](../tickets/T-{Project}-{IssueID}.md) <- **GitHub #{IssueID}**
- 프로젝트별 섹션 배치 규칙은 기존 TASK_BOARD.md 구조를 따른다
```

**공유 issue_repo 프로젝트 판별** (예: `all_issue`를 BW, BD, IM이 공유):
```
1. Issue title/label에서 프로젝트 키워드 매칭: "betterwell" → BW, "bidify" → BD, "imdr" → IM
2. Issue에 project label이 있으면 사용 (예: "project:betterwell")
3. 기존 tickets/ 파일에 해당 Issue가 이미 있으면 그 파일의 Project Code 사용
4. 판별 불가 시 → Phase 4 리포트의 "신규 등록 제안"에 기록하고, 자동 추가하지 않음
```

**tickets/ 파일 갱신**:
```
- Label 변경 시 ticket 파일의 메타데이터만 업데이트 (Status, Priority 등)
- 새 Issue인데 ticket 파일이 없으면 -> Phase 4 리포트에 "신규 등록 제안"으로 기록
  (자동 생성하지 않음 — 티켓 생성은 prompts/CREATE_TICKET.md로 수행)
```

---

## Phase 4: Sync Report 출력

동기화 결과를 아래 형식으로 출력한다.

```markdown
## Sync Report: {YYYY-MM-DD}

### Houston -> GitHub (제안 - 수동 처리 필요)
| Action | Issue | Repo | 사유 |
|:---|:---|:---|:---|
| Close | #{number} {title} | {issue_repo} | TASK_BOARD Done, CHANGESETS Done |
| Add Label | #{number} {title} | {issue_repo} | TASK_BOARD Hold |

> 위 항목은 자동 변경되지 않습니다. 확인 후 수동으로 처리하세요.

### GitHub -> Houston (자동 적용됨)
| Action | 대상 | 내용 |
|:---|:---|:---|
| TASK_BOARD 갱신 | #{number} | Active -> Done (Issue Closed) |
| TASK_BOARD 추가 | #{number} | New issue, Active에 추가 |
| Label 동기화 | #{number} | priority:P1 -> ticket 메타데이터 갱신 |

### 불일치 (수동 확인 필요)
| Issue | Houston | GitHub | 비고 |
|:---|:---|:---|:---|
| #{number} | Active | Closed | 재오픈 필요? |
| #{number} | Done | Open | PR Review 중 — 상태 맞음? |

### 신규 등록 제안
| Issue | Repo | Title | Labels |
|:---|:---|:---|:---|
| #{number} | {issue_repo} | {title} | {labels} |

> 신규 티켓은 `prompts/CREATE_TICKET.md`로 생성하세요.

### Summary
- 스캔한 이슈 수: {N}
- Houston -> GitHub 제안: {N}건
- GitHub -> Houston 자동 적용: {N}건
- 수동 확인 필요: {N}건
- 신규 등록 제안: {N}건
```

---

## Execution

### 실행 방법
```
prompts/SYNC.md 기반으로 Houston <-> GitHub 동기화를 수행해줘.
```

### 사용하는 MCP Tools

| Tool | 용도 |
|:---|:---|
| `mcp__github__search_issues` | Issue 검색 (assignee, repo, state 필터) |
| `mcp__github__get_issue` | 개별 Issue 상세 조회 |
| `mcp__github__list_issues` | 레포별 Issue 목록 조회 |
| `Glob` | tickets/ 파일 검색 |
| `Read` / `Edit` | TASK_BOARD.md, tickets/ 읽기/수정 |

### 주의사항

1. **GitHub Issue 자동 변경 금지**: Houston -> GitHub 방향은 절대 자동 실행하지 않는다. 제안 목록만 출력한다.
2. **issue_repo 필수**: fleet.yaml에 `issue_repo`가 없는 프로젝트는 동기화 대상에서 제외한다.
3. **중복 issue_repo 처리**: 여러 프로젝트가 같은 issue_repo를 공유할 수 있다 (예: BW, BD, IM -> all_issue). 중복 스캔하지 않도록 issue_repo를 deduplicate한 후 스캔한다.
4. **매칭 규칙**: GitHub Issue 번호와 Houston 티켓은 tickets/ 파일의 `GitHub Issue` 메타데이터 또는 파일명의 Issue ID로 매칭한다.
