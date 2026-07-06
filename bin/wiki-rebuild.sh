#!/usr/bin/env bash
# Rebuild the merlib wiki from the ontology — the wired, one-command pipeline.
#
#   wiki-rebuild.sh [repo-dir]              # generate pages -> index -> browser view
#   wiki-rebuild.sh [repo-dir] --merge      # first fold ontology/*additions*.yaml into canonical
#
# Source of truth is the filesystem: ontology/*.yaml -> wiki/*.md -> INDEX.md + wiki-view.html.
# Run this after any ontology change (or after a deep-read updates an entry).
set -euo pipefail

REPO="/Users/esaruoho/work/merlib-dump"
MERGE=0
for a in "$@"; do
  case "$a" in
    --merge) MERGE=1 ;;
    -*) ;;                       # ignore other flags
    *) REPO="$a" ;;
  esac
done
BIN="$(cd "$(dirname "$0")" && pwd)"

if [ "$MERGE" = "1" ]; then
  echo "==> folding ontology additions into canonical"
  python3 "$BIN/merge-ontology-additions.py" "$REPO"
fi
echo "==> generating wiki pages from ontology"
python3 "$BIN/wiki-generate.py" "$REPO"
echo "==> regenerating INDEX.md"
python3 "$BIN/wiki-index.py" "$REPO/wiki"
echo "==> regenerating wiki-view.html"
python3 "$BIN/wiki-view.py" "$REPO/wiki"
echo "==> done"
