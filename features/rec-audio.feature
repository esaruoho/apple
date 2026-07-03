# ============================================================================
# REPORT CARD — rec-audio: post-process a recording's audio for editing
# ============================================================================
#
# WHAT THIS CARD SPAWNS
#   Codespace : bin/rec-audio.swift (+ compiled bin/rec-audio; swiftc -target macos13.0,
#               frameworks AVFoundation/CoreMedia), commands/rec-audio.md (/rec-audio slash).
#               Mirrored to esaruoho/apple-rec.
#   Thinkspace : features/rec-pipeline-report.md (the session that spawned the whole rec arc).
#   Areaspace : OWNS = splitting a recording's audio tracks to separate files, and mixing
#               them into one. MUST NOT TOUCH = the recording itself (that's screen-audio-record)
#               and video re-encoding (flatten passes the video THROUGH untouched).
#
# WHY THIS CARD EXISTS
#   A `rec` recording is ONE .mov with video + system audio (+ a mic track if used). iMovie
#   merges embedded audio tracks into one soundtrack (can't edit them apart), and YouTube plays
#   only the FIRST audio track. rec-audio bridges both: `split` gives iMovie independent tracks;
#   `flatten` gives a single mixed track that plays both everywhere.
#
# REPORT-CARD LEGEND  @hw-verified = ran live, output probed · @built = compiles, path not run.
#
# RESULT  Direct-push to main. bin/rec-audio(.swift), commands/rec-audio.md. Commits: 3335cc1
#   (split/flatten), 0f03398 (Ventura backward-compat). Mirrored: apple-rec 9ecd7e3/4f3ce4e.
#   Built -target macos13.0 → runs on Ventura/Sonoma/Sequoia+.
# ============================================================================

Feature: Post-process a screen recording's audio (split / flatten)

  @hw-verified
  Scenario: split writes each audio track to its own .m4a  (ran live)
    Given a recording with two audio tracks (system first, mic second)
    When `rec-audio split <in.mov>` runs
    Then it exports <stem>-system.m4a and <stem>-mic.m4a via AVAssetExportSession(AppleM4A),
      one AVMutableComposition per track
    And a single-audio-track recording yields just <stem>-system.m4a with a note
    # cite: rec-audio.swift split() + exportOneTrack(); verified: two AAC m4a, correct durations

  @hw-verified
  Scenario: flatten mixes all audio into one track, video passthrough  (ran live)
    Given a recording with system + mic tracks
    When `rec-audio flatten <in.mov> [-o out]` runs
    Then AVAssetReaderAudioMixOutput SUMS the audio tracks (each at 0.8 to avoid clipping) and
      the video is copied via a passthrough AVAssetReaderTrackOutput/AVAssetWriterInput (no re-encode)
    And the result is <stem>-flat.mov with exactly one video + one mixed AAC audio track
    # cite: flatten(); verified: probe showed 1 video (avc1) + 1 audio (aac)

  @hw-verified
  Scenario: version-safe export runs on Ventura+ with no deprecation warnings  (ran live)
    Given AVAssetExportSession.exportAsynchronously is deprecated in macOS 15
    When exportOneTrack runs
    Then #available(macOS 15) uses the modern export(to:as:), else the deprecated path (13–14)
    And built -target macos13.0 → minos 13 (runs on Ventura/Sonoma/Sequoia+), no warnings
    # cite: exportOneTrack() #available branch; verified: minos 13.0, clean compile
    # NOTE macOS floor = 13 (async loadTracks/load); the recorder's floor is higher (mic=15).

  @hw-verified
  Scenario: rec --mic auto-runs flatten to make a YouTube-ready file  (ran live)
    Given `rec --mic` (auto-flatten) records with a mic track
    When it stops
    Then screen-audio-record shells to the co-located rec-audio flatten → <name>-flat.mov
    # cite: screen-audio-record.swift makeYouTubeVersion(); verified: both files produced
