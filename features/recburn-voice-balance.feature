# ============================================================================
# REPORT CARD — recburn makes the VOICE audible against the app audio
# ============================================================================
#
# WHAT THIS CARD SPAWNS
#   Codespace : bin/rec-audio.swift — `BalanceParams`, `micGainDb`, `planRebalance`,
#               `RebalancePlan`, `TimelineTrackReader`, `RebalancedMixer`,
#               `LevelAccumulator`, `Biquad`, `Follower`, `GainSmoother`,
#               `compressorGainDb`, `packGained`, `makeAudioSampleBuffer`,
#               `pcmFormatDescription`, `selfTest`, and the rebalance branch inside
#               `flatten` + the two-track report in `level`.
#               bin/screen-audio-record.swift — `Options.rebalanceAudio`, the
#               `--no-rebalance` flag, and its passthrough to the flatten step.
#               ../apple-rec/build.sh — the `rec-audio --self-test` build gate.
#   Thinkspace: features/recburn-voice-balance.session.md.
#   Areaspace : OWNS = the balance between the microphone and the app audio, and the
#               absolute-timeline alignment of the two audio tracks.
#               MUST NOT TOUCH = the video stream (passthrough always), the overall
#               delivered loudness (that is recburn-loudness.feature's job, and it runs
#               AFTER this), the subtitles, or the original recording.
#
# WHY THIS CARD EXISTS
#   Esa, after delivering a Renoise walkthrough: "it turns out the microphone was wayy
#   too quiet … can ya fix the volume of the mic since we have them as separate channels
#   … don't make it distort." Then, once it was fixed by hand: "the micfix is perfect.
#   how about you turn that into a recburn feature so when i recburn, it'll do that."
#
#   recburn-loudness.feature already normalises the delivered file, and that file was
#   correctly normalised — and the narration was still inaudible. One overall gain moves
#   the voice and the app audio TOGETHER, so it cannot close a gap between them. This is
#   the failure that normalisation is structurally unable to fix.
#
# REPORT-CARD LEGEND
#   @hw-verified  run live on this Mac against Esa's own 461-second recording; every
#                 number below was measured, and the OUTPUT was re-measured.
#   @self-test    asserted by `rec-audio --self-test`, which build.sh gates on.
#   @note         a documented boundary.
#
# RESULT
#   Direct-push to main, no PR. Mirrored to the public standalone esaruoho/apple-rec.
# ============================================================================

