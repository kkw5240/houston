#!/bin/bash

# scripts/close_ticket.sh
# Usage: ./close_ticket.sh <TICKET_PATH>

TICKET_PATH=$1

if [ -z "$TICKET_PATH" ]; then
  echo "Usage: $0 <TICKET_PATH>"
  exit 1
fi

if [ ! -d "$TICKET_PATH" ]; then
  echo "Error: Directory '$TICKET_PATH' not found."
  exit 1
fi

# Safety Check: Don't delete master!
if [[ "$TICKET_PATH" == *"master"* ]]; then
  echo "CRITICAL ERROR: Path contains 'master'. Access Denied."
  exit 1
fi

echo "========================================"
echo "Closing Ticket Repository"
echo "Path: $TICKET_PATH"
echo "========================================"

# Check for unpushed commits?
cd "$TICKET_PATH" || exit
UNPUSHED=$(git log --branches --not --remotes)

if [ -n "$UNPUSHED" ]; then
  echo "⚠️  WARNING: You have UNPUSHED commits in this repository!"
  echo "Are you sure you want to delete permenantly? (y/N)"
  read -r RESPONSE
  if [[ "$RESPONSE" != "y" ]]; then
    echo "Aborted."
    exit 1
  fi
fi

# Delete
echo "Deleting directory..."
rm -rf "$TICKET_PATH"

echo "✅ Ticket Repo Deleted."
