# Note Tasks Skill

Extract action items from a saved note and format them as a markdown task checklist grouped by owner.

## Usage

```
/note-tasks <query or note title>
/note-tasks sprint planning
/note-tasks 2026-03-14-sprint-planning
```

## Flow

### Step 1 — Find the note

Run:
```bash
bash scripts/note-search.sh "<query>"
```

If multiple results are returned, show them and ask the user to pick one by number. If no results, report that and stop.

### Step 2 — Read the note file

Read the full file at the path returned by the search.

### Step 3 — Extract action items

Look for action item tables in the note. These are markdown tables with columns like `Item`, `Owner`, `Due`, `Status`. Extract all rows (Open and any other status).

If there is no action items table, say so clearly and offer to summarize the note's key points as a freeform task list instead (ask the user first).

### Step 4 — Format as checklist

Output a markdown checklist grouped by owner:

```markdown
## Task List: {source note title} ({source note date})

> Source: {source note file path}

### {Owner Name}
- [ ] {task description} — due {due date}

### {Other Owner}
- [ ] {task description} — due {due date}

### Unassigned
- [ ] {task description}
```

- Use `- [ ]` for Open status items
- Use `- [x]` for Done/Closed status items
- Group unassigned actions under "Unassigned"
- Sort owners alphabetically

### Step 5 — Offer to save

Ask: "Save this task list as a quick note? (y/n)"

If yes, save using the standard flow:
```bash
bash scripts/note-save.sh "quick" "Tasks: {source title}" "{YYYY-MM-DD}"
```
Then write the checklist content to that path, run `bash scripts/note-index.sh`, and git commit with message `note(quick): Tasks: {source title} [{date}]`.

## Behavior Rules

- Always show the source note file path in the output so the user can trace back
- Suggest `/note-actions` if the user wants open actions across all notes (not just one)
- Suggest `/note-followup` if the user wants to continue working from this note in a new meeting
