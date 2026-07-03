# @hotfix — Hotfix Template

Use this tag for production emergencies requiring immediate fix.

## Required Sections

- **Summary**: Production impact, affected users/systems, urgency
- **Scenario**: At least 1 Given-When-Then (reproduction)
- **Regression Test**: MANDATORY — proves the bug is fixed

## Shortened Process

Hotfix follows a **fast-track** flow — full BDD/TDD cycle is skipped.

1. Create ticket (minimal: Summary + 1 Scenario)
2. Branch: `hotfix/T-{Project}-{ID}--{desc}` from production branch (check repo CLAUDE.md or fleet.yaml `branch`)
3. Write regression test that reproduces the bug
4. Fix the bug (minimal scope — fix only, no refactoring)
5. Verify: regression test passes + existing tests don't break
6. PR to production branch → deploy → verify in production
7. Post-deploy sync per repo's git strategy (e.g., rebuild stage, merge to integration branch)

## Implementation Plan Pattern

```
### CS-01: Hotfix

#### [Pre]
- [ ] Production impact assessed
- [ ] Branch created from production branch (check repo CLAUDE.md or fleet.yaml `branch`)

#### [Tasks]
- [ ] IP-01: Regression test (reproduces the production bug)
- [ ] IP-02: Minimal fix (Green)
- [ ] IP-03: Verify existing tests pass

#### [Post]
- [ ] PR to production branch
- [ ] Deployed and verified in production
- [ ] Post-deploy sync per repo's git strategy
```

## Commit Convention

```
🚑 hotfix: {short description of production fix}
```

## Checklist

- [ ] Fix is minimal scope (fix ONLY, no cleanup)
- [ ] Regression test written
- [ ] PR targets production branch (check repo CLAUDE.md or fleet.yaml)
- [ ] Deployed and verified in production
- [ ] Post-deploy sync completed per repo's git strategy
