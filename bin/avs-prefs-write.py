#!/usr/bin/env python3
"""
Round-trip writer for the AVSPreferenceKey blob inside
~/Library/Preferences/com.apple.Accessibility.plist.

This is the unblocker for the plist-write-firing experiment
(analysis/sal/vocal-shortcuts-plist-write-firing-test.md). It can:

  --list                       show current entries (read-only)
  --backup [PATH]              write the current plist to PATH (default ./avs-backup-<ts>.plist)
  --restore PATH               restore plist from a backup file
  --remove-id UUID             remove the entry with this identifier
  --add JSON                   append a JSON entry (the full entry dict)
  --reload-cfprefsd            killall -HUP cfprefsd to flush caches
  --kick-daemons               killall assistantd siriinferenced (force reload)
  --dump                       print the raw decoded JSON array to stdout

Safety notes:
  * Every write makes an automatic timestamped backup at
    ~/Library/Preferences/.com.apple.Accessibility.plist.backup-<unix-ts>.
  * The plist is binary; we read it via plistlib, mutate the JSON array,
    re-encode the array as UTF-8 bytes, set it back, and write binary.
  * Apple's UI normally trains audio in addition to writing this plist;
    a plist-only write tests whether the daemon falls back to generic ASR.

This script never connects to a network and operates only on the user's own
preferences plist. It is the test harness, not a deploy tool.
"""
from __future__ import annotations

import argparse
import json
import plistlib
import shutil
import subprocess
import sys
import time
from pathlib import Path

PLIST = Path.home() / "Library/Preferences/com.apple.Accessibility.plist"
KEY = "AVSPreferenceKey"
BACKUP_DIR = Path.home() / "Library/Preferences"


def read_plist() -> dict:
    if not PLIST.exists():
        sys.exit(f"plist not found: {PLIST}")
    with open(PLIST, "rb") as f:
        return plistlib.load(f)


def write_plist(plist: dict, no_backup: bool = False) -> Path | None:
    backup_path = None
    if not no_backup:
        backup_path = BACKUP_DIR / f".com.apple.Accessibility.plist.backup-{int(time.time())}"
        shutil.copy2(PLIST, backup_path)
    with open(PLIST, "wb") as f:
        plistlib.dump(plist, f, fmt=plistlib.FMT_BINARY)
    return backup_path


def decode_entries(plist: dict) -> list[dict]:
    blob = plist.get(KEY)
    if not blob:
        return []
    if isinstance(blob, bytes):
        return json.loads(blob.decode("utf-8"))
    if isinstance(blob, str):
        return json.loads(blob)
    return list(blob)


def encode_entries(entries: list[dict]) -> bytes:
    return json.dumps(entries, separators=(",", ":")).encode("utf-8")


def reload_cfprefsd() -> None:
    subprocess.run(["killall", "-HUP", "cfprefsd"], check=False, capture_output=True)


def kick_daemons() -> None:
    for d in ("assistantd", "siriinferenced"):
        subprocess.run(["killall", d], check=False, capture_output=True)


def cmd_list() -> int:
    entries = decode_entries(read_plist())
    print(f"{len(entries)} entry/entries:")
    for e in entries:
        sc = e.get("associatedShortcut", {})
        kind = next(iter(sc.get("type", {}).keys()), "?")
        print(f"  id={e.get('identifier')}  \"{e.get('name')}\"  → [{kind}] {sc.get('name')}")
    return 0


def cmd_backup(path: str | None) -> int:
    dest = Path(path) if path else Path.cwd() / f"avs-backup-{int(time.time())}.plist"
    shutil.copy2(PLIST, dest)
    print(f"wrote {dest}")
    return 0


def cmd_restore(path: str) -> int:
    src = Path(path)
    if not src.exists():
        sys.exit(f"no such file: {src}")
    # auto-backup current state before overwriting
    auto = BACKUP_DIR / f".com.apple.Accessibility.plist.pre-restore-{int(time.time())}"
    shutil.copy2(PLIST, auto)
    shutil.copy2(src, PLIST)
    print(f"restored from {src}  (current state archived to {auto})")
    reload_cfprefsd()
    return 0


def cmd_remove(uuid: str) -> int:
    plist = read_plist()
    entries = decode_entries(plist)
    keep = [e for e in entries if e.get("identifier") != uuid]
    if len(keep) == len(entries):
        sys.exit(f"no entry with identifier {uuid}")
    plist[KEY] = encode_entries(keep)
    bp = write_plist(plist)
    print(f"removed {uuid}; backup at {bp}")
    reload_cfprefsd()
    return 0


def cmd_add(payload_json: str) -> int:
    try:
        entry = json.loads(payload_json)
    except json.JSONDecodeError as e:
        sys.exit(f"invalid JSON: {e}")
    if not isinstance(entry, dict):
        sys.exit("--add expects a single JSON object (one entry)")
    if "identifier" not in entry or "name" not in entry:
        sys.exit("entry must include 'identifier' and 'name'")
    plist = read_plist()
    entries = decode_entries(plist)
    entries.append(entry)
    plist[KEY] = encode_entries(entries)
    bp = write_plist(plist)
    print(f"added entry {entry['identifier']}; backup at {bp}")
    reload_cfprefsd()
    return 0


def cmd_dump() -> int:
    entries = decode_entries(read_plist())
    print(json.dumps(entries, indent=2))
    return 0


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__.splitlines()[1])
    g = p.add_mutually_exclusive_group(required=True)
    g.add_argument("--list", action="store_true")
    g.add_argument("--dump", action="store_true")
    g.add_argument("--backup", nargs="?", const="", metavar="PATH",
                   help="copy plist to PATH (default ./avs-backup-<ts>.plist)")
    g.add_argument("--restore", metavar="PATH")
    g.add_argument("--remove-id", metavar="UUID")
    g.add_argument("--add", metavar="JSON",
                   help="single JSON entry object to append")
    g.add_argument("--reload-cfprefsd", action="store_true")
    g.add_argument("--kick-daemons", action="store_true")
    args = p.parse_args()

    if args.list:
        return cmd_list()
    if args.dump:
        return cmd_dump()
    if args.backup is not None:
        return cmd_backup(args.backup or None)
    if args.restore:
        return cmd_restore(args.restore)
    if args.remove_id:
        return cmd_remove(args.remove_id)
    if args.add:
        return cmd_add(args.add)
    if args.reload_cfprefsd:
        reload_cfprefsd()
        print("sent HUP to cfprefsd")
        return 0
    if args.kick_daemons:
        kick_daemons()
        print("killed assistantd + siriinferenced (launchd will respawn)")
        return 0
    return 1


if __name__ == "__main__":
    sys.exit(main())
