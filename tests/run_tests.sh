#!/usr/bin/env bash
# tests/run_tests.sh — comprehensive simulation tests for note-taking scripts
# Runs all scripts from /tmp to verify the global path fix works end-to-end.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

PASS=0
FAIL=0

# ---- helpers -----------------------------------------------------------------

assert_contains() {
  local label="$1" expected="$2" actual="$3"
  if echo "$actual" | grep -qF -- "$expected"; then
    echo "  PASS: $label"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $label"
    echo "        expected to find : $(printf '%q' "$expected")"
    echo "        actual output    : $(echo "$actual" | head -3 | sed 's/^/        /')"
    FAIL=$((FAIL + 1))
  fi
}

assert_not_contains() {
  local label="$1" unexpected="$2" actual="$3"
  if echo "$actual" | grep -qF "$unexpected"; then
    echo "  FAIL: $label (found unexpected string)"
    echo "        unexpected string: $(printf '%q' "$unexpected")"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS: $label"
    PASS=$((PASS + 1))
  fi
}

assert_file_exists() {
  local label="$1" path="$2"
  if [[ -e "$path" ]]; then
    echo "  PASS: $label"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $label (path not found: $path)"
    FAIL=$((FAIL + 1))
  fi
}

assert_file_contains() {
  local label="$1" expected="$2" path="$3"
  if grep -qF -- "$expected" "$path" 2>/dev/null; then
    echo "  PASS: $label"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $label"
    echo "        expected to find: $(printf '%q' "$expected")"
    echo "        in file         : $path"
    FAIL=$((FAIL + 1))
  fi
}

assert_file_not_contains() {
  local label="$1" unexpected="$2" path="$3"
  if grep -qF "$unexpected" "$path" 2>/dev/null; then
    echo "  FAIL: $label (found unexpected string in file)"
    echo "        unexpected: $(printf '%q' "$unexpected")"
    echo "        in file   : $path"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS: $label"
    PASS=$((PASS + 1))
  fi
}

# ---- fixture setup -----------------------------------------------------------

