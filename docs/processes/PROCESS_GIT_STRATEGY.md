# Process: Git Strategy (Stage-Based Flow)

> **Authoritative source**: `.houston/PROCESSES.md` §3. This file is the detailed reference.
> Inline agent instructions (CLAUDE.md etc.) are auto-generated from `.houston/` — keep them in sync.

## 1. Branching Convention

This workspace follows a **Stage-Based** branching strategy.

### 1.1 Branch Types

| Branch Type | Pattern | Purpose | Merge Target |
| :--- | :--- | :--- | :--- |
| **main** | `main` / `master` | Production-ready code | - |
| **stage** | `stage` | Integration & test server deployment | main (scheduled) |
| **feature** | `feat/T-{Project}-{IssueID}--CS-{Seq}` | New features | stage |
| **fix** | `fix/T-{Project}-{IssueID}--CS-{Seq}` | Bug fixes | stage |
| **hotfix** | `hotfix/T-{Project}-{IssueID}--{desc}` | Production urgent fixes | main & stage |

### 1.2 Project Codes

Define your own project codes in `.houston/fleet.yaml`. Examples:

- `XX` — My Backend Service
- `YY` — Another Service
- `ZZ` — Frontend App

## 2. Workflows

### 2.1 Feature / Fix Flow (Normal)

```
stage → feat/T-XX-123--CS-01 → PR → stage
```

1. Create branch from `stage`
2. Implement and commit
3. Create PR to `stage`
4. Code review & merge
5. Delete feature branch

### 2.2 Hotfix Flow (Production Emergency)

```
main → hotfix/T-XX-999--critical-fix → PR → main → merge to stage
```

1. Create branch from `main` (or `master`)
2. Implement minimal fix
3. Create PR to `main`
4. Review, merge, and **deploy immediately**
5. Merge `main` back to `stage` to sync
6. Delete hotfix branch

**Hotfix Rules:**
- MUST create PR even for hotfixes (no direct push to main)
- MUST be minimal scope (fix only)
- MUST deploy and verify immediately after merge
- MUST sync back to stage

### 2.3 Regular Deploy Flow

```
stage → PR → main (on scheduled deploy day)
```

1. Verify all changes on stage are validated
2. Create `stage` → `main` PR
3. Review & merge
4. Production deploy and verify

## 3. General Rule

Branching strategies in repositories MUST align with this convention.
