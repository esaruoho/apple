# ============================================================================
# REPORT CARD — macOS energy consumption from the CLI
# ============================================================================
#
# WHAT THIS CARD SPAWNS
#   Codespace : bin/apple-energy (now/watch/power/adapter over powermetrics + top
#               + system_profiler + pmset; watch parses powermetrics -f plist via
#               python3 plistlib + aggregates per-process energy impact),
#               commands/apple-energy.md (/apple-energy slash pointer),
#               analysis/energy-consumption-cli.md (the answer-to-Dima writeup).
#   Thinkspace: features/apple-energy.session.md (the spawning conversation).
#   Areaspace : OWNS = (a) reading energy/power/heat telemetry from Apple-shipped
#               CLIs + aggregating per-process energy over a sampled window, and
#               (b) ACTING on hogs: SIGTERM a process (kill) or stop+disable a
#               launchd job so it stays dead (off). The read/act split is explicit
#               in help. MUST NOT TOUCH = changing power POLICY (pmset writes,
#               caffeinate, sleep/hibernate mode) and critical/system processes
#               (kill refuses a denylist + pid<50). off is dry-run by default.
#
# WHY THIS CARD EXISTS
#   Dima asked: he has `system_profiler SPPowerDataType | grep Wattage` for current
#   adapter wattage, and wants Activity Monitor's "Energy" tab — "which apps consume
#   the most energy over time" — from the CLI. That tab is a front-end over Apple
#   CLIs; the one gap is macOS exposes NO historical per-app energy store, so
#   over-time ranking must be sampled + aggregated. This tool does exactly that.
#
# REPORT-CARD LEGEND
#   @built       wired + runnable. "(ran live)" = executed this session on the real Mac.
#   @parser-verified  the powermetrics-plist aggregation was tested against a
#                synthetic null-separated two-sample plist (Safari 25+35=60,
#                WindowServer 40+10=50 → correctly ranked). The live powermetrics
#                capture itself needs root and was NOT exercisable in the
#                non-interactive build session (sudo has no TTY to prompt) — honest grade.
#   @note        a documented boundary, not an executable claim.
#
# RESULT
#   Direct-push to main, no PR. Files: bin/apple-energy (+x), commands/apple-energy.md,
#   features/apple-energy.feature (+ .session.md), analysis/energy-consumption-cli.md.
#   Live machine at build time: adapter 87W, battery 100% / 312 cycles / Normal.
# ============================================================================

Feature: Read macOS energy & power telemetry from the command line

  @built
  Scenario: now prints a no-sudo snapshot of top apps by energy impact  (ran live)
    Given top's POWER column is the same per-process energy-impact metric Activity Monitor shows
    When `apple-energy now [N]` runs
    Then it takes TWO top listings (-l 2) and prints only the SECOND, ranked by power
    And the first listing is discarded because top reports 0.0 until it has a delta
    And no sudo is required
    # cite: bin/apple-energy cmd_now(); awk keeps rows after the 2nd PID header

  @built @parser-verified
  Scenario: watch samples powermetrics over a window and ranks per-process energy
    Given macOS keeps no queryable historical per-app energy store
    When `apple-energy watch [mins] [secs]` runs
    Then it runs `sudo powermetrics --samplers tasks --show-process-energy -f plist`
      for count = mins*60/secs samples at secs interval
    And python3 plistlib splits the null-separated plist docs, sums energy_impact
      per process name across all samples, and prints a TOTAL / AVG-per-sample / %% ranking
    And samples==0 prints "No energy data captured" instead of crashing
    # cite: bin/apple-energy cmd_watch() + the APPLE_ENERGY_RAW python heredoc;
    #       parser tested against a synthetic 2-sample plist this session

  @built
  Scenario: power reports actual system watts, not relative units  (ran live, headers)
    When `apple-energy power [N]` runs
    Then it runs `sudo powermetrics --samplers cpu_power,gpu_power` and greps the
      CPU / GPU / package power (mW) + frequency lines
    # cite: bin/apple-energy cmd_power()

  @built
  Scenario: adapter prints wattage + battery state, no sudo  (ran live)
    Given Dima's existing script is `system_profiler SPPowerDataType | grep Wattage`
    When `apple-energy adapter` runs
    Then it greps SPPowerDataType for AC wattage, charging state, charge %, cycle
      count, and condition, then appends `pmset -g batt` for the live source
    And it is a superset of Dima's one-liner (87W confirmed live, plus 100% / 312 cycles / Normal)
    # cite: bin/apple-energy cmd_adapter(); ran live this session

  @built
  Scenario: heat frames watts AS heat and shows the thermal drivers  (ran live, no-sudo part)
    Given Apple Silicon (M3 Pro) exposes no clean CPU die temp, but a chip dissipates
      ~100%% of its drawn power as heat, so package watts ARE the heat-generation rate
    When `apple-energy heat [N]` runs
    Then it prints the watts=heat explainer, `pmset -g therm` throttle state (no sudo),
      then `sudo powermetrics --samplers cpu_power,thermal,smc` package power +
      thermal pressure + fan RPM
    And with no sudo it still prints the throttle state and a clear "(no powermetrics
      data — sudo may have been declined)" line instead of failing
    # cite: bin/apple-energy cmd_heat(); no-sudo portion ran live this session

  @built
  Scenario: kill SIGTERMs a hog now but refuses critical processes  (ran live)
    When `apple-energy kill <name|pid>` runs
    Then it resolves names via pgrep -i, SIGTERMs each match, and reports what died
    And it REFUSES pid<50 or any name in the critical denylist (kernel_task, launchd,
      WindowServer, coreaudiod, loginwindow, configd, powerd, …)
    And it points at `off` for anything that respawns (launchd-kept)
    # cite: bin/apple-energy cmd_kill() + CRITICAL_RE; ran live — killed a throwaway
    #       sleep, refused WindowServer (pid 174), handled no-match

  @built
  Scenario: off finds the launchd job, dry-runs by default, disables on --yes  (dry-run ran live)
    Given a hog like lghub_updater is kept alive by launchd and just respawns after kill
    When `apple-energy off <name>` runs
    Then a python3 + PlistBuddy scan of ~/Library/LaunchAgents + /Library/LaunchAgents
      + /Library/LaunchDaemons matches by plist filename / Label / program basename
    And it prints each matched Label + program + plist + domain and STOPS (dry run)
    And only `off <name> --yes` runs `launchctl bootout` + `launchctl disable`
      (system domain auto-prepends sudo) and prints the exact `launchctl enable` undo
    And it correctly resolved lghub_updater → com.logi.ghub.updater in /Library/LaunchDaemons
      (system domain) this session, distinct from the com.logi.ghub tray agent
    # cite: bin/apple-energy cmd_off(); dry-run ran live against the real lghub plists

  @note
  Scenario: power POLICY is out of bounds
    Given the ACT verbs stop processes/jobs, they never change how the Mac manages power
    Then no pmset write / caffeinate / sleep-mode change is ever issued — only bootout/disable/kill

  @built
  Scenario: same capability is reachable as a zero-roundtrip slash
    Given commands/apple-energy.md forwards $ARGUMENTS to bin/apple-energy
    When `/apple-energy ...` is typed in Claude Code
    Then the tool runs with no further LLM tokens spent
    # cite: commands/apple-energy.md; installed by commands/install.sh symlink
