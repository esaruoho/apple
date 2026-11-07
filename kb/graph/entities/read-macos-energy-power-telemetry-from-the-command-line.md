---
name: Read macOS energy & power telemetry from the command line
slug: read-macos-energy-power-telemetry-from-the-command-line
kind: feature
confidence: 0.6
updated: 2026-11-02
---

## Summary
Convey feature: features/apple-energy.feature.

## Claims
- Scenario (L45): now prints a no-sudo snapshot of top apps by energy impact (ran live)
- Scenario (L64): watch samples powermetrics over a window and ranks per-process energy
- Scenario (L76): power reports actual system watts, not relative units (ran live, headers)
- Scenario (L83): adapter prints wattage + battery state, no sudo (ran live)
- Scenario (L92): claude enumerates running Claude Code sessions by version (ran live)
- Scenario (L107): claude TTYs are Cmd-clickable to jump to the session (registration ran live)
- Scenario (L123): the aejump handler sends the AppleEvent directly (TCC-correct) (diagnosed live)
- Scenario (L137): now is a proper 4-column table, not a freeform blob (ran live)
- Scenario (L148): claude and now render as Unicode box-drawing tables (ran live)
- Scenario (L158): claude/now/jump show the SESSION NAME, not just the project (ran live)
- Scenario (L175): jump focuses a claude session's terminal window/tab (resolution + tty-read ran live)
- Scenario (L188): heat frames watts AS heat and shows the thermal drivers (ran live, no-sudo part)
- Scenario (L200): kill SIGTERMs a hog now but refuses critical processes (ran live)
- Scenario (L210): off finds the launchd job, dry-runs by default, disables on --yes (dry-run ran live)
- Scenario (L223): power POLICY is out of bounds
- Scenario (L228): same capability is reachable as a zero-roundtrip slash

## Relationships
