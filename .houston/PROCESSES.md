# Houston Processes

Summaries of core workflows. For full details, see `docs/processes/`.

---

<!-- SKILL:houston-ticket:START -->
## 1. Repo-per-Ticket Workflow

> Full doc: `docs/processes/WORKFLOW_REPO_PER_TICKET.md`

Each ticket gets its own **disposable workspace** — a git worktree from the source repo.

**Lifecycle**: Worktree & Spawn → Use → Verify → Destroy

```
workspace/{project}/
  source/              # Read-Only template (always synced to remote)
  T-{ID}-{desc}/       # Isolated ticket workspace (disposable)
```

**Finding the right repository:**

Before creating a ticket workspace, identify the target repo:
1. Check `.houston/fleet.yaml` — fleet manifest (which repos are docked)
2. Match project code to repo: BW → my-project, EH → another-project, etc.
3. Source path convention: `{project-folder}/source/` (read-only, always synced to remote)
4. If the repo is not listed or the path doesn't exist, ask the user.

Check if `scripts/houston` exists in the workspace. If yes, use the CLI. If not, use the manual fallback below.

### With Houston CLI (preferred)

```bash
# Create ticket workspace (project code lookup from fleet.yaml)
houston ticket <CODE> <TICKET_ID> [DESC]
# Example: houston ticket XX T-XX-100 feature-name
# → Syncs my-project/source to master (from fleet.yaml)
# → Creates my-project/T-XX-100-feature-name/
# → Branch: feat/T-XX-100--CS-01

# Close ticket workspace (after PR merge)
houston close <TICKET_PATH>

# Check fleet status
houston status --fetch

# Show project info
houston info <CODE>
```

You can also pass a direct path instead of a project code (backward compatible):
```bash
houston ticket ../my-project/source T-XX-100 feature-name
```

### Without Scripts (manual fallback)

If scripts are not available in the workspace:

```bash
# 1. Update source to latest
cd ../lines-{project}/source && git pull origin {base}  # {base} = fleet.yaml의 branch 필드

# 2. Create worktree (preferred) or copy
git worktree add ../T-{ID}-{description} -b feat/T-{Project}-{ID}--CS-01
cd ../T-{ID}-{description}

# 3. Work...

# 4. After PR merge — remove worktree
cd .. && git -C source/ worktree remove T-{ID}-{description}
```

**Key rules**:
- NEVER work directly in `source/`. It is read-only (main worktree).
- Folder naming: `T-{ProjectCode}-{IssueID}-{description}`
- Branch naming: `feat/T-{ProjectCode}-{IssueID}--CS-{Seq}`
- Always check for unpushed commits before removing ticket workspaces.

### Lifecycle Hooks

Houston supports lifecycle hooks that run automatically on workspace events:

- **on_ticket_start**: Runs after workspace creation (e.g., pip install, .env copy)
- **on_ticket_end**: Runs before workspace removal (e.g., cleanup)

Configure in `.houston/config.yaml` (global) or `.houston/fleet.yaml` (per-project override).
Hooks are non-blocking: failure prints a warning but does not abort the operation.

```yaml
# .houston/config.yaml
lifecycle_hooks:
  on_ticket_start: ".houston/hooks/on-ticket-start.sh"
  on_ticket_end: ".houston/hooks/on-ticket-end.sh"
```

### Multi-Repo Tickets

When a ticket spans multiple repositories (e.g., CS-01 = Backend, CS-02 = Frontend):

1. Each CS targets ONE repo — this is enforced by Golden Rule #5 (One Repo Focus)
2. When moving to a new CS in a different repo:
   - Complete current CS → record evidence in CHANGESETS.md
   - Create a new ticket workspace in the target repo: `T-{ID}-{desc}/`
   - Create a new branch: `feat/T-{Project}-{ID}--CS-{Seq}`
   - Continue with the new CS's [Pre] → [Tasks] → [Post]
3. The ticket file stays in Houston — it tracks ALL CS across repos

### Parallel Work (Sub-Issues / Independent Tasks)

When the user requests multiple tasks at once (e.g., sub-issues within one parent issue, or independent tickets):

