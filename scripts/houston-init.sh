#!/bin/bash
# ============================================================
# houston-init.sh — Initialize a new Houston workspace
#
# Usage:
#   houston-init.sh [workspace_path]
#
# If no path is given, initializes in the current directory.
# Creates the Houston directory structure, runs the first build,
# and installs git hooks.
# ============================================================

set -e

TARGET="${1:-.}"

# ---- Resolve path ----
if [ "$TARGET" != "." ]; then
  mkdir -p "$TARGET"
fi
TARGET="$(cd "$TARGET" && pwd)"

# ---- Check if already initialized ----
if [ -d "$TARGET/.houston" ]; then
  echo "⚠️  Houston is already initialized in this workspace."
  echo "   $TARGET/.houston/ exists."
  exit 1
fi

echo "🚀 Initializing Houston workspace..."
echo "   Path: $TARGET"
echo ""

# ---- Create directory structure ----
echo "[1/5] Creating directory structure..."
mkdir -p "$TARGET/.houston"
mkdir -p "$TARGET/.github"
mkdir -p "$TARGET/scripts"
mkdir -p "$TARGET/tickets"
mkdir -p "$TARGET/tasks"
mkdir -p "$TARGET/docs/processes"
mkdir -p "$TARGET/docs/standards"
mkdir -p "$TARGET/prompts"
mkdir -p "$TARGET/daily_scrum"

# ---- Create .houston/ source files ----
echo "[2/5] Creating Houston source files..."

# IDENTITY.md
cat > "$TARGET/.houston/IDENTITY.md" << 'EOF'
# Houston — Mission Control

You are operating inside **Houston**, a Mission Control system for software engineering operations.

## What Houston Is

Houston is a **Control Tower** that orchestrates work across multiple service repositories.
It does NOT contain application code. It owns **truth about work**: what needs to be done, what has been done, and the proof that it was done correctly.

- **Documentation is the operating system.** Code is the output.
- **Every action must leave evidence.** Without proof, it is not done.
- **Repositories own implementation.** Houston owns governance and process.

## Your Role

You are a **Mission Operator** inside Houston. This means:

- You follow Houston's processes — not your own defaults.
- You read Houston's rules BEFORE taking any action on a task.
- You verify your work with evidence BEFORE marking anything as complete.
- When uncertain, you **ask** — you do not guess or assume.
- You treat documentation updates as **equal priority** to code changes.

## Operating Model

| Responsibility | Owner |
|:---|:---|
| WHAT to build, WHY, WHERE, and PROOF | Houston (this workspace) |
| HOW to implement | Individual repositories |

## Communication

- Be direct and evidence-based.
- Use Korean for process context and business discussions.
- Use English for technical terms, code, and commit messages.
- Prefer "confirmed/verified" over "understood/got it" — confirmation implies you actually checked.

## Script Output Tone

Houston scripts (`scripts/houston-*.sh`, etc.) use **Mission Control tone** in their user-facing output.

**Guidelines for script messages:**
- Use space/mission metaphors: "docked", "undocked", "fleet", "launch", "mission"
- Use emoji for visual scanning: 🚀 🛰️ 📡 ✅ ⚠️ ❌
- Keep it brief — tone is flavor, not noise

**Where NOT to use Mission Control tone:**
- `.houston/` source documents — these must be plain and precise
- Agent inline instructions — clarity over personality
- Commit messages — use standard `{emoji} {type}: {description}` format
EOF

# RULES.md (minimal starter)
cat > "$TARGET/.houston/RULES.md" << 'EOF'
# Houston Rules

These rules are mandatory. They apply to every task, every session, every agent.

## 10 Golden Rules

1. **Repo-per-Ticket**: Never work in `source/`. Copy to `T-{ID}` folder for isolation.
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

## Evidence-Based Completion

> "Without proof, the status is NOT Done."

Every completed task MUST have:
- A commit hash or PR link recorded in `tasks/CHANGESETS.md`
- Acceptance tests passing (Green)
- No regressions in existing tests

## Commit Rules

**Message format:**
```bash
git commit -m "{emoji} {type}: {short description}"
```

