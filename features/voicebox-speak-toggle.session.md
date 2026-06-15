# Session — Voicebox speak toggle

Faithful record of the conversation that spawned `features/voicebox-speak-toggle.feature`.

## How to get back
- Transcript: `file:///Users/esaruoho/.claude/projects/-Users-esaruoho-work-apple/b69cc0bd-6106-4ea0-b3a1-d270e860ee6c.jsonl`
- Session ID: `b69cc0bd-6106-4ea0-b3a1-d270e860ee6c`
- Resume: `claude --resume b69cc0bd-6106-4ea0-b3a1-d270e860ee6c`
- Date: 2026-06-15

## The request
Esa: "boot up apple skill. now, please add 'voicebox enable / voicebox disable', onto this
computer, onto apple toolbox, so that i can set it up when i want to and shut it up when i
dont want claude speaking to me. okay?"

## What I found before building
- Claude's spoken responses are produced by the **Claude Code Stop hook**
  `~/.claude/hooks/voicebox_speak.py` (registered in `~/.claude/settings.json`). It grabs the
  last assistant message, POSTs to local Voicebox `:17493`, polls, downloads the WAV, plays it
  with `afplay`. That hook is the single chokepoint for ALL of Claude's speech.
- `~/bin/voicebox-on` / `voicebox-off` already exist but are a **different concept**: the
  server-side speaker-claim gate (`/speak/claim` + `/speak/release`, keyed on
  `VOICEBOX_CLIENT_ID`). Not what Esa asked for — he wants a simple local "talk to me / don't".
- `~/bin/voicebox-stop` cuts whatever is currently playing (kills the afplay PID + POSTs
  `/speak/stop`). AppleToolbox already exposes it as "🔇 Stop Voicebox".

## Decision
Put the switch where the speech actually flows: a state file
`~/.config/voicebox/speak.state` ("on"/"off", missing == on to preserve current behaviour),
read by the Stop hook. A one-line CLI flips it; AppleToolbox shows a live toggle row.

## What I built
1. `bin/voicebox-speak` — `enable|on / disable|off / toggle / status` (+`--quiet`). Disable
   also calls `voicebox-stop` so it goes quiet immediately. status exits 0=on / 1=off.
2. Patched `voicebox_speak.py`: added `speech_enabled()` + an early return in `main()` before
   the health probe. Verified by importing the module and checking both states.
3. AppleToolbox: `claudeSpeechEnabled()` reads the state file; a self-relabelling menu row
   ("🗣️ Claude Speech: ON …" / "🤫 Claude Speech: OFF …") placed under "Stop Voicebox",
   click runs `bin/voicebox-speak toggle --quiet`. Rebuilt + relaunched via `topbar/build.sh`
   (clean compile; warnings present were pre-existing).
4. `commands/voicebox-speak.md` slash + `commands/install.sh` (52 slashes).

## Verification done this session
- CLI: status→ON(rc0), disable→OFF(rc1), toggle→ON, state file contents correct.
- Hook: `python3 -c ast.parse` OK; module import shows `speech_enabled()` False when off,
  True when on.
- Swift: `topbar/build.sh` compiled my additions cleanly, menu-bar relaunched.
- Left state = ON at end of session.

## Not verified (honest grade)
- End-to-end live audio (synthesise → play → disable-mid-turn-stops) needs a running Voicebox
  backend and a real Claude turn. Graded `@untested` on the card.

## v2 — Esa corrected the spec (2026-06-15)
Esa: the toggle isn't enough. "by saying it is on I define that it both works and is on" —
enabling in AppleToolbox must CHECK whether the Voicebox server is on/off and START it if
it's off, then set Claude talking. He shouldn't have to think about the server at all.

Rebuilt:
- `bin/voicebox-speak enable` now calls `~/bin/voicebox-start` when the server is down and
  waits for `/health`. `status` reports flag + server + effective (WILL SPEAK / SILENT).
  `disable` leaves the server running (fast re-enable). `toggle` = effective-on → disable,
  else enable.
- AppleToolbox: added `voiceboxServerUp` cache + `probeVoiceboxServer()` (off-main-thread
  localhost health curl), a `toggleClaudeSpeech` selector that fires enable/disable then
  re-probes a few times, and a 3-state menu row (ON / ON-but-server-down / OFF).

PROVEN live this session:
- killed the real server (was `uvicorn … --host 127.0.0.1 --port 17493`, PID 15784; note the
  `--host` is why `voicebox-status`/`voicebox-start`'s `pgrep 'uvicorn backend.main:app
  --port 17493'` pattern misses it — my detection uses the HTTP /health endpoint, which is
  robust to that). status → "server down / SILENT".
- ran exactly what the toolbox Enable click runs (`voicebox-speak enable --quiet`) → server
  booted in ~4s → status "WILL SPEAK".
- fired the Stop hook → afplay PID 19405 played the WAV. Full chain confirmed.
- Left state ON, server up (Esa's normal setup).

## v3 — companion fix: robust server PID detection (2026-06-15)
Esa: "fix the PGREP thing … robust, functional, no leftovers or dead code … like a human
being would do it when they respect the person they are delivering the fix to."

Audited every place that detects the Voicebox server process:
- `~/bin/voicebox-status:195` — used `pgrep -f 'uvicorn backend.main:app --port 17493'`.
  Brittle: misses `--host 127.0.0.1 --port`, `--reload --port`, `python -m uvicorn` forms.
  FIXED: derive `PORT="${ENDPOINT##*:}"` and find the PID via
  `lsof -nP -iTCP:"$PORT" -sTCP:LISTEN -t | head -1` (whoever holds the port IS the server).
- `~/bin/voicebox-start` — already detects via /health and prints its own `$!`; stop-hint
  "use voicebox-status to find it" now resolves correctly. No change needed.
- `~/work/voicebox/justfile` `pkill -f "uvicorn backend.main:app"` — upstream repo, broad
  match works for all forms; left untouched to avoid upstream merge conflicts.
- `bin/voicebox-speak` (this feature) — already used /health + lsof; correct.

PROVEN: relaunched the server in the `--host 127.0.0.1 --port 17493` form → old pgrep MISS
(no PID), new lsof method found PID 33252; full `voicebox-status` runs clean (exit 0) with the
correct PID. Caveat surfaced honestly: `~/bin` is NOT a git repo, so the voicebox-status fix
is live on disk but not version-controlled — only the report-card note here records it.
