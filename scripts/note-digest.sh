#!/usr/bin/env bash
# note-digest.sh — summarize notes from a date range
# Usage: bash scripts/note-digest.sh [--days <N>] [--from <YYYY-MM-DD>] [--to <YYYY-MM-DD>]
# Default: last 7 days

set -euo pipefail

NOTES_DIR="notes"
DAYS=7
FROM_DATE=""
TO_DATE=$(date +%Y-%m-%d)
TODAY=$(date +%Y-%m-%d)

while [[ $# -gt 0 ]]; do
  case "$1" in
    --days) DAYS="$2"; shift 2 ;;
    --from) FROM_DATE="$2"; shift 2 ;;
    --to)   TO_DATE="$2"; shift 2 ;;
    *) shift ;;
  esac
done

if [[ -z "$FROM_DATE" ]]; then
  FROM_DATE=$(date -d "${TO_DATE} -${DAYS} days" +%Y-%m-%d 2>/dev/null \
    || date -v-"${DAYS}"d +%Y-%m-%d 2>/dev/null \
    || python3 -c "from datetime import date, timedelta; d=date.fromisoformat('${TO_DATE}'); print(d - timedelta(days=${DAYS}))")
fi

parse_field() {
  local field="$1" file="$2"
  awk '/^---/{found++; next} found==1 && /^'"$field"':/{sub(/^[^:]+: */,""); print; exit}' "$file"
}

normalize_date() {
  [[ "$1" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && echo "$1" || echo ""
}

urgency_marker() {
  local due_norm
  due_norm=$(normalize_date "$1")
  [[ -z "$due_norm" ]] && return 0
  if [[ "$due_norm" < "$TODAY" ]]; then
    echo "⚠ OVERDUE"
  else
    local cutoff
    cutoff=$(date -d "${TODAY} +3 days" +%Y-%m-%d 2>/dev/null \
      || python3 -c "from datetime import date,timedelta; print(date.fromisoformat('${TODAY}')+timedelta(days=3))" 2>/dev/null \
      || echo "")
    [[ -n "$cutoff" && "$due_norm" <= "$cutoff" ]] && echo "→ DUE SOON" || true
  fi
}

mapfile -t ALL_FILES < <(find "$NOTES_DIR" -name "*.md" ! -name ".gitkeep" ! -name "INDEX.md" | sort -r)

MATCHED_FILES=()
for f in "${ALL_FILES[@]}"; do
  date=$(parse_field "date" "$f")
  [[ -z "$date" ]] && continue
  [[ "$date" < "$FROM_DATE" ]] && continue
  [[ "$date" > "$TO_DATE" ]] && continue
  MATCHED_FILES+=("$f")
done

TOTAL=${#MATCHED_FILES[@]}

echo "## Weekly Digest: ${FROM_DATE} → ${TO_DATE}"
echo ""
echo "> ${TOTAL} note(s) in this period"
echo ""

if [[ $TOTAL -eq 0 ]]; then
  echo "No notes found in this date range."
  exit 0
fi

echo "---"
echo ""

# Group by type
declare -A TYPE_GROUPS
for f in "${MATCHED_FILES[@]}"; do
  type=$(parse_field "type" "$f")
  [[ -z "$type" ]] && type="quick"
  TYPE_GROUPS[$type]+="${f}"$'\n'
done

for type in meeting minutes discussion instruction quick; do
  [[ -v TYPE_GROUPS[$type] ]] || continue
  mapfile -t type_files <<< "${TYPE_GROUPS[$type]}"

  LABEL=$(echo "${type^}s")
  echo "### ${LABEL}"
  echo ""

  for f in "${type_files[@]}"; do
    [[ -z "$f" ]] && continue
    title=$(parse_field "title" "$f")
    date=$(parse_field "date" "$f")
    [[ -z "$title" ]] && title=$(basename "$f" .md)
    echo "- **${date}** [${title}](${f#notes/})"
  done
  echo ""
done

# Open actions summary
echo "---"
echo ""
echo "### Open Actions in This Period"
echo ""

OPEN_COUNT=0
for f in "${MATCHED_FILES[@]}"; do
  [[ -z "$f" ]] && continue
  title=$(parse_field "title" "$f")
  date=$(parse_field "date" "$f")

  while IFS= read -r row; do
    [[ "$row" =~ Action.*Owner ]] && continue
    [[ "$row" =~ ^[[:space:]]*\|[[:space:]]*[-:] ]] && continue
    echo "$row" | grep -qi "open" || continue
    IFS='|' read -ra cols <<< "$row"
    local_cols=()
    for c in "${cols[@]}"; do
      trimmed=$(echo "$c" | xargs)
      local_cols+=("$trimmed")
    done
    ncols=${#local_cols[@]}
    if [[ $ncols -ge 5 ]]; then
      action="${local_cols[1]}"; owner="${local_cols[2]}"; due="${local_cols[3]}"
    elif [[ $ncols -ge 4 ]]; then
      action="${local_cols[0]}"; owner="${local_cols[1]}"; due="${local_cols[2]}"
    else
      continue
    fi
    [[ -z "$action" || "$action" == "..." ]] && continue
    urgency=$(urgency_marker "$due")
    prefix=""
    [[ -n "$urgency" ]] && prefix="**${urgency}** — "
    echo "- [ ] ${prefix}**${action}** — ${owner:-Unassigned} — due: ${due:-TBD} *(from: ${title}, ${date})*"
    OPEN_COUNT=$((OPEN_COUNT + 1))
  done < <(grep -P '^\s*\|' "$f" 2>/dev/null || true)
done

[[ $OPEN_COUNT -eq 0 ]] && echo "No open actions in this period."
echo ""
echo "---"
echo "*Digest generated: $(date '+%Y-%m-%d %H:%M')*"
