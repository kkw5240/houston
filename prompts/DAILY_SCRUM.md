# Daily Scrum Workflow: Sync & Update (Incremental)

Use this prompt to synchronize GitHub Issues and **update** the Daily Scrum report incrementally.

> **Target Assignee**: `{GITHUB_USERNAME}` (configure for your team)
> **Language**: Korean (Report only) — customize as needed

---

## Phase 1: Ticket Synchronization

**Instruction**: Execute the following steps for each project.

1.  **Fetch Issues from GitHub**:
    Use `gh` CLI or GitHub MCP tools to query open issues assigned to the target user.

2.  **Check Existence & Create Tickets**:
    *   Iterate through the results.
    *   Identify **New Issues** (not tracked in `workspace/tickets/` or task board).
    *   **IF Missing**: Create Ticket file OR add to task board.

3.  **Sync Status**:
    *   **IF Issue is Closed**: Update Ticket to `Done` in `tasks/CHANGESETS.md`.

4.  **Extract Priority & Activity Metadata**:
    *   **DueDate**: Project `Target Date` (Primary) > `Milestone` (Secondary).
    *   **Labels**: `priority:P0`, `qa`, `bug`...
    *   **Activity**: `updatedAt` < Today 00:00 -> **Idle**.

5.  **Review Discrepancies (Manual)**:
    *   **IF Ticket is Done but GitHub Issue is Open**: Report for manual review.
    *   **Do NOT auto-close Issues** — manual confirmation required.

---

## Phase 1.5: Priority Scoring

Calculate a **Priority Score** for each ticket.

### Priority Matrix

| Factor | Weight | Scoring |
| :--- | :--- | :--- |
| **Urgency (Label)** | 40% | P0=100, P1=70, P2=40, P3=20, None=30 |
| **Due Date** | 30% | Today=100, Tomorrow=80, This week=60, Next week=40, TBD=20 |
| **Quick Win** | 20% | <1hr=100, Half-day=70, Full day=50, 2+ days=30 |
| **Dependency** | 10% | Independent=100, FE waiting=50, External=30 |
| **Category** | Bonus | **QA/Bug**=+10 (visibility) |

### Final Priority Calculation

```
Score = (Urgency × 0.4) + (DueDate × 0.3) + (QuickWin × 0.2) + (Dependency × 0.1) + Bonus
```

| Score Range | Priority Tag | Meaning |
| :--- | :--- | :--- |
| 80-100 | `[🔴 Urgent]` | Must handle today |
| 60-79 | `[🟠 High]` | Start today |
| 40-59 | `[🟡 Normal]` | Handle this week |
| 0-39 | `[🟢 Low]` | When available |

---

## Phase 2: Updating Daily Scrum (Incremental Reporting)

**Instruction**: Update the report without overwriting manual entries.

### 1. Document Strategy
- **Path**: `daily_scrum/{YYYY}/{MM}/{YYYY.MM.DD}.md` (workspace-relative path)
- **Action**:
    - **IF New File**: Create from scratch.
    - **IF Exists**: **Read content first**. Identify changes vs existing content. **Append/Merge** new progress.

### 2. Update Rules (Smart Merge)
1.  **Preserve Manual Entries**: Never delete 'Special Notes' or manually added tasks unless explicitly told.
2.  **Move Completed**: If a ticket moved from 'Planned' to 'Done' during the day, move the line.
3.  **Append New**: Add newly synchronized tickets to the appropriate section.
4.  **Sort by Priority**: Priority Score descending.

### 3. Content Structure

#### A. Work Done
- List Tickets that are **Done** or **merged** today.
- Format: `[#{IssueID}] {GitHub Title}: {Brief Status} (PR Link or Commit)`
- Group by project, sort by completion time

#### B. Planned Work

**1. Overdue & High Risk**
- Overdue items OR P0/P1 items inactive for 3+ days.

**2. {Project} - Main Track**
- Active tasks sorted by Priority Score.

**3. QA & Bug Reports (New)**
- `label:qa` OR `label:bug` items established recently.

**4. Idle (Low Priority)**
- Active items with no updates today (excluding Overdue/High Risk).

#### C. Special Notes
- Critical Issues (P0) and Blockers
- Dependency issues (Frontend waiting, DB migration check, etc.)
- Schedule risks (Due date approaching but cannot start)

---

## Execution

### Example Command
```
Execute daily scrum update based on prompts/DAILY_SCRUM.md
```

### Flow
1. Query GitHub Issues for each project (`first: 100`)
2. Extract priority/due date from labels and milestones
3. Compare with Task Board, identify missing tickets, update
4. Calculate **Priority Score** for each ticket
5. Generate/update Daily Scrum document sorted by priority
6. Update task board progress

### Available MCP Tools
| Tool | Purpose |
| :--- | :--- |
| `mcp__github__search_issues` | Search issues (assignee, repo, state filter) |
| `mcp__github__get_issue` | Get individual issue details (labels, milestone, PR links) |
| `mcp__github__list_pull_requests` | List PRs |
| `Glob` | Search ticket files |
| `Read` / `Write` / `Edit` | Create/modify documents |

---

## Quick Reference

### Project Codes

Define your own in `.houston/fleet.yaml`. Example:

| Project | Code | Ticket Prefix Example |
| :--- | :--- | :--- |
| My Backend | XX | `T-XX-100` |
| Another Service | YY | `T-YY-200` |
| Infrastructure | INFRA | `T-INFRA-001` |

### Priority Labels (GitHub)

| Label | Urgency Score |
| :--- | :--- |
| `priority:P0`, `critical`, `urgent` | 100 |
| `priority:P1`, `high` | 70 |
| `priority:P2`, `medium` | 40 |
| `priority:P3`, `low` | 20 |
| (no label) | 30 |
