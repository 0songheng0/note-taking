# Note Standup Skill

Fast daily standup note capture. Three sections: Yesterday / Today / Blockers. Auto-fills Yesterday from the previous standup note if one exists.

## Usage

```
/note-standup
/note-standup Alice Bob Carol — finished auth, working on payments, no blockers
```

## Flow

### Step 1 — Find yesterday's standup (silently)

Run:
```bash
bash scripts/note-search.sh "standup" tag:standup
```

Look for the most recent result. If a previous standup note is found:
- Extract its **Today** section items (they become Yesterday's work)
- Extract any **open action items** from the note

If no previous standup exists, Yesterday section will be blank.

### Step 2 — Detect inline content

If the user provided content in the invocation (e.g. `/note-standup Alice Bob Carol — finished X, working on Y, blocked by Z`):
- Parse it: names before `—` are attendees, after `—` is content
- Infer Yesterday / Today / Blockers from keywords: "finished/completed/shipped/done" → Yesterday, "working on/starting/continuing" → Today, "blocked/waiting/stuck" → Blockers
- Skip Steps 3–4 and go directly to Step 5

### Step 3 — Collect attendees

Ask (one question): "Who's on the standup today? (names, comma-separated, or press Enter to skip)"

### Step 4 — Collect content

Show the pre-filled Yesterday section if found, then ask:

> "Go ahead — what did you do yesterday, what are you doing today, any blockers? Don't format, just dump."

Extract and sort into the three sections.

### Step 5 — Format the note

Use today's date as `{DATE}`. Title: `Daily Standup {DATE}`.

```markdown
---
type: meeting
title: Daily Standup {DATE}
date: {DATE}
tags: [standup, daily]
attendees: [{names or —}]
has_actions: {true|false}
related: []
---

# Daily Standup: {DATE}

**Date:** {DATE}
**Attendees:** {names or —}

## Yesterday
{bullet list of completed work — pre-filled from previous standup's Today section if found}

## Today
{bullet list of planned work}

## Blockers
{bullet list of blockers — or: — if none}

## Action Items
| Action | Owner | Due | Priority | Status |
|--------|-------|-----|----------|--------|
| ...    | ...   | ... | Medium   | Open   |
```

If no blockers, write `— No blockers` in the Blockers section.

### Step 6 — Save

```bash
bash scripts/note-save.sh "meeting" "Daily Standup {DATE}" "{DATE}"
```

Write the file, then:
```bash
bash scripts/note-index.sh
git add notes/
git commit -m "note(meeting): Daily Standup [{DATE}]"
```

Show the save summary card.

## Behavior Rules

- Always tag with `standup` and `daily` — this is what `/note-followup` and `/note-search` use to find previous standups
- If a previous standup is found, show a one-line summary: `↩ Pre-filled Yesterday from: {previous note title} ({date})`
- Keep the note fast — standup should take under 2 minutes to capture
- Action items are optional — only include if someone calls out a task during the standup
- Suggest `/note-actions` after saving to see all open items across all notes
