#!/bin/bash
# ============================================================
# houston-dock.sh — Register a repository in the Houston fleet
#
# Usage:
#   houston-dock.sh <repo_url> --code <CODE> [--branch <branch>] [--name "<name>"] [--stack <stack>] [--has-claude-md]
#   houston-dock.sh --existing <path> --code <CODE> [--name "<name>"] [--stack <stack>] [--has-claude-md]
#
# Examples:
#   houston-dock.sh https://github.com/org/my-backend.git --code BW --branch master --name "My Backend Service"
#   houston-dock.sh --existing ./my-project/source --code BW --name "My Backend Service"
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_DIR="$(dirname "$SCRIPT_DIR")"
FLEET_FILE="$WORKSPACE_DIR/.houston/fleet.yaml"

# ---- Defaults ----
REPO_URL=""
EXISTING_PATH=""
CODE=""
BRANCH="master"
NAME=""
STACK=""
HAS_CLAUDE_MD="false"

# ---- Parse arguments ----
while [[ $# -gt 0 ]]; do
  case $1 in
    --existing)
      EXISTING_PATH="$2"
      shift 2
      ;;
    --code)
      CODE="$2"
      shift 2
      ;;
    --branch)
      BRANCH="$2"
      shift 2
      ;;
    --name)
      NAME="$2"
      shift 2
      ;;
    --stack)
      STACK="$2"
      shift 2
      ;;
    --has-claude-md)
      HAS_CLAUDE_MD="true"
      shift
      ;;
    --help|-h)
      echo "Usage:"
      echo "  $0 <repo_url> --code <CODE> [--branch <branch>] [--name \"<name>\"] [--stack <stack>] [--has-claude-md]"
      echo "  $0 --existing <path> --code <CODE> [--name \"<name>\"] [--stack <stack>] [--has-claude-md]"
      echo ""
      echo "Options:"
      echo "  --code         Project code (e.g., BW, EH, PR) — REQUIRED"
      echo "  --branch       Default branch (default: master)"
      echo "  --name         Human-readable repo name"
      echo "  --stack        Tech stack (e.g., python/fastapi, flutter)"
      echo "  --has-claude-md  Repo has a CLAUDE.md file"
      echo "  --existing     Path to already-cloned repo (skip clone)"
      exit 0
      ;;
    *)
      # First positional arg = repo URL
      if [ -z "$REPO_URL" ] && [ -z "$EXISTING_PATH" ]; then
        REPO_URL="$1"
      else
        echo "❌ Unknown argument: $1"
        exit 1
      fi
      shift
      ;;
  esac
done

# ---- Validation ----
if [ -z "$CODE" ]; then
  echo "❌ --code is required. Example: --code BW"
  exit 1
fi

if [ -z "$REPO_URL" ] && [ -z "$EXISTING_PATH" ]; then
  echo "❌ Provide a repo URL or --existing <path>"
  exit 1
fi

# Check for duplicate code in fleet.yaml
if [ -f "$FLEET_FILE" ]; then
  if grep -q "code: ${CODE}$" "$FLEET_FILE" 2>/dev/null; then
    echo "❌ [${CODE}] is already docked in the fleet. Use houston-undock.sh first."
    exit 1
  fi
fi

