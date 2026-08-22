# ============================================================================
# REPORT CARD — a recording survives ScreenCaptureKit dying under it
# ============================================================================
#
# WHAT THIS CARD SPAWNS
#   Codespace : bin/screen-audio-record.swift — `handleStreamFailure(_:)`,
#               `tryReconnect()`, `scheduleRetry(_:)`, `giveUp(_:)`, the extracted
#               `makeFilter(_:_:)` and `pixelSize(of:)`, the `contentFilter` /
#               `writerWidth` / `writerHeight` / `interruptionCount` /
#               `totalFrozenSeconds` / `cutShort` state, and the `cutShort`,
#               `cutShortReason`, `interruptions`, `frozenSeconds` manifest fields.
#   Thinkspace: features/recburn-stream-recovery.session.md.
#   Areaspace : OWNS = what happens when the OS ends the capture. MUST NOT TOUCH = the
#               response to dropped frames (report, never act), the meaning of Ctrl-C,
#               or the captured file, which is never discarded.
#
# WHY THIS CARD EXISTS
#   Esa: "does recburn have some way of 'oh no you dropped frames, im gonna exit the
#   recording', cos thats not good."
#   The answer to the question as asked was no — but the investigation found the one path
#   that DID end a recording unasked, and it had ended one of ours an hour earlier.
#
# REPORT-CARD LEGEND
#   @hw-verified  run live on this Mac (macOS 15.6.1, 2026-08-22); numbers were measured.
#   @built        wired + compiles; that branch was not exercised live (and why).
#   @note         a documented boundary.
#
# RESULT
#   Direct-push to main, no PR. Mirrored to esaruoho/apple-rec; RecBurn.app rebuilt and
#   reinstalled to /Applications with this engine.
# ============================================================================

Feature: The only thing that ends a take is the person making it

  @hw-verified
  Scenario: dropped frames do not stop anything  (measured 2026-08-22)
    Given a recording in progress at 60 fps
    When all 12 cores are flooded for 15 seconds
    Then the writer falls to 38 fps of 60 and says so, naming the processes eating the CPU
    And the recording continues through it and for 6 seconds after the load is released
    And 24 seconds are captured, exit code 0, file intact
    # innards: `checkHealth()` writes to stderr and does nothing else — it holds no
    # reference to finish() or exit(). Every err() exit in the file is startup-time.

  @hw-verified
  Scenario: killing replayd no longer ends the take  (measured 2026-08-22)
    Given a recording that has been running for 6 seconds
    When `kill -9` is sent to /usr/libexec/replayd
    Then ScreenCaptureKit reports "Failed during stream due to application connection being interrupted"
    And the recorder says "this was NOT you" and reconnects in 0.3s
    And recording continues to 31 seconds total
    And ffprobe finds ONE continuous file: 1218 frames, 0.00s → 31.49s, with a single
      0.28s gap at t=5.47 — exactly the outage, and nothing lost after it
    # Before this change the same kill ended the take at 6 seconds and then ran the whole
    # flatten + transcribe + burn pipeline on the truncated result.

  @hw-verified
  Scenario: the interruption is on the record, not just in the scrollback  (2026-08-22)
    Then the closing line reads "· survived 1 interruption (0.3s frozen)"
    And the manifest carries "interruptions": 1 and "frozenSeconds": 0.2995949983596802
    # innards: `RecBurnManifest.interruptions` / `.frozenSeconds`, both optional, so a
    # clean recording's manifest is unchanged and older readers are unaffected

  @note
  Scenario: why writing into the same file works at all
    Given a NEW SCStream is built after the old one died
    Then its sample buffers carry mach-time-based presentation timestamps
    And those are monotonic across the outage, so the writer's timeline simply continues
    And `sessionStarted` is already true, so no second startSession is attempted
    And the gap renders as the last frame held for the length of the outage

  @built
  Scenario: two failures are deliberately NOT retried through
    Given the display resolution changed mid-recording
    Then reconnection stops, because the file is already committed to the old dimensions
    And the reason names both sizes
    Given instead that the --app being recorded has quit
    Then reconnection stops, because the recording that was asked for no longer exists
    # innards: the two `giveUp(…)` guards in `tryReconnect()`. @built: neither was staged
    # live. Retrying through either would produce a file worse than an honest stop.

  @built
  Scenario: giving up is unmistakable
    Given 60 seconds of continuous downtime have passed
    Then a boxed "RECORDING CUT SHORT" banner is printed
    And it says "THIS WAS NOT YOU — nothing you pressed ended this take"
    And the captured file is still finalized and still playable
    And the manifest carries cutShort: true plus the reason
    # @built: the 60s budget was never reached live — every real failure reconnected on
    # the first attempt. Backoff is 0.5s, 1s, 2s, 4s, then every 5s.

  @hw-verified
  Scenario: a cut-short take does not silently cost you the render  (2026-08-22)
    Given a take was cut short and post-processing is about to start
    Then the hint changes to "(this take was cut short — Ctrl-C NOW to skip the render of it)"
    # Nobody asked for that render. It is exactly the twenty minutes that
    # [[recburn-abort]] was built to give back, so the abort is offered by name here.

  @note
  Scenario: what is still stale
    Given AppleToolbox.app bundles its own copy of the engine
    Then /Applications/AppleToolbox/.../Contents/Helpers/screen-audio-record is from Jul 3
    And it was NOT rebuilt here, because replacing a nested helper invalidates the outer
      signature and re-signing AppleToolbox risks its Screen Recording and FDA grants
