#!/usr/bin/env python3
"""finder-exporter — Finder tags, sidebar, recents, label colors.

Three back-doors:
  - mdfind for tag queries (`mdfind 'kMDItemUserTags == "*"'`)
  - ~/Library/Application Support/com.apple.sharedfilelist/*.sfl3 (NSKeyedArchiver bplist)
  - ~/Library/Preferences/com.apple.finder.plist for tag colors and view settings

Subcommands:
  status        counts overview
  tags          list every Finder tag in use + count of files with that tag
  tag-files     list every file with a given tag
  recents       recent docs (LSSharedFileList)
  favorites     sidebar favorites
  export        full markdown vault
"""

from __future__ import annotations

import argparse
import json
import os
import plistlib
import re
import subprocess
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_ENV = ROOT / ".env"
SFL_DIR = Path(os.path.expanduser(
    "~/Library/Application Support/com.apple.sharedfilelist"
))
FINDER_PLIST = Path(os.path.expanduser("~/Library/Preferences/com.apple.finder.plist"))


def load_env() -> dict[str, str]:
    env: dict[str, str] = {}
    if DEFAULT_ENV.exists():
        for line in DEFAULT_ENV.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            env[k.strip()] = os.path.expanduser(v.strip().strip('"').strip("'"))
    env.setdefault("VAULT_PATH", os.path.expanduser("~/work/apple/exported/finder"))
    env["VAULT_PATH"] = os.path.expanduser(env["VAULT_PATH"])
    return env


def mdfind(query: str, limit: int | None = None) -> list[str]:
    proc = subprocess.run(["mdfind", query], capture_output=True, text=True,
                          check=False, timeout=30)
    paths = [l for l in proc.stdout.splitlines() if l]
    return paths[:limit] if limit else paths


def get_user_tags(path: str) -> list[str]:
    proc = subprocess.run(["mdls", "-name", "kMDItemUserTags", "-raw", path],
                          capture_output=True, text=True, check=False, timeout=10)
    if proc.returncode != 0:
        return []
    out = proc.stdout.strip()
    if out.startswith("(") and out.endswith(")"):
        # Comma-separated list inside parens
        inner = out[1:-1]
        tags = [t.strip().strip('"') for t in inner.split(",") if t.strip()]
        # Tag entries can include color suffix: "Music\n6"
        return [t.split("\n")[0] for t in tags]
    return []


def all_tagged_files() -> list[str]:
    return mdfind('kMDItemUserTags == "*"')


# =====================================================================
# .sfl3 NSKeyedArchiver decode
# =====================================================================

def decode_sfl3(path: Path) -> list[dict]:
    """Walk an LSSharedFileList .sfl3 file and return [{name, url, ...}]."""
    if not path.exists():
        return []
    try:
        with open(path, "rb") as f:
            data = f.read()
        plist = plistlib.loads(data)
    except Exception:
        return []
    objs = plist.get("$objects") or []
    if not objs:
        return []
    out: list[dict] = []
    for o in objs:
        if not isinstance(o, dict):
            continue
        # Items typically have "Name" + "Bookmark" (URL bookmark blob)
        name = o.get("Name") or o.get("name") or ""
        bookmark = o.get("Bookmark") or o.get("bookmark")
        if name and isinstance(name, str):
            row = {"name": name}
            if isinstance(bookmark, (bytes, bytearray)):
                # extract a printable URL fragment if visible
                m = re.search(rb"file://[^\x00]+", bookmark)
                if m:
                    row["url_hint"] = m.group(0).decode("utf-8", errors="replace")
            out.append(row)
    return out


# =====================================================================
# Subcommands
# =====================================================================

def cmd_status(args) -> int:
    files = all_tagged_files()
    print("Finder overview")
    print(f"  Tagged files (mdfind): {len(files)}")
    sfls = list(SFL_DIR.glob("*/*.sfl3")) + list(SFL_DIR.glob("*.sfl3"))
    print(f"  SFL3 lists found:      {len(sfls)}")
    return 0


def cmd_tags(args) -> int:
    files = all_tagged_files()
    counter: Counter = Counter()
    for f in files:
        for t in get_user_tags(f):
            counter[t] += 1
    if args.json:
        print(json.dumps([{"tag": t, "file_count": n}
                          for t, n in counter.most_common()], indent=2, ensure_ascii=False))
        return 0
    for t, n in counter.most_common():
        print(f"  {n:>5}  {t}")
    print(f"\n{len(counter)} tag(s) across {len(files)} file(s)")
    return 0


def cmd_tag_files(args) -> int:
    paths = mdfind(f'kMDItemUserTags == "{args.tag}"')
    for p in paths[: args.limit or len(paths)]:
        print(f"  {p}")
    print(f"\n{len(paths)} file(s) tagged {args.tag!r}")
    return 0


