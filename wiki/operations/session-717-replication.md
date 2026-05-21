---
description: Where the WWDC 2016 session 717 replication stands as of 2026-05-08; what works, what's broken, what's next
---

# Sal Session 717 Replication — current state

The Sal Soghoian WWDC 2016 session 717 demo has been replicated end-to-end on Esa's M3 Pro / macOS 15.6.1, voice-driven via Hey Sal Vocal Shortcut. The thing Apple killed in 2016 runs in 2026.

**Why:** session 717 was pulled by Apple a week after delivery, four months before Sal's role was eliminated. The recovered transcript (`sources/sal/wwdc2016-session-717/717-transcript.txt`) plus CitrusPeel255.zip (the public installer with 18 .scptd AppleScriptObjC libraries) are enough to rebuild the entire voice-automation stack on current macOS — but with caveats Apple changed underneath.

**How to apply:** when discussing or extending the Hey Sal stack, treat these as load-bearing facts:

1. **Vocal Shortcuts is the trigger surface** (`~/Library/Preferences/com.apple.Accessibility.plist` → `AVSPreferenceKey`, JSON in bytes). Apple Silicon only. Reader: `bin/list-vocal-shortcuts.py`.
2. **Hey Sal architecture** is Vocal Shortcut → Hey Sal Shortcut (Dictate Text → Run AppleScript with input wired to Dictated Text magic variable) → matcher (`bin/sal-siri-match.py`) → either user Shortcut OR Sal handler.
3. **The matcher** does fuzzy keyword matching across two catalogs: 588 Sal phrasings (from `commands.json`) + auto-discovered user Shortcuts (`shortcuts list`, 5-min cache). USER_BOOST=1.5 so user Shortcuts win on tie. Dead-bundle filter skips Sal handlers using `com.apple.iWork.*` (those error -1728 — Apple renamed bundles).
4. **~32 user Shortcuts in a "Sal Demo" folder** in Shortcuts.app sidebar bypass Sal's broken DC-Keynote/Pages/Numbers libraries with native `tell application "Keynote"` calls. Built by `bin/build-sal-demo-shortcuts.py`. Folder organized by `bin/organize-sal-shortcuts-into-folder.applescript`.
5. **Demo runner**: `Sal Demo Guide` Shortcut walks the user through speaking each command via Hey Sal in sequence (display dialogs, not auto-play). `analysis/sal/sal-demo-script.md` is the printable script.
6. **Native Swift binaries** replace broken Sal helpers: `bin/sal-take-photo` (AVCaptureVideoDataOutput → JPEG, replaces broken PictureTaker Helper) and `bin/sal-qr` (CIQRCodeGenerator → PNG). Both compile from .swift via `swiftc -O` on first run; Swift script-mode fails for AVCapturePhotoOutput's KVO needs.
7. **Hey Sal Shortcut must be hand-built in Shortcuts.app** — my Python `.shortcut` generator can't produce the action-to-action wiring format Apple uses. The Run AppleScript action's input chip must be manually set to "Dictated Text" magic variable (not "Shortcut Input"). Body uses `on run {input, parameters}` and reads `input` directly.
8. **Don't use Copy to Clipboard between Dictate Text and Run AppleScript** — clobbers user clipboard and breaks "paste clipboard to title" commands. Direct input wiring is correct.

Status as of 2026-05-08:
- Hey Sal voice routing: ✅ working
- ~32 user Shortcuts imported: ✅
- Sal Demo folder in Shortcuts.app: ✅
- Sal Demo Guide walkthrough: ✅
- Take My Picture (native AVFoundation): ✅
- QR This + QR My Clipboard: ✅
- Sal's broken DC-Keynote/Pages/Numbers handlers: filtered out, replaced by user Shortcuts
- Master auto-play orchestrator: deprecated (bypassed Hey Sal — wrong abstraction)

What's NOT done:
- Cross-app chains (Photos → Keynote, Maps round-trip, Numbers→Keynote chart) — Tier B work in `analysis/sal/wwdc-717-demo-command-inventory.md`
- Photos assistive title-loop ("help me to add titles")
- "Make a new presentation with these" (selected-photos-to-Keynote chain)
- Save-to-thumb-drive-and-eject

References:
- README "Session 717 Replication — Hey Sal v1" section (2026-05-08)
- skill.md sections: Vocal Shortcuts / Apple Bundle ID Drift / Sal's PictureTaker Helper.app Broken on Sequoia / Apple-Native Only
- analysis/sal/wwdc-717-demo-command-inventory.md (8-stage arc, status of every command)
- analysis/sal/sal-demo-shortcut-library-architecture.md (folder structure design)
- analysis/sal/sal-demo-script.md (printable runbook)
