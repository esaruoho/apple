# ============================================================================
# REPORT CARD — recburn normalises the delivered video's loudness
# ============================================================================
#
# WHAT THIS CARD SPAWNS
#   Codespace : bin/rec-audio.swift — `Levels` (peak, whole-file RMS, 4096-bin amplitude
#               histogram, 400ms block RMS, and `gated` loudness), `gainFor`, `softLimit`,
#               `measureLevels`, `applyGain`, the `level` and `normalize` verbs, and
#               normalisation inside `flatten`. bin/screen-audio-record.swift — the
#               `--no-normalize` opt-out, passed through to the flatten step.
#   Thinkspace: features/recburn-loudness.session.md.
#   Areaspace : OWNS = how loud the delivered .mov is. MUST NOT TOUCH = the video stream
#               (passthrough always), the balance between mic and system audio, or the
#               dynamics of the take (one constant gain, never per-moment AGC).
#
# WHY THIS CARD EXISTS
#   Esa: "i want you to improve recburn in such a way that it shows the volume of the
#   recording, so that we can normalize it so its good volume overall … so when it flattens,
#   before it delivers the flattened video, and before it starts burning in the subtitles,
#   it will actually increase the volume."
#   A screencast mixes app audio that was already mastered with a microphone a metre away.
#   The result is reliably too quiet, and the viewer has to reach for the volume knob.
#
# REPORT-CARD LEGEND
#   @hw-verified  run live on this Mac (macOS 15.6.1) against Esa's own 78-minute recording;
#                 every number below was measured, and the OUTPUT was re-measured.
#   @built        wired + compiles; that branch was not exercised live (and why).
#   @note         a documented boundary.
#
# RESULT
#   Direct-push to main, no PR. Mirrored to the public standalone esaruoho/apple-rec.
# ============================================================================

