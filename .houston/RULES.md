# Houston Rules

These rules are mandatory. They apply to every task, every session, every agent.

## 10 Golden Rules

1. **Repo-per-Ticket**: Never work in `source/`. Create a worktree in `T-{ID}` folder for isolation.
2. **Docs-First**: Update or create design docs BEFORE writing code.
3. **Source of Truth**: `tickets/` defines WHAT. `tasks/CHANGESETS.md` tracks STATUS.
4. **Hierarchy**: `README.md` > `docs/` > repo-level `CLAUDE.md`.
5. **BDD/TDD**: Write Acceptance Tests (Red) BEFORE implementation (Green).
6. **One Scenario = One Test**: Map each BDD scenario to exactly one acceptance test.
7. **Side-Effect Check**: Verify related modules are not broken before marking Done.
8. **No Skipping**: Do not skip verification steps, even under time pressure.
9. **No Guessing**: If requirements are ambiguous, ask the user. Do not assume.
10. **Pre-Commit**: Run lint and format checks before creating a PR.

## Documentation-First Principle

> "If you delete all code and rebuild from `/docs` alone, the result must behave identically."

Writing docs first IS designing. Code implements the design.
If you code first, docs become post-hoc descriptions — not blueprints.
That breaks the rebuild guarantee above.

- **Default**: Document BEFORE coding. Always.
- **Only exception**: Changes that add nothing new
  (typo, config value, bug fix within existing design).
  These may be coded first, but all docs must be completed before Done.
- If a design doc is missing or outdated, update it FIRST — before changing code.
- Documentation is Long-term Memory for AI agents. Treat it as critical infrastructure.

### What "Docs" Means

Documentation lives in TWO places. Both must be maintained.

| Location | What belongs there | Owner |
|:---|:---|:---|
| Houston `tickets/` | Intent: what to build, scenarios, acceptance criteria | Houston |
| Service repo `docs/` | Domain: how the service works, API specs, business rules, data models | Repo |

**Rebuild test**: Pick any service repo. Delete all code. Hand `docs/` to a new AI Agent.
Can it rebuild the service with identical behavior? If not, the docs are incomplete.

- If the repo has no `docs/` directory, use whatever documentation exists (README, wiki, inline comments). If nothing exists, create minimal design notes in the Houston ticket's Implementation Plan section.

## Evidence-Based Completion

> "Without proof, the status is NOT Done."

Every completed task MUST have:
- A commit hash or PR link recorded in `tasks/CHANGESETS.md`
- Acceptance tests passing (Green)
- No regressions in existing tests

## Context Priority Order

When entering a repository, read context in this order:

```
1. Houston workspace rules (this document)
2. Houston README.md (governance & process)
3. {repo}/CLAUDE.md (implementation patterns, if exists)
4. {repo}/docs/ (detailed specifications)
5. {repo}/README.md (basic project info)
6. Code patterns via search (last resort)
```

## Agent Execution Rules

1. **Read before doing**: Check Houston rules and repo docs before touching code.
2. **Write before coding**: Update design docs before implementation.
3. **Test before coding**: Write acceptance tests based on Ticket Scenarios first.
4. **Prove your work**: Capture evidence (commit, PR, test results) before marking done.
5. **One Repo Focus**: Modify only one repository per Change Set.

---

## Non-Code Work (Docs, Config, CI)

Some tasks don't involve application code. For these, the full BDD/TDD cycle is unnecessary.

**Criteria** — a task is "non-code" if it modifies ONLY:
- Documentation files (*.md, docs/)
- Configuration files (CI/CD, linter configs, env templates)
- Houston process files (.houston/, prompts/, tickets/)
- Infrastructure scripts (no business logic)

**Simplified flow for non-code tasks:**
1. ✅ Ticket — still required (even minimal)
2. ✅ Branch — still required
3. ❌ BDD Scenarios — not required
4. ❌ Acceptance Tests — not required
5. ✅ PR + Evidence — still required
6. ✅ Commit format — still required

> When in doubt whether a task is "non-code", apply the full process. Better safe than sorry.

**When NO ticket is needed at all:**

Some interactions don't produce deliverables. Skip the entire ticket/branch/PR process for:
- **Questions**: "이 코드 뭐야?", "이 API 어떻게 동작해?"
- **Troubleshooting**: "DB 연결 안 돼", "빌드 에러 도와줘"
- **Code Review**: "이 PR 리뷰해줘"
- **Exploration**: "이 모듈 구조 분석해줘"

Rule of thumb: If the task produces NO code change or document change, no ticket is needed.

---

## Key Terminology: CS & IP

These terms are used daily. You MUST understand them.

| Term | Full Name | What It Is |
|:---|:---|:---|
| **CS** | Change Set | A work group unit. Each CS has [Pre] → [Tasks] → [Post] phases. |
| **IP** | Implementation Plan item | An individual task item within a CS's [Tasks] section. |

**Examples of user commands:**
- `"T-XX-100 처리해줘"` → Execute entire ticket, all CS in order.
- `"T-XX-100의 CS-02부터 진행해"` → Start from Change Set 02.
- `"T-XX-100의 CS-01 IP-03부터 진행해"` → Resume from the 3rd task item in CS-01.

