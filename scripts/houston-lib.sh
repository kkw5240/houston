#!/bin/bash
# ============================================================
# houston-lib.sh — Houston Common Function Library
#
# Shared functions used by all Houston scripts.
# Source this file at the top of each script:
#
#   SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
#   source "$SCRIPT_DIR/houston-lib.sh"
#
# Provided functions:
#   find_houston_root()   — Find Houston workspace root by walking up
#   resolve_script_dir()  — Resolve symlinks to find real script dir
#   fleet_lookup()        — Lookup path/branch by project CODE
#   fleet_info()          — Print full project info by CODE
#   fleet_parse_all()     — Iterate all fleet entries (callback pattern)
#   fleet_get_hook()      — Get hook path for a project code
#   run_hook()            — Execute a lifecycle hook (non-blocking)
#   is_worktree()         — Check if a path is a git worktree
#   get_worktree_main()   — Get the main repo path for a worktree
# ============================================================

# --- find_houston_root() ---
# Walk up from $PWD to find the directory containing .houston/
# Sets HOUSTON_ROOT on success. Returns 1 on failure.
find_houston_root() {
  local dir="$PWD"
  while [ "$dir" != "/" ]; do
    if [ -d "$dir/.houston" ]; then
      echo "$dir"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  return 1
}

# --- resolve_script_dir() ---
# Resolve symlinks for a given script path ($1) and echo the real directory.
# Usage: SCRIPT_DIR=$(resolve_script_dir "$0")
resolve_script_dir() {
  local source="$1"
  local dir
  while [ -L "$source" ]; do
    dir="$(cd "$(dirname "$source")" && pwd)"
    source="$(readlink "$source")"
    [[ "$source" != /* ]] && source="$dir/$source"
  done
  echo "$(cd "$(dirname "$source")" && pwd)"
}

# --- fleet_lookup() ---
# Reads fleet.yaml for a given project CODE.
# Sets FLEET_PATH (absolute) and FLEET_BRANCH.
# Requires HOUSTON_ROOT and FLEET to be set.
fleet_lookup() {
  local code="$1"

  if [ ! -f "$FLEET" ]; then
    echo "❌ Fleet manifest not found: $FLEET" >&2
    return 1
  fi

  FLEET_PATH=""
  FLEET_BRANCH=""
  FLEET_ISSUE_REPO=""
  local found=false
  while IFS= read -r line; do
    if echo "$line" | grep -q "code: $code\$"; then
      found=true
      continue
    fi
    if $found; then
      if echo "$line" | grep -q "^  - code:"; then
        break
      fi
      # NOTE: *issue_repo:* MUST be before *repo:* (if added) to avoid substring match
      case "$line" in
        *issue_repo:*) FLEET_ISSUE_REPO=$(echo "$line" | sed 's/.*issue_repo: *//');;
        *path:*)       FLEET_PATH=$(echo "$line" | sed 's/.*path: *//')       ;;
        *branch:*)     FLEET_BRANCH=$(echo "$line" | sed 's/.*branch: *//')   ;;
      esac
    fi
  done < "$FLEET"

  if [ -z "$FLEET_PATH" ]; then
    echo "❌ Project code '$code' not found in fleet.yaml" >&2
    return 1
  fi

  # Resolve to absolute path relative to Houston root
  FLEET_PATH="$HOUSTON_ROOT/$FLEET_PATH"
  return 0
}

