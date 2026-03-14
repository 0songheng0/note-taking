# Note Project Skill

Project container view. Groups all notes that share a project tag into one consolidated view: timeline of notes, key decisions, and all open actions. Notion's Projects database equivalent — no separate database needed.

## Usage

```
/note-project auth-redesign
/note-project --tag sprint-12
/note-project payments --from 2026-03-01
```

## Flow

### Step 1 — Identify the project

From the invocation arguments:
- If `--tag <tag>` is given, use that tag as the project identifier
- Otherwise, treat the argument as both a keyword search and a tag search

Run:
```bash
bash scripts/note-search.sh "<query>" [tag:<tag>] [after:<date>]
```

### Step 2 — Validate scope

- If 0 notes found: report and suggest `/note-tags` to see available tags
- If 1–30 notes found: proceed
- If > 30 notes found: warn and ask to narrow with `--from <date>` or a more specific tag

### Step 3 — Read all matching notes

Read each matched note file to extract:
- YAML frontmatter (type, date, title, tags, attendees)
- Decisions Made / Conclusions sections
- Action items table rows

### Step 4 — Render the project view

```markdown
## Project: {project name or tag}

**Period:** {earliest date} → {latest date}
**Notes:** {total count} ({breakdown by type})
**Open actions:** {count}

---

### Timeline

| Date | Type | Note | Key Point |
|------|------|------|-----------|
| {date} | {type} | [{title}]({path}) | {one-line summary of main decision or outcome} |
... (newest first)

---

### Key Decisions
- {decision} *(from: [{note title}]({path}), {date})*
- ...

---

### Open Action Items

| Action | Owner | Due | Priority | Status | Source |
|--------|-------|-----|----------|--------|--------|
| {action} | {owner} | {due} | {priority} | {status} | [{title}]({path}) |
... (sorted: Blocked → In Progress → Open, then High → Medium → Low)

---

### Open Questions
- {unresolved question from any note} *(from: {note title})*

---

*Generated: {today's date} · {N} notes · {N} open actions*
```

### Step 5 — Offer to save

Ask: "Save this as a project brief? (y/n)"
- If yes: save via standard flow using `note-save.sh "discussion" "Project: {name}" "{date}"`, then Write tool, `note-index.sh`, and git commit.
- If no: display only, no file written.

## Behavior Rules

- Derive everything strictly from the source notes — no invented facts
- If a note has no obvious "Key Point" summary, use the note title as the one-liner
- Open Questions: look for `## Open Questions` sections in matched notes; include any unanswered bullets
- The view is project-scoped — suggest `/note-brief` for date-scoped aggregation across multiple projects
- Do not count Done action items in the "Open actions" header count
- Suggest `/note-tags` if the user seems unsure what project tags exist
