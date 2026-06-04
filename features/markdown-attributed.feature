# ============================================================================
# REPORT CARD — Markdown → NSAttributedString (AppleBar result pane parses markdown)
# ============================================================================
#
# THE CONVEY
#   The global rule: anything showing markdown must PARSE it — never raw ###, **, `code`,
#   --- on screen. AppleBar's result pane was dumping tool/model output as plain monospace,
#   so search hits and chat answers showed literal markdown. Convey "render this markdown"
#   by mapping it to an NSAttributedString the NSTextView can display with real styling.
#
# WHAT THIS CARD SPAWNS
#   Codespace : shared/MarkdownAttributed.swift          (the renderer — pure logic)
#               shared/markdown-attributed-tests.swift   (headless assertions)
#               shared/test-markdown-attributed.sh       (the runner — laptop, no GUI)
#               apple-bar/AppleBar.swift showResult()     (consumes it)
#               apple-bar/build.sh                        (compiles the shared unit)
#   Thinkspace: this card + the session transcript
#   Areaspace : OWNS = markdown string → attributed string for AppKit text views.
#               MUST NOT TOUCH = where the text comes from, or HTML rendering (that's
#               FoundationModelsChat/Markdown.swift, the WebView sibling — not re-rolled).
#
# WHY THIS CARD EXISTS
#   Esa, with a screenshot of raw "### Phase 4", "**Goal:**", "# Whiteboard Knob", `~/work/`,
#   --- in the AppleBar result: "does not parse markdown. this is a global rule that all
#   markdown showing things need to parse it. AppleBar also needs to show it."
#
# REUSE NOTE
#   The repo's existing Markdown.swift renders to HTML for a WebView; an NSTextView needs
#   attributed strings. Different output target → a sibling renderer, not a duplicate. The
#   concurrent "karaoke speak-back" work calls showResult() when speech ends, so it gets
#   the same markdown render for free — one renderer, two callers.
#
# REPORT-CARD LEGEND
#   @verified  passes shared/test-markdown-attributed.sh on the laptop (headless)
#   @built     wired + compiles
#   @note      context, not a claim
#
# RESULT
#   Direct-push to main. New: the three shared/ files + this card. Changed: AppleBar.swift
#   (showResult → MarkdownAttributed.render), build.sh (+the shared unit in swiftc).
# ============================================================================

Feature: AppleBar parses markdown in its result pane

  @verified
  Scenario: headings, bold, code, and rules render (not raw markers)
    Given markdown with "# H", "**bold**", "`code`", "---", and "- bullet"
    When MarkdownAttributed.render runs
    Then the output string keeps the text but drops the #, **, ` markers
    And "**Goal:**" text is bold; "`~/work/`" text is monospaced; "---" is a rule line; "-" → •
    # cite: shared/MarkdownAttributed.swift render()/inline(); shared/markdown-attributed-tests.swift
    # headless 2026-06-05: 11/11 assertions PASS (bold + monospace traits checked)

  @built
  Scenario: AppleBar shows the rendered markdown, not the raw text
    Given a tool/model result containing markdown
    When showResult(text) runs
    Then it calls MarkdownAttributed.render(text) and sets it on the result NSTextView
    # cite: apple-bar/AppleBar.swift showResult(); build.sh compiles shared/MarkdownAttributed.swift

  @note
  Scenario: the karaoke speak-back settles on the same render
    Given the concurrent karaoke feature reveals plain text word-by-word while speaking
    Then when speech ends it calls showResult(karaokeFinal) — the SAME markdown render
    # one renderer serves both the plain result path and the karaoke end-state

  @note
  Scenario: it is the attributed sibling of the HTML renderer, not a duplicate
    Given FoundationModelsChat/Markdown.swift already renders markdown → HTML (for a WebView)
    Then MarkdownAttributed renders markdown → NSAttributedString (for an NSTextView)
    And the two differ only by output target — honoring reuse-before-rerolling
