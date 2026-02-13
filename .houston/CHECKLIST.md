# Houston Session Checklist

Run through this checklist every time you start a new task or resume work.

## [PRE] Before Starting Work

- [ ] **Working from Houston root?** — Always launch your AI agent from the Houston workspace root directory, not from inside a ticket workspace. Houston rules and fleet.yaml are only accessible from the root.
- [ ] **Requires a ticket?** — If the task produces NO code/doc changes (questions, troubleshooting, code review, exploration), skip the full process and respond directly
- [ ] **Ticket exists?** — `tickets/T-{Project}-{IssueID}.md` is present
  - If NO ticket exists: create one first using `prompts/CREATE_TICKET.md`
  - If `tickets/` directory doesn't exist: `mkdir -p tickets/`
- [ ] **Task Board updated?** — Ticket registered in `tasks/TASK_BOARD.md`
  - If `tasks/TASK_BOARD.md` doesn't exist: create it with the ticket as first entry
- [ ] **Repo-per-Ticket?** — Check `.houston/fleet.yaml` for target repo path, then create workspace (NOT in `source/`)
- [ ] **Branch created?** — `feat/T-{Project}-{ID}--CS-{Seq}` from base branch (check fleet.yaml `branch` field)
- [ ] **Resuming?** — If resuming, check ticket Evidence section + CHANGESETS.md for last completed CS/IP
  - Run `git fetch origin` and check if base branch has new commits
  - If outdated: `git merge origin/{base}` or `git rebase origin/{base}` before continuing

## [DURING] While Working

- [ ] **Change Set created?** — New row in `tasks/CHANGESETS.md` (Status: WIP)
- [ ] **Docs first?** — Design docs or ticket scenarios updated BEFORE coding.
  - Houston ticket: scenarios and acceptance criteria.
  - Service repo `docs/`: domain docs, API specs, business rules affected by this change.
  - Fast-track OK only if the change adds nothing new (typo, config, bug fix within existing design).
  - Fast-tracked? → Complete all docs before Done.
- [ ] **Test first?** — Acceptance tests written (Red) BEFORE implementation
- [ ] **Regression test?** — If Bug Fix ticket, regression test written (`tests/regression/`)
- [ ] **One repo focus?** — Modifying only one repository at a time

## [POST] After Completing a Change Set

- [ ] **Evidence recorded?** — PR link or commit hash in `tasks/CHANGESETS.md`
- [ ] **Tests green?** — All acceptance tests passing
- [ ] **No regressions?** — Existing tests still pass
- [ ] **Lint passed?** — Run repo's lint/format checks.
  - Check repo CLAUDE.md for specific commands.
  - If no repo CLAUDE.md: check fleet.yaml `stack` field, explore repo config files (.pre-commit-config.yaml, Makefile, etc.)
- [ ] **Catch-up done?** — If you fast-tracked any [PRE]/[DURING] items, complete them now.
- [ ] **Commit message correct?** — Uses `{type}: {description}` format with `Co-Authored-By`