# --- fleet_info() ---
# Print full project info for a given CODE.
# Requires FLEET to be set.
fleet_info() {
  local code="$1"

  if [ ! -f "$FLEET" ]; then
    echo "❌ Fleet manifest not found: $FLEET" >&2
    return 1
  fi

  local found=false
  local name="" repo="" path="" branch="" stack="" has_claude_md="" issue_repo=""

  while IFS= read -r line; do
    if echo "$line" | grep -q "code: $code\$"; then
      found=true
      continue
    fi
    if $found; then
      if echo "$line" | grep -q "^  - code:"; then
        break
      fi
      case "$line" in
        *issue_repo:*)    issue_repo=$(echo "$line" | sed 's/.*issue_repo: *//');;
        *name:*)          name=$(echo "$line" | sed 's/.*name: *//')          ;;
        *repo:*)          repo=$(echo "$line" | sed 's/.*repo: *//')          ;;
        *path:*)          path=$(echo "$line" | sed 's/.*path: *//')          ;;
        *branch:*)        branch=$(echo "$line" | sed 's/.*branch: *//')      ;;
        *stack:*)         stack=$(echo "$line" | sed 's/.*stack: *//')        ;;
        *has_claude_md:*) has_claude_md=$(echo "$line" | sed 's/.*has_claude_md: *//');;
      esac
    fi
  done < "$FLEET"

  if ! $found; then
    echo "❌ Project code '$code' not found in fleet.yaml" >&2
    return 1
  fi

  local claude_icon="❌"
  [ "$has_claude_md" = "true" ] && claude_icon="✅"

  echo "📡 $name ($code)"
  echo "   Repo:      $repo"
  echo "   Path:      $path"
  echo "   Stack:     $stack"
  echo "   Branch:    $branch"
  echo "   CLAUDE.md: $claude_icon"
  [ -n "$issue_repo" ] && echo "   Issues:    $issue_repo"
}

# --- fleet_parse_all() ---
# Iterate all fleet entries and extract project information.
# Populates arrays: PROJECT_DIRS (unique parent dirs),
#   FLEET_CODES, FLEET_ISSUE_REPOS (parallel arrays per entry).
# Requires FLEET to be set.
fleet_parse_all() {
  PROJECT_DIRS=()
  FLEET_CODES=()
  FLEET_ISSUE_REPOS=()
  if [ ! -f "$FLEET" ]; then
    return 1
  fi
  local current_code="" current_issue_repo=""
  while IFS= read -r line; do
    # Detect new entry
    local code
    code=$(echo "$line" | sed -n 's/.*code: *//p')
    if [ -n "$code" ]; then
      # Finalize previous entry
      if [ -n "$current_code" ]; then
        FLEET_CODES+=("$current_code")
        FLEET_ISSUE_REPOS+=("$current_issue_repo")
      fi
      current_code="$code"
      current_issue_repo=""
      continue
    fi
    # Parse fields
    local path
    path=$(echo "$line" | sed -n 's/.*path: *//p')
    if [ -n "$path" ]; then
      local parent
      parent=$(dirname "$path")
      local local_found=false
      for existing in "${PROJECT_DIRS[@]}"; do
        [ "$existing" = "$parent" ] && local_found=true && break
      done
      $local_found || PROJECT_DIRS+=("$parent")
    fi
    local ir
    ir=$(echo "$line" | sed -n 's/.*issue_repo: *//p')
    [ -n "$ir" ] && current_issue_repo="$ir"
  done < "$FLEET"
  # Finalize last entry
  if [ -n "$current_code" ]; then
    FLEET_CODES+=("$current_code")
    FLEET_ISSUE_REPOS+=("$current_issue_repo")
  fi
}

