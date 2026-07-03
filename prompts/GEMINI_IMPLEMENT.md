# Gemini Implementation Prompt Template

> Houston 티켓 기반 구현을 Gemini에게 위임할 때 사용하는 프롬프트 템플릿.
> 구현 완료 후 Claude에서 code-review + merge 진행.

---

## 사용법

1. Worktree 생성 (수동 또는 Houston CLI)
2. Worktree 디렉토리에서 Gemini CLI 실행
3. 아래 프롬프트를 Gemini에게 전달
4. 구현 완료 후 PR 생성까지 Gemini가 수행
5. Claude에서 PR 리뷰 → merge

---

## Base Prompt (공통)

```
You are implementing a Houston ticket in a Python/FastAPI project.
Follow the ticket's Implementation Plan EXACTLY — do not skip steps, do not add features beyond scope.

## Critical Rules

1. **Docs-First**: Update design docs BEFORE writing any code. The [Pre] section lists exactly which docs to update.
2. **BDD/TDD**: Write acceptance tests FIRST (Red), then implement (Green). Section 5 has the Gherkin scenarios — map each to exactly 1 test function.
3. **Pre-commit**: Run `poetry run pre-commit run --all-files` before committing. Fix any failures.
4. **Commit format**: `{emoji} {type}: {description}` with `Co-Authored-By: Gemini <noreply@google.com>` trailer.
5. **PR format**: `gh pr create --base {BASE_BRANCH} --title "..." --body "Refs org/all_issue#{ISSUE_ID}"` — Use `Refs`, NOT `Closes` or `Fixes`.
6. **No scope creep**: Implement ONLY what the ticket specifies. Do not refactor adjacent code, add comments to unchanged code, or "improve" anything outside scope.
7. **Clean Architecture**: Follow the project's layer structure. Business logic in Use Case only. No business logic in Router or Repository.
8. **Error handling**: Use the project's exception pattern (see repo CLAUDE.md), not raw HTTPException.

## Execution Order

1. Read the repo's CLAUDE.md first — it has build/test/lint commands, git strategy, and code conventions.
2. Follow the ticket's [Pre] → [Tasks] → [Post] in strict order.
3. Each IP (Implementation Plan item) in [Tasks] is a discrete step. Complete one before starting the next.
4. After all [Tasks], run the [Post] checklist item by item.
5. Create PR when all [Post] checks pass.

## What NOT to Do

- Do NOT modify files outside the ticket's scope.
- Do NOT skip the acceptance test step (IP-01 in most tickets).
- Do NOT use `Closes` or `Fixes` in PR body (it auto-closes the GitHub issue).
- Do NOT push to `source/` — you should be in a worktree.
- Do NOT commit without running pre-commit.
- Do NOT add type annotations, docstrings, or comments to code you didn't change.
```

---

## Per-Ticket Prompt Format

```
## Ticket

Read the Houston ticket at: `{TICKET_FILE_PATH}`
This is your SOLE source of truth for what to implement.

## Repository

- Working directory: {WORKTREE_PATH}
- Repo CLAUDE.md: Read it first for build/test/lint commands and conventions.
- Base branch: {BASE_BRANCH}
- PR target: {BASE_BRANCH}

## GitHub Issue

{GITHUB_ISSUE_URL}

## Start

Begin with the ticket's [Pre] section. Execute each step in order.
When you reach [Tasks], implement IP-01 first (acceptance tests), confirm they fail, then proceed to IP-02 and beyond.
After all tasks, run the [Post] checklist.
Finally, create the PR.
```