def cmd_recents(args) -> int:
    sfl = SFL_DIR / "com.apple.LSSharedFileList.RecentDocuments.sfl3"
    items = decode_sfl3(sfl)
    if args.json:
        print(json.dumps(items, indent=2, ensure_ascii=False))
        return 0
    for it in items[: args.limit or len(items)]:
        print(f"  {it.get('name', '?')}")
    print(f"\n{len(items)} recent doc(s)")
    return 0


def cmd_favorites(args) -> int:
    sfl = SFL_DIR / "com.apple.LSSharedFileList.FavoriteItems.sfl3"
    items = decode_sfl3(sfl)
    if args.json:
        print(json.dumps(items, indent=2, ensure_ascii=False))
        return 0
    for it in items:
        print(f"  {it.get('name', '?')}")
    return 0


def write_md(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)


def cmd_export(args) -> int:
    env = load_env()
    vault = Path(env["VAULT_PATH"])
    vault.mkdir(parents=True, exist_ok=True)
    files = all_tagged_files()
    by_tag: dict[str, list[str]] = defaultdict(list)
    for f in files:
        for t in get_user_tags(f):
            by_tag[t].append(f)

    tag_dir = vault / "tags"
    tag_dir.mkdir(parents=True, exist_ok=True)
    tag_idx = ["# Finder Tags", ""]
    for t in sorted(by_tag, key=lambda k: -len(by_tag[k])):
        slug = re.sub(r"[^a-zA-Z0-9._-]+", "-", t).strip("-").lower() or "untitled"
        tag_idx.append(f"- [{t}](./{slug}.md) — {len(by_tag[t])} files")
        body = [f"# {t} ({len(by_tag[t])} files)", ""]
        for p in sorted(by_tag[t]):
            body.append(f"- `{p}`")
        write_md(tag_dir / f"{slug}.md", "\n".join(body))
    write_md(tag_dir / "_index.md", "\n".join(tag_idx))

    # recents + favorites
    for label, sfl_name in [
        ("recents", "com.apple.LSSharedFileList.RecentDocuments.sfl3"),
        ("favorites", "com.apple.LSSharedFileList.FavoriteItems.sfl3"),
        ("recent-applications", "com.apple.LSSharedFileList.RecentApplications.sfl3"),
        ("recent-hosts", "com.apple.LSSharedFileList.RecentHosts.sfl3"),
        ("recent-servers", "com.apple.LSSharedFileList.RecentServers.sfl3"),
        ("favorite-volumes", "com.apple.LSSharedFileList.FavoriteVolumes.sfl3"),
        ("icloud-items", "com.apple.LSSharedFileList.iCloudItems.sfl3"),
    ]:
        items = decode_sfl3(SFL_DIR / sfl_name)
        body = [f"# {label} ({len(items)})", ""]
        for it in items:
            body.append(f"- {it.get('name', '?')}")
        write_md(vault / f"{label}.md", "\n".join(body))

    index = ["# Finder Vault", "",
             f"- [Tags]({tag_dir.name}/_index.md) ({len(by_tag)} unique, "
             f"{len(files)} tagged files)",
             "- [Recents](./recents.md)",
             "- [Favorites](./favorites.md)",
             "- [Recent applications](./recent-applications.md)",
             "- [Recent hosts](./recent-hosts.md)",
             "- [Recent servers](./recent-servers.md)",
             "- [Favorite volumes](./favorite-volumes.md)",
             "- [iCloud items](./icloud-items.md)", ""]
    write_md(vault / "INDEX.md", "\n".join(index))
    print(f"Wrote vault: {vault}")
    print(f"  tags: {len(by_tag)}  tagged files: {len(files)}")
    return 0


def main() -> int:
    p = argparse.ArgumentParser(prog="finder-exporter")
    sub = p.add_subparsers(dest="cmd", required=True)
    sub.add_parser("status").set_defaults(func=cmd_status)
    sp = sub.add_parser("tags"); sp.add_argument("--json", action="store_true"); sp.set_defaults(func=cmd_tags)
    sp = sub.add_parser("tag-files"); sp.add_argument("tag"); sp.add_argument("--limit", type=int); sp.set_defaults(func=cmd_tag_files)
    sp = sub.add_parser("recents"); sp.add_argument("--limit", type=int); sp.add_argument("--json", action="store_true"); sp.set_defaults(func=cmd_recents)
    sp = sub.add_parser("favorites"); sp.add_argument("--json", action="store_true"); sp.set_defaults(func=cmd_favorites)
    sub.add_parser("export").set_defaults(func=cmd_export)
    args = p.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
