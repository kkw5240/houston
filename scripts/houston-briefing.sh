#!/bin/bash
# ============================================================
# houston-briefing.sh — Session briefing for current work status
#
# Combines: active workspaces + task board + changesets
# into a quick status report for session start or context recovery.
#
# Usage: houston briefing
# ============================================================

set -e

# --- Find Houston root ---
find_houston_root() {
  local dir="$PWD"
  while [ "$dir" != "/" ]; do
    if [ -d "$dir/.houston" ]; then
      echo "$dir"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  echo "❌ Not inside a Houston workspace" >&2
  return 1
}

HOUSTON_ROOT=$(find_houston_root) || exit 1
FLEET="$HOUSTON_ROOT/.houston/fleet.yaml"
TASK_BOARD="$HOUSTON_ROOT/tasks/TASK_BOARD.md"
CHANGESETS="$HOUSTON_ROOT/tasks/CHANGESETS.md"

TODAY=$(date +"%Y-%m-%d")

# Set terminal title
echo -ne "\033]0;Houston: Briefing ($TODAY)\007"

echo "📡 Houston Briefing — $TODAY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# --- Section 1: Active Workspaces ---
echo "🎯 Active Workspaces:"
echo ""

TOTAL=0
WORKSPACE_LINES=()

# Collect project dirs from fleet
PROJECT_DIRS=()
if [ -f "$FLEET" ]; then
  while IFS= read -r line; do
    path=$(echo "$line" | sed -n 's/.*path: *//p')
    if [ -n "$path" ]; then
      parent=$(dirname "$path")
      local_found=false
      for existing in "${PROJECT_DIRS[@]}"; do
        [ "$existing" = "$parent" ] && local_found=true && break
      done
      $local_found || PROJECT_DIRS+=("$parent")
    fi
  done < "$FLEET"
fi

for project_dir in "${PROJECT_DIRS[@]}"; do
  abs_dir="$HOUSTON_ROOT/$project_dir"
  [ ! -d "$abs_dir" ] && continue

  for ticket_dir in "$abs_dir"/T-*; do
    [ ! -d "$ticket_dir" ] && continue
    [ ! -d "$ticket_dir/.git" ] && continue

    TOTAL=$((TOTAL + 1))
    dirname_only=$(basename "$ticket_dir")
    branch=$(cd "$ticket_dir" && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "???")
    dirty_files=$(cd "$ticket_dir" && git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    unpushed=$(cd "$ticket_dir" && git log --branches --not --remotes --oneline 2>/dev/null | wc -l | tr -d ' ')
    last_commit_msg=$(cd "$ticket_dir" && git log -1 --format="%s" 2>/dev/null || echo "")
    last_commit_time=$(cd "$ticket_dir" && git log -1 --format="%cr" 2>/dev/null || echo "")

    status=""
    [ "$dirty_files" -gt 0 ] && status="${status}⚠️ ${dirty_files} dirty "
    [ "$unpushed" -gt 0 ] && status="${status}📤 ${unpushed} unpushed "
    [ -z "$status" ] && status="✅ clean"

    echo "  📂 $dirname_only"
    echo "     Branch: $branch"
    echo "     Last:   $last_commit_msg ($last_commit_time)"
    echo "     Status: $status"
    echo ""
  done
done

if [ "$TOTAL" -eq 0 ]; then
  echo "  (no active ticket workspaces)"
  echo ""
fi

# --- Section 2: Task Board (In Progress) ---
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Task Board — In Progress:"
echo ""

if [ -f "$TASK_BOARD" ]; then
  in_progress=false
  while IFS= read -r line; do
    # Detect "In Progress" section
    if echo "$line" | grep -qi "in progress"; then
      in_progress=true
      continue
    fi
    # Stop at next section header
    if $in_progress && echo "$line" | grep -q "^## "; then
      break
    fi
    # Print non-empty lines in the In Progress section
    if $in_progress && [ -n "$line" ]; then
      echo "  $line"
    fi
  done < "$TASK_BOARD"
  $in_progress || echo "  (no task board found)"
else
  echo "  (tasks/TASK_BOARD.md not found)"
fi
echo ""

# --- Section 3: WIP Change Sets ---
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔄 Change Sets — WIP:"
echo ""

if [ -f "$CHANGESETS" ]; then
  # Print header line, then grep for WIP rows
  header=$(grep "^|.*Ticket.*CS.*Repo.*Status" "$CHANGESETS" 2>/dev/null || true)
  separator=$(grep "^|.*:---" "$CHANGESETS" 2>/dev/null | head -1 || true)
  wip_lines=$(grep -i "| *WIP *|" "$CHANGESETS" 2>/dev/null || true)

  if [ -n "$wip_lines" ]; then
    [ -n "$header" ] && echo "  $header"
    [ -n "$separator" ] && echo "  $separator"
    echo "$wip_lines" | while IFS= read -r wip; do
      echo "  $wip"
    done
  else
    echo "  (no WIP change sets)"
  fi
else
  echo "  (tasks/CHANGESETS.md not found)"
fi
echo ""

# --- Section 4: Tips ---
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💡 Quick Commands:"
echo "   houston active             — detailed workspace view"
echo "   houston ticket XX T-XX-100 — create new workspace"
echo "   houston status --fetch     — fleet sync status"
echo "   houston info <CODE>        — project details"
