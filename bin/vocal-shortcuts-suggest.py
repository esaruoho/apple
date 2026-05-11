#!/usr/bin/env python3
"""
Vocal Shortcuts — suggest, orphan, and drift report.

Cross-references three data sources to produce a coverage report for the
Vocal Shortcuts trigger surface:

  1. AVSPreferenceKey   — live Vocal Shortcut bindings (phrase → Shortcut UUID)
     ~/Library/Preferences/com.apple.Accessibility.plist
  2. Shortcuts.sqlite   — live Shortcuts.app database (ZSHORTCUT.ZWORKFLOWID, ZNAME)
     ~/Library/Shortcuts/Shortcuts.sqlite
  3. seven-purpose audit — triple-channel candidates from sal-7-purpose-audit.py
     analysis/sal/seven-purpose-audit.md

Three reports:

  - ORPHANS      Vocal Shortcut binds a UUID that no longer exists (or is
                 tombstoned) in Shortcuts.sqlite. Binding will silently fail.
  - DRIFT        Vocal Shortcut's cached associatedShortcut.name does not match
                 the live ZNAME. Cosmetic only (binding is UUID-stable) but
                 confuses the user who renamed it.
  - SUGGESTIONS  Shortcuts that exist in Shortcuts.sqlite but have NO Vocal
                 Shortcut bound. With --audit-only, restrict to Shortcuts whose
                 name fuzzy-matches a triple-channel audit candidate filename.

Why this exists: read is solved (list-vocal-shortcuts.py) but no tool surfaced
the gap between "what's bindable" and "what's bound". This is that tool.

Output modes:
  default        human-readable to stdout
  --json         JSON document with all three reports
  --write PATH   markdown report written to PATH (default analysis/sal/...)
  --audit-only   filter suggestions to triple-channel audit matches
"""
import argparse
import json
import plistlib
import re
import sys
from datetime import date
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent / "lib"))
from apple_sqlite_snapshot import snapshot_open  # noqa: E402

HOME = Path.home()
REPO = Path(__file__).resolve().parent.parent
PLIST = HOME / "Library/Preferences/com.apple.Accessibility.plist"
PLIST_KEY = "AVSPreferenceKey"
SHORTCUTS_DB = HOME / "Library/Shortcuts/Shortcuts.sqlite"
AUDIT_MD = REPO / "analysis/sal/seven-purpose-audit.md"
DEFAULT_OUT = REPO / "analysis/sal/vocal-shortcuts-coverage.md"


# ---- Vocal Shortcuts (source 1) ----

def read_vocal_shortcuts():
    if not PLIST.exists():
        return []
    with open(PLIST, "rb") as f:
        plist = plistlib.load(f)
    blob = plist.get(PLIST_KEY)
    if not blob:
        return []
    if isinstance(blob, bytes):
        return json.loads(blob.decode("utf-8"))
    if isinstance(blob, str):
        return json.loads(blob)
    return blob


def vs_target_uuid(entry):
    """Return target Shortcut UUID for a `siriShortcut` entry, else None."""
    t = entry.get("associatedShortcut", {}).get("type", {})
    if "siriShortcut" in t:
        return t["siriShortcut"].get("id")
    return None


def vs_cached_name(entry):
    return entry.get("associatedShortcut", {}).get("name")


# ---- Shortcuts.sqlite (source 2) ----

def read_shortcuts_db():
    """
    Return {workflow_uuid: name} for live (non-tombstoned) Shortcuts.

    Uses the WAL-safe snapshot helper so the running Shortcuts.app's
    uncommitted WAL state is included.
    """
    if not SHORTCUTS_DB.exists():
        return {}
    with snapshot_open(SHORTCUTS_DB) as con:
        rows = con.execute(
            "SELECT ZWORKFLOWID, ZNAME FROM ZSHORTCUT "
            "WHERE ZTOMBSTONED = 0 AND ZWORKFLOWID IS NOT NULL"
        ).fetchall()
    return {uuid: name for uuid, name in rows if uuid}


# ---- Audit (source 3) ----

AUDIT_ROW = re.compile(r"^\|\s*(\d+)\s*\|\s*`([^`]+)`\s*\|")


def read_audit_candidates():
    """
    Return [(score, filename_basename_without_ext)] from the triple-channel
    section of the audit. Empty if audit hasn't been generated yet.
    """
    if not AUDIT_MD.exists():
        return []
    out = []
    in_table = False
    for line in AUDIT_MD.read_text().splitlines():
        if line.startswith("# Triple-channel candidates"):
            in_table = True
            continue
        if in_table and line.startswith("# "):
            break
        if not in_table:
            continue
        m = AUDIT_ROW.match(line)
        if m:
            score = int(m.group(1))
            path = m.group(2)
            stem = Path(path).stem
            out.append((score, stem))
    return out


