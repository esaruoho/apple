# ============================================================================
# REPORT CARD — rec-subtitle: Whisper .srt + Apple-native subtitle burn-in
# ============================================================================
#
# WHAT THIS CARD SPAWNS
#   Codespace : bin/rec-subtitle.swift (+ compiled bin/rec-subtitle; swiftc -target macos13.0,
#               frameworks AVFoundation/CoreMedia/QuartzCore/AppKit), commands/rec-subtitle.md.
#   Thinkspace : features/rec-pipeline-report.md.
#   Areaspace : OWNS = turning a recording's speech into .srt (via whisp/Whisper) and painting
#               those subtitles into the video. MUST NOT TOUCH = the transcription engine
#               itself (delegates to ~/work/whisp/whisp or the Mini) and audio mixing (rec-audio).
#
# WHY THIS CARD EXISTS
#   Step 3 of the screencast pipeline: captions. YouTube can take an .srt sidecar; other places
#   need the subtitles burned into the picture. Transcription is heavy, so it routes to the
#   always-on Mac Mini by default (keeps Whisper off the laptop).
#
# REPORT-CARD LEGEND  @hw-verified = ran live, frame/output inspected · @built = compiles, the
#   round-trip/path was not exercised live (honestly graded).
#
# RESULT  Direct-push to main. bin/rec-subtitle(.swift), commands/rec-subtitle.md. Commits:
#   4725ebc (srt + burn-in), 1705700 (--mini Mini routing + one-command --burn chain).
#   apple-only (depends on the private whisp CLI); NOT mirrored to apple-rec.
# ============================================================================

Feature: Subtitle a screen recording (.srt sidecar + burn-in)

  @hw-verified
  Scenario: transcribe → .srt sidecar via whisp (Whisper)  (ran live)
    Given a recording (or a --mic voice-only .m4a)
    When `rec-subtitle <video>` runs
    Then it shells to ~/work/whisp/whisp (--out <dir>) and normalizes the result to <stem>.srt
    # cite: rec-subtitle.swift transcribe() + main; verified: whisp(tiny) produced a real .srt

  @hw-verified
  Scenario: --burn hard-paints the subtitles into the video  (ran live)
    Given an .srt (given, existing sidecar, or freshly transcribed)
    When `rec-subtitle <video> --burn` runs
    Then it builds AVMutableVideoComposition + AVVideoCompositionCoreAnimationTool, one CALayer
      per cue, each with a DISCRETE opacity keyframe over the full timeline (0 → 1 during
      [start,end] → 0), and exports <stem>-subtitled.mov
    And each subtitle is RASTERIZED to a CGImage (white text, black outline, bottom-center) —
      CATextLayer does NOT draw in the offline CA render (verified), so a plain CALayer + image is used
    And an empty transcript skips the burn gracefully (keeps the .srt)
    # cite: burn() + renderTextImage(); verified: frame at t=3s shows the subtitle right-side-up,
    # t=0.4s (pre-cue) is clean → timing gate works; flip fixed via flipped:false render

  @hw-verified
  Scenario: version-safe burn export (Ventura+)  (ran live)
    Then #available(macOS 15) uses export(to:as:), else the deprecated path; built -target macos13.0
    # cite: burn() export branch

  @built
  Scenario: --mini routes transcription to the Mac Mini (keeps CPU off this mac)
    Given --mini
    When transcription is needed
    Then it submits the audio via ~/work/whisp-transcripts/whisp-submit (Syncthing whisp-inbox →
      Mini whisp-worker) and polls ~/work/whisp-transcripts/transcripts + whisp-results for the
      returned .srt (30-min timeout), then continues to burn
    # cite: transcribeOnMini() + findSRT(); @built — the round-trip needs the live Mini worker;
    # poll locations/naming are best-effort. Fallback: --burn-local transcribes here.

  @built
  Scenario: one-command pipeline — rec --mic --pip --burn
    Given the recorder's --burn flag
    When recording stops (after auto-flatten)
    Then screen-audio-record shells to the co-located rec-subtitle --burn (+ --mini unless
      --burn-local) and reveals the -subtitled.mov
    # cite: screen-audio-record.swift makeSubtitledVersion(); @built — mirrors the @hw-verified
    # makeYouTubeVersion chain; the end-to-end record→transcribe→burn was verified via rec-subtitle
    # directly (whisp tiny), not through the recorder's --burn spawn.

  @built
  Scenario: transcription shows progress and elapsed time
    Given transcribe() is about to run Whisper
    Then it prints "transcribing <file> of M:SS audio — whisper model=…, lang=…" (the total media
      length, via mediaSeconds(), so Whisper's streamed [mm:ss] segment timestamps read as
      progress toward a known end), passes --verbose True so every decoded line streams live, and
      on completion prints "✓ transcribed N subtitle lines in M:SS" (wall-clock since launch)
    # cite: transcribe() — mediaSeconds() + clock() + t0/Date() + --verbose True; @built (logic
    # verified at compile; the streamed segments are Whisper's own stdout, inherited by the child)

  @built
  Scenario: burn-in reports its export time
    Given burn() is about to export
    Then it prints "burning N subtitles into <file> (M:SS video)…" then on success
      "✓ <out>  ·  burned in M:SS" (wall-clock of the export)
    # cite: burn() — clock(CMTimeGetSeconds(dur)) + t0/Date()

  @hw-verified
  Scenario: subtitle glyphs keep their counters open (no more muddy a/e)  (ran live)
    Given a subtitle line containing a, e, o, g, 8
    When renderTextImage rasterizes it
    Then it draws the black glyphs at 16 points around a circle of radius ≈4.5% of the glyph
      size, then the white glyphs on top — an OUTSIDE-only outline. The centered
      `.strokeWidth: -4.0` stroke (which grew inward and closed the counters into mud) is gone.
    And a frame extracted from a re-burned video shows "Good evening…" with every a/e/o/g/d/b
      counter open and crisp
    # cite: subtitleAttr() + renderTextImage() offset-composite; @hw-verified via ffmpeg frame
    #       grab + the hidden `rec-subtitle --render-sample "…" out.png` dev tool
