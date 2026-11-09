# Report card: bin/notes-process — #process tag in Apple Notes → Cloudcity LLM reply, APPEND-ONLY
Feature: a #process tag in a note gets an LLM reply added as rich text, never by rewriting the note

  @built @hw-verified
  Scenario: A real orange Notes tag is found (2026-11-08, note p13544)
    Given Esa typed "hey i want you to tell me about electricity #process" in Notes.app
    Then find_occurrences() finds it in NoteStore.sqlite opened read-only (hashtag UTI, ZALTTEXT)
    And prompts_for() sends "hey i want you to tell me about electricity" verbatim to fmremote

  @built @hw-verified
  Scenario: Fallback — reply as a linked rich-text note (note p13583)
    Given the Shortcut "notes-process-append" is not installed
    Then the reply is created as "Re: <title>" via bin/notes-new (markdown → rich text)
    And the original note is not modified at all

  @todo
  # generated Shortcut FAILED (dialogs) 2026-11-08; disabled. Hand-built variant documented, unverified.
  Scenario: True append via Shortcut (wiki/concepts/notes-process-append-shortcut.md)
    Given the Shortcut is installed and the note title is unique (title_count() == 1)
    Then the markdown reply is appended with Make Rich Text from Markdown + Append to Note

  @built @hw-verified
  Scenario: No feedback loop
    Then the second pass reports "nothing new for #process"
    And the ledger is keyed by the tag object's ZIDENTIFIER
    And the reply ends with "#done" and is sanitised so it never contains the trigger

  @built @sim-verified
  Scenario: Never rewrites a note (test_notes_process.py: 7 tests)
    Then the source contains no "set body"

  @built @designed
  Scenario: Guards
    Then locked notes, Recently Deleted, and notes edited < 15s ago are skipped

  @untested
  Scenario: Running on the Mini under Cloudcity-Boot via systems.yaml

  @built
  Scenario: Notes.app self-heals on the unattended Mini
    Given Notes is not running, or 2 Notes requests in a row time out (Notes wedged)
    Then notes-process starts Notes in the background (open -g -a Notes), restarting it first if wedged
    # bin/notes-process heal_notes(); 2026-11-09 Mini Notes was stuck 16 days at 76% CPU
