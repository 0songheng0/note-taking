# Note Board Skill

Kanban-style view of action items across all notes, grouped into status columns: Blocked → In Progress → Open. Notion's Board view equivalent, in plain markdown.

## Usage

```
/note-board
/note-board --owner Alice
/note-board --priority high
/note-board --tag sprint
```

## Flow

1. Run note-actions to collect all active items:
   ```bash
   bash scripts/note-actions.sh [--owner <name>] [--priority <level>]
   ```

2. If `--tag` is provided, also pre-filter notes by tag first:
   ```bash
   bash scripts/note-search.sh "" tag:<tag>
   ```
   Then only include action items from the matching files.

3. Render the output as a kanban board. Build three columns from the action items:
   - **Blocked** — status = Blocked
   - **In Progress** — status = In Progress
   - **Open** — status = Open

   Format as a markdown table with one column per status:

   ```
   ## Action Board

   | 🚫 Blocked | 🔄 In Progress | 📋 Open |
   |------------|----------------|---------|
   | ⚠ OVERDUE **[High]** Fix payments — Alice — due: 2026-03-10 | **[High]** Deploy staging — Bob — due: 2026-03-17 | **[Medium]** Write release notes — Carol — due: 2026-03-20 |
   | | **[Medium]** Update docs — Alice — due: 2026-03-18 | **[Low]** Clean up logs — — due: TBD |
   ```

   Pad shorter columns with empty cells so the table is valid markdown. Within each column, sort High → Medium → Low.

4. After the table, show a one-line summary:
   ```
   > N blocked · N in progress · N open
   ```

5. Suggest follow-up actions:
   - `/note-actions` for the classic list view
   - `/note-person <name>` to focus on one person's board

## Behavior Rules

- If all columns are empty after filtering, say "No active action items found" and suggest broadening the filter
- Keep cell content short — truncate action text at 60 characters if needed, appending `…`
- Urgency markers (⚠ OVERDUE, → DUE SOON) always show when applicable, even in truncated form
- Do not modify any files — this is a read-only view
- The board works best in a markdown renderer; in plain terminal the table may wrap — that's acceptable