1. **Each task gets its own workspace** — Repo-per-Ticket applies per task, not per session
   - Task A → `T-{ID-A}-{desc}/` + branch `feat/T-{Project}-{ID-A}--CS-{Seq}`
   - Task B → `T-{ID-B}-{desc}/` + branch `feat/T-{Project}-{ID-B}--CS-{Seq}`
2. **Same repo is OK** — multiple ticket workspaces can branch from the same `source/`
3. **No cross-contamination** — never mix changes from different tasks in one workspace
4. **Track separately** — each task gets its own CS row in `tasks/CHANGESETS.md`
5. **Evidence per task** — each task must have its own commit hash / PR link
6. **TASK_BOARD.md** shows parallel status — multiple items in "In Progress" is normal

> Parallel work is safe because Repo-per-Ticket guarantees physical isolation.
> If two tasks modify the same file, conflicts are resolved at PR merge time — not in the workspace.

**Priority decision criteria** (highest first):

1. **Hotfix / Production incident** — always top priority
2. **User-specified priority** — "A 먼저 해줘" etc.
3. **Blocker resolution** — unblocks another task's dependency
4. **Quick Win** — shortest time to completion
5. **FIFO** — when none of the above apply

When uncertain, ask the user.
<!-- SKILL:houston-ticket:END -->

---

<!-- SKILL:houston-test-strategy:START -->
## 2. Testing Strategy (TDD + BDD Hybrid)

> Full doc: `docs/PROCESS_TESTING.md`

**Core flow**: Scenario → Acceptance Test (Red) → TDD Implementation → Green → Commit

### Test Types

| Test Type | Purpose | When | Committed? |
|:---|:---|:---|:---|
| **Acceptance Test** | Prove requirements met | BEFORE coding (Red) | Yes |
| **Regression Test** | Prevent bug recurrence | When fixing bugs | Yes |
| **Unit Test** | Fast feedback, design aid | During coding | No (local only) |

### Acceptance Test Rules

- 1 BDD Scenario = 1 Acceptance Test function (strict 1:1 mapping)
- Use Given-When-Then format from ticket scenarios
- Minimize mocks — prefer real DB/API
- Validate inputs/outputs only — not implementation details
- Commit acceptance tests only; unit tests stay local

### Regression Test Rules

- **Bug Fix tickets: regression test is MANDATORY.**
- File naming: `tests/regression/test_T_{PROJECT}_{ISSUE_ID}.py`
- Purpose: reproduce the bug, then prove the fix prevents recurrence.
- Regression tests ARE committed (unlike unit tests).

### Test Requirements by Ticket Type

| Ticket Type | Acceptance Test | Regression Test |
|:---|:---|:---|
| New Feature | Required | — |
| Bug Fix | Case by case | **Required** |
| Refactoring | — | — |
| Docs / Config | — | — |

### Test Directory Structure

```
tests/
  acceptance/           # Committed — proves requirements met
  regression/           # Committed — prevents bug recurrence
  fixtures/             # Test data factories
  unit/                 # NOT committed — local dev only (.gitignore)
```
<!-- SKILL:houston-test-strategy:END -->

---

## 3. Git Conventions

Git 브랜칭 전략, 커밋 포맷, PR 규칙 등은 **각 repo의 CLAUDE.md에서 정의**한다.
Houston은 거버넌스(티켓, 증거, 프로세스)를 소유하며, 구현 컨벤션은 repo에 위임한다.

- `fleet.yaml`의 `branch` 필드가 해당 repo의 base branch를 결정한다.
- Repo CLAUDE.md가 없는 경우, 기본적으로 `fleet.yaml`의 `branch`에서 분기하고 같은 branch로 PR한다.

**Project codes**: EH (Another Project), BW (My Project), PS (Third Project), BF (Fourth Project), IM (Fifth Project), HOU (Houston)

<!-- SKILL:houston-hotfix:START -->
### Hotfix Fast Track

When the user declares a task as **Hotfix** (production emergency):

**Shortened process** — skip full BDD/TDD cycle:
1. Create ticket (minimal: Summary + 1 Scenario)
2. Branch from production branch (check repo CLAUDE.md or fleet.yaml `branch` field)
3. Write a **regression test** that reproduces the bug
4. Fix the bug (minimal scope — fix only, no refactoring)
5. Verify: regression test passes + existing tests don't break
6. PR to production branch → deploy → verify in production

