# REPORT CARD: PDF analysis survives reply attachment size rejection
# WHAT THIS CARD SPAWNS
# Codespace: bin/freellmask-mail send_inbox_reply; test_mail_reply_attachment_fallback.py
# Thinkspace: mail-reply-attachment-fallback.session.md
# Areaspace: OWNS explicit HTTP 413 fallback; MUST NOT retry ambiguous delivery errors.
# SESSION >> features/mail-reply-attachment-fallback.session.md
# RESULT: Pending commit; direct push, no PR. Runtime recovery pending.
# WATCH: send_inbox_reply
Feature: Deliver analysis when returned original attachments exceed the mail service limit
  @built @sim-verified
  Scenario: Explicit size rejection permits a smaller reply
    # cite: bin/freellmask-mail send_inbox_reply; test_mail_reply_attachment_fallback.py
    Given an analysis reply containing the original PDF
    When AgentMail explicitly rejects it with HTTP 413
    Then retry once in the same thread without attachments
    And preserve the analysis and recipient fields
    And tell the reader the originals remain in the original email

  @built @sim-verified
  Scenario: Ambiguous errors preserve the at-most-once contract
    # cite: bin/freellmask-mail send_inbox_reply; test_mail_reply_attachment_fallback.py
    Given the reply submission raises a timeout or non-413 error
    When send_inbox_reply handles the result
    Then it does not add a fallback submission

  @runtime-untested
  Scenario: Recover the actual Milewski PDF request
    # evidence: analysis/proofs/milewski-email-proof-attachment.json
    Given cloudcity-llm received the original 5391907-byte PDF with matching SHA256
    And its initial reply was rejected with HTTP 413
    When the bounded recovery client generates and submits its analysis
    Then an actual reply message ID must be recorded before claiming delivery
