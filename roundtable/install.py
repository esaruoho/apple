#!/usr/bin/env python3
"""Stage over Syncthing, install on Cloudcity, and declare a visible Boot pane.

REPORT-CARD >> features/aimeat-roundtable.feature
Installation never starts a detached process or restarts Boot by itself.
"""
import argparse
import ast
import hashlib
import json
from pathlib import Path
import shutil
import socket
import subprocess
import sys
import tempfile
import time
import shlex

ROOT = Path(__file__).resolve().parents[1]
WORK = Path.home() / "work"
FILES = ["bin/aimeat-roundtable", "roundtable/bridge.py", "roundtable/install.py",
         "roundtable/convey-roundtable.py.txt"]
SMOKE_TEXT = "Roundtable pipeline check. Consider a greenhouse with an open window: sunlight enters, stored heat changes, and warm air leaves. Discuss how identifying the source, boundary and measurable flows helps distinguish a mechanism from a measurement claim. The source marker is GREENHOUSE-731. Address this specific example rather than a generic introduction.\n"
SERVICE = '''
  # REPORT-CARD >> apple/features/aimeat-roundtable.feature
  - name: aimeat-roundtable
    does: Stable text drops in the synced AIMEAT folder become grounded Sages MLX discussions; results stream beside each source.
    kind: queue-worker
    inbox: merlib-dump/aimeat
    results: comms/queue/aimeat-roundtable-results
    worker: apple/bin/aimeat-roundtable
    pane: while true; do cd /Users/esaruoho/work/apple && /opt/homebrew/bin/python3 bin/aimeat-roundtable watch; sleep 10; done
    launch: pane "AIMEAT Roundtable"
    heartbeat: comms/queue/aimeat-roundtable-heartbeat.json
'''
PANE = '''
		-- REPORT-CARD >> apple/features/aimeat-roundtable.feature
		try
		with timeout of 30 seconds
		set aimeatRoundtableTab to (create tab with default profile)
		set aimeatRoundtableSession to (current session of aimeatRoundtableTab)
		tell aimeatRoundtableSession
			set name to "AIMEAT Roundtable"
			write text "while true; do cd /Users/esaruoho/work/apple && /opt/homebrew/bin/python3 bin/aimeat-roundtable watch; echo '[AIMEAT roundtable exited; restarting in 10s]'; sleep 10; done"
		end tell
		end timeout
		on error tabErr number tabErrNum
			my noteTabFailure("AIMEAT Roundtable", tabErr, tabErrNum)
		end try
'''
ANCHOR = "\n\tend tell\n\tend tell\nend timeout\n"
GUARD = '''  # REPORT-CARD >> features/aimeat-roundtable.feature
  if [ "${FM_MLX_NO_SSH:-0}" = "1" ]; then
    echo "fm-mlx: MLX HTTP endpoint unavailable (SSH fallback disabled)" >&2
    exit 1
  fi
'''


def add_pane(text):
    if 'set name to "AIMEAT Roundtable"' in text:
        return text
    if text.count(ANCHOR) != 1:
        raise ValueError("Boot source structure changed; refusing an ambiguous insertion")
    return text.replace(ANCHOR, PANE + ANCHOR)


def add_service(text):
    if "  - name: aimeat-roundtable\n" in text:
        return text.replace("    results: merlib-dump/aimeat\n", "    results: comms/queue/aimeat-roundtable-results\n")
    if "\nsystems:\n" not in text:
        raise ValueError("systems.yaml has no systems list")
    # Keep the entry inside systems, before any following top-level YAML section.
    lines = text.splitlines(keepends=True)
    begin = lines.index("systems:\n") + 1
    for index in range(begin, len(lines)):
        line = lines[index]
        if line.strip() and not line.startswith((" ", "\t", "#", "\n")):
            lines.insert(index, SERVICE + "\n")
            break
    else:
        lines.append(SERVICE)
    return "".join(lines)


def compatible_function(engine_source):
    """Use current Convey when available; retain a reproducible older-host patch."""
    tree = ast.parse(engine_source)
    node = next(n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name == "cmd_roundtable")
    function = "\n".join(engine_source.splitlines()[node.lineno - 1:node.end_lineno]) + "\n"
    if "_rt_lore" not in function or "seated_by_name" not in function:
        function = (ROOT / "roundtable/convey-roundtable.py.txt").read_text()
    if '"type": "error", "message": ev["msg"]' not in function:
        function = function.replace('            if k == "error":\n',
            '            if k == "error":\n'
            '                if jsonl:\n'
            '                    print(json.dumps({"type": "error", "message": ev["msg"], "name": ev["name"]}), flush=True)\n')
    if "REPORT-CARD >> apple/features/aimeat-roundtable.feature" not in function:
        function = function.replace('    # CONVEY-CARD >>', '    # REPORT-CARD >> apple/features/aimeat-roundtable.feature\n    # CONVEY-CARD >>', 1)
    compile(function, "convey-roundtable-compatibility", "exec")
    return function


