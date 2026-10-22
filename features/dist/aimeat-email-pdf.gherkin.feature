# Pure Gherkin test extracted from features/aimeat-email-pdf.feature
# (report-card banner stripped; inline # cite: traceability kept)
# Regenerate: python3 print-card.py features/aimeat-email-pdf.feature

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
    And the email reply carries the analysis and names its analysis types
    # cite: shared/aimeat_mail.py publish collect advance
    # cite: roundtable/bridge.py collect

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
