# ============================================================================
# REPORT CARD — tap ONE app's audio straight to a .wav, no plugin, no loopback
# ============================================================================
#
# WHAT THIS CARD SPAWNS
#   Codespace : bin/app-audio-record.swift (source) + bin/app-audio-record (compiled;
#               swiftc -O, frameworks ScreenCaptureKit/AVFoundation/CoreMedia/CoreAudio/
#               AppKit), bin/wav (curses picker, python3 stdlib — same shape as
#               bin/sessions), commands/app-audio-record.md + commands/wav.md (slashes).
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
#   Direct-pushes to main, no PR. Live build machine: macOS 15.6.1 (24G90), 2026-07-29.
#   Ship 1 (71ce6fa): the recorder — app-scoped SCK tap → LinearPCM .wav.
#   Ship 2 (5d784e9): --out accepts a folder; silence self-inflicted teardown error.
#   Ship 3: the ANSWER TO "select by cursor up/down and press enter" — CoreAudio
#     process objects (--list-audio: who is actually outputting audio) + bin/wav, the
#     arrow-key picker; plus live dBFS metering, the SILENT/effectively-silent verdicts,
#     --front, --after, and matched-app echo. Also fixes the --out folder rule.
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
  Scenario: --out is a FILE only if it ends in .wav, otherwise a FOLDER  (ran live 2026-07-29)
    Given the ask was "record a wavefile to a specific folder"
    When `--out <dir>` names a folder that does NOT exist yet
    Then the folder is created and <stamp>-<App>.wav lands inside it
    When `--out <dir>/deeper/take.wav` names a .wav in a missing folder
    Then the parent folders are created and the file is written at exactly that path
    # innards: `resolveOutPath(_:label:)` + `stamped(_:)`
    # BUG THIS FIXES: the first rule was "folder only if it already exists or ends in /",
    # which silently turned `--out ~/Music/grabs` on its FIRST run into an extension-less
    # FILE named `grabs`. Found by the picker's end-to-end test, not by reasoning.

  @hw-verified
  Scenario: an app that holds an open stream but renders nothing is called out  (ran live 2026-07-29)
    Given Ableton Live was "playing" per CoreAudio (output stream open) but rendering ~nothing
    When a 2s tap of Live finished
    Then it exited 0 with the file kept, but printed
      "⚠️  effectively silent — peak is -100.6 dBFS, far below audible"
    And this is distinct from the all-zero case, which is an exit-3 failure
    # innards: `finish()` — the `db < -60` branch
    # WHY: -100 dBFS reported as a clean ✓ is a success message that disappoints later.

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

  @hw-verified
  Scenario: the picker lists apps and marks who is ACTUALLY making sound  (ran live 2026-07-29)
    Given CoreAudio's audio-process object list (macOS 14.4+) knows which processes
      are currently running output — something SCShareableContent cannot tell you
    When `app-audio-record --list-audio` ran
    Then it emitted JSON per process with pid / bundleID / name / playing / isApp
    And with Ableton Live and Schism Tracker both open it reported exactly
      playing: ["Live", "Schism Tracker"]
    And `wav` filtered 38 audio clients down to 7 rows — real apps plus anything
      currently playing — so audiomxd / assistantd / avconferenced never appear
    # innards: bin/app-audio-record.swift `audioProcesses()` + `printAudioProcessesJSON()`,
    #          bin/wav `audio_procs()`
    # NOTE: the filter is NSRunningApplication.activationPolicy == .regular, NOT a
    #       blacklist of daemon names — a blacklist leaked audiomxd on the first try.

  @hw-verified
  Scenario: it survives a terminal that can't hide the cursor  (ran live 2026-07-29)
    Given Esa's terminal reports TERM=ansi, whose terminfo has no civis capability
    And Python 3.14 raises curses.error on curs_set() returning ERR (older Pythons did not)
    When `wav` starts there
    Then it draws normally instead of dying with a traceback
    And TERM=ansi / dumb / xterm-256color were all exercised through a pty: no crash in any
    # innards: bin/wav `picker()` — try/except around curs_set + start_color, plus
    #          safe_add() wrapping every write (last-cell writes raise too)
    # NOTE: bin/sessions had ALREADY solved this exact thing at line 520, comment and all.
    #       I wrote fresh curses instead of reusing its hardening. Reuse-before-re-rolling
    #       is a standing rule here and I broke it; the fix is that pattern, copied.

  @hw-verified
  Scenario: arrow keys + Enter produce a .wav  (ran live 2026-07-29, driven through a pty)
    Given `wav --seconds 3 --out ./pickdrop` running in a pseudo-terminal
    When ↓ then ↑ then Enter were written to the pty
    Then the curses picker exited, the recorder ran with --app com.ableton.live,
      the live dBFS meter redrew ~10x/sec, and a finished .wav was reported
    # innards: bin/wav `picker()` + `main()`
    # NOTE: this test is what caught the --out folder bug above; the UI was fine.
    # Re-run under TERM=ansi after the curs_set fix: ↓ ↑ ⏎ → tapped Live, wrote
    # ansidrop/2026-07-29-14-21-21-Live.wav. keypad(True) makes arrows work on ansi too.

  @hw-verified
  Scenario: Enter raises the picked app before the tap opens  (logic ran headlessly 2026-07-29)
    Given you picked an app because you intend to play something in it
    When Enter is pressed
    Then `/usr/bin/open -b <bundleID>` runs FIRST, then the recorder starts 0.5s later
    And `--no-activate` skips the raise entirely
    And with no --seconds it first prints "recording until Ctrl-C (click back to this
      terminal to stop)", because raising the app takes focus off the terminal
    # innards: bin/wav `main()` — the `if activate and not choice.get("all")` block
    # HOW TESTED: subprocess/curses stubbed, asserting call ORDER and argv — the repo's
    #   test-renderers-headlessly rule. A live run would have yanked focus off Esa
    #   mid-session, so the actual window-raise is his one-keypress check, not mine.
    # NOTE: this is user-requested activation via `open`, NOT System Events keystrokes —
    #   nothing is typed into whatever was frontmost (see never-UI-hijack rule).

  @hw-verified
  Scenario: the meter line is also the clock  (ran live 2026-07-29, pty)
    Given "stopping after 16.0s" printed once tells you nothing while you wait
    When a 16s capture runs
    Then the meter line carries a live countdown: 16.0s left, 15.9s left, 15.8s left …
    And 30 redraws were observed over 2.5s (~12/sec)
    And with no --seconds it counts UP as elapsed m:ss instead
    # innards: `drawMeter()` (clock section) + `startMeterClock()`
    # NOTE: driven by a 0.1s timer AND the audio callbacks, so the clock keeps ticking
    #       even if buffers stall — a frozen countdown would be its own kind of lie.

  @hw-verified
  Scenario: stop the capture with a keypress, not just Ctrl-C  (ran live 2026-07-29, pty)
    Given a capture is running in a terminal
    When Enter, Esc, q or Ctrl-C is pressed
    Then the recorder finalises the .wav and reports it — all four verified through a pty
    And Enter at 3s into a 16s capture produced a finished 484096-byte file at -5.2 dBFS
    # innards: `installKeyWatcher()` + `restoreTerminal()`
    # HOW: ICANON+ECHO cleared so single keys arrive unechoed; ISIG deliberately LEFT ON
    #      so Ctrl-C still raises SIGINT exactly as before.
    # NOTE: `stty -g` before vs after a run is BYTE-IDENTICAL — the terminal is never
    #       left in raw mode, including via atexit if we die unexpectedly.

  @hw-verified
  Scenario: "first, then" — record Renoise TO Ableton Live as one gesture  (2026-07-29)
    Given a recording is rarely the end of the thought
    When you press Enter on the source app
    Then a second screen asks where the finished .wav should go: Nothing / Finder /
      any running app, defaulting to the first app that is NOT the source
    And `--then "Ableton"` / `--then finder` / `--then none` skip that screen entirely
    And Esc on the second screen goes BACK to the source list rather than quitting
    # innards: bin/wav `choose_then()` inside `picker()`, `resolve_then()`, `run_then()`

  @hw-verified
  Scenario: the path is handed over as DATA, not scraped from prose  (ran live 2026-07-29)
    Given the "then" step needs to know which file was just written
    When --manifest <path> is passed
    Then the recorder writes {schema, path, bytes, peak_dbfs, silent, app} JSON there
    And it writes it on BOTH outcomes — a silent grab produced
      {"peak_dbfs": -999, "silent": true} exactly as designed
    And wav deletes the manifest after reading it (verified: no wav-*.json left in TMPDIR)
    # innards: `writeManifest(bytes:silent:)`; consumed in bin/wav `main()`
    # WHY: same doctrine as screen-audio-record's RECBURN-MANIFEST — nobody greps the
    #      human "✓ …" line, whose wording will change.

  @hw-verified
  Scenario: a silent grab is never handed onward  (ran live 2026-07-29)
    Given opening 20s of silence in Live is worse than opening nothing, because it
      looks like it worked
    When the manifest reports silent: true
    Then the then-step is skipped with "→ not sending to Finder: the grab was silent"
    And with silent: false the same path DOES fire the handoff
    # innards: bin/wav `main()` — the `if info.get("silent")` guard

  @hw-verified
  Scenario: destinations resolve by bundle id or by name, and refusals are admitted  (2026-07-29)
    Given "ableton" matches a RUNNING app       → open -b com.ableton.live <file>
    And   "Renoise" matches nothing running     → open -a Renoise <file>   (by NAME)
    And   "com.foo.bar" is dotted               → open -b com.foo.bar <file>
    And   "finder"                              → open -R <file>
    And   "none"                                → no subprocess at all
    When the target app REFUSES the open (non-zero exit)
    Then it says "<app> would not open it (<reason>); revealing in Finder instead"
      rather than printing a success line
    # innards: `resolve_then()` + `run_then()`
    # NOTE: some DAWs only accept dragged files, so the refusal path is not theoretical.

  @note
  Boundary: "playing" means an open output stream, not audible sound
    kAudioProcessPropertyIsRunningOutput is true for an app holding an output stream
    even when it renders silence — hence the separate peak-based verdicts after capture.
