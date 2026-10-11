# REPORT CARD: One material editor contract including all five voices
# WHAT THIS CARD SPAWNS
# Codespace: bin/freellmask-mail research_email_material; recovery client; test_mail_material_editor.py
# Thinkspace: mail-material-editor-contract.session.md
# Areaspace: OWNS document editor selection and section validation; preserve routing for other topics.
# SESSION >> features/mail-material-editor-contract.session.md
# RESULT: Feature/card 37422650; direct push to main, no PR.
# Runtime: corrected reply 010001a12b3e9ef6-a3d1ca8d-1229-4f76-af5b-a0f2ae6fcf4a-000000 received in Gmail.
# Evidence: analysis/proofs/milewski-corrected-receipt.json; milewski-corrected-analysis.md.
# Deployment: isolated snapshot verified; existing long-running worker remains unchanged.
# WATCH: research_email_material
Feature: Free Energy documents retain the complete editorial format across entry points
  @built @sim-verified
  Scenario: Free Energy material invokes the same full editor
    # cite: bin/freellmask-mail research_email_material, poll_once, compose_and_send
    Given a document routed to free-energy
    When inbound mail, compose or recovery asks for its analysis
    Then pass the Free Energy viewpoint and material mode to the existing editor
    And require Russell, Bearden, Prigogine, Hilarion and the skeptical engineer
    And require summary, key points, quotes, entities, what holds up, verification table and assessment

  @built @sim-verified
  Scenario: Missing sections cannot pass as successful analysis
    # cite: test_mail_material_editor.py test_each_missing_voice_blocks_delivery
    Given any required voice or material heading is absent
    When the shared document editor checks its output
    Then return a requeue sentinel instead of a sendable answer

  @built @sim-verified
  Scenario: Other topics retain their routed viewpoint
    # cite: test_mail_material_editor.py test_plain_documents_keep_their_own_space
    Given a document routed to apple
    When the document editor is called
    Then do not inject the Free Energy viewpoint

  @runtime-verified
  Scenario: Correct the incomplete Milewski email
    Given the earlier delivery proof omitted the required editorial voices
    When the corrected recovery runs on Cloudcity
    Then record a new reply with every required section and verify its Gmail receipt