Feature: Lift the voice against the app audio, measured not guessed

  @hw-verified
  Scenario: normalisation cannot fix this, and the delivered file proved it  (2026-08-27)
    Given 2026-08-27-14-44-28.mov — a 461s Renoise walkthrough, system audio + mic
    When each audio track was measured on its own
    Then the system audio read -9.2 LUFS with a true peak of +0.5 dBTP (already clipped)
    And the microphone read -35.3 LUFS with a true peak of -10.6 dBTP
    And the narration was therefore 26 dB UNDER the wavetable demo it was narrating
    And the delivered -flat-subtitled.mov was correctly normalised to -15.8 LUFS
    And the voice in it was still inaudible
    # innards: `planRebalance`
    # THIS IS WHY one constant gain is not enough: it moves both sources together, so the
    #   26 dB survives normalisation exactly. The balance has to be set BEFORE the sum.

  @hw-verified
  Scenario: the two audio tracks do not start at the same instant  (measured 2026-08-27)
    Given the same recording
    Then the system track's first sample is stamped at 0.119042 s
    And the microphone's first sample is stamped at 0.299563 s
    And anything that simply concatenates decoded packets puts the voice 180 ms out
    When each sample buffer's PTS is converted to an absolute frame index and gaps are
      silence-filled, so frame 0 of the mix is frame 0 of the video
    Then the delivered audio cross-correlates against the original mix at lag 0.00 ms
    # innards: `TimelineTrackReader.pull()` / `.read(pos:frames:into:)`
    # HOW CAUGHT: the first hand-built version of this mix (ffmpeg, before the feature
    #   existed) landed 185 ms late, because the filter graph dropped the per-track start
    #   offsets and the mov muxer then wrote its own AAC-priming start_time on top.
    # @note the Swift path beats that hand-built version: 0.00 ms vs -13 ms, because the
    #   limiter here is stateless and has no lookahead latency to compensate for.

  @hw-verified
  Scenario: the mic gain is whatever it takes, not a number someone typed  (2026-08-27)
    Given both tracks measured at -11.4 dBFS (app) and -38.0 dBFS (mic), gated
    When the balance is planned
    Then the mic is lifted +21.0 dB — enough to land voiceLead above the DUCKED app audio
    And the app audio ducks 7 dB while the voice is present
    And nothing in the chain is tuned to this one recording
    # innards: `micGainDb(sysGatedDb:micGatedDb:)` — (app - duckDepth + voiceLead) - mic
    # @note the hand-tuned version Esa approved used +23 dB, reached by ear. The measured
    #   formula independently arrives at +21.0 dB, and the two outputs measure the same:
    #   -15.82 vs -15.58 LUFS, LRA 11.00 vs 11.10.

  @hw-verified
  Scenario: it does not distort, which is the whole constraint  (re-measured 2026-08-27)
    Given the mic is being lifted 21 dB
    When the chain runs — 75 Hz high-pass, gain, 4:1 soft-knee compressor at -14 dBFS,
      then a stateless soft ceiling at -3 dBFS before the sum
    Then the summed mix peaks at 0.7 dBFS instead of 5.2 dBFS without that ceiling
    And the delivered file's true peak is -1.24 dBTP
    And the final limiter shapes 0.128% of samples
    And the mic's crest factor survives at ~20 dB, so speech still sounds like speech
    # innards: `RebalancedMixer.next()` — compressor then `softLimit` on the mic
    # WHY the ceiling is separate from the compressor: the compressor's 10 ms attack
    #   deliberately lets transients through (that is what keeps speech alive), so a
    #   keyboard click was arriving at the sum 10 dB over full scale.

  @hw-verified
  Scenario: the measure pass and the write pass run the identical chain  (2026-08-27)
    Given normalisation needs the gain before it writes the first sample
    When rebalancing is on
    Then the loudness measured is the loudness of the REBALANCED mix, not the raw sum
    And a second RebalancedMixer, constructed identically, produces what gets written
    # innards: `flatten` — `LevelAccumulator` pass, then the writer pass
    # WHY: measuring the raw sum and writing the rebalanced mix would compute the gain
    #   against audio that is not what ships. That is the same class of lie as claiming a
    #   ceiling you do not enforce.

  @hw-verified
  Scenario: --no-rebalance is bit-exact with the old behaviour  (2026-08-27)
    Given the same recording flattened with --no-rebalance
    Then the result correlates with the previously-delivered -flat.mov at 1.00000
    # innards: `flatten(_:_:normalize:rebalance:)` — `plan == nil` takes the old path
    # WHY: a new default is only safe if the old one is still exactly reachable.

  @hw-verified
  Scenario: one audio track, or a mic that was never used, is left alone  (2026-08-27)
    Given a recording with only a system-audio track
    Then the rebalance path is not taken and flatten behaves exactly as before
    And a silent stretch measures as silence rather than producing a NaN gain
    # innards: `let doRebalance = rebalance && audioTracks.count >= 2`

  @self-test
  Scenario: the balance decision refuses the three ways it could be harmful
    Given `rec-audio --self-test`, which ../apple-rec/build.sh runs on every build
    Then a voice already louder than the app audio is never ATTENUATED
    And a dead microphone is capped at maxMicBoost, because hiss lifted 40 dB is loud hiss
    And a silent (-inf dBFS) track yields a gain of 0, not NaN
    And the post-gain voice lands exactly voiceLead dB above the ducked bed
    # innards: `selfTest()` — 20 assertions over the balance, compressor, limiter,
    #          high-pass and both followers

  @self-test
  Scenario: the ducker ducks on its attack and recovers on its release
    Then 20 ms of speech pulls the app audio down past 0.72 of full level
    And 20 ms of silence does not bring it back, so it cannot chatter between words
    # innards: `GainSmoother` — down uses `attackMs`, up uses `releaseMs`
    # HOW CAUGHT: an ordinary `Follower` gets this backwards for a gain, because for a
    #   gain "going down" is the attack.

  @note
  Scenario: what the reported ducking percentage does and does not mean
    Given the delivered recording reports "app audio under the voice 98%, 5.4 dB deep"
    Then 98% is how often the ducker was engaged AT ALL, which is nearly always when
      someone narrates continuously with sub-second pauses
    And 5.4 dB of 7 is the honest number — the mean depth over the whole recording
    # innards: `RebalancedMixer.meanDuckDb`
    # HOW CAUGHT: the first gate (12 dB below the mic's gated loudness) counted KEYBOARD
    #   noise as speech and reported 99% at full depth — a static cut wearing a ducker's
    #   clothes. Tightened to 6 dB. The percentage alone was hiding that; the mean depth
    #   is what makes it visible.
