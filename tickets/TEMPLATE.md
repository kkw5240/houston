# Ticket: T-{ProjectCode}-{GitHubIssueID} [Title]

> **Naming Convention**: `T-{ProjectCode}-{GitHubIssueID}-{Description}.md`
>
> **Project Codes**: Define your own in `.houston/fleet.yaml`.
> Examples: `XX` (My Backend), `YY` (Another Service), `INFRA` (Infrastructure)
>
> **GitHub Issue Policy**: All tickets MUST have a GitHub Issue.
> For cross-repo scope, create a dedicated issue repository.

| Metadata | Value |
| :--- | :--- |
| **Status** | Draft / Active / Review / Done |
| **Created** | YYYY-MM-DD |
| **Owner** | @user |
| **Source** | GitHub Issue / Slack / Other |
| **GitHub Issue** | [#IssueID](https://github.com/org/repo/issues/{IssueID}) |

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

> Detailed implementation plan. Execute in [Pre] → [Tasks] → [Post] order.
> [Tasks] can be freely defined per ticket type. Subtask tree structure is OK.
> Completed Change Sets are recorded in `tasks/CHANGESETS.md`.

### CS-01: {Implementation plan title} → `repo-name`

**[Pre]**
- [ ] Create branch: `feat/T-{ProjectCode}-{IssueID}--CS-01`
- [ ] Analyze related docs/code
- [ ] Identify impact scope

**[Tasks]**
- [ ] {task 1}
  - [ ] {subtask 1-1}
  - [ ] {subtask 1-2}
- [ ] {task 2}
- [ ] {task 3}

**[Post]**
- [ ] Update related docs (if applicable)
- [ ] Verify acceptance tests pass
- [ ] Commit & Push
- [ ] Create PR
- [ ] Record in `tasks/CHANGESETS.md`

### CS-02: {Other repo plan} → `repo-name-2` (if applicable)
...

## 5. Scenarios (BDD)

> **Rule**: 1 Scenario = 1 Acceptance Test. Only scenarios defined here become tests.
>
> Typically 1-3, max 5. Happy Path required. Add key failure cases selectively.

### Scenario 1: {Happy Path scenario title}
```gherkin
Given {precondition — data state, user permissions, etc.}
When {action — API call, user action}
Then {expected result — response code, state change}
And {additional verification} (optional)
```

### Scenario 2: {Key failure case} (optional)
```gherkin
Given {precondition}
When {action}
Then {expected error/result}
```

## 6. Acceptance Criteria
- [ ] Scenario 1 acceptance test passes
- [ ] Scenario 2 acceptance test passes (if applicable)
- [ ] No regression in existing tests

## 7. References

> List known reference files when writing the ticket.
> If empty, AI Agent will explore during the Implementation Plan Analysis phase.
>
> Project-wide constraints: see each repository's `CLAUDE.md`, `docs/`.

### Related Code (Optional)
- (e.g.) `app/order/use_case/export_excel.py` - Similar implementation

### Related Docs (Optional)
- (e.g.) `docs/api/order.md` - API spec

### Search Hints (Optional)
> Keywords or patterns for AI to reference during exploration. OK to leave empty.

- Keywords: `keyword1`, `keyword2`
- Similar feature: description of existing similar feature

## 8. Ticket-Specific Constraints (Optional)
> Only write when there are **exceptions** to project-wide rules or special constraints for this ticket.

- (e.g.) Must maintain existing response format for legacy compatibility
- (e.g.) Urgent hotfix — minimal changes only, no refactoring

## 9. Evidence
> Proof of completed work. See `tasks/CHANGESETS.md`.

| CS | Proof |
| :--- | :--- |
| CS-01 | PR #123, commit `abc1234` |

## 10. Notes
<!-- In-progress memos, blockers, discussion items, etc. -->
