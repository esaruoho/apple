# =============================================================================
# REPORT CARD: mailfe-convey-belt — file/paste/image/PDF → extracted packet →
#                                      free-energy analysis → rich email
# Skin: CLI front door + reusable Convey belt stages
# SESSION >> features/mailfe-convey-belt.session.md
#
# WHY THIS CARD EXISTS
#   Esa asked for the thing behind `mailfe` to be expressed as Gherkin concepts
#   for Convey: "modularize each of the input output segment of this so that
#   anything else can benefit from this too. this would be the true convey belt."
#
# CONVEY MEANING
#   `mailfe` is not the important noun. The reusable noun is a belt:
#
#     intake → text extraction → source packet → analysis → rendering → delivery
#
#   Each stage has a typed input and output. `mailfe` is one front door over that
#   belt; future callers can replace the front door or the delivery target without
#   rewriting OCR, analysis prompts, rendering, or AgentMail.
#
# WHAT THIS CARD SPAWNS
#   Codespace : bin/mailfe                       (front door / local orchestrator)
#               bin/file-to-text                (attachment-to-text extractor)
#               bin/mail-free-energy-analysis   (Cloudcity analysis + email sender)
#   Thinkspace: this feature card; the Newman proof email; free-energy-lens-voices.feature
#   Areaspace : OWNS the typed belt contract and the "mail me analysis" workflow.
#               MUST NOT own whisp transcription (`process` owns media/YouTube);
#               MUST NOT own KeelyNet scheduling; MUST NOT own AgentMail generally.
#
# RESULT
#   Built locally + deployed to Cloudcity 2026-07-21.
#   Proved with:
#     - Dorsey ELI3 pasted source → email
#     - `mailfe --combine` on KeelyNet NEWMAN1-7 + six Newman/Bedini board PNGs
#       → one 12,665-word extracted packet → one email with Visual / Animation Treatment
# =============================================================================

