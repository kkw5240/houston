# @refactor — Refactoring Template

Use this tag when restructuring code without changing behavior.

## Required Sections

- **Summary**: What is being refactored and why (tech debt, readability, performance)
- **Scope**: Exactly which modules/files are affected
- **Invariant**: What behavior must NOT change

## Implementation Plan Pattern

```
### CS-01: Refactoring

#### [Pre]
- [ ] Existing tests pass (baseline Green)
- [ ] Document current behavior as invariant

#### [Tasks]
- [ ] IP-01: Refactor {target module/pattern}
- [ ] IP-02: Verify all existing tests still pass
- [ ] IP-03: Update docs if structure changed

#### [Post]
- [ ] All existing tests still green (zero behavior change)
- [ ] PR created and linked
```

## Commit Convention

```
♻️ refactor: {short description of structural change}
```

## Checklist

- [ ] NO behavior changes (input/output identical)
- [ ] Existing tests pass before AND after
- [ ] No new features mixed into the refactoring
- [ ] Docs updated if module structure changed
