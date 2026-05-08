#!/usr/bin/env python3
"""console-exporter — Console.app's data via the `log` CLI back-door.

Console.app has no AppleScript dictionary, no App Intents, no URL scheme.
But the underlying `log` CLI (ships with macOS) is strictly more powerful:
streaming, filtering by predicate, time windows, subsystems, signposts.
We wrap it for catalog-style usage.

Subcommands (all read-only):
  status        host info + diagnostic-report counts
  show          query logs with --last 1h --match REGEX --process NAME
  subsystems    list distinct subsystems seen in last N hours
  diag-list     enumerate ~/Library/Logs/DiagnosticReports + /Library/...
  diag-export   copy / symlink diagnostic reports into the vault
  export        run a saved query and write the output as a markdown vault page

No third-party dependencies. Apple-native `log show` only.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from collections import Counter
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_ENV = ROOT / ".env"

USER_DIAG = Path(os.path.expanduser("~/Library/Logs/DiagnosticReports"))
SYS_DIAG = Path("/Library/Logs/DiagnosticReports")


def load_env() -> dict[str, str]:
    env: dict[str, str] = {}
    if DEFAULT_ENV.exists():
        for line in DEFAULT_ENV.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            env[k.strip()] = os.path.expanduser(v.strip().strip('"').strip("'"))
    env.setdefault("VAULT_PATH", os.path.expanduser("~/work/apple/exported/console"))
    env["VAULT_PATH"] = os.path.expanduser(env["VAULT_PATH"])
    return env


def run_log_show(args_list: list[str]) -> str:
    proc = subprocess.run(
        ["log", "show"] + args_list,
        capture_output=True, text=True, check=False, timeout=120,
    )
    if proc.returncode != 0:
        sys.stderr.write(proc.stderr)
    return proc.stdout


# =====================================================================
# Subcommands
# =====================================================================

def cmd_status(args) -> int:
    print("Console / log overview")
    print(f"  User diag dir:   {USER_DIAG}  "
          f"({len(list(USER_DIAG.glob('*'))) if USER_DIAG.exists() else 0} entries)")
    print(f"  System diag dir: {SYS_DIAG}  "
          f"({len(list(SYS_DIAG.glob('*'))) if SYS_DIAG.exists() else 0} entries)")
    # quick log show counts last 5 minutes
    out = run_log_show(["--last", "5m", "--style", "compact"])
    lines = [l for l in out.splitlines() if l]
    print(f"  log lines (last 5m): {len(lines)}")


def build_predicate(args) -> str:
    parts: list[str] = []
    if args.process:
        parts.append(f'process == "{args.process}"')
    if args.subsystem:
        parts.append(f'subsystem == "{args.subsystem}"')
    if args.category:
        parts.append(f'category == "{args.category}"')
    if args.error:
        parts.append('messageType >= 16')          # error/fault
    return " AND ".join(parts)


def cmd_show(args) -> int:
    cmd: list[str] = []
    if args.last:
        cmd += ["--last", args.last]
    if args.start:
        cmd += ["--start", args.start]
    if args.end:
        cmd += ["--end", args.end]
    pred = build_predicate(args)
    if pred:
        cmd += ["--predicate", pred]
    cmd += ["--style", "compact"]
    out = run_log_show(cmd)
    if args.match:
        rx = re.compile(args.match, re.I)
        out = "\n".join(l for l in out.splitlines() if rx.search(l))
    if args.limit:
        out = "\n".join(out.splitlines()[: args.limit])
    print(out)
    return 0


def cmd_subsystems(args) -> int:
    cmd = ["--last", args.last or "1h", "--style", "compact"]
    raw = run_log_show(cmd)
    counter: Counter = Counter()
    # Compact format: "<timestamp> <thread> <type> <activity> <pid> <process>: (<subsystem>) <message>"
    pat = re.compile(r"\(([^()]+:[^()]+)\)")
    for line in raw.splitlines():
        m = pat.search(line)
        if m:
            counter[m.group(1)] += 1
    for sub, n in counter.most_common(args.top or 30):
        print(f"  {n:>6}  {sub}")
    print(f"\n{sum(counter.values())} log lines / "
          f"{len(counter)} distinct subsystem:category pairs in last {args.last or '1h'}.")
    return 0


def list_diagnostic_reports() -> list[Path]:
    out: list[Path] = []
    for d in (USER_DIAG, SYS_DIAG):
        if d.exists():
            out.extend(sorted(d.glob("*"),
                              key=lambda p: p.stat().st_mtime, reverse=True))
    return out


def cmd_diag_list(args) -> int:
    rows = list_diagnostic_reports()
    if args.match:
        rx = re.compile(args.match, re.I)
        rows = [p for p in rows if rx.search(p.name)]
    for p in rows:
        try:
            mtime = datetime.fromtimestamp(p.stat().st_mtime, tz=timezone.utc)
            mt = mtime.strftime("%Y-%m-%d %H:%M")
            size = p.stat().st_size
        except OSError:
            mt = "?"
            size = 0
        kind = ".".join(p.suffixes[-2:]) if p.suffixes else p.suffix
        print(f"  {mt}  {size:>10}b  {kind:<12}  {p.name}")
    print(f"\n{len(rows)} diagnostic report(s)")
    return 0


def cmd_diag_export(args) -> int:
    env = load_env()
    out_dir = Path(env["VAULT_PATH"]) / "diagnostic-reports"
    out_dir.mkdir(parents=True, exist_ok=True)
    rows = list_diagnostic_reports()
    if args.match:
        rx = re.compile(args.match, re.I)
        rows = [p for p in rows if rx.search(p.name)]
    n = 0
    for p in rows:
        target = out_dir / p.name
        if target.exists() or target.is_symlink():
            target.unlink()
        if args.copy:
            shutil.copy2(p, target)
        else:
            target.symlink_to(p)
        n += 1
    print(f"Exported {n} diagnostic report(s) to {out_dir} "
          f"({'copied' if args.copy else 'symlinked'})")
    return 0


def cmd_export(args) -> int:
    env = load_env()
    pred = build_predicate(args)
    cmd: list[str] = []
    if args.last:
        cmd += ["--last", args.last]
    if pred:
        cmd += ["--predicate", pred]
    cmd += ["--style", "compact"]
    raw = run_log_show(cmd)
    if args.match:
        rx = re.compile(args.match, re.I)
        raw = "\n".join(l for l in raw.splitlines() if rx.search(l))
    if not raw.strip():
        print("(no log lines matched)")
        return 0
    out_dir = Path(env["VAULT_PATH"]) / "queries"
    out_dir.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now().strftime("%Y-%m-%d__%H%M%S")
    label = (args.label or "query").replace("/", "-")
    path = out_dir / f"{stamp}__{label}.md"
    fm = ["---",
          f'label: "{label}"',
          f'generated: "{datetime.now().isoformat(timespec="seconds")}"',
          f'last: "{args.last or ""}"',
          f'predicate: "{pred}"',
          f'match: "{args.match or ""}"',
          f'lines: {len(raw.splitlines())}',
          "---",
          "",
          f"# Console query — {label}",
          "",
          "```",
          raw,
          "```",
          ""]
    path.write_text("\n".join(fm))
    print(f"Wrote {len(raw.splitlines())} log lines to {path}")
    return 0


# =====================================================================
# argparse
# =====================================================================

def add_query_args(p: argparse.ArgumentParser) -> None:
    p.add_argument("--last", help="e.g. 5m, 1h, 6h, 1d (default to log show default)")
    p.add_argument("--start", help="ISO-like datetime start")
    p.add_argument("--end", help="ISO-like datetime end")
    p.add_argument("--process", help="Limit to one process name")
    p.add_argument("--subsystem", help="Limit to one subsystem")
    p.add_argument("--category", help="Limit to one category")
    p.add_argument("--error", action="store_true", help="Errors + faults only")
    p.add_argument("--match", help="Regex post-filter on the line")
    p.add_argument("--limit", type=int, help="Max output lines")


def main() -> int:
    p = argparse.ArgumentParser(prog="console-exporter")
    sub = p.add_subparsers(dest="cmd", required=True)

    sp = sub.add_parser("status", help="Counts overview")
    sp.set_defaults(func=cmd_status)

    sp = sub.add_parser("show", help="log show wrapper with filters")
    add_query_args(sp)
    sp.set_defaults(func=cmd_show)

    sp = sub.add_parser("subsystems",
                         help="Top subsystems in recent log activity")
    sp.add_argument("--last", help="Time window (default 1h)")
    sp.add_argument("--top", type=int, help="Show top N (default 30)")
    sp.set_defaults(func=cmd_subsystems)

    sp = sub.add_parser("diag-list", help="List diagnostic reports")
    sp.add_argument("--match", help="Regex on filename")
    sp.set_defaults(func=cmd_diag_list)

    sp = sub.add_parser("diag-export",
                         help="Symlink/copy diagnostic reports into vault")
    sp.add_argument("--match", help="Regex on filename")
    sp.add_argument("--copy", action="store_true",
                    help="Copy files (default: symlink)")
    sp.set_defaults(func=cmd_diag_export)

    sp = sub.add_parser("export",
                         help="Save a filtered log query as a markdown vault page")
    add_query_args(sp)
    sp.add_argument("--label", help="Filename slug for this query (default: 'query')")
    sp.set_defaults(func=cmd_export)

    args = p.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
