#!/usr/bin/env python3
"""app-plist-probe — scan every Apple-app plist for extractable user data.

Walks two roots:
  ~/Library/Containers/com.apple.*/Data/Library/Preferences/   (sandboxed apps)
  ~/Library/Preferences/com.apple.*.plist                      (system-wide prefs)

For each plist, decodes top-level keys, recursively unwraps NSKeyedArchiver
blobs, and produces a survey report: which apps actually persist user data
(not just window frames + migration flags) and what shape that data takes.
This is the meta-layer that tells us which apps deserve a dedicated
<app>-exporter.

No third-party dependencies. Apple-native plistlib only.

Usage:
  app-plist-probe.py                        # full survey to stdout
  app-plist-probe.py --md > survey.md       # markdown report
  app-plist-probe.py --json                 # machine-readable
  app-plist-probe.py --interesting-only     # skip apps with only window-frame
                                            # state and migration flags
  app-plist-probe.py --grep tesla           # find plist values containing string
  app-plist-probe.py --app voicememos       # one app
"""

from __future__ import annotations

import argparse
import json
import os
import plistlib
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

CONTAINERS = Path(os.path.expanduser("~/Library/Containers"))
PREFS = Path(os.path.expanduser("~/Library/Preferences"))

# Keys we consider "noise" — every Mac app has these. If a plist has ONLY these,
# it has no user data worth exporting.
NOISE_KEYS = {
    "NSWindow Frame", "NSNavLastRootDirectory", "NSNavPanelExpandedSizeForOpenMode",
    "NSNavPanelExpandedSizeForSaveMode", "NSToolbar Configuration",
    "NSFullScreenMenuItemEverywhere", "NSStatusItem Visible",
    "NSStatusItem Preferred Position", "WebKitDeveloperExtras",
    "DefaultsVersion", "LegacyMigrated", "MigratedSettings",
    "NSScrollViewShouldScrollUnderTitlebar", "ApplePersistenceIgnoreState",
    "ApplePersistence", "AppleAntiAliasingThreshold",
    "kMTAStateStoreLatestEvent",  # tiny clock state blob
}


def is_noise_key(k: str) -> bool:
    if k in NOISE_KEYS:
        return True
    for prefix in ("NSWindow Frame ", "NSToolbar ", "NSSplitView ",
                   "NSTableView ", "NSOutlineView ", "NSStatusItem ",
                   "NSNavLastRootDirectory", "NSNavPanelExpanded"):
        if k.startswith(prefix):
            return True
    return False


@dataclass
class PlistReport:
    path: Path
    app_id: str
    container_kind: str           # "container" | "global"
    size: int
    error: str | None = None
    keys: list[str] = field(default_factory=list)
    interesting_keys: list[str] = field(default_factory=list)
    nested_archived: list[str] = field(default_factory=list)
    sample: dict[str, Any] = field(default_factory=dict)


def decode_keyed_archiver(blob: bytes) -> Any:
    """If blob is an NSKeyedArchiver bplist, unwrap to a more readable dict.

    Returns a dict with 'archived_class' and 'objects' keys, or {} on failure.
    """
    try:
        d = plistlib.loads(blob)
    except Exception:
        return {}
    if not isinstance(d, dict):
        return {}
    if "$archiver" not in d or "$objects" not in d:
        return {}
    objs = d.get("$objects") or []
    cls = ""
    for o in objs:
        if isinstance(o, dict) and "$classname" in o:
            cls = o["$classname"]
            break
    return {"archived_class": cls, "object_count": len(objs)}


def looks_like_bplist(b: bytes) -> bool:
    return isinstance(b, (bytes, bytearray)) and len(b) >= 8 and b[:6] == b"bplist"


