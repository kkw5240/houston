# @feature — New Feature Template

Use this tag when creating tickets for new functionality.

## Required Sections

- **Summary**: What the feature does, business context, user impact
- **Scenarios**: 1-5 Given-When-Then scenarios (complexity-dependent)
- **Acceptance Tests**: One test per scenario (strict 1:1 mapping)

## Implementation Plan Pattern

```
### CS-01: Feature Implementation

#### [Pre]
- [ ] Design docs updated (Houston ticket + repo docs/)
- [ ] Acceptance tests written from scenarios (Red)

#### [Tasks]
- [ ] IP-01: Implement domain/business logic
- [ ] IP-02: Implement API/controller layer
- [ ] IP-03: Integration testing

#### [Post]
- [ ] All acceptance tests green
- [ ] No regressions in existing tests
- [ ] PR created and linked
```

## Commit Convention

```
✨ feat: {short description of new feature}
```

## Checklist

- [ ] Design docs written BEFORE code
- [ ] Acceptance tests written BEFORE implementation
- [ ] BDD scenarios cover happy path + edge cases
- [ ] API specs documented (if applicable)
- [ ] Side-effect check completed
