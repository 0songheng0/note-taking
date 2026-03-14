# Note Search Skill

Search across all saved notes with optional filters for type, date range, and tags.

## Usage

```
/note-search <query>
/note-search retro type:meeting
/note-search budget after:2026-01-01
/note-search "" tag:sprint
/note-search onboarding before:2026-03-01 type:instruction
```

## Flow

Parse the user's invocation arguments:
- The first non-filter word(s) are the search query (can be empty `""` to list all)
- `type:<type>` — filter by note type (`meeting`, `minutes`, `instruction`, `discussion`, `quick`)
- `after:<YYYY-MM-DD>` — only notes on or after this date
- `before:<YYYY-MM-DD>` — only notes on or before this date
- `tag:<tag>` — filter by frontmatter tag (with or without `#`)

Build the script call and run it:

```bash
bash scripts/note-search.sh "<query>" [type:<type>] [after:<date>] [before:<date>] [tag:<tag>]
```

Display the output directly to the user.

## Behavior Rules

- Pass filters exactly as recognized tokens; omit any that were not specified
- If the user writes `/note-search` with no arguments, ask: "What are you looking for?"
- Suggest `/note-actions` if the user seems to be hunting for action items
- Suggest `/note-followup` if the user found a relevant note and wants to continue it
