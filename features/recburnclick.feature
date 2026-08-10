# ============================================================================
# REPORT CARD — recburnclick: a live click counter burned into the recording
# ============================================================================
#
# WHAT THIS CARD SPAWNS
#   Codespace : bin/recburnclick (wrapper: rec + --clicks), and inside
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
# RESULT
#   Direct-push to main, no PR. Files: bin/recburnclick, bin/screen-audio-record.swift
#   (+ rebuilt binary), commands/recburnclick.md, features/recburnclick.feature + .session.md.
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