| Emoji | Type | Purpose |
|:---|:---|:---|
| ✨ | `feat` | New feature |
| 🐛 | `fix` | Bug fix |
| 📝 | `docs` | Documentation only |
| ♻️ | `refactor` | Code refactoring |
| ✅ | `test` | Adding or updating tests |
| 🔧 | `chore` | Build, config, CI changes |
| 🚑 | `hotfix` | Critical production fix |
EOF

# PROCESSES.md (minimal starter)
cat > "$TARGET/.houston/PROCESSES.md" << 'EOF'
# Houston Processes

Summaries of core workflows. Customize these for your team.

## 1. Repo-per-Ticket Workflow

Each ticket gets its own **disposable workspace** — a full copy of the source repo.

**Finding the right repository:**

Before creating a ticket workspace, identify the target repo:
1. Check `.houston/fleet.yaml` — fleet manifest (which repos are docked)
2. Match project code to repo
3. Source path convention: `{project-folder}/source/`
4. If the repo is not listed or the path doesn't exist, ask the user.

## 2. Testing Strategy

**Core flow**: Scenario → Acceptance Test (Red) → TDD Implementation → Green → Commit

## 3. Git Strategy

**Branches**: main/master (production), stage (integration), feat/* (features), fix/* (fixes)
EOF

# CHECKLIST.md (minimal starter)
cat > "$TARGET/.houston/CHECKLIST.md" << 'EOF'
# Houston Session Checklist

Run through this checklist every time you start a new task or resume work.

## [PRE] Before Starting Work

- [ ] **Requires a ticket?** — If the task produces NO code/doc changes, skip the full process
- [ ] **Ticket exists?** — `tickets/T-{Project}-{IssueID}.md` is present
- [ ] **Repo-per-Ticket?** — Check `.houston/fleet.yaml` for target repo path

## [DURING] While Working

- [ ] **Docs first?** — Design docs or ticket scenarios updated BEFORE coding
- [ ] **Test first?** — Acceptance tests written (Red) BEFORE implementation

## [POST] After Completing a Change Set

- [ ] **Evidence recorded?** — PR link or commit hash in `tasks/CHANGESETS.md`
- [ ] **Tests green?** — All acceptance tests passing
- [ ] **Commit message correct?** — Uses `{emoji} {type}: {description}` format
EOF

# fleet.yaml (empty template)
cat > "$TARGET/.houston/fleet.yaml" << 'EOF'
# .houston/fleet.yaml
# Houston Fleet Manifest — repositories managed by this control tower
#
# Register repos with: scripts/houston-dock.sh
# Remove repos with:   scripts/houston-undock.sh

fleet:
EOF

# config.yaml
cat > "$TARGET/.houston/config.yaml" << 'CONFIGEOF'
# Houston Workspace Configuration
# Customize tools here. Process/policy rules live in .houston/*.md files.

# Agent adapters to generate from .houston/ sources.
# Each path is relative to workspace root.
# Remove or add entries to match your team's AI tools.
adapters:
  - CLAUDE.md
  - .cursorrules
  - .windsurfrules
  - .github/copilot-instructions.md

# Git hooks
hooks:
  # Auto-rebuild adapters when .houston/ source files change
  pre_commit_build: true
CONFIGEOF

# build.sh
cat > "$TARGET/.houston/build.sh" << 'BUILDEOF'
#!/bin/bash
# ============================================================
# Houston Build System
# Assembles agent-specific instruction files from .houston/ sources.
#
# Marker mode: If a file already exists, only the content between
# <!-- HOUSTON:START --> and <!-- HOUSTON:END --> markers is replaced.
# User-written content outside the markers is preserved.
#
# If the file does not exist, it is created with Houston content only.
#
# Usage: .houston/build.sh
# ============================================================

set -e

HOUSTON_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_DIR="$(dirname "$HOUSTON_DIR")"

# --- Load adapter list from config ---
CONFIG="$HOUSTON_DIR/config.yaml"
if [ -f "$CONFIG" ]; then
  ADAPTERS=()
  if command -v yq &>/dev/null; then
    # yq available — safe YAML parsing
    mapfile -t ADAPTERS < <(yq -r '.adapters[]' "$CONFIG" 2>/dev/null)
  fi
  # Fallback: bash parsing (when yq unavailable or yq returned nothing)
  if [ ${#ADAPTERS[@]} -eq 0 ]; then
    in_adapters=false
    while IFS= read -r line; do
      # Detect start of adapters: section
      if echo "$line" | grep -q '^adapters:'; then
        in_adapters=true
        continue
      fi
      # Stop at next top-level key
      if $in_adapters && echo "$line" | grep -q '^[a-z]'; then
        break
      fi
      # Extract "  - path/to/file" entries
      if $in_adapters; then
        path=$(echo "$line" | sed -n 's/^  *- *//p')
        [ -n "$path" ] && ADAPTERS+=("$path")
      fi
    done < "$CONFIG"
  fi
