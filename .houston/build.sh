#!/bin/bash
# ============================================================
# Houston Build System
# Assembles agent-specific instruction files from .houston/ sources.
#
# Adapter variants (3):
#   CLAUDE.md            — STUB_HARNESS: skill blocks replaced with `/skill-name` invocation hints
#   AGENTS.md, GEMINI.md — STUB_READ:    skill blocks replaced with filesystem-read hints
#   All others           — FULL:         marker comments stripped, full inline content kept
#
# Marker mode: If a file already exists, only the content between
# <!-- HOUSTON:START --> and <!-- HOUSTON:END --> markers is replaced.
# User-written content outside the markers is preserved.
#
# If the file does not exist, it is created with Houston content only.
#
# After adapter generation, .houston/skills/*.md are synced to
# ~/.claude/skills/{name}/SKILL.md for Claude Code lazy-loading.
#
# Sources digest cache (.houston/.cache/):
#   On rerun, if all sources (IDENTITY/RULES/PROCESSES/CHECKLIST/config.yaml/
#   skills/*.md/build.sh itself) are byte-identical to the last successful
#   build AND all previously produced output files still exist, the build
#   is skipped. Use --no-cache (or --force-rebuild) to bypass.
#
# Usage: .houston/build.sh [--no-cache | --force-rebuild]
# ============================================================

set -e

HOUSTON_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_DIR="$(dirname "$HOUSTON_DIR")"
SKILLS_DIR="$HOUSTON_DIR/skills"

# --- Cache configuration ---
CACHE_DIR="$HOUSTON_DIR/.cache"
MANIFEST_FILE="$CACHE_DIR/sources-manifest.json"
DIGEST_FILE="$CACHE_DIR/sources-digest.md"

USE_CACHE=true
for arg in "$@"; do
  case "$arg" in
    --no-cache|--force-rebuild)
      USE_CACHE=false
      ;;
    -h|--help)
      sed -n '1,/^# ====/p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
  esac
done

