# ============================================================================
# REPORT CARD — Dictation button (on-device speech-to-text)
# ============================================================================
#
# WHAT THIS CARD SPAWNS
#   Codespace : shared/Dictation.swift  (OnDeviceDictation — the one engine)
#               apple-bar/AppleBar.swift (wireDictation + 🎙 button — a consumer)
#               topbar/AppleToolbox.swift (SpeechDictationController — fat consumer)
#               shared/dictation-tests.swift + shared/test-dictation.sh (the runner)
#   Thinkspace: features/dictation-button.session.md (+ bundled transcript)
#   Areaspace : OWNS = mic capture + SFSpeechRecognizer + emitting transcription
#               strings. MUST NOT TOUCH = where the text goes (each app decides via
#               callbacks), FoundationModels, the network, any Whisper path.
#
# WHY THIS CARD EXISTS
#   Dictation was implemented THREE times: AppleToolbox (the original, full-featured),
#   a half-copy in AppleBar, and very nearly a fourth. This card extracts ONE shared
#   engine, makes the mic-free behaviour an executable test, and records the unit so an
#   LLM can recreate the button from the card alone — no re-invention.
#
# REPORT-CARD LEGEND (grade tags in use)
#   @verified  passes shared/test-dictation.sh on a real Mac (headless, no mic)
#   @built     compiled + wired into a running app, but not auto-tested
#   @untested  needs a live mic + TCC grant — verifiable by a human, not headlessly
#   @todo      not done yet
#   @note      context, not a claim
#
# RESULT
#   Engine + DRY extraction + card: direct-push to main, no PR.
#   Files: shared/Dictation.swift (new), shared/dictation-tests.swift (new),
#          shared/test-dictation.sh (new), apple-bar/AppleBar.swift (consumes engine),
#          apple-bar/build.sh (compiles shared engine), this card + session.
#   Lineage: 369d9b0 first added the 🎙 button (inline, the DRY violation) →
#            this commit extracts OnDeviceDictation and rewires AppleBar onto it.
# ============================================================================

Feature: On-device dictation button
  As a toolbox user, I can speak a request instead of typing it.
  The mic + recogniser logic lives once, in OnDeviceDictation; each app wires its
  three callbacks (onText / onStateChange / onError) to its own UI.

  @verified
  Scenario: A fresh engine is idle
    Given a new OnDeviceDictation
    Then isRunning is false
    # cite: shared/Dictation.swift OnDeviceDictation.isRunning (~28); test dictation-tests.swift

  @verified
  Scenario: On-device recognition is preferred (audio stays local)
    Given a new OnDeviceDictation
    Then prefersOnDevice is true
    And start() sets requiresOnDeviceRecognition when the OS+hardware support it
    # cite: shared/Dictation.swift start() (~70, macOS 13 guard); test dictation-tests.swift

  @built
  Scenario: AppleBar's button is the real dictation glyph, not a cartoon emoji
    Given the command bar's dictate affordance
    Then it renders the SF Symbol "mic.fill" (template-tinted), going red while listening —
      the system dictation look, not the "🎙" emoji
    And the command field's text is vertically centred (VCenteredCell), not sitting "upper"
    # cite: apple-bar/AppleBar.swift micIcon(active:) + VCenteredCell.drawingRect(forBounds:)
    # hand-verified 2026-06-04 (screenshot): SF-Symbol mic at the field's right, centred text

  @verified
  Scenario: Stopping an idle engine is a safe no-op
    Given an engine that was never started
    When stop() is called (even twice)
    Then it does not crash, isRunning stays false, and onStateChange does not fire
    # cite: shared/Dictation.swift stop() (~110, removeTap/endAudio tolerate empty state)

  @built @untested
  Scenario: Tapping the mic authorises, listens, and streams text into the field
    Given the AppleBar command bar is open
    When I click the 🎙 button
    Then it prompts once for Speech Recognition + Microphone, the button turns to ⏹,
      and my words appear live in the field as I speak
    # cite: shared/Dictation.swift authorizeThenStart()/start() (~38..100);
    #       apple-bar/AppleBar.swift wireDictation() onText/onStateChange (~216)
    # untested: needs a live mic + TCC grant — human checklist, not headless

  @built @untested
  Scenario: Return stops the mic, then runs what was heard
    Given the mic is listening
    When I press Return (or ⏹)
    Then dictation stops and the heard text is run as the query
    # cite: apple-bar/AppleBar.swift runQuery() "if dictation.isRunning { dictation.stop() }" (~158)

  @built @untested
  Scenario: A final result arriving after stop is dropped (no duplicate text)
    Given the recogniser has a pending final-result callback
    When stop() has already flipped isRunning false
    Then the late callback is ignored and the phrase is not emitted twice
    # cite: shared/Dictation.swift recognitionTask closure "guard self.isRunning" (~95)
    # ported from the AppleToolbox original, which documented this exact bug

  @built
  Scenario: AppleBar consumes the shared engine, not its own copy (DRY)
    Given apple-bar/AppleBar.swift
    Then it holds one OnDeviceDictation and contains no SFSpeechRecognizer code itself
    And apple-bar/build.sh compiles shared/Dictation.swift alongside it
    # cite: apple-bar/AppleBar.swift "let dictation = OnDeviceDictation()" (~39);
    #       apple-bar/build.sh swiftc "$HERE/../shared/Dictation.swift"

  @todo
  Scenario: AppleToolbox's SpeechDictationController sits on top of the shared engine
    Given topbar/AppleToolbox.swift SpeechDictationController (~8170)
    Then its mic + recogniser core is OnDeviceDictation, with its cursor-aware
      tentative-range rendering and audio-file capture layered on the onText callback
    # todo: not yet refactored — the controller is large + battle-tested; adopt next.
    #       cite: topbar/AppleToolbox.swift SpeechDictationController (8170..8536)

  @note
  Scenario: Converse is a separate path, not a consumer
    Given ~/work/converse/main.swift
    Then its dictation is Whisper (AVAudioEngine → whisper worker), a different engine
    And it is intentionally OUT of scope for OnDeviceDictation (SFSpeechRecognizer)
    # cite: converse/main.swift AVAudioEngine (~2688) — Whisper, not Speech framework
