#!/bin/bash
# ============================================================
# houston-undock.sh — Remove a repository from the Houston fleet
#
# Usage:
#   houston-undock.sh <PROJECT_CODE>
#
# Example:
#   houston-undock.sh BW
#
# Note: This does NOT delete the repo directory. You must remove it manually.
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_DIR="$(dirname "$SCRIPT_DIR")"
FLEET_FILE="$WORKSPACE_DIR/.houston/fleet.yaml"

CODE="$1"

# ---- Validation ----
if [ -z "$CODE" ]; then
  echo "Usage: $0 <PROJECT_CODE>"
  echo "Example: $0 BW"
  exit 1
fi

if [ ! -f "$FLEET_FILE" ]; then
  echo "❌ Fleet manifest not found: $FLEET_FILE"
  exit 1
fi

# ---- Find the entry ----
if ! grep -q "code: ${CODE}$" "$FLEET_FILE" 2>/dev/null; then
  echo "❌ [${CODE}] is not in the fleet."
  exit 1
fi

# Extract repo info before removal
REPO_PATH=$(awk "/code: ${CODE}$/{found=1} found && /path:/{print \$2; exit}" "$FLEET_FILE")
REPO_NAME=$(awk "/code: ${CODE}$/{found=1} found && /name:/{sub(/name: /,\"\"); print; exit}" "$FLEET_FILE")

# ---- Check for unpushed commits ----
FULL_PATH="$WORKSPACE_DIR/$REPO_PATH"
if [ -d "$FULL_PATH/.git" ]; then
  UNPUSHED=$(cd "$FULL_PATH" && git log --oneline @{u}..HEAD 2>/dev/null | wc -l | tr -d ' ')
  if [ "$UNPUSHED" -gt 0 ] 2>/dev/null; then
    echo "⚠️  [${CODE}] has ${UNPUSHED} unpushed commit(s) in $REPO_PATH"
    echo "   Are you sure you want to undock? (y/N)"
    read -r CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
      echo "   Aborted."
      exit 0
    fi
  fi
fi

# ---- Remove entry from fleet.yaml ----
# Strategy: Use awk to remove the block starting with "- code: CODE" until the next "- code:" or EOF
TEMP_FILE=$(mktemp)
awk -v code="$CODE" '
  BEGIN { skip=0 }
  /^  - code: / {
    if ($3 == code) { skip=1; next }
    else { skip=0 }
  }
  # Skip blank line immediately before a new entry (cleanup)
  skip && /^$/ { next }
  # Skip indented lines belonging to the current entry
  skip && /^    / { next }
  !skip { print }
' "$FLEET_FILE" > "$TEMP_FILE"

mv "$TEMP_FILE" "$FLEET_FILE"

echo ""
echo "🛬 [${CODE}] ${REPO_NAME} undocked from fleet"
if [ -d "$FULL_PATH" ]; then
  echo ""
  echo "   Directory still exists: $REPO_PATH"
  echo "   To remove it manually:"
  echo "     rm -rf $REPO_PATH"
fi
