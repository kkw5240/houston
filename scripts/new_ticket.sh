#!/bin/bash
# ============================================================
# scripts/new_ticket.sh
# Creates an isolated ticket workspace from a source repository.
#
# Usage:
#   ./new_ticket.sh <SOURCE_PATH> <TICKET_ID> [DESCRIPTION]
#
# When called via `houston ticket <CODE>`, the environment variable
# HOUSTON_BASE_BRANCH is set to the fleet.yaml branch for auto-sync.
#
# Example:
#   ./new_ticket.sh ../my-project/source T-XX-100 feature-name
# ============================================================

set -e

MASTER_PATH=$1
TICKET_ID=$2
DESC=$3

# Help / Usage
if [ -z "$MASTER_PATH" ] || [ -z "$TICKET_ID" ]; then
  echo "Usage: $0 <SOURCE_PATH> <TICKET_ID> [DESCRIPTION]"
  echo "Example: $0 ../my-project/source T-XX-100 feature-name"
  exit 1
fi

# Resolve absolute path for source
MASTER_ABS_PATH=$(cd "$MASTER_PATH" && pwd)
PROJECT_DIR=$(dirname "$MASTER_ABS_PATH")
TARGET_DIR_NAME="${TICKET_ID}"

if [ -n "$DESC" ]; then
  TARGET_DIR_NAME="${TARGET_DIR_NAME}-${DESC}"
fi

TARGET_PATH="${PROJECT_DIR}/${TARGET_DIR_NAME}"

# Validation
if [ ! -d "$MASTER_ABS_PATH" ]; then
  echo "❌ Source path '$MASTER_PATH' does not exist." >&2
  exit 1
fi

if [ -d "$TARGET_PATH" ]; then
  echo "❌ Target directory '$TARGET_PATH' already exists." >&2
  exit 1
fi

echo "🚀 Creating Ticket Workspace"
echo "   Source: $MASTER_ABS_PATH"
echo "   Target: $TARGET_PATH"
echo ""

# 1. Sync source to base branch
echo "[1/3] 📡 Syncing source repository..."
cd "$MASTER_ABS_PATH" || exit

# Use HOUSTON_BASE_BRANCH from houston CLI, or fall back to current branch
BASE_BRANCH="${HOUSTON_BASE_BRANCH:-}"
if [ -n "$BASE_BRANCH" ]; then
  CURRENT=$(git rev-parse --abbrev-ref HEAD)
  if [ "$CURRENT" != "$BASE_BRANCH" ]; then
    git checkout "$BASE_BRANCH" 2>/dev/null || {
      echo "⚠️  Branch '$BASE_BRANCH' not found locally. Fetching..." >&2
      git fetch origin "$BASE_BRANCH"
      git checkout "$BASE_BRANCH"
    }
  fi
  echo "   Base branch: $BASE_BRANCH (from fleet.yaml)"
  git pull origin "$BASE_BRANCH" || { echo "⚠️  git pull failed (skipping)"; }
else
  CURRENT=$(git rev-parse --abbrev-ref HEAD)
  echo "   Base branch: $CURRENT (current)"
  git pull origin "$CURRENT" || { echo "⚠️  git pull failed (skipping)"; }
fi

# 2. Copy Repository
echo "[2/3] 📂 Cloning to ticket workspace..."
cp -R "$MASTER_ABS_PATH" "$TARGET_PATH"

# 3. Create Branch (Houston convention: feat/T-{ID}--CS-{NN})
echo "[3/3] 🌿 Setting up git branch..."
cd "$TARGET_PATH" || exit

# Auto-increment CS number: find existing feat/T-{ID}--CS-* branches
LAST_CS=$(git branch -a 2>/dev/null \
  | sed 's|.*remotes/origin/||; s|^ *||' \
  | grep "^feat/${TICKET_ID}--CS-" \
  | sed "s|feat/${TICKET_ID}--CS-||" \
  | sort -n \
  | tail -1)

if [ -n "$LAST_CS" ]; then
  # Remove leading zeros for arithmetic, then re-pad
  NEXT_CS=$(printf "%02d" $(( 10#$LAST_CS + 1 )))
else
  NEXT_CS="01"
fi

BRANCH_NAME="feat/${TICKET_ID}--CS-${NEXT_CS}"
git checkout -b "$BRANCH_NAME"

echo ""
echo "✅ Ticket workspace created!"
echo "   📂 Path:   $TARGET_PATH"
echo "   🌿 Branch: $BRANCH_NAME"

# Set terminal title
echo -ne "\033]0;Houston: ${TICKET_ID} (${BRANCH_NAME})\007"
