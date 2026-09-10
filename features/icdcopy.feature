# ============================================================================
# REPORT CARD — icdcopy: iCloud Drive copy + checksum verify
# ============================================================================
#
# WHAT THIS CARD SPAWNS
#   Codespace : bin/icdcopy
#   Thinkspace: features/icdcopy.session.md
#   Areaspace : OWNS = copying iCloud Drive files/folders to a local external
#               destination with resumable rsync and post-copy verification.
#               MUST NOT TOUCH = deleting the source, evicting iCloud originals,
#               bulk moving, Finder automation, or destructive cleanup.
#
# RESULT
#   Initial build: direct local utility install, no PR.
#   Files changed: bin/icdcopy, features/icdcopy.feature,
#     features/icdcopy.session.md.
#
# WATCH: icdcopy
# ============================================================================

Feature: Copy iCloud Drive files and folders to external storage without Finder errors

  @built
  Scenario: command has the one-and-done shape Esa asked for
    Given a source file or folder in iCloud Drive
    And a destination folder such as `/Volumes/T9/iCloudDrive AbletonCloud`
    When `icdcopy SOURCE DESTINATION_FOLDER` runs
    Then the source lands at `DESTINATION_FOLDER/basename(SOURCE)`
    And the user does not need to remember the rsync flags
    # innards: bin/icdcopy argument parsing and `target="$dest_root/$src_name"`

  @built
  Scenario: copy is resumable after iCloud or disk interruption
    Given iCloud downloads may stall or fail partway through a large Ableton project
    When the rsync copy exits non-zero
    Then the wrapper reports COPY INCOMPLETE
    And rerunning the exact same command resumes via partial files
    # innards: bin/icdcopy copy rsync uses --partial and --append-verify

  @built
  Scenario: verification is checksum-based before success is claimed
    Given the copy rsync finished successfully
    When the verification pass runs
    Then rsync compares source and destination with --checksum in dry-run mode
    And success is printed only when the dry-run reports no changed paths
    # innards: bin/icdcopy verification rsync uses --checksum --dry-run

  @built
  Scenario: source data is never deleted by the wrapper
    Given the destination copy verifies
    When the command exits successfully
    Then it prints that the source was not deleted
    And no `--remove-source-files`, `rm`, or destructive move path exists
    # innards: bin/icdcopy final message and absence of destructive operations
