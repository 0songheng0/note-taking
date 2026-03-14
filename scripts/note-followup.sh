#!/usr/bin/env bash
# note-followup.sh — find the most recent note matching a title pattern and extract its open actions
# Usage: bash scripts/note-followup.sh [<title-pattern>] [--type <type>]
# Outputs: original note path, title, date, and a markdown block of open action rows

set -euo pipefail

NOTES_DIR="notes"
TITLE_PATTERN=""
TYPE_FILTER=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --type) TYPE_FILTER="$2"; shift 2 ;;
    *)      TITLE_PATTERN="$1"; shift ;;
  esac
done

parse_field() {
  local field="$1" file="$2"
  awk '/^---/{found++; next} found==1 && /^'"$field"':/{sub(/^[^:]+: */,""); print; exit}' "$file"
}

# Find all candidate notes (newest first)
mapfile -t FILES < <(find "$NOTES_DIR" -name "*.md" ! -name ".gitkeep" ! -name "INDEX.md" | sort -r)

MATCH=""
for f in "${FILES[@]}"; do
  type=$(parse_field "type" "$f")
  title=$(parse_field "title" "$f")

  [[ -n "$TYPE_FILTER" && "$type" != "$TYPE_FILTER" ]] && continue

  if [[ -n "$TITLE_PATTERN" ]]; then
    echo "$title" | grep -qi "$TITLE_PATTERN" || continue
  fi

  # Only types with action tables
  [[ "$type" == "meeting" || "$type" == "minutes" || "$type" == "discussion" ]] || continue

  MATCH="$f"
  break
done

if [[ -z "$MATCH" ]]; then
  echo "ERROR: No matching note found."
  exit 1
fi

PREV_TITLE=$(parse_field "title" "$MATCH")
PREV_DATE=$(parse_field "date" "$MATCH")
PREV_TYPE=$(parse_field "type" "$MATCH")

echo "PREV_FILE=${MATCH}"
echo "PREV_TITLE=${PREV_TITLE}"
echo "PREV_DATE=${PREV_DATE}"
echo "PREV_TYPE=${PREV_TYPE}"
echo "---OPEN_ACTIONS---"

# Extract open action rows
grep -P '^\s*\|' "$MATCH" 2>/dev/null | while IFS= read -r row; do
  [[ "$row" =~ Action.*Owner ]] && continue
  [[ "$row" =~ ^[[:space:]]*\|[[:space:]]*[-:] ]] && continue
  echo "$row" | grep -qi "open" || continue
  echo "$row"
done

echo "---END---"