**What is skipped**: Full BDD scenario suite, acceptance test-first cycle, docs-first update
**What is NOT skipped**: Ticket creation (minimal), regression test, PR, evidence recording

> The user must explicitly say "Hotfix" or "긴급" to trigger this track.
> If unclear, ask: "Is this a production emergency (Hotfix) or a normal fix?"
<!-- SKILL:houston-hotfix:END -->

---

## 4. Ticket & Change Set Model

**Ticket** (`tickets/T-{Project}-{ID}.md`): A unit of intent. 1 Ticket = 1 GitHub Issue.

**Change Set (CS)** (`tasks/CHANGESETS.md`): A logical group of changes within one repository.
- 1 Ticket can have multiple CS (e.g., Backend CS-01, Frontend CS-02)
- Each CS has internal structure: [Pre] → [Tasks] (IP items) → [Post]
- Status flow: Draft → WIP → Review → Staged → Done
- Evidence (commit hash / PR link) is REQUIRED to mark "Done"

**Task Board** (`tasks/TASK_BOARD.md`): Kanban view of all active work.

**Archive**: When CHANGESETS.md grows large, archive completed entries:
```bash
houston archive              # Archive Done entries older than 14 days
houston archive --days 30    # Custom cutoff (30 days)
houston archive --dry-run    # Preview without changes
```
- Archived entries move to `tasks/CHANGESETS_ARCHIVE_{YYYY}.md` (yearly files)
- Active file retains non-Done entries + recent Done entries
- Archive files are append-only (cumulative per year)

---

## 5. Work Phases (General Execution)

```
Phase 1: Context & Planning
  └── Read Houston rules → Read repo docs → Search code patterns

Phase 2: Documentation (Intent Alignment)
  └── Houston ticket: verify scenarios match intent
  └── Service repo docs/: update domain docs, API specs, business rules affected by this change

Phase 3: Acceptance Test First (Red)
  └── Read ticket scenarios → Write acceptance tests → Confirm they fail

Phase 4: Implementation (Red → Green)
  └── TDD for details → Follow repo patterns → Atomic commits

Phase 5: Evidence & Commit
  └── All acceptance tests green → Create PR → Record in CHANGESETS.md
```

---

## 6. Agent Communication Protocol

When reporting progress, follow this 4-stage interface:

| Stage | Output |
|:---|:---|
| **Plan** | Implementation plan — what you will do and in what order |
| **Edit** | Code changes + test code |
| **Verify** | Pass/fail evidence (test results, lint output) |
| **Done** | PR link + commit hash recorded in CHANGESETS.md |

---

<!-- SKILL:houston-daily-scrum:START -->
## 7. Daily Scrum (2-Step Process)

Daily Scrum은 **Sync**(데이터 정합성)와 **Report**(보고서 생성) 두 단계로 분리됩니다.

### Step 1: Sync — Houston <-> GitHub 동기화

- **Prompt**: `prompts/SYNC.md`
- **When**: Daily Scrum 전, 또는 데이터 정합성이 필요할 때 독립 실행 가능
- **What**: Houston 문서(TASK_BOARD, tickets, CHANGESETS)와 GitHub Issue 상태를 양방향 비교
- **Policy**:
  - GitHub → Houston: 자동 적용 (TASK_BOARD 갱신, ticket 메타데이터 동기화)
  - Houston → GitHub: Dry-run (제안 목록만 출력, 수동 처리)
- **Output**: Sync Report (제안 목록 + 자동 적용 결과 + 수동 확인 필요 항목)

### Step 2: Report — Daily Scrum 보고서 생성

- **Prompt**: `prompts/DAILY_SCRUM.md`
- **Path**: `daily_scrum/{YYYY}/{MM}/{YYYY.MM.DD}.md`
- **When**: Sync 완료 후, 또는 업무 시작 시
- **Prerequisite**: Step 1 Sync가 오늘 실행되었어야 함 (미실행 시 안내)
- **Content**: 금일 수행 업무, 익일 계획 (Priority Score 기반 정렬), Sync Summary, 특이 사항
<!-- SKILL:houston-daily-scrum:END -->

---

## 8. Ticket Creation

When a ticket does not exist yet (e.g., first time using Houston, or ad-hoc request from Slack/verbal):

