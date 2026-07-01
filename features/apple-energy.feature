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
    Then it takes TWO top listings (-l 2) and reads only the SECOND, ranked by power
    And the first listing is discarded because top reports 0.0 until it has a delta
    And it resolves each PID's FULL name via `ps -ww -o comm=` instead of top's
      ~16-char-truncated COMMAND column, so "Ray Helper (Rend" → "Ray Helper (Renderer)"
    And it renders a proper 4-column box table (PID · Process · What it is · Power) — NOT a
      freeform blob — via shared `_apple_energy.describe()` which splits each process into
      (process-name, detail): claude → "<ver> OLD|ok · «session» · <age> · <project> · <term>
      <tty>", a known daemon → its KNOWN description (fileproviderd/mdsync/trustd/WindowServer…
      all explained), a runtime → "<script> (← <parent>)", an app → blank (self-explanatory)
    And a PID that exits during top's sample window shows top's own name + " · ended"
      (e.g. "top · ended") instead of a bare "?" — top's -stats includes command as fallback
    And no sudo is required
    # cite: bin/apple-energy cmd_now() + bin/_apple_energy.py describe()/KNOWN; ran live —
    #       columnar table, claude row "2.1.197 ok · «~gravity-paper» · 1m · ~/work/... ttys005"

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
  Scenario: claude enumerates running Claude Code sessions by version  (ran live)
    Given Claude Code installs each version as a binary named after its version
      (~/.local/share/claude/versions/2.1.197), so top shows "2.1.193" as a process name
    When `apple-energy claude` runs
    Then it reads the current version from the ~/.local/bin/claude symlink target, finds
      every running instance (pgrep -x claude + pgrep -f /versions/2.), and for each prints
      PID, real version (lsof txt basename), OLD/ok flag, READABLE age (7d 23h / 1h 35m via
      human_age, not raw 07-22:58:40), %CPU, TERM (iTerm2 vs Terminal, ppid-chain walk),
      TTY, and project (cwd) — matching the compact table Esa liked, plus jump/kill hints
    And the introspection (proc_maps/terminal_of/version_of/cwd_of/claude_row/human_age)
      lives in the shared bin/_apple_energy.py so now/claude/jump don't duplicate it (DRY)
    # cite: bin/apple-energy cmd_claude() + bin/_apple_energy.py; ran live — 8 sessions,
    #       readable ages, TERM iTerm2/Terminal, ttys002-009

  @built
  Scenario: claude TTYs are Cmd-clickable to jump to the session  (registration ran live)
    Given iTerm2 follows OSC 8 hyperlinks on Cmd-click, but Terminal.app does NOT support
      OSC 8 — so clickable TTYs are an iTerm2-only feature; footers say so per TERM_PROGRAM
    When `apple-energy install-jump` runs once
    Then it builds ~/Applications/AppleEnergyJump.app (an AppleScript `on open location`
      handler that runs `apple-energy jump <pid>`), adds CFBundleURLTypes for the aejump:
      scheme to its Info.plist, and registers it via Launch Services (lsregister -f)
    And `apple-energy claude` (to a real TTY) wraps each session's TTY cell in an OSC 8
      hyperlink to aejump://<pid>, so Cmd-click focuses that session's terminal tab
    And render_table stays aligned because it measures VISIBLE width (_vislen strips the
      OSC 8 + SGR escapes) — verified: every boxed line is the same visible width
    And piped/non-tty output emits plain TTYs (no escapes)
    And BOTH claude and now make the claude-session TTY clickable (shared hyperlink path)
    # cite: cmd_install_jump() + cmd_claude()/annotate() links branch + hyperlink/_vislen

  @built
  Scenario: the aejump handler sends the AppleEvent directly (TCC-correct)  (diagnosed live)
    Given a first attempt buried the `tell iTerm2` in shell→python→osascript, which macOS
      could not attribute, so it denied with -1743 "Not authorised" and showed NO prompt
    When install-jump builds the applet
    Then the applet's `on open location` calls `apple-energy _resolve <pid>` (a shell call,
      no Apple events) to get TERM+tty, then `tell application "iTerm2"/"Terminal"` DIRECTLY
      so macOS attributes the event to the app and shows the one-time Automation prompt
    And the app gets a stable CFBundleIdentifier + ad-hoc codesign + NSAppleEventsUsageDescription
      so TCC identity is stable, and install-jump `tccutil reset AppleEvents <id>` clears stale denies
    And it logs each invocation to ~/.local/state/apple-energy/jump.log for debuggability
    # cite: cmd_install_jump() applet + cmd_resolve(); diagnosed via jump.log showing -1743,
    #       fixed to direct-tell — remaining step is the user's one-time Allow click

  @built
  Scenario: now is a proper 4-column table, not a freeform blob  (ran live)
    Given Esa found the single "what it is" column inconsistent/uninformative (mostly blank)
    When `apple-energy now` prints
    Then it renders PID · Process · What it is · Power as a box table via `describe(pid,…)`
      which returns (process_name, detail): a KNOWN daemon → its one-line purpose (the KNOWN
      map was expanded to cover fileproviderd/mdsync/trustd/coreduetd/… so few rows are blank),
      claude → "ver OLD|ok · «session» · age · project · term tty(clickable)", a runtime →
      "script (← parent)", a vanished pid → top's name + "ended"
    # cite: bin/_apple_energy.py describe()/KNOWN; bin/apple-energy cmd_now(); ran live

  @built
  Scenario: claude and now render as Unicode box-drawing tables  (ran live)
    Given Esa wanted the boxed table style (┌─┬─┐ │ ├─┼─┤ └─┴─┘), not ASCII "----" rules
    When claude or now prints
    Then it builds rows and calls the shared `_apple_energy.render_table(headers, rows,
      aligns)` which auto-sizes each column, centers headers, left/right-aligns data cells,
      and draws single-line box borders
    And no emoji is used inside cells (they can render double-width and break alignment)
    # cite: bin/_apple_energy.py render_table(); bin/apple-energy cmd_claude()/cmd_now()

  @built
  Scenario: claude/now/jump show the SESSION NAME, not just the project  (ran live)
    Given Claude Code stores one transcript per session at
      ~/.claude/projects/<encoded-cwd>/<session-id>.jsonl with a name derivable as
      customTitle → summary → first user-message snippet (same rule as bin/sessions)
    And the running process does NOT keep the transcript open, so PID→session is inferred
    When session_map(info) runs
    Then it pairs each PID to its session by matching the process start time (ps lstart)
      to the session's first-message timestamp — verified EXACT for all 4 merlib-dump
      sessions (gravity-paper/prigogine/"boot up …" each matched a PID to the second)
    And a confident (≤180s) match shows the plain name; a fallback (freshest unclaimed
      transcript, e.g. a resumed session whose creation ≠ process start) is prefixed "~"
    And claude gains a SESSION NAME column, now appends «name» to the claude row, and
      jump matches on the name too (jump <name> focuses that session's tab)
    # cite: bin/_apple_energy.py session_map/_session_for/session_name; ran live —
    #       "robmcneilly" (76.7%% CPU), "gravity-paper", "prigogine"; jump prigogine worked

  @built
  Scenario: jump focuses a claude session's terminal window/tab  (resolution + tty-read ran live)
    Given each session has a tty (ttysNNN) and a terminal (iTerm2/Terminal)
    When `apple-energy jump <pid|tty|version|project-substring>` runs
    Then it resolves the target against every claude session; a unique match is focused via
      the terminal's OWN AppleScript verbs (iTerm2 select session/tab/window + activate;
      Terminal set selected + set frontmost) — NOT System Events keystrokes, so it's window
      management, not a UI hijack (and Esa explicitly asked for the focus change)
    And an ambiguous target (e.g. a version shared by 5 sessions) lists the matches and asks
      for a unique PID/tty instead of guessing; a no-match prints a pointer to `claude`
    # cite: bin/apple-energy cmd_jump(); ran live — ambiguous/no-match paths + a read-only
    #       osascript probe confirmed iTerm2/Terminal expose `tty of session` as /dev/ttysNNN

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