**Execution order within a ticket:**
```
CS-01 → CS-02 → CS-03 → ...
Each CS: [Pre] → [Tasks] (IP-01, IP-02, ...) → [Post]
```

---

## Session Resume Logic

When resuming interrupted work:

1. Read the ticket file (`tickets/T-{Project}-{ID}.md`)
2. Check the **Evidence** section — find the last completed CS
3. Check `tasks/CHANGESETS.md` — confirm current status
4. Resume from the next incomplete CS (or specific IP if specified by user)

---

## Commit Rules

> **Repo override**: 각 repo의 CLAUDE.md에 커밋 규칙이 정의되어 있으면 repo의 규칙을 따른다.
> 아래는 repo에 별도 규칙이 없을 때 적용되는 Houston 기본값이다.

**Message format:**
```bash
git commit -m "$(cat <<'EOF'
{emoji} {type}: {short description}

{body - optional}

Co-Authored-By: {Agent Name} <noreply@anthropic.com>
EOF
)"
```

**Commit types:**

| Emoji | Type | Purpose |
|:---|:---|:---|
| ✨ | `feat` | New feature |
| 🐛 | `fix` | Bug fix |
| 📝 | `docs` | Documentation only |
| ♻️ | `refactor` | Code refactoring (no behavior change) |
| ✅ | `test` | Adding or updating tests |
| 🔧 | `chore` | Build, config, CI changes (no business logic) |
| 🚑 | `hotfix` | Critical production fix |

---

## Blocker & Failure Handling

When you encounter problems, follow this protocol — do NOT silently retry forever.

| Situation | Action |
|:---|:---|
| **Test failure** | Fix and retry. After 3 failed attempts: record cause in ticket Notes, set ticket to Hold, report to user. |
| **Dependency blocker** | Record blocker details in ticket Notes, set ticket to Hold, update TASK_BOARD.md. |
| **Ambiguous requirements** | Use AskUserQuestion to ask the user. Do NOT guess. |
| **PR review rejected** | Incorporate feedback, fix, resubmit. |

**Common test failure troubleshooting:**

| Failure Type | Check |
|:---|:---|
| Import Error | Verify dependencies installed, check import paths |
| Assertion Error | Compare expected vs actual values, review logic |
| Timeout | Check async handling, adjust timeout values |
| DB Connection | Verify env vars, check DB server status |

---

## User Override Protocol

When the user's instruction conflicts with Houston rules:

1. **Explain the risk** — State which rule would be skipped and what could go wrong
2. **Respect the decision** — The user is the Commander. If they confirm after understanding the risk, proceed
3. **Record it** — Add a note in the ticket's Notes section: `⚠️ User override: {what was skipped and why}`

**Examples:**
- User: "테스트 안 써도 돼" → Explain: "Acceptance test 생략 시 regression 위험. 계속할까요?" → User confirms → Proceed + record
- User: "docs 업데이트 나중에 해" → Explain: "Documentation-First 규칙 위반. 나중에 잊을 수 있음." → User confirms → Proceed + record

> Never silently skip a rule. Never refuse a direct user instruction. Always explain, then comply.

---

## Status Definitions

```
Ticket:     Draft → Active → Done
                      ↓
                    Hold (blocked)

Change Set: Draft → WIP → Review → Staged → Done
```

| Status | Meaning |
|:---|:---|
| **Draft** | Planned, not started |
| **Active / WIP** | In progress |
| **Hold** | Blocked — blocker must be resolved first |
| **Staged** | Deployed to test server, awaiting production |
| **Done** | Complete — evidence (commit/PR) is REQUIRED |

---

## Architecture Default

All repositories in this workspace follow **Clean Architecture** unless their repo-level `CLAUDE.md` states otherwise.

```
Controller / Router  → Input/Output, HTTP handling
Service / UseCase    → Business logic
Repository           → Data access
Entity / Model       → Data structures
```

- Business logic MUST NOT exist in Controllers or Repositories.
- See `docs/standards/ARCHITECTURE_STANDARDS.md` for full reference.

**When no repo-level CLAUDE.md exists**, explore code patterns before writing:

1. Check `stack` field in `.houston/fleet.yaml` — adapt tools and file patterns to the repo's language/framework
2. Find similar endpoints/features by searching the codebase
3. Identify project structure: check top-level directory layout
4. Look for existing tests: check test directory structure and naming conventions
5. Check for shared utilities: search for common helper/util modules

---

## Adding New Agent Adapters

To generate an adapter for a new AI tool (e.g., a new IDE or CLI):

1. Add the output file path to `.houston/config.yaml` under `adapters:`
   ```yaml
   adapters:
     - CLAUDE.md
     - .cursorrules
     - .windsurfrules
     - .github/copilot-instructions.md
     - .new-agent-config      # ← add here
   ```
2. Run `.houston/build.sh` — the new adapter is created automatically
3. Verify the new file contains the same Houston content as existing adapters
