# WIKI PAGE / REPORT CARD: Transcript analyses automatically come home
# WHAT THIS CARD SPAWNS:
#   codespace — shared/email_analysis.py, bin/freellmask-mail;
#               convey/cli.py, transcript_intake.py, transcript_vault.py, actions/video
#   thinkspace — transcript-vault-email-analysis.session.md
#   areaspace — OWNS: exact response persistence, text-only return and vault links
#               MUST NOT TOUCH: source media, personal notes, deep-analysis grades
# SESSION: transcript-vault-email-analysis.session.md
# RESULT: implementation and automated checks complete; deployment pending; no feature commit yet.
# WATCH: prepare delivered compose_and_send cmd_email_transcript make_email_analysis collect _build
# RESULT-LOG >>

Feature: A conveyed video yields a readable transcript and its analyses

  @code-verified @runtime-untested
  Scenario: Save the exact response before attempting mail delivery
    # cite: shared/email_analysis.py prepare delivered; bin/freellmask-mail compose_and_send
    Given Cloudcity has composed an answer over a transcript
    When the mail agent sends that answer
    Then its exact Markdown body is already saved beside the canonical transcript
    And a separate receipt records pending, sent, or failed delivery and actual model attribution

  @code-verified @runtime-untested
  Scenario: Analyses arrive after the transcript through Syncthing
    # cite: convey/transcript_intake.py collect; convey/transcript_vault.py _build
    Given the transcript has already been collected into the archive
    When its email response and speaker-analysis sidecars arrive
    Then the next automatic collection places linked analysis children beneath its vault note
    And later refreshes keep those generated children
    And source revisions are distinguished from the analyzed source hash

  @code-verified @runtime-untested
  Scenario: Normal video completion includes saved analysis
    # cite: convey/actions/video make_email_analysis; convey/cli.py cmd_email_transcript
    Given convey video runs through the existing Cloudcity video worker
    When its transcript is ready
    Then the default analysis station records its response against the flat transcript
    And named-speaker material remains in the input to the analysis
    And a matching sent receipt prevents duplicate composition and email on retry
    And analysis failure is reported instead of a successful plain done-notice

  @stock
  Scenario: Machine output does not close the deep-analysis backlog
    # cite: convey/transcript_intake.py collect; convey/ledger.py analysis_legs
    Given a transcript has machine analyses but no deep-analysis sidecar
    When the archive and vault refresh
    Then the item remains pending deep analysis
    And personal notes and source media are preserved
