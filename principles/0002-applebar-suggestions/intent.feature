# Imported by convey from features/spotlight-suggestions.feature on 2026-06-04.
# Ungraded scenarios were defaulted to @untested (honest — not a pass).
# Bind verify/steps.py to make scenarios runnable; until then they are UNRUN.

# ============================================================================
# REPORT CARD — AppleBar Spotlight-style live suggestions
# ============================================================================
#
# WHAT THIS CARD SPAWNS
#   Codespace : shared/intents.json   (the ONE catalog — actions, examples, needsArg)
#               apple-bar/AppleBar.swift (in-process NLEmbedding ranking + ↑/↓ list)
#               bin/apple-intent      (loads the same JSON; --action force-run)
#               bin/apple-do          (a case per action; +battery/wifi/clipboard/lock)
#               shared/test-intent-routing.sh (routing guard, 17 cases)
#   Thinkspace: features/spotlight-suggestions.session.md (+ bundled transcript)
#   Areaspace : OWNS = ranking the catalog as you type + running the picked action.
#               MUST NOT TOUCH = the action implementations (apple-do owns those).
#
# WHY THIS CARD EXISTS
#   Make AppleBar feel like Spotlight: type → a ranked list of capabilities → ↑/↓ to
#   pick → ↩ runs the highlighted one. The catalog moved to ONE shared JSON so the
#   bar (live, in-process) and apple-intent (CLI routing) never diverge — DRY.
#
# REPORT-CARD LEGEND
#   @verified  passes shared/test-intent-routing.sh on a real Mac (headless)
#   @built     compiled + running, hand-verified by eye (GUI interaction)
#   @note      context, not a claim
#
# RESULT
#   Direct-push to main, no PR. Files: shared/intents.json (new),
#   apple-bar/AppleBar.swift (suggestions + NLEmbedding), bin/apple-intent (JSON
#   catalog + --action), bin/apple-do (+4 caps), shared/test-intent-routing.sh, card.
# ============================================================================

Feature: Live Spotlight-style suggestions in AppleBar
  Typing ranks the capabilities in real time; arrow keys pick; Return runs the pick.

  @built
  Scenario: Typing shows a ranked, navigable suggestion list
    Given the command bar is open
    When I type a phrase
    Then the top capabilities appear as a list (action + description), best first,
      ranked in-process by NLEmbedding over shared/intents.json — no subprocess
    And ↑/↓ move the highlight, and Return runs the highlighted capability
    # cite: AppleBar.swift rank()/renderSuggestions()/controlTextDidChange + ↑↓ monitor;
    #       loadCatalog() embeds every example once at launch

  @verified
  Scenario: The picked suggestion runs exactly that action (no re-routing)
    Given a highlighted suggestion
    When I press Return
    Then AppleBar runs `apple-intent --action <name> "<text>"`, which skips embedding
      and runs that capability directly (needsArg actions get the typed phrase)
    # cite: AppleBar.swift runQuery() action pick; bin/apple-intent forcedAction branch;
    #       test shared/test-intent-routing.sh proves phrase→action for all 17 cases

  @verified
  Scenario: One catalog, two readers (DRY)
    Given shared/intents.json
    Then bin/apple-intent loads it (loadCatalog) AND AppleBar loads it (loadCatalog),
      so adding an intent in one file updates both the CLI router and the live list
    # cite: bin/apple-intent loadCatalog(); AppleBar.swift loadCatalog(); INTENTS_JSON path

  @verified
  Scenario: More Apple capabilities recognised
    Given the expanded catalog
    When I ask about battery / wifi / clipboard / locking
    Then they route to battery / wifi / clipboard / lock respectively
    # cite: shared/intents.json (+4 intents); bin/apple-do cases; test routing guard

  @note @untested
  Scenario: "?" stays converse, not a suggestion
    Given a phrase starting with "?"
    Then no suggestions are shown and Return sends it to the fm converse path
    # cite: AppleBar.swift controlTextDidChange / runQuery "?" guards
