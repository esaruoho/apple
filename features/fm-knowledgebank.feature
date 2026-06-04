# ============================================================================
# REPORT CARD — chat answers are banked to a FoundationModels Knowledgebank
# ============================================================================
#
# THE CONVEY
#   AppleBar already answers "chat <q>" / "converse <q>" / "? <q>" by routing through
#   bin/apple-intent → fm-submit → FoundationModels on the Mini, and SHOWS the answer.
#   But the answer vanished when the panel closed. Convey the same act ("ask the
#   on-device model a thing") so its OUTPUT persists: every real answer is appended to
#   a durable, browsable knowledgebank — what the model has told you, kept for recall.
#
# WHAT THIS CARD SPAWNS
#   Codespace : bin/apple-intent  (converse block: save on success; saveToKnowledgebank())
#   Thinkspace: this card + the spawning session (Esa: "the result being saved to
#               foundationmodels knowledgebank")
#   Areaspace : OWNS = persisting chat/ask answers. MUST NOT TOUCH = the routing/answer
#               logic (apple-intent/fm-submit own that), nor AppleBar.swift (it shells
#               out to the interpreted apple-intent script live — no recompile needed).
#
# WHY THIS CARD EXISTS
#   "chat hello hello tell me about chess" worked end-to-end already — the gap was only
#   that the answer was not saved. One chokepoint (the converse block) covers AppleBar,
#   direct `apple-intent "chat …"`, and any future caller at once.
#
# REPORT-CARD LEGEND
#   @verified  reproduced on a real Mac (live run + file proof cited)
#   @built     wired + parses; not yet end-to-end proven
#   @note      context, not a claim
#
# RESULT
#   Direct-push to main. New: this card. Changed: bin/apple-intent (converse block +
#   saveToKnowledgebank). NOT changed (the DRY win): AppleBar.swift, fm-submit — the
#   answer chain is reused as-is; only its output is now banked.
# ============================================================================

Feature: chat/ask answers are banked to a FoundationModels Knowledgebank

  @verified
  Scenario: a chat answer from the on-device model is appended to the bank
    Given the fm-worker on the Mini is alive
    When `apple-intent "chat hello hello tell me about chess"` runs (what AppleBar sends)
    Then the answer prints AND is appended to the FoundationModels Knowledgebank
    And the entry carries a timestamp, the mode (chat), the question, and the answer
    # cite: bin/apple-intent converse block; saveToKnowledgebank()
    # hand-verified 2026-06-04: ~/.config/apple-bar/foundationmodels-knowledgebank.md
    #   gained "## 2026-06-04 23:59:32 · chat / **Q:** hello hello tell me about chess / …"

  @verified
  Scenario: the bank is append-only with a one-time header
    Given the bank file may or may not exist yet
    When the first answer is banked
    Then a "# FoundationModels Knowledgebank" header is written once
    And every later answer is appended after it (seekToEndOfFile), never overwriting
    # cite: bin/apple-intent saveToKnowledgebank() (header-if-absent + append)

  @built
  Scenario: only real answers are banked
    Given a converse run returns a non-zero code or an empty answer
    When the converse block finishes
    Then nothing is written to the bank (no empty/failed entries)
    # cite: bin/apple-intent  `if r.code == 0 && !said.isEmpty`

  @note
  Scenario: the bank location is conventional and overridable
    Given no override is set
    Then the bank lives beside learned.feature at
      ~/.config/apple-bar/foundationmodels-knowledgebank.md
    And FM_KNOWLEDGEBANK overrides the path (for tests / alternate stores)
    # cite: bin/apple-intent saveToKnowledgebank() path resolution
