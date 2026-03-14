# Note Follow-up Skill

Start a follow-up note pre-filled with open action items from a previous note. Perfect for recurring meetings or picking up where you left off.

## Usage

```
/note-followup
/note-followup sprint retro
/note-followup --type meeting
```

## Flow

### Step 1 — Find the previous note

Run the follow-up script with the user's title pattern (if provided):

```bash
bash scripts/note-followup.sh ["<title-pattern>"] [--type <type>]
```

The script outputs key-value lines followed by a `---OPEN_ACTIONS---` block containing the raw action table rows from the matched note.

Parse the output:
- `PREV_FILE=` — path to the matched note
- `PREV_TITLE=` — title of the matched note
- `PREV_DATE=` — date of the matched note
- `PREV_TYPE=` — type of the matched note
- Lines between `---OPEN_ACTIONS---` and `---END---` — the open action rows

If the script outputs `ERROR:`, tell the user no matching note was found and suggest running `/note-search` to locate it.

### Step 2 — Confirm with the user

Show the user what was found:

> Found: **{PREV_TITLE}** ({PREV_DATE})
> This note has {N} open action(s). Starting a follow-up {PREV_TYPE} note.
> Title for this follow-up? (default: "Follow-up: {PREV_TITLE}")

### Step 3 — Build the pre-filled note

Create a new note of the same type (`PREV_TYPE`) with:

1. A **Status Update** section at the top listing each open action from the previous note, with a `[ ]` checkbox, prompting the user to update status
2. The rest of the template empty and ready to fill in
3. A `## Previous Note` footer linking back to `PREV_FILE`

Example pre-fill for a meeting note:
```markdown
## Status Update (from {PREV_TITLE}, {PREV_DATE})

| Action | Owner | Previous Due | Current Status | Update |
|--------|-------|-------------|----------------|--------|
| {action row 1} | {owner} | {due} | Open → ? | |
| {action row 2} | {owner} | {due} | Open → ? | |
```

### Step 4 — Ask for today's content

Tell the user:
> "Add today's new discussion points, decisions, and actions. I'll merge them with the status update above."

Accept their dump and structure it into the remainder of the note template.

### Step 5 — Save

Use the same save flow as `/note` (Step 5):
1. Run `bash scripts/note-save.sh "{type}" "{title}" "{DATE}"`
2. Write the file
3. Run `bash scripts/note-index.sh`
4. Commit: `git add notes/ && git commit -m "note({type}): {title} [{DATE}]"`
5. Show the save summary card

## Behavior Rules

- If no title pattern is given and no type filter is given, find the most recent note that has open actions (any type)
- If multiple notes match the pattern, list them and ask the user to pick one
- Never close or modify the original note — only reference it
