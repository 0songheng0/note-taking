#!/usr/bin/env bash
# install.sh — install note-taking commands globally to ~/.claude/commands/
# After running this, /note and all related commands are available in any Claude Code session.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GLOBAL_COMMANDS_DIR="$HOME/.claude/commands"

mkdir -p "$GLOBAL_COMMANDS_DIR"

echo "Installing commands from $REPO_DIR → $GLOBAL_COMMANDS_DIR ..."
echo ""

for src in "$REPO_DIR/.claude/commands/"*.md; do
  filename="$(basename "$src")"
  dst="$GLOBAL_COMMANDS_DIR/$filename"

  sed \
    -e "s|bash scripts/|bash $REPO_DIR/scripts/|g" \
    -e "s|git add notes/|git -C $REPO_DIR add notes/|g" \
    -e "s|git add \.claude/|git -C $REPO_DIR add .claude/|g" \
    -e "s|git commit |git -C $REPO_DIR commit |g" \
    "$src" > "$dst"

  echo "  installed: $filename"
done

echo ""
echo "✓ Done. All commands are available globally in Claude Code."
echo "  Notes are saved to: $REPO_DIR/notes/"
echo "  Re-run this script after pulling updates to refresh the installed commands."
