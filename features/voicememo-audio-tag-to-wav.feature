# FEATURE CARD — Voice Memo #audio → .wav sample
#
# WHAT THIS CARD SPAWNS
#   Codespace : topbar/AppleToolbox.swift  (VoiceMemoPipeline class)
#   Thinkspace: features/voicememo-audio-tag-to-wav.session.md
#   Areaspace : owns the #audio tag → WAV export path ONLY. Must NOT touch the
#               #process → whisp transcription path (shares only the SQL poll).
#
# RESULT
#   Feature commit(s): see `git log -- topbar/AppleToolbox.swift` (2026-06-09)
#   PR: direct-push, no PR.
#   Files changed: topbar/AppleToolbox.swift (VoiceMemoPipeline: +#audio branch,
#     exportAudio/ffmpeg/timestamp/audio-state helpers, broadened SQL).
#   Build: topbar/build.sh → /Applications/AppleToolbox/Apple-Workflows/AppleToolbox.app
#   INNARDS BACK-LINK: AppleToolbox.swift VoiceMemoPipeline.exportAudio()

Feature: A Voice Memo tagged #audio becomes a .wav sample on disk
  The live submitter is the Swift VoiceMemoPipeline inside AppleToolbox (the
  menu-bar app with Full Disk Access). It already routes #process memos to whisp
  for transcription. #audio is a SECOND, independent output: the recording's
  audio, transcoded to a WAV sample under ~/Music/samples/VoiceMemos/, named by
  the recording's own timestamp + a slug of its title.

  Background:
    Given AppleToolbox is running with Full Disk Access
    And it polls CloudRecordings.db every 30 s
    And ffmpeg is installed at /opt/homebrew/bin/ffmpeg

  @hw-verified
  Scenario: a downloaded memo tagged #audio is exported to WAV
    Given a Voice Memo whose title contains "#audio"
    And its audio is downloaded locally (ZLOCALDURATION > 0, ZPATH set)
    When the pipeline polls and sees it for the first time
    Then ffmpeg transcodes the .m4a to 16-bit PCM WAV
    And the file lands at ~/Music/samples/VoiceMemos/<yyyy-MM-dd-HH-mm-ss>-<slug>.wav
    And the timestamp is the recording's OWN date in local time
    And all #hashtags are stripped from <slug>
    And the uniqueid is recorded in voicememo-audio-exports.json (no re-export)
    # ffmpeg cmd + naming + samples-dir writability verified 2026-06-09 via the
    # exact `pcm_s16le` command on a real memo → RIFF WAVE 16-bit 44100 Hz.

  @built @untested-on-real-tag
  Scenario: the export fires automatically once a deferred memo downloads
    Given a #audio memo that is iCloud-only (ZLOCALDURATION 0.0, empty ZPATH)
    When the pipeline polls
    Then exportAudio returns false (defer) and writes nothing
    And no error is logged
    When the audio later downloads from iCloud
    Then the next 30 s poll exports the WAV
    # The two real memos "Vuosaaren kartano #audio" (2026-06-04) are in exactly
    # this deferred state until their iCloud audio is pulled (see Task 4).

  @built
  Scenario: #audio and #process on the same memo both fire
    Given a memo tagged BOTH "#process" and "#audio"
    When the pipeline polls
    Then it is submitted to whisp (transcription) AND exported to WAV
    And the two paths dedup independently (submissions vs audioExports)

  @built
  Scenario: idempotent + atomic
    Given the target WAV already exists on disk
    Then exportAudio records it and does no ffmpeg work
    And in-progress transcodes write to <out>.partial.wav then move into place
