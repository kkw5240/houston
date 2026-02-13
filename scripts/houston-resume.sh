#!/bin/bash
# ============================================================
# houston-resume.sh — Resume interrupted ticket work
#
# Scans ticket file, CHANGESETS.md, and git state to produce
# a resumption summary. Zero overhead during work — derives
# state from existing artifacts (git commits, ticket checkboxes).
#
# Usage:
#   houston-resume.sh <TICKET_ID>
#
# Examples:
#   houston-resume.sh T-INFRA-001
#   houston-resume.sh T-XX-100
# ============================================================

set -e

# --- Find Houston workspace root ---
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

HOUSTON_ROOT=$(find_houston_root) || {
  echo "❌ Not inside a Houston workspace (.houston/ not found)" >&2
  exit 1
}

TICKET_ID="${1:-}"
if [ -z "$TICKET_ID" ]; then
  echo "Usage: houston resume <TICKET_ID>"
  echo ""
  echo "Examples:"
  echo "  houston resume T-INFRA-001"
  echo "  houston resume T-XX-100"
  exit 1
fi

# --- Step 1: Find ticket file ---
TICKET_FILE=""
for f in "$HOUSTON_ROOT/tickets/"*"${TICKET_ID}"*".md"; do
  if [ -f "$f" ]; then
    TICKET_FILE="$f"
    break
  fi
done

if [ -z "$TICKET_FILE" ]; then
  echo "❌ Ticket not found: ${TICKET_ID}" >&2
  echo "   Searched: $HOUSTON_ROOT/tickets/" >&2
  exit 1
fi

TICKET_NAME=$(basename "$TICKET_FILE" .md)

# --- Step 2: Extract ticket status ---
TICKET_STATUS=$(grep 'Status' "$TICKET_FILE" 2>/dev/null | head -1 | awk -F'|' '{print $3}' | sed 's/[* ]//g')
[ -z "$TICKET_STATUS" ] && TICKET_STATUS="Unknown"

echo "🛰️  Resuming ${TICKET_ID}: $(echo "$TICKET_NAME" | sed "s/^T-[A-Z]*-[0-9]*-//" | tr '-' ' ')"
echo "   Ticket: $(basename "$TICKET_FILE")"
echo "   Status: ${TICKET_STATUS}"
echo ""

# --- Step 3: Find WIP/Active CS from CHANGESETS.md ---
CHANGESETS="$HOUSTON_ROOT/tasks/CHANGESETS.md"
echo "📋 Change Sets:"

if [ -f "$CHANGESETS" ]; then
  # Show all CS entries for this ticket
  grep -i "$TICKET_ID" "$CHANGESETS" 2>/dev/null | while IFS='|' read -r _ cs_id _ status repo proof date _; do
    cs_id=$(echo "$cs_id" | xargs)
    status=$(echo "$status" | xargs)
    repo=$(echo "$repo" | xargs)

    # Status icon
    case "$status" in
      Done)   icon="✅" ;;
      WIP)    icon="🔧" ;;
      Review) icon="👀" ;;
      Draft)  icon="📝" ;;
      *)      icon="⬜" ;;
    esac

    echo "   ${icon} ${cs_id}: ${status} (${repo})"
  done

  # Check if there are any WIP entries
  WIP_COUNT=$(grep -i "$TICKET_ID" "$CHANGESETS" 2>/dev/null | grep -c "WIP" || true)
  if [ "$WIP_COUNT" -eq 0 ]; then
    echo "   (No WIP Change Sets found)"
  fi
else
  echo "   ⚠️  CHANGESETS.md not found"
fi

echo ""

# --- Step 4: Find active CS and show IP status from ticket ---
# Extract the current (last) CS section that has unchecked items
echo "📌 Implementation Plan (current CS):"

# Find the last CS section with [ ] items (= incomplete)
# Strategy: find all CS headers, then for the last WIP one, show IPs
CURRENT_CS=""
CURRENT_CS_LINE=0

# Find WIP CS from changesets to know which CS to focus on
WIP_CS_NUM=""
if [ -f "$CHANGESETS" ]; then
  WIP_CS_NUM=$(grep -i "$TICKET_ID" "$CHANGESETS" 2>/dev/null | grep "WIP" | head -1 | awk -F'|' '{print $2}' | xargs | sed 's/.*-//')
fi

# Extract IP items from ticket for the WIP CS (or last incomplete CS)
in_target_cs=false
found_tasks=false

