```
  ╔══════════════════════════════════════════════════════════════════╗
  ║                                                                  ║
  ║    ██████╗ ███╗   ███╗███████╗███████╗███████╗                  ║
  ║   ██╔══██╗████╗ ████║██╔════╝██╔════╝██╔════╝                  ║
  ║   ███████║██╔████╔██║█████╗  ███████╗███████╗                  ║
  ║   ██╔══██║██║╚██╔╝██║██╔══╝  ╚════██║╚════██║                  ║
  ║   ██║  ██║██║ ╚═╝ ██║███████╗███████║███████║                  ║
  ║   ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝                  ║
  ║                                                                  ║
  ║          your messy thoughts, neatly kept                        ║
  ║                                                                  ║
  ║             capture  ·  retrieve  ·  expand                     ║
  ║                                                                  ║
  ╚══════════════════════════════════════════════════════════════════╝
```

**aMess** is a Claude Code–powered note-taking workspace built for people who think fast and document late. Drop a raw thought, a meeting transcript, a Slack dump, or a half-formed idea — aMess structures it, indexes it, commits it to git, and hands it back as a meeting note, a feature plan, a task checklist, or even a new Claude slash command. Everything lives in plain markdown files, nothing requires a database, and nothing is ever lost.

---

## Quick Start

Open any Claude Code session in this repository and run:

```
/note
```

Claude will ask for a type, a title, and your content — then save, index, and commit the note automatically. No setup, no config, no installs.

**Power move** — provide everything upfront and skip all questions:
```
/note sprint retro — Alice Bob Carol, decided to cut feature X, Carol owns the refactor by Friday
```

---

## The 11 Skills

Skills are organized into three groups by intent.

---

### ✦ Capture — put thoughts in

| Skill | What it does |
|-------|-------------|
| `/note` | Guided note capture. Claude asks type → title → content, auto-detects type from your content, structures it into a template, saves, and commits. |
| `/note-agent` | Zero-question mode. Paste a raw transcript, email thread, or Slack dump. Claude reads it, infers everything — type, attendees, decisions, actions — and saves without asking. |
| `/note-followup` | Continue a recurring meeting. Finds the previous note by topic, pre-fills today's note with its open action items, then merges in your new content. |

**Capture tips:**

- Use `/note` when you want to stay in control of the structure.
- Use `/note-agent` when you have a messy block of text you don't want to clean up yourself.
- Use `/note-followup` for anything recurring: standups, 1:1s, sprint reviews, weekly syncs.

---

### ✦ Retrieve — get things out

| Skill | What it does |
|-------|-------------|
| `/note-search` | Full-text search with filters. Find notes by keyword, type, date range, or tag. |
| `/note-actions` | Surface all open action items across every saved note, grouped by owner. Filter by person or overdue status. |
| `/note-digest` | Generate a dated summary of notes — total count, grouped by type with links, consolidated open actions. Optionally save as a quick note. |

**Search filter syntax:**

```
/note-search retro type:meeting after:2026-03-01
/note-search "" tag:sprint                          ← list all sprint-tagged notes
/note-search budget before:2026-03-15 type:minutes
/note-search onboarding type:instruction
```

**Action item filters:**

```
/note-actions                          ← all open actions across all notes
/note-actions --owner Alice            ← only Alice's items
/note-actions --overdue                ← only past-due items
```

**Digest date ranges:**

```
/note-digest                                       ← past 7 days (default)
/note-digest --days 1                              ← today only
/note-digest --days 30                             ← past month
/note-digest --from 2026-03-01 --to 2026-03-14    ← explicit range
```

> `notes/INDEX.md` is also auto-regenerated after every save — a browsable dashboard of all notes, grouped by type, sorted newest-first, with tags and open action counts at a glance.

---

### ✦ Expand — turn notes into work

| Skill | What it does |
|-------|-------------|
| `/note-tasks` | Extract action items from a single note and format them as a markdown checklist grouped by owner. Optionally save as a quick note. |
| `/note-feature` | Expand a meeting or discussion note into a full feature plan: problem statement, goals, success criteria, scope, user stories, milestones, open questions. |
| `/note-skill` | Convert an instruction note (SOP, how-to, process doc) into a working Claude Code slash command written to `.claude/commands/` — immediately invocable. |
| `/note-brief` | Synthesize multiple notes — by date range, topic, or tag — into a consolidated project brief: timeline, key decisions, open actions, next steps. |

