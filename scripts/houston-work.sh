#!/bin/bash
# ============================================================
# houston-work.sh — Launch AI agent with ticket context
#
# Runs resume scan, saves context, and launches the configured
# AI agent with the resume context as initial prompt.
#
# Usage:
#   houston-work.sh [--agent <cli>] <TICKET_ID>
#
# Agent is configured in .houston/config.yaml:
#   agent:
#     cli: claude    # claude | gemini | codex
#     auto_resume: true
#
# Examples:
#   houston-work.sh T-XX-100
#   houston-work.sh --agent codex T-XX-100
#   houston-work.sh T-INFRA-001
# ============================================================

set -e

# --- Load common library ---
source "$(cd "$(dirname "$0")" && pwd)/houston-lib.sh"

HOUSTON_ROOT=$(find_houston_root) || {
  echo "❌ Not inside a Houston workspace (.houston/ not found)" >&2
  exit 1
}

AGENT_OVERRIDE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --agent|-a)
      AGENT_OVERRIDE="${2:-}"
      if [ -z "$AGENT_OVERRIDE" ]; then
        echo "Usage: houston work [--agent <cli>] <TICKET_ID>"
        echo ""
        echo "Examples:"
        echo "  houston work T-XX-100"
        echo "  houston work --agent codex T-XX-100"
        exit 1
      fi
      shift 2
      ;;
    --help|-h)
      echo "Usage: houston work [--agent <cli>] <TICKET_ID>"
      echo ""
      echo "Examples:"
      echo "  houston work T-XX-100"
      echo "  houston work --agent codex T-XX-100"
      exit 0
      ;;
    --*)
      echo "❌ Unknown option: $1" >&2
      echo "Usage: houston work [--agent <cli>] <TICKET_ID>" >&2
      exit 1
      ;;
    *)
      break
      ;;
  esac
done

TICKET_ID="${1:-}"
if [ -z "$TICKET_ID" ]; then
  echo "Usage: houston work [--agent <cli>] <TICKET_ID>"
  echo ""
  echo "Examples:"
  echo "  houston work T-XX-100"
  echo "  houston work --agent codex T-XX-100"
  echo "  houston work T-INFRA-001"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="$HOUSTON_ROOT/.houston/config.yaml"

# --- Read agent config ---
AGENT_CLI="claude"
AUTO_RESUME="true"

if [ -f "$CONFIG" ]; then
  # Parse agent.cli
  val=$(grep -A5 '^agent:' "$CONFIG" 2>/dev/null | grep 'cli:' | head -1 | awk '{print $2}')
  [ -n "$val" ] && AGENT_CLI="$val"

  # Parse agent.auto_resume
  val=$(grep -A5 '^agent:' "$CONFIG" 2>/dev/null | grep 'auto_resume:' | head -1 | awk '{print $2}')
  [ "$val" = "false" ] && AUTO_RESUME="false"
fi

if [ -n "$AGENT_OVERRIDE" ]; then
  AGENT_CLI="$AGENT_OVERRIDE"
fi

# --- Verify agent CLI is installed ---
if ! command -v "$AGENT_CLI" &>/dev/null; then
  echo "❌ Agent CLI not found: $AGENT_CLI" >&2
  echo "   Install it or change agent.cli in .houston/config.yaml" >&2
  exit 1
fi

# --- Run resume scan ---
CONTEXT_FILE="$HOUSTON_ROOT/.houston/resume-context.md"

if [ "$AUTO_RESUME" = "true" ]; then
  echo "📡 Running resume scan for ${TICKET_ID}..."
  echo ""

  # Capture resume output
  RESUME_OUTPUT=$("$SCRIPT_DIR/houston-resume.sh" "$TICKET_ID" 2>&1) || {
    echo "❌ Resume scan failed for ${TICKET_ID}" >&2
    echo "$RESUME_OUTPUT" >&2
    exit 1
  }

  # Display resume output
  echo "$RESUME_OUTPUT"
  echo ""

  # Save context file (shared with houston resume-context --ensure)
  houston_write_resume_context "$CONTEXT_FILE" "$TICKET_ID" "$RESUME_OUTPUT"

  echo "📋 Context saved: .houston/resume-context.md"
  echo ""
fi

# --- Launch agent ---
echo "🚀 Launching ${AGENT_CLI}..."
echo ""

# Build the initial prompt
PROMPT="Houston, ${TICKET_ID} 작업을 이어서 진행해줘."

if [ "$AUTO_RESUME" = "true" ] && [ -f "$CONTEXT_FILE" ]; then
  PROMPT="$(cat "$CONTEXT_FILE")"
fi

# Agent-specific launch
cd "$HOUSTON_ROOT"

case "$AGENT_CLI" in
  claude)
    # claude "prompt" → interactive session with initial message
    exec claude "$PROMPT"
    ;;

  gemini)
    # gemini -i "prompt" → interactive mode with initial prompt
    exec gemini -i "$PROMPT"
    ;;

  codex)
    # codex "prompt" → interactive session with initial message
    exec codex "$PROMPT"
    ;;

  *)
    # Generic fallback: try passing prompt as positional argument
    echo "⚠️  Unknown agent '$AGENT_CLI'. Attempting generic launch..."
    exec "$AGENT_CLI" "$PROMPT"
    ;;
esac