def summarize_value(v: Any, depth: int = 0) -> Any:
    """Return a compact JSON-friendly preview of a plist value."""
    if depth > 3:
        return "…"
    if isinstance(v, dict):
        return {k: summarize_value(vv, depth + 1)
                for k, vv in list(v.items())[:5]}
    if isinstance(v, list):
        return [summarize_value(x, depth + 1) for x in v[:3]] + \
               (["…"] if len(v) > 3 else [])
    if isinstance(v, (bytes, bytearray)):
        if looks_like_bplist(v):
            return {"_nested_bplist": decode_keyed_archiver(v) or "raw"}
        return f"<{len(v)} bytes>"
    if isinstance(v, str):
        return v if len(v) <= 100 else v[:100] + "…"
    return v


def probe_plist(path: Path, kind: str) -> PlistReport:
    try:
        size = path.stat().st_size
    except OSError as e:
        return PlistReport(path=path, app_id=path.stem, container_kind=kind,
                           size=0, error=str(e))
    rep = PlistReport(path=path, app_id=app_id_from_path(path, kind),
                      container_kind=kind, size=size)
    try:
        with open(path, "rb") as f:
            d = plistlib.load(f)
    except Exception as e:
        rep.error = f"plistlib: {e}"
        return rep
    if not isinstance(d, dict):
        rep.sample = {"_root": summarize_value(d)}
        return rep
    rep.keys = sorted(d.keys())
    rep.interesting_keys = [k for k in rep.keys if not is_noise_key(k)]
    rep.sample = {k: summarize_value(d[k]) for k in rep.interesting_keys[:10]}
    # Find nested NSKeyedArchiver blobs (apps love stuffing these inside plists)
    for k, v in d.items():
        if isinstance(v, (bytes, bytearray)) and looks_like_bplist(v):
            inner = decode_keyed_archiver(v)
            if inner:
                rep.nested_archived.append(
                    f"{k}: {inner.get('archived_class') or 'unknown'} "
                    f"({inner.get('object_count')} objs)"
                )
    return rep


def app_id_from_path(path: Path, kind: str) -> str:
    if kind == "container":
        # ...Containers/com.apple.X/Data/Library/Preferences/foo.plist → com.apple.X
        for p in path.parents:
            if p.parent and p.parent.name == "Containers":
                return p.name
        return path.stem
    return path.stem  # com.apple.foo


def collect() -> list[PlistReport]:
    out: list[PlistReport] = []

    if CONTAINERS.exists():
        for container in sorted(CONTAINERS.glob("com.apple.*")):
            prefs = container / "Data" / "Library" / "Preferences"
            if not prefs.exists():
                continue
            for plist in sorted(prefs.glob("*.plist")):
                out.append(probe_plist(plist, "container"))

    if PREFS.exists():
        for plist in sorted(PREFS.glob("com.apple.*.plist")):
            out.append(probe_plist(plist, "global"))

    return out


def is_interesting(rep: PlistReport) -> bool:
    if rep.error:
        return False
    if not rep.interesting_keys:
        return False
    # at least one key with non-trivial structure
    return any(not is_noise_key(k) for k in rep.interesting_keys)


# =====================================================================
# Output formats
# =====================================================================

def render_md(reports: list[PlistReport], interesting_only: bool) -> str:
    out: list[str] = ["# Apple App Plist Survey", "",
                      "Generated by `bin/app-plist-probe.py`.",
                      "Lists every plist under "
                      "`~/Library/Containers/com.apple.*/Data/Library/Preferences/` "
                      "and `~/Library/Preferences/com.apple.*.plist` "
                      "with non-trivial user data.", ""]
    by_app: dict[str, list[PlistReport]] = {}
    for r in reports:
        if interesting_only and not is_interesting(r):
            continue
        by_app.setdefault(r.app_id, []).append(r)
    out.append(f"## Summary")
    out.append("")
    out.append(f"- Total plists scanned: {len(reports)}")
    out.append(f"- With user-extractable data: "
               f"{sum(1 for r in reports if is_interesting(r))}")
    out.append(f"- Apps covered: {len(by_app)}")
    out.append("")
    out.append("## Per-app detail")
    out.append("")
    for app in sorted(by_app):
        out.append(f"### {app}")
        out.append("")
        for r in by_app[app]:
            out.append(f"- **{r.path.name}** "
                       f"({r.container_kind}, {r.size} bytes)")
            if r.error:
                out.append(f"  - error: `{r.error}`")
                continue
            out.append(f"  - keys: {len(r.keys)}, "
                       f"interesting: {len(r.interesting_keys)}")
            if r.interesting_keys:
                preview = ", ".join(f"`{k}`" for k in r.interesting_keys[:8])
                out.append(f"  - {preview}")
            if r.nested_archived:
                out.append(f"  - nested NSKeyedArchiver: "
                           f"{', '.join(r.nested_archived[:3])}")
        out.append("")
    return "\n".join(out)


