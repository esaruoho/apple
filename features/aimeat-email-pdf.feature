# REPORT CARD: email PDFs into AIMEAT, with complete page/section accounting
# SESSION >> features/aimeat-email-pdf.session.md
# WATCH: shared/aimeat_mail.py roundtable/install_mail.py test_aimeat_source.py bin/mail-pdf-text.swift scripts/wordcloud-dark.py eligible process_pending extract_pdf bounded_source_step require_complete_analysis analysis_html stage_handler install_handler
# WHAT THIS CARD SPAWNS
# Codespace: shared/aimeat_mail.py, bin/mail-pdf-text{,.swift}, roundtable/install_mail.py,
#            bin/freellmask-mail poll integration, roundtable/bridge.py collector.
# Thinkspace: aimeat-email-pdf.session.md and bundled source transcript.
# Areaspace: owner-email PDFs and explicit PDF URLs, durable source/analysis return,
#            existing Mini mail pane and existing roundtable; no laptop inference.
# RESULT: apple c86de4bf, fda339dd, 5a8af07e (PDF intake, transport, tests, integration).
#         convey b7862fb27 (black wordcloud canvas), delivered by cd02ac15d.
#         Direct-push to main, no PR; newer Convey remote work preserved by merge.
#         Card-authoring commit: c86de4bf; delivery bookkeeping follows in git.
#         Mini activation/hash match verified for final payload dfc71c558e8a859b.
#         Evidence: analysis/proofs/aimeat-email-pdf-verification.json (39 tests).
#         Email transport is simulated in tests; no live test email sent.
# Tests: test_aimeat_mail.py plus existing mail/editor/roundtable behavioral suites.

Feature: Owner emails deliver complete PDF material and analyses to AIMEAT

  @built @sim-verified
  Scenario: Owner PDF intake is durable and does not answer twice
    Given an owner emails a PDF attachment or explicit PDF URL
    When the Mini mail pane polls the inbox
    Then it queues a message-ID keyed job before the legacy reply claim
    And an ambiguous send is retained as unconfirmed without automatic resending
    # cite: shared/aimeat_mail.py eligible enqueue process_pending advance
    # cite: bin/freellmask-mail poll_once

  @built @sim-verified @runtime-verified
  Scenario: Every PDF page and every text section is considered
    Given a PDF longer than twenty pages or fourteen text sections
    When the Mini extracts and reads the PDF
    Then every page has an embedded-text or OCR record
    And all text sections receive checkpointed readings without a part-count cutoff
    And pages with no recognized text are listed explicitly
    # cite: bin/mail-pdf-text.swift
    # cite: shared/aimeat_mail.py extract_pdf chunks advance

  @built @sim-verified
  Scenario: The laptop receives the original and actual returned results
    Given completed section analyses and a matching completed roundtable
    When Syncthing returns the exported artifacts
    Then the filing-only collector verifies hashes and files them in merlib-dump/aimeat
    And local edits are preserved
    And the Mini can run its roundtable directly from the job workspace while the laptop is asleep
    And the email reply carries the analysis and names its analysis types
    And all three cloud images carry readable source Markdown and rendering JSON
    # cite: shared/aimeat_mail.py publish collect advance
    # cite: roundtable/bridge.py collect
    # cite: shared/aimeat_mail.py merge_mail_inputs
    # cite: shared/cloud_assets.py generate

  @code-verified @sim-verified
  Scenario: Substack analysis mail is sent only after every requested analysis is complete
    Given a Substack source job has saved reading checkpoints
    When source synthesis times out, the roundtable fails, or any cloud artifact is missing
    Then the failure and checkpoints remain in the job state without sending an email
    And the handler sends only after nonempty analysis, matching completed roundtables,
        and all three cloud PNGs and Markdown rendering sources pass verification
    And source-analysis steps have a one-hour default deadline on the Mini
    And targeted Mini deployment replaces only the handler and preserves a backup
    # cite: shared/aimeat_mail.py bounded_source_step require_complete_analysis advance _process_pending
    # cite: shared/aimeat_mail.py analysis_html ; roundtable/install_mail.py stage_handler install_handler
    # cite: test_aimeat_source.py

  @built @runtime-verified
  Scenario: Wordclouds use a black canvas and readable title
    Given an installed Convey or archive wordcloud generator
    When the dark-theme patch is applied and a cloud is rendered
    Then its cloud and surrounding figure have a black background
    And its title is white
    # cite: scripts/wordcloud-dark.py dark apply

  @stock @sim-verified
  Scenario: Compute stays on CloudcityMacMini
    Given the laptop receives files through Syncthing
    When it runs the existing collector
    Then it copies artifacts without running OCR or a model
    And processing entry points reject the laptop
    # cite: shared/aimeat_mail.py mini collect process_pending
