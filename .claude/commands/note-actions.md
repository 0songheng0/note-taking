# Note Actions Skill

Scan all saved notes and surface open action items, grouped by owner.

## Usage

```
/note-actions
/note-actions --owner Alice
/note-actions --overdue
```

## Flow

Run the actions script with any filters the user provided:

```bash
bash scripts/note-actions.sh [--owner "<name>"] [--overdue]
```

Display the output directly to the user as formatted Markdown.

If no arguments were given by the user, run with no flags to show all open actions.

**Supported filters:**
- `--owner <name>` — show only actions assigned to a specific person (case-insensitive partial match)
- `--overdue` — show only actions where the due date is before today

## Behavior Rules

- Run the script and display results verbatim — do not summarize or truncate
- If the script outputs "No open action items found." relay that message clearly
- Remind the user they can use `/note-followup` to continue from a note with open actions
