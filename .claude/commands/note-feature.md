# Note Feature Skill

Expand a saved note (meeting, discussion, or minutes) into a structured feature plan document.

## Usage

```
/note-feature <query or note title>
/note-feature budget discussion march
/note-feature 2026-03-14-product-review
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

### Step 3 — Expand into a feature plan

Generate a structured feature plan using only content derived from the source note. Do not invent facts. Where the source note is ambiguous or sparse, note it explicitly with `[needs clarification]`.

Use this template:

```markdown
---
type: instruction
title: Feature Plan: {source note title}
date: {YYYY-MM-DD today}
tags: [feature-plan, {tags inherited from source note}]
related: [{source note file path}]
---

## Problem Statement
{Derived from the discussion context, pain points, or goals mentioned in the source note}

## Goals
- {goal derived from source note decisions or discussion}

## Success Criteria
- {measurable outcome based on source note content}

## Scope
**In scope:** {what was agreed to be included}
**Out of scope:** {what was explicitly excluded, or [needs clarification] if not discussed}

## User Stories
- As a {role}, I want to {action} so that {outcome}

## Milestones
| Milestone | Description | Target Date |
|-----------|-------------|-------------|
| M1        | {first deliverable} | {date or TBD} |

## Open Questions
- {unresolved items or questions raised in source note}

## Action Items
| Item | Owner | Due | Status |
|------|-------|-----|--------|
| {action items carried over from source note} | {owner} | {due} | Open |
```

### Step 4 — Save the feature plan

Save using the standard flow:
```bash
bash scripts/note-save.sh "instruction" "Feature Plan: {source title}" "{YYYY-MM-DD}"
```
Write the feature plan content to the returned path, run `bash scripts/note-index.sh`, and git commit:
```
note(instruction): Feature Plan: {source title} [{date}]
```

### Step 5 — Display confirmation

Show a save summary card:
```
Feature plan saved
  File : notes/instructions/{date}-feature-plan-{slug}.md
  From : {source note path}
  Tags : {tags}
```

## Behavior Rules

- Derive all content strictly from the source note — never invent goals, stakeholders, or timelines
- If the source note is very sparse, fill what you can and mark gaps with `[needs clarification]`
- Works best with meeting, minutes, or discussion type notes; if used on a quick or instruction note, warn the user and proceed anyway
- Suggest `/note-brief` if the user wants to combine multiple notes before generating the plan
- Suggest `/note-tasks` if the user just wants the action items extracted without a full plan
