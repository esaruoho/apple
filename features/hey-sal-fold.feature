# ============================================================================
# REPORT CARD — "Hey Sal", folded INTO AppleBar (voice = a second door, one room)
# ============================================================================
#
# THE CONVEY
#   "Hey Sal" was a Vocal Shortcut that ran its OWN matcher (bin/sal-siri-match.py →
#   DC-XXX AppleScript handlers) — a parallel routing brain to AppleBar's. Convey the
#   SAME human act ("speak a request, have the Mac do it") through AppleBar's existing
#   apple-intent → apple-do pipeline instead, so voice and keyboard are two input
#   doors into ONE routing room. The Vocal Shortcut shrinks to a one-action launcher.
#
# WHAT THIS CARD SPAWNS
#   Codespace : apple-bar/AppleBar.swift   (applebar:// URL handler; listen mode;
#                                           silence auto-submit; no-speech give-up)
#               apple-bar/build.sh         (CFBundleURLTypes → claims applebar: scheme)
#               shared/Dictation.swift     (UNCHANGED — the one on-device engine, reused)
#               bin/maps-directions, bin/apple-intent, bin/apple-do (UNCHANGED — voice
#                                           lands on the exact same chain typing does)
#   Thinkspace: features/hey-sal-fold.session.md (+ this session's transcript)
#   Areaspace : OWNS = the hands-free voice WAKE + auto-run for AppleBar. MUST NOT TOUCH
#               = the routing/acting logic (that's apple-intent/apple-do's job) — the
#               fold's whole point is to NOT own a second router.
#
# WHY THIS CARD EXISTS
#   DRY question raised live: "Hey Sal → Directions" got the location-aware saddr fix
#   only if it reached bin/maps-directions. The vocal path went through sal-siri-match,
#   a separate brain that did NOT. Folding voice into AppleBar means there is exactly
#   one routing brain; every fix (me-location saddr, future intents) reaches voice and
#   keyboard at once. Esa: "fold Hey Sal, as an idea, to the Apple Bar … even better."
#
# REPORT-CARD LEGEND
#   @verified  reproduced on a real Mac (unified-log / dry-run proof cited)
#   @built     wired + compiles + launches; not yet end-to-end voice-verified
#   @note      context, not a claim
#
# RESULT
#   Direct-push to main. New: this card + session. Changed: apple-bar/AppleBar.swift,
#   apple-bar/build.sh. NOT changed (the DRY win): Dictation.swift, apple-intent,
#   apple-do, maps-directions, me-location — voice reuses all of them as-is.
#   The user re-points the "Hey Sal" Vocal Shortcut to one action: Open URL
#   applebar://listen (kept out of git — it's a Shortcuts.app object, the user's to edit).
# ============================================================================

Feature: Hey Sal folded into AppleBar — hands-free voice over the one routing pipeline

  @verified
  Scenario: applebar://listen and applebar://open route to AppleBar's handler
    Given AppleBar registers a kAEGetURL handler for the applebar: scheme (Info.plist claims it)
    When `open applebar://listen` (or applebar://open) fires
    Then AppleBar's handleGetURL runs with the right host
    # cite: AppleBar.swift registerURLScheme()/handleGetURL; build.sh CFBundleURLTypes
    # hand-verified 2026-06-04 via unified log:
    #   "AppleBar: handleGetURL 'applebar://open' host='open'"
    #   "AppleBar: handleGetURL 'applebar://listen' host='listen'"

  @built
  Scenario: listen mode wakes the bar and starts the shared on-device dictation
    Given applebar://listen
    When handleGetURL sees host == "listen"
    Then it shows the panel, sets listenMode, and starts OnDeviceDictation (the SAME
      engine the 🎙 button uses — no re-roll)
    And the placeholder reads "Listening (Hey Sal)… speak, then pause — or ↩"
    # cite: AppleBar.swift showPanelAndListen(); shared/Dictation.swift authorizeThenStart()
    # hand-verified 2026-06-04: log shows tccd + TextInputUI XPC engaging (recognizer + perm)

  @built
  Scenario: speaking auto-runs through apple-intent after a silence gap (hands-free)
    Given listenMode is on and partial transcriptions are filling the field
    When ~1.6s passes with no new words (you stopped talking)
    Then the silence timer fires runQuery → runIntent → apple-intent → apple-do
    And so "directions home" spoken == "directions home" typed (identical chain,
      including me-location saddr); ↩ still submits immediately as an override
    # cite: AppleBar.swift bumpSilenceTimer()/silenceSeconds; runQuery()/runIntent()
    # NOT yet voice-verified end-to-end (needs a real spoken utterance) — graded @built

  @built
  Scenario: no speech at all → release the mic (no energy hog)
    Given listenMode started but nothing was said
    When listenGiveUpSeconds (9s) elapse with the field still empty
    Then dictation.stop() releases the mic
    And ESC also aborts a listen cleanly (stops the mic, hides the panel)
    # cite: AppleBar.swift showPanelAndListen() give-up timer; cancelOperation handler
    # honors the global "no runaway mic / energy hog" rule

  @verified
  Scenario: the fold adds NO second router — voice reuses the existing chain
    Given bin/apple-intent routes "directions"/"how do i get home"/"navigate home" → apple-do directions
    Then AppleBar's voice path calls that same apple-intent, not sal-siri-match
    And no maps:// URL is built anywhere but bin/maps-directions (single source of truth)
    # cite: apple-intent --dry-run (match: directions 1.00 → "would run: apple-do directions")
    # cite: grep "maps://" → only bin/maps-directions

  @note
  Scenario: the Vocal Shortcut becomes a thin launcher (the user's one edit)
    Given the existing "Hey Sal" Vocal Shortcut ran sal-siri-match's DC-XXX handlers
    Then it is re-pointed to a single action: Open URLs → applebar://listen
    And sal-siri-match remains available but is no longer the directions/voice brain
    # the Shortcut is a Shortcuts.app object, not in git; the user edits it (no UI-hijack)
