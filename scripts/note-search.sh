#!/usr/bin/env bash
# note-search.sh — search notes with optional filters
# Usage: bash scripts/note-search.sh "<query>" [type:<type>] [after:<YYYY-MM-DD>] [before:<YYYY-MM-DD>] [tag:<tag>]
# Examples:
#   bash scripts/note-search.sh "retro"
#   bash scripts/note-search.sh "budget" type:meeting
#   bash scripts/note-search.sh "onboarding" after:2026-01-01
#   bash scripts/note-search.sh "" tag:sprint

set -euo pipefail

NOTES_DIR="notes"
QUERY=""
FILTER_TYPE=""
FILTER_AFTER=""
FILTER_BEFORE=""
FILTER_TAG=""

# ---- parse args -------------------------------------------------------------

for arg in "$@"; do
  case "$arg" in
    type:*)   FILTER_TYPE="${arg#type:}" ;;
    after:*)  FILTER_AFTER="${arg#after:}" ;;
    before:*) FILTER_BEFORE="${arg#before:}" ;;
    tag:*)    FILTER_TAG="${arg#tag:}" ;;
    *)        QUERY="$arg" ;;
  esac
done

# ---- helpers ----------------------------------------------------------------

parse_field() {
  local field="$1" file="$2"
  awk '/^---/{found++; next} found==1 && /^'"$field"':/{sub(/^[^:]+: */,""); print; exit}' "$file"
}

# ---- collect candidates -----------------------------------------------------

mapfile -t ALL_FILES < <(find "$NOTES_DIR" -name "*.md" ! -name ".gitkeep" ! -name "INDEX.md" | sort -r)

RESULTS=()

for f in "${ALL_FILES[@]}"; do
  type=$(parse_field "type" "$f")
  date=$(parse_field "date" "$f")
  title=$(parse_field "title" "$f")
  tags=$(parse_field "tags" "$f")

  # Type filter
  if [[ -n "$FILTER_TYPE" && "$type" != "$FILTER_TYPE" ]]; then
    continue
  fi

  # Date filters
  if [[ -n "$FILTER_AFTER" && -n "$date" && "$date" < "$FILTER_AFTER" ]]; then
    continue
  fi
  if [[ -n "$FILTER_BEFORE" && -n "$date" && "$date" > "$FILTER_BEFORE" ]]; then
    continue
  fi

  # Tag filter
  if [[ -n "$FILTER_TAG" ]]; then
    echo "$tags" | grep -qi "${FILTER_TAG#\#}" || continue
  fi

  # Content/title query
  if [[ -n "$QUERY" ]]; then
    if ! grep -qi "$QUERY" "$f" 2>/dev/null; then
      continue
    fi
  fi

  RESULTS+=("$f")
done

# ---- output -----------------------------------------------------------------

NRESULTS=${#RESULTS[@]}

if [[ $NRESULTS -eq 0 ]]; then
  echo "No notes matched your search."
  exit 0
fi

echo "## Search Results (${NRESULTS} found)"
echo ""
[[ -n "$QUERY" ]]        && echo "Query  : \"${QUERY}\""
[[ -n "$FILTER_TYPE" ]]  && echo "Type   : ${FILTER_TYPE}"
[[ -n "$FILTER_AFTER" ]] && echo "After  : ${FILTER_AFTER}"
[[ -n "$FILTER_TAG" ]]   && echo "Tag    : ${FILTER_TAG}"
echo ""
echo "---"
echo ""

for f in "${RESULTS[@]}"; do
  type=$(parse_field "type" "$f")
  date=$(parse_field "date" "$f")
  title=$(parse_field "title" "$f")
  tags=$(parse_field "tags" "$f")
  [[ -z "$title" ]] && title=$(basename "$f" .md)

  tag_str=""
  if [[ -n "$tags" && "$tags" != "[]" ]]; then
    tag_str=$(echo "$tags" | tr -d '[]' | sed 's/,/ /g' | xargs -n1 printf '`%s` ')
  fi

  echo "### [${title}](${f#notes/})"
  echo "> ${date} · ${type:-unknown} ${tag_str}"
  echo ""

  # Show matching lines with context (up to 3 matches)
  if [[ -n "$QUERY" ]]; then
    matches=$(grep -in "$QUERY" "$f" 2>/dev/null | grep -v '^[0-9]*:---' | grep -v 'type:\|date:\|tags:\|related:' | head -3 || true)
    if [[ -n "$matches" ]]; then
      while IFS= read -r m; do
        echo "  > ${m}"
      done <<< "$matches"
      echo ""
    fi
  fi
done
