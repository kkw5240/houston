#!/bin/bash
# ============================================================
# scripts/close_ticket.sh
# Close a ticket workspace (with safety checks, hooks, and post-processing).
#
# Supports both git worktree and legacy cp-R workspaces.
# Post-processing: CHANGESETS.md update, PR creation offer, remote branch cleanup.
#
# Usage: ./close_ticket.sh <TICKET_PATH>
# ============================================================

set -e

# --- Load common library ---
source "$(cd "$(dirname "$0")" && pwd)/houston-lib.sh"
HOUSTON_ROOT=$(find_houston_root 2>/dev/null) || true

TICKET_PATH=$1

if [ -z "$TICKET_PATH" ]; then
  echo "Usage: $0 <TICKET_PATH>"
  exit 1
fi

# Resolve to absolute path
if [[ "$TICKET_PATH" != /* ]]; then
  TICKET_PATH="$(cd "$TICKET_PATH" 2>/dev/null && pwd)" || {
    echo "❌ Directory '$1' not found." >&2
    exit 1
  }
fi

if [ ! -d "$TICKET_PATH" ]; then
  echo "❌ Directory '$TICKET_PATH' not found." >&2
  exit 1
fi

# Safety Check: Don't delete master or source!
if [[ "$TICKET_PATH" == *"master"* ]] || [[ "$(basename "$TICKET_PATH")" == "source" ]]; then
  echo "❌ CRITICAL: Path contains 'master' or 'source'. Access Denied." >&2
  exit 1
fi

echo "🛰️  Closing Ticket Workspace"
echo "   Path: $TICKET_PATH"
echo ""

# Extract context
TICKET_DIR_NAME=$(basename "$TICKET_PATH")
TICKET_ID=$(echo "$TICKET_DIR_NAME" | grep -oE 'T-[A-Z]+-[0-9]+' | head -1)
PROJECT_CODE=$(echo "$TICKET_ID" | sed 's/^T-//; s/-.*//' 2>/dev/null)
BRANCH_NAME=$(cd "$TICKET_PATH" && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

# Detect workspace type
IS_WORKTREE=false
if is_worktree "$TICKET_PATH"; then
  IS_WORKTREE=true
  echo "   Type: Git Worktree"
else
  echo "   Type: Legacy (cp-R clone)"
fi
echo "   Branch: $BRANCH_NAME"
echo ""

# Check for unpushed commits
cd "$TICKET_PATH" || exit
UNPUSHED=$(git log --branches --not --remotes --oneline 2>/dev/null || true)

if [ -n "$UNPUSHED" ]; then
  UNPUSHED_COUNT=$(echo "$UNPUSHED" | wc -l | tr -d ' ')
  echo "⚠️  WARNING: $UNPUSHED_COUNT unpushed commit(s):"
  echo "$UNPUSHED" | head -5
  [ "$UNPUSHED_COUNT" -gt 5 ] && echo "   ... and $((UNPUSHED_COUNT - 5)) more"
  echo ""
  echo "Are you sure you want to delete permanently? (y/N)"
  read -r RESPONSE
  if [[ "$RESPONSE" != "y" ]]; then
    echo "Aborted."
    exit 1
  fi
fi

# Run on_ticket_end hook (before deletion)
export TICKET_ID WORKSPACE_PATH="$TICKET_PATH" PROJECT_CODE BRANCH_NAME
if [ -n "$HOUSTON_ROOT" ]; then
  run_hook "on_ticket_end" "$PROJECT_CODE"
fi

# --- Post-processing (interactive, user confirmation required) ---

# 1. Offer PR creation (if branch has been pushed)
if [ -n "$BRANCH_NAME" ] && [ "$BRANCH_NAME" != "HEAD" ]; then
  HAS_REMOTE=$(git ls-remote --heads origin "$BRANCH_NAME" 2>/dev/null | wc -l | tr -d ' ')
  EXISTING_PR=""
  if [ "$HAS_REMOTE" -gt 0 ] && command -v gh &>/dev/null; then
    EXISTING_PR=$(gh pr list --head "$BRANCH_NAME" --state open --json number --jq '.[0].number' 2>/dev/null || true)
  fi

  if [ "$HAS_REMOTE" -gt 0 ] && [ -z "$EXISTING_PR" ] && command -v gh &>/dev/null; then
    echo "📡 Branch '$BRANCH_NAME' is pushed but has no open PR."
    echo "   Create a PR? (y/N)"
    read -r PR_RESPONSE
    if [[ "$PR_RESPONSE" == "y" ]]; then
      echo "   Creating PR..."
      gh pr create --base stage --head "$BRANCH_NAME" --fill 2>&1 || {
        echo "⚠️  PR creation failed (non-blocking)" >&2
      }
    fi
  fi
fi

# 2. Update CHANGESETS.md (if Houston root available)
if [ -n "$HOUSTON_ROOT" ] && [ -n "$TICKET_ID" ]; then
  CHANGESETS="$HOUSTON_ROOT/tasks/CHANGESETS.md"
  if [ -f "$CHANGESETS" ]; then
    # Check for WIP entries matching this ticket
    WIP_LINE=$(grep -n "$TICKET_ID" "$CHANGESETS" 2>/dev/null | grep -i "WIP" | head -1 || true)
    if [ -n "$WIP_LINE" ]; then
      echo ""
      echo "📋 Found WIP entry in CHANGESETS.md:"
      echo "   $(echo "$WIP_LINE" | cut -d: -f2-)"
      echo "   Mark as Done? (y/N)"
      read -r CS_RESPONSE
      if [[ "$CS_RESPONSE" == "y" ]]; then
        LINE_NUM=$(echo "$WIP_LINE" | cut -d: -f1)
        sed -i '' "${LINE_NUM}s/WIP/Done/" "$CHANGESETS"
        sed -i '' "${LINE_NUM}s/|  *|$/| $(date +%Y-%m-%d) |/" "$CHANGESETS"
        echo "   ✅ CHANGESETS.md updated"
      fi
    fi
  fi
fi

# 3. Offer remote branch deletion
if [ -n "$BRANCH_NAME" ] && [ "$BRANCH_NAME" != "HEAD" ]; then
  HAS_REMOTE=$(git ls-remote --heads origin "$BRANCH_NAME" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$HAS_REMOTE" -gt 0 ]; then
    echo ""
    echo "🗑️  Delete remote branch '$BRANCH_NAME'? (y/N)"
    read -r DEL_RESPONSE
    if [[ "$DEL_RESPONSE" == "y" ]]; then
      git push origin --delete "$BRANCH_NAME" 2>&1 || {
        echo "⚠️  Remote branch deletion failed (non-blocking)" >&2
      }
    fi
  fi
fi

# Go back to parent before deleting
cd "$(dirname "$TICKET_PATH")" || exit

# Remove workspace
echo ""
echo "🗑️  Removing workspace..."
if $IS_WORKTREE; then
  # Get main repo path before removing
  MAIN_REPO=$(get_worktree_main "$TICKET_PATH" 2>/dev/null || true)
  if [ -n "$MAIN_REPO" ]; then
    git -C "$MAIN_REPO" worktree remove "$TICKET_PATH" --force 2>/dev/null || {
      echo "⚠️  git worktree remove failed. Attempting manual cleanup..." >&2
      rm -rf "$TICKET_PATH"
      # Prune stale worktree entries
      [ -n "$MAIN_REPO" ] && git -C "$MAIN_REPO" worktree prune 2>/dev/null || true
    }
  else
    echo "⚠️  Could not determine main repo. Falling back to rm -rf." >&2
    rm -rf "$TICKET_PATH"
  fi
else
  # Legacy cp-R workspace
  rm -rf "$TICKET_PATH"
fi

echo "✅ Ticket workspace closed: $TICKET_DIR_NAME"
