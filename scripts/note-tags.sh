#!/usr/bin/env bash
# note-tags.sh — list all tags used across notes with usage counts
# Usage: bash scripts/note-tags.sh [--sort alpha]
# Default sort: by count descending

set -euo pipefail

NOTES_DIR="notes"
SORT_MODE="count"  # count | alpha

while [[ $# -gt 0 ]]; do
  case "$1" in
    --sort) SORT_MODE="$2"; shift 2 ;;
    *) shift ;;
  esac
done

declare -A TAG_COUNTS

while IFS= read -r f; do
  # Extract the tags line from YAML frontmatter
  tags_line=$(awk '
    /^---/ { found++; next }
    found > 1 { exit }
    found == 1 && /^tags:/ { sub(/^tags: */, ""); print; exit }
  ' "$f")
  [[ -z "$tags_line" ]] && continue

  # Strip brackets and split on commas
  tags_line="${tags_line#[}"
  tags_line="${tags_line%]}"

  IFS=',' read -ra tag_arr <<< "$tags_line"
  for tag in "${tag_arr[@]}"; do
    # Trim whitespace and quotes
    tag=$(echo "$tag" | xargs | tr -d "\"'")
    [[ -z "$tag" ]] && continue
    if [[ -v TAG_COUNTS[$tag] ]]; then
      TAG_COUNTS[$tag]=$((TAG_COUNTS[$tag] + 1))
    else
      TAG_COUNTS[$tag]=1
    fi
  done
done < <(find "$NOTES_DIR" -name "*.md" ! -name ".gitkeep" ! -name "INDEX.md" 2>/dev/null)

if [[ ${#TAG_COUNTS[@]} -eq 0 ]]; then
  echo "No tags found. Add tags to your notes' YAML frontmatter to get started."
  exit 0
fi

echo "## Tag Index"
echo ""
echo "| Count | Tag |"
echo "|------:|-----|"

if [[ "$SORT_MODE" == "alpha" ]]; then
  sort_cmd="sort -t'|' -k2,2"
else
  sort_cmd="sort -t'|' -k1,1rn -k2,2"
fi

while IFS= read -r line; do
  count="${line%%|*}"
  tag="${line#*|}"
  printf "| %5s | %s |\n" "$count" "$tag"
done < <(
  for tag in "${!TAG_COUNTS[@]}"; do
    printf '%s|%s\n' "${TAG_COUNTS[$tag]}" "$tag"
  done | eval "$sort_cmd"
)

echo ""
echo "*${#TAG_COUNTS[@]} unique tag(s) across all notes*"
