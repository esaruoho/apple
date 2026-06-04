#!/usr/bin/env python3
"""
voicebox-clone-worker — polls ~/work/comms/queue/voicebox-clone-inbox/ for clone
job specs, builds a Voicebox voice profile from the attached recording via the
local Voicebox at http://127.0.0.1:17493, and writes the new profile id/name to
~/work/comms/queue/voicebox-clone-results/.

Runs on CloudcityMacMini (where Voicebox lives). Syncthing mirrors the queue
folders to/from the submitting host, so this worker never needs SSH or outside
HTTP — the mirror of voicebox-worker, but for cloning instead of TTS.

  voicebox-clone-worker.py            # run forever
  voicebox-clone-worker.py --once     # process pending then exit (testing)
  voicebox-clone-worker.py --status   # print queue state and exit

Clone job spec (JSON file in inbox), written by `voicebox-clone`:
  {
    "id": "20260603-...-clone-Bearden",
    "kind": "clone",
    "profile_name": "Bearden",
    "recording": "20260603-...-clone-Bearden.wav",  // file sitting next to the spec
    "reference_text": "what the speaker says in the recording"
  }

Flow per job (Voicebox v0.5.0 API):
  1. POST /profiles            {name}                       -> new profile {id}
  2. POST /profiles/{id}/samples  (multipart: file + reference_text)
  3. write voicebox-clone-results/<id>.json {profile_id, profile_name}

After processing: recording + spec moved to voicebox-clone-processed/ (or
voicebox-clone-failed/ with the error appended). Heartbeat + JSONL log mirror
the TTS worker.
"""
import json
import mimetypes
import os
import socket
import sys
import time
import urllib.error
import urllib.request
import uuid
from pathlib import Path

HOST = socket.gethostname().split(".")[0]

QUEUE = Path(os.environ.get("VOICEBOX_QUEUE", str(Path.home() / "work/comms/queue")))
INBOX     = QUEUE / "voicebox-clone-inbox"
RESULTS   = QUEUE / "voicebox-clone-results"
PROCESSED = QUEUE / "voicebox-clone-processed"
FAILED    = QUEUE / "voicebox-clone-failed"
HEARTBEAT = QUEUE / "voicebox-clone-heartbeat.json"
LOG       = QUEUE / "voicebox-clone-log.jsonl"

VB = os.environ.get("VOICEBOX_URL", "http://127.0.0.1:17493")
POLL_SECONDS = float(os.environ.get("VOICEBOX_POLL_SECONDS", "3"))


