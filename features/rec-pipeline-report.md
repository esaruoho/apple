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
    Delivered the "new upload + turn old video into a signpost" plan. User re-uploaded — DONE.

  @hw-verified  STEP 2 — Webcam baked-in picture-in-picture (--pip)  (ran live)
    Given --pip, When recording, Then each screen frame is composited with the webcam corner
    (Core Image → AVAssetWriterInputPixelBufferAdaptor) and the "speaking head" is baked in.
    Verified: extracted frame shows the webcam rectangle placed/sized correctly (bottom-right).
    CAVEAT: the camera SOURCE was black in the headless test (covered/held — raw grab mean=0.0),
    so live imagery unconfirmed; the compositing pipeline IS confirmed. AppleToolbox chooser
    gained a "🎥 Include webcam" checkbox. # apple 5f75463

  @hw-verified  STEP 3 — Whisper .srt + hard burn-in (rec-subtitle)  (ran live)
    `rec-subtitle <video>` → whisp/Whisper → <stem>.srt. `--burn` → <stem>-subtitled.mov with
    subtitles painted into the picture (AVVideoCompositionCoreAnimationTool; text rasterized to
    CGImage because CATextLayer doesn't draw in the offline render; DISCRETE opacity keyframe).
    Verified: t=3s shows the subtitle right-side-up + outlined, t=0.4s (pre-cue) is clean.
    Transcription wired to whisp (@built — no full Whisper run in-test, to spare CPU). # apple 4725ebc

  @hw-verified  rec-audio backward-compat to Ventura + version-safe export  (ran live)
    #available(macOS 15) branch: modern export(to:as:) on 15+, deprecated path on 13–14; built
    -target macos13.0 → minos 13, runs on Ventura/Sonoma/Sequoia+, no deprecation warnings. # apple 0f03398

  @hw-verified  Launcher sweep — dead ~/work/apple/topbar/AppleToolbox.app path repointed  (ran live)
    hey-apple.applescript → `open -b com.esaruoho.appletoolbox`; toolbox-goto + grant-perms.md
    resolve the app by bundle id (mdfind). Re-sweep: no live references left. # apple 0f03398

  @hw-verified  Removed stale /Applications/AppleToolbox/AppleToolbox.app.STALE-20260528  (done)

---

## FEASIBILITY ANSWERED — tracing macOS backward
- **rec-audio (split/flatten):** floor = macOS **13 (Ventura)** — set by the async AVAsset
  loading APIs (`loadTracks`, `load(.duration)`). Could reach ~10.13 by switching to the old
  synchronous track accessors. Shipped at 13.
- **rec-subtitle burn-in:** also ~13 (async load + CoreAnimationTool).
- **The RECORDER floor is higher:** system-audio needs macOS **13** (SCStream audio), the live
  **mic** needs **15** (`captureMicrophone`), screen-only is **12.3**. So the mic/auto-flatten
  path can't drop below 15 without `#available` guards around captureMicrophone (not done).

## ⚠️ STILL OPEN — dropped/deliberate
  @dropped  Real-time MIXED single track AT RECORD time (PCM summation) — superseded by
    post-hoc `rec-audio flatten`; deliberately not built.
  @todo  CARD DEBT — features/screen-audio-record.feature still stops at "ship 4"; the TCC fix,
    rec-audio, auto-flatten, PiP, and rec-subtitle are carded HERE (this report) but that
    per-unit `.feature` was not brought current. rec-audio + rec-subtitle have no `.feature` of
    their own. (This report card is the honest interim; the per-unit backfill is the remaining debt.)
  @todo  Recorder mic-path Sonoma support — guard `captureMicrophone` behind #available to let
    the mic/auto-flatten path run on <15. Not done.

## 💭 CLARIFIED / CLOSED
- **iMovie import:** user confirmed the .mov carried BOTH voice + system audio and the export
  did too — but iMovie read them as ONE audio stream (merged), not two. Matches the known
  "iMovie merges embedded tracks" behavior; the re-upload is done.
- **Re-upload:** DONE (user).  **STALE copy:** removed.  **Deprecated export API:** fixed.

---

## RESULT (this session)
- apple `main`: 412fccd, eeb9b9e, 264a8fd, 4f47a4c, 214c3a5, 3335cc1, d8a65e0, 6ee6d97, 8000e55,
  0f03398 (launcher+backcompat), 5f75463 (PiP), 4725ebc (rec-subtitle) (+ bot auto-regens).
- apple-rec `main`: c8af559, 0f48f50, 9ecd7e3 (PiP/backcompat mirror pending).
- convey `main`: 41e9a8db.
- Memory: `feedback_tcc_bundle_sck_helper_same_identity.md`, `apple_rec_standalone.md`.
- Pre-existing WIP left untouched (not ours): apple `atlas/*`, convey `FAILED-DOIS.md` + cache.

## How to get back
- Transcript: `file:///Users/esaruoho/.claude/projects/-Users-esaruoho-work-apple/6d81d169-c28a-4913-9650-2716a635d7a5.jsonl`
- Session ID: `6d81d169-c28a-4913-9650-2716a635d7a5` · Resume: `claude --resume 6d81d169-c28a-4913-9650-2716a635d7a5`
- When: 2026-07-02 ~00:45 EEST → 2026-07-03. Machine: macOS 15.6.1 (24G90).
