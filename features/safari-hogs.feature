# REPORT CARD: safari-hogs — find, select, close the power-hungry Safari tab
# SESSION >> features/safari-hogs.session.md
# WATCH: bin/safari-hogs commands/safari-hogs.md wiki/concepts/safari-tab-power.md procs tabs front_tabs cputime BURN_JS PROBE_JS select close
# RESULT: see git log -- bin/safari-hogs (direct-push to main, no PR).

Feature: Identify which Safari tab is eating power, and act on it

  @built @hw-verified
  Scenario: Rank Safari processes by energy without side effects
    When I run "safari-hogs procs"
    Then Safari-path WebContent/GPU/Networking/Service-Worker PIDs are ranked by power, CPU, RAM
    And Mail / Keyboard Maestro WebContent processes are excluded
    # cite: bin/safari-hogs safari_pids power procs
    # verified 2026-11-10: pid 53806 9.3 power ranked first of 17

  @built @hw-verified
  Scenario: Map a front tab to its PID by CPU fingerprint
    When I run "safari-hogs tabs"
    Then each window's current tab gets a 400 ms busy loop and the PID whose CPU time jumps is reported
    # cite: bin/safari-hogs tabs BURN_JS cputime
    # verified 2026-11-10: x.com tab -> pid 53806, YouTube tab -> pid 1238

  @built @hw-verified
  Scenario: Background tabs are never JS-probed
    Then a hot PID with no front tab is listed as unmapped instead of waking sleeping tabs
    # cite: bin/safari-hogs tabs orphans

  @built @untested
  Scenario: Select or close the worst offender
    When I run "safari-hogs worst" the top-scored tab is made current and its window raised
    When I run "safari-hogs close-worst" it asks y/N before closing
    # cite: bin/safari-hogs select close

  @built @hw-verified
  Scenario: Background tabs are attributed by cache-partition site, without JS
    When a busy process hosts no front tab
    Then its mmapped WebKitCache record partitions name the sites it serves
    And all tabs on those sites are listed as candidates (site-level, not tab-level)
    # cite: bin/safari-hogs sites_for_pid all_tabs tabs
    # verified 2026-11-10: pid 27008 -> google.com, 174 candidate tabs

  @built @untested
  Scenario: Repeated `worst` walks down the list
    Then it skips the front tab of window 1 and the last pick stored in ~/.cache/safari-hogs-last
    # cite: bin/safari-hogs pick_next
