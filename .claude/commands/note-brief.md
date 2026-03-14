# Note Brief Skill

Combine multiple notes from a date range or topic into a single consolidated project brief — with a timeline, key decisions, open actions, and next steps.

## Usage

```
/note-brief <topic keyword>
/note-brief --from 2026-03-01 --to 2026-03-14
/note-brief --tag sprint
/note-brief authentication redesign
```

## Flow

### Step 1 — Parse arguments

Supported arguments:
- `--from <YYYY-MM-DD>` — start date (inclusive)
- `--to <YYYY-MM-DD>` — end date (inclusive, default: today)
- `--tag <tag>` — filter by tag
- Any other words → treated as a keyword search query

Multiple filters can be combined: `/note-brief auth --from 2026-03-01 --tag backend`

### Step 2 — Gather matching notes

Build and run the search:
```bash
bash scripts/note-search.sh "<query>" [after:<from-date>] [before:<to-date>] [tag:<tag>]
```

- If **0 notes** found: report clearly and suggest broadening the search or checking `/note-search`
- If **1–20 notes** found: proceed — read all of them
- If **more than 20 notes** found: warn the user ("Found {N} notes — that's a lot. Consider narrowing with `--from`, `--to`, or `--tag`.") and ask if they want to continue or refine

### Step 3 — Read all matching notes

Read each note file returned by the search.

### Step 4 — Synthesize the project brief

Generate the brief using only content from the source notes. Do not invent facts. Mark any gaps with `[needs clarification]`.

```markdown
---
type: discussion
title: Project Brief: {topic or date range}
date: {YYYY-MM-DD today}
tags: [project-brief, {union of all tags from source notes}]
related: [{list of all source note file paths}]
---

## Executive Summary
{2–3 sentences synthesizing what this body of notes is collectively about — the problem space, what was discussed, and the current state}

## Timeline
| Date | Note | Summary |
|------|------|---------|
| {date} | [{note title}]({note path}) | {one-line summary of that note} |

(sorted chronologically, oldest first)

## Key Decisions
- **{decision}** — from [{source note title}]({source note path})

## Open Action Items
| Item | Owner | Due | Source | Status |
|------|-------|-----|--------|--------|
| {action} | {owner} | {due} | [{note title}]({path}) | Open |

## Open Questions
- {unresolved question} — raised in [{source note title}]({source note path})

## Next Steps
- {synthesized recommendation based on the body of notes}
```

### Step 5 — Save the brief

Save using the standard flow:
```bash
bash scripts/note-save.sh "discussion" "Project Brief: {topic}" "{YYYY-MM-DD}"
```
Write the brief content to the returned path, run `bash scripts/note-index.sh`, and git commit:
```
note(discussion): Project Brief: {topic} [{date}]
```

### Step 6 — Display confirmation

Show a save summary card:
```
Project brief saved
  File    : notes/discussions/{date}-project-brief-{slug}.md
  Sources : {N} notes combined
  Actions : {count} open action items
  Range   : {from date} → {to date}
```

## Behavior Rules

- Derive all content strictly from source notes — never invent decisions, owners, or timelines
- Always link decisions and actions back to their source note
- If source notes span very different topics, note that in the Executive Summary and consider whether a brief makes sense
- Suggest `/note-feature` to expand the brief into a full feature plan
- Suggest `/note-tasks` to extract just the action items from any single note
