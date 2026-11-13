# WHAT THIS CARD SPAWNS:
# codespace: bin/messages-counts; exported/imessage-counts (private output)
# thinkspace: messages-counts.session.md
# areaspace: read local Messages and contact identity metadata; never message bodies or source writes.
# SESSION: messages-counts.session.md
# RESULT: Feature and card delivered in 34bb404b, direct push to main, no PR.
# Files: bin/messages-counts; skill.md; wiki/concepts/messages-automation.md;
#        messages-counts.feature; messages-counts.session.md; generated indexes.
# WATCH: connect_readonly load_contacts count_messages write_reports
# RESULT-LOG >>
#   2026-11-13  direct-commit  touched: connect_readonly load_contacts count_messages write_reports
Feature: Local message counts per contact
  @built @runtime-verified
  Scenario: Count both sides of direct conversations
    # cite: bin/messages-counts count_messages
    Given local Messages history and Contacts identity metadata
    When the counter reads the databases with read-only connections
    Then direct conversations include sent and received distinct message IDs
    And groups are reported separately
    And reactions and system events are separated from ordinary messages

  @built @runtime-verified
  Scenario: Keep private data local
    # cite: bin/messages-counts connect_readonly write_reports
    Given the default gitignored exported directory
    When reports are generated
    Then message bodies and attachment data are never selected
    And no network request or source database write is performed
