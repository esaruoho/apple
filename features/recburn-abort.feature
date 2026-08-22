# ============================================================================
# REPORT CARD — Ctrl-C twice abandons the pipeline and returns the shell
# ============================================================================
#
# WHAT THIS CARD SPAWNS
#   Codespace : bin/screen-audio-record.swift — `abortRequested`, `runningChild`,
#               `partialOutputs`, `isAborting()`, `descendants(of:)`, `killTree(_:)`,
#               `cleanupPartials()`, `handleInterrupt()`, `abortNow()`, the SIGINT/SIGTERM
#               sources in `installSignalHandler()`, the abort checks inside
#               `makeYouTubeVersion` / `makeSubtitledVersion` / `finish()`, and the
#               `aborted` field on `RecBurnManifest`.
#   Thinkspace: features/recburn-abort.session.md.
#   Areaspace : OWNS = what a second Ctrl-C means once the capture has stopped, and the
#               lifetime of every process the post-stop steps spawn. MUST NOT TOUCH = the
#               meaning of the FIRST Ctrl-C (stop + finalize, unchanged since day one), the
#               raw capture (never deleted, ever), or a `.srt` that whisper finished writing.
#
# WHY THIS CARD EXISTS
#   Esa: "i want ctrl-c to be the 'halt the whole recburn' … imagine if i botched up a 1 hour
#   recording and i need to wait 20 minutes to get the botched recording to finish being
#   botched, and then i am not able to ya know just start recording the thing again."
#   The recorder ignored SIGINT after the first press, so a bad take cost the full render
#   before it could be re-shot. The cost is proportional to the length of the mistake, which
#   is exactly backwards.
#
# REPORT-CARD LEGEND
#   @hw-verified  run live on this Mac (macOS 15.6.1, 2026-08-22); numbers were measured.
#   @built        wired + compiles; that branch was not exercised live (and why).
#   @note         a documented boundary.
#
# RESULT
#   Direct-push to main, no PR. Mirrored to the public standalone esaruoho/apple-rec.
# ============================================================================

Feature: Two presses of the same key always get the shell back

  @hw-verified
  Scenario: the second Ctrl-C abandons transcription and exits at once  (measured 2026-08-22)
    Given a `rec --mic --burn` recording that has been stopped with one Ctrl-C
    And the flatten step has finished and rec-subtitle is running
    When SIGINT is sent a second time
    Then the recorder prints "aborting — the recording is kept, the rest of the pipeline is cancelled"
    And the shell comes back in 0.1s
    And the exit code is 130
    # innards: `handleInterrupt()` dispatches by count — `finishing` then `abortRequested`

  @hw-verified
  Scenario: killing the child is not enough — the tree has to go  (measured 2026-08-22)
    Given rec-subtitle runs whisper as `bash -lc`, and Foundation's Process puts every
      spawn in its OWN process group
    Then rec-subtitle sits in one group and whisper sits in another
    And `kill(-pgid)` on the child would leave whisper eating a core after the abort
    When the shipped `descendants(of:)` + `killTree(_:)` were compiled against a
      deliberately 3-deep tree spanning separate process groups
    Then all 3 processes were gone after the call, and 0 survived
    # innards: `descendants(of:)` walks PPID from `ps -axo pid=,ppid=`, because parentage
    # is the only structure that survives a process-group boundary

  @hw-verified
  Scenario: what is kept and what is deleted  (measured 2026-08-22)
    Given an abort landed while subtitles were being burned
    Then take.mov (the raw capture) is kept
    And take-flat.mov (the finished flatten) is kept
    And take-flat.srt is kept, and the recorder says "transcription had finished — kept …"
    And take-flat-subtitled.mov is removed, and the recorder says "removed half-written …"
    # innards: `cleanupPartials()`; the `.srt` is deliberately absent from `partialOutputs`
    # because whisper writes it whole at the end, so its existence proves it finished — and
    # it is the most expensive minutes of the run to throw away

  @hw-verified
  Scenario: the escape hatch is announced when it becomes true  (2026-08-22)
    Given post-processing is about to start after the first Ctrl-C
    Then "(Ctrl-C again to abandon the rest — the recording itself is already safe)" is printed
    # innards: `finish()`, gated on `opts.burn || (opts.autoFlatten && micEverOn)` — silent
    # when there is nothing to abandon, and printed at the moment it applies rather than
    # buried in --help where nobody is looking

  @hw-verified
  Scenario: the watchdog fires when finishWriting never returns  (observed 2026-08-22)
    Given ScreenCaptureKit failed the stream with "application connection being interrupted"
    And `stopCapture`'s completion therefore never ran, so the writer never finalized
    When the abort was requested
    Then nothing was killed, because no child had started yet
    And 8 seconds later the recorder printed "still finalizing after 8s — leaving anyway"
    And `_exit(130)` ran
    # innards: the `asyncAfter(deadline: .now() + 8)` in `abortNow()`. This branch was NOT
    # written for a test — it caught a real SCK failure on the first run that hit it. Before
    # this change that state hung forever.

  @built
  Scenario: an abort must never corrupt the .mov it is abandoning
    Given the abort arrives while AVAssetWriter is still inside finishWriting
    Then the process does NOT exit immediately, because that produces an unplayable file
    And `abortRequested` is set and every later stage checks `isAborting()` and skips
    And the exit happens on the normal path, after the writer lands
    # @built: reached live only via the SCK-failure path above, where the writer never
    # landed at all. The ordinary "abort during a slow finalize" case is by construction.

  @built
  Scenario: SIGTERM climbs the same ladder
    Given `kill <pid>` is sent instead of Ctrl-C
    Then it stops the recording if one is running, and abandons post-work if not
    # innards: a second DispatchSource on SIGTERM pointing at `handleInterrupt()`. Wired
    # so an external stop cannot drop the capture on the floor mid-write; not exercised live.

  @note
  Scenario: one press is never destructive
    Given Ctrl-C could have been overloaded into "throw the recording away"
    Then it deliberately is not
    And the raw capture is the one artifact that cannot be produced again
    And RecBurn.app's stop button (`p.interrupt()`, one SIGINT) therefore behaves exactly
      as it always has

  @note
  Scenario: the manifest says so
    Given a consumer reads <base>.recburn.json to find the finished article
    Then `aborted: true` is present when the pipeline did not run to the end
    And `final` must not be presented as finished when that flag is set
    # innards: `RecBurnManifest.aborted` — an optional, so older readers are unaffected
