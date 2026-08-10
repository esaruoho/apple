# ============================================================================
# REPORT CARD — recburnclick: a live click counter burned into the recording
# ============================================================================
#
# WHAT THIS CARD SPAWNS
#   Codespace : bin/recburnclick (wrapper: recburn + --clicks) and bin/recburn (which the
#               apple repo was missing entirely — brought over from the standalone), inside
#               bin/screen-audio-record.swift — the `ClickCounter` type, the
#               `clickBadge(_:baseW:)` renderer, the badge block in `compositeFrame`
#               (renamed from compositePiP, since it now composes more than PiP),
#               and the --clicks / --clicks-corner / --clicks-label / --clicks-seed flags.
#   Thinkspace: features/recburnclick.session.md.
#   Areaspace : OWNS = counting mouse-downs during a recording and drawing that number
#               into the video frames. MUST NOT TOUCH = the audio path, the PiP geometry,
#               the subtitle/burn pipeline, or anything requiring an event tap /
#               Accessibility grant.
#
# WHY THIS CARD EXISTS
#   Esa: "recburnclick — all it does is, in addition to everything else, it calculates the
#   amount of clicks. and shows it visibly … everytime i click, the counter goes up. so
#   thats in the video, too." A demo video that shows its own click count is self-evidencing:
#   the viewer sees "this took 4 clicks" rather than being told afterwards.
#
# REPORT-CARD LEGEND
#   @hw-verified  compiled AND run live on this Mac (macOS 15.6.1 / 24G90); the claim was
#                 checked against the actual recorded pixels via Apple Vision OCR.
#   @built        wired + compiles; that branch was not exercised live (and why).
#   @note         a documented boundary, not an executable claim.
#
#   MIRRORED to the public standalone esaruoho/apple-rec (~/work/apple-rec), which is where
#   RecBurn.app lives: Engine/screen-audio-record.swift, Engine/recburnclick, build.sh
#   (ships recburnclick in bin/), Sources/RecBurn/{RecBurnController,RecBurnApp}.swift for
#   the menu setting. Standalone is canonical on divergence (same rule as apple-energy).
#
# RESULT
#   Direct-push to main, no PR. Files: bin/recburnclick, bin/recburn,
#   bin/screen-audio-record.swift (+ rebuilt binary), commands/recburnclick.md,
#   features/recburnclick.feature + .session.md; plus the apple-rec mirror above.
# ============================================================================