# ---- Determine repo path ----
if [ -n "$EXISTING_PATH" ]; then
  # --existing mode: validate the path
  if [ ! -d "$EXISTING_PATH" ]; then
    echo "❌ Path does not exist: $EXISTING_PATH"
    exit 1
  fi
  if [ ! -d "$EXISTING_PATH/.git" ]; then
    echo "❌ Not a git repository: $EXISTING_PATH"
    exit 1
  fi

  # Resolve to relative path from workspace
  EXISTING_ABS="$(cd "$EXISTING_PATH" && pwd)"
  REL_PATH="${EXISTING_ABS#$WORKSPACE_DIR/}"

  # If path is outside workspace, REL_PATH will still be absolute
  if [[ "$REL_PATH" == /* ]]; then
    echo "⚠️  Path is outside the workspace: $EXISTING_ABS"
    echo "   Fleet paths should be relative to: $WORKSPACE_DIR"
    echo "   Storing absolute path. Consider moving the repo inside the workspace."
  fi

  # Derive repo URL from git remote if not provided
  if [ -z "$REPO_URL" ]; then
    REPO_URL=$(cd "$EXISTING_PATH" && git remote get-url origin 2>/dev/null || echo "")
  fi

  # Derive name from directory if not provided
  if [ -z "$NAME" ]; then
    NAME="$(basename "$(dirname "$REL_PATH")")"
  fi

  echo "📡 Registering existing repository..."
  echo "   Path: $REL_PATH"

else
  # Clone mode: derive project folder name from URL
  REPO_BASENAME=$(basename "$REPO_URL" .git)

  # Extract project folder name (e.g., my-project-backend -> my-project)
  # Convention: first two segments joined by hyphen
  PROJECT_FOLDER=$(echo "$REPO_BASENAME" | sed -E 's/^(lines-[^-]+|imdr-[^-]+).*/\1/')
  REL_PATH="${PROJECT_FOLDER}/source"
  TARGET_DIR="$WORKSPACE_DIR/$PROJECT_FOLDER"

  if [ -d "$WORKSPACE_DIR/$REL_PATH" ]; then
    echo "❌ Directory already exists: $REL_PATH"
    echo "   Use --existing if you want to register it."
    exit 1
  fi

  if [ -z "$NAME" ]; then
    NAME="$REPO_BASENAME"
  fi

  echo "📡 Cloning repository..."
  echo "   URL: $REPO_URL"
  echo "   Destination: $REL_PATH"

  mkdir -p "$TARGET_DIR"
  git clone "$REPO_URL" "$WORKSPACE_DIR/$REL_PATH"
  cd "$WORKSPACE_DIR/$REL_PATH"
  git checkout "$BRANCH" 2>/dev/null || true
fi

# ---- Detect has_claude_md if not explicitly set ----
FULL_PATH="$WORKSPACE_DIR/$REL_PATH"
if [ "$HAS_CLAUDE_MD" = "false" ] && [ -f "$FULL_PATH/CLAUDE.md" ]; then
  HAS_CLAUDE_MD="true"
fi

# ---- Detect stack if not provided ----
if [ -z "$STACK" ]; then
  if [ -f "$FULL_PATH/requirements.txt" ] || [ -f "$FULL_PATH/pyproject.toml" ]; then
    if grep -rq "fastapi" "$FULL_PATH/requirements.txt" "$FULL_PATH/pyproject.toml" 2>/dev/null; then
      STACK="python/fastapi"
    elif grep -rq "lambda" "$FULL_PATH/requirements.txt" "$FULL_PATH/pyproject.toml" 2>/dev/null; then
      STACK="python/lambda"
    else
      STACK="python"
    fi
  elif [ -f "$FULL_PATH/pubspec.yaml" ]; then
    STACK="flutter"
  elif [ -f "$FULL_PATH/go.mod" ]; then
    if grep -q "gin" "$FULL_PATH/go.mod" 2>/dev/null; then
      STACK="golang/gin"
    else
      STACK="golang"
    fi
  elif [ -f "$FULL_PATH/package.json" ]; then
    STACK="node"
  elif [ -f "$FULL_PATH/main.tf" ]; then
    STACK="terraform"
  else
    STACK="unknown"
  fi
fi

# ---- Append to fleet.yaml ----
if [ ! -f "$FLEET_FILE" ]; then
  mkdir -p "$(dirname "$FLEET_FILE")"
  cat > "$FLEET_FILE" << 'HEADER'
# .houston/fleet.yaml
# Houston Fleet Manifest

fleet:
HEADER
fi

cat >> "$FLEET_FILE" << EOF

  - code: ${CODE}
    name: ${NAME}
    repo: ${REPO_URL}
    branch: ${BRANCH}
    path: ${REL_PATH}
    stack: ${STACK}
    has_claude_md: ${HAS_CLAUDE_MD}
EOF

echo ""
echo "🚀 [${CODE}] ${NAME} docked successfully"
echo "   Path: ${REL_PATH}"
echo "   Branch: ${BRANCH}"
echo "   Stack: ${STACK}"
echo "   CLAUDE.md: ${HAS_CLAUDE_MD}"
