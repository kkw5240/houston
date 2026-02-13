# Houston Processes

Summaries of core workflows. For full details, see `docs/processes/`.

---

## 1. Repo-per-Ticket Workflow

> Full doc: `docs/processes/WORKFLOW_REPO_PER_TICKET.md`

Each ticket gets its own **disposable workspace** — a full copy of the source repo.

**Lifecycle**: Copy & Spawn → Use → Verify → Destroy

```
workspace/{project}/
  source/              # Read-Only template (always synced to remote)
  T-{ID}-{desc}/       # Isolated ticket workspace (disposable)
```

**Finding the right repository:**

Before creating a ticket workspace, identify the target repo:
1. Check `.houston/fleet.yaml` — fleet manifest (which repos are docked)
2. Match project code to repo: BW → my-project, EH → another-project, etc.
3. Source path convention: `{project-folder}/source/` (read-only, always synced to remote)
4. If the repo is not listed or the path doesn't exist, ask the user.

Check if `scripts/houston` exists in the workspace. If yes, use the CLI. If not, use the manual fallback below.

### With Houston CLI (preferred)

```bash
# Create ticket workspace (project code lookup from fleet.yaml)
houston ticket <CODE> <TICKET_ID> [DESC]
# Example: houston ticket XX T-XX-100 feature-name
# → Syncs my-project/source to master (from fleet.yaml)
# → Creates my-project/T-XX-100-feature-name/
# → Branch: feat/T-XX-100--CS-01

# Close ticket workspace (after PR merge)
houston close <TICKET_PATH>

# Check fleet status
houston status --fetch

# Show project info
houston info <CODE>
```

You can also pass a direct path instead of a project code (backward compatible):
```bash
houston ticket ../my-project/source T-XX-100 feature-name
```

### Without Scripts (manual fallback)

If scripts are not available in the workspace:

```bash
# 1. Update source to latest
cd ../lines-{project}/source && git pull origin stage

# 2. Copy to ticket folder
cp -R . ../T-{ID}-{description}
cd ../T-{ID}-{description}

# 3. Create branch
git checkout -b feat/T-{Project}-{ID}--CS-01

# 4. Work...

# 5. After PR merge — delete ticket folder
cd .. && rm -rf T-{ID}-{description}
```

**Key rules**:
- NEVER work directly in `source/`. It is read-only.
- Folder naming: `T-{ProjectCode}-{IssueID}-{description}`
- Branch naming: `feat/T-{ProjectCode}-{IssueID}--CS-{Seq}`
- Always check for unpushed commits before deleting ticket folders.

### Multi-Repo Tickets

When a ticket spans multiple repositories (e.g., CS-01 = Backend, CS-02 = Frontend):

1. Each CS targets ONE repo — this is enforced by Golden Rule #5 (One Repo Focus)
2. When moving to a new CS in a different repo:
   - Complete current CS → record evidence in CHANGESETS.md
   - Create a new ticket workspace in the target repo: `T-{ID}-{desc}/`
   - Create a new branch: `feat/T-{Project}-{ID}--CS-{Seq}`
   - Continue with the new CS's [Pre] → [Tasks] → [Post]
3. The ticket file stays in Houston — it tracks ALL CS across repos

### Parallel Work (Sub-Issues / Independent Tasks)

When the user requests multiple tasks at once (e.g., sub-issues within one parent issue, or independent tickets):

1. **Each task gets its own workspace** — Repo-per-Ticket applies per task, not per session
   - Task A → `T-{ID-A}-{desc}/` + branch `feat/T-{Project}-{ID-A}--CS-{Seq}`
   - Task B → `T-{ID-B}-{desc}/` + branch `feat/T-{Project}-{ID-B}--CS-{Seq}`
2. **Same repo is OK** — multiple ticket workspaces can copy from the same `source/`
3. **No cross-contamination** — never mix changes from different tasks in one workspace
4. **Track separately** — each task gets its own CS row in `tasks/CHANGESETS.md`
5. **Evidence per task** — each task must have its own commit hash / PR link
6. **TASK_BOARD.md** shows parallel status — multiple items in "In Progress" is normal

> Parallel work is safe because Repo-per-Ticket guarantees physical isolation.
> If two tasks modify the same file, conflicts are resolved at PR merge time — not in the workspace.

**Priority decision criteria** (highest first):

1. **Hotfix / Production incident** — always top priority
2. **User-specified priority** — "A 먼저 해줘" etc.
3. **Blocker resolution** — unblocks another task's dependency
4. **Quick Win** — shortest time to completion
5. **FIFO** — when none of the above apply

When uncertain, ask the user.

---

## 2. Testing Strategy (TDD + BDD Hybrid)

> Full doc: `docs/processes/PROCESS_TESTING.md`

**Core flow**: Scenario → Acceptance Test (Red) → TDD Implementation → Green → Commit

### Test Types

| Test Type | Purpose | When | Committed? |
|:---|:---|:---|:---|
| **Acceptance Test** | Prove requirements met | BEFORE coding (Red) | Yes |
| **Regression Test** | Prevent bug recurrence | When fixing bugs | Yes |
| **Unit Test** | Fast feedback, design aid | During coding | No (local only) |

### Acceptance Test Rules

- 1 BDD Scenario = 1 Acceptance Test function (strict 1:1 mapping)
- Use Given-When-Then format from ticket scenarios
- Minimize mocks — prefer real DB/API
- Validate inputs/outputs only — not implementation details
- Commit acceptance tests only; unit tests stay local

### Regression Test Rules

- **Bug Fix tickets: regression test is MANDATORY.**
- File naming: `tests/regression/test_T_{PROJECT}_{ISSUE_ID}.py`
- Purpose: reproduce the bug, then prove the fix prevents recurrence.
- Regression tests ARE committed (unlike unit tests).

