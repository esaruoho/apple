#!/usr/bin/env python3
"""
shortcuts-exporter — catalog every Shortcut in Shortcuts.app as readable
markdown so AI assistants (and humans) can study the user's automation
library without opening the app.

Data source: ~/Library/Shortcuts/Shortcuts.sqlite (WAL-safe snapshot via
the shared bin/lib/apple_sqlite_snapshot.py helper). The .sqlite holds
every Shortcut's name, UUID, folder, action count, trigger count, voice
phrase, run history, etc. We do NOT decode the action body (ZSHORTCUTACTIONS.ZDATA
is an NSKeyedArchiver bplist referencing Apple-internal intent identifiers —
a meaningful decode is its own project) — instead we surface what the
schema gives us cleanly and link to the action count.

Subcommands:
  status            counts + storage overview
  list              flat list of all live Shortcuts
  folders           folder tree with per-folder counts
  show <name>       one Shortcut's metadata
  export            write the full vault under VAULT_PATH

Output structure (export):
  exported/shortcuts/
    _index.md                 master list, sorted by folder
    folders/
      <folder-slug>/_index.md per-folder list
    by-uuid/<uuid>.md         one file per Shortcut
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sqlite3
import sys
from collections import defaultdict
from datetime import datetime, timedelta, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_ENV = ROOT / ".env"
SHORTCUTS_DB = Path.home() / "Library/Shortcuts/Shortcuts.sqlite"
COCOA_EPOCH = datetime(2001, 1, 1, tzinfo=timezone.utc)

sys.path.insert(0, str(ROOT.parent / "bin" / "lib"))
from apple_sqlite_snapshot import snapshot_open_persistent  # noqa: E402


def load_env() -> dict[str, str]:
    env: dict[str, str] = {}
    if DEFAULT_ENV.exists():
        for line in DEFAULT_ENV.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            env[k.strip()] = os.path.expanduser(v.strip().strip('"').strip("'"))
    env.setdefault("VAULT_PATH", os.path.expanduser("~/work/apple/exported/shortcuts"))
    env["VAULT_PATH"] = os.path.expanduser(env["VAULT_PATH"])
    return env


def cocoa_to_iso(z: float | None) -> str:
    if z is None:
        return ""
    return (COCOA_EPOCH + timedelta(seconds=z)).isoformat()


def slugify(s: str) -> str:
    s = re.sub(r"[^a-zA-Z0-9._-]+", "-", s).strip("-").lower()
    return s or "untitled"


# =====================================================================
# Queries
# =====================================================================

SHORTCUT_COLS = (
    "ZNAME", "ZWORKFLOWID", "ZACTIONCOUNT", "ZTRIGGERCOUNT", "ZRUNEVENTSCOUNT",
    "ZPHRASE", "ZSOURCE", "ZASSOCIATEDAPPBUNDLEIDENTIFIER",
    "ZCREATIONDATE", "ZMODIFICATIONDATE", "ZLASTRUNEVENTDATE",
    "ZDISABLEDONLOCKSCREEN", "ZHIDDENFROMWIDGET", "ZHIDDENFROMLIBRARYANDSYNC",
    "ZWORKFLOWSUBTITLE", "ZLASTSAVEDONDEVICENAME",
)


def query_shortcuts(con: sqlite3.Connection) -> list[dict]:
    rows = con.execute(
        f"SELECT Z_PK, {', '.join(SHORTCUT_COLS)} FROM ZSHORTCUT "
        "WHERE ZTOMBSTONED = 0 ORDER BY ZNAME COLLATE NOCASE"
    ).fetchall()
    out: list[dict] = []
    for r in rows:
        d = {"pk": r[0]}
        for i, col in enumerate(SHORTCUT_COLS, start=1):
            d[col] = r[i]
        out.append(d)
    return out


def query_folders(con: sqlite3.Connection) -> dict[int, str]:
    """Return {pk: folder_name} for every live (non-tombstoned) collection."""
    try:
        rows = con.execute(
            "SELECT Z_PK, ZNAME FROM ZCOLLECTION "
            "WHERE ZTOMBSTONED = 0 "
            "ORDER BY ZNAME COLLATE NOCASE"
        ).fetchall()
    except sqlite3.OperationalError:
        return {}
    return {r[0]: (r[1] or "(unnamed)") for r in rows}


def query_folder_membership(con: sqlite3.Connection) -> dict[int, int]:
    """Return {shortcut_pk: folder_pk}. Z_4SHORTCUTS is the join table:
    Z_7SHORTCUTS → ZSHORTCUT.Z_PK, Z_4PARENTS1 → ZCOLLECTION.Z_PK."""
    try:
        rows = con.execute(
            "SELECT Z_7SHORTCUTS, Z_4PARENTS1 FROM Z_4SHORTCUTS"
        ).fetchall()
    except sqlite3.OperationalError:
        return {}
    return {sc_pk: f_pk for sc_pk, f_pk in rows}


def enrich(shortcuts: list[dict], folders: dict[int, str],
           membership: dict[int, int]) -> None:
    for sc in shortcuts:
        f_pk = membership.get(sc["pk"])
        sc["folder"] = folders.get(f_pk, "") if f_pk else ""


# =====================================================================
# Subcommands
# =====================================================================

def with_db():
    if not SHORTCUTS_DB.exists():
        sys.exit(f"Shortcuts DB not found at {SHORTCUTS_DB}")
    return snapshot_open_persistent(SHORTCUTS_DB)


def cmd_status(args) -> int:
    con = with_db()
    shortcuts = query_shortcuts(con)
    folders = query_folders(con)
    membership = query_folder_membership(con)
    enrich(shortcuts, folders, membership)

    voiced = sum(1 for s in shortcuts if s.get("ZPHRASE"))
    with_actions = sum(1 for s in shortcuts if (s.get("ZACTIONCOUNT") or 0) > 0)
    with_triggers = sum(1 for s in shortcuts if (s.get("ZTRIGGERCOUNT") or 0) > 0)
    print("Shortcuts library overview")
    print(f"  Total live Shortcuts:       {len(shortcuts)}")
    print(f"  Folders:                    {len(folders)}")
    print(f"  With at least one action:   {with_actions}")
    print(f"  With at least one trigger:  {with_triggers}")
    print(f"  With Siri phrase:           {voiced}")
    print(f"  DB path:                    {SHORTCUTS_DB}")
    return 0


def cmd_list(args) -> int:
    con = with_db()
    shortcuts = query_shortcuts(con)
    folders = query_folders(con)
    membership = query_folder_membership(con)
    enrich(shortcuts, folders, membership)
    if args.json:
        print(json.dumps([{
            "name": s["ZNAME"],
            "uuid": s["ZWORKFLOWID"],
            "folder": s["folder"],
            "actions": s.get("ZACTIONCOUNT") or 0,
            "triggers": s.get("ZTRIGGERCOUNT") or 0,
            "phrase": s.get("ZPHRASE") or "",
        } for s in shortcuts], indent=2, ensure_ascii=False))
        return 0
    width = max(len(s["ZNAME"] or "") for s in shortcuts) if shortcuts else 0
    for s in shortcuts:
        actions = s.get("ZACTIONCOUNT") or 0
        folder = s["folder"]
        print(f"  {(s['ZNAME'] or '?'):<{width}}  {actions:>3}a  {folder}")
    print(f"\n{len(shortcuts)} Shortcut(s)")
    return 0


def cmd_folders(args) -> int:
    con = with_db()
    shortcuts = query_shortcuts(con)
    folders = query_folders(con)
    membership = query_folder_membership(con)
    enrich(shortcuts, folders, membership)
    by_folder: dict[str, list[dict]] = defaultdict(list)
    for s in shortcuts:
        by_folder[s["folder"] or "(no folder)"].append(s)
    for folder in sorted(by_folder, key=str.lower):
        items = by_folder[folder]
        print(f"  {folder}: {len(items)}")
        if args.verbose:
            for s in items:
                print(f"      {s['ZNAME']}")
    return 0


def cmd_show(args) -> int:
    con = with_db()
    shortcuts = query_shortcuts(con)
    target = args.name.lower()
    hits = [s for s in shortcuts if (s["ZNAME"] or "").lower() == target]
    if not hits:
        hits = [s for s in shortcuts if target in (s["ZNAME"] or "").lower()]
    if not hits:
        sys.exit(f"no Shortcut matching {args.name!r}")
    folders = query_folders(con)
    membership = query_folder_membership(con)
    enrich(hits, folders, membership)
    for s in hits:
        print(f"Name:      {s['ZNAME']}")
        print(f"UUID:      {s['ZWORKFLOWID']}")
        print(f"Folder:    {s['folder'] or '(none)'}")
        print(f"Actions:   {s.get('ZACTIONCOUNT') or 0}")
        print(f"Triggers:  {s.get('ZTRIGGERCOUNT') or 0}")
        print(f"Runs:      {s.get('ZRUNEVENTSCOUNT') or 0}")
        print(f"Phrase:    {s.get('ZPHRASE') or '(none)'}")
        print(f"App bundle: {s.get('ZASSOCIATEDAPPBUNDLEIDENTIFIER') or '(none)'}")
        print(f"Source:    {s.get('ZSOURCE') or '(unknown)'}")
        print(f"Created:   {cocoa_to_iso(s.get('ZCREATIONDATE'))}")
        print(f"Modified:  {cocoa_to_iso(s.get('ZMODIFICATIONDATE'))}")
        print(f"Last run:  {cocoa_to_iso(s.get('ZLASTRUNEVENTDATE')) or '(never)'}")
        print(f"Lock OK:   {'no' if s.get('ZDISABLEDONLOCKSCREEN') else 'yes'}")
        print(f"In widget: {'no' if s.get('ZHIDDENFROMWIDGET') else 'yes'}")
        print(f"Hidden:    {'yes' if s.get('ZHIDDENFROMLIBRARYANDSYNC') else 'no'}")
        if s.get("ZWORKFLOWSUBTITLE"):
            print(f"Subtitle:  {s['ZWORKFLOWSUBTITLE']}")
        if s.get("ZLASTSAVEDONDEVICENAME"):
            print(f"Last save: {s['ZLASTSAVEDONDEVICENAME']}")
        print()
    return 0


def render_shortcut_md(s: dict) -> str:
    actions = s.get("ZACTIONCOUNT") or 0
    triggers = s.get("ZTRIGGERCOUNT") or 0
    runs = s.get("ZRUNEVENTSCOUNT") or 0
    phrase = s.get("ZPHRASE") or ""
    name = s["ZNAME"] or "?"
    yaml = [
        "---",
        f"name: {json.dumps(name, ensure_ascii=False)}",
        f"uuid: {s['ZWORKFLOWID']}",
        f"folder: {json.dumps(s['folder'], ensure_ascii=False)}",
        f"actions: {actions}",
        f"triggers: {triggers}",
        f"runs: {runs}",
    ]
    if phrase:
        yaml.append(f"phrase: {json.dumps(phrase, ensure_ascii=False)}")
    bundle = s.get("ZASSOCIATEDAPPBUNDLEIDENTIFIER")
    if bundle:
        yaml.append(f"app_bundle: {bundle}")
    src = s.get("ZSOURCE")
    if src:
        yaml.append(f"source: {src}")
    if s.get("ZCREATIONDATE"):
        yaml.append(f"created: {cocoa_to_iso(s['ZCREATIONDATE'])}")
    if s.get("ZMODIFICATIONDATE"):
        yaml.append(f"modified: {cocoa_to_iso(s['ZMODIFICATIONDATE'])}")
    if s.get("ZLASTRUNEVENTDATE"):
        yaml.append(f"last_run: {cocoa_to_iso(s['ZLASTRUNEVENTDATE'])}")
    yaml.append("---")
    body = [f"# {name}", ""]
    if s.get("ZWORKFLOWSUBTITLE"):
        body.append(f"> {s['ZWORKFLOWSUBTITLE']}")
        body.append("")
    body.append(f"**UUID** `{s['ZWORKFLOWID']}`  ")
    body.append(f"**Folder** {s['folder'] or '_(none)_'}  ")
    body.append(f"**Actions** {actions} | **Triggers** {triggers} | **Runs** {runs}  ")
    if phrase:
        body.append(f"**Siri phrase** \"{phrase}\"  ")
    if bundle:
        body.append(f"**App bundle** `{bundle}`  ")
    body.append("")
    body.append("## Run via CLI")
    body.append("```bash")
    body.append(f'shortcuts run "{name}"')
    body.append("```")
    body.append("")
    body.append("> Action contents are stored in `ZSHORTCUTACTIONS.ZDATA` as a")
    body.append("> serialized NSKeyedArchiver bplist; decoding the action graph")
    body.append("> for human reading is a future enhancement.")
    return "\n".join(yaml) + "\n\n" + "\n".join(body) + "\n"


def cmd_export(args) -> int:
    env = load_env()
    vault = Path(env["VAULT_PATH"])
    vault.mkdir(parents=True, exist_ok=True)
    (vault / "folders").mkdir(parents=True, exist_ok=True)
    (vault / "by-uuid").mkdir(parents=True, exist_ok=True)

    con = with_db()
    shortcuts = query_shortcuts(con)
    folders = query_folders(con)
    membership = query_folder_membership(con)
    enrich(shortcuts, folders, membership)

    by_folder: dict[str, list[dict]] = defaultdict(list)
    for s in shortcuts:
        by_folder[s["folder"] or "(no folder)"].append(s)
        (vault / "by-uuid" / f"{s['ZWORKFLOWID']}.md").write_text(render_shortcut_md(s))

    # per-folder index
    for folder_name, items in by_folder.items():
        slug = slugify(folder_name)
        fdir = vault / "folders" / slug
        fdir.mkdir(parents=True, exist_ok=True)
        lines = [f"# {folder_name} ({len(items)})", ""]
        for s in sorted(items, key=lambda x: (x["ZNAME"] or "").lower()):
            uuid = s["ZWORKFLOWID"]
            actions = s.get("ZACTIONCOUNT") or 0
            voice = " 🎙" if s.get("ZPHRASE") else ""
            lines.append(f"- [{s['ZNAME']}](../../by-uuid/{uuid}.md) — {actions} action(s){voice}")
        (fdir / "_index.md").write_text("\n".join(lines) + "\n")

    # master index
    master = [
        "# Shortcuts library",
        "",
        f"- **Total live Shortcuts:** {len(shortcuts)}",
        f"- **Folders:** {len(by_folder)}",
        f"- **DB:** `{SHORTCUTS_DB}`",
        "",
        "## Folders",
        "",
    ]
    for folder in sorted(by_folder, key=str.lower):
        slug = slugify(folder)
        master.append(f"- [{folder}](./folders/{slug}/_index.md) — {len(by_folder[folder])}")
    master.append("")
    master.append("## Every Shortcut (alphabetical)")
    master.append("")
    for s in shortcuts:
        uuid = s["ZWORKFLOWID"]
        actions = s.get("ZACTIONCOUNT") or 0
        master.append(f"- [{s['ZNAME']}](./by-uuid/{uuid}.md) — {actions} action(s) — folder: _{s['folder'] or '(none)'}_")
    (vault / "_index.md").write_text("\n".join(master) + "\n")

    print(f"wrote {len(shortcuts)} Shortcut(s) across {len(by_folder)} folder(s) to {vault}")
    return 0


def main() -> int:
    p = argparse.ArgumentParser(prog="shortcuts-exporter", description=__doc__.splitlines()[1])
    sub = p.add_subparsers(dest="cmd", required=True)

    sp = sub.add_parser("status", help="counts + storage overview")
    sp.set_defaults(func=cmd_status)

    sp = sub.add_parser("list", help="flat list of every live Shortcut")
    sp.add_argument("--json", action="store_true")
    sp.set_defaults(func=cmd_list)

    sp = sub.add_parser("folders", help="folder tree")
    sp.add_argument("--verbose", "-v", action="store_true")
    sp.set_defaults(func=cmd_folders)

    sp = sub.add_parser("show", help="one Shortcut's metadata")
    sp.add_argument("name")
    sp.set_defaults(func=cmd_show)

    sp = sub.add_parser("export", help="write full vault to VAULT_PATH")
    sp.set_defaults(func=cmd_export)

    args = p.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
