#!/usr/bin/env python3
"""music-exporter — Apple Music.app → markdown vault via AppleScript sdef.

Music.app is Tier 1 (full sdef). Library.musicdb is a private format,
so we go through the AppleScript dictionary which exposes everything
we need: tracks, playlists (including smart playlists), ratings, play
counts, last-played dates.

Subcommands (all read-only):
  status         counts overview (tracks, playlists, sources)
  playlists      list all playlists + per-playlist track counts
  tracks         list tracks (--playlist NAME, --match REGEX, --limit N)
  artists        artists by track count
  albums         albums by track count
  smart          list smart playlists
  export         markdown vault dump
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from collections import Counter
from dataclasses import dataclass
from pathlib import Path
from datetime import datetime

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_ENV = ROOT / ".env"


def load_env() -> dict[str, str]:
    env: dict[str, str] = {}
    if DEFAULT_ENV.exists():
        for line in DEFAULT_ENV.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            env[k.strip()] = os.path.expanduser(v.strip().strip('"').strip("'"))
    env.setdefault("VAULT_PATH", os.path.expanduser("~/work/apple/exported/music"))
    env["VAULT_PATH"] = os.path.expanduser(env["VAULT_PATH"])
    return env


SLUG_RE = re.compile(r"[^a-zA-Z0-9._-]+")


def slugify(s: str, max_len: int = 60) -> str:
    s = SLUG_RE.sub("-", (s or "").strip()).strip("-")
    return (s[:max_len] or "untitled").lower()


def osascript(src: str) -> str:
    proc = subprocess.run(["osascript", "-e", src],
                          capture_output=True, text=True, check=False, timeout=120)
    if proc.returncode != 0:
        sys.stderr.write(proc.stderr)
        return ""
    return proc.stdout


# Use Music's parallel-array idiom (tested elsewhere in the family) to
# avoid the per-property-fetch slowdown.

def music_counts() -> dict:
    out = osascript('''
    tell application "Music"
        set t to count of tracks
        set p to count of playlists
        return (t as text) & "|" & (p as text)
    end tell
    ''').strip()
    if not out or "|" not in out:
        return {"tracks": 0, "playlists": 0}
    parts = out.split("|")
    return {"tracks": int(parts[0]), "playlists": int(parts[1])}


def music_playlists() -> list[dict]:
    """Return all playlists with name + track-count + smart flag.

    `smart` is only valid on user playlists; library / radio / Apple-Music-
    sourced playlists raise -1728 in bulk. We query smart playlists
    separately by class and intersect by name.
    """
    src = '''
    set US to (ASCII character 31)
    set RS to (ASCII character 30)
    set out to ""
    tell application "Music"
        set ns to name of playlists of source "Library"
        set n to count of ns
        repeat with i from 1 to n
            try
                set pname to (item i of ns as text)
                set ptc to (count of tracks of playlist pname of source "Library")
            on error
                set ptc to 0
            end try
            set out to out & pname & US & (ptc as text) & RS
        end repeat
    end tell
    return out
    '''
    raw = osascript(src)
    out = []
    for rec in raw.split("\x1e"):
        if not rec.strip():
            continue
        parts = rec.split("\x1f")
        if len(parts) < 2:
            continue
        out.append({
            "name": parts[0],
            "track_count": int(parts[1] or 0),
            "smart": False,  # filled in below
        })
    # Mark smart playlists.
    smart_src = '''
    set RS to (ASCII character 30)
    set out to ""
    try
        tell application "Music"
            set theList to (every user playlist of source "Library" whose smart is true)
            set n to count of theList
            if n > 0 then
                set ns to name of theList
                repeat with i from 1 to n
                    set out to out & (item i of ns as text) & RS
                end repeat
            end if
        end tell
    end try
    return out
    '''
    smart_raw = osascript(smart_src)
    smart_names = {x.strip() for x in smart_raw.split("\x1e") if x.strip()}
    for p in out:
        if p["name"] in smart_names:
            p["smart"] = True
    return out


def music_tracks(playlist: str | None = None, limit: int | None = None) -> list[dict]:
    target = (
        f'set theTracks to tracks of playlist "{playlist}" of source "Library"'
        if playlist else 'set theTracks to tracks of source "Library"'
    )
    src = f'''
    set US to (ASCII character 31)
    set RS to (ASCII character 30)
    tell application "Music"
        {target}
        set ns to name of theTracks
        set ar to artist of theTracks
        set al to album of theTracks
        set du to duration of theTracks
        set rt to rating of theTracks
        set pc to played count of theTracks
        set ye to year of theTracks
    end tell
    set out to ""
    set n to count of ns
    repeat with i from 1 to n
        set out to out & (item i of ns) & US & (item i of ar) & US & (item i of al) & US & (item i of du) & US & (item i of rt) & US & (item i of pc) & US & (item i of ye) & RS
    end repeat
    return out
    '''
    raw = osascript(src)
    out = []
    for rec in raw.split("\x1e"):
        if not rec.strip():
            continue
        parts = rec.split("\x1f")
        if len(parts) < 7:
            continue
        out.append({
            "name": parts[0], "artist": parts[1], "album": parts[2],
            "duration": float(parts[3] or 0),
            "rating": int(parts[4] or 0),
            "played_count": int(parts[5] or 0),
            "year": int(parts[6] or 0),
        })
        if limit and len(out) >= limit:
            break
    return out


# =====================================================================
# Subcommands
# =====================================================================

def cmd_status(args) -> int:
    c = music_counts()
    print("Music overview")
    print(f"  Tracks:    {c['tracks']:,}")
    print(f"  Playlists: {c['playlists']:,}")
    return 0


def cmd_playlists(args) -> int:
    pls = music_playlists()
    if args.json:
        print(json.dumps(pls, indent=2, ensure_ascii=False))
        return 0
    if args.smart_only:
        pls = [p for p in pls if p["smart"]]
    for p in sorted(pls, key=lambda p: -p["track_count"])[: args.limit or len(pls)]:
        kind = "[smart]" if p["smart"] else "       "
        print(f"  {p['track_count']:>5}  {kind}  {p['name']}")
    print(f"\n{len(pls)} playlist(s)")
    return 0


def cmd_smart(args) -> int:
    pls = [p for p in music_playlists() if p["smart"]]
    for p in sorted(pls, key=lambda p: -p["track_count"]):
        print(f"  {p['track_count']:>5}  {p['name']}")
    print(f"\n{len(pls)} smart playlist(s)")
    return 0


def cmd_tracks(args) -> int:
    tracks = music_tracks(playlist=args.playlist, limit=args.limit)
    if args.match:
        rx = re.compile(args.match, re.I)
        tracks = [t for t in tracks if any(rx.search(t.get(k, "") or "") for k in ("name", "artist", "album"))]
    if args.json:
        print(json.dumps(tracks, indent=2, ensure_ascii=False))
        return 0
    for t in tracks:
        rating = "★" * (t["rating"] // 20) if t["rating"] else " "
        dur = int(t["duration"])
        m, s = divmod(dur, 60)
        print(f"  {rating:<5}  {m:>3}:{s:02}  {t['played_count']:>4}×  "
              f"{t['name']:<40}  {t['artist']:<25}  {t['album'][:30]}")
    print(f"\n{len(tracks)} track(s)")
    return 0


def cmd_artists(args) -> int:
    tracks = music_tracks()
    counter: Counter = Counter(t["artist"] for t in tracks if t["artist"])
    for a, n in counter.most_common(args.limit or 50):
        print(f"  {n:>5}  {a}")
    print(f"\n{len(counter)} unique artist(s) across {len(tracks)} tracks")
    return 0


def cmd_albums(args) -> int:
    tracks = music_tracks()
    counter: Counter = Counter()
    for t in tracks:
        if t["album"] and t["artist"]:
            counter[f"{t['artist']} — {t['album']}"] += 1
    for a, n in counter.most_common(args.limit or 50):
        print(f"  {n:>4}  {a}")
    print(f"\n{len(counter)} unique album(s)")
    return 0


def write_md(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)


def cmd_export(args) -> int:
    env = load_env()
    vault = Path(env["VAULT_PATH"])
    vault.mkdir(parents=True, exist_ok=True)
    pls = music_playlists()
    counts = music_counts()
    stamp = datetime.now().isoformat(timespec="seconds")

    pl_dir = vault / "playlists"
    pl_dir.mkdir(parents=True, exist_ok=True)
    pl_idx = ["# Playlists", ""]
    for p in sorted(pls, key=lambda p: -p["track_count"]):
        if p["track_count"] == 0:
            continue
        kind = "smart" if p["smart"] else "user"
        slug = slugify(p["name"]) or f"playlist"
        pl_idx.append(f"- [{p['name']}](./{slug}.md) — "
                      f"{p['track_count']} tracks ({kind})")
        if args.with_tracks:
            tracks = music_tracks(playlist=p["name"])
            body = ["---",
                    f'playlist: "{p["name"]}"',
                    f'kind: "{kind}"',
                    f'track_count: {p["track_count"]}',
                    "---", "",
                    f"# {p['name']} ({p['track_count']} tracks, {kind})", ""]
            for t in tracks:
                rating = "★" * (t["rating"] // 20) if t["rating"] else ""
                body.append(f"- {t['name']} — *{t['artist']}* — _{t['album']}_  {rating}".rstrip())
            write_md(pl_dir / f"{slug}.md", "\n".join(body))
        else:
            body = ["---",
                    f'playlist: "{p["name"]}"',
                    f'kind: "{kind}"',
                    f'track_count: {p["track_count"]}',
                    "---", "",
                    f"# {p['name']} ({p['track_count']} tracks, {kind})", "",
                    "_Run `music-exporter export --with-tracks` to populate._"]
            write_md(pl_dir / f"{slug}.md", "\n".join(body))
    write_md(pl_dir / "_index.md", "\n".join(pl_idx))

    index = ["# Music Vault", "",
             f"Generated {stamp}.", "",
             f"- Tracks: {counts['tracks']:,}",
             f"- Playlists: {counts['playlists']:,} (see [./playlists/_index.md](./playlists/_index.md))",
             ""]
    write_md(vault / "INDEX.md", "\n".join(index))
    print(f"Wrote vault: {vault}")
    print(f"  playlists: {len(pls)}  tracks (live): {counts['tracks']:,}")
    if not args.with_tracks:
        print("  (per-playlist track lists empty; pass --with-tracks to populate)")
    return 0


def main() -> int:
    p = argparse.ArgumentParser(prog="music-exporter")
    sub = p.add_subparsers(dest="cmd", required=True)
    sub.add_parser("status").set_defaults(func=cmd_status)
    sp = sub.add_parser("playlists")
    sp.add_argument("--smart-only", action="store_true")
    sp.add_argument("--limit", type=int)
    sp.add_argument("--json", action="store_true")
    sp.set_defaults(func=cmd_playlists)
    sub.add_parser("smart").set_defaults(func=cmd_smart)
    sp = sub.add_parser("tracks")
    sp.add_argument("--playlist", help="restrict to one playlist")
    sp.add_argument("--match", help="regex over name/artist/album")
    sp.add_argument("--limit", type=int)
    sp.add_argument("--json", action="store_true")
    sp.set_defaults(func=cmd_tracks)
    sp = sub.add_parser("artists"); sp.add_argument("--limit", type=int); sp.set_defaults(func=cmd_artists)
    sp = sub.add_parser("albums"); sp.add_argument("--limit", type=int); sp.set_defaults(func=cmd_albums)
    sp = sub.add_parser("export")
    sp.add_argument("--with-tracks", action="store_true",
                    help="Include track lists in per-playlist .md "
                         "(slower; without this only the playlist index is populated)")
    sp.set_defaults(func=cmd_export)
    args = p.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
