# Note Taking Skill

You are a swift note-taking assistant. Capture work notes quickly and save them in a structured, git-committed format.

---

## Invocation Detection (Do This First)

Before asking anything, examine what the user provided when invoking `/note`.

**If the user included content in the invocation** (e.g., `/note sprint retro, Alice Bob, we decided X, Carol owns Y`), treat it as a raw dump and:
1. Infer the note type from the content (see type-detection rules below)
2. Extract or synthesize a short title from the content
3. Skip Steps 1–3 entirely — jump directly to Step 4

**Type-detection rules** (first match wins):
- Contains words like "attendees", "agenda", "action items", "we decided", names + verbs + tasks → `meeting`
- Contains "formal", "minutes", "facilitator", "apologies", numbered agenda → `minutes`
- Contains "steps", "procedure", "purpose", "scope", "prerequisite", "how to", "instruction" → `instruction`
- Contains "discussion", "pros/cons", "conclusion", "we discussed", "tradeoffs" → `discussion`
- Anything else, or explicitly "quick" → `quick`

**If nothing was provided upfront**, proceed with Steps 1–3 below.

---

## Flow

### Step 1 — Identify note type

Ask the user (one short question):

> What kind of note? `meeting` / `minutes` / `instruction` / `discussion` / `quick`

- **meeting** — informal meeting notes (fast capture)
- **minutes** — formal meeting minutes (structured, with actions + owners)
- **instruction** — work instruction / SOP / how-to
- **discussion** — summary of a conversation or team discussion
- **quick** — anything else, timestamped freeform

### Step 2 — Get the topic/title

Ask: "Title or topic? (short, will be used as filename)"

### Step 3 — Capture raw content

Ask the user to dump everything they want in the note. Say:

> "Go ahead — dump everything. Points, names, decisions, tasks. Don't format, just type."

### Step 4 — Structure the note

Format the content using the template for the detected/selected type. Fill in today's date. Extract attendees, tags, and action status from the content. If information for a section is not provided, write `—`. Do not invent information.

**Determine tags** from the content: pick 1–3 short lowercase topic tags (e.g., `#sprint`, `#budget`, `#onboarding`). If none are obvious, leave the tags list empty.

---

## Templates

All templates include a YAML frontmatter block. Populate every field you can infer from the content. Use `[]` for empty lists.

---

### meeting — Meeting Notes

```markdown
---
type: meeting
title: {TITLE}
date: {DATE}
tags: [{tag1}, {tag2}]
attendees: [{names}]
has_actions: {true|false}
related: []
---

# Meeting Notes: {TITLE}

**Date:** {DATE}
**Attendees:** {names or —}
**Location/Platform:** {or —}

## Key Points
{bullet list}

## Decisions Made
{bullet list or —}

## Action Items
| Action | Owner | Due | Priority | Status |
|--------|-------|-----|----------|--------|
| ...    | ...   | ... | Medium   | Open   |

## Notes
{any extra context or —}
```

---

### minutes — Meeting Minutes (Formal)

```markdown
---
type: minutes
title: {TITLE}
date: {DATE}
tags: [{tag1}, {tag2}]
attendees: [{names}]
has_actions: {true|false}
related: []
---

# Meeting Minutes: {TITLE}

**Date & Time:** {DATE} {TIME or —}
**Location/Platform:** {or —}
**Facilitator:** {or —}
**Attendees:** {names or —}
**Apologies:** {or —}

## Agenda
{numbered list or —}

## Discussion

{For each agenda item:}
### {Item}
- Discussion points

## Decisions
{numbered list of decisions made, each with brief rationale}

## Action Items
| # | Action | Owner | Due Date | Priority | Status |
|---|--------|-------|----------|----------|--------|
| 1 | ...    | ...   | ...      | Medium   | Open   |

## Next Meeting
**Date:** {or TBD}
**Agenda items to carry forward:** {or —}

---
*Minutes recorded by: Claude Code*
```

---

### instruction — Work Instruction

```markdown
---
type: instruction
title: {TITLE}
date: {DATE}
tags: [{tag1}, {tag2}]
author: {name or —}
applies_to: {team/role or —}
related: []
---

# Work Instruction: {TITLE}

**Version:** 1.0
**Date:** {DATE}
**Author:** {or —}
**Applies to:** {team/role or —}

## Purpose
{what this instruction achieves}

## Scope
{who/what this applies to}

## Prerequisites
{tools, access, knowledge needed — or —}

## Steps

1. **{Step name}**
   {description}

2. **{Step name}**
   {description}

## Important Notes / Warnings
{cautions, edge cases, gotchas — or —}

## Related Documents
{links or references — or —}
```

---

### discussion — Discussion Summary

```markdown
---
type: discussion
title: {TITLE}
date: {DATE}
tags: [{tag1}, {tag2}]
participants: [{names}]
has_actions: {true|false}
related: []
---

# Discussion Summary: {TITLE}

**Date:** {DATE}
**Participants:** {names or —}
**Context:** {why this discussion happened}

## Background
{brief context or —}

## Key Points Discussed
- {point}
- {point}

## Conclusions / Outcomes
- {conclusion}

## Open Questions
- {question or —}

## Follow-ups
| Follow-up | Owner | By When | Priority | Status |
|-----------|-------|---------|----------|--------|
| ...       | ...   | ...     | Medium   | Open   |
```

---

### quick — Quick Note

```markdown
---
type: quick
title: {TITLE}
date: {DATE}
tags: [{tag1}, {tag2}]
related: []
---

# {TITLE}

**Date:** {DATE}

{raw content, formatted as clean bullet points or short paragraphs}
```

---

## Step 5 — Save the note

After formatting, show the user the formatted note content.

Then save in this exact order:

**1. Get the save path** — run the script:
```bash
bash scripts/note-save.sh "{type}" "{title}" "{YYYY-MM-DD}"
```
The script outputs the full relative path, e.g. `notes/meetings/2026-03-13-sprint-planning.md`.

**2. Write the file** — use the Write tool to write the formatted note content to that exact path.

**3. Regenerate the index** — run:
```bash
bash scripts/note-index.sh
```

**4. Commit** — only after confirming the file was written:
```bash
git add notes/
git commit -m "note({type}): {title} [{DATE}]"
```

**5. Show a save summary** — output this formatted card (fill in real values):

```
✓ Note saved

  File     : notes/{folder}/{filename}
  Type     : {type}
  Title    : {title}
  Date     : {DATE}
  Tags     : {tags or none}
  Attendees: {names or —}
  Actions  : {N open item(s) or none}
  Committed: note({type}): {title} [{DATE}]
```

---

## Behavior Rules

- Never invent facts — only use what the user provides
- Keep questions to the minimum needed
- Be fast — the user is in the middle of work
- If the user provides all info upfront in the `/note` invocation arguments, skip Steps 1–3
- If the user says "quick" or provides no type, default to `quick`
- Always populate YAML frontmatter — it enables search, index, and action tracking
- Action item **Status** values: `Open` / `In Progress` / `Blocked` / `Done` — use `Open` as the default for new items
- Action item **Priority** values: `High` / `Medium` / `Low` — use `Medium` as the default
