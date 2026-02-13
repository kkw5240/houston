#!/bin/bash
# ============================================================
# Houston Git Hook Installer
# Installs a pre-commit hook that auto-rebuilds agent adapters
# when .houston/ source files are modified.
#
# Usage: .houston/install-hooks.sh
# ============================================================

set -e

HOUSTON_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_DIR="$(dirname "$HOUSTON_DIR")"
HOOK_FILE="$WORKSPACE_DIR/.git/hooks/pre-commit"

# Check if .git exists
if [ ! -d "$WORKSPACE_DIR/.git" ]; then
  echo "Error: No .git directory found at $WORKSPACE_DIR"
  echo "Run this script from a git repository."
  exit 1
fi

# --- Read config ---
CONFIG="$HOUSTON_DIR/config.yaml"
PRE_COMMIT_BUILD="true"  # default
if [ -f "$CONFIG" ]; then
  val=$(grep 'pre_commit_build:' "$CONFIG" | awk '{print $2}')
  [ "$val" = "false" ] && PRE_COMMIT_BUILD="false"
fi

if [ "$PRE_COMMIT_BUILD" = "false" ]; then
  echo "Pre-commit build hook disabled in config.yaml"
  # Remove existing hook if present
  [ -f "$HOOK_FILE" ] && rm "$HOOK_FILE"
  exit 0
fi

# Create hooks directory if needed
mkdir -p "$WORKSPACE_DIR/.git/hooks"

# Write the pre-commit hook
# The hook reads config.yaml at commit time to get the current adapter list
cat > "$HOOK_FILE" << 'HOOK_EOF'
#!/bin/bash
# Houston Auto-Build Hook
# Rebuilds agent adapters when .houston/ source files change.

if git diff --cached --name-only | grep -q "^\.houston/"; then
  echo "[Houston] Source files changed. Rebuilding agent adapters..."
  .houston/build.sh

  # Stage adapters listed in config.yaml (or defaults)
  CONFIG=".houston/config.yaml"
  if [ -f "$CONFIG" ]; then
    in_adapters=false
    while IFS= read -r line; do
      if echo "$line" | grep -q '^adapters:'; then
        in_adapters=true
        continue
      fi
      if $in_adapters && echo "$line" | grep -q '^[a-z]'; then
        break
      fi
      if $in_adapters; then
        path=$(echo "$line" | sed -n 's/^  *- *//p')
        [ -n "$path" ] && [ -f "$path" ] && git add "$path"
      fi
    done < "$CONFIG"
  else
    # Fallback: stage default adapters
    for f in CLAUDE.md .cursorrules .windsurfrules .github/copilot-instructions.md; do
      [ -f "$f" ] && git add "$f"
    done
  fi

  echo "[Houston] Adapters rebuilt and staged."
fi
HOOK_EOF

chmod +x "$HOOK_FILE"

echo "Houston pre-commit hook installed at: $HOOK_FILE"
echo "Agent adapters will auto-rebuild when .houston/ files are committed."
