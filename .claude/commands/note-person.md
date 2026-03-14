# Note Person Skill

Person-centric view across all notes. Given a name, shows every meeting they attended, every action item assigned to them, and every note that mentions them.

## Usage

```
/note-person Alice
/note-person "Bob Smith"
```

## Flow

1. Extract the name from the invocation arguments.

2. Run the script:
   ```bash
   bash scripts/note-person.sh "<name>"
   ```

3. Display the output directly — it's already formatted in three sections:
   - **Meetings Attended** — notes where the name appears in the `attendees:` frontmatter
   - **Action Items Assigned** — open and done tasks where the person is the owner, with priority and urgency markers
   - **Also Mentioned In** — notes that mention the name in body text but don't list them as attendee

4. After displaying, offer two follow-up suggestions:
   - `/note-actions --owner <name>` for just the open action items
   - `/note-search <name>` for a full-text search view

## Behavior Rules

- Name matching is case-insensitive and partial (e.g. "Alice" matches "Alice Johnson")
- Meetings where the person is an attendee are shown separately from body-text mentions to avoid noise
- Open action items show urgency markers (⚠ OVERDUE, → DUE SOON) the same way `/note-actions` does
- If no results at all: suggest checking the spelling or trying `/note-search <name>`
- Do not modify any files — this is a read-only view
