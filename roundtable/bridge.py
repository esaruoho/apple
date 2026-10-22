"""Text-folder intake for the existing Convey Sages roundtable.

REPORT-CARD >> features/aimeat-roundtable.feature
No inference engine lives here: Convey owns the panel, source grounding and lore.
"""
from __future__ import annotations

import argparse
import asyncio
import fcntl
import hashlib
import json
import os
from pathlib import Path
import signal
import socket
import sys
import tempfile
import time
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_FOLDER = Path.home() / "work/merlib-dump/aimeat"
DEFAULT_CONVEY = Path.home() / "work/convey/bin/convey"
SEATS = "all"
SCHEMA = "aimeat-roundtable/1"
RETURN_ROOT = Path.home() / "work/comms/queue/aimeat-roundtable-results"


def require_mini() -> str:
    host = socket.gethostname().split(".")[0].lower()
    if host not in {"cloudcity", "cloudcitymacmini"}:
        raise RuntimeError("Roundtable compute is CloudcityMacMini-only. Drop the text in the synced AIMEAT folder; do not run this worker on the laptop.")
    return host


def fold_roster(text: str) -> str:
    """Materialize folded YAML prose for Convey's dependency-free roster reader.

    Its fallback reader treats `stance: >-` as the literal stance. Keep the
    canonical Sages file untouched and derive a readable transport projection.
    """
    lines, out, i = text.splitlines(), [], 0
    while i < len(lines):
        line = lines[i]
        i += 1
        if line.strip().startswith("stance:") and line.strip().split(":", 1)[1].strip() in {">", ">-", "|", "|-"}:
            indent = len(line) - len(line.lstrip())
            prose = []
            while i < len(lines) and (not lines[i].strip() or len(lines[i]) - len(lines[i].lstrip()) > indent):
                prose.append(lines[i].strip())
                i += 1
            line = " " * indent + "stance: " + " ".join(p for p in prose if p)
        out.append(line)
    return "\n".join(out) + "\n"


def prepare_roster(convey: Path) -> list[str]:
    sys.path.insert(0, str(convey.resolve().parents[1]))
    from convey import roster
    directory = roster.roster_dir()
    source = directory / "sages.yaml"
    if not source.is_file():
        raise RuntimeError("Canonical Sages roster is missing")
    # The full bench is canonical when present. Older Minis have Sages and
    # Classic separately: combine those without duplicating shared seats.
    sources = [directory / "all.yaml"] if (directory / "all.yaml").exists() else [source, directory / "classic.yaml"]
    people = {}
    for path in sources:
        if path.exists():
            for person in roster._parse_roster(fold_roster(path.read_text()))["participants"]:
                people.setdefault(person["name"], person)
    if not people:
        raise RuntimeError("Installed full-bench roster has no participants")
    lines = ["# Generated from the installed full bench; edit the original rosters.", "name: aimeat-sages", "participants:"]
    for person in people.values():
        lines.append(f"  - name: {person['name']}")
        person["brain"] = "mlx"  # This service is explicitly a Qwen/MLX panel.
        # Resolve a legacy home-directory skill alias from installed locations.
        if person.get("knows") and not Path(person["knows"]).expanduser().is_file():
            aliases = [Path.home() / ".agents/skills/rhythmic-balanced-interchange/SKILL.md",
                       Path.home() / ".codex/skills/rhythmic-balanced-interchange/SKILL.md",
                       Path.home() / "work/apple/roundtable/corpora/russell.md"] if person["name"] == "Russell" else []
            for alias in aliases:
                if alias.is_file():
                    person["knows"] = str(alias)
                    break
        for key in ("voice", "brain", "knows", "stance"):
            if person.get(key):
                lines.append(f"    {key}: {person[key]}")
    text = "\n".join(lines) + "\n"
    derived = directory / "aimeat-sages.yaml"
    if not derived.exists() or derived.read_text() != text:
        atomic_text(derived, text)
    return list(people)


