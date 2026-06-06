#!/usr/bin/env python3
"""
voicebox-worker — polls ~/work/comms/queue/voicebox-inbox/ for job specs,
runs each through the local Voicebox at http://127.0.0.1:17493, writes the
resulting WAV to ~/work/comms/queue/voicebox-results/.

Runs on CloudcityMacMini (where Voicebox lives). Syncthing mirrors the queue
folders to/from the submitting host so this worker never needs SSH or HTTP
from outside the LAN.

  voicebox-worker.py                 # run forever
  voicebox-worker.py --once          # process pending then exit (testing)
  voicebox-worker.py --status        # print queue state and exit

Job spec (JSON file in inbox):
  {
    "id": "schauberger-water-spiral-01",
    "text": "...",
    "profile": "Heart",
    "engine": "kokoro",
    "language": "en"          // optional
  }

After processing each job:
  - WAV moved to voicebox-results/<id>.wav
  - Job spec moved to voicebox-processed/<id>.json
  - Heartbeat written to voicebox-heartbeat.json
  - One line appended to voicebox-log.jsonl
  - On failure: job spec moved to voicebox-failed/<id>.json with error appended
"""
# FEATURE-CARD >> features/voicebox-worker.feature  (spec + grades + session)
import json
import os
import shutil
import socket
import sys
import time
import urllib.request
from pathlib import Path

HOST = socket.gethostname().split(".")[0]

QUEUE = Path(os.environ.get(
    "VOICEBOX_QUEUE",
    str(Path.home() / "work/comms/queue"),
))
INBOX     = QUEUE / "voicebox-inbox"
RESULTS   = QUEUE / "voicebox-results"
PROCESSED = QUEUE / "voicebox-processed"
FAILED    = QUEUE / "voicebox-failed"
HEARTBEAT = QUEUE / "voicebox-heartbeat.json"
LOG       = QUEUE / "voicebox-log.jsonl"

VB = os.environ.get("VOICEBOX_URL", "http://127.0.0.1:17493")
POLL_SECONDS = float(os.environ.get("VOICEBOX_POLL_SECONDS", "2"))

# A job is renamed <name>.inflight while it is being synthed (so Syncthing won't
# reflow it). If the worker dies mid-synth (crash, or the guardian kickstarts it
# because a hung synth starved the heartbeat), that .inflight is stranded — it is
# never re-scanned. recover_inflight() re-queues such orphans at boot, capped so a
# poison input that crashes/hangs synth EVERY time can't wedge the queue in an
# endless boot→claim→die→boot loop; after the cap it goes to voicebox-failed/.
INFLIGHT_SUFFIX = ".inflight"
RECOVERY_STATE = QUEUE / "voicebox-inbox" / ".inflight-recoveries.json"
MAX_INFLIGHT_RECOVERIES = int(os.environ.get("VOICEBOX_MAX_INFLIGHT_RECOVERIES", "2"))