setup_fixtures() {
  cat > "$REPO_DIR/notes/meetings/2026-03-14-weekly-standup.md" << 'EOF'
---
type: meeting
title: Weekly Standup
date: 2026-03-14
tags: [sprint, engineering]
attendees: [Alice, Bob]
has_actions: true
related: []
---

# Meeting Notes: Weekly Standup

**Date:** 2026-03-14
**Attendees:** Alice, Bob
**Location/Platform:** Zoom

## Key Points
- Sprint velocity is on track
- Alice is blocked on infra access

## Decisions Made
- Deploy on Friday

## Action Items
| Action | Owner | Due | Priority | Status |
|--------|-------|-----|----------|--------|
| Fix infra access | Alice | 2026-01-01 | High | Open |
| Write release notes | Bob | 2026-03-20 | Medium | Open |
| Update changelog | Alice | 2026-03-10 | Low | Done |
| Review PR #42 | Bob | 2026-03-14 | High | Blocked |

## Notes
Weekly sync, recurring every Monday.
EOF

  cat > "$REPO_DIR/notes/meetings/2026-03-07-weekly-standup.md" << 'EOF'
---
type: meeting
title: Weekly Standup
date: 2026-03-07
tags: [sprint]
attendees: [Alice, Bob]
has_actions: true
related: []
---

# Meeting Notes: Weekly Standup

**Date:** 2026-03-07
**Attendees:** Alice, Bob
**Location/Platform:** Zoom

## Key Points
- Reviewed backlog
- Agreed on sprint goals

## Action Items
| Action | Owner | Due | Priority | Status |
|--------|-------|-----|----------|--------|
| Draft sprint goals | Alice | 2026-03-10 | High | Open |
| Notify stakeholders | Bob | 2026-03-09 | Medium | Open |

## Notes
Previous week standup.
EOF

  cat > "$REPO_DIR/notes/minutes/2026-03-12-q2-planning-minutes.md" << 'EOF'
---
type: minutes
title: Q2 Planning Minutes
date: 2026-03-12
tags: [planning, engineering]
attendees: [Alice, Bob, Carol]
has_actions: true
related: []
---

# Meeting Minutes: Q2 Planning Minutes

**Date & Time:** 2026-03-12 14:00
**Facilitator:** Alice
**Attendees:** Alice, Bob, Carol

## Agenda
1. Review Q1 outcomes
2. Set Q2 goals

## Decisions
1. Hire two engineers in Q2

## Action Items
| # | Action | Owner | Due Date | Priority | Status |
|---|--------|-------|----------|----------|--------|
| 1 | Post job listings | Carol | 2026-03-25 | High | Open |
| 2 | Define interview process | Bob | 2026-03-18 | Medium | Open |

## Next Meeting
**Date:** 2026-03-26
EOF

  cat > "$REPO_DIR/notes/discussions/2026-03-10-auth-strategy.md" << 'EOF'
---
type: discussion
title: Auth Strategy Discussion
date: 2026-03-10
tags: [engineering, security]
participants: [Alice, Bob]
has_actions: false
related: []
---

# Discussion Summary: Auth Strategy Discussion

**Date:** 2026-03-10
**Participants:** Alice, Bob
**Context:** Evaluating OAuth vs JWT for the new API

## Key Points Discussed
- OAuth adds complexity but is industry standard
- JWT is simpler but harder to revoke

## Conclusions / Outcomes
- Proceed with OAuth for external clients

## Open Questions
- Which OAuth provider to use?
EOF

  cat > "$REPO_DIR/notes/instructions/2026-03-05-deploy-to-production.md" << 'EOF'
---
type: instruction
title: How to Deploy to Production
date: 2026-03-05
tags: [devops, engineering]
author: Alice
applies_to: Engineering team
related: []
---

# Work Instruction: How to Deploy to Production

**Version:** 1.0
**Author:** Alice

## Purpose
Ensure safe, repeatable deployments.

## Steps
1. **Run tests** — `make test`
2. **Tag the release** — `git tag vX.Y.Z`
3. **Push to production** — `make deploy`

## Important Notes / Warnings
Never deploy on Fridays.
EOF

  cat > "$REPO_DIR/notes/quick/2026-03-14-api-rate-limits.md" << 'EOF'
---
type: quick
title: API Rate Limit Notes
date: 2026-03-14
tags: [engineering]
related: []
---

# API Rate Limit Notes

**Date:** 2026-03-14

- GitHub API: 5000 req/hr authenticated
- Default retry after 60 seconds on 429
EOF
}

# ---- cleanup -----------------------------------------------------------------

cleanup_fixtures() {
  rm -f \
    "$REPO_DIR/notes/meetings/2026-03-14-weekly-standup.md" \
    "$REPO_DIR/notes/meetings/2026-03-07-weekly-standup.md" \
    "$REPO_DIR/notes/minutes/2026-03-12-q2-planning-minutes.md" \
    "$REPO_DIR/notes/discussions/2026-03-10-auth-strategy.md" \
    "$REPO_DIR/notes/instructions/2026-03-05-deploy-to-production.md" \
    "$REPO_DIR/notes/quick/2026-03-14-api-rate-limits.md" \
    "$REPO_DIR/notes/INDEX.md"
}

# Ensure cleanup runs even if tests fail
trap cleanup_fixtures EXIT

# ---- setup -------------------------------------------------------------------

echo "================================================"
echo " note-taking simulation tests"
echo " REPO: $REPO_DIR"
echo " CWD during tests: /tmp  (global path fix test)"
echo "================================================"
echo ""

setup_fixtures

# All script invocations below run from /tmp to verify BASH_SOURCE path fix
cd /tmp

