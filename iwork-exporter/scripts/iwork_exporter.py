#!/usr/bin/env python3
"""iwork-exporter — Pages, Numbers, Keynote (regular + Creator Studio).

Apple ships two parallel iWork installs on this Mac:
  - Regular iWork (App Store): com.apple.iWork.Pages / .Numbers / .Keynote (v14.x)
  - Creator Studio (newer):    com.apple.Pages / .Numbers / .Keynote (v15.x)

Both have full AppleScript sdefs. Recent documents are in
LSSharedFileList .sfl3 files (NSKeyedArchiver bplists) shared across
the two variants.

Subcommands (read-only):
  status          which apps installed + recent doc counts
  apps            list every iWork app with version + bundle id
  recents         recent docs for one app (--app pages/numbers/keynote)
  all-recents     combined recents across all three apps
  export          markdown vault (apps.md + per-app recents)

The .sfl3 decoder properly resolves NSKeyedArchiver UID references
(unlike a naive top-level walk) so document names + URLs come out
clean.
"""

from __future__ import annotations

import argparse
import json
import os
import plistlib
import re
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_ENV = ROOT / ".env"
SFL_DIR = Path(os.path.expanduser(
    "~/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.ApplicationRecentDocuments"
))


def load_env() -> dict[str, str]:
    env: dict[str, str] = {}
    if DEFAULT_ENV.exists():
        for line in DEFAULT_ENV.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            env[k.strip()] = os.path.expanduser(v.strip().strip('"').strip("'"))
    env.setdefault("VAULT_PATH", os.path.expanduser("~/work/apple/exported/iwork"))
    env["VAULT_PATH"] = os.path.expanduser(env["VAULT_PATH"])
    return env


# =====================================================================
# .sfl3 NSKeyedArchiver UID resolver
# =====================================================================

class UID:  # plistlib types it as plistlib.UID
    pass


def _is_uid(x) -> bool:
    return type(x).__name__ == "UID"


def _uid_value(x) -> int:
    return x.data if hasattr(x, "data") else int(x)


def resolve_archiver(plist: dict) -> object:
    """Walk an NSKeyedArchiver bplist and return the resolved root object.

    Replaces every UID reference with the actual object from $objects,
    converting NSDictionary (NS.keys + NS.objects) to a real dict and
    NSArray (NS.objects) to a list.
    """
    objs = plist.get("$objects") or []
    top = plist.get("$top") or {}
    root_uid = top.get("root")
    if not _is_uid(root_uid):
        return None

    seen: dict[int, object] = {}

    def resolve(uid_val: int):
        if uid_val in seen:
            return seen[uid_val]
        if uid_val < 0 or uid_val >= len(objs):
            return None
        obj = objs[uid_val]
        seen[uid_val] = None  # placeholder against cycles
        out = _resolve(obj)
        seen[uid_val] = out
        return out

    def _resolve(obj):
        if obj == "$null":
            return None
        if isinstance(obj, dict):
            # NSDictionary
            if "NS.keys" in obj and "NS.objects" in obj:
                keys = [resolve(_uid_value(k)) for k in obj["NS.keys"]]
                vals = [resolve(_uid_value(v)) for v in obj["NS.objects"]]
                return dict(zip(keys, vals))
            # NSArray / NSMutableArray
            if "NS.objects" in obj and "NS.keys" not in obj:
                return [resolve(_uid_value(v)) for v in obj["NS.objects"]]
            # Plain object: resolve any UID-valued fields
            out = {}
            for k, v in obj.items():
                if k.startswith("$"):
                    continue
                if _is_uid(v):
                    out[k] = resolve(_uid_value(v))
                else:
                    out[k] = v
            return out
        if _is_uid(obj):
            return resolve(_uid_value(obj))
        return obj

    return resolve(_uid_value(root_uid))


RESOLVE_BOOKMARK_SWIFT = Path(__file__).resolve().parent / "resolve_bookmark.swift"


