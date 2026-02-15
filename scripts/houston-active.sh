#!/bin/bash
# ============================================================
# houston-active.sh — Show all active ticket workspaces
#
# Scans fleet projects for T-* directories and reports their
# git branch, last commit, and dirty status.
#
# Usage: houston active
# ============================================================

set -e

# --- Load common library ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/houston-lib.sh"

HOUSTON_ROOT=$(find_houston_root) || {
  echo "❌ Not inside a Houston workspace" >&2
  exit 1
}
FLEET="$HOUSTON_ROOT/.houston/fleet.yaml"

if [ ! -f "$FLEET" ]; then
  echo "❌ Fleet manifest not found: $FLEET" >&2
  exit 1
fi

# Set terminal title
echo -ne "\033]0;Houston: Active Workspaces\007"

echo "🛰️  Active Ticket Workspaces"
echo ""

TOTAL=0
DIRTY_COUNT=0

# Collect unique project directories from fleet.yaml
fleet_parse_all

for project_dir in "${PROJECT_DIRS[@]}"; do
  abs_dir="$HOUSTON_ROOT/$project_dir"
  [ ! -d "$abs_dir" ] && continue

  # Find T-* directories (ticket workspaces)
  has_tickets=false
  for ticket_dir in "$abs_dir"/T-*; do
    [ ! -d "$ticket_dir" ] && continue
    [ ! -e "$ticket_dir/.git" ] && continue

    if ! $has_tickets; then
      echo "📂 $project_dir/"
      has_tickets=true
    fi

    dirname_only=$(basename "$ticket_dir")
    TOTAL=$((TOTAL + 1))

    # Get git info
    branch=$(cd "$ticket_dir" && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "???")
    last_commit=$(cd "$ticket_dir" && git log -1 --format="%cr — %s" 2>/dev/null || echo "no commits")

    # Check dirty status
    dirty_files=$(cd "$ticket_dir" && git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    unpushed=$(cd "$ticket_dir" && git log --branches --not --remotes --oneline 2>/dev/null | wc -l | tr -d ' ')

    status_icon="✅ Clean"
    if [ "$dirty_files" -gt 0 ]; then
      status_icon="⚠️  ${dirty_files} uncommitted changes"
      DIRTY_COUNT=$((DIRTY_COUNT + 1))
    fi

    push_info=""
    if [ "$unpushed" -gt 0 ]; then
      push_info=" | 📤 ${unpushed} unpushed commits"
    fi

    echo "  $dirname_only/"
    echo "    🌿 $branch"
    echo "    📝 $last_commit"
    echo "    $status_icon$push_info"
    echo ""
  done
done

if [ "$TOTAL" -eq 0 ]; then
  echo "  (no active ticket workspaces found)"
  echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Total: $TOTAL active workspaces"
[ "$DIRTY_COUNT" -gt 0 ] && echo "⚠️  $DIRTY_COUNT with uncommitted changes"