Feature: Deliver a recording at a normal listening level, measured not guessed

  @hw-verified
  Scenario: the absolute peak is the wrong thing to normalise against  (measured 2026-08-14)
    Given Esa's 2026-08-14-13-26-01-flat-subtitled.mov (78 min, 11 GB)
    When its amplitude distribution was measured
    Then the absolute peak was 0.0 dBFS but the 99.99th percentile was only -7.6 dBFS
    And that lone full-scale sample is a click, not the level of the recording
    And peak normalisation would therefore have applied -1.0 dB — attenuating a video
      whose actual problem is that it is far too quiet
    # innards: `Levels.hist` + `Levels.percentile(_:)`
    # THIS IS WHY the first design was wrong and had to be replaced: it took
    #   min(peak-gain, rms-gain), so one click vetoed the whole feature.

  @hw-verified
  Scenario: whole-file RMS is also wrong, because a screencast is mostly pauses  (2026-08-14)
    Given the same file
    Then its median sample sits at -51.8 dBFS — the file is mostly silence between sentences
    And whole-file RMS read -32.1 dBFS while the GATED loudness was -29.6 dBFS
    # innards: `Levels.gated` — 400ms blocks, absolute gate at ~-60 dBFS, then a relative
    #          gate 10 dB below the mean of what survived (the shape EBU R128 uses)
    # WHY: gating measures the material that is actually PLAYING. Without it you normalise
    #      against the silence and under-lift every recording that has pauses in it.

  @hw-verified
  Scenario: the whole thing is lifted, on Esa's own material  (ran live 2026-08-14)
    Given a 90s excerpt cut losslessly from that recording (stream copy, 10:00-11:30)
    When `rec-audio normalize` ran
    Then loudness went from -34.6 dBFS to -18.1 dBFS — a +16.6 dB lift
    And the peak landed at exactly -1.0 dBFS, so nothing clips
    And re-measuring the OUTPUT agreed: "+0.1 dB → -18.0 dBFS", i.e. already at target
    And it took 1.1s, because the video is stream-copied and only the audio is re-encoded
    # innards: `flatten(_:_:normalize:)` — measure pass, then `applyGain` on the write pass

  @hw-verified
  Scenario: the ceiling is a ceiling — a bug the tool's own output caught  (fixed 2026-08-14)
    Given the first limiter mapped overs with tanh into [knee, 1.0]
    When the normalised excerpt was re-measured
    Then it peaked at -0.0 dBFS while the tool had printed "ceiling -1 dBFS"
    And that is a false claim AND a real risk: true-peak overshoot after AAC encoding is
      how a "normalised" file ends up clipping in someone's player
    When the knee and the ceiling were separated (knee 5 dB below, tanh → ceiling)
    Then the same excerpt re-measured at exactly -1.0 dBFS
    # innards: `softLimit(_:ceiling:knee:)`
    # HOW CAUGHT: by running `rec-audio level` on the tool's own output. Measuring the
    #   input proves nothing about what you shipped.

  @hw-verified
  Scenario: it happens in flatten, so the subtitled video inherits it  (ran live 2026-08-14)
    Given Esa asked for it "before it delivers the flattened video, and before it starts
      burning in the subtitles"
    When a real 6s recording ran with --mic --auto-flatten
    Then the recorder printed the measurement, the gain and the result during flatten
    And the recorder burns subtitles from the flattened file, so the subtitled deliverable
      carries the normalised audio without a second pass
    # innards: screen-audio-record `makeYouTubeVersion` (flatten) → `makeSubtitledVersion`

  @hw-verified
  Scenario: near-silence is not amplified into hiss  (observed live 2026-08-14)
    Given a test recording made in a silent room measured -58.2 dBFS
    When it was normalised
    Then the gain was capped at +30.0 dB and it said so, rather than reaching for the
      +40 dB the target would have implied
    # innards: `maxBoostDb`

  @hw-verified
  Scenario: the volume is SHOWN, not just changed  (ran live 2026-08-14)
    Given "i want you to improve recburn in such a way that it shows the volume"
    When `rec-audio level <video>` runs
    Then it prints gated loudness, peak, whole-file RMS, the p50/p90/p99/p99.9/p99.99
      spread, and the gain it WOULD apply — changing nothing
    And `flatten` prints the same measurement inline while recording finishes
    # innards: the `level` verb

  @hw-verified
  Scenario: delivered on the real 78-minute recording  (ran live 2026-08-14)
    Given Esa's own capture, after redaction
    When `rec-audio normalize` ran on the full 14 GB file
    Then loudness went -29.6 -> -20.9 dBFS (+9.5 dB) in 53 seconds
    And frame count (140401) and duration (4680.033s) were unchanged, because the video
      is stream-copied and only the audio is re-encoded
    # NOTE ON THE SHORTFALL: it stopped at -20.9, not the -18 target, because the gain is
    #   capped by headroom — the 99.9th-percentile sample sits at -10.5 dBFS. Reaching -18
    #   would mean shaping considerably more transients. The tool chose the honest cap.
    # NOTE ON THE PEAK: the delivered file measures 0.0 dBFS peak although the limiter
    #   ceiling is -1. The limiter runs on PCM BEFORE the AAC encode, and AAC reconstructs
    #   a few samples slightly above where they went in. p99.99 sits at -1.1 dBFS, so the
    #   bulk respects the ceiling. A true-peak limiter would be needed to guarantee it.

  @hw-verified
  Scenario: recburn does it automatically, on every take  (ran live 2026-08-14)
    Given `recburn --no-pip --no-burn` (mic on, which is what makes flatten run)
    When ~7s was recorded and stopped
    Then the raw capture measured -52.1 dBFS and the delivered -flat.mov measured
      -23.4 dBFS, peak -1.6 — a +28.7 dB lift with no flag passed
    And the +30 dB boost cap was reported rather than silently applied
    # innards: screen-audio-record `makeYouTubeVersion` -> rec-audio `flatten`

  @note
  Boundary: plain `rec` is NOT normalised
    Flatten only runs when `--auto-flatten` AND the mic was actually used
    (`opts.autoFlatten && micEverOn`), so a system-audio-only `rec` take never reaches the
    normaliser. recburn/recburnclick always pass --mic, so they always do. Closing this
    would mean either re-encoding audio on every plain capture, or having `rec` emit a
    -flat.mov it does not produce today — a design choice, not an oversight.

  @note
  Boundary: one constant gain, deliberately — not compression or AGC
    The whole recording is multiplied by a single number, so nothing pumps, breathes, or
    shifts the balance between voice and app audio. Only the transients above the knee are
    shaped, and the tool reports what percentage that was.

  @note
  Boundary: the limiter is stateless, with no look-ahead
    A sample-wise soft knee cannot anticipate a transient the way a real look-ahead limiter
    does. For speech-plus-app-audio at these gains it is inaudible; for music mastering it
    would not be the right tool.

  @note
  Boundary: gated loudness here is RMS-based, not true LUFS
    No K-weighting filter is applied, so the number is not directly comparable to a
    broadcast LUFS meter. The gating shape is R128's; the weighting is not. Good enough to
    normalise consistently against itself, which is what this pipeline needs.
