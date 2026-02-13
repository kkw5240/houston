# Ticket Execution Prompt

Use this prompt to request an AI agent to execute a created ticket.

---

## Prompt Template

### Basic (Full Ticket Execution)
```
T-{ProjectCode}-{IssueID} — execute this ticket.
Follow the workspace/README.md process.
```

### Partial Execution / Session Resume

Use when a session was interrupted or only specific work needs to be done.

```
# Start from a specific CS
T-{ProjectCode}-{IssueID} — start from CS-02.

# Start from a specific IP within a CS (useful for session resume)
T-{ProjectCode}-{IssueID} — resume from CS-01 IP-03.
```

**Terminology:**
- **CS (Change Set)**: Work group unit ([Pre] → [Tasks] → [Post] structure)
- **IP (Implementation Plan item)**: Individual task item within a CS's [Tasks] section

---

## Examples

### Full Ticket Execution
```
T-XX-100 — execute this ticket.
Follow the workspace/README.md process.
```

### Session Resume (from specific IP)
```
T-XX-100 — resume from CS-01 IP-03.
# → Resumes from the 3rd task item in CS-01
```

### Execute Specific CS Only
```
T-XX-100 — execute CS-02 only.
# → Runs CS-02 from [Pre] through [Post]
```

---

## AI Agent Notes

When executing a ticket, follow this order:

1. **Checklist**: Check Houston Session Checklist (required)
2. Read `workspace/README.md` (process rules)
3. Read ticket file (`tickets/T-{ProjectCode}-{IssueID}-*.md`)
4. Execute Implementation Plan in order
   - CS order: CS-01 → CS-02 → ...
   - Within each CS: [Pre] → [Tasks] → [Post]
5. Update `tasks/CHANGESETS.md` on completion

### Session Resume

1. Check ticket Evidence section for last completed CS
2. Check `tasks/CHANGESETS.md` for current status
3. Resume from the interrupted point