def parse_bookmark_url(blob) -> tuple[str | None, str | None]:
    """Resolve a bookmark blob to (path, name) via Foundation NSURL.

    Falls back to None,None if Swift resolution fails (e.g. stale
    bookmark, broken file path).
    """
    if not isinstance(blob, (bytes, bytearray)):
        return None, None
    try:
        proc = subprocess.run(
            ["/usr/bin/swift", str(RESOLVE_BOOKMARK_SWIFT)],
            input=bytes(blob), capture_output=True, timeout=10,
        )
        if proc.returncode != 0:
            return None, None
        d = json.loads(proc.stdout.decode("utf-8", errors="replace"))
        return d.get("path"), d.get("name")
    except Exception:
        return None, None


def load_recents(sfl_name: str) -> list[dict]:
    path = SFL_DIR / sfl_name
    if not path.exists():
        return []
    try:
        with open(path, "rb") as f:
            data = f.read()
        plist = plistlib.loads(data)
    except Exception:
        return []
    root = resolve_archiver(plist)
    if not isinstance(root, dict):
        return []
    items = root.get("items") or []
    out: list[dict] = []
    for it in items:
        if not isinstance(it, dict):
            continue
        bookmark = it.get("Bookmark") or it.get("bookmark")
        path, name = (None, None)
        if bookmark:
            path, name = parse_bookmark_url(bookmark)
        out.append({
            "name": name or it.get("Name") or "?",
            "path": path or "",
            "uuid": it.get("uuid", ""),
        })
    return out


# =====================================================================
# App enumeration
# =====================================================================

@dataclass
class IWorkApp:
    label: str          # "Pages" / "Numbers" / "Keynote"
    variant: str        # "regular" / "creator-studio"
    path: Path
    bundle_id: str
    version: str

    @property
    def installed(self) -> bool:
        return self.path.exists()


def get_app_info(path: Path) -> tuple[str, str]:
    if not path.exists():
        return "", ""
    info = path / "Contents" / "Info.plist"
    try:
        with open(info, "rb") as f:
            d = plistlib.load(f)
        return d.get("CFBundleIdentifier", ""), d.get("CFBundleShortVersionString", "")
    except Exception:
        return "", ""


def list_apps() -> list[IWorkApp]:
    candidates = [
        ("Pages",   "regular",         Path("/Applications/Pages.app")),
        ("Numbers", "regular",         Path("/Applications/Numbers.app")),
        ("Keynote", "regular",         Path("/Applications/Keynote.app")),
        ("Pages",   "creator-studio",  Path("/Applications/Pages Creator Studio.app")),
        ("Numbers", "creator-studio",  Path("/Applications/Numbers Creator Studio.app")),
        ("Keynote", "creator-studio",  Path("/Applications/Keynote Creator Studio.app")),
    ]
    out: list[IWorkApp] = []
    for label, variant, path in candidates:
        if not path.exists():
            continue
        bid, ver = get_app_info(path)
        out.append(IWorkApp(label=label, variant=variant, path=path,
                            bundle_id=bid, version=ver))
    return out


# .sfl3 filename mapping
SFL_FILES = {
    "pages":   "com.apple.iwork.pages.sfl3",
    "numbers": "com.apple.iwork.numbers.sfl3",
    "keynote": "com.apple.iwork.keynote.sfl3",
}


# =====================================================================
# Subcommands
# =====================================================================

def cmd_status(args) -> int:
    apps = list_apps()
    print("iWork overview")
    print(f"  Apps installed: {len(apps)}")
    for a in apps:
        print(f"    {a.label:<8}  {a.variant:<14}  v{a.version:<8}  {a.bundle_id}")
    print()
    for label, fname in SFL_FILES.items():
        items = load_recents(fname)
        print(f"  Recent {label:<8}: {len(items):>4}  ({fname})")
    return 0


