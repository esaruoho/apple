# ============================================================================
# REPORT CARD — tap ONE app's audio straight to a .wav, no plugin, no loopback
# ============================================================================
#
# WHAT THIS CARD SPAWNS
#   Codespace : bin/app-audio-record.swift (source) + bin/app-audio-record (compiled;
#               swiftc -O, frameworks ScreenCaptureKit/AVFoundation/CoreMedia/AppKit),
#               commands/app-audio-record.md (slash pointer).
#   Thinkspace: features/app-audio-record.session.md (the spawning conversation).
#   Areaspace : OWNS = pulling a single running application's audio output off the
#               system audio engine into a LinearPCM .wav, with no video track and no
#               re-encode. MUST NOT TOUCH = video capture (that is screen-audio-record /
#               `rec`), installing any virtual audio device, rerouting the source app's
#               output device, or any AudioUnit / plugin surface.
#
# WHY THIS CARD EXISTS
#   Esa asked for "an AudioUnit plugin that is basically just 'hear to virtual output
#   port .. this audio'" so an app's sound lands as a wavefile in a folder. The AU
#   framing is a dead end: an AudioUnit is loaded INTO a host process and has no route
#   to another application's audio — the only thing that shape of solution buys you is a
#   loopback HAL driver (BlackHole/Loopback/Soundflower), which requires an install AND
#   requires the source app to be manually re-pointed at the fake device.
#   ScreenCaptureKit already ships the capability: an SCContentFilter scoped to an
#   application, with SCStreamConfiguration.capturesAudio, yields THAT application's
#   audio only, as a parallel tap — the app keeps playing to the real speakers, nothing
#   is rerouted, nothing is installed. `rec --app X` already used this for screen+audio
#   .mov; this card is the audio-only, straight-to-WAV sibling.
#
# REPORT-CARD LEGEND
#   @hw-verified  compiled AND run live on this Mac (macOS 15.6.1 / 24G90); output
#                 inspected with afinfo + sample-peak analysis.
#   @built        wired + compiles; that branch was not exercised live.
#   @note         a documented boundary, not an executable claim.
#
# RESULT
#   Direct-push to main, no PR. Files: bin/app-audio-record.swift, bin/app-audio-record
#   (binary), commands/app-audio-record.md, features/app-audio-record.feature +
#   .session.md. Live build machine: macOS 15.6.1 (24G90), 2026-07-29.
# ============================================================================

Feature: Capture one application's audio to a .wav without a loopback driver

  @hw-verified
  Scenario: all-system tap writes a real, non-silent WAV  (ran live 2026-07-29)
    Given a quiet system sound was playing (afplay -v 0.05 Submarine.aiff)
    When `app-audio-record --all --seconds 4 --out tap-test.wav` ran
    Then it self-stopped after 4s and finalised the file
    And afinfo reported "2 ch, 48000 Hz, Int16, interleaved", 4.26 s, WAVE
    And the samples were non-silent — peak 5281, RMS 1602 of 32767
    # innards: bin/app-audio-record.swift `setupWriter()` (AVAssetWriter fileType .wav,
    #          kAudioFormatLinearPCM / 48000 / 2ch / 16-bit / interleaved)
    #          + `stream(_:didOutputSampleBuffer:of:)` case .audio

  @hw-verified
  Scenario: app scoping really scopes — a silent app yields digital silence while other audio plays  (ran live 2026-07-29)
    Given the SAME afplay sound was audibly playing through the same output device
    When `app-audio-record --app Preview --seconds 4` ran (Preview makes no sound)
    Then the resulting WAV was 4 s of exact digital silence — peak 0, RMS 0
    And this is the negative control proving SCContentFilter(display:including:)
      selects that application's audio taps ONLY, not the mixed system bus
    # innards: bin/app-audio-record.swift `start(_:)` — the `if let name = opts.appName`
    #          branch building SCContentFilter(display:including:exceptingWindows:)

  @hw-verified
  Scenario: --out takes a FOLDER, not just a filename  (ran live 2026-07-29)
    Given the ask was "record a wavefile to a specific folder"
    When `app-audio-record --all --seconds 3 --out <dir>` ran with <dir> not existing
    Then the folder was created and a timestamped <stamp>-system.wav landed inside it
    And a path with a trailing "/" is treated as a folder even if it does not exist yet,
      while any other non-directory path is used verbatim as the output file
    # innards: `resolveOutPath(_:label:)` + `stamped(_:)`

  @hw-verified
  Scenario: teardown is silent, not an error  (ran live 2026-07-29)
    Given finish() calls stopCapture(), which trips SCStreamDelegate didStopWithError
    When the recorder stops on its own --seconds deadline
    Then no "stream stopped:" line is printed, because the stop was ours
    And an UNREQUESTED stop still reports and finalises what was captured
    # innards: `stream(_:didStopWithError:)` — the `guard !finished` gate

  @hw-verified
  Scenario: --list enumerates tappable applications  (ran live 2026-07-29)
    When `app-audio-record --list` ran
    Then it printed every running application with its bundle id, one per line,
      deduped by name and sorted case-insensitively (Live, Schism Tracker, Safari, …)
    # innards: `listContent(_:)`

  @built
  Scenario: no --seconds means record until Ctrl-C
    Given `app-audio-record --app Renoise --out ~/take.wav` is running
    When the user presses Ctrl-C
    Then a DispatchSource SIGINT handler calls finish(), which stops the SCStream,
      marks the input finished and finalises the WAV header before exit(0)
    # innards: `installSignalHandler()` + `finish()`
    # NOTE: the timed path (--seconds) exercises the exact same finish() and IS
    #       hw-verified; only the interactive SIGINT delivery is untested here.

  @built
  Scenario: recorder's own audio never leaks into the capture
    Given SCStreamConfiguration.excludesCurrentProcessAudio = true
    Then anything this process itself plays is excluded from the tap
    # innards: `start(_:)` cfg.excludesCurrentProcessAudio

  @built
  Scenario: a capture that never received audio fails loudly instead of writing a stub
    Given the chosen app produced no audio at all for the whole capture
    When the recorder finishes
    Then no session was ever started, so it prints "no audio was captured — was the app
      actually making sound?" to stderr and exits 2, leaving no half-written WAV
    # innards: `finish()` — the `guard self.started` branch
    # NOTE: distinct from the Preview scenario above, where SCK DID deliver silent
    #       buffers (a valid silent WAV) rather than no buffers at all.

  @note
  Boundary: there is no AudioUnit in this design, on purpose
    An AudioUnit runs inside its host's process and cannot see another app's audio.
    "Plugin that receives audio from a different app" only exists as a loopback HAL
    device, which needs an install and a manual output-device reroute in the source app.
    This tool needs neither: the source app is untouched and keeps playing normally.

  @note
  Boundary: video is configured but inert
    SCStream still wants a video configuration, so the config asks for a 2x2 frame at
    1 fps and NO .screen stream output is attached — nothing is encoded or written.

  @note
  Boundary: permission is Screen Recording, not Microphone
    ScreenCaptureKit gates app-audio capture behind Screen Recording (System Settings ▸
    Privacy & Security). No microphone is ever opened.

  @note
  Alternative not taken: CoreAudio process taps (macOS 14.4+)
    AudioHardwareCreateProcessTap + a tap-backed aggregate device is the leaner, truly
    audio-only route (no Screen Recording permission). It was not used because SCK was
    already proven in this repo by screen-audio-record and shares the app-matching code
    shape. If the Screen Recording prompt ever becomes a problem, that is the swap.