def normalize(s):
    """lowercase, strip non-alphanumerics — for fuzzy name matching."""
    return re.sub(r"[^a-z0-9]+", "", s.lower())


def audit_matches_shortcut(audit_stem, shortcut_name):
    """
    Fuzzy match: either side's normalized form contains the other's, and the
    shorter side is at least 4 chars (avoid trivial substring collisions).
    """
    a = normalize(audit_stem)
    b = normalize(shortcut_name)
    if not a or not b:
        return False
    short, long_ = (a, b) if len(a) <= len(b) else (b, a)
    if len(short) < 4:
        return False
    return short in long_


# ---- Report builder ----

def build_report(audit_only=False):
    entries = read_vocal_shortcuts()
    shortcuts = read_shortcuts_db()  # uuid -> name
    audit = read_audit_candidates()

    bound_uuids = set()
    orphans = []
    drift = []
    for e in entries:
        uuid = vs_target_uuid(e)
        if not uuid:
            continue  # siriRequest / accessibility — no Shortcut UUID to check
        bound_uuids.add(uuid)
        live_name = shortcuts.get(uuid)
        if live_name is None:
            orphans.append({
                "phrase": e.get("name"),
                "cached_name": vs_cached_name(e),
                "missing_uuid": uuid,
                "entry_id": e.get("identifier"),
            })
            continue
        cached = vs_cached_name(e)
        if cached != live_name:
            drift.append({
                "phrase": e.get("name"),
                "cached_name": cached,
                "live_name": live_name,
                "uuid": uuid,
            })

    unbound = [
        {"name": name, "uuid": uuid}
        for uuid, name in shortcuts.items()
        if uuid not in bound_uuids and name
    ]
    unbound.sort(key=lambda r: r["name"].lower())

    if audit_only:
        audit_stems = [stem for _score, stem in audit]
        suggestions = []
        for s in unbound:
            hits = [stem for stem in audit_stems if audit_matches_shortcut(stem, s["name"])]
            if hits:
                suggestions.append({**s, "audit_matches": hits})
    else:
        suggestions = unbound

    return {
        "totals": {
            "vocal_shortcuts": len(entries),
            "live_shortcuts": len(shortcuts),
            "bound": len(bound_uuids),
            "orphans": len(orphans),
            "drift": len(drift),
            "unbound": len(unbound),
            "audit_candidates": len(audit),
        },
        "orphans": orphans,
        "drift": drift,
        "suggestions": suggestions,
        "audit_only": audit_only,
    }


# ---- Output ----

def render_text(report):
    t = report["totals"]
    lines = []
    lines.append(f"Vocal Shortcuts coverage:")
    lines.append(
        f"  {t['bound']}/{t['live_shortcuts']} live Shortcuts have a Vocal binding "
        f"({t['vocal_shortcuts']} total Vocal entries, "
        f"{t['vocal_shortcuts'] - t['bound']} non-Shortcut)"
    )
    lines.append("")

    if report["orphans"]:
        lines.append(f"ORPHANS ({len(report['orphans'])}) — binding points at missing Shortcut:")
        for o in report["orphans"]:
            lines.append(f"  \"{o['phrase']}\" → {o['cached_name']!r}  MISSING UUID {o['missing_uuid']}")
        lines.append("")

    if report["drift"]:
        lines.append(f"DRIFT ({len(report['drift'])}) — cached name differs from live name:")
        for d in report["drift"]:
            lines.append(
                f"  \"{d['phrase']}\"  cached={d['cached_name']!r}  live={d['live_name']!r}"
            )
        lines.append("")

    sug = report["suggestions"]
    label = "audit-matched" if report["audit_only"] else "all"
    lines.append(f"SUGGESTIONS ({len(sug)}, {label}) — Shortcuts with no Vocal binding:")
    for s in sug:
        suffix = ""
        if "audit_matches" in s:
            suffix = f"  [audit: {', '.join(s['audit_matches'])}]"
        lines.append(f"  {s['name']}  ({s['uuid']}){suffix}")
    return "\n".join(lines)