def stage(action="install"):
    if action == "smoke":
        # Create the input on the sending computer too. Archive Syncthing is
        # send-only here: Mini-created inputs do not travel back to this host.
        source = WORK / "merlib-dump/aimeat/roundtable-pipeline-check.txt"
        if not source.exists():
            source.write_text(SMOKE_TEXT)
    digest = hashlib.sha256()
    for name in FILES:
        digest.update((ROOT / name).read_bytes())
    russell = Path.home() / ".agents/skills/rhythmic-balanced-interchange/SKILL.md"
    digest.update(russell.read_bytes())
    engine_source = (WORK / "convey/convey/cli.py").read_text()
    function = compatible_function(engine_source)
    digest.update(function.encode())
    target = WORK / "comms/queue/aimeat-roundtable-deploy" / digest.hexdigest()[:16]
    target.mkdir(parents=True, exist_ok=True)
    manifest = {}
    for name in FILES:
        data = (ROOT / name).read_bytes()
        dst = target / name
        dst.parent.mkdir(parents=True, exist_ok=True)
        dst.write_bytes(data)
        manifest[name] = hashlib.sha256(data).hexdigest()
    # The Mini's older roster points Russell at a skill path it does not have.
    # Ship a grounded corpus snapshot with the deployment, never model weights.
    corpus = target / "roundtable/corpora/russell.md"
    corpus.parent.mkdir(parents=True, exist_ok=True)
    corpus.write_bytes(russell.read_bytes())
    manifest["roundtable/corpora/russell.md"] = hashlib.sha256(corpus.read_bytes()).hexdigest()
    patch = target / "roundtable/convey-roundtable.py.txt"
    patch.write_text(function)
    manifest["roundtable/convey-roundtable.py.txt"] = hashlib.sha256(patch.read_bytes()).hexdigest()
    (target / "manifest.json").write_text(json.dumps(manifest, indent=2))
    if action == "activate":
        cmd = "cloudcity restart"
    else:
        cmd = "run --direct --timeout 90 " + shlex.join([
            "/opt/homebrew/bin/python3", str(target / "roundtable/install.py"),
            action, "--payload", str(target)])
    request = WORK / "comms/queue/pakettibot-inbox" / f"aimeat-roundtable-{action}-{target.name}-{time.time_ns()}.cmd"
    request.parent.mkdir(parents=True, exist_ok=True)
    request.write_text(cmd + "\n")
    print(json.dumps({"payload": str(target), "request": str(request),
                      "reply": str(WORK / 'comms/queue/pakettibot-outbox' / (request.stem + '.out.txt'))}))


