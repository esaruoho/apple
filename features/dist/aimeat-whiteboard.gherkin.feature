# Pure Gherkin test extracted from features/aimeat-whiteboard.feature
# (report-card banner stripped; inline # cite: traceability kept)
# Regenerate: python3 print-card.py features/aimeat-whiteboard.feature

Feature: One selected archive folder gets a reviewed preparation before paid whiteboard generation
  As Esa I want the existing Mini roundtable to prepare board content for one selected folder
  So that I can review the Markdown before explicitly triggering Gemini whiteboard images.

  @runtime-verified
  Scenario: Prepare one folder from its existing Markdown
    # cite: bin/aimeat-whiteboard prepare markdown_sources
    Given one direct child folder under articles/boards has usable Markdown
    When I run `aimeat-whiteboard prepare <folder>`
    Then one provenance-linked request enters the existing synced AIMEAT intake
    And no Gemini image-generation call occurs
    And no other board folder is enrolled

  @runtime-verified
  Scenario: Collect a completed Mini roundtable as an editable preparation
    # cite: bin/aimeat-whiteboard collect
    Given Cloudcity returns the matching source-hash roundtable transcript
    When I collect the printed preparation id
    Then `_whiteboard-preparation.md` is written inside the selected folder
    And an existing review file is preserved unless `--replace` is explicit

  @designed @untested
  Scenario: Verify the installed BBS and Free Energy Whiteboard route without image generation
    # cite: bin/aimeat-whiteboard skill_contract manufacture
    Given a reviewed preparation exists
    When I run `aimeat-whiteboard yes-but-whiteboard <folder> --plan`
    Then the BBS guidance, Free Energy frontmatter schema and installed Whiteboard skill entry point are checked
    And the exact red-button command is printed with `--full` and `--guardrails`
    And neither the generator nor Gemini is called

  @designed @untested
  Scenario: Explicitly manufacture reviewed boards
    # cite: bin/aimeat-whiteboard manufacture skill_contract add_board_provenance ; ~/.agents/skills/whiteboard/bin/whiteboard-generate.sh
    Given I have reviewed and edited `_whiteboard-preparation.md`
    When I run `aimeat-whiteboard yes-but-whiteboard <folder>`
    Then the installed Whiteboard skill receives that Markdown and the selected board count
    And every generated companion Markdown receives Free Energy source-provenance frontmatter
    And its dated output contains the skill's PNG, PDF, synopsis, companion Markdown and manifest

  @untested
  Scenario: Image-only source is kept on the Cloudcity OCR path
    # cite: bin/aimeat-whiteboard markdown_sources
    Given a selected folder contains no usable Markdown
    When I prepare it
    Then the command stops before submitting content
    And it directs image-only PDF text extraction to the existing Cloudcity OCR pipeline

  @stock
  Scenario: Existing board outputs remain untouched
    # cite: bin/aimeat-whiteboard prepare collect manufacture
    Given the selected folder or any unselected folder already contains board outputs
    When preparation or manufacture runs
    Then existing outputs are neither deleted nor automatically regenerated