# --- Load adapter list from config ---
CONFIG="$HOUSTON_DIR/config.yaml"
if [ -f "$CONFIG" ]; then
  ADAPTERS=()
  if command -v yq &>/dev/null; then
    # yq available — safe YAML parsing
    mapfile -t ADAPTERS < <(yq -r '.adapters[]' "$CONFIG" 2>/dev/null)
  fi
  # Fallback: bash parsing (when yq unavailable or yq returned nothing)
  if [ ${#ADAPTERS[@]} -eq 0 ]; then
    in_adapters=false
    while IFS= read -r line; do
      # Detect start of adapters: section
      if echo "$line" | grep -q '^adapters:'; then
        in_adapters=true
        continue
      fi
      # Stop at next top-level key
      if $in_adapters && echo "$line" | grep -q '^[a-z]'; then
        break
      fi
      # Extract "  - path/to/file" entries
      if $in_adapters; then
        path=$(echo "$line" | sed -n 's/^  *- *//p')
        [ -n "$path" ] && ADAPTERS+=("$path")
      fi
    done < "$CONFIG"
  fi
else
  # Fallback: default adapter list (no config.yaml)
  ADAPTERS=(
    "AGENTS.md"
    "CLAUDE.md"
    ".cursorrules"
    ".windsurfrules"
    ".github/copilot-instructions.md"
  )
fi

# --- Build source-files list (must mirror what assemble_block consumes) ---
SOURCES=(
  "$HOUSTON_DIR/IDENTITY.md"
  "$HOUSTON_DIR/RULES.md"
  "$HOUSTON_DIR/PROCESSES.md"
  "$HOUSTON_DIR/CHECKLIST.md"
  "$HOUSTON_DIR/config.yaml"
  "$HOUSTON_DIR/build.sh"
)
if [ -d "$SKILLS_DIR" ]; then
  for f in "$SKILLS_DIR"/*.md; do
    [ -f "$f" ] && SOURCES+=("$f")
  done
fi

# --- Build expected-outputs list (manifest verifies all still exist on cache hit) ---
OUTPUT_PATHS=()
for adapter in "${ADAPTERS[@]}"; do
  OUTPUT_PATHS+=("$WORKSPACE_DIR/$adapter")
done
if [ -d "$SKILLS_DIR" ]; then
  for src in "$SKILLS_DIR"/*.md; do
    [ -f "$src" ] || continue
    name=$(basename "$src" .md)
    OUTPUT_PATHS+=("$HOME/.claude/skills/$name/SKILL.md")
  done
fi

# --- Cache hit check ---
# Returns "hit:<last_built>" or "miss:<reason>" on stdout.
cache_status() {
  if [ ! -f "$MANIFEST_FILE" ]; then
    echo "miss:no-manifest"
    return
  fi
  if ! command -v python3 &>/dev/null; then
    echo "miss:no-python3"
    return
  fi
  python3 - "$MANIFEST_FILE" "::SRC::" "${SOURCES[@]}" "::OUT::" "${OUTPUT_PATHS[@]}" <<'PY'
import hashlib, json, os, sys
manifest_file = sys.argv[1]
rest = sys.argv[2:]
src_i = rest.index("::SRC::")
out_i = rest.index("::OUT::")
sources = rest[src_i + 1:out_i]
outputs = rest[out_i + 1:]
try:
    with open(manifest_file) as f:
        manifest = json.load(f)
except Exception as e:
    print(f"miss:manifest-unreadable")
    sys.exit(0)
stored = manifest.get("sources", {})
if set(stored.keys()) != set(sources):
    print("miss:source-set-changed")
    sys.exit(0)
for p in sources:
    if not os.path.isfile(p):
        print(f"miss:source-missing:{os.path.basename(p)}")
        sys.exit(0)
    with open(p, "rb") as f:
        sha = hashlib.sha256(f.read()).hexdigest()
    if sha != stored.get(p, {}).get("sha256"):
        print(f"miss:source-changed:{os.path.basename(p)}")
        sys.exit(0)
for o in outputs:
    if not os.path.isfile(o):
        print(f"miss:output-missing:{os.path.basename(o)}")
        sys.exit(0)
print(f"hit:{manifest.get('last_built', 'unknown')}")
PY
}

mkdir -p "$CACHE_DIR"

if $USE_CACHE; then
  status=$(cache_status)
  if [[ "$status" == hit:* ]]; then
    last_built="${status#hit:}"
    echo "[build] sources unchanged, using cache (last_built=$last_built)"
    exit 0
  fi
  reason="${status#miss:}"
  echo "[build] cache miss ($reason) — rebuilding"
fi

# --- Load source files ---
IDENTITY=$(cat "$HOUSTON_DIR/IDENTITY.md")
RULES_RAW=$(cat "$HOUSTON_DIR/RULES.md")
PROCESSES_RAW=$(cat "$HOUSTON_DIR/PROCESSES.md")
CHECKLIST=$(cat "$HOUSTON_DIR/CHECKLIST.md")

# --- Build FULL variant: strip marker comments, keep section content ---
# Removes <!-- SKILL:*:START --> and <!-- SKILL:*:END --> lines only
strip_skill_markers() {
  local content="$1"
  printf '%s\n' "$content" | grep -vE '^<!-- SKILL:[A-Za-z0-9_-]*:(START|END) -->'
}

RULES_FULL=$(strip_skill_markers "$RULES_RAW")
PROCESSES_FULL=$(strip_skill_markers "$PROCESSES_RAW")

# --- Build STUB variants: replace SKILL marker blocks with lazy-load stubs ---
# Two modes:
#   harness — Claude Code Skills harness invocation (`/skill-name`)
#   read    — filesystem read instruction (for omx/codex via AGENTS.md, gemini-cli via GEMINI.md)
make_stub_content() {
  local content="$1"
  local mode="$2"  # harness | read
  printf '%s\n' "$content" | awk -v mode="$mode" '
    /^<!-- SKILL:[A-Za-z0-9_-]*:START -->/ {
      skill_name = $0
      sub(/^<!-- SKILL:/, "", skill_name)
      sub(/:START -->.*$/, "", skill_name)
      in_block = 1
      heading_printed = 0
      next
    }
    /^<!-- SKILL:[A-Za-z0-9_-]*:END -->/ {
      in_block = 0
      print ""
      next
    }
    in_block {
      if (!heading_printed && /^#+ /) {
        heading = $0
        print heading
        print ""
        if (mode == "harness") {
          print "> 📦 **Lazy-loaded skill**: `/" skill_name "` — invoke via Claude Code Skills harness when triggers match. Full content: `.houston/skills/" skill_name ".md`."
        } else {
          print "> 📦 **Lazy-loaded skill**: `" skill_name "` — Read `.houston/skills/" skill_name ".md` before applying procedure when user input matches triggers (see source frontmatter `triggers:` field)."
        }
        heading_printed = 1
      }
      next
    }
    { print }
  '
}

RULES_STUB_HARNESS=$(make_stub_content "$RULES_RAW" "harness")
PROCESSES_STUB_HARNESS=$(make_stub_content "$PROCESSES_RAW" "harness")
RULES_STUB_READ=$(make_stub_content "$RULES_RAW" "read")
PROCESSES_STUB_READ=$(make_stub_content "$PROCESSES_RAW" "read")

# --- Build skill index for lazy-load adapters ---
# Lists all skills in .houston/skills/ so the LLM can locate them on demand.
build_skill_index() {
  local mode="$1"  # harness | read
  if [ ! -d "$SKILLS_DIR" ]; then
    return
  fi
  printf '## Houston Skills (Lazy-Load Index)\n\n'
  if [ "$mode" = "harness" ]; then
    printf 'Claude Code auto-matches triggers and invokes the skill. The harness reads frontmatter from `~/.claude/skills/{name}/SKILL.md` (synced from `.houston/skills/{name}.md`).\n\n'
  else
    printf 'When the user input matches a skill'\''s triggers, **read the source file** at `.houston/skills/{name}.md` for the full procedure. Each source has frontmatter (`description`, `when_to_use`, `triggers`) describing match criteria.\n\n'
  fi
  printf '| Skill | Description | Source |\n'
  printf '|:---|:---|:---|\n'
  for src in "$SKILLS_DIR"/*.md; do
    [ -f "$src" ] || continue
    local name desc
    name=$(basename "$src" .md)
    desc=$(awk -F': ' '/^description:/ { sub(/^description: */, ""); print; exit }' "$src" | sed 's/|/\\|/g')
    printf '| `%s` | %s | `.houston/skills/%s.md` |\n' "$name" "$desc" "$name"
  done
  printf '\n'
}

