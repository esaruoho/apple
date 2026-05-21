---
name: QuickTime Player 7 Pro vs QT Player X scriptability cliff
description: The 2003/2004 QT scripting era ($29.99 QT 7 Pro license) had a 40-property annotation system, chapter manipulation, current-matrix transforms, save-export-settings (.qtex), HREF embedding, media skins; QT Player X in Sequoia has a drastically stripped sdef
type: reference
originSessionId: f28a1d2b-4331-43e3-9b69-6e7756ffc44e
---
**QuickTime Player 7 Pro** ($29.99 license, Mac OS X 10.5-10.11 era) had a richly scriptable QuickTime Player with ~150 ready-made Apple-shipped scripts in the QuickTime Scripts Collection.

**Modern QuickTime Player X** (Sequoia 2026) has had its sdef drastically stripped. Most of the 2003/2004 demo scripts do not work against the modern player.

## What's lost on Sequoia QT Player X

- Annotations (40+ fields: artist, copyright, performers, etc.)
- Chapter creation / edit / rename / delete
- Track-level operations (text tracks, video tracks, frame-level scripting)
- HREF embedding (so a movie file IS its own hyperlink)
- Media skins (non-rectangular movie shapes)
- `current matrix` get/set (3x3 transform — skew/rotate/squeeze/flip)
- `save export settings` (.qtex codec presets)
- `enter full screen` / `exit full screen` with background color
- The 150-script QuickTime Scripts collection's most-useful members

## What still works on Sequoia QT Player X

- `play` / `pause` / `stop` / `start recording` (screen+audio)
- Basic file open
- Window position get/set
- Volume

## Workarounds on 2026 Sequoia

For the things QT Player X can't do:
- **`avconvert`** for codec transformations (Apple's official CLI)
- **`ffmpeg`** for everything else
- **AVFoundation via Swift one-liner** — `swift -e 'import AVFoundation; ...'` for property-level metadata surgery
- **MetadataKit** / **AVMetadataItem** for annotation-style metadata access

The Sal 2003 `call method` pattern (bridge to native API when sdef lacks verbs) ports forward: now you bridge via Swift one-liner or JXA `$` bridge instead of AppleScript Studio + Xcode.

## Legacy Mac workaround

If you keep a legacy macOS 10.6-10.11 Mac (some pros do — for QT Pro and discontinued audio plugins), the **2003/2004 scripts work verbatim** on QT Player 7 Pro. The QuickTime Scripts Collection from `apple.com/applescript` (mirror in `sources/sal/macosxautomation.com/`) is still functional on that machine.

## Sources

- WWDC 2003 #718 — `sources/sal/wwdc/2003-session-718-applescript-and-quicktime/`
- WWDC 2004 #723 — `sources/sal/wwdc/2004-session-723-applescript-and-quicktime/`
- Deep-dive bulletpoint — `sources/sal/wwdc/demo-bulletpoints/01-QUICKTIME-PRO-AUTOMATION.md`
