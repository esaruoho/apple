"""
Shared resolver for LSSharedFileList .sfl3 files (NSKeyedArchiver bplists).

The .sfl3 format is `~/Library/Application Support/com.apple.sharedfilelist/`
files used by Finder, iWork, Safari, etc. for "recent documents", "favorites",
"recent applications", "iCloud items" — each backed by an NSKeyedArchiver
property list with UID references between objects.

Naively walking `$objects` looking for top-level dicts with a "Name" key
misses everything: the items are reached via the `$top.root` UID into
`$objects[N].items[*]`, and each item's `Name` and `Bookmark` fields are
themselves UID-referenced objects elsewhere in `$objects`.

This module does the proper walk:

  1. `resolve_archiver(plist)` → walks `$objects` from `$top.root`, replacing
     every UID with the actual referenced object, converting NSDictionary
     (NS.keys + NS.objects) → real dict and NSArray → list. Returns the
     resolved root dict.
  2. `parse_bookmark_url(blob)` → shells out to `resolve_bookmark.swift`
     (sibling file) to resolve a Foundation bookmark blob into (path, name).
  3. `load_sfl3_items(path)` → end-to-end convenience: resolves the .sfl3 at
     `path` and returns `[{"name", "path", "uuid"} ...]`.

Adapted from `iwork-exporter/scripts/iwork_exporter.py` (which still ships
its own local copy for standalone-package self-containment; reconcile later
if duplication becomes a maintenance burden).
"""
from __future__ import annotations

import json
import plistlib
import subprocess
from pathlib import Path


RESOLVE_BOOKMARK_SWIFT = Path(__file__).resolve().parent / "resolve_bookmark.swift"


def _is_uid(x) -> bool:
    return type(x).__name__ == "UID"


def _uid_value(x) -> int:
    return x.data if hasattr(x, "data") else int(x)


def resolve_archiver(plist: dict) -> object:
    """Walk an NSKeyedArchiver bplist and return the resolved root object.

    Replaces every UID reference with the actual object from `$objects`,
    converting NSDictionary → dict and NSArray → list.
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


def parse_bookmark_url(blob) -> tuple[str | None, str | None]:
    """Resolve a Foundation bookmark blob to (path, name) via NSURL.

    Returns (None, None) on stale/broken bookmarks. Requires
    `/usr/bin/swift` (ships with macOS, no install).
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


def load_sfl3_items(path: str | Path) -> list[dict]:
    """
    Convenience: parse an .sfl3 file and return list of items as dicts with
    `name`, `path`, `uuid`. Empty list if the file is missing, malformed,
    or has no items. Bookmarks are resolved per-item; pass-through if
    resolution fails (path stays empty).
    """
    p = Path(path)
    if not p.exists():
        return []
    try:
        plist = plistlib.loads(p.read_bytes())
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
        resolved_path, resolved_name = (None, None)
        if bookmark:
            resolved_path, resolved_name = parse_bookmark_url(bookmark)
        out.append({
            "name": resolved_name or it.get("Name") or "?",
            "path": resolved_path or "",
            "uuid": it.get("uuid", ""),
        })
    return out