def render_markdown(report):
    t = report["totals"]
    lines = [
        "---",
        "title: Vocal Shortcuts — coverage report",
        f"date: {date.today().isoformat()}",
        "generator: bin/vocal-shortcuts-suggest.py",
        "sources:",
        "  - ~/Library/Preferences/com.apple.Accessibility.plist (AVSPreferenceKey)",
        "  - ~/Library/Shortcuts/Shortcuts.sqlite (ZSHORTCUT)",
        "  - analysis/sal/seven-purpose-audit.md",
        "---",
        "",
        "# Tallies",
        "",
        f"- Vocal Shortcut entries: **{t['vocal_shortcuts']}**",
        f"- Live (non-tombstoned) Shortcuts: **{t['live_shortcuts']}**",
        f"- Live Shortcuts with a Vocal binding: **{t['bound']}**",
        f"- Orphaned bindings: **{t['orphans']}**",
        f"- Rename drift: **{t['drift']}**",
        f"- Unbound Shortcuts: **{t['unbound']}**",
        f"- Triple-channel audit candidates: **{t['audit_candidates']}**",
        "",
    ]

    lines.append("# Orphans")
    lines.append("")
    if not report["orphans"]:
        lines.append("_None._")
    else:
        lines.append("| Phrase | Cached name | Missing UUID |")
        lines.append("|---|---|---|")
        for o in report["orphans"]:
            lines.append(f"| `{o['phrase']}` | {o['cached_name']} | `{o['missing_uuid']}` |")
    lines.append("")

    lines.append("# Drift")
    lines.append("")
    if not report["drift"]:
        lines.append("_None._")
    else:
        lines.append("| Phrase | Cached name | Live name |")
        lines.append("|---|---|---|")
        for d in report["drift"]:
            lines.append(f"| `{d['phrase']}` | {d['cached_name']} | {d['live_name']} |")
    lines.append("")

    label = "audit-matched" if report["audit_only"] else "all unbound"
    lines.append(f"# Suggestions ({label})")
    lines.append("")
    if not report["suggestions"]:
        lines.append("_None._")
    else:
        if report["audit_only"]:
            lines.append("| Shortcut | UUID | Audit candidate match |")
            lines.append("|---|---|---|")
            for s in report["suggestions"]:
                lines.append(
                    f"| {s['name']} | `{s['uuid']}` | {', '.join(s['audit_matches'])} |"
                )
        else:
            lines.append("| Shortcut | UUID |")
            lines.append("|---|---|")
            for s in report["suggestions"]:
                lines.append(f"| {s['name']} | `{s['uuid']}` |")
    lines.append("")

    return "\n".join(lines)


def fix_drift(report) -> int:
    """
    Rewrite AVSPreferenceKey, replacing each drifted entry's cached
    associatedShortcut.name with the live ZNAME from Shortcuts.sqlite.

    Drift is cosmetic — bindings stay UUID-stable across renames — but the
    cached name shows up in the Vocal Shortcuts list in System Settings,
    so out-of-sync labels confuse the user. Returns count of entries fixed.
    """
    drift = report["drift"]
    if not drift:
        return 0

    raw_entries = read_vocal_shortcuts()
    drift_by_phrase = {d["phrase"]: d["live_name"] for d in drift}
    fixed = 0
    for entry in raw_entries:
        live = drift_by_phrase.get(entry.get("name"))
        if live is None:
            continue
        entry.setdefault("associatedShortcut", {})["name"] = live
        fixed += 1

    new_blob = json.dumps(raw_entries, separators=(",", ":")).encode("utf-8")
    with open(PLIST, "rb") as f:
        plist = plistlib.load(f)
    plist[PLIST_KEY] = new_blob
    with open(PLIST, "wb") as f:
        plistlib.dump(plist, f, fmt=plistlib.FMT_BINARY)

    # cfprefsd caches the plist in memory; ask it to reread.
    import subprocess
    subprocess.run(["killall", "-HUP", "cfprefsd"], check=False, capture_output=True)
    return fixed


def main():
    p = argparse.ArgumentParser(description=__doc__.splitlines()[1])
    p.add_argument("--json", action="store_true", help="emit JSON instead of text")
    p.add_argument("--audit-only", action="store_true",
                   help="filter suggestions to triple-channel audit matches")
    p.add_argument("--write", nargs="?", const=str(DEFAULT_OUT),
                   help=f"write markdown report (default: {DEFAULT_OUT.relative_to(REPO)})")
    p.add_argument("--fix-drift", action="store_true",
                   help="rewrite AVSPreferenceKey to repair drifted cached names")
    args = p.parse_args()

    report = build_report(audit_only=args.audit_only)

    if args.fix_drift:
        n = fix_drift(report)
        print(f"Fixed drift on {n} entr{'y' if n == 1 else 'ies'}.")
        if n:
            print("Re-run without --fix-drift to verify drift count is now 0.")
        return

    if args.json:
        print(json.dumps(report, indent=2))
    else:
        print(render_text(report))

    if args.write:
        out_path = Path(args.write)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(render_markdown(report))
        print(f"\nWrote {out_path}", file=sys.stderr)


if __name__ == "__main__":
    main()
