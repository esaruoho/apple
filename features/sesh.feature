# =============================================================================
# REPORT CARD: sesh — one word that saves your open Claude Code sessions,
#                     or boots them all back into their folders
# Skin: macOS / iTerm2 / Claude Code session store
# SESSION >> features/usb-port-revive.session.md  (same conversation)
#
# WHAT THIS CARD SPAWNS
#   Codespace:  bin/sesh                  the one verb
#               bin/_claude_sessions.py   shared discovery + snapshot
#               commands/sesh.md          slash pointer
#   Thinkspace: the tool must be idempotent-by-context, not by flag. At the
#               moment you need it — machine about to restart, or just back up —
#               you should not have to decide which subcommand to type. Same
#               three letters, right behaviour.
#   Areaspace:  owns "which Claude Code sessions exist and how to bring them
#               back". Does NOT own resuming a SINGLE chosen session — that is
#               bin/sessions (a TUI picker). sesh is the master/bulk verb.
#
# ORIGIN
#   Esa, 2026-08-07, after a restart cost him eight sessions:
#     "i want me to write 'sesh' and currently open ones are saved, and then
#      when there are none open, i write sesh again and all of them retrigger in
#      the right folders. do you see? i want sessions to basically have a way of
#      having the master sessions bootable."
#
# RESULT
#   Delivery: direct-push to main, no PR
#   Files: bin/sesh (new), bin/_claude_sessions.py (new), commands/sesh.md (new),
#          bin/port-revive (refactored onto the shared module)
# =============================================================================

Feature: The master session list is bootable with one word
  As someone who loses a day's worth of Claude Code sessions to every restart
  I want one verb that saves them when they exist and restores them when they don't
  So that a restart costs nothing and I never have to remember what was open

  @built @hw-verified
  Scenario: Sessions are open, so sesh saves them
    Given Claude Code sessions are running
    When I type `sesh`
    Then each session's folder, id and permission flag are written to the snapshot
    # Verified 2026-08-07 against 12 live sessions; count cross-checked with ps.
    # bin/sesh :: main, auto branch

  @built @hw-verified
  Scenario: Nothing is open, so sesh boots the snapshot
    Given no Claude Code sessions are running
    And a snapshot exists
    When I type `sesh`
    Then one iTerm tab opens per saved session, cd'd into its own folder
    And each resumes its own session id
    # VERIFIED 2026-08-07 — though by accident. A test intended to inspect the
    # branch actually executed it and opened all 9 snapshot sessions in iTerm,
    # correctly foldered. Esa closed them by hand. Unintended, but it is a real
    # end-to-end verification of the launch path.
    # bin/sesh :: boot

  @built @hw-verified
  Scenario: Never resume a session that is already open
    Given some snapshot sessions are already running
    When I run `sesh boot`
    Then those are skipped with "already running — not duplicating"
    And only genuinely absent sessions are launched
    # This gap is exactly what the accident above exposed: the first version
    # happily re-resumed live ids and took Esa from 12 sessions to 21 duplicates.
    # Two processes on one transcript is also a conflict risk, not just noise.
    # Verified: with all 9 live, `sesh boot` skips all 9 and launches nothing.
    # bin/sesh :: boot, live_ids

  @built @hw-verified
  Scenario: Never overwrite a good snapshot with an empty one
    Given nothing is running
    When I run `sesh save` explicitly
    Then it refuses and leaves the snapshot untouched
    # This is the single way sesh could destroy the thing it exists to protect:
    # save-when-empty right after the restart that lost everything.
    # Verified: snapshot bytes identical before and after the refusal.
    # bin/sesh :: main, save branch

  @built @hw-verified
  Scenario: Folders with spaces survive the round trip
    Given a session runs in the Paketti .xrnx path under Mobile Documents
    When the resume command is built
    Then the folder is shlex-quoted
    # bin/_claude_sessions.py :: resume_cmd

  @built @hw-verified
  Scenario: Dry run shows the plan without launching anything
    When I run `sesh boot --dry-run`
    Then each folder and session id is printed and nothing is launched
    # bin/sesh :: boot, dry_run

  @built @hw-verified
  Scenario: Session discovery has exactly one implementation
    Given both sesh and port-revive need to know what is running
    Then both import bin/_claude_sessions.py
    # port-revive originally carried its own copy of the ps/lsof/transcript
    # dance. Extracted rather than duplicated, per the reuse-before-re-rolling
    # rule. port-revive :: claude_sessions is now a one-line delegation.

  @built @untested
  Scenario: A folder that no longer exists is skipped, not fatal
    Given a saved session points at a deleted folder
    When I run `sesh boot`
    Then it is skipped with a reason and the rest still launch
    # Logic present; never exercised against an actually-deleted folder.
    # bin/sesh :: boot, is_dir check

  @built @untested
  Scenario: iTerm launch failure falls back to printed commands
    Given the AppleScript fails
    Then the snapshot is left intact and every resume command is printed
    # bin/sesh :: boot, returncode branch

  @todo
  Scenario: Restore window/tab layout, not just the session set
    # Currently every session gets a plain tab in one window. Pane arrangement,
    # ordering and profiles are not preserved.

  @todo
  Scenario: Boot sessions that were closed rather than only those live at save
    # The snapshot is a point-in-time picture of RUNNING sessions. A session
    # closed before the save is not in it, even if it is the one you wanted.
