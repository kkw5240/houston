# @bug-fix — Bug Fix Template

Use this tag when creating tickets for bug fixes.

## Required Sections

- **Summary**: Bug symptom, reproduction steps, expected vs actual behavior
- **Scenario**: At least 1 Given-When-Then (reproduction scenario)
- **Regression Test**: `tests/regression/test_T_{PROJECT}_{ID}.py` is MANDATORY

## Implementation Plan Pattern

```
### CS-01: Bug Fix

#### [Pre]
- [ ] Read related code and identify root cause
- [ ] Verify bug reproduction (manual or automated)

#### [Tasks]
- [ ] IP-01: Write regression test that reproduces the bug (Red)
- [ ] IP-02: Implement fix (Green)
- [ ] IP-03: Verify no side-effects on related modules

#### [Post]
- [ ] All tests green (regression + existing)
- [ ] PR created and linked
```

## Commit Convention

```
🐛 fix: {short description of what was fixed}
```

## Checklist

- [ ] Root cause identified and documented in ticket
- [ ] Regression test written BEFORE fix
- [ ] Fix is minimal scope (no refactoring mixed in)
- [ ] Side-effect check completed