def atomic_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(prefix="." + path.name, dir=path.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as out:
            out.write(text)
            out.flush()
            os.fsync(out.fileno())
        os.replace(tmp, path)
    finally:
        if os.path.exists(tmp):
            os.unlink(tmp)


def write_json(path: Path, value: dict) -> None:
    atomic_text(path, json.dumps(value, ensure_ascii=False, indent=2) + "\n")


def read_json(path: Path) -> dict:
    return json.loads(path.read_text()) if path.exists() else {}


def sections(text: str, limit: int = 6000) -> list[tuple[int, int, str]]:
    """Lossless, explicit character ranges; never silently discard the tail."""
    parts, start = [], 0
    while start < len(text):
        end = min(len(text), start + limit)
        if end < len(text):
            newline = text.rfind("\n", start + limit // 2, end)
            if newline >= 0:
                end = newline + 1
        parts.append((start, end, text[start:end]))
        start = end
    return parts


def candidates(folder: Path, stable_seconds: float) -> list[Path]:
    now = time.time()
    return [p for p in sorted(folder.iterdir())
            if p.is_file() and not p.is_symlink() and not p.name.startswith(".")
            and p.suffix.lower() == ".txt"
            and not p.name.lower().endswith((".text.txt", ".transcript.txt", ".speakers.txt"))
            and now - p.stat().st_mtime >= stable_seconds]


def job_for(source: Path, data: bytes, seats: str, turns: int) -> tuple[Path, dict]:
    sha = hashlib.sha256(data).hexdigest()
    jid = hashlib.sha256(json.dumps([source.name, sha, seats, turns]).encode()).hexdigest()[:24]
    directory = source.parent / ".roundtable" / jid
    state = read_json(directory / "state.json") or {
        "schema": SCHEMA, "id": jid, "source": source.name, "sha256": sha,
        "seats": seats, "turns_per_section": turns, "status": "queued",
        "completed": [], "attempts": 0, "created": time.time(),
    }
    return directory, state


def output_paths(source: Path) -> tuple[Path, Path]:
    return source.with_name(source.name + ".roundtable.md"), source.with_name(source.name + ".roundtable.json")


def collect(folder: Path, returns: Path = RETURN_ROOT) -> int:
    """File verified returned artifacts. No model imports or inference on the client."""
    sys.path.insert(0, str(ROOT / 'shared'))
    from aimeat_mail import collect as collect_mail
    copied = collect_mail(folder)
    for path in sorted(returns.glob("*/state.json")):
        try:
            state = read_json(path)
            name = state["source"]
            if state.get("schema") != SCHEMA or Path(name).name != name:
                continue
            source = folder / name
            if source.is_symlink() or not source.is_file():
                continue
            if hashlib.sha256(source.read_bytes()).hexdigest() != state["sha256"]:
                continue
            markdown = (path.parent / "transcript.md").read_bytes()
            if hashlib.sha256(markdown).hexdigest() != state.get("result_sha256"):
                continue  # the other half of this update has not synced yet
            result, status = output_paths(source)
            old = read_json(status)
            if old.get("created", 0) > state["created"]:
                continue
            if old == state and result.exists() and result.read_bytes() == markdown:
                continue
            atomic_text(result, markdown.decode("utf-8"))
            write_json(status, state)
            copied += 1
        except (OSError, ValueError, KeyError, TypeError):
            continue  # partial Syncthing updates are retried at the next tick
    return copied


def render(source: Path, job: Path, state: dict) -> None:
    lines = [f"# Roundtable — {source.name}", "",
             "AI-generated persona interpretations grounded in the configured corpora.",
             "These are not quotations or statements by the historical people.", "",
             f"Status: **{state['status']}** · Panel: {state['seats']} · Brain: Qwen via MLX",
             f"Source SHA-256: `{state['sha256']}`", "",
             f"Sections completed: {len(state['completed'])}/{state.get('sections', 0)}", ""]
    if state.get("error"):
        lines += [f"Processing error: {state['error']}", ""]
    for index, span in enumerate(state.get("ranges", [])):
        events = job / f"section-{index + 1:04}.jsonl"
        if not events.exists():
            continue
        lines += [f"## Section {index + 1} · source characters {span[0]}–{span[1]} (end exclusive)", ""]
        for raw in events.read_text().splitlines():
            try:
                event = json.loads(raw)
            except json.JSONDecodeError:
                continue
            if event.get("type") == "turn":
                lines += [f"### {event['name']}", "", event["text"], ""]
    result, status = output_paths(source)
    # Archive each version; a later revision must not erase its predecessor.
    markdown = "\n".join(lines)
    atomic_text(job / "transcript.md", markdown)
    write_json(job / "state.json", state)
    # merlib-dump is send-only on RayMac. Return artifacts through the two-way
    # comms share; the existing client watcher files them beside the original.
    if state.get("host") in {"cloudcity", "cloudcitymacmini"}:
        returned = dict(state, result_sha256=hashlib.sha256(markdown.encode()).hexdigest())
        atomic_text(RETURN_ROOT / state["id"] / "transcript.md", markdown)
        write_json(RETURN_ROOT / state["id"] / "state.json", returned)
    # Never attach a stale result to source bytes edited while inference was running.
    if source.exists() and hashlib.sha256(source.read_bytes()).hexdigest() == state["sha256"]:
        atomic_text(result, markdown)
        write_json(status, state)


async def stream_section(command: list[str], events: Path, timeout: float, on_turn) -> list[dict]:
    env = dict(os.environ, FM_MLX_HOST="http://127.0.0.1:8080", FM_MLX_RESOLVE_IP="127.0.0.1",
               FM_MLX_NO_SSH="1", PYTHONUNBUFFERED="1")
    proc = await asyncio.create_subprocess_exec(
        *command, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE,
        stdin=asyncio.subprocess.DEVNULL, env=env, start_new_session=True,
        limit=1024 * 1024)
    stderr = asyncio.create_task(proc.stderr.read())
    received = []
    try:
        async with asyncio.timeout(timeout):
            with events.open("w", encoding="utf-8") as out:
                while raw := await proc.stdout.readline():
                    try:
                        event = json.loads(raw)
                    except json.JSONDecodeError:
                        continue  # existing engine may print a diagnostic outside JSONL
                    received.append(event)
                    out.write(json.dumps(event, ensure_ascii=False) + "\n")
                    out.flush()
                    os.fsync(out.fileno())
                    if event.get("type") == "turn":
                        on_turn()
                rc = await proc.wait()
                err = (await stderr).decode(errors="replace")
                if rc:
                    raise RuntimeError(f"roundtable exited {rc}: {err[-1000:]}")
    finally:
        if proc.returncode is None:
            # Bound the whole process tree, including the brain's curl subprocess.
            try:
                os.killpg(proc.pid, signal.SIGTERM)
                await asyncio.wait_for(proc.wait(), 5)
            except asyncio.TimeoutError:
                os.killpg(proc.pid, signal.SIGKILL)
                await proc.wait()
            except ProcessLookupError:
                pass
        if not stderr.done():
            stderr.cancel()
        await asyncio.gather(stderr, return_exceptions=True)
    return received


def running_mlx_model() -> str:
    """Read the already-running Mini server; never select or download weights."""
    with urllib.request.urlopen("http://127.0.0.1:8080/v1/models", timeout=5) as response:
        models = json.load(response).get("data", [])
    if not models or not models[0].get("id"):
        raise RuntimeError("Mini's local MLX server reports no loaded model")
    expected = read_json(Path.home() / "work/comms/queue/mlx-server-heartbeat.json").get("model")
    ids = [model["id"] for model in models if model.get("id")]
    if expected in ids:
        return expected
    if len(ids) == 1:
        return ids[0]
    raise RuntimeError("Mini reports multiple models without a matching worker heartbeat; refusing to select weights")


def verify_panel(convey: Path, seats: str) -> None:
    require_mini()
    prepare_roster(convey)
    # load_roster falls back to classic when the file is missing. Fail explicitly
    # rather than quietly substitute generic personas for the requested figures.
    sys.path.insert(0, str(convey.resolve().parents[1]))
    from convey import roster
    if "sages" not in roster.available():
        raise RuntimeError("Sages roster is not installed on this machine")
    panel = {p["name"]: p for p in roster.load_roster("aimeat-sages", "mlx")}
    for name in (list(panel) if seats == "all" else seats.split(",")):
        if name not in panel:
            raise RuntimeError(f"Sages persona missing: {name}")
        p = panel[name]
        if p["stance"] in {">", ">-", "|", "|-"}:
            raise RuntimeError(f"{name}'s persona prose was not parsed")
        if p["brain"] != "mlx":
            raise RuntimeError(f"{name} is not configured for MLX")
        if name in ("Bearden", "Prigogine", "Russell", "Hilarion"):
            corpus = Path(p.get("knows", "")).expanduser()
            if not corpus.is_file() or not corpus.stat().st_size:
                raise RuntimeError(f"{name}'s grounding corpus is missing: {corpus}")


async def process(source: Path, *, convey: Path = DEFAULT_CONVEY, seats: str = SEATS,
                  turns: int = 0, timeout: float = 1500, retry: bool = False,
                  runner=stream_section, preflight=verify_panel) -> dict:
    if seats == "all":
        require_mini()
        seats = ",".join(prepare_roster(convey))
    turns = turns or 2 * len(seats.split(","))
    if source.is_symlink() or source.suffix.lower() not in (".txt", ".md"):
        raise ValueError("submit a regular UTF-8 .txt or .md file")
    data = source.read_bytes()
    text = data.decode("utf-8-sig")
    if not text.strip():
        raise ValueError("empty text file")
    if len(data) > 1024 * 1024:
        raise ValueError("text exceeds the 1 MiB per-document processing limit")
    job, state = job_for(source, data, seats, turns)
    if state["status"] == "complete":
        state.setdefault("host", socket.gethostname().split(".")[0].lower())
        result, status = output_paths(source)
        missing_return = state["host"] in {"cloudcity", "cloudcitymacmini"} and not (RETURN_ROOT / state["id"] / "state.json").exists()
        if not result.exists() or read_json(status).get("id") != state["id"] or missing_return:
            render(source, job, state)
        return state
    if state["status"] == "failed" and not retry:
        state.setdefault("host", socket.gethostname().split(".")[0].lower())
        if state["host"] in {"cloudcity", "cloudcitymacmini"} and not (RETURN_ROOT / state["id"] / "state.json").exists():
            render(source, job, state)
        return state
    if not retry and state.get("retry_at", 0) > time.time():
        return state
    parts = sections(text)
    state.update(sections=len(parts), ranges=[[a, b] for a, b, _ in parts], host=socket.gethostname().split(".")[0].lower(),
                 status="running", attempts=state["attempts"] + 1, error=None)
    job.mkdir(parents=True, exist_ok=True)
    atomic_text(job / "source.txt", text)
    render(source, job, state)
    try:
        preflight(convey, seats)
        if runner is stream_section:
            os.environ["FM_MLX_MODEL"] = running_mlx_model()
        for index, (start, end, chunk) in enumerate(parts):
            if index in state["completed"]:
                continue
            board = job / f"section-{index + 1:04}.txt"
            atomic_text(board, chunk)
            topic = f"Discuss {source.name}: section {index + 1}/{len(parts)}"
            command = [str(convey), "roundtable", topic, "--roster", "aimeat-sages", "--brain", "mlx",
                       "--seat", seats, "--turns", str(turns), "--no-speak", "--jsonl",
                       "--board", str(board), "--context-budget", "18000",
                       "--inject", "Discuss the supplied source passage specifically. Distinguish its claims from your interpretation. For energy devices, identify the reservoir and open-system coupling first; keep measurement questions specific to the device."]
            events = await runner(command, job / f"section-{index + 1:04}.jsonl", timeout,
                                  lambda: render(source, job, state))
            actual = [e for e in events if e.get("type") == "turn"]
            names = {e.get("name") for e in actual}
            if (len(actual) < turns or not set(seats.split(",")).issubset(names)
                    or not any(e.get("type") == "end" for e in events)):
                errors = [e.get("message", "") for e in events if e.get("type") == "error"]
                detail = "; ".join(errors[-2:])[-1000:]
                raise RuntimeError(f"section {index + 1} incomplete: {len(actual)}/{turns} turns" + (f": {detail}" if detail else ""))
            state["completed"].append(index)
            render(source, job, state)
        state.update(status="complete", finished=time.time(), retry_at=0)
    except Exception as exc:
        state.update(status="failed" if state["attempts"] >= 3 else "retrying",
                     error=f"{type(exc).__name__}: {exc}", retry_at=time.time() + 60 * state["attempts"])
    render(source, job, state)
    return state


def main() -> int:
    ap = argparse.ArgumentParser(description="Drop-folder → grounded MLX roundtable → result beside source")
    ap.add_argument("verb", choices=["watch", "once", "submit", "status", "collect"])
    ap.add_argument("source", nargs="?", type=Path)
    ap.add_argument("--folder", type=Path, default=DEFAULT_FOLDER)
    ap.add_argument("--convey", type=Path, default=DEFAULT_CONVEY)
    ap.add_argument("--seats", default=SEATS)
    ap.add_argument("--turns", type=int, default=0, help="0 = two full panel rounds")
    ap.add_argument("--poll", type=float, default=3)
    ap.add_argument("--stable-seconds", type=float, default=5)
    ap.add_argument("--timeout", type=float, default=1500)
    ap.add_argument("--retry", action="store_true")
    args = ap.parse_args()
    auto_seats = args.seats == "all"
    auto_turns = args.turns == 0
    folder = args.folder.expanduser().resolve()
    if not folder.is_dir():
        ap.error(f"folder does not exist: {folder}")
    if args.verb == "collect":
        count = collect(folder)
        if count:
            print(f"filed {count} returned roundtable result(s)")
        return 0
    if args.verb != "status":
        try:
            require_mini()
            if args.seats == "all":
                args.seats = ",".join(prepare_roster(args.convey))
        except RuntimeError as exc:
            ap.error(str(exc))
    seats = [s.strip() for s in args.seats.split(",") if s.strip()]
    args.seats = ",".join(seats)
    args.turns = args.turns or 2 * len(seats)
    if not seats or len(seats) != len(set(seats)) or args.turns < len(seats) or args.turns > 60:
        ap.error("select distinct seats and between one full panel round and 60 turns")
    if args.poll <= 0 or args.timeout <= 0 or args.stable_seconds < 0:
        ap.error("poll and timeout must be positive; stable-seconds must be nonnegative")
    if args.verb == "status":
        for path in sorted(folder.glob("*.roundtable.json")):
            state = read_json(path)
            print(f"{state['status']:10} {state['source']} {len(state['completed'])}/{state['sections']} sections")
        return 0
    try:
        require_mini()
    except RuntimeError as exc:
        ap.error(str(exc))
    lock_dir = folder / ".roundtable"
    lock_dir.mkdir(exist_ok=True)
    with (lock_dir / ".lock").open("a") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            sys.exit("roundtable intake already running for this folder")
        hb = Path.home() / "work/comms/queue/aimeat-roundtable-heartbeat.json"
        worker_mtime = Path(__file__).stat().st_mtime_ns
        while True:
            paths = [args.source.expanduser().resolve()] if args.verb == "submit" and args.source else candidates(folder, args.stable_seconds)
            if args.verb == "watch":
                sys.path.insert(0, str(ROOT / "shared"))
                from aimeat_mail import merge_mail_inputs
                paths = merge_mail_inputs(paths, args.stable_seconds)
            if args.verb == "submit" and not args.source:
                ap.error("submit requires a source path")
            failed = False
            for path in paths:
                # Status heartbeat remains separate from per-document durable results.
                if args.verb == "watch":
                    write_json(hb, {"schema": SCHEMA, "ts": time.time(), "status": "running", "source": path.name})
                try:
                    state = asyncio.run(process(path, convey=args.convey, seats=SEATS if auto_seats else args.seats,
                                                turns=0 if auto_turns else args.turns, timeout=args.timeout, retry=args.retry))
                    print(f"{state['status']}: {path.name}", flush=True)
                    failed |= state["status"] != "complete"
                except (OSError, UnicodeError, ValueError) as exc:
                    failed = True
                    print(f"rejected {path.name}: {exc}", file=sys.stderr, flush=True)
            if args.verb != "watch":
                return int(failed)
            write_json(hb, {"schema": SCHEMA, "ts": time.time(), "status": "ready", "folder": str(folder)})
            time.sleep(args.poll)
            if Path(__file__).stat().st_mtime_ns != worker_mtime:
                print("Bridge updated; returning to the Cloudcity-Boot wrapper for reload.", flush=True)
                return 0


if __name__ == "__main__":
    raise SystemExit(main())
