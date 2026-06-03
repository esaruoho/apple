# Session — Directions home ("how do I get home" → Maps) — a Convey

Faithful, not flattering. Audit trail for `directions-home.feature`.

## How to get back

- **Same session** as the dictation / me-address cards:
  `file:///Users/esaruoho/.claude/projects/-Users-esaruoho-work-apple/fde596bb-669f-493a-8a43-04a4e33cd964.jsonl`
- **Bundled transcript (local-only, gitignored):** `features/dictation-button.transcript.jsonl` / `.md`
- **Session ID:** `fde596bb-669f-493a-8a43-04a4e33cd964` · **Resume:** `claude --resume fde596bb-669f-493a-8a43-04a4e33cd964`
- **Card authored:** 2026-06-03 (EEST).

## How this unit was spawned

Esa: *"temperature should only result in 'temp' or 'hot'. this how far away am i from
home is a call for Maps -> Directions to happen. we already have the code in
~/work/ray-graph … 'Launch Direction via URL' via App going. this will be the next
Convey. We Convey the idea of 'how to get home' by mapping Maps to it with the
Directions set-up."*

Two asks:
1. **Narrow the climate trigger** — "temperature" should mean temp/hot, and stop the
   `home` climate action swallowing every phrase with "home" in it.
2. **New Convey** — map "how to get home / how far am I from home" → Apple Maps
   Directions, reusing the ray-graph URL code (don't re-roll).

## What shipped

- `bin/maps-directions` — opens `https://maps.apple.com/?daddr=<home>&dirflg=<w|d|r>`.
  Destination = home (me-address, cached, door-code line stripped); source omitted so
  Maps routes from the current location → distance + ETA. Mode auto-detected from the
  phrase. **Reuses** the pattern from `ray-graph/js/dashboard/dashboard-ui.js`
  `getDirectionsUrl` (dirflg w/d/r) per the reuse-before-rerolling rule.
- `bin/apple-do` — capability `directions`.
- `bin/apple-intent` — `directions` intent; the climate `home` intent narrowed to
  temp/heat/humidity phrasings only. Three "home" senses now separate:
  thermostat (`home`), address (`address`), destination (`directions`).
- `shared/test-intent-routing.sh` — cases added; **passes** (incl. the live miss
  "how far away am i from home" → directions, and "temperature" → home).

## Honest status

- Routing `@verified` (headless test). Maps-URL build hand-verified (printed the URL
  without opening, to avoid foregrounding Maps mid-session); the actual `open` is the
  Apple-native one-liner and runs when Esa triggers it from the bar.
- Address join is slightly rough ("B20,00990 Helsinki Finland"); Maps geocoding is
  tolerant, but the comma placement could be tidied if a route ever misses.
