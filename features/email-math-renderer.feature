# REPORT CARD: One Markdown, rich-text and math renderer for research email
# SESSION >> features/email-math-renderer.session.md
# WATCH: shared/format_email.py shared/email_renderer_install.py test_email_renderer.py
# WHAT THIS CARD SPAWNS
# Codespace: shared/format_email.py plus import-only mail callers and archive shim.
# Thinkspace: email-math-renderer.session.md.
# Areaspace: email presentation and lossless sources; no inference or delivery policy changes.
# RESULT: implementation and card in this commit; direct-push, no PR.
# Evidence: analysis/proofs/email-math-renderer.json; corrected dossier HTML beside it.
# Live deployment: receipt recorded separately when verified; no corrected email resent.
Feature: Research emails share one renderer and retain equation source
  @built @sim-verified
  Scenario: Slash and dollar delimited multiline equations survive Markdown
    Given inline and display TeX in the phase conjugation dossier
    When shared/format_email.py renders the email
    Then all 37 expressions render with zero unsupported-expression fallbacks
    And test_email_renderer.py verifies scripts, fractions, escaping and code exclusion
  @built @sim-verified
  Scenario: Unsupported syntax never silently loses mathematical content
    Given an unsupported or malformed TeX expression
    When the canonical renderer processes it
    Then the complete original expression remains visibly labelled
    And email_payload attaches exact Markdown and extracted TeX source
  @built @sim-verified
  Scenario: All five mail paths delegate rendering
    Given the migrated mail callers and archive compatibility shim
    When email_renderer_install.py applies its migration twice
    Then rendering remains owned by shared/format_email.py
    And unrelated delivery policy stays unchanged
