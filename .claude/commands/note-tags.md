# Note Tags Skill

List all tags used across your notes, sorted by frequency. Helps maintain tag consistency and discover what's already tagged.

## Usage

```
/note-tags
/note-tags --sort alpha
```

## Flow

1. Run the script:
   ```bash
   bash scripts/note-tags.sh
   ```
   Or for alphabetical sort:
   ```bash
   bash scripts/note-tags.sh --sort alpha
   ```

2. Display the output directly — it's already formatted as a markdown table with counts and tag names.

3. After showing the table, add a short note if you spot any obvious inconsistencies (e.g., `sprint` used 4 times and `sprints` used 1 time — suggest standardizing).

## Behavior Rules

- Run from the repo root so the `notes/` path resolves correctly
- If no tags are found, explain that tags go in the YAML frontmatter `tags: [tag1, tag2]` of each note
- Do not modify any files — this is a read-only view
- Suggest `/note-search tag:<tagname>` to filter notes by a specific tag
