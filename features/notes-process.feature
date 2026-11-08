# Report card: bin/notes-process — #process hashtag in Apple Notes → Cloudcity LLM reply, non-destructive
Feature: a #process tag in a note gets an LLM reply appended, then is marked #done

  @built @hw-verified
  Scenario: Inline trigger line is answered and closed (2026-11-08, note p13471)
    Given a note line "What is the capital of Finland? … #process"
    When "notes-process --once" runs
    Then the line text minus the tag is sent verbatim to fmremote (Mini FoundationModels)
    And the reply is appended under a ──── divider with "🤖 fmremote · <time>"
    And "#process" becomes "#done" and every original line is still present

  @built @hw-verified
  Scenario: No feedback loop
    Then a second pass reports "no notes contain #process"
    And the reply is sanitised (sanitize()) so it can never contain the trigger tag
    And a ledger (~/.local/share/notes-process/ledger.jsonl) blocks re-processing the same line

  @built @sim-verified
  Scenario: Trigger parsing (test_notes_process.py)
    Then a bare "#process" line sends the note text above it, minus the title
    And "#processed" / "#process-later" do not trigger

  @built @designed
  Scenario: Guards before any write
    Then password-protected notes, notes with attachments, Recently Deleted,
      and notes edited < 15s ago are skipped
    And the body HTML is backed up before writing
    And the note is re-read before writing; if it changed during the LLM call the write is aborted
    And if any original line is missing after the write, the backup is restored at once

  @untested
  Scenario: A tag typed by hand in Notes.app (real Notes tag object) is detected and rewritten
  @untested
  Scenario: Notes on the Mini (iCloud-synced) running under Cloudcity-Boot via systems.yaml