SKILL_INDEX_HARNESS=$(build_skill_index "harness")
SKILL_INDEX_READ=$(build_skill_index "read")

# --- Assemble Houston blocks (3 variants) ---
assemble_block() {
  local rules="$1"
  local processes="$2"
  local skill_index="$3"  # empty string for FULL variant
  local index_section=""
  if [ -n "$skill_index" ]; then
    index_section="${skill_index}
---

"
  fi
  printf '%s\n' "<!-- HOUSTON:START — Auto-generated by .houston/build.sh. DO NOT EDIT between markers. -->

${IDENTITY}

---

${index_section}${rules}

---

${processes}

---

${CHECKLIST}

<!-- HOUSTON:END -->"
}

HOUSTON_BLOCK_FULL=$(assemble_block "$RULES_FULL" "$PROCESSES_FULL" "")
HOUSTON_BLOCK_STUB_HARNESS=$(assemble_block "$RULES_STUB_HARNESS" "$PROCESSES_STUB_HARNESS" "$SKILL_INDEX_HARNESS")
HOUSTON_BLOCK_STUB_READ=$(assemble_block "$RULES_STUB_READ" "$PROCESSES_STUB_READ" "$SKILL_INDEX_READ")

# --- Write function: marker-aware, accepts block content as argument ---
write_adapter() {
  local FILE="$1"
  local HOUSTON_BLOCK="$2"

  if [ -f "$FILE" ]; then
    # File exists — check for markers
    if grep -q "<!-- HOUSTON:START" "$FILE" 2>/dev/null; then
      # Replace content between markers (inclusive)
      local TEMP
      TEMP=$(mktemp)
      awk '
        /<!-- HOUSTON:START/ { skip=1; print "___HOUSTON_PLACEHOLDER___"; next }
        /<!-- HOUSTON:END/   { skip=0; next }
        !skip { print }
      ' "$FILE" > "$TEMP"

      # Replace placeholder with new Houston block
      local BLOCK_TEMP
      BLOCK_TEMP=$(mktemp)
      printf '%s\n' "$HOUSTON_BLOCK" > "$BLOCK_TEMP"

      # Build final file: lines before placeholder, Houston block, lines after
      local FINAL_TEMP
      FINAL_TEMP=$(mktemp)
      while IFS= read -r line; do
        if [ "$line" = "___HOUSTON_PLACEHOLDER___" ]; then
          cat "$BLOCK_TEMP"
        else
          printf '%s\n' "$line"
        fi
      done < "$TEMP" > "$FINAL_TEMP"

      mv "$FINAL_TEMP" "$FILE"
      rm -f "$TEMP" "$BLOCK_TEMP"
      echo "  ✅ $(basename "$FILE") (updated — user content preserved)"
    else
      # File exists but no markers — append Houston block at the end
      printf '\n%s\n' "$HOUSTON_BLOCK" >> "$FILE"
      echo "  ✅ $(basename "$FILE") (appended — existing content preserved)"
    fi
  else
    # File does not exist — create with Houston content only
    mkdir -p "$(dirname "$FILE")"
    printf '%s\n' "$HOUSTON_BLOCK" > "$FILE"
    echo "  ✅ $(basename "$FILE") (created)"
  fi
}

