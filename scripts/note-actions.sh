#!/usr/bin/env bash
# note-actions.sh — extract active action items from all notes
# Usage: bash scripts/note-actions.sh [--owner <name>] [--overdue] [--priority <high|medium|low>]
# Groups by status: Blocked → In Progress → Open
# Sorts by priority within each group: High → Medium → Low
# Flags overdue and due-soon items

set -euo pipefail

NOTES_DIR="notes"
FILTER_OWNER=""
FILTER_OVERDUE=false
FILTER_PRIORITY=""
TODAY=$(date +%Y-%m-%d)

# ---- parse args ---------------------------------------------------------------

while [[ $# -gt 0 ]]; do
  case "$1" in
    --owner)    FILTER_OWNER="$2"; shift 2 ;;
    --overdue)  FILTER_OVERDUE=true; shift ;;
    --priority) FILTER_PRIORITY="${2,,}"; shift 2 ;;
    *) shift ;;
  esac
done

# ---- helpers ------------------------------------------------------------------

parse_field() {
  local field="$1" file="$2"
  awk '/^---/{found++; next} found>1{exit} found==1 && /^'"$field"':/{sub(/^[^:]+: */,""); print; exit}' "$file"
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

priority_rank() {
  case "${1,,}" in high) echo 1;; medium) echo 2;; low) echo 3;; *) echo 2;; esac
}

status_rank() {
  case "${1,,}" in blocked) echo 1;; "in progress") echo 2;; *) echo 3;; esac
}

# ---- collect actions ----------------------------------------------------------

# Each entry: "srank|prank|owner|formatted_line"
ALL_LINES=()

while IFS= read -r f; do
  type=$(parse_field "type" "$f")
  title=$(parse_field "title" "$f")
  note_date=$(parse_field "date" "$f")
  [[ -z "$title" ]] && title=$(basename "$f" .md)

  [[ "$type" == "meeting" || "$type" == "minutes" || "$type" == "discussion" ]] || continue

  while IFS= read -r row; do
    # Skip separator and header rows
    [[ "$row" =~ ^[[:space:]]*\|[[:space:]]*[-:] ]] && continue
    [[ "$row" =~ \|[[:space:]]*(Action|Follow-up|#)[[:space:]]*\| ]] && continue

    IFS='|' read -ra cols <<< "$row"
    local_cols=()
    for c in "${cols[@]}"; do
      t=$(echo "$c" | xargs)
      [[ -n "$t" ]] && local_cols+=("$t")
    done
    ncols=${#local_cols[@]}
    [[ $ncols -lt 4 ]] && continue

    # Detect column layout:
    # 6 cols — minutes + priority:            # | action | owner | due | priority | status
    # 5 cols, first is digit — minutes:       # | action | owner | due | status
    # 5 cols, first is text — meeting+prio:   action | owner | due | priority | status
    # 4 cols — meeting/discussion (legacy):   action | owner | due | status
    action="" owner="" due="" priority="Medium" status=""

    if [[ $ncols -ge 6 ]]; then
      action="${local_cols[1]}"; owner="${local_cols[2]}"; due="${local_cols[3]}"
      priority="${local_cols[4]}"; status="${local_cols[5]}"
    elif [[ $ncols -eq 5 ]]; then
      if [[ "${local_cols[0]}" =~ ^[0-9]+$ ]]; then
        action="${local_cols[1]}"; owner="${local_cols[2]}"; due="${local_cols[3]}"; status="${local_cols[4]}"
      else
        action="${local_cols[0]}"; owner="${local_cols[1]}"; due="${local_cols[2]}"
        priority="${local_cols[3]}"; status="${local_cols[4]}"
      fi
    else
      action="${local_cols[0]}"; owner="${local_cols[1]}"; due="${local_cols[2]}"; status="${local_cols[3]}"
    fi

    # Skip placeholder rows and done items — only keep active statuses
    [[ -z "$action" || "$action" == "..." ]] && continue
    [[ "$action" =~ ^(Action|Follow-up)$ ]] && continue
    echo "$status" | grep -qiE "^(open|in progress|blocked)$" || continue

    # Apply filters
    [[ -n "$FILTER_OWNER" ]] && ! echo "$owner" | grep -qi "$FILTER_OWNER" && continue
    [[ -n "$FILTER_PRIORITY" ]] && [[ "${priority,,}" != "$FILTER_PRIORITY" ]] && continue

    if [[ "$FILTER_OVERDUE" == true ]]; then
      due_norm=$(normalize_date "$due")
      { [[ -z "$due_norm" ]] || [[ "$due_norm" >= "$TODAY" ]]; } && continue
    fi

    [[ -z "$owner"    || "$owner"    == "—" ]] && owner="Unassigned"
    [[ -z "$priority" || "$priority" == "—" ]] && priority="Medium"

    urgency=$(urgency_marker "$due")
    note_ref="[${title}](${f#notes/}) (${note_date})"

    # Build formatted line
    prefix=""
    [[ -n "$urgency" ]] && prefix="${urgency} — "

    line="- [ ] ${prefix}**[${priority}]** ${action} — ${owner} — due: ${due:-TBD} — ${note_ref}"

    srank=$(status_rank "$status")
    prank=$(priority_rank "$priority")
    # Use a safe separator that won't appear in paths/titles
    ALL_LINES+=("${srank}${CHAR_SEP:-|}${prank}${CHAR_SEP:-|}${owner}${CHAR_SEP:-|}${line}")

  done < <(grep -P '^\s*\|' "$f" 2>/dev/null || true)

done < <(find "$NOTES_DIR" -name "*.md" ! -name ".gitkeep" ! -name "INDEX.md" | sort)

# ---- output -------------------------------------------------------------------

if [[ ${#ALL_LINES[@]} -eq 0 ]]; then
  echo "No active action items found."
  exit 0
fi

echo "## Active Action Items"
echo ""

[[ "$FILTER_OVERDUE"  == true ]] && echo "> Showing **overdue** items only (before ${TODAY})" && echo ""
[[ -n "$FILTER_OWNER"   ]] && echo "> Filtered by owner: **${FILTER_OWNER}**" && echo ""
[[ -n "$FILTER_PRIORITY" ]] && echo "> Filtered by priority: **${FILTER_PRIORITY^}**" && echo ""

echo "> Legend: ⚠ OVERDUE · → DUE SOON · Priority shown as [High/Medium/Low]"
echo ""

# Sort: status rank asc, priority rank asc, owner alpha
mapfile -t SORTED_LINES < <(printf '%s\n' "${ALL_LINES[@]}" | sort -t'|' -k1,1n -k2,2n -k3,3)

declare -A STATUS_LABELS=( [1]="Blocked" [2]="In Progress" [3]="Open" )
current_srank=""

for entry in "${SORTED_LINES[@]}"; do
  srank="${entry%%|*}"
  tmp="${entry#*|}"
  # prank="${tmp%%|*}"   # not needed for display
  tmp="${tmp#*|}"
  # owner="${tmp%%|*}"   # not needed for display
  line="${tmp#*|}"

  if [[ "$srank" != "$current_srank" ]]; then
    [[ -n "$current_srank" ]] && echo ""
    echo "### ${STATUS_LABELS[$srank]}"
    current_srank="$srank"
  fi
  echo "$line"
done

echo ""