Feature: Burn a live click counter into a screen recording

  @hw-verified
  Scenario: counting clicks needs NO event tap and NO Accessibility prompt  (probed live 2026-07-29)
    Given the obvious implementations — CGEventTap or an NSEvent global monitor — both
      require Accessibility and hand us every event just to increment a number
    When CGEventSource.counterForEventType(.combinedSessionState, …) is read for
      leftMouseDown + rightMouseDown + otherMouseDown
    Then macOS returns the session's running tally with no permission dialog at all
      (probe on this Mac: left 7576, right 90, other 413)
    And the recorder takes a baseline at capture start, so the badge counts from 0
    # innards: `ClickCounter` in bin/screen-audio-record.swift

  @hw-verified
  Scenario: the number is really in the pixels  (ran live 2026-07-29)
    Given `screen-audio-record --system-audio --clicks --clicks-seed 42 --out clicktest.mov`
    When ~5s was recorded and frame @2s was extracted with AVAssetImageGenerator
    Then Apple Vision OCR of the top-left corner of that frame read "CLICKS: 42"
    And this is the claim that matters — not that the flag parsed, but that the badge
      survived H.264 encoding into the delivered file
    # innards: `clickBadge(_:baseW:)` + the badge block in `compositeFrame(screen:pts:)`
    # HOW TESTED: record → extract frame → crop corner → bin/vision-ocr. No human looking
    #             at a video and saying "yeah that looks right".

  @hw-verified
  Scenario: corner and label are honoured  (ran live 2026-07-29)
    Given `recburnclick --clicks-corner br --clicks-label TAPS --clicks-seed 7`
    When frame @2s was cropped to the BOTTOM-RIGHT quadrant and OCR'd
    Then it read "TAPS: 7" — so both the placement and the relabelling reached the pixels
    # innards: the `switch opts.clicksCorner` block; `opts.clicksLabel`

  @hw-verified
  Scenario: plain `rec` is unchanged  (ran live 2026-07-29)
    Given --clicks made the pixel-buffer-adaptor path apply to more than just --pip
    When plain `rec --fps 15` ran with no click flags
    Then it still produced 3024x1964 video with 1 audio track, 3.2s, 1193932 bytes
    # innards: `setupWriter` — `if opts.pip || opts.clicks`; and the frame-path branch
    # WHY CHECKED: widening a shared condition is exactly how an unrelated feature breaks.

  @built
  Scenario: the counter goes UP as you click
    Given the badge is redrawn whenever the count changes
    When a left, right or middle mouse-down happens during the recording
    Then the next composited frame shows the incremented number
    # innards: `ClickCounter.count` (seed + sessionTotal − baseline), read per frame;
    #          `badgeCache` re-renders only when (count, width) changes, so the badge
    #          neither shimmers nor costs a text layout every frame
    # NOT VERIFIED HERE, AND WHY: a real click is required. Synthetic clicks posted to my
    #   own pid (CGEvent.postToPid) were tried and do NOT move the session counter —
    #   confirmed by probe, delta 0. The only synthetic click that WOULD count is one
    #   posted to the session, which lands in whatever app Esa is using: the exact
    #   UI-hijack that is forbidden while he is at the keyboard. So this scenario is
    #   Esa's one-click check, deliberately left ungraded rather than faked.

  @built
  Scenario: --clicks composes with --pip and --mic
    Given the badge is composited after the webcam corner in the same CIImage chain
    Then a speaking-head demo can also carry its click count
    # innards: `compositeFrame` — PiP block, then the badge block, then one ctx.render
    # NOT VERIFIED: --pip switches the webcam on, and the camera light during Esa's
    #   working session is not a side effect worth a test run.

  @hw-verified
  Scenario: recburnclick inherits RECBURN's settings, not rec's  (ran live 2026-07-29)
    Given recburn = rec --mic --pip --burn, so it records the microphone
    And the first cut of recburnclick chained to `rec`, which silently dropped the mic
    When `recburnclick --no-pip --no-burn` ran
    Then the recorder announced "🎤 microphone: ON — your voice IS being recorded"
    And the .mov carried 2 audio tracks (system + mic), not 1
    # innards: bin/recburnclick — `exec "$DIR/recburn" --clicks "$@"`
    # NOTE: the apple repo had no bin/recburn at all; only the standalone did. Brought over.

  @hw-verified
  Scenario: a chained wrapper can be subtracted from  (ran live 2026-07-29)
    Given recburnclick → recburn → rec each ADD flags, so there was no way to drop one
    When --no-mic / --no-pip / --no-burn / --no-clicks are passed after them
    Then the later flag wins, because parsing is sequential
    And this is what made the test above possible without switching the webcam on
    # innards: the negation cases in `parseArgs()`

  @built
  Scenario: the click counter is a RecBurn.app menu setting with its own corner
    Given Esa: "the bottom-right position should be something i can decide, from recburn
      app on topbar too"
    Then the menu has "Click Counter (CLICKS: n, burned in)" plus a "Click Counter
      Position" submenu (Top Left / Top Right / Bottom Left / Bottom Right)
    And the corner is chosen INDEPENDENTLY of the webcam's — they share the PiPCorner
      type but never the value, since you want them in opposite corners
    And both persist in UserDefaults and are settable per-recording over the URL scheme
      (`?clicks=0|1&clickcorner=tl|tr|bl|br`)
    # innards: apple-rec Sources/RecBurn/RecBurnController.swift (clickCounter,
    #          clicksCorner, args, applyQuery) + RecBurnApp.swift (menu + actions)
    # NOT VERIFIED: RecBurn.app builds clean (21.9s, signed), but clicking through its
    #   menu bar means driving Esa's UI while he works. His check, not mine.

  @hw-verified
  Scenario: the counter can be zeroed mid-recording  (ran live 2026-08-10)
    Given a recording seeded to 77 with a busy screen so frames track wall time
    When SIGUSR2 arrived at 6s wall (≈5.3s of a 10.6s video)
    Then the burned-in badge read 77 at t=1s and t=3s, and 0 at t=5s, t=7s, t=9s
    And the recording was neither stopped nor split — it kept going at 0
    # innards: `ClickCounter.reset()` (baseline←now, seed←0), the SIGUSR2 DispatchSource in
    #          `installSignalHandler()`, `resetClicks()`, and `badgeCache = nil` so the
    #          next frame redraws even if no further click changes the number
    # HOW TESTED: OCR of frames sampled across the timeline, not one lucky frame. A first
    #   attempt sampled only two points and misread the result, because with a STATIC
    #   screen SCK emits frames sparsely and video time drifts from wall time.

  @hw-verified
  Scenario: the counter really does go UP on real clicks  (observed live 2026-08-10)
    Given an earlier reset test ran while Esa was working
    Then the badge sequence across that video was 50 → 0 → 1 → 2 → 3
    And nothing but a left/right/middle mouse-down can move that number, so those
      increments are his actual clicks — the scenario previously graded @built
    # innards: `ClickCounter.count`
    # NOTE: observed rather than staged. Synthetic clicks still cannot be used (see below).

  @hw-verified
  Scenario: any trigger can fire the reset — it is a signal, not a keystroke  (ran live 2026-08-10)
    Given `recburn-click-reset` sends SIGUSR2 to whatever is recording
    When it ran during a recording, the recorder logged "↺ clicks reset to 0"
    And with nothing recording it printed "nothing is recording" and exited 1, so a
      binding can tell the difference
    # innards: bin/recburn-click-reset
    # WHY A SIGNAL: it works from a global hotkey, a Loupedeck/Stream Deck button, a MIDI
    #   mapping, a Shortcut or a bare `kill -USR2` alike — no window, no key capture, no
    #   Accessibility grant. Same seam as the existing SIGUSR1 mic toggle.

  @built
  Scenario: ⌃⌥⌘Space zeroes the counter from anywhere
    Given RecBurn.app registers ⌃⌥⌘Space with Carbon's RegisterEventHotKey
    When the combination is pressed while any app is frontmost
    Then the app sends SIGUSR2 to the recorder — its own child if it started one,
      otherwise any running recorder, so it also works during a CLI recording
    And the menu carries "Reset Click Count to 0" showing the same shortcut
    # innards: apple-rec Sources/RecBurn/RecBurnApp.swift `registerResetHotKey()` +
    #          RecBurnController.swift `resetClickCount()`
    # VERIFIED: RegisterEventHotKey returned noErr on this Mac — nothing else owns
    #   ⌃⌥⌘Space (a conflict WOULD have been logged, and is the one failure mode
    #   detectable without pressing keys).
    # NOT VERIFIED: that it actually fires. status == noErr is NOT proof a hotkey fires
    #   (a documented gotcha in this repo), and confirming it needs a real keypress —
    #   synthesising one would post keys into whatever app Esa has focused.
    # BOUNDARY: Carbon hotkeys need a real NSApplication, so this requires RecBurn.app to
    #   be running. A pure-terminal recording has `recburn-click-reset` instead. The hotkey
    #   is deliberately registered in ONE process only — two registration sites across two
    #   apps race last-writer-wins.

  @note
  Boundary: it counts clicks, not what was clicked
    The session counter is a tally, not an event stream — there is no target, no
    coordinates, nothing about WHICH window received the click. That is the trade for
    needing no permission, and it is the right trade for "how many clicks did this take".

  @note
  Boundary: clicks from anywhere count
    The tally is session-wide, so a click in a different app during the recording still
    increments it. For a demo video that is correct (a click is a click); for measuring
    one app specifically it would not be.

  @note
  Boundary: --clicks-seed is for demos and tests
    It starts the counter at n rather than 0. It exists so the burned-in badge can be
    verified headlessly against a known number, and for a take that continues a count
    from a previous recording.
