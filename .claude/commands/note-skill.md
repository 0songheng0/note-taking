# Note Skill Generator

Convert a saved instruction note (SOP, how-to, process doc) into a Claude Code skill file that can be invoked immediately as a slash command.

## Usage

```
/note-skill <query or note title>
/note-skill onboarding process
/note-skill deploy checklist
```

## Flow

### Step 1 — Find the note

Run, preferring instruction-type notes:
```bash
bash scripts/note-search.sh "<query> type:instruction"
```

If no instruction-type results, fall back to:
```bash
bash scripts/note-search.sh "<query>"
```
And warn the user: "This note is not an instruction type — the generated skill may need manual refinement."

If multiple results are returned, show them and ask the user to pick one by number.

### Step 2 — Read the note file

Read the full file at the path returned by the search.

### Step 3 — Ask for skill name

Ask: "What should this skill be named? Use lowercase with hyphens (e.g. `onboard-engineer`, `deploy-staging`)."

The skill name becomes both the filename (`.claude/commands/{skill-name}.md`) and the slash command (`/{skill-name}`).

### Step 4 — Generate the skill file

Convert the note's procedure into a Claude Code skill using this structure:

```markdown
# {Skill Title}

{One-line description derived from the note's purpose/intro}

## Usage

\```
/{skill-name}
/{skill-name} <arg>
\```

## Flow

### Step 1 — {first step title from note}
{instructions derived from the note's first procedure step}

### Step 2 — {next step title}
{instructions from next step}

(continue for all steps)

## Behavior Rules

- {rule derived from warnings, prerequisites, or cautions in the source note}
- Always confirm before destructive or irreversible actions
```

Mapping from note to skill:
- Note's **Purpose/Overview** → skill's one-line description
- Note's **Steps** → skill's Flow steps
- Note's **Warnings/Prerequisites** → skill's Behavior Rules
- Note's **action items** → omit (those are task-specific, not procedural)

### Step 5 — Write the skill file

Write the generated content to `.claude/commands/{skill-name}.md`.

### Step 6 — Confirm and commit

Display:
```
Skill created
  Command : /{skill-name}
  File    : .claude/commands/{skill-name}.md
  Source  : {source note path}

You can invoke it immediately with /{skill-name}
```

Git commit:
```bash
git add .claude/commands/{skill-name}.md
git commit -m "skill({skill-name}): generated from note {source-note-title}"
```

## Behavior Rules

- Keep the generated skill file concise — Claude reads it at runtime, so clarity beats completeness
- Do not copy raw YAML frontmatter from the note into the skill file
- Do not include note-specific content (attendees, dates, tags) in the skill — only the reusable procedure
- If the note has fewer than 2 clear steps, warn the user that the source material may be too sparse for a useful skill
- Suggest `/note-feature` if the user actually wants a feature plan instead of a runnable skill
