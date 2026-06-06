# Session — voicebox-worker crash-durability (the 7 stranded Bearden sentences)

Faithful, not flattering. Audit trail for `voicebox-worker.feature`.

## How to get back

- Transcript: `file:///Users/esaruoho/.claude/projects/-Users-esaruoho-work-convey/36ad5654-1255-4044-914c-1d6426760bf8.jsonl`
- Session ID: `36ad5654-1255-4044-914c-1d6426760bf8`
- Resume: `claude --resume 36ad5654-1255-4044-914c-1d6426760bf8`
- When: 2026-06-06 EEST, ~18:30–23:10 (a continued/compacted session; the worker work is its tail)
- Project cwd: `/Users/esaruoho/work/convey` (the work touched `~/work/apple` + `~/work/comms` + the Mini)

## The request, and how it sharpened

It started as "finish the Bearden render" (153 sentences, cloned Tom Bearden voice,
profile `86111f10-…`). I reported it done. It was not — and the user's later one-liner
was exact: **"make voiceboxworker requeue stale inflight."** That's the unit this card
covers: the durability gap the render exposed.

## The incident (why this exists)

I claimed the render complete on `pending=0`. Checking honestly: 7 inbox files were
`*.json.inflight` with **no WAVs**. The worker claims a job by renaming `<id>.json` →
`<id>.json.inflight` *before* synth (so Syncthing won't reflow it mid-process), but
`claim_jobs()` only ever scans `.json`/`.txt`. So a job the worker died on was stranded
forever, and `pending` (which counts only unclaimed `.json`) read 0 — the orphan
**masqueraded as done.** That made my "complete" a lie.

Re-queueing the 7 manually (`mv .inflight → .json`) rendered 6. One — a 38-char fragment
`"It would be nice if broken symmetry in\n"` — kept failing. The worker log showed it
`start` three times (2026-06-04, then twice on 06-06), each immediately followed by a
worker `boot`: a no-SSE-progress synth starved the heartbeat, the guardian kickstarted
the worker ~57s in (before the 240s synth budget), and the job re-orphaned. **Stripping
the trailing newline rendered it in ~88s** → clean 153/153. (narrate's `split_sentences`
already `.strip()`s, so this was a stale pre-strip job; the lesson is about the WORKER's
durability, not narrate.)

## What I built

`recover_inflight()` — runs once at boot, re-queues every `.inflight` to its original
name, with a per-job recovery counter (`.inflight-recoveries.json`, auto-pruned to only
still-orphaned jobs) that caps retries at `MAX_INFLIGHT_RECOVERIES` (default 2). Past the
cap → `voicebox-failed/` with a `_worker_error`. The cap is the whole point: without it, a
poison input loops boot→claim→die→boot forever and freezes the queue.

## Decisions (and one I corrected)

- **Cap, not infinite retry.** My first instinct was "just re-queue orphans." That alone
  would have turned the trailing-newline poison into an endless worker-restart loop. The
  cap + give-up-to-failed is what makes it safe.
- **Never rewrite `.txt` content.** Only JSON specs get the `_worker_error` annotation;
  a `.txt` job is re-queued verbatim (a JSON stub would have destroyed its text).
- **Recovery at boot only.** An `.inflight` created by the *currently running* worker is
  actively being processed — not an orphan. Only `.inflight` present *at startup* is, by
  definition, abandoned.
- **State auto-prunes.** `.inflight-recoveries.json` keeps only keys still orphaned this
  boot, so a job that succeeds after one recovery doesn't carry a stale count.

## Verified vs not

- **Recovery logic — verified-live on the Mini (Python 3.9.6), temp queue:** fresh orphan
  re-queued; poison (prior count 2) → `voicebox-failed/` + error; `.txt` content intact;
  state pruned. Also a 3-case unit test on the laptop + `py_compile`.
- **Deploy — verified:** `apple` doesn't Syncthing-sync, so `scp`'d to the Mini; grep
  confirms the code landed (3 matches); LaunchAgent `com.esa.voicebox-worker` kickstarted
  (boot 20:08:54Z); queue clean at 153/153, so recovery ran with nothing to recover.
- **NOT verified:** a real crash-mid-synth → boot-recovery → successful re-render in
  production (I proved the function, not a full live crash-and-recover cycle). The two
  `@caveat`s in the card (pending masquerade between boots; guardian killing before the
  synth budget) are honest known sharp edges, not fixed here.
- Process hygiene: orphan ssh/watcher check after the background watchers — clean.

## Possible next turns

- **Continuous reaper:** age out `.inflight` older than N minutes mid-run (not only at
  boot), so a stranded job is recovered without waiting for a restart.
- **Heartbeat during a no-progress synth** so the guardian waits out the 240s budget
  instead of kickstarting at ~57s (removes the root cause, not just the backstop).
- A standalone `voicebox-worker --recover` flag to force a recovery pass on demand.