Feature: mailfe is a reusable Convey belt from source material to emailed analysis
  As the operator of the personal archive
  I want any text-bearing input to move through a typed analysis belt
  So that KeelyNet files, pasted notes, PDFs, images, and future sources can reuse the same extraction, analysis, rendering, and delivery stages

  Background:
    Given the belt stages are named `intake`, `extract_text`, `assemble_packet`, `analyze`, `render`, and `deliver`
    And `process` remains the separate media/YouTube-to-transcript belt
    And `mailfe` is the current CLI front door for this belt
    And `mail-free-energy-analysis` is the current Cloudcity analysis-and-email stage
    And `FREE_ENERGY_LENS_VOICES` controls Russell, Bearden, Prigogine, and Hilarion lens sections

  @built
  Scenario: the front door accepts stdin as a source
    Given a user has pasted text on stdin
    When they run `pbpaste | mailfe --title "Pasted source"`
    Then `mailfe` creates one source payload from stdin
    And the payload enters the same `assemble_packet`, `analyze`, `render`, and `deliver` stages as a file
    And the resulting email subject is derived from the provided title

  @built
  Scenario: the front door accepts one local file
    Given a user has a local file path
    When they run `mailfe source.md`
    Then the `intake` stage resolves the path to an absolute file path
    And the `extract_text` stage emits plain UTF-8 text plus source identity
    And the file basename becomes the default packet title

  @built
  Scenario: the extraction stage normalizes many file types to text
    Given a file extension is text, Markdown, code, JSON, YAML, RTF, HTML, DOCX, PDF, or image
    When `extract_text` runs
    Then text-like files are read directly
    And RTF/HTML/Office-ish files are converted with `textutil`
    And PDF/image files are OCRed through Apple Vision via `file-to-text`
    And the output contract is always text suitable for an LLM context window

  @built
  Scenario: unknown binary files fail before analysis
    Given a source file cannot be read as text and cannot be OCRed
    When `extract_text` runs
    Then the belt fails with a clear extraction error
    And no model call is made
    And no email is sent

  @built @proved
  Scenario: multiple sources can be combined into one packet
    Given a user passes multiple files and `--combine`
    When `mailfe --combine --title "Newman packet" NEWMAN1.md NEWMAN2.md board.png` runs
    Then the `assemble_packet` stage emits one packet, not one packet per source
    And each source is separated by a `SOURCE FILE` marker
    And the packet preserves source order
    And exactly one analysis email is sent
    # proved 2026-07-21: NEWMAN1-7 + Newman whiteboard PNGs + Dorsey Newman/Bedini PNG
    # extracted 12,665 words and sent one email:
    # msg=<0100019f855b20dd-8ad05244-2f6b-4d6e-ad6f-a8af9457889e-000000@email.amazonses.com>

  @built
  Scenario: analysis is a stage, not the front door
    Given a source packet has been assembled
    When the `analyze` stage runs
    Then it calls Cloudcity freellmapi for the main analysis
    And it may call MLX/Qwen for a subordinate lesser take
    And it applies the free-energy analysis prompt
    And it can include `Cross-Lens Reads` when `FREE_ENERGY_LENS_VOICES=1`
    And callers do not need to know which model or host performed the analysis

  @built
  Scenario: visual material gets a treatment, not just OCR text
    Given a source packet includes OCR from PNG, JPG, PDF, whiteboard, board, diagram, figure, or image filenames
    When the `analyze` stage writes the email body
    Then it includes `Visual / Animation Treatment`
    And that section describes what the original image appears to show
    And it proposes a generated/cleaned frame that clarifies the mechanism
    And it gives a 3-6 beat original-to-generated fade or animation sequence
    And it does not invent details that the source packet does not support

  @built
  Scenario: generated whiteboards are optional visual derivatives
    Given a source packet has been assembled from text, OCR, and image filenames
    When `mailfe --whiteboards --whiteboard-count 3` runs
    Then `render visual` calls the existing Gemini whiteboard generator
    And the generated PNG boards are attached to the outgoing AgentMail message
    And the generated PDF board packet is attached when the generator produces one
    And the generated artifacts persist under `whiteboards/mailfe/<date-title>/` unless an output directory is supplied
    And this is opt-in so normal analysis emails do not pay image-generation cost

  @built
  Scenario: source images are carried as email attachments
    Given a source packet includes PNG, JPG, GIF, TIFF, HEIC, BMP, or WEBP files
    When `mailfe` sends the packet to Cloudcity
    Then the image files are copied to temporary Cloudcity storage
    And large images are resized/compressed into email-sized derivatives before delivery
    And `deliver` attaches the source images or their email-sized derivatives to the outgoing AgentMail message
    And the rendered email lists the attached source image filenames
    And the temporary Cloudcity copies are removed after sending

  @built
  Scenario: rendering turns Markdown into rich email HTML
    Given the analysis stage returns Markdown
    When `render` runs
    Then headings become email headings
    And bold, italic, inline code, ordered lists, and bullets render as HTML
    And pipe-table Markdown renders as a real HTML table
    And table cells do not appear in the email as raw `|`-delimited text
    And the plain text part is also sent for mail clients that ignore HTML

  @built
  Scenario: delivery is an interchangeable output stage
    Given a rendered analysis exists
    When `deliver` runs with the AgentMail backend
    Then the result is emailed to the requested recipient
    And the command prints the AgentMail message id
    And a future deliverer could save to wiki, headspace, PDF, Discord, or a queue without changing extraction or analysis

  @built
  Scenario: the belt distinguishes analysis from transcription
    Given the input is an audio file, video file, or YouTube URL
    When the user wants a transcript
    Then the correct front door is still `process`
    And whisp owns the speech-to-text result
    But a transcript produced by whisp can later become a `mailfe` source packet

  @built
  Scenario: the belt is reusable by other Convey front doors
    Given another tool has already produced text, OCR, transcript, wiki excerpts, or source snippets
    When it hands those bytes to `assemble_packet`
    Then it can reuse the same `analyze`, `render`, and `deliver` stages
    And it does not need to shell through the `mailfe` CLI
    And the belt remains DRY across KeelyNet, pasted notes, images, PDFs, videos-after-transcription, and future archive jobs

  @todo
  Scenario: Convey names each stage as a first-class verb
    Given the current implementation exists as `mailfe` plus helper scripts
    When the belt is promoted into Convey proper
    Then Convey exposes verbs equivalent to:
      | stage           | candidate verb              | output |
      | intake          | `convey source intake`      | source references |
      | extract_text    | `convey source text`        | extracted text |
      | assemble_packet | `convey packet build`       | packet document |
      | analyze         | `convey analyze freeenergy` | Markdown analysis |
      | render          | `convey render email`       | HTML + text email body |
      | deliver         | `convey deliver mail`       | message id |
    And `mailfe` becomes a thin alias over those verbs
