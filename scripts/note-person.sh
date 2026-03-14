#!/usr/bin/env bash
# note-person.sh — person-centric view across all notes
# Usage: bash scripts/note-person.sh "<name>"
# Shows: meetings attended, action items assigned, notes mentioning the person

set -euo pipefail

NOTES_DIR="notes"
NAME="${1:-}"

if [[ -z "$NAME" ]]; then
  echo "Usage: bash scripts/note-person.sh \"<name>\"" >&2
  exit 1
fi

TODAY=$(date +%Y-%m-%d)

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

# ---- collect data -------------------------------------------------------------

MEETINGS=()       # "date|title|path"
ACTION_ITEMS=()   # "due|priority|action|title|path"
MENTIONS=()       # "date|title|path"

while IFS= read -r f; do
  type=$(parse_field "type" "$f")
  title=$(parse_field "title" "$f")
  note_date=$(parse_field "date" "$f")
  attendees=$(parse_field "attendees" "$f")
  [[ -z "$title" ]] && title=$(basename "$f" .md)

  # 1. Check attendees frontmatter
  if echo "$attendees" | grep -qi "$NAME"; then
    MEETINGS+=("${note_date}|${title}|${f}")
  fi

  # 2. Scan action item tables for this person as owner
  if [[ "$type" == "meeting" || "$type" == "minutes" || "$type" == "discussion" ]]; then
    while IFS= read -r row; do
      [[ "$row" =~ ^[[:space:]]*\|[[:space:]]*[-:] ]] && continue
      [[ "$row" =~ \|[[:space:]]*(Action|Follow-up|#)[[:space:]]*\| ]] && continue

      echo "$row" | grep -qi "$NAME" || continue

      IFS='|' read -ra cols <<< "$row"
      local_cols=()
      for c in "${cols[@]}"; do
        t=$(echo "$c" | xargs)
        [[ -n "$t" ]] && local_cols+=("$t")
      done
      ncols=${#local_cols[@]}
      [[ $ncols -lt 4 ]] && continue

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

      [[ -z "$action" || "$action" == "..." ]] && continue
      [[ "$action" =~ ^(Action|Follow-up)$ ]] && continue

      # Confirm owner matches
      echo "$owner" | grep -qi "$NAME" || continue

      [[ -z "$priority" || "$priority" == "—" ]] && priority="Medium"
      [[ -z "$status"   || "$status"   == "—" ]] && status="Open"

      ACTION_ITEMS+=("${due:-}|${priority}|${action}|${title}|${f}|${status}|${note_date}")
    done < <(grep -P '^\s*\|' "$f" 2>/dev/null || true)
  fi

  # 3. Check body text mentions (outside frontmatter)
  if grep -qi "$NAME" "$f" 2>/dev/null; then
    # Only count if NOT already in MEETINGS (attendee) — avoid double-counting
    already=false
    for m in "${MEETINGS[@]:-}"; do
      [[ "${m##*|}" == "$f" ]] && already=true && break
    done
    if [[ "$already" == false ]]; then
      MENTIONS+=("${note_date}|${title}|${f}")
    fi
  fi

done < <(find "$NOTES_DIR" -name "*.md" ! -name ".gitkeep" ! -name "INDEX.md" | sort -r)

# ---- output -------------------------------------------------------------------

echo "## ${NAME} — Person View"
echo ""

# Meetings attended
if [[ ${#MEETINGS[@]} -gt 0 ]]; then
  echo "### Meetings Attended (${#MEETINGS[@]})"
  echo ""
  for entry in "${MEETINGS[@]}"; do
    IFS='|' read -r d t p <<< "$entry"
    echo "- **${d}** [${t}](${p#notes/})"
  done
  echo ""
else
  echo "### Meetings Attended"
  echo ""
  echo "No meetings found where ${NAME} is listed as an attendee."
  echo ""
fi

# Action items
OPEN_ACTIONS=()
DONE_ACTIONS=()
for entry in "${ACTION_ITEMS[@]:-}"; do
  IFS='|' read -r due priority action title path status note_date <<< "$entry"
  urgency=$(urgency_marker "$due")
  prefix=""
  [[ -n "$urgency" ]] && prefix="**${urgency}** — "
  note_ref="[${title}](${path#notes/}) (${note_date})"
  line="- [ ] ${prefix}**[${priority}]** ${action} — due: ${due:-TBD} — ${note_ref}"
  echo "$status" | grep -qiE "^done$" && DONE_ACTIONS+=("$line") || OPEN_ACTIONS+=("$line")
done

echo "### Action Items Assigned"
echo ""
if [[ ${#OPEN_ACTIONS[@]} -gt 0 ]]; then
  echo "**Open:**"
  for l in "${OPEN_ACTIONS[@]}"; do echo "$l"; done
  echo ""
fi
if [[ ${#DONE_ACTIONS[@]} -gt 0 ]]; then
  echo "**Done:**"
  for l in "${DONE_ACTIONS[@]}"; do
    echo "${l/- \[ \]/- [x]}"; done
  echo ""
fi
if [[ ${#ACTION_ITEMS[@]} -eq 0 ]]; then
  echo "No action items assigned to ${NAME}."
  echo ""
fi

# Mentions
if [[ ${#MENTIONS[@]} -gt 0 ]]; then
  echo "### Also Mentioned In (${#MENTIONS[@]})"
  echo ""
  for entry in "${MENTIONS[@]}"; do
    IFS='|' read -r d t p <<< "$entry"
    echo "- **${d}** [${t}](${p#notes/})"
  done
  echo ""
fi

total=$((${#MEETINGS[@]} + ${#ACTION_ITEMS[@]} + ${#MENTIONS[@]}))
echo "---"
echo "*${total} reference(s) to ${NAME} across all notes*"