else
  # Fallback: default adapter list (no config.yaml)
  ADAPTERS=(
    "CLAUDE.md"
    ".cursorrules"
    ".windsurfrules"
    ".github/copilot-instructions.md"
  )
fi

# --- Load source files ---
IDENTITY=$(cat "$HOUSTON_DIR/IDENTITY.md")
RULES=$(cat "$HOUSTON_DIR/RULES.md")
PROCESSES=$(cat "$HOUSTON_DIR/PROCESSES.md")
CHECKLIST=$(cat "$HOUSTON_DIR/CHECKLIST.md")

# --- Assemble Houston block ---
HOUSTON_BLOCK="<!-- HOUSTON:START — Auto-generated by .houston/build.sh. DO NOT EDIT between markers. -->

${IDENTITY}

---

${RULES}

---

${PROCESSES}

---

${CHECKLIST}

<!-- HOUSTON:END -->"

# --- Write function: marker-aware ---
write_adapter() {
  local FILE="$1"

  if [ -f "$FILE" ]; then
    # File exists — check for markers
    if grep -q "<!-- HOUSTON:START" "$FILE" 2>/dev/null; then
      # Replace content between markers (inclusive)
      local TEMP=$(mktemp)
      awk '
        /<!-- HOUSTON:START/ { skip=1; print "___HOUSTON_PLACEHOLDER___"; next }
        /<!-- HOUSTON:END/   { skip=0; next }
        !skip { print }
      ' "$FILE" > "$TEMP"

      # Replace placeholder with new Houston block
      local BLOCK_TEMP=$(mktemp)
      printf '%s\n' "$HOUSTON_BLOCK" > "$BLOCK_TEMP"

      # Build final file: lines before placeholder, Houston block, lines after
      local FINAL_TEMP=$(mktemp)
      while IFS= read -r line; do
        if [ "$line" = "___HOUSTON_PLACEHOLDER___" ]; then
          cat "$BLOCK_TEMP"
        else
          printf '%s\n' "$line"
        fi
      done < "$TEMP" > "$FINAL_TEMP"

      mv "$FINAL_TEMP" "$FILE"
      rm -f "$TEMP" "$BLOCK_TEMP"
      echo "  ✅ $(basename "$FILE") (updated — user content preserved)"
    else
      # File exists but no markers — append Houston block at the end
      printf '\n%s\n' "$HOUSTON_BLOCK" >> "$FILE"
      echo "  ✅ $(basename "$FILE") (appended — existing content preserved)"
    fi
  else
    # File does not exist — create with Houston content only
    mkdir -p "$(dirname "$FILE")"
    printf '%s\n' "$HOUSTON_BLOCK" > "$FILE"
    echo "  ✅ $(basename "$FILE") (created)"
  fi
}

# --- Generate adapters ---
echo "Houston build system:"
for adapter in "${ADAPTERS[@]}"; do
  write_adapter "$WORKSPACE_DIR/$adapter"
done
echo ""
echo "Build complete. ${#ADAPTERS[@]} adapters generated."
BUILDEOF
chmod +x "$TARGET/.houston/build.sh"

# install-hooks.sh
cat > "$TARGET/.houston/install-hooks.sh" << 'HOOKEOF'
#!/bin/bash
# Install Houston pre-commit hook

set -e

HOUSTON_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_DIR="$(dirname "$HOUSTON_DIR")"
HOOK_FILE="$WORKSPACE_DIR/.git/hooks/pre-commit"

