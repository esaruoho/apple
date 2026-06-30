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
