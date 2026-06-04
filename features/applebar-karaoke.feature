# ============================================================================
# REPORT CARD — AppleBar karaoke: chat answers reveal in sync with the voice
# ============================================================================
#
# THE CONVEY
#   A chat answer in AppleBar appeared only AFTER speech ended (and earlier, not at
#   all). Two root causes: the CLI spoke via a detached `say` that INHERITED AppleBar's
#   stdout pipe, so readDataToEndOfFile() blocked until speech finished; and even fixed,
#   "show it all, then talk" isn't what was wanted. Convey the same act ("hear the
#   answer") as KARAOKE: AppleBar drives speech itself and reveals the text word-by-word
#   in time with the voice. Esa: "what i was hoping was 'karaoke' so while it is being
#   said, the text appears."
#
# WHAT THIS CARD SPAWNS
#   Codespace : apple-bar/AppleBar.swift  (synth + AVSpeechSynthesizerDelegate;
#                                          speakKaraoke/renderKaraoke/zoeAVVoice/
#                                          plainForSpeech; runQuery routes chat → karaoke;
#                                          runIntent sets FM_CHAT_SPEAK=0)
#               bin/apple-intent          (speakDetached given OWN null stdio — the
#                                          pipe-inheritance fix, for direct CLI callers)
#   Thinkspace: this card + the spawning session
#   Areaspace : OWNS = how a chat/ask answer is SPOKEN + revealed inside AppleBar.
#               MUST NOT TOUCH = the routing/answer logic (apple-intent/fm-submit), the
#               suggestion ranker, or the dictation engine.
#
# REPORT-CARD LEGEND
#   @verified  reproduced on a real Mac (proof cited)
#   @built     compiles + launches; not yet eyeball-verified live on screen
#   @note      context, not a claim
#
# RESULT
#   Direct-push to main. New: this card. Changed: apple-bar/AppleBar.swift (karaoke),
#   bin/apple-intent (null-stdio on speakDetached). AppleBar rebuilt (build.sh) and
#   relaunched. apple-intent unchanged for routing — only its detached-say stdio.
# ============================================================================

Feature: AppleBar karaoke — the chat answer is revealed in sync with the spoken voice

  @verified
  Scenario: AppleBar compiles and launches with the synth wired
    Given AppleBar.swift conforms to AVSpeechSynthesizerDelegate and owns an AVSpeechSynthesizer
    When ./apple-bar/build.sh runs
    Then it builds AppleBar.app and the app relaunches
    # cite: AppleBar.swift synth/applicationDidFinishLaunching (synth.delegate = self)
    # verified 2026-06-05: "Built: …/AppleBar.app"; relaunched

  @built
  Scenario: a chat answer is shown whole, then brightens word-by-word as spoken
    Given "chat what is chess" returns an answer
    When AppleBar speaks it via AVSpeechSynthesizer (Zoe)
    Then the full answer is shown immediately (dim), readable at once, stable size
    And willSpeakRange brightens each word as it is spoken, current word highlighted
    And when speech ends the body settles into the markdown render
    # cite: AppleBar.swift speakKaraoke/renderKaraoke; willSpeakRange/didFinish delegate
    # NOT yet eyeball-verified on screen this session — graded @built

  @built
  Scenario: the result appears WITHOUT waiting for speech (the original bug, fixed)
    Given a chat query
    When apple-intent returns the answer text
    Then AppleBar shows + starts speaking it immediately (no block until speech ends)
    And apple-intent is invoked with FM_CHAT_SPEAK=0 so the CLI does not ALSO speak
    And bin/apple-intent's detached `say` now uses its OWN null stdio (so any pipe-
      capturing caller no longer blocks on readDataToEndOfFile until speech finishes)
    # cite: AppleBar.swift runIntent (FM_CHAT_SPEAK=0); bin/apple-intent speakDetached()

  @built
  Scenario: speech stops when the bar is dismissed or reopened
    Given karaoke is speaking
    When ESC closes the panel, or ⌥Space opens a fresh one
    Then synth.stopSpeaking(.immediate) silences it (no talking over a dismissed panel)
    # cite: AppleBar.swift cancelOperation handler; showPanel()

  @note
  Scenario: voice + markdown handling
    Given the answer may contain markdown markers
    Then plainForSpeech strips them so the spoken/displayed karaoke string is clean prose
      and AVSpeech ranges line up; the FINAL render re-adds formatting via showResult
    And Zoe (Premium) is chosen when the OS exposes voice quality (macOS 13+), else any
      Zoe, else the system default; CONVEY_VOICE overrides
    # cite: AppleBar.swift plainForSpeech(); zoeAVVoice()