CONFIG="$HOUSTON_DIR/config.yaml"
PRE_COMMIT_BUILD="true"
if [ -f "$CONFIG" ]; then
  val=$(grep 'pre_commit_build:' "$CONFIG" | awk '{print $2}')
  [ "$val" = "false" ] && PRE_COMMIT_BUILD="false"
fi

if [ "$PRE_COMMIT_BUILD" = "false" ]; then
  echo "Pre-commit build hook disabled in config.yaml"
  exit 0
fi

mkdir -p "$(dirname "$HOOK_FILE")"

cat > "$HOOK_FILE" << 'EOF'
#!/bin/bash
if git diff --cached --name-only | grep -q "^\.houston/"; then
  echo "[Houston] Source files changed. Rebuilding agent adapters..."
  .houston/build.sh
  CONFIG=".houston/config.yaml"
  if [ -f "$CONFIG" ]; then
    in_adapters=false
    while IFS= read -r line; do
      if echo "$line" | grep -q '^adapters:'; then in_adapters=true; continue; fi
      if $in_adapters && echo "$line" | grep -q '^[a-z]'; then break; fi
      if $in_adapters; then
        path=$(echo "$line" | sed -n 's/^  *- *//p')
        [ -n "$path" ] && [ -f "$path" ] && git add "$path"
      fi
    done < "$CONFIG"
  else
    for f in CLAUDE.md .cursorrules .windsurfrules .github/copilot-instructions.md; do
      [ -f "$f" ] && git add "$f"
    done
  fi
  echo "[Houston] Adapters rebuilt and staged."
fi
EOF
chmod +x "$HOOK_FILE"

echo "Pre-commit hook installed."
HOOKEOF
chmod +x "$TARGET/.houston/install-hooks.sh"

# ---- Copy fleet scripts ----
echo "[3/5] Installing fleet scripts..."

# Copy the houston-* scripts from the same directory as this init script
INIT_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
for script in houston-dock.sh houston-undock.sh houston-status.sh; do
  if [ -f "$INIT_SCRIPT_DIR/$script" ]; then
    cp "$INIT_SCRIPT_DIR/$script" "$TARGET/scripts/$script"
    chmod +x "$TARGET/scripts/$script"
  fi
done

# ---- Create starter files ----
cat > "$TARGET/tasks/CHANGESETS.md" << 'EOF'
# Change Sets

| Ticket | CS | Repo | Status | Branch | Evidence |
|:---|:---|:---|:---|:---|:---|
EOF

cat > "$TARGET/tasks/TASK_BOARD.md" << 'EOF'
# Task Board

## In Progress


## Done

EOF

cat > "$TARGET/README.md" << 'EOF'
# Houston Workspace

This workspace is managed by **Houston** — a Mission Control system for software engineering operations.

## Quick Start

```bash
# Register a repository
scripts/houston-dock.sh https://github.com/org/my-repo.git --code XX

# Check fleet status
scripts/houston-status.sh

# Rebuild agent adapters after editing .houston/ files
.houston/build.sh
```

## Structure

| Directory | Purpose |
|:---|:---|
| `.houston/` | Source of truth for rules, processes, identity |
| `scripts/` | Automation scripts (dock, undock, status, tickets) |
| `tickets/` | Ticket files (one per task) |
| `tasks/` | CHANGESETS.md, TASK_BOARD.md |
| `docs/` | Detailed reference documentation |
| `prompts/` | AI prompt templates |
EOF

# ---- Git init + first build ----
echo "[4/5] Initializing git repository..."
cd "$TARGET"
if [ ! -d ".git" ]; then
  git init
fi

echo "[5/5] Running first Houston build..."
.houston/build.sh

# ---- Install hooks ----
.houston/install-hooks.sh

echo ""
echo "✅ Houston workspace initialized!"
echo ""
echo "📋 Next steps:"
echo "   1. Register your repos:  scripts/houston-dock.sh <repo_url> --code <CODE>"
echo "   2. Check fleet status:   scripts/houston-status.sh"
echo "   3. Create your first ticket and start working!"
echo ""
echo "📡 Houston is ready for launch."
