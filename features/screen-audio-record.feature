# ============================================================================
# REPORT CARD — screen + system-audio recording without a loopback driver
# ============================================================================
#
# WHAT THIS CARD SPAWNS
#   Codespace : bin/screen-audio-record.swift (source) + bin/screen-audio-record
#               (compiled binary; swiftc -O, frameworks ScreenCaptureKit/AVFoundation/
#               CoreMedia/CoreGraphics/AppKit), bin/rec (one-word launcher wrapper),
#               commands/screen-audio-record.md + commands/rec.md (slash pointers),
#               topbar/AppleToolbox.swift (🧰 ▸ "Record Screen & Audio" toggle:
#               recordScreenAudioToggle + recDefaultOutPath + screenRecProc state).
#   Thinkspace: features/screen-audio-record.session.md (the spawning conversation).
#   Areaspace : OWNS = capturing a display's video AND audio-off-the-system-engine into
#               one .mov via ScreenCaptureKit, with the audio scoped either to a single
#               app (SCContentFilter including that app) or to the whole display, plus
#               optional native mic as a 2nd track. MUST NOT TOUCH = installing any
#               virtual audio device, driving the ⌘⇧5 GUI, or muxing via ffmpeg — the
#               whole point is zero third-party, Apple-framework-only.
#
# WHY THIS CARD EXISTS
#   Esa: record the screen AND an audio app's OUTPUT at once, and "the answer is not
#   'let it play via speaker and go into microphone', that's junk". QuickTime / ⌘⇧5
#   only offer a MICROPHONE picker — Apple omits system audio from the built-in
#   recorder ON PURPOSE, forcing a fake-mic loopback (BlackHole/Loopback). The
#   capability DOES ship in the OS: ScreenCaptureKit's SCStreamConfiguration.capturesAudio
#   pulls audio straight off the system audio engine, and an app-scoped SCContentFilter
#   captures ONLY that app's sound. This tool surfaces it as a terminal command.
#
# REPORT-CARD LEGEND
#   @hw-verified  compiled AND run live on this Mac (macOS 15.6.1); output inspected.
#   @built        wired + compiles; the specific branch was not exercised live.
#   @note         a documented boundary, not an executable claim.
#
# RESULT
#   Two direct-pushes to main, no PR.
#   Ship 1 (commit 412fccd): bin/screen-audio-record.swift + binary,
#     commands/screen-audio-record.md, features/screen-audio-record.feature + .session.md.
#   Ship 2 (this commit): default ~/Videos/<timestamp>.mov naming when --out omitted,
#     bin/rec launcher, commands/rec.md, AppleToolbox "Record Screen & Audio" toggle.
#   Live build machine: macOS 15.6.1 (24G90), display 1512x982 @2x.
# ============================================================================

Feature: Record screen + system audio to one .mov with no loopback driver

  @hw-verified
  Scenario: single-app audio isolation captures screen + only that app's sound  (ran live)
    Given Renoise was running and audible on this Mac
    When `screen-audio-record --app Renoise --out <path>` ran for ~6s then got Ctrl-C (SIGINT)
    Then it built an SCContentFilter(display:including:[Renoise], exceptingWindows:[])
    And SCStreamConfiguration.capturesAudio=true with excludesCurrentProcessAudio=true
    And it muxed via AVAssetWriter(.mov) into ONE file with TWO tracks
    And AVFoundation probe confirmed: duration 5.48s, video codec avc1 (H.264) 3024x1964,
      audio codec 'aac ' — no microphone, no BlackHole, no virtual cable
    # cite: bin/screen-audio-record.swift start()/setupWriter()/stream(_:didOutputSampleBuffer:of:)

  @hw-verified
  Scenario: Ctrl-C stops cleanly and finalizes a playable file  (ran live)
    Given a recording in progress
    When SIGINT arrives
    Then a DispatchSource signal handler (SIGINT set to SIG_IGN first) calls finish() once
    And finish() calls stream.stopCapture, marks every writer input finished, then
      writer.finishWriting and prints "✓ saved <path>" only on .completed
    And a re-entrant guard (finishing flag) makes a second Ctrl-C a no-op
    # cite: installSignalHandler() + finish()

  @hw-verified
  Scenario: --list enumerates displays and audible apps  (ran live)
    Given screen-recording permission is granted to the launching terminal
    When `screen-audio-record --list` runs
    Then it prints each display with index + WxH + displayID
    And each running application once (deduped) with its bundle id, for use as --app <name>
    # cite: listContent(); ran live — 1 display + ~35 apps incl. Renoise (com.renoise.renoise)

  @built
  Scenario: whole-display capture with all system audio
    Given no single app is named
    When `screen-audio-record --system-audio --out <path>` runs
    Then the filter is SCContentFilter(display:excludingWindows:[]) — full display, all audio
    And omitting BOTH --app and --system-audio is a hard error (must choose a scope)
    # cite: start() filter branch — @built: compiles + logic verified, this branch not run live

  @built
  Scenario: optional microphone as a second audio track
    Given --also-mic is passed
    When recording starts
    Then SCStreamConfiguration.captureMicrophone=true (native macOS 15+ mic capture, no
      AVCaptureSession) and a SECOND AVAssetWriterInput(.audio) receives .microphone buffers
    And QuickTime plays the system-audio track by default; the mic is a selectable 2nd track
    # cite: setupWriter(mic:) + stream() .microphone case — @built: not exercised live

  @hw-verified
  Scenario: --out omitted defaults to ~/Videos/<timestamp>.mov  (ran live)
    Given no --out is passed
    When recording starts
    Then Recorder.defaultOutPath() creates ~/Videos (if missing) and names the file
      yyyy-MM-dd-HH-mm-ss.mov
    And a live `rec` run wrote ~/Videos/2026-07-02-01-07-46.mov — probe confirmed
      3.10s, video avc1 3024x1964, audio 'aac '
    # cite: Recorder.defaultOutPath() + start()

  @hw-verified
  Scenario: rec is the one-word terminal launcher  (ran live)
    Given `bin/rec` on PATH
    When `rec` runs with no args
    Then it exec's `screen-audio-record --system-audio "$@"` → whole screen + all system
      audio → ~/Videos/<timestamp>.mov, Ctrl-C stops
    And `rec --app <name>` passes through and single-app audio wins over --system-audio
      (start() checks appName first)
    # cite: bin/rec; ran live — wrote+finalized a .mov under ~/Videos

  @built
  Scenario: AppleToolbox 🧰 ▸ Record Screen & Audio is a start/stop toggle
    Given the menu-bar app is running
    When the row is clicked and screenRecProc is nil
    Then it spawns `screen-audio-record --system-audio --out ~/Videos/<timestamp>.mov`,
      retains the Process in screenRecProc, notifies "Recording…", and the row relabels
      to "⏹ Stop Recording (→ ~/Videos)"
    When clicked again
    Then it sends SIGINT via Process.interrupt() so the recorder finalizes the .mov,
      clears screenRecProc, and notifies "Recording saved <name>"
    # cite: recordScreenAudioToggle() + recDefaultOutPath() + menu row in rebuildMenu()
    # @built: compiled + deployed live (build.sh, menu-bar relaunched); the same binary
    # + --system-audio --out path is @hw-verified via rec, but the click itself and the
    # interrupt()-from-AppleToolbox path were not GUI-driven in this build session.

  @note
  Scenario: Sequoia re-prompts screen-recording permission
    Given macOS 15 asks weekly / after reboot for screen recording + screenshots
    Then any ScreenCaptureKit tool inherits that prompt; the code cannot suppress it —
      approve the launching terminal (iTerm) once when the OS asks