def install(payload):
    if socket.gethostname().split(".")[0].lower() not in {"cloudcity", "cloudcitymacmini"}:
        raise RuntimeError("Install and AppleScript compilation must run on CloudcityMacMini")
    manifest = json.loads((payload / "manifest.json").read_text())
    for name in manifest:
        if hashlib.sha256((payload / name).read_bytes()).hexdigest() != manifest[name]:
            raise RuntimeError(f"payload has not finished syncing: {name}")
    sys.path.insert(0, str(payload / "roundtable"))
    from bridge import verify_panel, atomic_text, DEFAULT_CONVEY, SEATS
    # Make the corpus available before checking the installed Mini's aliases.
    corpus = WORK / "apple/roundtable/corpora/russell.md"
    corpus.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(payload / "roundtable/corpora/russell.md", corpus)
    verify_panel(DEFAULT_CONVEY, SEATS)
    boot = WORK / "comms/cloudcity-boot/main.applescript"
    registry = WORK / "convey/systems.yaml"
    target = WORK / "Cloudcity-Boot.app/Contents/Resources/Scripts/main.scpt"
    fm = WORK / "apple/bin/fm-mlx"
    engine = WORK / "convey/convey/cli.py"
    engine_text = engine.read_text()
    engine_tree = ast.parse(engine_text)
    old_node = next(n for n in engine_tree.body if isinstance(n, ast.FunctionDef) and n.name == "cmd_roundtable")
    engine_lines = engine_text.splitlines(keepends=True)
    function = (payload / "roundtable/convey-roundtable.py.txt").read_text()
    engine_lines[old_node.lineno - 1:old_node.end_lineno] = [function]
    engine_text = "".join(engine_lines)
    # Add the flag only to the roundtable subparser on older installations.
    start = engine_text.index('sub.add_parser("roundtable"')
    end = engine_text.index('sp.set_defaults(func=cmd_roundtable)', start)
    parser_block = engine_text[start:end]
    if 'sp.add_argument("--seat"' not in parser_block:
        anchor = '    sp.add_argument("--turns"'
        where = engine_text.index(anchor, start, end)
        engine_text = engine_text[:where] + '    sp.add_argument("--seat", default=None, help="comma-separated persona names from the selected roster")\n' + engine_text[where:]
    compile(engine_text, str(engine), "exec")
    # Existing per-turn retrieval is required; do not silently install an
    # ungrounded voice if the target's supporting module is absent.
    sys.path.insert(0, str(WORK / "convey"))
    from convey import knows
    if not callable(knows.retrieve):
        raise RuntimeError("Convey corpus retrieval is not installed")
    # Prepare and syntax-check before changing the installed boot source.
    boot_text = add_pane(boot.read_text())
    registry_text = add_service(registry.read_text())
    fm_text = fm.read_text()
    if 'FM_MLX_NO_SSH' not in fm_text:
        marker = 'if [ "$curl_rc" -ne 0 ] || [ -z "$raw_reply" ]; then\n'
        if fm_text.count(marker) != 1:
            raise ValueError("Mini fm-mlx differs; SSH guard needs review")
        fm_text = fm_text.replace(marker, marker + GUARD)
    backups = payload / ("backups-" + str(time.time_ns()))
    backups.mkdir()
    with tempfile.TemporaryDirectory() as tmp:
        source = Path(tmp) / "main.applescript"
        compiled = Path(tmp) / "main.scpt"
        source.write_text(boot_text)
        subprocess.run(["osacompile", "-o", str(compiled), str(source)], check=True,
                       capture_output=True, text=True, timeout=60)
        for path in (boot, registry, fm, target, engine):
            shutil.copy2(path, backups / path.name)
        for name in FILES:
            dest = WORK / "apple" / name
            dest.parent.mkdir(parents=True, exist_ok=True)
            if dest.exists():
                backup = backups / name
                backup.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(dest, backup)
            shutil.copy2(payload / name, dest)
        boot.write_text(boot_text)
        registry.write_text(registry_text)
        fm.write_text(fm_text)
        atomic_text(engine, engine_text)
        shutil.copy2(compiled, target)
    # Migrate a failed pre-upgrade job to one bounded retry. Completed sections
    # and all original state remain in place; no already-finished work is erased.
    folder = WORK / "merlib-dump/aimeat"
    for state_file in (folder / ".roundtable").glob("*/state.json"):
        state = json.loads(state_file.read_text())
        if state.get("status") == "failed" and any(marker in (state.get("error") or "") for marker in
                ("unrecognized arguments: --seat", "incomplete: 0/", "<urlopen error")):
            state.update(status="queued", attempts=0, retry_at=0)
            state_file.write_text(json.dumps(state, indent=2))
    # Confirm the actual installed source can load the named personas and corpora.
    verify_panel(DEFAULT_CONVEY, SEATS)
    print(json.dumps({"installed": True, "backups": str(backups),
                      "folder": str(WORK / "merlib-dump/aimeat"),
                      "activation": "cloudcity restart", "personas": SEATS}))


def probe():
    sys.path.insert(0, str(WORK / "convey"))
    from convey import roster
    panel = roster.load_roster("sages", "mlx")
    folder = WORK / "merlib-dump/aimeat"
    help_result = subprocess.run([str(WORK / "convey/bin/convey"), "roundtable", "--help"],
                                 capture_output=True, text=True, timeout=30)
    states = []
    for path in sorted((folder / ".roundtable").glob("*/state.json"))[-5:]:
        state = json.loads(path.read_text())
        states.append({k: state.get(k) for k in ("source", "status", "seats", "error", "completed", "sections")})
    print(json.dumps({"host": socket.gethostname(), "panel": [p["name"] for p in panel],
                      "rosters": {name: [p["name"] for p in roster.load_roster(name, "mlx")]
                                  for name in roster.available()},
                      "folder_exists": folder.is_dir(),
                      "text_inputs": [p.name for p in folder.glob("*.txt")],
                      "engine_flags": {flag: flag in help_result.stdout for flag in ("--jsonl", "--seat", "--board")},
                      "jobs": states,
                      "heartbeat": json.loads((WORK / "comms/queue/aimeat-roundtable-heartbeat.json").read_text())
                      if (WORK / "comms/queue/aimeat-roundtable-heartbeat.json").exists() else None}, indent=2))


def smoke():
    if socket.gethostname().split(".")[0].lower() not in {"cloudcity", "cloudcitymacmini"}:
        raise RuntimeError("Smoke input must be created on CloudcityMacMini")
    source = WORK / "merlib-dump/aimeat/roundtable-pipeline-check.txt"
    if not source.exists():
        source.write_text(SMOKE_TEXT)
    print(json.dumps({"source": str(source), "result": str(source) + ".roundtable.md"}))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("verb", choices=["stage", "install", "probe", "smoke"])
    parser.add_argument("--action", choices=["install", "probe", "activate", "smoke"], default="install")
    parser.add_argument("--payload", type=Path)
    args = parser.parse_args()
    if args.verb == "stage":
        stage(args.action)
    elif args.verb == "probe":
        probe()
    elif args.verb == "smoke":
        smoke()
    elif args.payload:
        install(args.payload)
    else:
        parser.error("install needs --payload")
