# REPORT CARD: Agent-readable cloud inputs and all three email cloud types
# SESSION >> features/cloud-source-markdown.session.md
# WATCH: shared/cloud_source.py shared/cloud_assets.py scripts/cloud-source-sidecars.py generate replay write_spec
# WHAT THIS CARD SPAWNS
# Codespace: shared/cloud_source.py, shared/cloud_assets.py, bin/cloud-assets;
#            surgical patches to existing Convey/archive renderers and wrappers.
# Thinkspace: cloud-source-markdown.session.md and its private transcript bundle.
# Areaspace: exact cloud rendering inputs, existing extractive key-takeaways,
#            email/cloud artifact return; no laptop rendering or OCR.
# RESULT: Mini installed and running payload ee890110f2619f17; code hashes matched.
#         Evidence: analysis/proofs/cloud-sources/verification.json (44 tests).
#         All three Markdown-only replays have identical pixels; email transport simulated.
#         Feature/card commit and direct-push delivery recorded in git history.

Feature: Cloud images carry readable reproducible source documents

  @code-verified @runtime-verified
  Scenario: Every newly rendered cloud saves its exact inputs before the image
    Given weighted words, sentences or extractive key ideas
    When the existing renderer creates a PNG
    Then it first saves a readable source.md with every supplied text item and weight
    And the Markdown contains a checksummed JSON rendering specification
    And wrappers and folder commands retain that source after deleting temporary files
    # cite: shared/cloud_source.py write_cloud_source write_spec read_spec
    # cite: scripts/cloud-source-sidecars.py word sentence wrapper cli

  @code-verified @sim-verified
  Scenario: Emailed PDFs return all three cloud types with their source files
    Given a PDF has readable prose and completed analyses
    When its Mini mail job prepares delivery
    Then wordcloud, sentencecloud and ideacloud PNGs and Markdown sources are archived and attached
    And idea selection reuses Convey's existing extractive key-takeaways
    And a missing cloud is reported explicitly
    # cite: shared/cloud_assets.py generate
    # cite: shared/aimeat_mail.py advance

  @code-verified @runtime-verified
  Scenario: An agent can recreate an image from Markdown without OCR
    Given a saved cloud rendering source
    When cloud-assets render reads its checksummed specification on the Mini
    Then it renders the stored items with the matching renderer
    And modified machine inputs fail checksum verification
    # cite: shared/cloud_assets.py replay
    # cite: shared/cloud_source.py read_spec

  @code-verified @sim-verified
  Scenario: Email is sent as formatted HTML with a plain-text fallback
    Given analysis Markdown contains headings, bold, code, lists, links and tables
    When the threaded email payload is composed
    Then the HTML body contains the corresponding formatting tags
    And the plain-text body remains available
    And source Markdown is attached separately for agents
    # cite: bin/freellmask-mail md_to_html md_to_inner_html
    # cite: shared/aimeat_mail.py advance

  @stock @sim-verified
  Scenario: New source sidecars do not become new corpus material automatically
    Given a corpus folder contains prior cloud source Markdown
    When a cloud generator scans the corpus again
    Then generated source.md files are excluded
    And render commands reject the laptop
    # cite: scripts/cloud-source-sidecars.py word sentence cli
    # cite: shared/cloud_assets.py mini