1. Read `prompts/CREATE_TICKET.md` for the standard creation process and template.
2. Source can be: GitHub Issue URL, Slack message, or verbal request.
3. BDD Scenarios are REQUIRED in every ticket (Given-When-Then format).
   - Bug Fix: 1 scenario / Simple Feature: 1-2 / Complex Feature: 3-5
4. Save to `tickets/T-{ProjectCode}-{IssueID}-{description}.md`
5. Register the ticket in `tasks/TASK_BOARD.md`.
6. Then continue with the Session Checklist [PRE] steps.

---

## 9. Mission Communication & Lifecycle (tmux)

tmux is Houston's runtime for parallel work. Two helpers and one lint are
mandatory for the parent-child architecture described in `.houston/RULES.md`
(Pane Delivery / Self-Kill Gate / Parent-Child Chain Enforcement / Intent Kind).

### 9.1 Pane delivery — `scripts/tmux-send-verified.sh`

Single point of enforcement for sending any prompt, report, or command into
an interactive Flight / Probe pane.

```bash
# Default profile = message (5s primary ACK + 3s retry, 8s total)
scripts/tmux-send-verified.sh <session:window> <file>

# Launch profile (12s primary ACK + 10s retry, 22s total)
# — used by launch-leaf-worker.sh right after agent cold-start, when the
#   agent TUI may take longer to print its first thinking signature.
scripts/tmux-send-verified.sh <session:window> <file> --profile launch

# Per-agent ACK profile (T-HOU-013+)
# Loads ack_regex from .houston/agent-profiles.yaml (profiles.<agent>.ack_regex).
# Default = claude. Missing/unreadable profile ⇒ falls back to the built-in
# claude regex (graceful). Override YAML path via HOUSTON_AGENT_PROFILES_FILE.
scripts/tmux-send-verified.sh <session:window> <file> --agent codex
```

Interactive leaf launch is agent-selectable and backward-compatible:

```bash
# Historical default: Claude Code
scripts/launch-leaf-worker.sh <session:window> <worktree> <prompt-file>

# Claude quota / parallel-agent path: Codex through OMX, same pane contract
scripts/launch-leaf-worker.sh --agent omx <session:window> <worktree> <prompt-file>

# Direct Codex or Gemini when OMX is not desired
scripts/launch-leaf-worker.sh --agent codex <session:window> <worktree> <prompt-file>
scripts/launch-leaf-worker.sh --agent gemini <session:window> <worktree> <prompt-file>
```

Use `scripts/houston-omx-exec-prompt.sh <prompt-file>` or `omx exec - < prompt-file` for one-shot Probes that should run to completion and exit. Use `launch-leaf-worker.sh --agent omx` only when the child must remain prompt-capable for follow-up instructions.

- Direct `tmux send-keys` is blocked by `.claude/settings.json` PreToolUse hook (`scripts/houston-tmux-guard.sh`). Strings containing `tmux send-keys` inside heredoc/markdown-inline-code bodies are stripped before matching and pass through
- The wrapper pastes payload via `tmux load-buffer FILE` + `tmux paste-buffer -d -r` (stdin-safe, no argv limit, byte-preserving) and self-advertises `HOUSTON_TMUX_SEND_VERIFIED=1`
- Exit codes: 0 = delivered + ACK, 2 = usage / target missing / empty file, 75 = delivery failure
- `launch-leaf-worker.sh` and follow-up report sends MUST use this wrapper; direct invocation is reserved for emergency recovery (`export HOUSTON_TMUX_SEND_VERIFIED=1` — must be exported in parent shell, not prefixed). The launcher drops `HOUSTON_TMUX_SEND_VERIFIED` from every child agent subprocess via `env -u` so sub-agents cannot inherit the bypass gate

### 9.2 Orbit lint — `scripts/houston-orbit.sh`

Scans live tmux sessions + `.omx/logs/tmux-safe-*.manifest` and surfaces
aged missions by intent kind.

```bash
houston orbit                                        # default scan (natural command, T-HOU-025)
houston orbit --mark <session> long_running          # reclassify
houston orbit --mark <session> pinned                # never alert
houston orbit archive [--days N] [--yes] [--dry-run] # archive dead short_running (T-HOU-025)
# (scripts/houston-orbit.sh … still works directly; `houston orbit …` dispatches to it)
```

