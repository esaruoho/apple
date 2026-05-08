#!/usr/bin/env python3
"""reminders_export — Apple Reminders → Markdown vault.

Hybrid AppleScript driver. One osascript call per command, batched output.
Outputs one .md file per reminder, organized by list, with YAML frontmatter.
Incremental: skips reminders whose modification date is unchanged.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_CONFIG = ROOT / "config.json"
DEFAULT_ENV = ROOT / ".env"
STATE_FILE = ROOT / ".state.json"

US = "\x1f"  # unit separator between fields
RS = "\x1e"  # record separator between reminders


def load_env() -> dict[str, str]:
    env: dict[str, str] = {}
    if DEFAULT_ENV.exists():
        for line in DEFAULT_ENV.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            env[k.strip()] = os.path.expanduser(v.strip().strip('"').strip("'"))
    env.setdefault("VAULT_PATH", os.path.expanduser("~/reminders-vault"))
    env["VAULT_PATH"] = os.path.expanduser(env["VAULT_PATH"])
    env.setdefault("INCLUDE_COMPLETED", "false")
    return env


def load_config() -> dict:
    if DEFAULT_CONFIG.exists():
        return json.loads(DEFAULT_CONFIG.read_text())
    return {"lists": []}


def load_state() -> dict:
    if STATE_FILE.exists():
        return json.loads(STATE_FILE.read_text())
    return {"reminders": {}, "last_run": None}


def save_state(state: dict) -> None:
    STATE_FILE.write_text(json.dumps(state, indent=2, default=str))


def osascript(src: str) -> str:
    proc = subprocess.run(
        ["osascript", "-e", src],
        capture_output=True,
        text=True,
        check=False,
    )
    if proc.returncode != 0:
        sys.stderr.write(proc.stderr)
        raise RuntimeError(f"osascript failed (exit {proc.returncode})")
    return proc.stdout


def list_lists() -> list[dict]:
    src = f'''
    set US to (ASCII character 31)
    set RS to (ASCII character 30)
    set out to ""
    tell application "Reminders"
        repeat with L in lists
            set out to out & (id of L) & US & (name of L) & US & (count of reminders of L) & RS
        end repeat
    end tell
    return out
    '''
    raw = osascript(src)
    items = []
    for rec in raw.split(RS):
        rec = rec.strip()
        if not rec:
            continue
        parts = rec.split(US)
        if len(parts) >= 3:
            items.append({"id": parts[0], "name": parts[1], "count": int(parts[2] or 0)})
    return items


def _iso(applescript_date_var: str) -> str:
    """Emit AppleScript that converts a date variable to ISO 8601 via component access."""
    return (
        f'((year of {applescript_date_var}) as text) & "-" & '
        f'(text -2 thru -1 of ("0" & ((month of {applescript_date_var}) as integer))) & "-" & '
        f'(text -2 thru -1 of ("0" & (day of {applescript_date_var}))) & "T" & '
        f'(text -2 thru -1 of ("0" & (hours of {applescript_date_var}))) & ":" & '
        f'(text -2 thru -1 of ("0" & (minutes of {applescript_date_var}))) & ":" & '
        f'(text -2 thru -1 of ("0" & (seconds of {applescript_date_var})))'
    )


def _iso_loop(var: str, dest: str, src_list: str) -> str:
    return f'''
    set {dest} to {{}}
    repeat with i_ from 1 to (count of {src_list})
        set d to item i_ of {src_list}
        if d is missing value then
            set end of {dest} to ""
        else
            set end of {dest} to {_iso("d")}
        end if
    end repeat
    '''


def fetch_reminders(list_name: str, include_completed: bool) -> list[dict]:
    """Return all reminders in a list as dicts. Uses parallel-array pattern (fast)."""
    completed_filter = "" if include_completed else "whose completed is false"
    safe_name = list_name.replace('"', '\\"')
    src = f'''
    set US to (ASCII character 31)
    set RS to (ASCII character 30)
    tell application "Reminders"
        set theList to first list whose name is "{safe_name}"
        set ids_ to id of (every reminder of theList {completed_filter})
        set names_ to name of (every reminder of theList {completed_filter})
        set comp_ to completed of (every reminder of theList {completed_filter})
        set prio_ to priority of (every reminder of theList {completed_filter})
        set flag_ to flagged of (every reminder of theList {completed_filter})
        set body_ to body of (every reminder of theList {completed_filter})
        set cre_ to creation date of (every reminder of theList {completed_filter})
        set mod_ to modification date of (every reminder of theList {completed_filter})
        set due_ to due date of (every reminder of theList {completed_filter})
        set compd_ to completion date of (every reminder of theList {completed_filter})
    end tell

    {_iso_loop("d", "creISO", "cre_")}
    {_iso_loop("d", "modISO", "mod_")}
    {_iso_loop("d", "dueISO", "due_")}
    {_iso_loop("d", "compdISO", "compd_")}

    set out to ""
    set n to count of ids_
    repeat with i from 1 to n
        set rbody to item i of body_
        if rbody is missing value then set rbody to ""
        set out to out & (item i of ids_) & US & (item i of names_) & US & ((item i of comp_) as text) & US & ((item i of prio_) as text) & US & ((item i of flag_) as text) & US & (item i of creISO) & US & (item i of modISO) & US & (item i of dueISO) & US & (item i of compdISO) & US & rbody & RS
    end repeat
    return out
    '''
    raw = osascript(src)
    items = []
    for rec in raw.split(RS):
        if not rec.strip():
            continue
        parts = rec.split(US)
        if len(parts) < 10:
            continue
        items.append({
            "id": parts[0],
            "name": parts[1],
            "completed": parts[2].strip().lower() == "true",
            "priority": int(parts[3] or 0),
            "flagged": parts[4].strip().lower() == "true",
            "creation_date": parts[5],
            "modification_date": parts[6],
            "due_date": parts[7],
            "completion_date": parts[8],
            "body": parts[9].rstrip("\n"),
            "list": list_name,
        })
    return items


SLUG_RE = re.compile(r"[^a-zA-Z0-9._-]+")


def slugify(s: str, max_len: int = 80) -> str:
    s = SLUG_RE.sub("-", s).strip("-")
    return (s[:max_len] or "untitled").lower()


def write_reminder(env: dict, r: dict) -> Path:
    list_dir = Path(env["VAULT_PATH"]) / slugify(r["list"])
    list_dir.mkdir(parents=True, exist_ok=True)
    date_prefix = (r["creation_date"] or "")[:10] or "undated"
    fname = f"{date_prefix}__{slugify(r['name'])}__{r['id'].split('/')[-1][:8]}.md"
    path = list_dir / fname

    fm = {
        "id": r["id"],
        "title": r["name"],
        "list": r["list"],
        "completed": r["completed"],
        "priority": r["priority"],
        "flagged": r["flagged"],
        "creation_date": r["creation_date"],
        "modification_date": r["modification_date"],
        "due_date": r["due_date"],
        "completion_date": r["completion_date"],
    }
    lines = ["---"]
    for k, v in fm.items():
        if isinstance(v, str):
            v = v.replace('"', '\\"')
            lines.append(f'{k}: "{v}"')
        else:
            lines.append(f"{k}: {json.dumps(v)}")
    lines.append("---")
    lines.append("")
    lines.append(f"# {r['name']}")
    lines.append("")
    if r["body"]:
        lines.append(r["body"])
        lines.append("")
    path.write_text("\n".join(lines))
    return path


def cmd_lists(args) -> int:
    items = list_lists()
    for L in items:
        print(f"{L['count']:>5}  {L['name']}")
    print(f"\n{len(items)} list(s)")
    return 0


def cmd_status(args) -> int:
    state = load_state()
    print(f"Vault: {load_env()['VAULT_PATH']}")
    print(f"Last run: {state.get('last_run') or 'never'}")
    print(f"Tracked reminders: {len(state.get('reminders', {}))}")
    by_list: dict[str, int] = {}
    for v in state.get("reminders", {}).values():
        by_list[v.get("list", "?")] = by_list.get(v.get("list", "?"), 0) + 1
    for k, n in sorted(by_list.items()):
        print(f"  {n:>5}  {k}")
    return 0


def cmd_export(args) -> int:
    env = load_env()
    cfg = load_config()
    state = load_state()
    include_completed = (
        args.include_completed
        or env.get("INCLUDE_COMPLETED", "false").lower() == "true"
    )

    if args.lists:
        targets = [s.strip() for s in args.lists.split(",") if s.strip()]
    elif args.all:
        targets = [L["name"] for L in list_lists()]
    else:
        targets = cfg.get("lists") or []
    if not targets:
        print("No lists selected. Pass --lists A,B or --all, or fill config.json.", file=sys.stderr)
        return 2

    Path(env["VAULT_PATH"]).mkdir(parents=True, exist_ok=True)
    tracked = state.setdefault("reminders", {})
    written = unchanged = 0

    for name in targets:
        print(f"→ {name}")
        try:
            reminders = fetch_reminders(name, include_completed)
        except RuntimeError as e:
            print(f"  ! {e}", file=sys.stderr)
            continue
        for r in reminders:
            prev = tracked.get(r["id"])
            if not args.force and prev and prev.get("modification_date") == r["modification_date"]:
                unchanged += 1
                continue
            path = write_reminder(env, r)
            tracked[r["id"]] = {
                "list": r["list"],
                "modification_date": r["modification_date"],
                "path": str(path),
            }
            written += 1
        print(f"  wrote {written}, unchanged {unchanged} so far")

    state["last_run"] = datetime.now(timezone.utc).isoformat()
    save_state(state)
    print(f"\nDone. {written} written, {unchanged} unchanged.")
    return 0


def main() -> int:
    p = argparse.ArgumentParser(prog="reminders-export")
    sub = p.add_subparsers(dest="cmd", required=True)

    sp = sub.add_parser("lists", help="List all Reminders lists")
    sp.set_defaults(func=cmd_lists)

    sp = sub.add_parser("export", help="Export reminders to vault")
    sp.add_argument("--lists", help="Comma-separated list names")
    sp.add_argument("--all", action="store_true", help="Export every list")
    sp.add_argument("--force", action="store_true", help="Re-export unchanged reminders")
    sp.add_argument("--include-completed", action="store_true", help="Include completed reminders")
    sp.set_defaults(func=cmd_export)

    sp = sub.add_parser("status", help="Show last run and per-list counts")
    sp.set_defaults(func=cmd_status)

    args = p.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