**Expand examples:**

```
/note-tasks sprint planning                        ← checklist from a single note
/note-tasks 2026-03-14-budget-review               ← by filename

/note-feature authentication redesign discussion   ← expand a discussion → feature plan
/note-feature Q2 roadmap kickoff

/note-skill onboarding process                     ← instruction note → new slash command
/note-skill how to cut a release

/note-brief --tag sprint                           ← all sprint notes → project brief
/note-brief --from 2026-03-01 --to 2026-03-14
/note-brief authentication                         ← topic keyword search across notes
```

---

## Note Types

| Type | Folder | Use when | Example title |
|------|--------|----------|---------------|
| `meeting` | `notes/meetings/` | Informal sync, 1:1, standup — key points and action items matter most | *Weekly Engineering Sync* |
| `minutes` | `notes/minutes/` | Formal meeting with agenda, numbered decisions, recorded next meeting | *Q2 Planning Session Minutes* |
| `instruction` | `notes/instructions/` | Step-by-step process, SOP, or how-to guide — something someone else could follow | *How to Deploy to Production* |
| `discussion` | `notes/discussions/` | Design discussion, architecture debate, open-ended conversation | *Auth Strategy Discussion* |
| `quick` | `notes/quick/` | Freeform thought dump, reference snippet, anything that doesn't fit a template | *API Rate Limit Notes* |

When in doubt, use `quick`. You can always expand it later with `/note-feature` or `/note-brief`.

---

## File Structure

```
aMess/
│
├── notes/                              ← all your notes live here
│   ├── INDEX.md                        ← auto-generated dashboard (do not edit by hand)
│   ├── meetings/
│   │   └── 2026-03-14-sprint-retro.md
│   ├── minutes/
│   │   └── 2026-03-10-q2-planning-session-minutes.md
│   ├── instructions/
│   │   └── 2026-03-01-how-to-deploy-to-production.md
│   ├── discussions/
│   │   └── 2026-03-12-auth-strategy-discussion.md
│   └── quick/
│       └── 2026-03-14-api-rate-limit-notes.md
│
├── scripts/                            ← shell scripts backing each skill
│   ├── note-save.sh                    ← resolves file path, creates directories
│   ├── note-index.sh                   ← regenerates INDEX.md after every save
│   ├── note-search.sh                  ← full-text search with filters
│   ├── note-actions.sh                 ← extracts open action items
│   ├── note-followup.sh                ← finds previous note and its open actions
│   └── note-digest.sh                  ← summarises a date range of notes
│
└── .claude/
    └── commands/                       ← Claude Code skill definitions
        ├── note.md                     ← /note
        ├── note-agent.md               ← /note-agent
        ├── note-followup.md            ← /note-followup
        ├── note-search.md              ← /note-search
        ├── note-actions.md             ← /note-actions
        ├── note-digest.md              ← /note-digest
        ├── note-tasks.md               ← /note-tasks
        ├── note-feature.md             ← /note-feature
        ├── note-skill.md               ← /note-skill
        └── note-brief.md               ← /note-brief
```

**File naming:** Every note is saved as `YYYY-MM-DD-slugified-title.md`. The date prefix ensures files sort chronologically in any directory listing. Special characters are stripped and spaces become hyphens.

---

## YAML Frontmatter

Every note begins with a YAML block. This is what makes search, indexing, and all expansion skills work — Claude reads these structured fields instead of parsing free prose.

```yaml
---
type: meeting                          # meeting | minutes | instruction | discussion | quick
title: Sprint Retrospective            # human-readable title
date: 2026-03-14                       # ISO 8601 date (YYYY-MM-DD)
tags: [sprint, engineering, retro]     # freeform — use consistently across notes
attendees: [Alice, Bob, Carol]         # for meeting and minutes types
has_actions: true                      # true if note contains an action items table
related: []                            # paths to related notes (linked by /note-brief, etc.)
---
```

