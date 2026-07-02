# REPORT CARD — the `rec` screencast-pipeline session (2026-07-02 → 07-03)

Session retrospective for the screen+audio recorder arc: what shipped, what got dropped
on the floor, and which ideas were raised but never traced. Faithful, not flattering.

## WHAT THIS CARD SPAWNS
- **Codespace:** `bin/screen-audio-record(.swift)`, `bin/rec`, `bin/rec-audio(.swift)`,
  `bin/doi2scihub`, `commands/{rec,screen-audio-record,rec-audio}.md`,
  `topbar/AppleToolbox.swift` + `topbar/build.sh` (bundled helpers), standalone
  `~/work/apple-rec/*`, `~/work/convey/convey/cli.py` (`scihub --browser`).
- **Thinkspace:** this file's "How to get back" transcript + `features/screen-audio-record.session.md`.
- **Areaspace:** OWNS = capturing screen+audio, post-processing that audio, and getting it
  onto YouTube. MUST NOT TOUCH = video editing itself (that's iMovie/FCP) and YouTube's
  hosting (can't replace a file/URL — established as a hard limit).

## LEGEND
`@hw-verified` ran live on this Mac, output inspected · `@built` compiles+deploys, GUI/keypress
path NOT driven headlessly · `@todo` planned, not built · `@dropped` raised then abandoned ·
`@idea-untraced` floated, never scoped.

---

## ✅ FINISHED — shipped + verified

  @hw-verified  Screen + system audio → one .mov, no loopback driver
    Given macOS 15.6.1 (ScreenCaptureKit), When `rec` / `screen-audio-record --system-audio`,
    Then a .mov with H.264 video + AAC system audio, straight off the audio engine (no BlackHole).
    # apple 412fccd · verified: Renoise 6s → avc1 3024x1964 + aac

  @hw-verified  `rec` one-word launcher, writes to the current folder
    Given `rec` on PATH, Then records → ./<timestamp>.mov in cwd; Ctrl-C finalizes.
    # apple eeb9b9e→264a8fd · verified live

  @hw-verified  --app scopes audio to a single app; --list enumerates
    # apple 412fccd · verified: Renoise-only audio isolation

  @hw-verified  Live mic on/off via SIGUSR1 (own track, updateConfiguration)
    Given a recording, When kill -USR1 <pid>, Then mic track toggles without restart.
    # apple 4f47a4c · verified: start-off→on→off→stop = 3-track .mov

  @hw-verified  --reveal (open -R) + --mic start state
    # apple 4f47a4c · verified

  @hw-verified  rec-audio split → system.m4a + mic.m4a (iMovie-independent tracks)
    Given a 2-track recording, When `rec-audio split`, Then two AAC sidecars.
    # apple 3335cc1 · verified

  @hw-verified  rec-audio flatten → video-passthrough .mov + one mixed AAC track
    # apple 3335cc1 · verified: AVAssetReaderAudioMixOutput, 1 video + 1 audio

  @hw-verified  --mic auto-flatten → YouTube-ready -flat.mov (the crisis fix)
    Given YouTube plays only track 1, When `rec --mic` stops, Then also emits -flat.mov mixed.
    # apple d8a65e0 · verified: both files produced, standalone too

  @hw-verified  TCC endless-prompt fix — bundle recorder in the app, same-identity signed
    Given the app was spawning an ad-hoc EXTERNAL binary (cdhash churns), Then re-prompt forever;
    When bundled in Contents/Helpers signed with the app's Apple-Dev identity, Then inherits the grant.
    # apple 214c3a5 · verified: helper flags=0x0(none), team 4V23QQYP9T, bundle verify OK

  @hw-verified  Recovered the user's real 24-min recording (voice on track 2) → -flat.mov
    # ~/Downloads/2026-07-02-17-50-32-flat.mov, verified both audio mixed

  @hw-verified  apple-rec standalone mirror synced (rec-audio + auto-flatten)
    # apple-rec 9ecd7e3 · verified: `rec --mic` self-builds both, emits both files

  @hw-verified  doi2scihub → convey `scihub --browser`; apple copy shimmed (DRY)
    # convey 41e9a8db, apple 6ee6d97→8000e55 · verified: URL logic + flag registration

  @built        AppleToolbox: ⌃⌥⌘R start/stop + Sound/Sound+Mic chooser + ⌃⌥⌘M mic toggle
    Compiled, deployed, hotkeys registered (no failure log). The GUI click / NSAlert / global
    keypress / auto-flatten-from-menu were NOT driven headlessly. The recorder they invoke IS
    @hw-verified. # apple 4f47a4c, d8a65e0

  @built        Answered (verified via web): can't replace YouTube file/audio and keep the URL
    Delivered the "new upload + turn old video into a signpost" plan. User's re-upload = their action.

---

## ⚠️ DROPPED ON THE FLOOR — planned, not built

  @todo  STEP 2 — Webcam "speaking head" capture (simultaneous webcam .mov for PiP)
    Explicitly on the roadmap. I asked the fork "separate file vs baked-in PiP?" — the
    mic-not-in-YouTube crisis interrupted and it was NEVER ANSWERED or built. This is the
    biggest dropped thread. Fork still open.

  @todo  STEP 3 — Whisper → .srt subtitles (feed -mic.m4a) + optional burn-in
    Planned as step 3 of the pipeline (whisp skill already exists). Never started.

  @dropped  Real-time MIXED single track AT RECORD time (PCM summation of sys+mic)
    Theorized in detail, then superseded by post-hoc `rec-audio flatten`. Flatten covers the
    need, so this is a deliberate drop — but the record-time mix was never built.

  @todo  CARD DEBT — features/screen-audio-record.feature is STALE
    It covers through "ship 4" (mic toggle/chooser/hotkeys). It does NOT card the later units:
    the TCC bundling fix, rec-audio (split/flatten), or --mic auto-flatten. Per the mandatory
    "building emits its card" rule, those shipped WITHOUT updating the card.

  @todo  rec-audio has NO card of its own
    A whole shipped unit (split/flatten) with no `.feature`. Should get one.

  @todo  Sweep other launchers for the dead ~/work/apple/topbar/AppleToolbox.app path
    I offered to grep all scripts/aliases/Loupedeck/Shortcuts for the stale path (the one that
    broke the "Hey Apple" Shortcut) so we catch them ALL. User didn't take it up; I didn't run
    it. Other launchers may still point at the deleted path. → fix: repoint to
    `open -b com.esaruoho.appletoolbox`.

---

## 💭 IDEAS RAISED, NEVER TRACED
- **Whether the user's iMovie export actually contains the voice** — I recommended my verified
  -flat.mov instead; the iMovie export was never confirmed either way.
- **Confirm the re-upload succeeded with audio** — open loop (user's action).
- **Stale `/Applications/AppleToolbox/AppleToolbox.app.STALE-20260528`** — flagged, left in
  place (didn't create it). Cleanup never done.
- **rec-audio.swift uses AVAssetExportSession** (deprecated in macOS 15) — works, but the
  `export(to:as:)` migration was noted and skipped.
- **A `rec-audio` slash + wiki page / mixing levels beyond the fixed 0.8 attenuation** — never scoped.

---

## RESULT (this session)
- apple `main`: 412fccd, eeb9b9e, 264a8fd, 4f47a4c, 214c3a5, 3335cc1, d8a65e0, 6ee6d97, 8000e55 (+ bot auto-regens).
- apple-rec `main`: c8af559, 0f48f50, 9ecd7e3.
- convey `main`: 41e9a8db.
- Memory written: `feedback_tcc_bundle_sck_helper_same_identity.md`, `apple_rec_standalone.md`.
- Pre-existing WIP left untouched (not ours): apple `atlas/*`, convey `FAILED-DOIS.md` + cache.

## How to get back
- Transcript: `file:///Users/esaruoho/.claude/projects/-Users-esaruoho-work-apple/6d81d169-c28a-4913-9650-2716a635d7a5.jsonl`
- Session ID: `6d81d169-c28a-4913-9650-2716a635d7a5` · Resume: `claude --resume 6d81d169-c28a-4913-9650-2716a635d7a5`
- When: 2026-07-02 ~00:45 EEST → 2026-07-03. Machine: macOS 15.6.1 (24G90).
