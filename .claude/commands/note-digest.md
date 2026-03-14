# Note Digest Skill

Generate a summary of all notes from the past week (or a custom date range). See what was discussed, decided, and what actions are still open.

## Usage

```
/note-digest
/note-digest --days 14
/note-digest --from 2026-03-01 --to 2026-03-15
```

## Flow

### Step 1 — Parse range

If no arguments are given, use `--days 7` (past 7 days).

Supported arguments:
- `--days <N>` — past N days from today (default: 7)
- `--from <YYYY-MM-DD>` — start date (inclusive)
- `--to <YYYY-MM-DD>` — end date (inclusive, default: today)

### Step 2 — Run the digest script

```bash
bash scripts/note-digest.sh [--days <N>] [--from <YYYY-MM-DD>] [--to <YYYY-MM-DD>]
```

### Step 3 — Display results

Show the script output directly. The digest includes:
- Total note count for the period
- Notes grouped by type with links
- Consolidated open action items from all notes in the period

### Step 4 — Offer to save

Ask: "Save this digest as a quick note? (y/n)"

If yes, save the digest output as a `quick` note:
- Title: `Weekly Digest {FROM_DATE} to {TO_DATE}`
- Content: the full digest markdown
- Use the standard save flow: `note-save.sh`, Write tool, `note-index.sh`, git commit

## Behavior Rules

- The digest is read-only — it does not modify any existing notes
- If there are no notes in the range, report that clearly and suggest checking `/note-search`
- Remind the user about `/note-actions` for a live view of all open actions (not just this period)
