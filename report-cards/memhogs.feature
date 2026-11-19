Feature: memhogs — which processes eat a Mac's memory, and what are they doing
  # impl: bin/memhogs · demo: analysis/memory/2026-11-19-cloudcity-memory.md

  @hw-verified
  Scenario: local + remote report
    Given any Mac reachable by SSH (python3 + Apple CLIs only, nothing installed remotely)
    When I run "memhogs" or "memhogs --host cloudcity"
    Then I see RAM, wired/active/compressed/free, swap and pressure
    And processes grouped into families (.app bundle, or interpreter + script / -m module)
    And the top processes by phys footprint (top -stats mem) with uptime and full argv

  @untested
  Scenario: --json output consumed by Fleet machine-card
