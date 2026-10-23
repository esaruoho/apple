# REPORT CARD: email PDFs into AIMEAT, with complete page/section accounting
# SESSION >> features/aimeat-email-pdf.session.md
# WATCH: shared/aimeat_mail.py shared/free_energy_analysis.py bin/mail-free-energy-analysis bin/freellmask-mail roundtable/install_mail.py test_aimeat_source.py bin/mail-pdf-text.swift eligible text_attachments is_text_source process_pending extract_pdf bounded_source_step require_complete_analysis advance _fm_call usable_read usable_reduction usable_synthesis
# WHAT THIS CARD SPAWNS
# Codespace: shared/aimeat_mail.py, bin/mail-pdf-text{,.swift}, roundtable/install_mail.py,
#            bin/freellmask-mail poll integration, roundtable/bridge.py collector.
# Thinkspace: aimeat-email-pdf.session.md and bundled source transcript.
# Areaspace: owner-email PDFs and explicit PDF URLs, durable source/analysis return,
#            existing Mini mail pane and existing roundtable; no laptop inference.
# RESULT: apple c86de4bf, fda339dd, 5a8af07e (PDF intake, transport, tests, integration).
#         apple 481d5c27 (completion-gated Substack delivery, checkpoint-safe failures).
#         convey b7862fb27 (black wordcloud canvas), delivered by cd02ac15d.
#         Direct-push to main, no PR; newer Convey remote work preserved by merge.
#         Card-authoring commit: c86de4bf; delivery bookkeeping follows in git.
#         Mini activation/hash match verified for final payload dfc71c558e8a859b.
#         Evidence: analysis/proofs/aimeat-email-pdf-verification.json (39 tests).
#         Email transport is simulated in tests; no live test email sent.
#         b22d0635: shared Free Energy prompt, owner text attachments, unified subject/output.
#         Runtime-untested; no analysis email sent in this change.
#         b2f179a7: local KeelyNet text intake reuses enqueue_text, not a batch sender.
#         f925ff96: reasoning-leak gate + accurate source naming; runtime-untested.
#         34a3f3d9: exclude KeelyNet distribution boilerplate from analysis output.
#         ef2d41d8: deterministic output scrub before rendering; runtime-untested.
#         621d0f85: require clean source section structure; use existing gateway model chain.
#         135cf4ef: retain gateway fallback for section reads after slow pinned call.
# Tests: test_aimeat_mail.py plus existing mail/editor/roundtable behavioral suites.

Feature: Owner emails deliver complete PDF and text material and analyses to AIMEAT

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


  @built @runtime-untested
  Scenario: Local archival text can be queued into the same AIMEAT source pipeline
    Given a KeelyNet Markdown source already resides on Cloudcity
    When enqueue_text receives its complete text and keelynet:// source reference
    Then it creates the same checkpointed source job used for Substack text
    And it sends the completed package with the source title as the subject
    # cite: shared/aimeat_mail.py enqueue_text send_source_email advance

  @built @runtime-untested
  Scenario: Owner text attachments use the same durable AIMEAT analysis path
    Given an owner emails a UTF-8 text, Markdown, CSV or JSON attachment
    When the Cloudcity mail pane polls the inbox
    Then it queues the source before the legacy reply claim
    And it preserves and analyzes the complete attachment without truncation
    And Free Energy synthesis uses the shared MAIN_SYS and LENS_SYS from mail-free-energy-analysis
    And the existing Sages, source-coverage, artifact-validation and shared-renderer stages run
    And generated artifact checks compare the same human-readable filenames used in the dossier manifest
    And private reasoning leaks are rejected before they enter the dossier
    And source reads must begin with the canonical report headings
    And source reads use the existing FreeLLMAPI fallback chain
    And unusable model output advances through that chain before the job retries on a later poll
    And the source filename is preserved in analysis references
    And the send gate removes archival distribution boilerplate even if a model repeats it
    And an incomplete analysis is not emailed
    # cite: shared/aimeat_mail.py text_attachments eligible enqueue advance require_complete_analysis display_asset_name
    # cite: shared/free_energy_analysis.py MAIN_SYS LENS_SYS
    # cite: bin/mail-free-energy-analysis main
    # cite: bin/freellmask-mail poll_once

  @built @runtime-untested
  Scenario: Free Energy source email uses the Phase Conjugation dossier structure
    Given a KeelyNet article is queued through the shared text pipeline
    When FreeLLMAPI, Qwen MLX, Flubuild, the titled Sages panel, and comparative synthesis finish
    Then the single shared Phase-based dossier builder assembles all seven sections
    And the existing format_email.py remains the only rich-text and math renderer
    And the original archive file remains unchanged while its email attachment omits BBS boilerplate
    And known word-processor, sponsor, address, distribution, and split contact banners are stripped from every outgoing text attachment
    And delivery is withheld if any known KeelyNet boilerplate remains in the dossier or a text attachment
    And no email is sent unless every model output, titled Sage, source digest, and artifact passes validation
    And queued Free Energy articles are processed end-to-end in arrival order to avoid batch round-robin delay
    And the Sages worker accepts queued mail sources only after their mail state reaches the roundtable stage
    And those mail sources are returned to the Sages worker in enqueue order
    And archive copies of any queued mail source are excluded until that mail source is eligible
    # cite: shared/aimeat_email_template.py build_dossier clean_source contains_keelynet_boilerplate titled_roundtable validate_dossier
    # cite: shared/aimeat_mail.py enqueue_text require_complete_analysis advance merge_mail_inputs sys.executable
    # cite: bin/fm-converse call_flubuild ; bin/flubuild-request.py prepare
    # cite: shared/format_email.py email_payload

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
