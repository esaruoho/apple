# WHAT THIS CARD SPAWNS:
# codespace: bin/aimeat-whiteboard, roundtable/whiteboard-workflow.md, wiki/concepts/whiteboard-integration.md
# thinkspace: aimeat-whiteboard.session.md plus local lossless transcript bundle
# areaspace: OWNS one-folder whiteboard preparation and explicit image trigger; reuses AIMEAT roundtable and user Whiteboard skill.
# MUST NOT touch: unselected board folders, existing PNG/PDF outputs, local OCR, or Gemini image generation during preparation.
# SESSION: aimeat-whiteboard.session.md
# RESULT: Mini compatibility payload `0db66f90cebf956d` installed; Whittaker/Tesla pilot returned a hash-verified two-section, 36-turn draft at `_whiteboard-preparation.md`; implementation + initial card `d71a59c1` pushed to main, no PR; Gemini manufacture remains unrun pending human review.
# WATCH: prepare markdown_sources collect manufacture board_folder

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
  Scenario: Explicitly manufacture reviewed boards
    # cite: bin/aimeat-whiteboard manufacture ; ~/.agents/skills/whiteboard/bin/whiteboard-generate.sh
    Given I have reviewed and edited `_whiteboard-preparation.md`
    When I run `aimeat-whiteboard yes-but-whiteboard <folder>`
    Then the installed Whiteboard skill receives that Markdown and the selected board count
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