# --- Generate adapters ---
echo "Houston build system:"
for adapter in "${ADAPTERS[@]}"; do
  FULL_PATH="$WORKSPACE_DIR/$adapter"
  base=$(basename "$adapter")
  case "$base" in
    "CLAUDE.md")
      write_adapter "$FULL_PATH" "$HOUSTON_BLOCK_STUB_HARNESS"
      ;;
    "AGENTS.md"|"GEMINI.md")
      write_adapter "$FULL_PATH" "$HOUSTON_BLOCK_STUB_READ"
      ;;
    *)
      write_adapter "$FULL_PATH" "$HOUSTON_BLOCK_FULL"
      ;;
  esac
done
echo ""

# --- Sync skills to Claude Code ---
SKILL_DEST="$HOME/.claude/skills"
if [ -d "$SKILLS_DIR" ]; then
  echo "Syncing Houston skills to Claude Code:"
  for src in "$SKILLS_DIR"/*.md; do
    [ -f "$src" ] || continue
    name=$(basename "$src" .md)
    dest_dir="$SKILL_DEST/$name"
    mkdir -p "$dest_dir"
    cp "$src" "$dest_dir/SKILL.md"
    echo "  📦 skill synced: $name"
  done
  echo ""
fi

# --- Write manifest + digest (cache for next run) ---
if command -v python3 &>/dev/null; then
  python3 - "$MANIFEST_FILE" "$DIGEST_FILE" "::SRC::" "${SOURCES[@]}" "::OUT::" "${OUTPUT_PATHS[@]}" <<'PY'
import hashlib, json, os, sys, time
manifest_file = sys.argv[1]
digest_file = sys.argv[2]
rest = sys.argv[3:]
src_i = rest.index("::SRC::")
out_i = rest.index("::OUT::")
sources = rest[src_i + 1:out_i]
outputs = rest[out_i + 1:]
src_entries = {}
digest = [
    "# Houston Sources Digest\n",
    "\n",
    "Generated by `.houston/build.sh` on cache miss. Used by the next build\n",
    "to decide whether sources changed; safe to delete (will be recreated).\n",
    "\n",
    f"Last built: {time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())}\n",
    "\n",
    "## Sources\n\n",
    "| Path | SHA-256 (prefix) | Size |\n",
    "|:---|:---|---:|\n",
]
for p in sources:
    if not os.path.isfile(p):
        continue
    with open(p, "rb") as f:
        data = f.read()
    sha = hashlib.sha256(data).hexdigest()
    src_entries[p] = {"sha256": sha, "size": len(data)}
    digest.append(f"| `{p}` | `{sha[:16]}…` | {len(data)} |\n")
digest.append("\n## Outputs (verified to exist on cache hit)\n\n")
for o in outputs:
    digest.append(f"- `{o}`\n")
manifest = {
    "version": 1,
    "last_built": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
    "sources": src_entries,
    "outputs": outputs,
}
with open(manifest_file, "w") as f:
    json.dump(manifest, f, indent=2, sort_keys=True)
    f.write("\n")
with open(digest_file, "w") as f:
    f.writelines(digest)
PY
  echo "[build] cache manifest written: ${MANIFEST_FILE#$WORKSPACE_DIR/}"
fi

echo "Build complete. ${#ADAPTERS[@]} adapters generated."
