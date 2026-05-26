---
layout: default
title: "Whiteboard Knob — 2,684 boards on a knob"
---

# Whiteboard Knob — 2,684 boards on a knob


[← Back to home](./)
Browse every whiteboard across `~/work/` and `~/.claude/skills/` with a physical Loupedeck knob. No dialogs, no folder picking — press Browse to load all 2,684 PNGs into a flat list, then turn the knob to scroll. Built 2026-03-18.

## Scripts

| Control | File | Subroutine | Action |
|---------|------|------------|--------|
| **Button** | `WhiteboardKnob.scpt` | `browse` | `find */boards/*.png */whiteboards/*.png` → flat sorted list, show first |
| **Knob ↻** | `WhiteboardKnob.scpt` | `next` | Next board (wraps around) — `sed -n` for O(1) random access |
| **Knob ↺** | `WhiteboardKnob.scpt` | `prev` | Previous board (wraps around) |
| **Knob press** | `WhiteboardKnob.scpt` | `open` | Open current board in Preview |

**Alternative wiring** (wrapper scripts, no subroutine needed): `WhiteboardBrowse.scpt`, `WhiteboardNext.scpt`, `WhiteboardPrev.scpt`, `WhiteboardOpen.scpt`.

## State files

- `/tmp/whiteboard-knob-files` — flat sorted list of all PNG paths (one per line)
- `/tmp/whiteboard-knob-index` — current position (1-based)
- `/tmp/whiteboard-knob-current` — current PNG path (bridge for external consumers)

## Design decisions

- **Flat list over folder picker** — 2,684 boards scrollable without dialogs.
- **`sed -n` for random access** into the file list — no loading the entire list into AppleScript.
- **macOS notification on every turn** — shows `WhiteboardKnob 42/2684` so you always know where you are.
- **Wrap-around navigation** — board 1 follows last; last precedes board 1.
- **Loupedeck wiring (critical):** use Custom → AppleScript, NOT Custom → Run (that opens Script Editor).

## Evolution

1. Started with two-level folder picker (project → topic → ~10 boards).
2. User protested: "it isn't a full 1300 whiteboards".
3. Rewritten to flat list: 2,684 boards scrollable without dialogs.

**Lesson:** when building knob-driven UIs, default to showing everything. Let the knob's infinite scroll be the filter. Dialogs break flow.
