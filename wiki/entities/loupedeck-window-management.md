# Loupedeck Window Management

Native window snapping driven from a Loupedeck Live — no Magnet, no Rectangle, pure System Events + NSScreen. Physical controls for window tiling.

- **Scripts:** `scripts/workflows/system-events/` (source `.applescript`) + `compiled/` (`.scpt` for Loupedeck).
- **Loupedeck wiring:** Custom → AppleScript in action search. Dialog has AppleScript file path, Subroutine, Arguments fields. Do NOT use Custom → Run (opens Script Editor instead).
- **Knobs have 3 actions:** turn left, turn right, press — separate AppleScript per action.

## Scripts

| Control | File | Subroutine | Action |
|---------|------|------------|--------|
| **Button** | `HideAllOthers.scpt` | — | `set visible of every process whose frontmost is false to false` — works even on Telegram (bypasses menu bar) |
| **Button** | `MosaicWindows.scpt` | — | Tile all frontmost-app windows into auto-grid |
| **Knob ↻** | `MosaicKnob.scpt` | `more` | Show one more window, retile grid |
| **Knob ↺** | `MosaicKnob.scpt` | `less` | Show one fewer window, retile grid |

**Workflow:** Hide All Others (focus on one app) → turn knob to dial in how many windows you see. Physical focus control.

## MosaicKnob architecture

- **State:** `/tmp/mosaic-knob-state` — persists window count between turns.
- **Valid steps only:** 1 → 2 → 3 → 4 → 6 → 8 → 9 → 12 → 16. Skips counts that leave empty grid cells.
- **Explicit layouts for 1-4:** 1 = full, 2 = side-by-side columns, 3 = three columns, 4 = 2×2. Only 6+ uses ratio optimizer.
- **Always main screen:** `NSScreen.main` (keyboard focus screen) via Swift one-liner. No multi-monitor detection — it was unreliable and sent windows to wrong screens.
- **Screen-aware filtering:** checks each window's position against main-screen bounds (10 px tolerance). Only tiles windows already on the main screen — won't pull from other screens.
- **No window hiding:** excess windows left untouched. No minimize, no off-screen moves. Just tile the first N.
- **Two-pass tiling:** resize all windows first, then position (prevents Safari overlap bug).
- **Loupedeck subroutines:** one `.scpt` with `on more()` / `on less()` handlers — Loupedeck calls the right one per knob direction.

## AppleScript gotchas

- `use framework "AppKit"` inside handlers breaks `osacompile` — use `do shell script "swift -e '...'"` for NSScreen.
- `use framework` works at top level only in `.scpt`, not inside `on handlerName()`.
- AppleScript `word` operator treats hyphens as word separators — `-1080` becomes `1080`. Use comma delimiters + `text item delimiters` for negative coords.
- Safari (and some apps) auto-adjusts window position after resize — resize first, position second.

## Design lessons (MosaicKnob evolution)

- **Multi-monitor detection is a trap.** Swift coordinate flipping to find "which screen" got math wrong, sent windows to portrait screen. `NSScreen.main` is reliable and predictable.
- **Never hide windows the user didn't ask to hide.** Both `-10000,-10000` off-screen and minimize approaches lost windows. Just tile N, leave the rest.
- **Ratio optimizer fails for small counts.** 16:10 target picked stacked (1×2) for 2 windows instead of side-by-side (2×1). Explicit layouts for 1-4 are obviously correct.
- **Simple beats clever.** Three rounds of fixes all removed complexity. The final version is shorter and works better than the "smart" one.
- **Count all windows = cross-screen chaos.** `count of windows of fp` includes windows on ALL screens. Must filter by position before tiling or off-screen windows get pulled in.
