#!/bin/bash
# OS-level automation: GrandPerspective (mosaic) + DaisyDisk (pie chart) on
# the same target, snapped side-by-side. One click, two visualizers,
# perfectly positioned. Composes three primitives:
#   1. GrandPerspective opened via `open -a` (folder-aware)
#   2. DaisyDisk opened via `open -a /` (volume root) OR the
#      daisydisk-scan-folder.sh UI-scripted helper (folder-aware via Cmd+O)
#   3. SideBySide.scpt — the existing Snap Windows action that tiles the
#      two frontmost apps
#
# Usage: disk-dual-scan.sh [absolute-path]   (default: /)
set -e

target="${1:-/}"
APPLE_DIR="$HOME/work/apple"
TOPBAR_SCRIPTS="$APPLE_DIR/topbar/scripts"
SNAP_SCRIPTS="$APPLE_DIR/scripts/workflows/system-events/compiled"

# GrandPerspective from the App Store is sandboxed — paths passed via
# `open -a GrandPerspective <folder>` are ignored. UI-script it for any
# real folder; only `/` is reachable via CLI (since the volume root
# is implicit).
if [ "$target" = "/" ]; then
    open -a GrandPerspective /
else
    "$TOPBAR_SCRIPTS/grandperspective-scan-folder.sh" "$target"
fi

# DaisyDisk handling diverges by target type. Root path → CLI is safe.
# Anything else → drive Cmd+O "Scan Folder…" via UI scripting since
# DaisyDisk's CLI collapses folder paths to the containing volume.
if [ "$target" = "/" ]; then
    open -a DaisyDisk /
else
    "$TOPBAR_SCRIPTS/daisydisk-scan-folder.sh" "$target"
fi

# Both apps need a moment to materialize their main windows before we
# can move them. DaisyDisk's UI-scripted path is the slower of the two.
sleep 2.5

# Tile the two frontmost apps side-by-side.
osascript "$SNAP_SCRIPTS/SideBySide.scpt"
