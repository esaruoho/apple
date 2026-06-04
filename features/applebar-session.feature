# ============================================================================
# REPORT CARD — AppleBar session (2026-06-01 → 2026-06-04)
# What we built: the non-Tahoe, on-device command bar for the Apple toolbox.
# ============================================================================
#
# THE ARC
#   Started from FoundationModelsChat (Mini-only, macOS 26). Ended with AppleBar:
#   a Spotlight-style command bar that runs on the LAPTOP — no FoundationModels to
#   DECIDE, on-device NLEmbedding to route, the Mini's 3B LLM only when you ask it to.
#
# WHAT THIS CARD SPAWNS
#   Codespace : bin/apple-intent (NLEmbedding router), apple-bar/AppleBar.swift
#               (command bar), shared/intents.json (catalog), shared/Dictation.swift
#               (dictation engine), bin/apple-do (+ me-address, maps-directions,
#               desktop-icons, dock-autohide), FoundationModelsChat/Markdown.swift
#   Thinkspace : this session (fde596bb…), bundled at features/dictation-button.transcript.*
#   Areaspace  : OWNS the laptop-side toolbox front door. The Mini owns the LLM.
#
# LEGEND  @shipped = committed + running   @verified = headless test passes
#         @built = runs, hand-verified   @leak-fixed = incident closed
# ============================================================================

Feature: AppleBar — what the session accomplished

  @shipped @verified
  Scenario: Headless Markdown renderer test (stop screenshotting render bugs)
    Then FoundationModelsChat/Markdown.swift extracted from the AppKit app; 16-case
      headless test (test-markdown.sh) gates build.sh. Catches ordered-list/MathML bugs.
    # rule: memory feedback-test-renderers-headlessly; wiki headless-renderer-testing.md

  @shipped
  Scenario: FoundationModelsChat exports the conversation
    Then .md + .pdf buttons (+ ⌘E/⇧⌘E) save into the session folder; PDF paginated via
      offscreen-window print (fixed a freeze), opens in Preview; .md reveals in Finder.

  @shipped @verified
  Scenario: apple-intent — the embedding intent router (non-Tahoe twin of fm)
    Then NLEmbedding routes a phrase → an apple-do action, on the laptop, no LLM.
      27 capabilities. Bare words match their own action. 34-case routing guard passes.

  @shipped
  Scenario: AppleBar — the Spotlight-style command bar
    Then ⌥Space/⌃Space opens it; live ranked suggestions (in-process NLEmbedding, ↑/↓);
      Return runs the pick; 🎙 dictation; whitelabel report templates + ⌘↩ LLM rephrase;
      "?"/"chat"/"converse" → the Mini's on-device LLM; every run logs a Gherkin rule.

  @shipped
  Scenario: One shared catalog + one shared dictation engine (DRY)
    Then shared/intents.json feeds BOTH the CLI router and the live bar; AppleBar
      consumes shared/Dictation.swift (extracted from AppleToolbox) instead of a 3rd copy.
    # rule: memory feedback-reuse-before-rerolling

  @shipped @built
  Scenario: Capabilities wired (the "Conveys")
    Then home / address (Contacts me-card, cached, no re-prompt) / directions (Maps via
      maps:// scheme, reused from ray-graph) / now / battery / wifi / clipboard / lock /
      desktop (hide icons) / dock (auto-hide) / dark / sleep / disk / mute / screenshot /
      eject / caffeinate / report / mini / uptime / keywords / entities / sentiment /
      fleet / spotlight / search / ocr.

  @verified
  Scenario: Each unit carries its own report card (the discipline)
    Then features/: dictation-button, me-address, directions-home, spotlight-suggestions,
      shell-toggles, + this one — each with graded Gherkin + a session leg; executable
      tests for the testable parts (test-markdown.sh, test-dictation.sh, test-intent-routing.sh).

  @leak-fixed
  Scenario: Incidents closed
    Then revived the Mini's hung fm-worker (heartbeat was 2.5h stale); killed a 2-day
      zombie wait-loop (unbounded `until [ -f xc-status2.out.txt ]; do sleep 3; done`).
    # lesson: never launch an unbounded wait-loop — bound it or await the harness signal.