- Thresholds (overridable via env): `HOUSTON_ORBIT_SHORT_DAYS=5`, `HOUSTON_ORBIT_LONG_DAYS=30`
- `houston orbit archive` reversibly `mv`s **dead + short_running + aged** manifests to
  `.omx/logs/archive/` (RETAIN: live / ancestor-of-live / child-of-live / long_running /
  pinned). Default lists + confirms; `--yes` for CI, `--dry-run` to preview. See RULES
  `## Mission Tree Visibility` → "Closed/dead node archiving"
- `HOUSTON_ORBIT_IGNORE_RE` (default `^omx-workspace-`) filters tool-runtime scratch
  sessions out of the scan + tree
- `pinned` = never alert. Used for Mission Control itself and explicit permanent working sessions
- `--mark` auto-creates a minimal v3 manifest if none exists (covers missions launched before the manifest schema; T-HOU-014 bumped this stub from v2 to v3 so `--mark` and the launcher emit the same schema)
- Legacy v1/v2 manifests (no `schema_version=3` marker) can be batch-migrated forward to v3 with `scripts/houston-orbit-bootstrap.sh --dry-run` (preview) then `--apply` (interactive) or `--apply --yes` (CI). Migration is field-preserving — existing values (incl. v2 `intent_kind`/`self_role`/`parent_*`) are carried over unchanged; only the three v3 fields (`parent_mission`←`parent_session`, `mission_family`, `lifecycle_phase`) are added. Backups (`.bak.<epoch>`) are written next to each rewritten file (T-HOU-013 IP-02 / T-HOU-014 IP-03)
- When prevention-first parent-child enforcement holds, the alert section should normally be empty

### 9.3 Manager kill-time checklist — `scripts/houston-clean-check.sh`

Run by the **owning node (direct parent)** before it kills a child node — any node that has children, at any tree depth.

```bash
scripts/houston-clean-check.sh <session>          # resolve cwd from manifest
scripts/houston-clean-check.sh /path/to/worktree  # direct path
```

- Verifies the child's worktree has 0 modified/staged, 0 untracked, 0 unpushed (when upstream is set)
- Exit 0 = clean, exit 1 = dirty (issues listed)
- This is item 3 of the three-item manager checklist (RULES.md `## Parent-Child Chain Enforcement`); items 1 and 2 (objective achieved / knowledge documented) are manual reviews

### 9.4 Mission tree visibility — naming, emoji, session description

The mission tree command `scripts/houston-orbit.sh tree` reads parent-child
lineage from the v3 manifest (+ live tmux state) and renders an ASCII tree.
Raw tmux views (`prefix + s`, status line, window names) stay legible via the
role emoji lineage, the session naming convention, and the session-description
tmux options — all defined in `.houston/RULES.md` (`## Mission Tree Visibility`).

```bash
houston orbit tree            # ASCII parent-child tree (natural command, T-HOU-025)
houston orbit tree --color    # colorize status via tput (TTY)
houston orbit relabel [--dry-run]   # number the raw tmux list (T-HOU-025)
# (scripts/houston-orbit.sh tree … still works directly)
```

Output: 🛰️ houston (MC) at the root; missions hang under it by `parent_mission`
(falling back to `parent_session`); a **designation coordinate** (`1`, `1.1`,
`1.1.1`, … — point-count = depth, computed from edges at render, never stored) +
archetype glyph (🧑‍🚀 Crew / 🔬 Probe) + status (🟢/✅/⚪/🟠) per node;
`(mission_family)` annotation when set. A node whose `parent_mission` points to
an unknown session is flagged 🟠 orphan; a `parent_mission` cycle is surfaced
flat under an "unreached" note (nothing is hidden). The tree is depth-unlimited:
Crews nest under Crews to any depth, with Probes at the leaves.

**Window-children (G2 — T-HOU-025)**: a live session's windows at index ≥ 1 whose
name begins with a recognized role glyph render as child nodes with derived
coordinates (`5` → `5.1`). A mission's leaf-window Probes are therefore visible in
the tree, not just session-level missions. See RULES `## Mission Tree Visibility`.

**Raw-list numbering (G3 — T-HOU-025)**: `houston orbit relabel` recomputes every
node's coordinate and writes it as a prefix on each **live window name**
(`<coord> <glyph> <objective>`); session names are never renamed and the coordinate
is a recomputed transient cache (manifest stays truth). It is idempotent (strips any
existing coordinate first) and skips the apex `houston` windows. The launcher calls
it best-effort at birth; run it manually after a kill / re-parent.