def log_event(event: dict):
    event["ts"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    with LOG.open("a") as f:
        f.write(json.dumps(event, ensure_ascii=False) + "\n")
    print(json.dumps(event, ensure_ascii=False), flush=True)


def heartbeat(state: dict):
    state["host"] = HOST
    state["ts"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    tmp = HEARTBEAT.with_suffix(".tmp")
    tmp.write_text(json.dumps(state, indent=2, ensure_ascii=False))
    tmp.replace(HEARTBEAT)


def _post_json(path: str, body: dict) -> dict:
    req = urllib.request.Request(
        VB + path, method="POST",
        headers={"Content-Type": "application/json"},
        data=json.dumps(body).encode(),
    )
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read())


def _post_multipart(path: str, fields: dict, file_field: str, file_path: Path) -> dict:
    """Minimal multipart/form-data POST (stdlib only) for /samples."""
    boundary = f"----voiceboxclone{uuid.uuid4().hex}"
    crlf = b"\r\n"
    body = bytearray()
    for key, value in fields.items():
        body += b"--" + boundary.encode() + crlf
        body += f'Content-Disposition: form-data; name="{key}"'.encode() + crlf + crlf
        body += str(value).encode("utf-8") + crlf
    ctype = mimetypes.guess_type(str(file_path))[0] or "application/octet-stream"
    body += b"--" + boundary.encode() + crlf
    body += (f'Content-Disposition: form-data; name="{file_field}"; '
             f'filename="{file_path.name}"').encode() + crlf
    body += f"Content-Type: {ctype}".encode() + crlf + crlf
    body += file_path.read_bytes() + crlf
    body += b"--" + boundary.encode() + b"--" + crlf
    req = urllib.request.Request(
        VB + path, method="POST",
        headers={"Content-Type": f"multipart/form-data; boundary={boundary}"},
        data=bytes(body),
    )
    with urllib.request.urlopen(req, timeout=120) as r:
        return json.loads(r.read())


def process_one(job_path: Path):
    try:
        spec = json.loads(job_path.read_text())
    except Exception as e:
        return False, f"unparseable job spec: {e}"

    job_id = spec.get("id") or job_path.stem
    name = (spec.get("profile_name") or "").strip()
    rec_name = spec.get("recording") or ""
    reference_text = (spec.get("reference_text") or "").strip()
    if not name:
        return False, "no profile_name"
    if not rec_name:
        return False, "no recording referenced"
    if not reference_text:
        return False, "no reference_text (Voicebox /samples requires it)"
    recording = job_path.parent / rec_name
    if not recording.exists():
        return False, f"recording not synced yet / missing: {recording.name}"

    log_event({"event": "start", "id": job_id, "profile": name,
               "recording": rec_name, "ref_chars": len(reference_text)})
    t0 = time.time()
    try:
        created = _post_json("/profiles", {"name": name})
        profile_id = created.get("id")
        if not profile_id:
            return False, f"no id in POST /profiles response: {created}"
        sample = _post_multipart(
            f"/profiles/{profile_id}/samples",
            {"reference_text": reference_text}, "file", recording,
        )
    except urllib.error.URLError as e:
        return False, f"voicebox not reachable at {VB}: {e}"
    except Exception as e:
        return False, str(e)
    elapsed = round(time.time() - t0, 2)

    out = RESULTS / f"{job_id}.json"
    tmp = out.with_suffix(".json.tmp")
    tmp.write_text(json.dumps({
        "id": job_id, "profile_id": profile_id, "profile_name": name,
        "sample": sample, "elapsed_s": elapsed,
        "speak_with": f'voicebox-submit --profile "{name}" --text "..."',
    }, indent=2, ensure_ascii=False))
    tmp.replace(out)
    log_event({"event": "done", "id": job_id, "profile_id": profile_id,
               "elapsed_s": elapsed, "result": str(out)})
    return True, str(out)


def claim_jobs():
    if not INBOX.exists():
        return []
    jobs = [p for p in INBOX.iterdir()
            if p.is_file() and p.suffix == ".json" and not p.name.startswith(".")]
    jobs.sort(key=lambda p: p.stat().st_mtime)
    return jobs


def ensure_dirs():
    for d in (INBOX, RESULTS, PROCESSED, FAILED):
        d.mkdir(parents=True, exist_ok=True)


def status_report():
    ensure_dirs()
    print(f"clone inbox  : {INBOX}  ({len(claim_jobs())} pending)")
    print(f"clone results: {RESULTS}  ({len(list(RESULTS.glob('*.json')))} built)")
    print(f"voicebox     : {VB}")
    if HEARTBEAT.exists():
        print(f"heartbeat    : {int(time.time() - HEARTBEAT.stat().st_mtime)}s ago")
    else:
        print("heartbeat    : never")


def main():
    once = "--once" in sys.argv
    if "--status" in sys.argv:
        status_report(); return
    if "-h" in sys.argv or "--help" in sys.argv:
        sys.stderr.write(__doc__); sys.exit(2)

    ensure_dirs()
    log_event({"event": "boot", "voicebox": VB, "queue": str(QUEUE)})
    while True:
        jobs = claim_jobs()
        heartbeat({"pending": len(jobs), "voicebox": VB})
        for job_path in jobs:
            stage = job_path.with_suffix(job_path.suffix + ".inflight")
            try:
                job_path.rename(stage)
            except FileNotFoundError:
                continue
            ok, msg = process_one(stage)
            # Move spec + its recording out of the inbox.
            try:
                spec = json.loads(stage.read_text())
            except Exception:
                spec = {}
            target_dir = PROCESSED if ok else FAILED
            if not ok:
                spec["_worker_error"] = msg
                stage.write_text(json.dumps(spec, indent=2, ensure_ascii=False))
            try:
                stage.rename(target_dir / job_path.name)
                rec = spec.get("recording")
                if rec and (INBOX / rec).exists():
                    (INBOX / rec).rename(target_dir / rec)
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
