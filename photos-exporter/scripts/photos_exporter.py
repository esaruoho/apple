#!/usr/bin/env python3
"""photos-exporter — Apple Photos.app catalog via the library SQLite.

Photos.app sdef is limited; the real surface is the SQLite at
~/Pictures/Photos Library.photoslibrary/database/Photos.sqlite. We
read it ?mode=ro&immutable=1 and enumerate albums, smart albums,
keywords, faces, places, and per-asset metadata.

Subcommands (all read-only):
  status      counts overview
  albums      regular + smart albums sorted by photo count
  album       list assets in one album
  keywords    user keyword tags
  places      photos with GPS coordinates (lat/lon ranges)
  favorites   ZFAVORITE = 1 photos
  search      filter by date / album / filename / keyword
  export      markdown vault (albums index + per-album summary)

Disk-lean: never copies image files. The 3.2 GB library stays at
Apple's path; the vault holds metadata only.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sqlite3
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# WAL-safe Apple SQLite snapshot helper. Photos.sqlite is ~3 GB on a real
# library — too costly to snapshot every export. Use immutable; Photos.app's
# WAL writes are slow enough that staleness is rarely material.
sys.path.insert(0, str(ROOT.parent / "bin" / "lib"))
from apple_sqlite_snapshot import open_immutable  # noqa: E402
DEFAULT_ENV = ROOT / ".env"
PHOTOS_LIB = Path(os.path.expanduser("~/Pictures/Photos Library.photoslibrary"))
DB_PATH = PHOTOS_LIB / "database" / "Photos.sqlite"
ORIGINALS = PHOTOS_LIB / "originals"
COCOA_EPOCH = datetime(2001, 1, 1, tzinfo=timezone.utc)

# Schema-version-dependent join table for album↔asset.
# On macOS 15.6.1 it's Z_30ASSETS with columns Z_30ALBUMS + Z_3ASSETS.
# This little detect helper picks the right column names if Apple bumps schema.
_JOIN_COLS_CACHE: dict[str, tuple[str, str, str]] = {}


def _detect_album_asset_join(con: sqlite3.Connection) -> tuple[str, str, str]:
    if "join" in _JOIN_COLS_CACHE:
        return _JOIN_COLS_CACHE["join"]
    # Match Z_<digits>ASSETS that has both an ALBUMS-suffixed and ASSETS-suffixed
    # column — this is the canonical album↔asset join.
    rows = con.execute(
        "SELECT name FROM sqlite_master WHERE type='table' "
        "AND name GLOB 'Z_[0-9]*ASSETS'"
    ).fetchall()
    for (tname,) in rows:
        cols = [c[1] for c in con.execute(f"PRAGMA table_info({tname})").fetchall()]
        album_col = next((c for c in cols if c.endswith("ALBUMS")), None)
        asset_col = next((c for c in cols if c.endswith("ASSETS")), None)
        if album_col and asset_col and album_col != asset_col:
            _JOIN_COLS_CACHE["join"] = (tname, album_col, asset_col)
            return tname, album_col, asset_col
    sys.exit("Could not find album↔asset join table — Photos schema changed?")


def load_env() -> dict[str, str]:
    env: dict[str, str] = {}
    if DEFAULT_ENV.exists():
        for line in DEFAULT_ENV.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            env[k.strip()] = os.path.expanduser(v.strip().strip('"').strip("'"))
    env.setdefault("VAULT_PATH", os.path.expanduser("~/work/apple/exported/photos"))
    env["VAULT_PATH"] = os.path.expanduser(env["VAULT_PATH"])
    return env


def open_ro() -> sqlite3.Connection:
    if not DB_PATH.exists():
        sys.exit(f"Photos library DB not found at {DB_PATH}")
    return open_immutable(DB_PATH)


def cocoa_to_dt(z: float | None) -> datetime | None:
    if z is None:
        return None
    return COCOA_EPOCH + timedelta(seconds=float(z))


def cocoa_to_iso(z: float | None) -> str:
    dt = cocoa_to_dt(z)
    return dt.strftime("%Y-%m-%d %H:%M") if dt else ""


SLUG_RE = re.compile(r"[^a-zA-Z0-9._-]+")


def slugify(s: str, max_len: int = 60) -> str:
    s = SLUG_RE.sub("-", (s or "").strip()).strip("-")
    return (s[:max_len] or "untitled").lower()


# =====================================================================
# Subcommands
# =====================================================================

def cmd_status(args) -> int:
    con = open_ro()
    n_assets = con.execute("SELECT COUNT(*) FROM ZASSET WHERE ZTRASHEDSTATE = 0").fetchone()[0]
    n_videos = con.execute("SELECT COUNT(*) FROM ZASSET WHERE ZTRASHEDSTATE = 0 AND ZKIND = 1").fetchone()[0]
    n_albums = con.execute("SELECT COUNT(*) FROM ZGENERICALBUM WHERE ZTRASHEDSTATE = 0").fetchone()[0]
    n_smart = con.execute("SELECT COUNT(*) FROM ZGENERICALBUM WHERE ZTRASHEDSTATE = 0 AND ZKIND = 1505").fetchone()[0]
    n_fav = con.execute("SELECT COUNT(*) FROM ZASSET WHERE ZFAVORITE = 1 AND ZTRASHEDSTATE = 0").fetchone()[0]
    n_hidden = con.execute("SELECT COUNT(*) FROM ZASSET WHERE ZHIDDEN = 1").fetchone()[0]
    n_geo = con.execute("SELECT COUNT(*) FROM ZASSET WHERE ZLATITUDE IS NOT NULL AND ZLATITUDE != -180 AND ZTRASHEDSTATE = 0").fetchone()[0]
    n_kw = con.execute("SELECT COUNT(*) FROM ZKEYWORD").fetchone()[0]
    con.close()
    print("Photos overview")
    print(f"  Library:       {PHOTOS_LIB}")
    print(f"  DB:            {DB_PATH.stat().st_size:,} bytes")
    print(f"  Assets total:  {n_assets:,}  (videos: {n_videos:,})")
    print(f"  Favorites:     {n_fav:,}")
    print(f"  Hidden:        {n_hidden:,}")
    print(f"  With GPS:      {n_geo:,}")
    print(f"  Albums:        {n_albums:,}  (smart: {n_smart:,})")
    print(f"  Keywords:      {n_kw:,}")
    return 0


def cmd_albums(args) -> int:
    con = open_ro()
    join, album_col, asset_col = _detect_album_asset_join(con)
    rows = con.execute(f"""
        SELECT a.Z_PK, COALESCE(a.ZTITLE,''), a.ZKIND, COUNT(j.{asset_col}) AS n
        FROM ZGENERICALBUM a
        LEFT JOIN {join} j ON j.{album_col} = a.Z_PK
        WHERE a.ZTRASHEDSTATE = 0 AND a.ZTITLE IS NOT NULL AND a.ZTITLE != ''
        GROUP BY a.Z_PK
        ORDER BY n DESC
    """).fetchall()
    con.close()
    if args.smart_only:
        rows = [r for r in rows if r[2] == 1505]
    if args.json:
        print(json.dumps([{
            "id": r[0], "title": r[1], "kind": r[2], "smart": r[2] == 1505,
            "asset_count": r[3]
        } for r in rows], indent=2, ensure_ascii=False))
        return 0
    for pk, title, kind, n in rows[: args.limit or len(rows)]:
        smart = "[smart]" if kind == 1505 else "       "
        print(f"  {n:>5}  {smart}  {title}")
    print(f"\n{len(rows)} album(s)")
    return 0


def cmd_album(args) -> int:
    con = open_ro()
    join, album_col, asset_col = _detect_album_asset_join(con)
    title = args.title
    rows = con.execute(f"""
        SELECT a.Z_PK FROM ZGENERICALBUM a
        WHERE a.ZTITLE = ? AND a.ZTRASHEDSTATE = 0
    """, (title,)).fetchall()
    if not rows:
        # try LIKE
        rows = con.execute(f"""
            SELECT a.Z_PK, a.ZTITLE FROM ZGENERICALBUM a
            WHERE a.ZTITLE LIKE ? AND a.ZTRASHEDSTATE = 0
        """, (f"%{title}%",)).fetchall()
        if not rows:
            sys.exit(f"No album matches {title!r}")
        if len(rows) > 1:
            print(f"Multiple matches for {title!r}:")
            for r in rows[:10]:
                print(f"  {r[1]}")
            sys.exit(1)
    pk = rows[0][0]
    assets = con.execute(f"""
        SELECT z.ZDATECREATED, z.ZFILENAME, z.ZDIRECTORY, z.ZWIDTH, z.ZHEIGHT,
               z.ZKIND, z.ZFAVORITE, z.ZLATITUDE, z.ZLONGITUDE
        FROM ZASSET z
        JOIN {join} j ON j.{asset_col} = z.Z_PK
        WHERE j.{album_col} = ? AND z.ZTRASHEDSTATE = 0
        ORDER BY z.ZDATECREATED ASC
    """, (pk,)).fetchall()
    con.close()
    for d, fn, dr, w, h, k, fav, lat, lon in assets[: args.limit or len(assets)]:
        date = cocoa_to_iso(d)[:16]
        kind = "vid" if k == 1 else "img"
        favstr = "★" if fav else " "
        gps = f"  ({lat:.3f},{lon:.3f})" if lat is not None and lat != -180 else ""
        print(f"  {date}  {kind} {favstr} {w}x{h}  {dr}/{fn}{gps}")
    print(f"\n{len(assets)} asset(s) in album")
    return 0


def cmd_keywords(args) -> int:
    con = open_ro()
    rows = con.execute("""
        SELECT k.ZTITLE, COUNT(*) AS n
        FROM ZKEYWORD k
        JOIN Z_1KEYWORDS j ON j.Z_47KEYWORDS = k.Z_PK
        GROUP BY k.Z_PK ORDER BY n DESC
    """).fetchall()
    con.close()
    for title, n in rows[: args.limit or len(rows)]:
        print(f"  {n:>5}  {title}")
    print(f"\n{len(rows)} keyword(s)")
    return 0


def cmd_places(args) -> int:
    con = open_ro()
    rows = con.execute("""
        SELECT ZDATECREATED, ZFILENAME, ZLATITUDE, ZLONGITUDE
        FROM ZASSET
        WHERE ZLATITUDE IS NOT NULL AND ZLATITUDE != -180
          AND ZTRASHEDSTATE = 0
        ORDER BY ZDATECREATED DESC
        LIMIT ?
    """, (args.limit or 50,)).fetchall()
    con.close()
    for d, fn, lat, lon in rows:
        print(f"  {cocoa_to_iso(d)[:16]}  {lat:>9.4f},{lon:>9.4f}  {fn}")
    return 0


def cmd_favorites(args) -> int:
    con = open_ro()
    rows = con.execute("""
        SELECT ZDATECREATED, ZFILENAME, ZWIDTH, ZHEIGHT, ZKIND
        FROM ZASSET WHERE ZFAVORITE = 1 AND ZTRASHEDSTATE = 0
        ORDER BY ZDATECREATED DESC LIMIT ?
    """, (args.limit or 100,)).fetchall()
    con.close()
    for d, fn, w, h, k in rows:
        kind = "vid" if k == 1 else "img"
        print(f"  {cocoa_to_iso(d)[:16]}  {kind} {w}x{h}  {fn}")
    return 0


def write_md(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)


def cmd_export(args) -> int:
    env = load_env()
    vault = Path(env["VAULT_PATH"])
    vault.mkdir(parents=True, exist_ok=True)
    con = open_ro()
    join, album_col, asset_col = _detect_album_asset_join(con)

    albums = con.execute(f"""
        SELECT a.Z_PK, COALESCE(a.ZTITLE,''), a.ZKIND, COUNT(j.{asset_col}) AS n
        FROM ZGENERICALBUM a
        LEFT JOIN {join} j ON j.{album_col} = a.Z_PK
        WHERE a.ZTRASHEDSTATE = 0 AND a.ZTITLE IS NOT NULL AND a.ZTITLE != ''
        GROUP BY a.Z_PK
        HAVING n > 0
        ORDER BY n DESC
    """).fetchall()

    alb_dir = vault / "albums"
    alb_dir.mkdir(parents=True, exist_ok=True)
    idx = ["# Albums", ""]
    for pk, title, kind, n in albums:
        slug = slugify(title) or f"album-{pk}"
        smart_label = " (smart)" if kind == 1505 else ""
        idx.append(f"- [{title}](./{slug}.md){smart_label} — {n} assets")
        body = ["---",
                f'album: "{title.replace(chr(34), chr(92)+chr(34))}"',
                f'kind: "{"smart" if kind == 1505 else "user"}"',
                f'asset_count: {n}',
                "---", "",
                f"# {title} ({n} assets{smart_label})", ""]
        if not args.heads_only:
            assets = con.execute(f"""
                SELECT z.ZDATECREATED, z.ZFILENAME, z.ZDIRECTORY,
                       z.ZWIDTH, z.ZHEIGHT, z.ZKIND, z.ZFAVORITE,
                       z.ZLATITUDE, z.ZLONGITUDE
                FROM ZASSET z
                JOIN {join} j ON j.{asset_col} = z.Z_PK
                WHERE j.{album_col} = ? AND z.ZTRASHEDSTATE = 0
                ORDER BY z.ZDATECREATED ASC
                LIMIT ?
            """, (pk, args.per_album_limit or 500)).fetchall()
            for d, fn, dr, w, h, k, fav, lat, lon in assets:
                kind_tag = "vid" if k == 1 else "img"
                fav_tag = "★ " if fav else ""
                gps = f"  ({lat:.4f},{lon:.4f})" if lat is not None and lat != -180 else ""
                body.append(f"- `{cocoa_to_iso(d)[:16]}` {fav_tag}{kind_tag} {w}×{h}  `{dr}/{fn}`{gps}")
        write_md(alb_dir / f"{slug}.md", "\n".join(body))
    write_md(alb_dir / "_index.md", "\n".join(idx))

    # keywords
    kws = con.execute("""
        SELECT k.ZTITLE, COUNT(*) FROM ZKEYWORD k
        JOIN Z_1KEYWORDS j ON j.Z_47KEYWORDS = k.Z_PK
        GROUP BY k.Z_PK ORDER BY 2 DESC
    """).fetchall()
    body = ["# Keywords", ""]
    for t, n in kws:
        body.append(f"- {n:>4}  {t}")
    write_md(vault / "keywords.md", "\n".join(body))

    # by year
    year_dir = vault / "by-year"
    year_dir.mkdir(parents=True, exist_ok=True)
    year_rows = con.execute("""
        SELECT strftime('%Y', ZDATECREATED + 978307200, 'unixepoch') AS y, COUNT(*)
        FROM ZASSET WHERE ZTRASHEDSTATE = 0 AND ZDATECREATED IS NOT NULL
        GROUP BY y ORDER BY y DESC
    """).fetchall()
    body = ["# By Year", ""]
    for y, n in year_rows:
        body.append(f"- {y}: {n:,}")
    write_md(year_dir / "_index.md", "\n".join(body))

    con.close()
    n_assets = open_ro().execute("SELECT COUNT(*) FROM ZASSET WHERE ZTRASHEDSTATE = 0").fetchone()[0]
    index = ["# Photos Vault", "",
             f"Generated {datetime.now().isoformat(timespec='seconds')}.", "",
             f"- Assets: {n_assets:,}",
             f"- [Albums](./albums/_index.md) ({len(albums)})",
             f"- [Keywords](./keywords.md) ({len(kws)})",
             f"- [By year](./by-year/_index.md)", ""]
    write_md(vault / "INDEX.md", "\n".join(index))
    print(f"Wrote vault: {vault}")
    print(f"  albums: {len(albums)}  keywords: {len(kws)}  assets: {n_assets:,}")
    return 0


def main() -> int:
    p = argparse.ArgumentParser(prog="photos-exporter")
    sub = p.add_subparsers(dest="cmd", required=True)
    sub.add_parser("status").set_defaults(func=cmd_status)
    sp = sub.add_parser("albums")
    sp.add_argument("--smart-only", action="store_true")
    sp.add_argument("--limit", type=int)
    sp.add_argument("--json", action="store_true")
    sp.set_defaults(func=cmd_albums)
    sp = sub.add_parser("album")
    sp.add_argument("title")
    sp.add_argument("--limit", type=int)
    sp.set_defaults(func=cmd_album)
    sp = sub.add_parser("keywords"); sp.add_argument("--limit", type=int); sp.set_defaults(func=cmd_keywords)
    sp = sub.add_parser("places"); sp.add_argument("--limit", type=int); sp.set_defaults(func=cmd_places)
    sp = sub.add_parser("favorites"); sp.add_argument("--limit", type=int); sp.set_defaults(func=cmd_favorites)
    sp = sub.add_parser("export")
    sp.add_argument("--heads-only", action="store_true",
                    help="Only album index — no per-asset listings")
    sp.add_argument("--per-album-limit", type=int,
                    help="Max assets per album .md (default 500)")
    sp.set_defaults(func=cmd_export)
    args = p.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
