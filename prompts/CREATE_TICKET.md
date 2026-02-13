# Ticket Creation Prompt

Use this prompt to create standardized tickets from various sources: GitHub Issues, Slack messages, verbal requests, etc.

---

## Prompt Template

### Basic (GitHub Issue)
```
Create a ticket based on the following request.

## Source
{GitHub Issue URL}

## Instructions
1. Follow `workspace/tickets/TEMPLATE.md` format
2. BDD Scenarios are REQUIRED (Section 5)
3. If information is insufficient: search code → check similar cases → ask me
4. Mark inferred content with [Inferred] tag
5. File name: `T-{ProjectCode}-{IssueID}-{short-description}.md`
```

### Slack / Verbal Request
```
Create a ticket based on the following request.

## Source
"{request content}"
- Requester: @name
- Channel: #channel (or verbal)

## Instructions
(same as above)
```

---

## AI Agent Notes

### Ticket Creation Order
1. Analyze source information
2. If insufficient, search code (related features, similar cases)
3. If still unclear, present a list of questions
4. Write ticket in `workspace/tickets/TEMPLATE.md` format
5. Save to `workspace/tickets/`

### BDD Scenario Rules
- **1 Scenario = 1 Acceptance Test** (Given-When-Then)
- At least 1 Happy Path required
- Bug fix: 1 / Simple feature: 1-2 / Complex feature: 3-5

> Detailed guide: [`workspace/README.md`](../README.md)

### Example Questions When Info is Missing
```markdown
## Pre-Ticket Clarification Needed

### Required
1. [ ] Is the affected repository `my-project-backend`?
2. [ ] What are the specific symptoms? (error message, empty file, etc.)

### Optional
3. [ ] Are there reproduction conditions?
4. [ ] When did this start happening?
```

---

## Creation Example

**Input**: "Order list Excel download is broken" (Slack)

**Output**: `T-XX-500-Excel-Download-Fix.md`

```markdown
# Ticket: T-XX-500 Excel Download Fix

| Metadata | Value |
| :--- | :--- |
| **Status** | Draft |
| **Created** | 2026-01-19 |
| **Owner** | @user |
| **Source** | Slack #bugs |
| **GitHub Issue** | [#500](https://github.com/org/my-project-backend/issues/500) |

## 1. Summary
Fix the Excel download feature on the order list page.

## 2. Scope
### In Scope
- Restore order list Excel download functionality

### Out of Scope
- Other pages' Excel download
- Excel format changes

## 3. Affected Repositories
- [ ] `my-project-backend`

## 4. Implementation Plan

### CS-01: Fix Excel download API bug → `my-project-backend`

**[Pre]**
- [ ] Create branch: `fix/T-XX-500--CS-01`
- [ ] [Inferred] Analyze related code (`order_router.py`, `export_use_case.py`)
- [ ] Reproduce error and identify root cause

**[Tasks]**
- [ ] [Inferred] Fix the bug
- [ ] Write acceptance test

**[Post]**
- [ ] Verify acceptance test passes
- [ ] Commit & Push
- [ ] Create PR
- [ ] Record in `tasks/CHANGESETS.md`

## 5. Scenarios (BDD)

### Scenario 1: Order list Excel download succeeds
```gherkin
Given order data exists and user is logged in
When GET /orders/export is called
Then response 200, Excel file is downloaded
And the file contains order data
```

## 6. Acceptance Criteria
- [ ] Scenario 1 acceptance test passes
- [ ] No regression in existing tests

## 7. References
### Related Code (Optional)
- [Inferred] `app/interfaces/order/order_router.py` - Order API
- [Inferred] `app/use_cases/order/export_use_case.py` - Excel export logic

## 8. Ticket-Specific Constraints (Optional)
- (none)

## 9. Evidence
| CS | Proof |
| :--- | :--- |

## 10. Notes
- Need to verify bug reproduction conditions
- Check recent deployment history
```
