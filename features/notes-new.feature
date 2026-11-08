# Report card: bin/notes-new — create one Apple Note safely (additive only)
Feature: notes-new creates exactly one new Apple Note without touching anything else

  @built @hw-verified
  Scenario: Creates a note in an explicit account/folder and verifies it
    Given account "iCloud" and folder "Notes" exist
    When I run "bin/notes-new --title T file.md"
    Then one note is made via `make new note` (APPLESCRIPT in bin/notes-new)
    And its id is printed and its name is read back and compared to T

  @built @hw-verified
  Scenario: Refuses bad targets instead of guessing
    Then folder "Recently Deleted" is refused (rc 2)
    And a missing folder fails with NO_FOLDER and is NOT created (rc 1)

  @built @hw-verified
  Scenario: Content cannot inject AppleScript or break HTML
    Then title/body travel as osascript argv, never spliced into script text
    And <, >, & are HTML-escaped before markdown conversion (inline())

  @designed
  Scenario: Never edits, moves, deletes, keystrokes, or writes NoteStore SQLite
    Then the only Notes verbs used are exists / make / id / name

  @untested
  Scenario: Google (IMAP) Notes account behaves like iCloud

  @built @hw-verified
  Scenario: Tables, blockquotes and rules become rich text (proved 2026-11-08)
    Given the Bearden-voice Wachsmuth/Dollard letter (merlib-dump/articles/2026-11-08-…)
    When it is posted with notes-new
    Then Notes stores a native <table> with 15 cells (header + 4 rows × 3) — table_html()
    And blockquotes keep bold/italic (indent is dropped by Notes; italic marks the quote)
    And --- becomes a ──── divider, ## becomes Notes' bold 18px heading
    And zero raw "|", "> " or "---" markers remain in the stored body