def render_json(reports: list[PlistReport], interesting_only: bool) -> str:
    out = []
    for r in reports:
        if interesting_only and not is_interesting(r):
            continue
        out.append({
            "path": str(r.path), "app_id": r.app_id,
            "container_kind": r.container_kind, "size": r.size,
            "error": r.error,
            "keys": r.keys, "interesting_keys": r.interesting_keys,
            "nested_archived": r.nested_archived,
            "sample": r.sample,
        })
    return json.dumps(out, indent=2, ensure_ascii=False, default=str)


def render_grep(reports: list[PlistReport], pattern: str) -> str:
    rx = re.compile(pattern, re.I)
    out: list[str] = []
    for r in reports:
        try:
            with open(r.path, "rb") as f:
                d = plistlib.load(f)
        except Exception:
            continue
        flat = _flatten(d)
        for path, val in flat.items():
            if rx.search(str(val)):
                out.append(f"{r.path}\n  {path}: {str(val)[:200]}")
    return "\n".join(out) or "(no matches)"


def _flatten(obj: Any, prefix: str = "") -> dict[str, str]:
    out: dict[str, str] = {}
    if isinstance(obj, dict):
        for k, v in obj.items():
            out.update(_flatten(v, f"{prefix}{k}/" if prefix else f"{k}/"))
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            out.update(_flatten(v, f"{prefix}[{i}]/"))
    elif isinstance(obj, (bytes, bytearray)):
        if looks_like_bplist(obj):
            try:
                inner = plistlib.loads(obj)
                out.update(_flatten(inner, prefix + "<bplist>/"))
            except Exception:
                out[prefix.rstrip("/")] = f"<{len(obj)} bytes>"
        else:
            out[prefix.rstrip("/")] = f"<{len(obj)} bytes>"
    else:
        out[prefix.rstrip("/")] = obj
    return out


def main() -> int:
    p = argparse.ArgumentParser(prog="app-plist-probe")
    p.add_argument("--md", action="store_true", help="Markdown report (default: text)")
    p.add_argument("--json", action="store_true", help="JSON output")
    p.add_argument("--interesting-only", action="store_true",
                   help="Skip apps with only window frames / migration flags")
    p.add_argument("--app", help="Only scan apps whose container ID contains this substring")
    p.add_argument("--grep", help="Find plist values matching regex (deep walk)")
    args = p.parse_args()

    reports = collect()
    if args.app:
        reports = [r for r in reports if args.app.lower() in r.app_id.lower()]

    if args.grep:
        print(render_grep(reports, args.grep))
        return 0
    if args.json:
        print(render_json(reports, args.interesting_only))
        return 0
    if args.md:
        print(render_md(reports, args.interesting_only))
        return 0
    # default: short text summary
    interesting = [r for r in reports if is_interesting(r)]
    print(f"Scanned {len(reports)} plists across "
          f"{len({r.app_id for r in reports})} apps.")
    print(f"With user-extractable data: {len(interesting)} plists "
          f"across {len({r.app_id for r in interesting})} apps.")
    print()
    print("Top 30 apps by interesting-key count:")
    by_app: dict[str, int] = {}
    for r in interesting:
        by_app[r.app_id] = by_app.get(r.app_id, 0) + len(r.interesting_keys)
    for app, n in sorted(by_app.items(), key=lambda x: -x[1])[:30]:
        print(f"  {n:>4}  {app}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
