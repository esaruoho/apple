# Voicebox on CloudcityMacMini — Walk-Up Onboarding

You walked up to the Mini. Monitor's awake. This folder is on your Desktop. Follow the steps top-to-bottom. Each `.command` file is double-clickable; each `.webloc` opens a Safari tab.

The end state: a daemon on this Mini is watching `~/work/comms/queue/voicebox-inbox/` via Syncthing. Anything dropped there from RayMac (or anywhere else) gets synthesised to WAV by Voicebox and returned via Syncthing.

**Where we are right now (live status, do not assume):**

- ✅ Voicebox.app v0.5.0 is installed and running on port 17493
- ✅ The voicebox-worker LaunchAgent is bootstrapped and polling the queue
- ❌ **No Qwen3-TTS model has been downloaded yet** (`model_loaded: false`)
- ❌ **No voice profile exists yet** (`/profiles` returns `[]`)
- ❌ The smoke-test job is in the inbox but cannot synth until (1) and (2) are done

Phases 1-2 below are the two GUI steps in Voicebox.app that can't be done over SSH. After that, everything is automatic.

---

## Phase 1 — Download a Qwen3-TTS model (~5-30 min depending on size)

1. **Open Voicebox.app on the Mini** (already running; check the Dock).
2. In Voicebox, navigate to **Models** (or **Settings → Models** — wording may vary by build).
3. Pick **Qwen TTS 0.6B** (smaller, faster, ~600 MB) **or** **Qwen TTS 1.7B** (better quality, ~2 GB). For first run: **0.6B is fine.**
4. Click **Download**. Wait for it to finish.
5. Click **Load** on the same model so `model_loaded` flips to `true`.

Verify via Safari tab 3 (`http://127.0.0.1:17493/health`) — `"model_loaded": true` after this step.

---

## Phase 2 — Create a voice profile (~1 minute)

A "profile" is what Voicebox calls a voice identity. You can either pick a stock one or clone from audio.

**Easiest path (stock voice):**

1. In Voicebox, navigate to **Profiles** (or **Voices**).
2. Create a new profile, give it the name **`default`** (the worker defaults to this name — keep it simple for the smoke test).
3. Pick any built-in voice character / sample if the UI offers them. Save.

**Voice-cloning path (later):** import a 5-15 second clean audio sample of the person you want to clone. Each cloned voice becomes a separate profile, e.g. `schauberger`, `sal`, `russell`. You'll reference these by name from the `voicebox-submit` calls.

Verify via Safari tab 3 — `/profiles` should now return an array with one entry.

---

## Phase 3 — Resubmit the smoke test (5 seconds)

The worker tried to process `smoke-test-001.json` while the model and profile were missing, and it landed in `voicebox-failed/`. Re-submit it:

1. **Double-click `03-Verify-Pipeline.command`.** It'll re-queue the smoke test, then re-check the four checkpoints. You should hear the synthesised WAV play.

---

## Phase 4 — Live tail (optional, leave open as a dashboard)

**Double-click `04-Tail-Worker-Log.command`** for a live JSONL stream of every job processed.

---

## Troubleshooting

| Symptom | Where to look |
|---|---|
| `model_loaded: false` after Phase 1 | Re-open Voicebox → Models → click **Load** explicitly |
| `Profile not found` in worker log | Phase 2 wasn't done, or profile name in job spec ≠ profile name in Voicebox. Rename or use `default`. |
| Worker not picking up jobs | `launchctl print gui/$(id -u)/com.esa.voicebox-worker` — should show `state = running` |
| To restart the worker | `launchctl kickstart -k gui/$(id -u)/com.esa.voicebox-worker` |
| To stop the worker | `launchctl bootout gui/$(id -u)/com.esa.voicebox-worker` |
| Voicebox app crashed | Re-launch Voicebox.app. Worker auto-reconnects on next poll. |

---

## What this gives you

Once Phases 1-2 are green, any synced Mac can:

- `voicebox-submit --text "..."` → WAV returns via Syncthing
- Right-click `.txt`/`.md` in Finder → **Quick Actions → Turn into Voice** → same pipeline
- `/show schauberger` captions synthesise on the Mini, not on your laptop
- `voices.yaml` content-addressed clips (the `%&/<id>%&/` sigil future) all flow through here

The Mini becomes the voice farm. Your laptop never loads Qwen3 weights again.

## API reference (for the curious)

Voicebox v0.5.0 endpoints used:

- `GET /health` — model & GPU status
- `GET /profiles` — list voice profiles
- `GET /models/status` — list available + downloaded models
- `POST /generate` — body `{text, profile_id, engine, language}`, returns `{id}`
- `GET /generate/{id}/status` — SSE stream, terminal event `{"status":"completed"}`
- `GET /audio/{id}` — WAV bytes

The worker (`/Users/esaruoho/work/apple/bin/voicebox-worker.py`) wraps all of this. To change the default engine or profile name across all jobs, edit the `VOICEBOX_DEFAULT_ENGINE` / `VOICEBOX_DEFAULT_PROFILE` env vars in the LaunchAgent plist.