def cmd_apps(args) -> int:
    apps = list_apps()
    if args.json:
        print(json.dumps([{
            "label": a.label, "variant": a.variant,
            "path": str(a.path), "bundle_id": a.bundle_id,
            "version": a.version,
        } for a in apps], indent=2, ensure_ascii=False))
        return 0
    for a in apps:
        print(f"  {a.label:<8}  {a.variant:<14}  v{a.version:<8}  {a.bundle_id}")
        print(f"    {a.path}")
    print(f"\n{len(apps)} app(s)")
    return 0


def cmd_recents(args) -> int:
    fname = SFL_FILES.get((args.app or "").lower())
    if not fname:
        sys.exit(f"--app must be one of: {', '.join(SFL_FILES)}")
    items = load_recents(fname)
    if args.json:
        print(json.dumps(items, indent=2, ensure_ascii=False, default=str))
        return 0
    for it in items[: args.limit or len(items)]:
        url = it.get("url") or ""
        print(f"  {it.get('name', '?'):<60}  {url[:80]}")
    print(f"\n{len(items)} recent {args.app} doc(s)")
    return 0


def cmd_all_recents(args) -> int:
    for label, fname in SFL_FILES.items():
        items = load_recents(fname)
        print(f"\n=== {label.upper()} ({len(items)}) ===")
        for it in items[:10]:
            print(f"  {it.get('name', '?')}")
        if len(items) > 10:
            print(f"  ... +{len(items) - 10} more")
    return 0


def write_md(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)


SLUG_RE = re.compile(r"[^a-zA-Z0-9._-]+")


def slugify(s: str, max_len: int = 60) -> str:
    s = SLUG_RE.sub("-", (s or "").strip()).strip("-")
    return (s[:max_len] or "untitled").lower()


def cmd_export(args) -> int:
    env = load_env()
    vault = Path(env["VAULT_PATH"])
    vault.mkdir(parents=True, exist_ok=True)

    apps = list_apps()
    body = ["# iWork Apps Installed", ""]
    for a in apps:
        body.append(f"## {a.label} — {a.variant} (v{a.version})")
        body.append("")
        body.append(f"- Bundle id: `{a.bundle_id}`")
        body.append(f"- Path: `{a.path}`")
        body.append("")
    write_md(vault / "apps.md", "\n".join(body))

    for label, fname in SFL_FILES.items():
        items = load_recents(fname)
        body = ["---",
                f'app: "{label}"',
                f'sfl3: "{fname}"',
                f'recent_count: {len(items)}',
                "---", "",
                f"# {label.title()} — Recent Documents ({len(items)})", ""]
        for it in items:
            url = it.get("url") or ""
            if url:
                body.append(f"- [{it.get('name', '?')}]({url})")
            else:
                body.append(f"- {it.get('name', '?')}")
        write_md(vault / f"recents-{label}.md", "\n".join(body))

    index = ["# iWork Vault", "",
             f"Generated {datetime.now().isoformat(timespec='seconds')}.",
             "",
             "- [Apps installed](./apps.md)",
             "- [Pages recents](./recents-pages.md)",
             "- [Numbers recents](./recents-numbers.md)",
             "- [Keynote recents](./recents-keynote.md)", ""]
    write_md(vault / "INDEX.md", "\n".join(index))
    print(f"Wrote vault: {vault}")
    print(f"  apps: {len(apps)}")
    for label, fname in SFL_FILES.items():
        n = len(load_recents(fname))
        print(f"  recents-{label}: {n}")
    return 0


def main() -> int:
    p = argparse.ArgumentParser(prog="iwork-exporter")
    sub = p.add_subparsers(dest="cmd", required=True)
    sub.add_parser("status").set_defaults(func=cmd_status)
    sp = sub.add_parser("apps"); sp.add_argument("--json", action="store_true"); sp.set_defaults(func=cmd_apps)
    sp = sub.add_parser("recents")
    sp.add_argument("--app", required=True, help="pages | numbers | keynote")
    sp.add_argument("--limit", type=int)
    sp.add_argument("--json", action="store_true")
    sp.set_defaults(func=cmd_recents)
    sub.add_parser("all-recents").set_defaults(func=cmd_all_recents)
    sub.add_parser("export").set_defaults(func=cmd_export)
    args = p.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