# ==============================================================================
echo "Suite 1: note-save.sh"
# ==============================================================================

out=$(bash "$REPO_DIR/scripts/note-save.sh" meeting "Sprint Retro" 2026-03-14)
assert_contains "meeting type maps to meetings/" "notes/meetings/2026-03-14-sprint-retro.md" "$out"
assert_contains "output is absolute path (not relative)" "$REPO_DIR/notes/" "$out"

out=$(bash "$REPO_DIR/scripts/note-save.sh" quick "My Note" 2026-03-14)
assert_contains "quick type maps to quick/" "notes/quick/2026-03-14-my-note.md" "$out"

out=$(bash "$REPO_DIR/scripts/note-save.sh" bogus "Test" 2026-03-14)
assert_contains "unknown type falls back to quick/" "notes/quick/" "$out"

out=$(bash "$REPO_DIR/scripts/note-save.sh" quick "Hello! World?" 2026-03-14)
assert_contains "special chars slugified" "2026-03-14-hello-world.md" "$out"

bash "$REPO_DIR/scripts/note-save.sh" minutes "Dir Test" 2026-03-14 > /dev/null
assert_file_exists "directory created by note-save.sh" "$REPO_DIR/notes/minutes"

echo ""

# ==============================================================================
echo "Suite 2: note-index.sh"
# ==============================================================================

bash "$REPO_DIR/scripts/note-index.sh" > /dev/null

assert_file_exists "INDEX.md created at absolute path" "$REPO_DIR/notes/INDEX.md"
assert_file_contains "total count correct (6 fixtures)" "**Total notes:** 6" "$REPO_DIR/notes/INDEX.md"
assert_file_contains "grouped by type: Meetings (2)" "## Meetings (2)" "$REPO_DIR/notes/INDEX.md"
assert_file_not_contains "links are relative (not absolute)" "$REPO_DIR/notes/meetings" "$REPO_DIR/notes/INDEX.md"

echo ""

# ==============================================================================
echo "Suite 3: note-search.sh"
# ==============================================================================

out=$(bash "$REPO_DIR/scripts/note-search.sh" "standup")
assert_contains "keyword search finds meeting" "Weekly Standup" "$out"

out=$(bash "$REPO_DIR/scripts/note-search.sh" "" type:quick)
assert_contains "type filter returns quick note" "API Rate Limit Notes" "$out"
assert_not_contains "type filter excludes meeting note" "Weekly Standup" "$out"

out=$(bash "$REPO_DIR/scripts/note-search.sh" "" tag:sprint)
assert_contains "tag filter finds sprint-tagged note" "Weekly Standup" "$out"

out=$(bash "$REPO_DIR/scripts/note-search.sh" "" after:2026-03-13)
assert_contains "after filter includes 03-14 note" "2026-03-14" "$out"
assert_not_contains "after filter excludes 03-07 note" "2026-03-07" "$out"

out=$(bash "$REPO_DIR/scripts/note-search.sh" "xyznotexist")
assert_contains "no results message" "No notes matched your search." "$out"

echo ""

# ==============================================================================
echo "Suite 4: note-actions.sh"
# ==============================================================================

out=$(bash "$REPO_DIR/scripts/note-actions.sh")
assert_contains "shows open action: Fix infra access" "Fix infra access" "$out"
assert_contains "overdue marker present" "⚠ OVERDUE" "$out"
assert_contains "blocked section header present" "### Blocked" "$out"
assert_contains "blocked action: Review PR #42" "Review PR #42" "$out"

out=$(bash "$REPO_DIR/scripts/note-actions.sh" --owner Alice)
assert_contains "owner filter shows Alice's action" "Fix infra access" "$out"
assert_not_contains "owner filter excludes Bob's action" "Write release notes" "$out"

out=$(bash "$REPO_DIR/scripts/note-actions.sh" --overdue)
assert_contains "overdue filter shows past-due action" "Fix infra access" "$out"
assert_not_contains "overdue filter excludes future action" "Write release notes" "$out"

