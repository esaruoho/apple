# Implementation: bin/notes-append-images · Knowledge: docs/apple-notes-images.md
Feature: notes-append-images — append images to an Apple Note, rendered once each

  @hw-verified
  Scenario: clipboard-paste path renders images inline, once
    Given an existing note created by notes-new
    When 8 PNG images are pasted via «class PNGf» clipboard + Cmd-V
    Then NoteStore shows 8 public.png attachments for that note
    And a screenshot shows each image once, unglitched
    # verified manually 2026-11-08 on the Russell radiant-spike note (same steps, pre-script)

  @built @untested
  Scenario: script reports a count mismatch
    When fewer public.png rows appear than images given
    Then it exits 4 and says to screenshot the note

  @designed
  Scenario: rejected methods are documented, not used
    Then `make new attachment` and data-URI <img> are never used (duplicates / file chips)
