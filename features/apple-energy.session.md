# Session — apple-energy

The spawning conversation for `bin/apple-energy` (report card: `apple-energy.feature`).

## How to get back

- Session ID: `3c38e0af-b108-435b-9459-2ae431398767`
- Resume: `claude --resume 3c38e0af-b108-435b-9459-2ae431398767`
- Date: 2026-06-30

## The request

Esa forwarded an email from **Dima**:

> "as you've been exploring and expanding MacOS capabilities, have you discovered
> anything on energy consumption? I have this short script to check how powerful is
> power adapter at the moment, but that's about it. And I'd like to know which apps
> consume the most energy over time. Activity Monitor seems to have this kind of
> information, but I was wondering whether it's also available via CLI."

Mid-build, Esa added: *"the short script dima mentions is
`system_profiler SPPowerDataType | grep Wattage` — please apply this as knowledge, too."*

Esa's instruction: **build apple-energy THEN commit THEN draft a reply to Dima** to paste back.

## What was decided

- The Activity Monitor "Energy" tab is a front-end over Apple-shipped CLIs; reproduce it
  with `powermetrics` / `top` / `system_profiler` / `pmset` — no Homebrew, no deps.
- The real gap: macOS exposes **no historical per-app energy store**. "Top apps over
  time" must be sampled + aggregated → that's the `watch` subcommand.
- Four verbs: `now` (no-sudo snapshot via top), `watch` (sudo powermetrics plist →
  python aggregate + rank), `power` (system watts), `adapter` (superset of Dima's line).

## What was verified live

- `now` ran live — ranked WindowServer / Finder / CGPDFService etc. by energy impact.
- `adapter` ran live — 87W adapter, battery 100% / 312 cycles / Normal.
- `watch` parser verified against a synthetic null-separated 2-sample plist
  (Safari 25+35=60, WindowServer 40+10=50 → correctly ranked + percentages).
- The live powermetrics capture (sudo) could NOT be exercised in the non-interactive
  build session — no TTY for sudo to prompt. Graded honestly as @parser-verified.

## Corrections during the build

- First `watch` attempt embedded the python parser via `python3 -c '…'` with
  single-quoted f-strings inside — the inner `'` terminated the bash single-quote and
  bash tried to execute `28}{PID:`. Fixed by capturing powermetrics to a tempfile and
  parsing via a quoted-delimiter heredoc (`<<'PY'`) reading `$APPLE_ENERGY_RAW` — zero
  escaping. (Same heredoc-vs-quoting class of bug as the md-to-clipboard incident.)
- `now` header printed twice (printed on both top listings); fixed to print the header
  only for the second listing.

## Follow-up (2026-07-01): heat + kill + off

Esa ran `apple-energy now` live (M3 Pro), watched Finder/lghub_updater/WindowServer/Renoise
rank, closed some Finder windows and saw the numbers drop, then asked for two more things:

1. *"how much a cpu percentage is resulting in heat"* → new **`heat`** verb. Reframed
   honestly: on a chip ~100% of drawn power becomes heat, so **package watts ARE the
   heat-generation rate** — there is no separate heat number. Apple Silicon (M3 Pro)
   exposes no clean CPU die temp, so `heat` reports the real drivers: `pmset -g therm`
   throttle state (no sudo) + `powermetrics --samplers cpu_power,thermal,smc` package
   power, thermal pressure, and fan RPM (sudo).
2. *"a method of turning something off, like killing the lghub server"* → new **`kill`**
   (SIGTERM now, with a critical-process denylist + pid<50 guard) and **`off`** (find the
   launchd job via PlistBuddy across the 3 LaunchAgents/Daemons dirs, dry-run by default,
   `--yes` runs `launchctl bootout` + `disable` and prints the `enable` undo).

Live-tested this session (no-sudo / non-mutating paths): `heat` no-sudo portion, `kill`
on a throwaway sleep (confirmed dead) + WindowServer refusal + no-match, `off lghub` and
`off lghub_updater` dry-runs (correctly resolved com.logi.ghub.updater as a system
LaunchDaemon, so `--yes` will use sudo). The sudo `heat`/`power`/`watch` capture and the
`off --yes` execution are for Esa to run — no TTY for sudo in the build session.

Design call worth keeping: `off` is **dry-run by default**. `off lghub` matches BOTH the
G HUB tray agent and the updater daemon; showing both before acting stops Esa from nuking
his whole Logitech setup when he only wants the useless updater gone.