while IFS= read -r line; do
  # Detect CS headers (### CS-NN: ...)
  if echo "$line" | grep -qE '^### CS-'; then
    if [ -n "$WIP_CS_NUM" ]; then
      if echo "$line" | grep -q "CS-${WIP_CS_NUM}"; then
        in_target_cs=true
        echo "   --- $(echo "$line" | sed 's/^### //') ---"
      else
        # Hit a different CS — stop if we were in target
        $in_target_cs && break
      fi
    fi
    continue
  fi

  # Stop at next major section (## N. ...)
  if $in_target_cs && echo "$line" | grep -qE '^## [0-9]+\.'; then
    break
  fi

  # When in target CS, show checklist items ([Pre], IP-*, [Post])
  if $in_target_cs; then
    if echo "$line" | grep -qE '^\- \[(x| )\] '; then
      found_tasks=true
      checked=$(echo "$line" | grep -oE '\[(x| )\]')
      item_text=$(echo "$line" | sed 's/^- \[.\] //')
      if [ "$checked" = "[x]" ]; then
        echo "   ✅ ${item_text}"
      else
        echo "   ⬜ ${item_text}"
      fi
    fi
  fi
done < "$TICKET_FILE"

if ! $found_tasks; then
  # Fallback: show all unchecked IP items from ticket
  echo "   (Could not isolate WIP CS — showing all pending IPs)"
  grep -E '^\- \[ \] IP-' "$TICKET_FILE" 2>/dev/null | while read -r line; do
    ip_text=$(echo "$line" | sed 's/^- \[ \] //')
    echo "   ⬜ ${ip_text}"
  done
fi

echo ""

# --- Step 5: Find ticket workspaces ---
echo "📂 Ticket Workspaces:"

FLEET="$HOUSTON_ROOT/.houston/fleet.yaml"
WORKSPACE_FOUND=false

# Search in fleet repo directories for T-{ID}-* folders
if [ -f "$FLEET" ]; then
  # Extract all paths from fleet.yaml
  grep "path:" "$FLEET" 2>/dev/null | sed 's/.*path: *//' | while read -r fleet_path; do
    repo_dir="$HOUSTON_ROOT/$fleet_path"
    parent_dir=$(dirname "$repo_dir")

    # Look for T-{TICKET_ID}-* directories
    for ws in "$parent_dir"/T-*"${TICKET_ID}"*/; do
      if [ -d "$ws" ]; then
        echo "   📁 $ws"

        # Show branch
        branch=$(cd "$ws" && git branch --show-current 2>/dev/null || echo "?")
        echo "      Branch: $branch"

        # Show last commit
        last_commit=$(cd "$ws" && git log --oneline -1 2>/dev/null || echo "none")
        echo "      Last commit: $last_commit"

        # Show uncommitted changes
        changes=$(cd "$ws" && git status --porcelain 2>/dev/null | wc -l | xargs)
        if [ "$changes" -gt 0 ]; then
          echo "      ⚠️  Uncommitted changes: ${changes} file(s)"
          cd "$ws" && git status --porcelain 2>/dev/null | head -5 | while read -r line; do
            echo "         $line"
          done
          [ "$changes" -gt 5 ] && echo "         ... and $((changes - 5)) more"
        else
          echo "      Clean working tree"
        fi

        WORKSPACE_FOUND=true
      fi
    done
  done
fi

# Also check Houston workspace itself (for INFRA tickets)
if echo "$TICKET_ID" | grep -qi "INFRA"; then
  echo "   📁 $HOUSTON_ROOT/ (Houston workspace)"
  branch=$(cd "$HOUSTON_ROOT" && git branch --show-current 2>/dev/null || echo "?")
  echo "      Branch: $branch"
  last_commit=$(cd "$HOUSTON_ROOT" && git log --oneline -1 2>/dev/null || echo "none")
  echo "      Last commit: $last_commit"
  changes=$(cd "$HOUSTON_ROOT" && git status --porcelain 2>/dev/null | wc -l | xargs)
  if [ "$changes" -gt 0 ]; then
    echo "      ⚠️  Uncommitted changes: ${changes} file(s)"
  else
    echo "      Clean working tree"
  fi
  WORKSPACE_FOUND=true
fi

if ! $WORKSPACE_FOUND; then
  echo "   (No active workspaces found)"
fi

echo ""

# --- Step 6: Recent git activity ---
echo "🕐 Recent Commits (last 5, matching ${TICKET_ID}):"

# Search in Houston workspace
cd "$HOUSTON_ROOT"
git log --oneline --all --grep="$TICKET_ID" -5 2>/dev/null | while read -r line; do
  echo "   $line"
done

# If no commits match ticket ID, show most recent commits
MATCH_COUNT=$(git log --oneline --all --grep="$TICKET_ID" -5 2>/dev/null | wc -l | xargs)
if [ "$MATCH_COUNT" -eq 0 ]; then
  echo "   (No commits matching ${TICKET_ID} — showing recent)"
  git log --oneline -5 2>/dev/null | while read -r line; do
    echo "   $line"
  done
fi

echo ""
echo "📡 Resume scan complete. Ready to continue."
