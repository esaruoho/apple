#!/usr/bin/env bash
# install.sh — symlink every slash-command .md from this repo into
# ~/.claude/commands/ so Claude Code can see them.
#
# Safe to re-run. Replaces existing symlinks; refuses to overwrite real files.

set -euo pipefail

SRC_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEST_DIR="$HOME/.claude/commands"

mkdir -p "$DEST_DIR"

installed=0
skipped=0

for src in "$SRC_DIR"/*.md; do
  name="$(basename -- "$src")"
  [ "$name" = "README.md" ] && continue
  dest="$DEST_DIR/$name"

  if [ -L "$dest" ]; then
    rm -- "$dest"
  elif [ -e "$dest" ]; then
    echo "skip: $dest exists and is not a symlink — leaving it alone" >&2
    skipped=$((skipped + 1))
    continue
  fi

  ln -s -- "$src" "$dest"
  echo "linked $name"
  installed=$((installed + 1))
done

echo
echo "installed $installed, skipped $skipped"
echo "slashes available in Claude Code: $(ls "$SRC_DIR"/*.md | grep -v README.md | wc -l | tr -d ' ')"