### Test Requirements by Ticket Type

| Ticket Type | Acceptance Test | Regression Test |
|:---|:---|:---|
| New Feature | Required | — |
| Bug Fix | Case by case | **Required** |
| Refactoring | — | — |
| Docs / Config | — | — |

### Test Directory Structure

```
tests/
  acceptance/           # Committed — proves requirements met
  regression/           # Committed — prevents bug recurrence
  fixtures/             # Test data factories
  unit/                 # NOT committed — local dev only (.gitignore)
```

---

## 3. Git Strategy (Stage-Based Flow)

> Full doc: `docs/processes/PROCESS_GIT_STRATEGY.md`

**Branches**:

| Type | Pattern | Merges Into |
|:---|:---|:---|
| Production | `main` / `master` | — |
| Integration | `stage` | `main` (scheduled) |
| Feature | `feat/T-{Project}-{ID}--CS-{Seq}` | `stage` |
| Fix | `fix/T-{Project}-{ID}--CS-{Seq}` | `stage` |
| Hotfix | `hotfix/T-{Project}-{ID}--{desc}` | `main` + `stage` |

**Project codes**: EH (Another Project), BW (My Project), PS (Third Project), BF (Fourth Project), IM (Fifth Project)

**Hotfix rules**:
- MUST create PR (no direct push to main)
- MUST be minimal scope (fix only)
- MUST deploy and verify immediately
- MUST sync back to stage after merge

### Hotfix Fast Track

When the user declares a task as **Hotfix** (production emergency):

**Shortened process** — skip full BDD/TDD cycle:
1. Create ticket (minimal: Summary + 1 Scenario)
2. Branch: `hotfix/T-{Project}-{ID}--{desc}` from `main`
3. Write a **regression test** that reproduces the bug
4. Fix the bug (minimal scope — fix only, no refactoring)
5. Verify: regression test passes + existing tests don't break
6. PR to `main` → deploy → verify in production
7. Sync back to `stage`: merge `main` into `stage`

**What is skipped**: Full BDD scenario suite, acceptance test-first cycle, docs-first update
**What is NOT skipped**: Ticket creation (minimal), regression test, PR, evidence recording

> The user must explicitly say "Hotfix" or "긴급" to trigger this track.
> If unclear, ask: "Is this a production emergency (Hotfix) or a normal fix?"

---

## 4. Ticket & Change Set Model

**Ticket** (`tickets/T-{Project}-{ID}.md`): A unit of intent. 1 Ticket = 1 GitHub Issue.

**Change Set (CS)** (`tasks/CHANGESETS.md`): A logical group of changes within one repository.
- 1 Ticket can have multiple CS (e.g., Backend CS-01, Frontend CS-02)
- Each CS has internal structure: [Pre] → [Tasks] (IP items) → [Post]
- Status flow: Draft → WIP → Review → Staged → Done
- Evidence (commit hash / PR link) is REQUIRED to mark "Done"

**Task Board** (`tasks/TASK_BOARD.md`): Kanban view of all active work.

**Archive**: When CHANGESETS.md grows large, archive completed entries:
```bash
houston archive              # Archive Done entries older than 14 days
houston archive --days 30    # Custom cutoff (30 days)
houston archive --dry-run    # Preview without changes
```
- Archived entries move to `tasks/CHANGESETS_ARCHIVE_{YYYY}.md` (yearly files)
- Active file retains non-Done entries + recent Done entries
- Archive files are append-only (cumulative per year)

---

## 5. Work Phases (General Execution)

```
Phase 1: Context & Planning
  └── Read Houston rules → Read repo docs → Search code patterns

Phase 2: Documentation (Intent Alignment)
  └── Houston ticket: verify scenarios match intent
  └── Service repo docs/: update domain docs, API specs, business rules affected by this change

Phase 3: Acceptance Test First (Red)
  └── Read ticket scenarios → Write acceptance tests → Confirm they fail

Phase 4: Implementation (Red → Green)
  └── TDD for details → Follow repo patterns → Atomic commits

Phase 5: Evidence & Commit
  └── All acceptance tests green → Create PR → Record in CHANGESETS.md
```

---

## 6. Agent Communication Protocol

When reporting progress, follow this 4-stage interface:

| Stage | Output |
|:---|:---|
| **Plan** | Implementation plan — what you will do and in what order |
| **Edit** | Code changes + test code |
| **Verify** | Pass/fail evidence (test results, lint output) |
| **Done** | PR link + commit hash recorded in CHANGESETS.md |

---

## 7. Daily Scrum

- **Path**: `daily_scrum/{YYYY}/{MM}/{YYYY.MM.DD}.md`
- **Prompt**: Use `prompts/DAILY_SCRUM.md` to generate the daily scrum update.
- **When**: At the start of each working day, or when the user asks for status sync.
- **Content**: Work done, planned work, blockers.

---

## 8. Ticket Creation

When a ticket does not exist yet (e.g., first time using Houston, or ad-hoc request from Slack/verbal):

1. Read `prompts/CREATE_TICKET.md` for the standard creation process and template.
2. Source can be: GitHub Issue URL, Slack message, or verbal request.
3. BDD Scenarios are REQUIRED in every ticket (Given-When-Then format).
   - Bug Fix: 1 scenario / Simple Feature: 1-2 / Complex Feature: 3-5
4. Save to `tickets/T-{ProjectCode}-{IssueID}-{description}.md`
5. Register the ticket in `tasks/TASK_BOARD.md`.
6. Then continue with the Session Checklist [PRE] steps.