echo ""

# ==============================================================================
echo "Suite 5: note-followup.sh"
# ==============================================================================

out=$(bash "$REPO_DIR/scripts/note-followup.sh" "standup")
assert_contains "finds most recent standup (2026-03-14)" "PREV_FILE=" "$out"
assert_contains "most recent note is 2026-03-14" "2026-03-14" "$out"
assert_not_contains "does not return older standup" "2026-03-07-weekly-standup" "$out"

assert_contains "outputs open actions block" "---OPEN_ACTIONS---" "$out"
assert_contains "open action appears in followup output" "Fix infra access" "$out"

set +e
out=$(bash "$REPO_DIR/scripts/note-followup.sh" "xyznotexist" 2>&1)
exit_code=$?
set -e
assert_contains "no match returns error message" "ERROR: No matching note found." "$out"
if [[ $exit_code -ne 0 ]]; then
  echo "  PASS: no match returns non-zero exit code"
  PASS=$((PASS + 1))
else
  echo "  FAIL: expected non-zero exit code for no match"
  FAIL=$((FAIL + 1))
fi

echo ""

# ==============================================================================
echo "Suite 6: note-digest.sh"
# ==============================================================================

out=$(bash "$REPO_DIR/scripts/note-digest.sh" --from 2026-03-14 --to 2026-03-14)
assert_contains "digest includes 03-14 meeting" "Weekly Standup" "$out"
assert_contains "digest includes 03-14 quick note" "API Rate Limit Notes" "$out"
assert_not_contains "digest excludes 03-12 minutes" "Q2 Planning Minutes" "$out"

out=$(bash "$REPO_DIR/scripts/note-digest.sh" --from 2026-03-01 --to 2026-03-14)
assert_contains "open actions section present" "### Open Actions in This Period" "$out"

out=$(bash "$REPO_DIR/scripts/note-digest.sh" --from 2020-01-01 --to 2020-01-02)
assert_contains "empty range message" "No notes found in this date range" "$out"

echo ""

# ==============================================================================
echo "Suite 7: note-person.sh"
# ==============================================================================

out=$(bash "$REPO_DIR/scripts/note-person.sh" "Alice")
assert_contains "person view shows meetings attended section" "### Meetings Attended" "$out"
assert_contains "Alice's meeting listed" "Weekly Standup" "$out"
assert_contains "Alice's overdue action shown" "Fix infra access" "$out"
assert_contains "overdue marker in person view" "⚠ OVERDUE" "$out"

echo ""

# ==============================================================================
echo "Suite 8: note-tags.sh"
# ==============================================================================

out=$(bash "$REPO_DIR/scripts/note-tags.sh")
assert_contains "engineering tag appears" "engineering" "$out"
assert_contains "sprint tag appears" "sprint" "$out"
assert_contains "tag index header" "## Tag Index" "$out"

echo ""

# ==============================================================================
echo "Suite 9: install.sh substitutions"
# ==============================================================================

# Run install.sh to ensure ~/.claude/commands/ is up to date
bash "$REPO_DIR/install.sh" > /dev/null

INSTALLED="$HOME/.claude/commands/note.md"

assert_file_exists "note.md installed globally" "$INSTALLED"
assert_file_not_contains "bare 'bash scripts/' not in installed file" "bash scripts/" "$INSTALLED"
assert_file_contains "absolute script path in installed file" "bash $REPO_DIR/scripts/" "$INSTALLED"
assert_file_contains "git add uses -C flag" "git -C $REPO_DIR add notes/" "$INSTALLED"
assert_file_contains "git commit uses -C flag" "git -C $REPO_DIR commit" "$INSTALLED"

echo ""

# ==============================================================================
echo "================================================"
echo " Results: $PASS passed, $FAIL failed"
echo "================================================"

[[ $FAIL -eq 0 ]]