**tmux popup** — `prefix + T` opens the tree in a scrollable popup. Add to
`~/.tmux.conf`:

```tmux
source-file ~/workspace/.houston/tmux/houston-keybindings.conf
```

then `tmux source-file ~/.tmux.conf`. The snippet binds `prefix + T`
(display-popup, tmux 3.2+) and `prefix + M-t` (tree into the pane). Adjust the
workspace path in the snippet if your Houston root is not `~/workspace`.

New missions get the lineage for free: pass `--family <name>` (and, for a child
mission, `--parent <session>`) to `scripts/houston-tmux-safe-launch.sh`, which
writes `mission_family` / `parent_mission` into the manifest.

Active sessions launched before Wave 3 are migrated once, manually:

```bash
# 1. Manifests: bring v1/v2 → v3 (field-preserving; dry-run first). The
#    bootstrap carries existing fields over unchanged and only adds the three
#    v3 fields; it now upgrades v2 manifests too (not just v1).
scripts/houston-orbit-bootstrap.sh --dry-run
scripts/houston-orbit-bootstrap.sh --apply

# 2. Set the real tree edges / family where the migrator could not infer them
#    (parent_mission defaults to parent_session; correct it where the real
#    parent differs — e.g. audit-derived hotfixes belong under the audit
#    mission, not Mission Control). Edit the manifest field, or relaunch.

# 3. Mirror lineage onto the live session's tmux description options:
tmux set-option -t <session> @parent_mission  <parent-or-empty>
tmux set-option -t <session> @mission_family  <family>
tmux set-option -t <session> @lifecycle_phase active   # active|closed|idle|orphan
```

Do not invent lineage. When the real parent/family of a pre-Wave-3 session is
unclear, confirm with the Commander before setting it — the manifest is
governance truth, not a guess.

### 9.5 Program — family-level coordination

When a `mission_family` crosses the Program trigger (RULES.md
`## Parent-Child Chain Enforcement` → Program: a 2nd concurrent live leaf in a
`long_running` family, or the high-touch override), launch a Program and hang the
family's leaf missions under it. A Program is simply a **Crew** (`self_role=crew`)
whose direct children are sibling missions — a named placement of the depth-unlimited
Crew archetype, so a Program may itself sit under another Program.
(Source: RFC-HOU-FLEETDECK-001, generalized by RFC-HOU-TREE-UNLIMITED-001.)

```bash
# 1. Launch the Program (long-running family coordinator)
scripts/houston-tmux-safe-launch.sh --family <F> --parent houston
scripts/houston-orbit.sh --mark <program-session> long_running

# 2. Launch each leaf UNDER the Program (not under houston)
scripts/houston-tmux-safe-launch.sh --family <F> --parent <program-session>

# 3. (Promotion) migrate leaves that started under MC
tmux set-option -t <leaf-session> @parent_mission <program-session>
#   + edit the leaf manifest parent_mission field to match (manifest = truth)
```

- MC communicates with the Program only; the Program owns its leaves.
- Detect trigger / death manually via `houston-orbit.sh tree`: count 🟢 leaves per
  family (trigger); a coordinator at `live=0` with 🟢 leaves = dead (liveness gate),
  **not** an orphan flag. See the RULES Program block.
- Close-out: the Program reports to MC; MC runs the kill-time checklist
  (`houston-clean-check.sh` on each leaf + the Program) then kills.

### 9.6 Work Distribution 운영 (Tier-1)
- **에스컬레이션(subsidiarity)**: 노드 단독판단 불가 결정은 `tmux-send-verified.sh`
  로 **직속 부모**에게 보고(apex 직행 금지). 부모가 직속 자식들을 가로질러 판단,
  안 되면 다시 한 단계 위로.
- **거버넌스 샤딩 L1**: 보드 write 는 소유자 앵커 섹션에 additive surgical insert
  (`reference_houston_root_reconcile_method` 절차). MC milestone flush.
- **결정 배치/사전위임**: 안전부류(docs-only·non-prod·in-scope audit)만 배치 진행;
  머지/외부/prod/상태는 건별 Commander 컨펌 유지.
