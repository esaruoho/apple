# ============================================================================
# REPORT CARD — icdcopy: iCloud Drive copy + checksum verify
# ============================================================================
#
# WHAT THIS CARD SPAWNS
#   Codespace : bin/icdcopy + bin/icloud-materialize.swift + bin/icdsizefolder
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
  Scenario: latest folder ranking can be copied by number
    Given `icdsizefolder` has saved a ranked folder manifest
    And the user is in the desired destination directory
    When `icdcopy 5` runs
    Then row 5 from the saved manifest becomes the source
    And the destination root is the current directory
    # innards: bin/icdsizefolder manifest writer + bin/icdcopy `resolve_manifest_index()`

  @built
  Scenario: folder ranking rows are actual folders
    Given the scanned root contains loose files
    When `icdsizefolder` ranks copy targets
    Then root-level loose files are excluded from the numbered list
    And `icdcopy N` always resolves to a folder path
    # innards: bin/icdsizefolder `folder_key()`

  @built
  Scenario: folder ranking defaults to useful iCloud scope and reports scan progress
    Given the user runs `icdsizefolder` from any shell directory
    When no root argument is provided outside iCloud Drive
    Then it scans `~/Library/Mobile Documents/com~apple~CloudDocs`
    When no root argument is provided inside an iCloud Drive subfolder
    Then it scans that current subtree
    And it prints a compact in-place scan heartbeat with directories, files, ranked folders, and elapsed time
    # innards: bin/icdsizefolder default root + `scan()` heartbeat

  @built
  Scenario: folder ranking table has stable aligned numeric columns
    Given the list has rows 1 through 30
    And some folders have six-digit file counts
    When `icdsizefolder` prints the ranking table
    Then row numbers are zero-padded like `01`
    And the files column width grows to fit the largest count
    # innards: bin/icdsizefolder table formatting

  @built
  Scenario: AbletonCloud can be ranked without typing the long iCloud path
    Given the user wants to rank folders inside iCloud Drive/AbletonCloud
    When `icdsizefolder ableton` runs
    Then it scans `~/Library/Mobile Documents/com~apple~CloudDocs/AbletonCloud`
    And the saved numeric mapping is suitable for `icdcopy N` from the T9 folder
    # innards: bin/icdsizefolder `PRESETS`

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
  Scenario: Finder metadata does not make a verified copy fail
    Given Finder may mutate `.DS_Store` while a folder copy is in progress
    When `icdcopy` copies and verifies an Ableton project
    Then `.DS_Store` and AppleDouble sidecar files are excluded from copy and verify
    And a changed Finder folder-view file does not force a manual rerun
    # innards: bin/icdcopy `rsync_common` excludes

  @built
  Scenario: verification differences are repaired automatically
    Given checksum verification reports real differences after the copy pass
    When fewer than two automatic repair passes have run
    Then `icdcopy` reruns rsync itself
    And it verifies again before asking the user to intervene
    # innards: bin/icdcopy verification repair loop

  @built
  Scenario: iCloud files are explicitly materialized before rsync copy
    Given a source tree may contain dataless iCloud placeholders
    When `icdcopy SOURCE DESTINATION_FOLDER` runs
    Then it first invokes `icloud-materialize.swift SOURCE`
    And the helper calls `startDownloadingUbiquitousItem(at:)` for each nonlocal file
    And it prints compact scan/waiting summaries before rsync begins copying
    # innards: bin/icdcopy materialize phase + bin/icloud-materialize.swift

  @built
  Scenario: Apple FileProvider enums are hidden in normal use
    Given FileProvider returns statuses named like `NSURLUbiquitousItemDownloadingStatusNotDownloaded`
    When `icdcopy SOURCE DESTINATION_FOLDER` runs without debug flags
    Then the command prints human-readable summaries
    And normal mode prints fixed-width received counts like `downloads ready 07/60`
    And projects above 99 pending files use three digits, like `007/120`
    And the current waiting filename is omitted while the ready count is changing
    And per-file status output is available only through `icloud-materialize.swift --verbose`
    # innards: bin/icloud-materialize.swift `verbose`

  @built
  Scenario: stalled download progress says elapsed time and timeout remaining
    Given iCloud accepts download requests but no pending files become ready
    When the download wait loop reports unchanged progress
    Then it prints elapsed no-progress time and timeout remaining
    And it avoids repeating identical `0/N` lines with no added information
    # innards: bin/icloud-materialize.swift progress loop

  @built
  Scenario: interrupted iCloud download phase exits cleanly
    Given the materializer receives Ctrl-C or SIGTERM during the download phase
    When control returns to `icdcopy`
    Then the wrapper reports that it stopped during iCloud download
    And it tells the user to rerun the same command to continue
    # innards: bin/icdcopy materialize_status 130/143 handling

  @built
  Scenario: a stuck iCloud download fails with the exact file instead of hanging
    Given FileProvider keeps one item at `NSURLUbiquitousItemDownloadingStatusNotDownloaded`
    When the materialization phase waits longer than its per-file limit
    Then the command exits non-zero
    And it names the stuck file and tells the user iCloud did not make the source local
    # innards: bin/icloud-materialize.swift `--max-wait`

  @built
  Scenario: slow iCloud completion is allowed to finish in one command
    Given iCloud may accept download requests but complete them after several minutes
    When `icdcopy` runs the materialization phase
    Then it waits without an overall timeout in normal copy mode
    And a file that completes after a long silent delay does not force a manual rerun
    # innards: bin/icdcopy `--max-wait 0`

  @built
  Scenario: resident bytes count as ready even if FileProvider status is stale
    Given iCloud has materialized a file onto local disk
    But FileProvider's download status has not updated yet
    When the materializer checks readiness
    Then it accepts resident disk blocks as ready
    And it does not keep waiting until the user quits and reruns
    # innards: bin/icloud-materialize.swift `residentBytesReady()` + `fileReady()`

  @built
  Scenario: zero visible progress is reported but not treated as failure
    Given iCloud accepted download requests
    But no requested file becomes ready for several minutes
    When the materialization phase is waiting
    Then it keeps waiting until iCloud reports the files ready or the user interrupts
    And it reports elapsed no-progress time without killing the useful background download
    # innards: bin/icdcopy materializer call without `--no-progress-timeout`

  @built
  Scenario: wrapper script stays parse-clean after shell edits
    Given `icdcopy` is edited to change copy or download behavior
    When `bash -n bin/icdcopy` is run
    Then Bash reports no syntax errors
    And the help text matches the current no-timeout iCloud download behavior
    # innards: bin/icdcopy syntax + `usage()`

  @built
  Scenario: source data is never deleted by the wrapper
    Given the destination copy verifies
    When the command exits successfully
    Then it prints that the source was not deleted
    And no `--remove-source-files`, `rm`, or destructive move path exists
    # innards: bin/icdcopy final message and absence of destructive operations

  @built
  Scenario: quoted Terminal-escaped paths are accepted
    Given Finder or Terminal produced `/Users/name/Mobile\ Documents/com\~apple\~CloudDocs/...`
    And the user wrapped that already-escaped path in quotes
    When `icdcopy "/Users/name/Mobile\ Documents/com\~apple\~CloudDocs/source" "/Volumes/T9/dest"` runs
    Then the wrapper normalizes the common backslash escapes before the existence check
    And escaped tildes remain literal `~` characters rather than expanding to `$HOME`
    And the copy proceeds against the real path rather than the literal-backslash path
    # innards: bin/icdcopy `normalize_path_arg()`

  # ── icdcheck: read-only download-audit sibling (added 2026-09-16) ───────────

  @built @sim-verified
  Scenario: icdcheck confirms a fully-local folder is PERFECT
    Given a folder whose every file is local/current/downloaded and resident on disk
    When `icdcheck PATH` runs
    Then it prints "PERFECT — every file is downloaded and resident on disk"
    And it exits 0
    # innards: bin/icdcheck → bin/icloud-materialize.swift `runCheck()` (isReady + residentBytesReady)
    # verified: audited ~/work/convey/kb/graph/entities-renoise → "6518 OK … PERFECT"

  @built @sim-verified
  Scenario: icdcheck flags dataless placeholders and in-flight downloads
    Given an iCloud folder holding some not-downloaded and some downloading files
    When `icdcheck PATH` runs
    Then it lists each not-ready file with a status label (NOT-DOWNLOADED / DOWNLOADING / SUSPECT)
    And it prints a summary count and the `icdmat <path>` fix hint
    And it exits 1
    # innards: bin/icloud-materialize.swift `runCheck()` categories + `isDownloading()`
    # verified: audited iCloud/ASCII → "1 not-downloaded, 11 downloading" exit 1

  @built
  Scenario: icdcheck never triggers a download (read-only audit)
    Given the audit classifies every file under PATH
    When `--check` mode runs
    Then it only reads iCloud resource values and on-disk stat, never calling startDownloadingUbiquitousItem
    And a placeholder stays a placeholder after the audit
    # innards: bin/icloud-materialize.swift `runCheck()` returns before the download loop; no download call

  @built
  Scenario: icdcheck emits machine-readable JSON for tooling
    Given `icdcheck --json PATH`
    When the audit completes
    Then it prints one JSON object with total/ok/not_downloaded/downloading/suspect and an issues array
    # innards: bin/icloud-materialize.swift `runCheck(json:)`

  @built
  Scenario: icdcheck reuses the materializer engine rather than re-rolling status logic
    Given icdmat and icdcheck both need iCloud download status
    When icdcheck is built
    Then it is a thin wrapper over the same bin/icloud-materialize.swift binary (cached under ~/.cache/icdcopy)
    And it shares resourceStatus/isReady/residentBytesReady with icdmat and icdcopy
    # innards: bin/icdcheck flags=(--check); DRY per feedback_reuse_before_rerolling
