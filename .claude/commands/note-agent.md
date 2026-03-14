# Note Agent Skill

Fully autonomous note capture. Paste a raw transcript, email thread, Slack dump, or stream of consciousness — the agent structures it into a note with zero Q&A.

## Usage

```
/note-agent
```

Then paste your raw content when prompted. Or include the raw dump directly in the invocation.

## Flow

### Step 1 — Collect the raw dump

If no content was provided in the invocation, say:

> "Paste everything — transcript, email, Slack thread, bullet dump, anything. I'll handle the rest."

Accept the entire block as-is.

### Step 2 — Autonomous analysis (no Q&A)

Without asking the user anything, determine:

**Type** — infer from content signals:
- Participants + decisions + tasks → `meeting`
- Formal language + agenda + "resolved" + action numbers → `minutes`
- Step-by-step procedure + purpose/scope language → `instruction`
- Deliberation + pros/cons + conclusions → `discussion`
- Everything else → `quick`

**Title** — synthesize a short, specific title (3–7 words) from the core topic. Do not use generic titles like "Meeting Notes" or "Discussion".

**Attendees / Participants** — extract all person names mentioned.

**Key points** — distill the most important items (not a transcript rehash).

**Decisions** — identify explicit decisions ("we decided", "agreed to", "will go with").

**Action items** — identify tasks assigned to people with any due dates mentioned. If owner is unclear, mark as Unassigned.

**Tags** — pick 1–3 topic tags from the content.

### Step 3 — Structure and confirm

Format the note using the appropriate template from `/note`. Show it to the user with a one-line header:

> Detected: **{type}** | Title: **{title}** | {N} action(s) | Tags: {tags}

Then show the full formatted note.

Do **not** ask for approval — proceed directly to saving unless the user explicitly says "wait" or "stop".

### Step 4 — Save

Use the same save flow as `/note` (Step 5):
1. `bash scripts/note-save.sh "{type}" "{title}" "{YYYY-MM-DD}"`
2. Write the file with the Write tool
3. `bash scripts/note-index.sh`
4. `git add notes/ && git commit -m "note({type}): {title} [{DATE}]"`
5. Show the save summary card

## Behavior Rules

- Ask zero questions — make autonomous decisions about all ambiguities
- For genuinely unclear information (e.g., two conflicting dates mentioned), pick the most recent/prominent one and note it with `*` in the note
- If the dump is too short to infer type or title, default to `quick` and use the first sentence as the title
- Speed is the point — the user chose `/note-agent` because they don't want back-and-forth
- After saving, briefly explain the key choices made: "Detected as `meeting`. Extracted 3 action items. Title synthesized from main topic."
