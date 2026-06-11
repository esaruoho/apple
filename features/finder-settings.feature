# ============================================================================
# REPORT CARD — Finder Settings via `defaults`
# ============================================================================
#
# WHAT THIS CARD SPAWNS
#   Codespace : bin/finder-settings (read/set every Finder ▸ Settings toggle via
#               com.apple.finder + NSGlobalDomain, then killall Finder),
#               commands/finder-settings.md (/finder-settings slash pointer),
#               wiki/concepts/finder-settings.md (key map + scope-value table),
#               skill.md routing line, MEMORY.md knowledge-table row.
#   Thinkspace: features/finder-settings.session.md (the spawning conversation).
#   Areaspace : OWNS = the Advanced pane (extensions, bin warnings, folders-on-top,
#               search scope) + the General desktop/tabs toggles, all as `defaults`
#               keys. MUST NOT TOUCH = the Sidebar pane (sfl2 store, not a defaults
#               job — see finder-sidebar-locked.md) and Finder windows beyond the
#               relaunch.
#
# WHY THIS CARD EXISTS
#   Esa wanted to drive Finder ▸ Settings checkboxes from code — specifically
#   "Search the Current Folder", "Show all filename extensions", and "Keep folders
#   on top in windows when sorting by name". Every box in that pane is a preference
#   key, so this is pure Apple-native `defaults` control + relaunch — NO UI
#   scripting, no Accessibility prompt. "really important to be able to do this work."
#
# REPORT-CARD LEGEND
#   @built  wired + runnable; restarts Finder (disruptive) so not in an automated
#           test. Scenarios marked "(ran live)" were executed successfully this
#           session against the real machine.
#   @note   a documented boundary, not an executable claim.
#
# RESULT
#   Direct-push to main, no PR. Commits:
#     bfef17f  bin/finder-settings + /finder-settings slash + wiki concept page
#     48a22f4  skill.md routing pointer (deploy)
#   Slash installed via commands/install.sh (symlink → ~/.claude/commands/).
#   MEMORY.md row added (outside repo). This card + .session.md added on top.
#   Live machine state after `apply`: AppleShowAllExtensions=1, _FXSortFoldersFirst=1,
#   FXDefaultSearchScope=SCcf.
# ============================================================================

Feature: Read & control Finder Settings from the command line

  @built
  Scenario: show prints the live state of every known toggle  (ran live)
    Given Finder ▸ Settings has booleans across NSGlobalDomain + com.apple.finder
    When `finder-settings` (or `finder-settings show`) runs
    Then it prints each toggle as ON / OFF / -default-, plus the search scope as
      SCev|SCcf|SCsp with its menu label
    And -default- distinguishes "key never written" from an explicit 0 — important
      because an unset FXDefaultSearchScope still READS as "Search This Mac" in the UI
    # cite: bin/finder-settings show(); read_bool returns "(unset)" → "-default-"

  @built
  Scenario: apply sets Esa's preset and relaunches Finder  (ran live)
    When `finder-settings apply` runs
    Then AppleShowAllExtensions=true (NSGlobalDomain), _FXSortFoldersFirst=true,
      FXDefaultSearchScope=SCcf (com.apple.finder), then killall Finder
    And the Advanced pane shows: extensions on, folders-on-top on, "Search the
      Current Folder" selected
    # cite: bin/finder-settings apply case; verified live → SCcf, both bools = 1

  @built
  Scenario: set flips any one boolean toggle on or off
    When `finder-settings set <name> on|off` runs (name ∈ show-extensions,
      warn-extension-change, warn-remove-icloud, warn-empty-bin, remove-bin-30days,
      folders-on-top, folders-on-top-desktop, open-in-tabs, show-hard-disks,
      show-external-disks, show-removable-media, show-connected-servers)
    Then it writes the mapped `defaults` key as -bool and relaunches Finder
    And an unknown name exits non-zero pointing at `finder-settings help`
    # cite: bin/finder-settings set case + key_for() name→"domain key" map

  @built
  Scenario: search selects the "When performing a search" scope
    When `finder-settings search current|thismac|previous` runs
    Then FXDefaultSearchScope := SCcf | SCev | SCsp and Finder relaunches
    # cite: bin/finder-settings search case; scope_label() maps value→menu text

  @built
  Scenario: every checkbox change is invisible until Finder relaunches  (ran live)
    Given `defaults write` updates the plist but a running Finder caches prefs
    When any set/search/apply path completes
    Then the tool calls `killall Finder` so the new value takes effect
    # cite: bin/finder-settings relaunch(); the apply run this session relaunched Finder

  @built
  Scenario: the same capability is reachable as a zero-roundtrip slash
    Given commands/finder-settings.md forwards $ARGUMENTS to bin/finder-settings
    When `/finder-settings ...` is typed in Claude Code
    Then the tool runs with no further LLM tokens spent
    # cite: commands/finder-settings.md; installed by commands/install.sh symlink

  @note
  Scenario: the Sidebar pane is out of scope
    Given Sidebar Favorites live in com.apple.sidebarlists / the sfl2 store, not
      plain booleans
    Then finder-settings deliberately does NOT touch them
    # cite: wiki/concepts/finder-settings.md gotchas; finder-sidebar-locked.md
