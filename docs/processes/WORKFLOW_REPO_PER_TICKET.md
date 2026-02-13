# Workflow: Repo-per-Ticket (Disposable Workspace)

> **Authoritative source**: `.houston/PROCESSES.md` §1. This file is the detailed reference.
> Inline agent instructions (CLAUDE.md etc.) are auto-generated from `.houston/` — keep them in sync.

## 1. Concept: Disposable Workspace

To solve **environment contamination** and **context switching** problems when handling multiple tickets simultaneously, we use a **Repo-per-Ticket** isolation workflow.

### 1.1 Problem: Single Workspace Limitations

| Problem | Description |
|------|------|
| **No physical parallelism** | Working on Ticket A, then urgent Ticket B requires git stash. Only one server port. |
| **Environment contamination** | .env and DB configs mixed, causing conflicts between tickets |
| **Human error** | Starting work on wrong branch, committing directly to develop |

### 1.2 Solution: Disposable Workspace

```
workspace/
├── my-project/
│   ├── source/                       # [Source] Read-Only origin (always latest remote)
│   ├── T-XX-100-feature-a/           # [Ticket A] Isolated workspace
│   └── T-XX-200-urgent-fix/          # [Ticket B] Isolated workspace
└── scripts/                          # Workspace automation scripts
```

### 1.3 Workflow: Copy & Spawn → Use & Destroy

1.  **Source Repo = Template**
    *   `source/` is always kept at the latest remote state
    *   Never code directly here (Read-Only)

2.  **Copy & Spawn** (start ticket)
    ```bash
    ./scripts/new_ticket.sh ../my-project/source T-XX-100 feature-a
    # Creates: my-project/T-XX-100-feature-a/
    ```
    - Full copy of source creates an isolated environment
    - Server ports, DB configs can be freely changed

3.  **Use & Destroy** (complete ticket)
    ```bash
    ./scripts/close_ticket.sh ./my-project/T-XX-100-feature-a
    ```
    - Delete ticket folder after PR merge
    - Reclaim disk space

### 1.4 Benefits

| Benefit | Description |
|------|------|
| **Complete isolation** | Changes in Ticket A don't affect Ticket B |
| **Parallel processing** | Run multiple servers simultaneously for comparison |
| **Easy rollback** | Just delete the folder to revert |
| **Reduced cognitive load** | Switch folders instead of branches |

---

## 2. Execution Guide (How-to)

How AI Agents execute tickets in the **Repo-per-Ticket** model.

### 2.1 When to Use

- When project group folder structure is set up (e.g., `../my-project/source/`)
- When handling multiple tickets simultaneously
- When environment isolation is needed

### 2.2 Execution Flow

```
1. Check/create ticket folder
   └── Use scripts/new_ticket.sh or manual copy

2. Move to ticket folder
   └── cd {project}/{ticket-folder}/

3. Execute standard ticket process
   └── [Pre] → [Tasks] → [Post]

4. Cleanup after completion
   └── Use scripts/close_ticket.sh or manual delete
```

### 2.3 Script Usage

**Start ticket:**
```bash
./scripts/new_ticket.sh <SOURCE_PATH> <TICKET_ID> [DESCRIPTION]
# Example:
./scripts/new_ticket.sh ../my-project/source T-XX-100 "feature-a"
# Creates: my-project/T-XX-100-feature-a/
# Branch: feat/T-XX-100--CS-01
```

**Close ticket:**
```bash
./scripts/close_ticket.sh <TICKET_PATH>
# Example:
./scripts/close_ticket.sh ./my-project/T-XX-100-feature-a
# Checks unpushed commits, then deletes folder
```

### 2.4 Important Rules

1. **Protect Source Repo**: Never work directly in `source/` folder
2. **Folder Naming**: Follow `T-{ProjectCode}-{IssueID}-{description}` format
3. **Branch Creation**: Create `feat/T-{ID}--CS-01` branch inside ticket folder
4. **Cleanup Required**: Delete ticket folder after PR merge (disk management)

### 2.5 Without Scripts (Manual Process)

When scripts are not available:

```bash
# 1. Update source
cd ../my-project/source
git pull origin master

# 2. Create ticket folder (copy)
cp -R . ../T-XX-100-feature-a
cd ../T-XX-100-feature-a

# 3. Create branch
git checkout -b feat/T-XX-100--CS-01

# 4. Work...

# 5. Delete after completion (check unpushed commits first)
cd ..
rm -rf T-XX-100-feature-a
```

---

## 3. Parallel Work (Sub-Issues / Independent Tasks)

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
2. **User-specified priority** — "Do A first" etc.
3. **Blocker resolution** — unblocks another task's dependency
4. **Quick Win** — shortest time to completion
5. **FIFO** — when none of the above apply

When uncertain, ask the user.