| Field | Used by |
|-------|---------|
| `type` | `/note-search`, `INDEX.md` grouping, `/note-skill` (prefers `instruction`) |
| `date` | `/note-search` date filters, `/note-digest`, `INDEX.md` sort order |
| `tags` | `/note-search tag:`, `INDEX.md` tag display, `/note-brief --tag` |
| `attendees` | `/note-followup` matching, displayed in `INDEX.md` |
| `has_actions` | `INDEX.md` action count, `/note-actions` scan |
| `related` | `/note-brief` source links, `/note-feature` back-references |

---

## Workflow Examples

### Scenario A — Recurring weekly standup

```
Monday
  /note-followup standup
  ↳ finds last week's standup note
  ↳ pre-fills today's note with open items from last time
  ↳ add today's updates, decisions, new actions
  ↳ saved as notes/meetings/2026-03-17-weekly-standup.md

Wednesday
  /note-actions --owner Alice
  ↳ check what Alice still owes from all recent notes

Friday
  /note-digest --days 5
  ↳ full week summary — decisions, open actions
  ↳ optionally save as a quick note for the record
```

---

### Scenario B — Feature kick-off through delivery

```
Day 1 — kick-off meeting
  /note-agent
  ↳ paste raw meeting transcript
  ↳ Claude extracts attendees, decisions, actions — no questions
  ↳ saved as notes/meetings/2026-03-14-auth-redesign-kickoff.md

Day 2 — turn it into a spec
  /note-feature auth redesign kickoff
  ↳ generates: problem statement · goals · scope · user stories · milestones
  ↳ saved as notes/instructions/2026-03-15-feature-plan-auth-redesign.md

Day 2 — get today's tasks
  /note-tasks auth redesign kickoff
  ↳ markdown checklist grouped by owner, ready to act on

Two weeks later — roll everything up
  /note-brief --tag auth --from 2026-03-14
  ↳ combines kick-off + follow-up meetings into one brief
  ↳ timeline · consolidated decisions · all open actions in one place
```

---

### Scenario C — Document a process, then make it a command

```
Step 1 — capture the process
  /note
  ↳ type: instruction
  ↳ title: How to Cut a Release
  ↳ content: your step-by-step notes
  ↳ saved as notes/instructions/2026-03-14-how-to-cut-a-release.md

Step 2 — turn it into a skill
  /note-skill how to cut a release
  ↳ Claude asks: "What should this skill be named?" → release-cut
  ↳ generates .claude/commands/release-cut.md
  ↳ you can now run /release-cut in any session, on any machine
```

---

## How Notes Are Stored

Every save triggers this automatic sequence:

```
  bash scripts/note-save.sh   →   resolves path, creates directory if needed
  Write tool                  →   writes formatted markdown to disk
  bash scripts/note-index.sh  →   regenerates notes/INDEX.md
  git commit                  →   note(type): Title [YYYY-MM-DD]
```

Because every save is a git commit:

- **Nothing is ever lost** — every version of every note is in git history
- **`git log notes/`** shows a chronological diary of all activity
- **`git show HEAD~3:notes/meetings/2026-03-14-standup.md`** retrieves any past version
- **Portable** — clone the repo on any machine and your full knowledge base is there

---

## Tips & Tricks

**Combine filters in search**
```
/note-search security type:discussion after:2026-01-01 tag:backend
```

**Single-day digest**
```
/note-digest --from 2026-03-14 --to 2026-03-14
```

**Chain skills for maximum throughput**
```
After a big meeting:
  1.  /note-agent        ← capture raw
  2.  /note-feature      ← expand to plan
  3.  /note-tasks        ← extract today's todos
  4.  /note-brief        ← roll up after a sprint
```

**Quarterly review in one command**
```
/note-brief --from 2026-01-01 --to 2026-03-31 --tag project-x
```
Pulls a full brief — every decision, action, and outcome across 3 months of notes.

**Find what you forgot**
```
/note-search "" after:2026-03-10        ← everything in the last few days
/note-search "" type:quick              ← all freeform notes ever
/note-actions --overdue                 ← things that needed to be done already
```

**Don't format when dumping** — Claude handles structure. Give it messy input; it gives back clean output.