def log_event(event: dict):
    event["ts"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    line = json.dumps(event, ensure_ascii=False)
    with LOG.open("a") as f:
        f.write(line + "\n")
    print(line, flush=True)


def heartbeat(state: dict):
    state["host"] = HOST  # so fleet peers attribute this service to its real machine
    state["ts"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    tmp = HEARTBEAT.with_suffix(".tmp")
    tmp.write_text(json.dumps(state, indent=2, ensure_ascii=False))
    tmp.replace(HEARTBEAT)


_PROFILE_CACHE = {}  # name (lowercase) -> uuid


def resolve_profile(name_or_id: str) -> str:
    """Accept either a profile UUID or a human-readable profile name; return the UUID.

    Voicebox v0.5.0's POST /generate requires UUID. Cached so we hit /profiles at
    most once per worker boot per profile name.
    """
    # If it already looks like a UUID, pass through
    if len(name_or_id) == 36 and name_or_id.count("-") == 4:
        return name_or_id
    key = name_or_id.lower()
    if key in _PROFILE_CACHE:
        return _PROFILE_CACHE[key]
    try:
        with urllib.request.urlopen(VB + "/profiles", timeout=5) as r:
            profiles = json.loads(r.read())
        for p in profiles:
            _PROFILE_CACHE[p["name"].lower()] = p["id"]
    except Exception as e:
        raise RuntimeError(f"could not list /profiles to resolve '{name_or_id}': {e}")
    if key not in _PROFILE_CACHE:
        available = sorted({p["name"] for p in profiles}) if profiles else []
        raise RuntimeError(f"profile '{name_or_id}' not found. available: {available or 'none — create one first'}")
    return _PROFILE_CACHE[key]


def voicebox_synth(text: str, profile_id_or_name: str, engine: str, language: str = "en") -> bytes:
    """Synth text → WAV bytes via local Voicebox v0.5.0 (Qwen3-TTS API).

    Raises RuntimeError on failure. Endpoint: POST /generate with GenerationRequest.
    """
    profile_uuid = resolve_profile(profile_id_or_name)
    body = {"text": text, "profile_id": profile_uuid, "engine": engine}
    if language:
        body["language"] = language
    req = urllib.request.Request(
        VB + "/generate", method="POST",
        headers={"Content-Type": "application/json"},
        data=json.dumps(body).encode(),
    )
    resp = json.loads(urllib.request.urlopen(req, timeout=30).read())
    gen_id = resp.get("id")
    if not gen_id:
        raise RuntimeError(f"no id in /speak response: {resp}")

    # Hard wall-clock budget per generation. The status SSE streams "generating"
    # every ~1s and only closes on completed/failed — so if a generation STALLS
    # server-side (e.g. chatterbox stuck loading the model), the stream never
    # ends. We MUST be able to escape an endless stream, or one stuck job freezes
    # the whole queue (this is the hang we are fixing). Bounded + cancel + move on.
    timeout_s = float(os.environ.get("VOICEBOX_SYNTH_TIMEOUT", "240"))
    deadline = time.time() + timeout_s
    completed = False
    last_status = None
    while time.time() < deadline:
        try:
            with urllib.request.urlopen(f"{VB}/generate/{gen_id}/status", timeout=15) as r:
                for raw in r:
                    if time.time() > deadline:      # escape a never-terminating stream
                        break
                    line = raw.decode().strip()
                    if not line.startswith("data:"):
                        continue
                    ev = json.loads(line[5:].strip())
                    st = ev.get("status")
                    last_status = st
                    if st == "completed":
                        completed = True
                        break
                    if st == "failed":
                        raise RuntimeError(f"voicebox synth failed: {ev}")
        # Py3.9: socket.timeout / TimeoutError are NOT URLError subclasses — catch all
        # transient read failures and retry within the budget instead of dying.
        except (urllib.error.URLError, socket.timeout, TimeoutError):
            time.sleep(2)
            continue
        if completed:
            break
        time.sleep(0.5)
    if not completed:
        _cancel_generation(gen_id)
        raise RuntimeError(
            f"synth timed out after {int(timeout_s)}s (last status: {last_status}); "
            f"cancelled generation {gen_id} so the queue keeps moving")

    with urllib.request.urlopen(f"{VB}/audio/{gen_id}", timeout=60) as r:
        return r.read()


def _cancel_generation(gen_id: str) -> None:
    """Best-effort cancel of a stalled generation so Voicebox frees up. Never raises."""
    try:
        req = urllib.request.Request(f"{VB}/generate/{gen_id}/cancel", method="POST")
        urllib.request.urlopen(req, timeout=10).read()
    except Exception:
        pass


def process_one(job_path: Path):
    """Process a single job spec file. Returns (ok, message)."""
    try:
        spec = json.loads(job_path.read_text())
    except Exception as e:
        return False, f"unparseable job spec: {e}"

    job_id = spec.get("id") or job_path.stem
    text = (spec.get("text") or "").strip()
    if not text:
        return False, "empty text"
    # v0.5.0 uses profile_id; accept legacy "profile" too. Default profile
    # name comes from env so the worker can be moved between Voicebox installs
    # without per-job edits.
    profile_id = spec.get("profile_id") or spec.get("profile") or os.environ.get("VOICEBOX_DEFAULT_PROFILE", "default")
    engine = spec.get("engine") or os.environ.get("VOICEBOX_DEFAULT_ENGINE", "qwen")
    language = spec.get("language") or "en"

    log_event({"event": "start", "id": job_id, "chars": len(text),
               "profile_id": profile_id, "engine": engine, "language": language})

    t0 = time.time()
    try:
        wav_bytes = voicebox_synth(text, profile_id, engine, language)
    except Exception as e:
        return False, str(e)
    elapsed = round(time.time() - t0, 2)

    # Write WAV atomically
    out = RESULTS / f"{job_id}.wav"
    tmp = out.with_suffix(".wav.tmp")
    tmp.write_bytes(wav_bytes)
    tmp.replace(out)

    log_event({"event": "done", "id": job_id, "bytes": len(wav_bytes),
               "elapsed_s": elapsed, "result": str(out)})
    return True, str(out)


def claim_jobs():
    """Yield job spec files in the inbox, oldest first."""
    if not INBOX.exists():
        return []
    jobs = []
    for p in INBOX.iterdir():
        if p.is_file() and p.suffix in {".json", ".txt"} and not p.name.startswith("."):
            jobs.append(p)
    jobs.sort(key=lambda p: p.stat().st_mtime)
    return jobs


def ensure_dirs():
    for d in (INBOX, RESULTS, PROCESSED, FAILED):
        d.mkdir(parents=True, exist_ok=True)


def status_report():
    ensure_dirs()
    pending = len(claim_jobs())
    done = len(list(RESULTS.glob("*.wav")))
    failed = len(list(FAILED.glob("*.json")))
    proc = len(list(PROCESSED.glob("*.json")))
    print(f"inbox    : {INBOX}  ({pending} pending)")
    print(f"results  : {RESULTS}  ({done} WAVs)")
    print(f"processed: {PROCESSED}  ({proc} jobs)")
    print(f"failed   : {FAILED}  ({failed} jobs)")
    print(f"voicebox : {VB}")
    if HEARTBEAT.exists():
        age = int(time.time() - HEARTBEAT.stat().st_mtime)
        print(f"heartbeat: {age}s ago")
    else:
        print("heartbeat: never")


def recover_inflight():
    """Re-queue jobs orphaned as <name>.inflight by a worker that died mid-synth.

    Runs once at boot. Any .inflight present at startup is by definition orphaned
    (a fresh worker is starting, so nothing is actively processing it). Each is
    re-queued to its original name so it's retried — but a per-job recovery count
    (persisted in .inflight-recoveries.json, auto-pruned to only currently-orphaned
    jobs) caps retries at MAX_INFLIGHT_RECOVERIES. Past the cap the job is moved to
    voicebox-failed/ with an error, so one poison input can't restart the worker
    forever and freeze the whole queue.
    """
    if not INBOX.exists():
        return
    orphans = sorted(p for p in INBOX.glob("*" + INFLIGHT_SUFFIX) if not p.name.startswith("."))
    if not orphans:
        return
    try:
        old_counts = json.loads(RECOVERY_STATE.read_text()) if RECOVERY_STATE.exists() else {}
    except Exception:
        old_counts = {}
    new_counts = {}  # only keys still orphaned survive → auto-prunes succeeded jobs
    for p in orphans:
        original = p.with_name(p.name[: -len(INFLIGHT_SUFFIX)])  # foo.json.inflight -> foo.json
        key = original.name
        n = int(old_counts.get(key, 0)) + 1
        job_id = original.stem
        try:
            spec = json.loads(p.read_text())
            job_id = spec.get("id") or job_id
        except Exception:
            spec = None  # not JSON (e.g. a .txt job) — never rewrite its content
        if n > MAX_INFLIGHT_RECOVERIES:
            FAILED.mkdir(parents=True, exist_ok=True)
            if spec is not None:
                spec["_worker_error"] = (
                    f"orphaned in-flight {n}x — the worker died mid-synth every time "
                    f"(likely a poison input that hangs or crashes Voicebox). Given up "
                    f"so the queue keeps moving; fix the input and resubmit.")
                try:
                    p.write_text(json.dumps(spec, indent=2, ensure_ascii=False))
                except Exception:
                    pass
            try:
                p.rename(FAILED / original.name)
                log_event({"event": "inflight_giveup", "id": job_id, "recoveries": n,
                           "detail": "moved to voicebox-failed to keep the queue moving"})
            except Exception as e:
                log_event({"event": "recover_move_failed", "id": job_id, "error": str(e)})
                new_counts[key] = n  # keep it; try again next boot
        else:
            try:
                p.rename(original)
                new_counts[key] = n
                log_event({"event": "inflight_recovered", "id": job_id, "recoveries": n,
                           "detail": "re-queued after the worker died mid-synth"})
            except Exception as e:
                log_event({"event": "recover_move_failed", "id": job_id, "error": str(e)})
    try:
        if new_counts:
            RECOVERY_STATE.write_text(json.dumps(new_counts, indent=2))
        elif RECOVERY_STATE.exists():
            RECOVERY_STATE.unlink()
    except Exception:
        pass


def main():
    once = "--once" in sys.argv
    if "--status" in sys.argv:
        status_report()
        return
    if "-h" in sys.argv or "--help" in sys.argv:
        sys.stderr.write(__doc__)
        sys.exit(2)

    ensure_dirs()
    log_event({"event": "boot", "voicebox": VB, "queue": str(QUEUE)})
    recover_inflight()  # re-queue jobs an earlier worker died on (capped)

    while True:
        jobs = claim_jobs()
        heartbeat({"pending": len(jobs), "voicebox": VB})

        for job_path in jobs:
            # Take it out of the inbox first so Syncthing doesn't reflow it mid-process
            stage = job_path.with_suffix(job_path.suffix + ".inflight")
            try:
                job_path.rename(stage)
            except FileNotFoundError:
                continue

            ok, msg = process_one(stage)
            target_dir = PROCESSED if ok else FAILED
            target = target_dir / job_path.name
            try:
                if not ok:
                    # Append error sidecar
                    try:
                        spec = json.loads(stage.read_text())
                    except Exception:
                        spec = {}
                    spec["_worker_error"] = msg
                    stage.write_text(json.dumps(spec, indent=2, ensure_ascii=False))
                stage.rename(target)
            except Exception as e:
                log_event({"event": "move_failed", "id": job_path.stem, "error": str(e)})

            if not ok:
                log_event({"event": "fail", "id": job_path.stem, "error": msg})

        if once:
            break
        time.sleep(POLL_SECONDS)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        log_event({"event": "shutdown", "reason": "SIGINT"})
