#!/bin/bash
# ============================================================
# houston-status.sh — Show the status of all docked repositories
#
# Usage:
#   houston-status.sh [--fetch]
#
# Options:
#   --fetch    Run git fetch on each repo before checking status
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_DIR="$(dirname "$SCRIPT_DIR")"
FLEET_FILE="$WORKSPACE_DIR/.houston/fleet.yaml"

DO_FETCH=false
if [ "$1" = "--fetch" ]; then
  DO_FETCH=true
fi

if [ ! -f "$FLEET_FILE" ]; then
  echo "❌ Fleet manifest not found: $FLEET_FILE"
  exit 1
fi

# ---- Parse fleet.yaml ----
# Extract entries as: code|name|path|branch
ENTRIES=()
while IFS= read -r line; do
  case "$line" in
    *"code: "*)  CURRENT_CODE=$(echo "$line" | sed 's/.*code: //') ;;
    *"name: "*)  CURRENT_NAME=$(echo "$line" | sed 's/.*name: //') ;;
    *"path: "*)  CURRENT_PATH=$(echo "$line" | sed 's/.*path: //') ;;
    *"branch: "*)
      CURRENT_BRANCH=$(echo "$line" | sed 's/.*branch: //')
      ENTRIES+=("${CURRENT_CODE}|${CURRENT_NAME}|${CURRENT_PATH}|${CURRENT_BRANCH}")
      ;;
  esac
done < "$FLEET_FILE"

if [ ${#ENTRIES[@]} -eq 0 ]; then
  echo "🛰️  Houston Fleet Status"
  echo ""
  echo "   No repositories docked. Use houston-dock.sh to register repos."
  exit 0
fi

# ---- Header ----
echo ""
echo "🛰️  Houston Fleet Status"
echo ""

# ---- Column widths ----
# Calculate dynamic widths
MAX_CODE=4
MAX_NAME=10
MAX_BRANCH=6
MAX_STATUS=6

for entry in "${ENTRIES[@]}"; do
  IFS='|' read -r code name path branch <<< "$entry"
  [ ${#code} -gt $MAX_CODE ] && MAX_CODE=${#code}
  [ ${#name} -gt $MAX_NAME ] && MAX_NAME=${#name}
  [ ${#branch} -gt $MAX_BRANCH ] && MAX_BRANCH=${#branch}
done

# Cap name width
[ $MAX_NAME -gt 30 ] && MAX_NAME=30

# ---- Print table ----
printf "   %-${MAX_CODE}s  %-${MAX_NAME}s  %-${MAX_BRANCH}s  %s\n" "Code" "Repository" "Branch" "Status"
printf "   %-${MAX_CODE}s  %-${MAX_NAME}s  %-${MAX_BRANCH}s  %s\n" \
  "$(printf '%*s' $MAX_CODE | tr ' ' '-')" \
  "$(printf '%*s' $MAX_NAME | tr ' ' '-')" \
  "$(printf '%*s' $MAX_BRANCH | tr ' ' '-')" \
  "----------------"

for entry in "${ENTRIES[@]}"; do
  IFS='|' read -r code name path branch <<< "$entry"

  FULL_PATH="$WORKSPACE_DIR/$path"

  # Check if path exists
  if [ ! -d "$FULL_PATH" ]; then
    STATUS="❌ Path missing"
    CURRENT_BRANCH="-"
    printf "   %-${MAX_CODE}s  %-${MAX_NAME}s  %-${MAX_BRANCH}s  %s\n" "$code" "$name" "$CURRENT_BRANCH" "$STATUS"
    continue
  fi

  # Check if it's a git repo
  if [ ! -d "$FULL_PATH/.git" ]; then
    STATUS="❌ Not a git repo"
    CURRENT_BRANCH="-"
    printf "   %-${MAX_CODE}s  %-${MAX_NAME}s  %-${MAX_BRANCH}s  %s\n" "$code" "$name" "$CURRENT_BRANCH" "$STATUS"
    continue
  fi

  cd "$FULL_PATH"

  # Optionally fetch
  if $DO_FETCH; then
    git fetch origin 2>/dev/null
  fi

  # Current branch
  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null | tr -d '\n' || echo "?")

  # Ahead/behind
  AHEAD=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo "?")
  BEHIND=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo "?")

  # Dirty working tree
  DIRTY=""
  if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    DIRTY=" (dirty)"
  fi

  # Build status string
  if [ "$AHEAD" = "?" ] || [ "$BEHIND" = "?" ]; then
    STATUS="⚠️  No upstream"
  elif [ "$AHEAD" -eq 0 ] && [ "$BEHIND" -eq 0 ]; then
    STATUS="✅ Synced${DIRTY}"
  elif [ "$AHEAD" -gt 0 ] && [ "$BEHIND" -gt 0 ]; then
    STATUS="⚠️  ${AHEAD} ahead, ${BEHIND} behind${DIRTY}"
  elif [ "$AHEAD" -gt 0 ]; then
    STATUS="⚠️  ${AHEAD} unpushed${DIRTY}"
  else
    STATUS="⚠️  ${BEHIND} behind${DIRTY}"
  fi

  printf "   %-${MAX_CODE}s  %-${MAX_NAME}s  %-${MAX_BRANCH}s  %s\n" "$code" "$name" "$CURRENT_BRANCH" "$STATUS"
done

echo ""
cd "$WORKSPACE_DIR"
