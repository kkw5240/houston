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
| Houston `tickets/` | Intent: what to build and scenarios; completion proof lives in §9 Evidence + `tasks/CHANGESETS.md`, not §4/§6 checkboxes | Houston |
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

## External PR Handling

When a PR is created, reviewed, and merged by **someone other than the Houston Mission Operator** (e.g., another developer's PR that the Operator only deploys/verifies), do NOT add it to `tasks/CHANGESETS.md` or `tasks/TASK_BOARD.md`. Those boards track work the Operator owns end-to-end.

**Rationale**
- A Change Set has a Pre/Tasks/Post lifecycle (Draft → WIP → Review → Staged → Done). A pure deployment of someone else's merged code does not match this lifecycle.
- Operator confirmed this policy on 2026-05-04 (PR #NNN, business card template integration by an external contributor).

**What to record instead**

If a Houston ticket exists for the work:

1. **Status** → `Done` (when merged + verified)
2. **Header table** → add `Implementer` field with the external author and PR link
   ```
   | **Implementer** | an external contributor (외부, PR #NNN) |
   ```
3. **Section 9 Evidence** → record PR/migration/deployment results
4. **Section 10 Notes** → state explicitly that CHANGESETS is intentionally empty for this Epic/ticket because the work was external
5. **CHANGESETS.md / TASK_BOARD.md** → leave untouched

If no ticket exists, no Houston-side bookkeeping is required beyond a brief note in the deployment evidence (e.g., Slack thread, follow-up docs PR).

**Houston work the Operator can still do for an external PR**
- Run the deploy itself (test → prod sequencing, ECS update, smoke verification)
- Post Slack notifications to internal channels
- Open follow-up docs PRs (history, design docs, db_models updates) in the affected repo
- Update related tickets' Evidence sections

---

## Key Terminology: CS & IP

These terms are used daily. You MUST understand them.

| Term | Full Name | What It Is |
|:---|:---|:---|
| **CS** | Change Set | A work group unit. Each CS has [Pre] → [Tasks] → [Post] phases. |
| **IP** | Implementation Plan item | An advisory WIP TODO item within a CS's [Tasks] section; not completion evidence. |

**Examples of user commands:**
- `"T-XX-100 처리해줘"` → Execute entire ticket, all CS in order.
- `"T-XX-100의 CS-02부터 진행해"` → Start from Change Set 02.
- `"T-XX-100의 CS-01 IP-03부터 진행해"` → Resume from the 3rd task item in CS-01.

Ticket §4 IP items = advisory WIP TODO, not completion evidence; ticket Status enum = `Draft|Active|Hold|Done`.

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

<!-- SKILL:houston-blocker:START -->
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
<!-- SKILL:houston-blocker:END -->

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

## tmux Pane Delivery Rule

Direct `tmux send-keys` is **disallowed**. All pane delivery must go through
`scripts/tmux-send-verified.sh`, which implements the contract
`paste → Enter → capture → ACK/readiness check → retry Enter once → fail (exit 75)`.

- Wrapper invocation: `scripts/tmux-send-verified.sh <session:window> <prompt-file> [--profile launch|message] [--agent claude|codex|gemini]`
- `--agent` (T-HOU-013) loads `ack_regex` from `.houston/agent-profiles.yaml`. Default = claude; missing/unreadable profile falls back to the built-in claude regex
- The wrapper pastes payload via `tmux load-buffer FILE` + `tmux paste-buffer -d -r` — stdin-safe, no argv "command too long" limit, byte-preserving (LF stays LF, no CR conversion). Self-advertises `HOUSTON_TMUX_SEND_VERIFIED=1` to bypass its own guard hook
- Enforcement: `.claude/settings.json` PreToolUse hook (`scripts/houston-tmux-guard.sh`) blocks any Bash call that starts a `tmux send-keys` command. Strings that merely *contain* `tmux send-keys` inside quoted echo/heredoc/markdown-inline-code are stripped before matching, so they are allowed
- Emergency override: `export HOUSTON_TMUX_SEND_VERIFIED=1` (must be exported in the parent shell — prefix-style `HOUSTON_…=1 <cmd>` does not work because the PreToolUse hook reads its env at fork time). For one-off recovery only, never as a normal path

---

## Mission Self-Kill Gate

A node may **not** kill *itself* (its own session, or its own window/pane). But a
node **owns its direct children's lifecycle** — it **may and must** tear down its
own child windows/panes after its kill-time checklist passes, **without any
override**. (Mission Control, the apex, is never killed.)

**What is blocked vs allowed** (window-scoped — T-HOU-029 CS-02b / SCRIPT-01):

| Command | Target | Verdict |
|:---|:---|:---|
| `tmux kill-session` | caller's **own** session | **blocked** (self-kill) |
| `tmux kill-window` / `kill-pane` | caller's **own window** (same session AND same window index) | **blocked** (self-kill) |
| `tmux kill-window` / `kill-pane` | a **different window** in the caller's own session (= a **child** node) | **allowed** — normal parent→child teardown, **no override** |
| `tmux kill-session` / `kill-window` / `kill-pane` | a **different session** (parent kills child session, MC sibling clean-up) | **allowed** |
| `tmux kill-server` | (whole server, incl. apex `houston`) | **blocked UNCONDITIONALLY** — never a valid agent action; **must never be weakened** |

- Enforcement: the PreToolUse hook (`scripts/houston-tmux-guard.sh`) is **window-scope 2-factor** for `kill-window`/`kill-pane` (own session AND own window index ⇒ block; a different window ⇒ allow). A target whose window can't be resolved (pane-id `%5`, window-id `@2`, malformed) is blocked **fail-safe**. Numeric window indices are compared numerically (`own:01` == own window `1`). `kill-server` is blocked unconditionally by a separate rule.
- Because a parent can now teardown its own child windows directly, **Mission Control does not reach in** to reap a child's descendants — each parent owns its children's launch **and** teardown.
- Emergency override `HOUSTON_FORCE_SELF_KILL=1` exists for **self**/**session**/`kill-server` only (stuck panes the parent cannot otherwise reach). **Caveat**: it must be exported in the caller's shell — it **cannot** be set from an agent's per-call command env (the hook reads its env at fork time, so a `VAR=1 <cmd>` prefix does not reach it). This is *why* legitimate child teardown must not depend on the override, and does not (it is allowed outright).

---

## Parent-Child Chain Enforcement

Every Houston node records its lineage in the launch manifest
(`.omx/logs/tmux-safe-<session>.manifest`, schema v3) so the parent can
verify ownership before kill, orbit lint can detect orphans, and
`houston-orbit.sh tree` can render the mission tree.

Manifest fields (driven by env vars / launcher flags at launch). Full spec:
`.houston/templates/manifest-v3-schema.yaml`.

| Field | Env var / flag | Default | Purpose |
|:---|:---|:---|:---|
| `parent_session` | `HOUSTON_PARENT_SESSION` | empty | immediate **launch** parent (kill-ownership) |
| `parent_window` | `HOUSTON_PARENT_WINDOW` | empty | parent window index |
| `parent_role` | `HOUSTON_PARENT_ROLE` | empty | direct-parent archetype: `mission_control` (apex) / `crew` (coordinator). Crew-class aliases (`flight_deck`/`flight`/`program`/`mission`) also accepted |
| `self_role` | `HOUSTON_SELF_ROLE` | `crew` | lifecycle **archetype** (NOT tree depth — depth derives from `parent_mission`, never stored): `mission_control` (apex `houston`) / `crew` (coordinator, owns direct children) / `probe` (bounded leaf). Crew-class aliases (verbatim, permanent): `mission` / `flight_deck` / `flight` / `program` |
| `intent_kind` | `HOUSTON_INTENT_KIND` | `short_running` | `short_running` / `long_running` / `pinned` (orbit-lint threshold) |
| `objective` | `HOUSTON_OBJECTIVE` | session name | free-form summary used by orbit/list output |
| `parent_mission` (v3) | `HOUSTON_PARENT_MISSION` / `--parent` | = `parent_session` | **tree-edge** parent for `houston-orbit.sh tree` |
| `mission_family` (v3) | `HOUSTON_MISSION_FAMILY` / `--family` | empty | effort grouping label (siblings cluster in the tree) |
| `lifecycle_phase` (v3) | `HOUSTON_LIFECYCLE_PHASE` | `active` | `active` / `closed` / `idle` / `orphan` (tree status) |

`houston orbit tree` derives displayed liveness from live `tmux ls`; stored `lifecycle_phase` is an advisory hint, not liveness truth.

**Kill-time checklist** — run by the **owning node (direct parent)** before killing each direct child. Applies to **any node that has children, at any tree depth** (a Crew owning sub-Crews or Probes):

1. **Objective achieved** — manager reviews the child's Flight Report / Probe Telemetry against acceptance criteria
2. **Knowledge documented** — new facts / decisions / trade-offs are in the appropriate doc / ticket / memory
3. **Worktree clean** — `scripts/houston-clean-check.sh <session>` returns exit 0 (no uncommitted, no untracked, no unpushed)

If any item fails the manager re-tasks the child and re-reads. Only after all three pass does the manager kill.

**Teardown is post-order (deepest leaves first)**: the deepest Probes are killed and cleaned first; each parent then kills its now-clean direct children; teardown propagates upward until Mission Control kills the top-level mission. A Crew cannot be killed until all of its children are killed and clean (the worktree clean-check enforces this).

v1/v2 manifests written before a field existed lack it; orbit tooling treats missing fields as defaults (`intent_kind=short_running`, `self_role=crew`, `parent_mission`=`parent_session`, `lifecycle_phase` inferred from live state). `scripts/houston-orbit-bootstrap.sh` migrates v1/v2 manifests forward to v3 in place (field-preserving, `.bak` backups, dry-run default).

### Node Archetype & Designation (depth-unlimited tree)

The Houston mission tree is **depth-unlimited**. A node is defined by two
**orthogonal** axes (RFC-HOU-TREE-UNLIMITED-001):

- **Archetype (character — stored in `self_role`, depth-independent)**:
  - **Crew** (🧑‍🚀) — an interactive, long-running coordinator. It **owns its direct
    children** (launch / kill / cleanup / receives their reports) and may itself be a
    child of another Crew. Crews nest to **any depth**: `Crew → Crew → … → Probe`.
  - **Probe** (🔬) — a bounded leaf work unit; may be one-shot; returns Telemetry.
  - **Mission Control** (🛰️ `houston`) is the unique **apex** — `self_role=mission_control`,
    identified by name, parentless, un-killable, and never owns execution (it keeps the
    Mission Control carve-out: no commits / pushes / reviews / cleanup).
  - (Crew generalizes the former Flight role; Probe is unchanged. The former
    `mission` / `flight_deck` / `flight` / `program` values are permanent **Crew-class
    aliases** — they still render and nest, just no longer a closed tier.)
- **Designation (position — NOT stored, derived at render)**: `houston-orbit.sh tree`
  prefixes each node with a dotted coordinate (`1`, `1.1`, `1.1.1`, …) computed from
  `parent_mission` edges. **Point-count = depth; prefix = parent lineage.** It is never
  stored, so re-parenting never produces stale positions (no drift). Exact coordinates
  appear only in the tree output; standalone references use the **placement** name
  (Program / Mission / Flight Deck / Flight) for coarse position.

> **No-drift invariant**: tree position is never written to a manifest or session name —
> `parent_mission` is the single source of truth and the coordinate is computed each render.

### Program (a named Crew placement — family coordinator)

When a single `mission_family` has **≥2 simultaneously-live leaf missions** (and
future waves are expected), Mission Control SHOULD NOT own each leaf directly —
each node talks only to its direct parent / direct children. A **Program** — a
`long_running` **Crew** whose direct children are the family's sibling missions —
coordinates them. It is **one named placement of the generic Crew archetype**, not a
new tier: a Crew may itself parent other Crews (a Program above a Program) to any
depth. (Flight Deck = a Crew whose children are within one mission session; Program =
a Crew whose children are sibling missions.)
(Source: RFC-HOU-FLEETDECK-001, `docs/projects/Houston/fleet-deck-rfc/`; generalized by
RFC-HOU-TREE-UNLIMITED-001.)

- A Program **is a Crew** (`self_role=crew`; the `program` value remains a valid
  Crew-class alias) with `intent_kind=long_running` and a `mission_family` label. Leaf
  missions set `parent_mission=<Program session>`. **No manifest schema change** — a
  launch convention over existing v3 fields. It is **not a separate tier**: it is one
  named placement of the generic Crew archetype — the same depth-unlimited
  parent-child chain, applied across sibling missions instead of within one.
- Owns, within the approved family scope: leaf launch/kill/worktree cleanup, leaf
  PR review·merge **lifecycle** supervision (repo-specific merge/lint stays with
  each leaf's own repo CLAUDE.md — one-repo-focus per CS), family status
  aggregation + milestone report to MC, and adjacent same-domain audit launches.
- **Instantiation trigger** (2-prong):
  - *Primary (concurrency)*: the moment a **2nd concurrent live leaf** appears in a
    `long_running` family. Sequential families (≤1 concurrent leaf) stay under
    MC-direct / batch reporting regardless of total count.
  - *Secondary (high-touch override)*: even at concurrency 1, if MC's direct serial
    per-leaf supervision (launch/kill/cleanup/PR-lifecycle) of a long-lived,
    high-frequency leaf is sustained, MC MAY escalate to a Program. Load =
    concurrency × per-leaf supervision frequency × duration.
  - *Detection is manual*: no tool counts concurrent live leaves. MC reads
    `houston-orbit.sh tree` and counts 🟢-live leaves sharing a `mission_family`.
    The trigger is MC operating discipline, not an enforced gate.
- **Promotion / migration**: when the trigger fires for a family that started under
  MC, **MC** spawns the Program and re-points existing leaves' `parent_mission` to
  it. Promotion is itself an MC-confirm action.
- **Escalation**: actions *widening* the approved family scope — new family, new
  repo/service/domain, **production deploy**, leaf-initiated sub-family, cross-family
  re-parent, Program scope saturation (split / sub-coordinator) — require ROOT
  (MC/Commander) confirm. Actions *within* scope are Program autonomy. Sibling
  Programs do NOT communicate laterally; cross-family dependencies escalate to MC.
- **Death/unresponsive — detection signal + liveness gate**:
  - A *dead* Program does **not** orphan-flag its leaves: its `.manifest` persists on
    disk so `houston-orbit.sh` keeps `known[coord]` true. The detectable signal is the
    **asymmetry in `houston-orbit.sh tree`** — the Program shows `live=0` (⚪ idle /
    ✅ closed, absent from `tmux ls`) while its leaves are still 🟢 active. (The
    🟠 orphan flag only fires if the Program's manifest is *also* deleted.)
  - A *live-but-stuck* Program has no automated signal — MC judgment on stalled
    milestone reports / ACKs.
  - **Liveness gate**: MC may adopt leaves only after the Program is **confirmed
    dead** (absent from `tmux ls`) OR after a **bounded unresponsiveness window +
    explicit demotion**. The window has no automated measure (no last-ACK timestamp
    is recorded) — it is an MC-discretion heuristic (e.g. "no milestone report / ACK
    for N hours"). Adoption re-points `parent_mission` atomically (optionally delete
    the stale manifest so the orphan branch self-cleans); a resumed Program must
    re-ACK topology before reclaiming any leaf.
- **Close-out**: a Program cannot self-kill (Self-Kill Gate). It reports family
  close-out to MC; MC runs the manager kill-time checklist (`houston-clean-check.sh`
  on each leaf + the Program) then kills.
- **30-day blind-spot**: a `long_running` Program is only weak-alerted by orbit-lint
  at 30 days. Record an explicit close-out owner / expected end-date in its
  `objective` or family meta-ticket so a stuck idle coordinator is not invisible.

---

## Mission Intent Kind

Mission lifetime is classified at launch so orbit lint can distinguish
intentional long-running missions from forgotten ones.

| Kind | Meaning | orbit-lint behavior |
|:---|:---|:---|
| `short_running` | normal mission (hours to a few days) | alert when age ≥ 5 days (default `HOUSTON_ORBIT_SHORT_DAYS`) |
| `long_running` | intentional multi-wave / repeated working session | weak alert only when age ≥ 30 days (default `HOUSTON_ORBIT_LONG_DAYS`) |
| `pinned` | explicit permanent (Mission Control, working sessions) | never alerted |

- Default at launch = `short_running`
- Reclassify a live mission: `scripts/houston-orbit.sh --mark <session> <kind>` (auto-creates a minimal v3 manifest if none exists)
- `long_running` does not bypass the manager kill-time checklist; it only changes when orbit lint nags

---

## Mission Tree Visibility

The flat `prefix + s` session list hides parent-child relationships. Houston
standardizes session naming, a role emoji lineage, and tmux session-description
options so the mission tree reads at a glance. The conventions below make the
raw tmux views (session list, status line, window names) legible immediately;
the machine-readable tree command `scripts/houston-orbit.sh tree` (and the
`prefix + T` tmux popup) consume them — see PROCESSES §9.4.

### Role emoji lineage

One emoji per node role — used in `houston-orbit.sh tree` (stdout), tmux window
names, and the session-description options below. The table below is the
**stdout** glyph set; tmux **window names** use a single-scalar **safe variant**
of it (ZWJ/VS16 glyphs corrupt the tmux status bar — see "Window name format"
below):

| Emoji | Role |
|:---|:---|
| 🛰️ | Mission Control (`houston`) — apex (`self_role=mission_control`) |
| 🧑‍🚀 | Crew — interactive coordinator at any depth (`self_role=crew`) |
| 🔬 | Probe (bounded leaf work unit) |
| 🚀 / ✈️ | Crew-class **aliases** during transition (`mission`/`flight_deck`/`program` → 🚀, `flight` → ✈️) |
| 🛏️ | Dock (parked/idle worktree node) |
| 🚑 | Hotfix mission |
| 🔵 | sub-mission (mission spawned under another mission) |

Tree depth/position is shown by the **designation coordinate** (`1`, `1.1`, …), not by
the glyph (see PROCESSES §9.4). The glyph conveys archetype only.

Tree status emoji (orthogonal to role; displayed liveness is derived from live `tmux ls`; stored `lifecycle_phase` is advisory):
🟢 active · ✅ closed · ⚪ idle · 🟠 orphan.

Notes on the role set (RFC-HOU-TREE-UNLIMITED-001):
- The canonical archetype value `crew` renders **🧑‍🚀** (`role_emoji()` returns it for
  `self_role=crew`). Depth is shown by the designation coordinate, not the glyph.
- **Name-based glyphs pre-empt the archetype glyph**: `role_emoji()` matches the session
  name first (`houston` → 🛰️, `*dock*` → 🛏️, `*hotfix*`/`hf` → 🚑) *before* the role
  check, so an apex / dock / hotfix node keeps its name glyph regardless of `self_role`.
- **Transition (option γ, adopted)**: the launcher default is now `crew`, so new nodes
  render 🧑‍🚀. Nodes that were already running at adoption keep their Crew-class **alias**
  glyphs (`mission`/`flight_deck`/`program` → 🚀, `flight` → ✈️) until they close; this
  is a one-line `role_emoji()` addition (it is **not** infra-change-free, but it is
  additive — alias glyphs are untouched). Long-running / pinned missions were converted
  to `crew` (and `houston` to `mission_control`) at adoption so they show the new glyph
  immediately; short-running ones age out within days.
- 🚑 remains a mission **flavor** (the node is still a Crew); 🔵 a sub-mission. Both are
  disambiguated by the `(family)` annotation, `intent_kind`, and the tree structure
  (children hanging beneath), in addition to the designation coordinate.

### Session naming convention

Session name = identity on disk and in tmux; once set, do not rename (drift
breaks ScheduleWakeup polling and orbit lookups — see
`.houston/templates/MISSION_PROMPT.md` §4 notes).

- Mission Control: fixed name `houston`.
- Mission / Flight Deck: `mission-<family>-<objective>-<YYYYMMDD>`
  (e.g. `mission-myproject-cache-backfill-sunset-20260602`). The `<family>`
  segment SHOULD match the manifest `mission_family` so siblings cluster.
- Flight Deck variant prefix `fd-` is also recognized.
- Program (family coordinator): same `mission-<family>-<objective>-<YYYYMMDD>`
  convention, where `<objective>` SHOULD signal the coordinator role (e.g.
  `...-program`). Its `mission_family` matches its leaves so the tree clusters them
  beneath it. (Pre-existing coordinators named `...-fleet-...` are grandfathered by
  the no-rename rule below.)
- Flights / Probes are normally **windows** inside the mission session; when a
  separate session is unavoidable, name it `<mission>-flight-<n>` /
  `<mission>-probe-<n>` and set its `parent_mission` to the owning mission.
- **Grandfathering**: sessions created before this convention (e.g. those
  without a `-<YYYYMMDD>` suffix, such as `mission-myproject-pptx-editor-fidelity`)
  are left as-is — the no-rename rule protects them. The convention applies to
  new launches; pre-existing sessions are migrated by setting their manifest /
  `@`-option lineage, not by renaming.

### Session-description tmux options

Each session SHOULD carry three tmux user options mirroring the v3 manifest
lineage fields, so live tmux views (status line, list, popups) can show the
tree without reading disk:

| tmux option | mirrors manifest field |
|:---|:---|
| `@parent_mission` | `parent_mission` |
| `@mission_family` | `mission_family` |
| `@lifecycle_phase` | `lifecycle_phase` |

Set on a live session:

```bash
tmux set-option -t <session> @parent_mission  <parent-session-or-empty>
tmux set-option -t <session> @mission_family  <family>
tmux set-option -t <session> @lifecycle_phase active   # active|closed|idle|orphan
# read back:
tmux show-option -t <session> -v @parent_mission
```

The manifest remains the source of truth for tooling (orbit lint, tree,
clean-check); the `@` options are a convenience mirror for raw tmux views. The
tree command MAY read the `@` options as a secondary live hint, but on any
disagreement the **manifest wins** — the mirror never overrides governance
truth. Migrating active sessions to set these options is a one-time manual step
(see PROCESSES §9.4).

### Window name format (launcher birth-form)

A mission is **born** into the mission-tree form: the launcher
(`scripts/houston-tmux-safe-launch.sh`, and `scripts/launch-leaf-worker.sh` for
leaf windows) applies the form automatically at launch, so the raw `prefix + s`
view and `houston-orbit.sh tree` are both consistent with **zero manual
retrofit**. The canonical tmux window name is:

```
<role-emoji> <objective>
```

- **`<role-emoji>`** — a single glyph from the single-source
  `houston_role_emoji_tmux()` (in `scripts/houston-lib.sh`).
- **single ASCII space** between glyph and objective.
- **`<objective>`** — the mission objective (`HOUSTON_OBJECTIVE`, default = the
  session name; for a leaf window, default = the worktree basename). Sanitized
  to a single line: any run of whitespace (space/tab/newline) collapses to one
  space, ends trimmed.
- **No designation number at *birth*.** The launcher writes `<glyph> <objective>`
  only — at launch it does not yet know the node's whole-tree coordinate.
- Example: `🚀 mission-houston-launcher-tree-birthform-20260606`, `🔬 T-XX-1213-L0-2-surface-map`.

**Coordinate prefix (added on demand by `relabel`, RC-2 re-examined — T-HOU-025).**
RFC-HOU-TREE-UNLIMITED-001 RC-2 originally kept the dotted coordinate *render-only*
(never in the window name) to avoid re-parent staleness. T-HOU-025 re-examined this:
the raw `prefix + s` list needs at least minimal numbering. The decision:

- `scripts/houston-orbit.sh relabel` recomputes every node's coordinate from
  `parent_mission` (+ live window) edges and rewrites each **live** window name to
  `<coord> <glyph> <objective>` (e.g. `5 🚀 mission-…`, `5.1 🔬 …CS-04-…`).
- **Session names are never touched** — the no-rename invariant holds. Only window
  names carry the coordinate.
- The coordinate in a window name is a **recomputed transient cache**, not stored
  truth. `relabel` strips any existing leading coordinate before re-applying, so it
  is idempotent.
- **Revised no-drift invariant**: no coordinate is stored in a *manifest* or a
  *session name*; `parent_mission` remains the single source of truth. The
  window-name coordinate is a cache whose staleness after a re-parent is bounded by
  re-running `relabel` (auto via the launcher hook + manual `houston orbit relabel`).
- The **apex `houston`** session's own windows (MISSION-CONTROL, dock-node) are left
  untouched by `relabel` (MC carve-out; they are not numbered tree nodes).

At launch the form also sets, on the session: `automatic-rename off` (so the
child process cannot clobber the name), the `@parent_mission` / `@mission_family`
/ `@lifecycle_phase` description mirror, and the pane title (= objective).

#### tmux-safe glyphs — why window names differ from the stdout tree

**tmux's status-line width calculation mis-measures multi-codepoint grapheme
clusters.** A ZWJ sequence — Crew `🧑‍🚀` = `U+1F9D1 U+200D U+1F680` — is counted
wider than the terminal renders it, so the window-status list overflows and the
status bar renders duplicated/wrapped (MC empirical finding 2026-06-06: a `🧑‍🚀`
window name duplicated the status bar 8×). Variation-selector glyphs (`U+FE0F`,
e.g. `🛰️ 🛏️ ✈️`) carry the same risk.

Therefore **tmux window-name glyphs MUST be single Unicode scalars — no ZWJ
(`U+200D`), no variation selector (`U+FE0F`).** `houston_role_emoji_tmux()`
wraps the stdout `houston_role_emoji()` and substitutes only the multi-codepoint
glyphs; single-scalar glyphs pass through unchanged. The orbit-tree **stdout**
keeps the full archetype glyphs (`🧑‍🚀` etc.) — stdout rendering is unaffected.

| Role / name | stdout tree | tmux window name |
|:---|:---:|:---:|
| Crew (`crew`) / Crew-class default | 🧑‍🚀 | **🚀** |
| Probe (`probe`) | 🔬 | 🔬 |
| Mission Control / `houston` (apex) | 🛰️ | **📡** |
| Dock (`*dock*`) | 🛏️ | **💤** |
| Hotfix (`*hotfix*`/`hf`) | 🚑 | 🚑 |
| `flight` alias | ✈️ | **🛫** |
| `flight_deck` alias | 🚀 | 🚀 |

The substitution is provably safe: every tmux-safe glyph is a single scalar with
no `U+200D`/`U+FE0F` byte (enforced by `scripts/test-houston-birthform.sh`). When
adding a new role glyph, verify by **launching a real session and checking the
status bar renders cleanly** — do not assume "single codepoint ⇒ safe."

### Window-children in the tree (G2 — T-HOU-025)

`houston-orbit.sh tree` reads the session graph from manifests, but a mission often
decomposes work into **windows inside its own session** (a Probe launched by
`launch-leaf-worker.sh`). Those windows are real nodes and must get a coordinate.

- A **live** session's window with **index ≥ 1** whose name (after stripping any
  leading coordinate) **begins with a recognized role glyph** is a **child node** of
  that session — coordinate `N` → `N.1`, `N.2`.
  - `index 0` is the session's own pane (it represents the session node itself; skip).
  - the glyph filter excludes ad-hoc shell windows (`bash`, `zsh`, …).
- Window-children exist **only when tmux is live** (windows are a tmux-runtime
  signal). This is complementary to T-HOU-024 (manifest = truth; tmux = one rich
  runtime) — both feed the one tree.
- The **apex `houston`** session's own windows are not numbered tree nodes (carve-out).

### Closed/dead node archiving (G4 — T-HOU-025)

Declutter of dead manifests is supported by `houston-orbit.sh archive`
(`[--days N] [--yes] [--dry-run]`). It is **reversible** (`mv` to `.omx/logs/archive/`,
excluded from the tree scan because the manifest glob is non-recursive).

- **Candidate** = a manifest that is ALL of: not-live (absent from `tmux ls`) AND
  `intent_kind=short_running` AND `age ≥ N` days (default `HOUSTON_ORBIT_SHORT_DAYS`).
- **RETAIN — never auto-archive**: `live` | **ancestor-of-live** (a live descendant
  exists) | **child-of-live** (the parent session is live **and is not the apex
  `houston`** — every mission hangs under the always-live apex, so apex-parentage
  alone must not protect a node; a real live non-apex working parent does) |
  `long_running` | `pinned`. (apex exclusion: T-HOU-026)
- Default mode = list candidates → **human confirm** → `mv`. `--yes` skips confirm
  (CI / agent), `--dry-run` lists only.
- `omx-workspace-*` (OMX `exec` scratch — live, manifest-less) is not archivable; it is
  **filtered** from the tree/scan via `HOUSTON_ORBIT_IGNORE_RE` (default
  `^omx-workspace-`, overridable; empty disables).

---

## Work Distribution (Capacity-Bounded)

Houston tree 가 평평해 모든 보고·거버넌스 flush·결정이 Mission Control(apex) 단일
채널로 수렴하면 funnel(누락·과부하)이 된다. 분산의 지배 원리는 **capacity-bounded
재귀 분할**이다 (RFC-HOU-WORK-DISTRIBUTION-001).

### 지배 원리 — Capacity-Bounded Recursive Subdivision
- 모든 노드(leaf·Crew·MC)는 처리 **capacity** 가 있다: leaf=한 미션 작업 최대 크기,
  coordinator=누락 없이 감당할 직속 자식 + 결정·보고 채널 부하. capacity 초과의
  관측 신호 = "누락이 잦아지고 과부하".
- **overflow 일 때만 분할**(항상 분할 아님). 저부하면 MC 직접(노드 0 추가).
- **self-subdivision**: overflow 한 노드가 *스스로* leaf→Crew 로 승격, 하위 leaf 를
  만들어 자기 작업/역할을 쪼개 위임하고 자신은 조율자로 남는다. 재귀·depth 무제한.
  - 안전 접점: 자식 생성은 **이미 승인된 자기 작업의 in-scope 분해**(자율)이지
    **새 effort/family 생성**(=apex MC 전용)이 아니다. 자식을 만든 노드는 그 순간
    자식의 kill-checklist·worktree 소유 부모가 된다(단일부모 kill 모델 유지).
- FLEETDECK Program "동시 2건+" 트리거는 coordinator-capacity overflow 의 특수 사례.
  TREE-UNLIMITED depth-무제한 Crew 중첩이 이 분할의 기계장치.

### Tier-1 — 즉시 적용 (구조 無, MC 채널 부하를 capacity 아래로)
1. **자율성 임계 매트릭스** — 노드는 *스코프 내* 결정을 자율 수행, 내부 expert-review
   로 품질 확정 후 **최종 1개만** 상신(중간 iteration 반복 금지).
   - 노드 자율: 스코프 내 leaf launch/kill/kill-checklist/cleanup · 검증/내부
     expert-review/문서조립 · 상태 rollup→milestone 보고 · 샤드 write · 인접 동일-스코프
     회귀 audit.
   - **상위 에스컬레이션(직속 부모 먼저 — subsidiarity)**: 노드 단독판단 불가 결정
     (cross-스코프 의존·순서·모호)은 **직속 부모로 한 단계씩**, 필요한 만큼만 상위로.
     **apex 직행 금지.** 부모가 자기 직속 자식들을 가로질러 판단.
   - Commander 전용(불가분): 새 effort/family/미션 생성(=apex) · PR 머지 · 외부 발송
     (Slack/PM/GitHub) · PM/GitHub 상태 변경 · production 배포 · self-kill 금지.
2. **거버넌스 샤딩 L1** — CHANGESETS/TASK_BOARD 를 **소유자별 앵커 섹션**으로 구획,
   write 는 자기 앵커에 additive surgical insert(전체복사 금지). MC 가 여전히 flush,
   **leaf 는 push 안 함**. 동시편집 경합 제거.
3. **결정채널 빈도 감축** — *누가* 결정하느냐(머지·외부·prod·상태=Commander)는 불변,
   *얼마나 자주* 채널을 점유하느냐만 감축: (a) 결정 후보 배치 상신, (b) **이미 안전한
   부류만 사전위임**(docs-only PR · in-scope **non-prod**(dev/검증) 배포 · 동일-effort
   회귀 audit). 안전게이트 자체는 불변.
4. **MC 행동 규칙** — launch 전 recon 금지(목표+포인터+게이트만) · 중간 iteration 반복
   금지(미션 자기완결 후 최종 1회 컨펌) · flush 는 milestone cadence · 거버넌스 고도 유지.

### 결정도 capacity-bounded (subsidiarity)
결정도 capacity 가 있다. 노드는 자기 결정-용량 내는 스스로 처리, overflow(단독판단
불가)는 **한 단계 위 직속 부모로만** 올린다(apex 직행 ❌). 작업 overflow→self-subdivide
의 결정판 대칭. TREE-UNLIMITED '직속 상대 튜플' 모델과 정합. → 결정이 apex 로 다시
몰리지 않게 하는 C3 분산의 핵심.

### Tier-2 — DEFERRED (실측 capacity overflow 시에만)
상시 코디네이터 풀은 선례 비용모델상 순차 규모엔 시기상조(코디네이터는 동시 2건+
에서만 값어치; 바쁘든 idle 이든 MC watch/ACK/kill-checklist 비용 floor 존재).
**실측 capacity overflow**(동시성/누락 신호) 관측 시에만 capacity-overflow 재귀 분할
(Program/Crew verbatim 재사용). down-transition = **lazy run-to-natural-close**
(부하 떨어져도 능동 kill 0 → thrash 회피). `pm-management-v3`(자식 6)를 파일럿 계측.

## Shared-Root Flush (leaf-never-pushes)

공유 root(`~/workspace`)에서 **미션(leaf)은 push/commit 하지 않는다.**
미션은 inline 작업만 하고, origin/master flush 는 **Mission Control(또는 위임받은
coordinator tier)이 전담**한다(A-policy). 이유: 다수 미션 동시 inline 편집 + 단일
master ref → 미션이 직접 push 시 non-FF/clobber 위험(드리프트는 cosmetic, push 가
위험). (근거: `feedback_shared_root_drift_ops`, `reference_houston_mc_flush_drift_cosmetic`,
`reference_houston_shared_worktree_branch_drift`.)

## Architecture Default

All repositories in this workspace follow **Clean Architecture** unless their repo-level `CLAUDE.md` states otherwise.

```
Controller / Router  → Input/Output, HTTP handling
Service / UseCase    → Business logic
Repository           → Data access
Entity / Model       → Data structures
```

- Business logic MUST NOT exist in Controllers or Repositories.
- See `docs/ARCHITECTURE_STANDARDS.md` for full reference.

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
     - AGENTS.md
     - CLAUDE.md
     - .cursorrules
     - .windsurfrules
     - .github/copilot-instructions.md
     - .new-agent-config      # ← add here
   ```
2. Run `.houston/build.sh` — the new adapter is created automatically
3. Verify the new file contains the same Houston content as existing adapters