# --- fleet_get_hook() ---
# Get the hook script path for a given hook name and project code.
# Priority: fleet.yaml per-project hook > config.yaml global hook
# Args: $1 = hook_name (e.g., "on_ticket_start"), $2 = project_code (optional)
# Requires HOUSTON_ROOT to be set.
# Echoes the resolved absolute path if found, or empty string.
fleet_get_hook() {
  local hook_name="$1"
  local project_code="${2:-}"
  local hook_path=""

  local fleet_file="$HOUSTON_ROOT/.houston/fleet.yaml"
  local config_file="$HOUSTON_ROOT/.houston/config.yaml"

  # 1. Check fleet.yaml for per-project hook override
  if [ -n "$project_code" ] && [ -f "$fleet_file" ]; then
    local in_project=false
    local in_hooks=false
    while IFS= read -r line; do
      if echo "$line" | grep -q "code: ${project_code}\$"; then
        in_project=true
        continue
      fi
      if $in_project; then
        if echo "$line" | grep -q "^  - code:"; then
          break
        fi
        if echo "$line" | grep -q "hooks:"; then
          in_hooks=true
          continue
        fi
        if $in_hooks; then
          # Stop at next non-indented field
          if echo "$line" | grep -qE "^    [a-z]"; then
            local key val
            key=$(echo "$line" | sed 's/^ *//' | cut -d: -f1)
            val=$(echo "$line" | sed 's/^[^:]*: *//' | sed 's/^ *//;s/ *$//' | tr -d '"')
            if [ "$key" = "$hook_name" ] && [ -n "$val" ]; then
              hook_path="$val"
              break
            fi
          else
            in_hooks=false
          fi
        fi
      fi
    done < "$fleet_file"
  fi

  # 2. Fallback to config.yaml global hook
  if [ -z "$hook_path" ] && [ -f "$config_file" ]; then
    local in_hooks_section=false
    while IFS= read -r line; do
      # Detect lifecycle_hooks: section (top-level)
      if echo "$line" | grep -qE '^lifecycle_hooks:'; then
        in_hooks_section=true
        continue
      fi
      if $in_hooks_section; then
        # Stop at next top-level key
        if echo "$line" | grep -qE '^[a-z]'; then
          break
        fi
        local key val
        key=$(echo "$line" | sed 's/^ *//' | cut -d: -f1)
        val=$(echo "$line" | sed 's/^[^:]*: *//' | sed 's/^ *//;s/ *$//' | tr -d '"')
        if [ "$key" = "$hook_name" ] && [ -n "$val" ]; then
          hook_path="$val"
          break
        fi
      fi
    done < "$config_file"
  fi

  # Resolve to absolute path
  if [ -n "$hook_path" ]; then
    if [[ "$hook_path" != /* ]]; then
      hook_path="$HOUSTON_ROOT/$hook_path"
    fi
    echo "$hook_path"
  fi
}

# --- run_hook() ---
# Execute a lifecycle hook. Non-blocking: if the hook fails, print warning
# and continue. If the hook doesn't exist, silently skip.
#
# Args: $1 = hook_name, $2 = project_code (optional)
# Environment variables passed to hook:
#   TICKET_ID, WORKSPACE_PATH, PROJECT_CODE, BRANCH_NAME, HOUSTON_ROOT
run_hook() {
  local hook_name="$1"
  local project_code="${2:-}"

  local hook_path
  hook_path=$(fleet_get_hook "$hook_name" "$project_code")

  # No hook configured — silently skip
  if [ -z "$hook_path" ]; then
    return 0
  fi

  # Hook file doesn't exist — silently skip
  if [ ! -f "$hook_path" ]; then
    return 0
  fi

  # Hook not executable — warn and skip
  if [ ! -x "$hook_path" ]; then
    echo "⚠️  Hook not executable: $hook_path (skipping)" >&2
    return 0
  fi

  echo "🔧 Running hook: $hook_name → $(basename "$hook_path")"

  # Export context for the hook
  export HOUSTON_ROOT
  export TICKET_ID="${TICKET_ID:-}"
  export WORKSPACE_PATH="${WORKSPACE_PATH:-}"
  export PROJECT_CODE="${PROJECT_CODE:-$project_code}"
  export BRANCH_NAME="${BRANCH_NAME:-}"

  # Execute — non-blocking (warning on failure)
  if ! "$hook_path"; then
    echo "⚠️  Hook '$hook_name' failed (non-blocking, continuing)" >&2
  fi

  return 0
}

# --- is_worktree() ---
# Check if a given path is a git worktree (not a full clone).
# Worktrees have a .git FILE (not directory) pointing to the main repo.
# Returns 0 if worktree, 1 if not.
is_worktree() {
  local path="$1"
  [ -f "$path/.git" ] && return 0
  return 1
}

# --- get_worktree_main() ---
# Get the main repository path for a worktree.
# Echoes the absolute path to the main repo's working directory.
# Returns 1 if the path is not a worktree.
get_worktree_main() {
  local path="$1"
  if ! is_worktree "$path"; then
    return 1
  fi
  # git rev-parse --git-common-dir returns the shared .git dir
  local common_dir
  common_dir=$(git -C "$path" rev-parse --git-common-dir 2>/dev/null) || return 1
  # Resolve to absolute path, then get parent (working dir)
  local abs_git_dir
  abs_git_dir=$(cd "$path" && cd "$common_dir" && pwd)
  # The main repo is the parent of the .git directory
  echo "$(dirname "$abs_git_dir")"
}
