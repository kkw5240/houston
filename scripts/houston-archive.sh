#!/bin/bash
# ============================================================
# houston-archive.sh — Archive completed Change Sets
#
# Moves "Done" CS entries older than N days from CHANGESETS.md
# to a yearly archive file (CHANGESETS_ARCHIVE_{YYYY}.md).
#
# Usage:
#   houston-archive.sh [--days N] [--dry-run]
#
# Default: 14 days
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

CHANGESETS="$HOUSTON_ROOT/tasks/CHANGESETS.md"
TASKS_DIR="$HOUSTON_ROOT/tasks"

if [ ! -f "$CHANGESETS" ]; then
  echo "❌ CHANGESETS.md not found: $CHANGESETS" >&2
  exit 1
fi

# --- Parse arguments ---
DAYS=14
DRY_RUN=false

while [ $# -gt 0 ]; do
  case "$1" in
    --days)
      DAYS="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    *)
      echo "Usage: houston-archive.sh [--days N] [--dry-run]"
      exit 1
      ;;
  esac
done

# --- Calculate cutoff date ---
if date -v-1d +%Y-%m-%d &>/dev/null 2>&1; then
  # macOS date
  CUTOFF=$(date -v-${DAYS}d +%Y-%m-%d)
else
  # GNU date
  CUTOFF=$(date -d "$DAYS days ago" +%Y-%m-%d)
fi

echo "📡 Houston Archive"
echo "   Cutoff: $CUTOFF ($DAYS days ago)"
echo "   Source: tasks/CHANGESETS.md"
if $DRY_RUN; then
  echo "   Mode:   DRY RUN (no changes will be made)"
fi
echo ""

# --- Read CHANGESETS.md and separate header, table header, and rows ---
HEADER_LINES=()
TABLE_HEADER=()
DATA_ROWS=()
ARCHIVE_ROWS=()
KEEP_ROWS=()

reading_header=true
table_header_done=false

while IFS= read -r line; do
  # Detect table rows (start with |)
  if echo "$line" | grep -q '^|'; then
    if $reading_header; then
      reading_header=false
    fi

    # First two | lines are table header + separator
    if ! $table_header_done; then
      TABLE_HEADER+=("$line")
      # The separator line (|:---|...) marks end of table header
      if echo "$line" | grep -q '^| *:'; then
        table_header_done=true
      fi
      continue
    fi

    # Data row — check if Done + older than cutoff
    status=$(echo "$line" | awk -F'|' '{print $4}' | xargs)
    date_field=$(echo "$line" | awk -F'|' '{print $(NF-1)}' | xargs)

    if [ "$status" = "Done" ] && [ -n "$date_field" ] && [[ "$date_field" < "$CUTOFF" ]]; then
      ARCHIVE_ROWS+=("$line")
    else
      KEEP_ROWS+=("$line")
    fi
  else
    if $reading_header; then
      HEADER_LINES+=("$line")
    fi
  fi
done < "$CHANGESETS"

ARCHIVE_COUNT=${#ARCHIVE_ROWS[@]}
KEEP_COUNT=${#KEEP_ROWS[@]}

echo "   Total data rows: $((ARCHIVE_COUNT + KEEP_COUNT))"
echo "   To archive:      $ARCHIVE_COUNT (Done + older than $DAYS days)"
echo "   To keep:         $KEEP_COUNT"
echo ""

if [ "$ARCHIVE_COUNT" -eq 0 ]; then
  echo "✅ Nothing to archive. All entries are recent or still active."
  exit 0
fi

# --- Show preview of entries to be archived ---
echo "📋 Entries to archive:"
for row in "${ARCHIVE_ROWS[@]}"; do
  cs_id=$(echo "$row" | awk -F'|' '{print $2}' | xargs)
  date_field=$(echo "$row" | awk -F'|' '{print $(NF-1)}' | xargs)
  echo "   - $cs_id ($date_field)"
done
echo ""

if $DRY_RUN; then
  echo "🛰️  Dry run complete. No files were modified."
  exit 0
fi

# --- Group archive rows by year ---
declare -A YEARLY_ROWS

for row in "${ARCHIVE_ROWS[@]}"; do
  date_field=$(echo "$row" | awk -F'|' '{print $(NF-1)}' | xargs)
  year=$(echo "$date_field" | cut -d'-' -f1)
  [ -z "$year" ] && year="unknown"
  YEARLY_ROWS["$year"]+="$row"$'\n'
done

# --- Write to archive files (append) ---
for year in "${!YEARLY_ROWS[@]}"; do
  ARCHIVE_FILE="$TASKS_DIR/CHANGESETS_ARCHIVE_${year}.md"

  if [ ! -f "$ARCHIVE_FILE" ]; then
    # Create new archive file with header
    {
      echo "# Change Sets Archive — $year"
      echo ""
      echo "Archived completed Change Sets from \`tasks/CHANGESETS.md\`."
      echo ""
      for h in "${TABLE_HEADER[@]}"; do
        echo "$h"
      done
    } > "$ARCHIVE_FILE"
  fi

  # Append rows
  while IFS= read -r row; do
    [ -n "$row" ] && echo "$row" >> "$ARCHIVE_FILE"
  done <<< "${YEARLY_ROWS[$year]}"

  row_count=$(echo -n "${YEARLY_ROWS[$year]}" | grep -c '^|' || true)
  echo "  ✅ CHANGESETS_ARCHIVE_${year}.md — $row_count entries appended"
done

# --- Rewrite active CHANGESETS.md ---
{
  for h in "${HEADER_LINES[@]}"; do
    echo "$h"
  done
  for h in "${TABLE_HEADER[@]}"; do
    echo "$h"
  done
  for row in "${KEEP_ROWS[@]}"; do
    echo "$row"
  done
} > "$CHANGESETS"

echo "  ✅ CHANGESETS.md — $KEEP_COUNT entries retained"
echo ""
echo "🚀 Archive complete."
