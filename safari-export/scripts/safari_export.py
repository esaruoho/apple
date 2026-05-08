#!/usr/bin/env python3
"""safari-export — read-only catalog + markdown vault for Safari data.

Reads SafariTabs.db, CloudTabs.db, History.db, and (optionally) live
Safari via AppleScript. Never writes to Apple's stores. Output goes
into a user-configurable vault as markdown / json / csv.

Subcommands:
  windows          List Safari windows + tab-group breakdown
  tabs             Filtered listing of open tabs (across all windows)
  tabgroups        List named tab groups + counts
  bookmarks        List bookmark folders / tree
  icloud-tabs      Tabs synced from other devices via iCloud
  history          Browsing history (filtered)
  search           Cross-search tabs + bookmarks + history
  export           Full markdown vault dump
  status           Counts overview

All read-only. No tabs closed, no bookmarks moved, no rows deleted.
"""

from __future__ import annotations

import argparse
import csv as csvmod
import json
import os
import re
import sqlite3
import sys
from collections import defaultdict
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_ENV = ROOT / ".env"

SAFARI_TABS_DB = Path(os.path.expanduser(
    "~/Library/Containers/com.apple.Safari/Data/Library/Safari/SafariTabs.db"
))
CLOUD_TABS_DB = Path(os.path.expanduser(
    "~/Library/Containers/com.apple.Safari/Data/Library/Safari/CloudTabs.db"
))
HISTORY_DB = Path(os.path.expanduser(
    "~/Library/Safari/History.db"
))

COCOA_EPOCH = datetime(2001, 1, 1, tzinfo=timezone.utc)


def cocoa_to_dt(z: float | None) -> datetime | None:
    if z is None:
        return None
    return COCOA_EPOCH + timedelta(seconds=float(z))


def cocoa_to_iso(z: float | None) -> str:
    dt = cocoa_to_dt(z)
    return dt.strftime("%Y-%m-%d %H:%M:%S") if dt else ""


def load_env() -> dict[str, str]:
    env: dict[str, str] = {}
    if DEFAULT_ENV.exists():
        for line in DEFAULT_ENV.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            env[k.strip()] = os.path.expanduser(v.strip().strip('"').strip("'"))
    env.setdefault("VAULT_PATH", os.path.expanduser("~/safari-vault"))
    env["VAULT_PATH"] = os.path.expanduser(env["VAULT_PATH"])
    return env


def open_ro(path: Path) -> sqlite3.Connection:
    if not path.exists():
        sys.exit(f"DB not found at {path}.\n"
                 "Grant Full Disk Access to Terminal in System Settings → Privacy & Security.")
    uri = f"file:{path}?mode=ro&immutable=1"
    return sqlite3.connect(uri, uri=True)


SLUG_RE = re.compile(r"[^a-zA-Z0-9._-]+")


def slugify(s: str, max_len: int = 80) -> str:
    s = (s or "").strip()
    s = SLUG_RE.sub("-", s).strip("-")
    return (s[:max_len] or "untitled").lower()


# =====================================================================
# Data model
# =====================================================================

@dataclass
class TabGroup:
    id: int
    title: str
    num_children: int
    is_local: bool       # the unnamed "Local" tab group of a window
    is_private: bool     # private-browsing tab group
    window_id: int | None


@dataclass
class Tab:
    id: int
    parent: int
    url: str
    title: str
    order_index: int
    last_modified: float | None
    tab_group_id: int


@dataclass
class WindowInfo:
    id: int
    scene_id: str
    is_last_session: bool
    local_tab_group_id: int | None
    private_tab_group_id: int | None
    tab_groups: list[TabGroup]
    total_tabs: int


@dataclass
class CloudTab:
    device_uuid: str
    device_name: str
    device_type: str
    title: str
    url: str
    last_modified: float | None


@dataclass
class HistoryItem:
    id: int
    url: str
    title: str
    visit_count: int
    last_visit: float | None


@dataclass
class Bookmark:
    id: int
    parent: int | None
    type: int            # 0 = leaf URL, 1 = folder/group
    title: str
    url: str
    num_children: int
    order_index: int
    last_modified: float | None


# =====================================================================
# Loaders
# =====================================================================

def load_windows() -> list[WindowInfo]:
    """Walk SafariTabs.db: windows + their tab groups + tab counts."""
    con = open_ro(SAFARI_TABS_DB)

    rows = con.execute("""
        SELECT id, scene_id, is_last_session, local_tab_group_id, private_tab_group_id
        FROM windows
        ORDER BY id
    """).fetchall()

    windows: list[WindowInfo] = []
    for wid, scene_id, is_last, local_tg, private_tg in rows:
        groups: list[TabGroup] = []
        # named/local tab groups visible in this window.
        # Exclude tab_group_id=0 — that's the synthetic bookmarks Root,
        # not a real tab group. Including it would double-count the
        # entire bookmark tree as "tabs in this window".
        join_rows = con.execute("""
            SELECT b.id, b.title, b.num_children
            FROM windows_tab_groups wtg
            JOIN bookmarks b ON b.id = wtg.tab_group_id
            WHERE wtg.window_id = ? AND b.deleted = 0 AND wtg.tab_group_id != 0
        """, (wid,)).fetchall()
        for tg_id, tg_title, num in join_rows:
            is_local = (tg_id == local_tg)
            groups.append(TabGroup(
                id=tg_id, title=tg_title or "(unnamed)",
                num_children=num or 0, is_local=is_local, is_private=False,
                window_id=wid,
            ))
        # tab counts via recursive descent from each tab group
        total = 0
        for g in groups:
            cnt = con.execute("""
                WITH RECURSIVE descendants(id) AS (
                  SELECT id FROM bookmarks WHERE id = ?
                  UNION ALL
                  SELECT b.id FROM bookmarks b JOIN descendants d ON b.parent = d.id
                  WHERE b.deleted = 0
                )
                SELECT COUNT(*) FROM descendants d
                JOIN bookmarks b ON b.id = d.id
                WHERE b.type = 0
            """, (g.id,)).fetchone()[0]
            g.num_children = cnt
            total += cnt
        windows.append(WindowInfo(
            id=wid, scene_id=scene_id or "",
            is_last_session=bool(is_last),
            local_tab_group_id=local_tg,
            private_tab_group_id=private_tg,
            tab_groups=sorted(groups, key=lambda g: (-g.num_children, g.title or "")),
            total_tabs=total,
        ))
    con.close()
    return windows


def load_tabs(window_id: int | None = None,
              tab_group_name: str | None = None) -> list[Tab]:
    """Recursive descent of bookmarks to collect leaf tabs."""
    con = open_ro(SAFARI_TABS_DB)
    if window_id is not None:
        roots = [r[0] for r in con.execute(
            "SELECT local_tab_group_id FROM windows WHERE id = ?", (window_id,)
        ).fetchall() if r[0] is not None]
    elif tab_group_name is not None:
        roots = [r[0] for r in con.execute(
            "SELECT id FROM bookmarks WHERE title = ? AND type = 1 AND deleted = 0",
            (tab_group_name,)
        ).fetchall()]
    else:
        # all open tabs across all windows: every window's local + named groups
        roots = [r[0] for r in con.execute("""
            SELECT DISTINCT tab_group_id FROM windows_tab_groups
        """).fetchall()]

    tabs: list[Tab] = []
    for root in roots:
        rows = con.execute("""
            WITH RECURSIVE descendants(id) AS (
              SELECT id FROM bookmarks WHERE id = ?
              UNION ALL
              SELECT b.id FROM bookmarks b JOIN descendants d ON b.parent = d.id
              WHERE b.deleted = 0
            )
            SELECT b.id, b.parent, COALESCE(b.url,''), COALESCE(b.title,''),
                   b.order_index, b.last_modified
            FROM descendants d
            JOIN bookmarks b ON b.id = d.id
            WHERE b.type = 0 AND b.deleted = 0
            ORDER BY b.parent, b.order_index
        """, (root,)).fetchall()
        for tid, parent, url, title, oi, lm in rows:
            tabs.append(Tab(id=tid, parent=parent, url=url, title=title,
                            order_index=oi or 0, last_modified=lm,
                            tab_group_id=root))
    con.close()
    return tabs


def load_tabgroups() -> list[TabGroup]:
    con = open_ro(SAFARI_TABS_DB)
    rows = con.execute("""
        SELECT b.id, b.title, b.num_children, wtg.window_id
        FROM bookmarks b
        JOIN windows_tab_groups wtg ON wtg.tab_group_id = b.id
        WHERE b.deleted = 0 AND wtg.tab_group_id != 0
        ORDER BY b.title
    """).fetchall()
    out = []
    for tg_id, title, num, wid in rows:
        # recompute count via descent (the column is sometimes stale)
        cnt = con.execute("""
            WITH RECURSIVE d(id) AS (
              SELECT id FROM bookmarks WHERE id = ?
              UNION ALL
              SELECT b.id FROM bookmarks b JOIN d ON b.parent = d.id
              WHERE b.deleted = 0
            )
            SELECT COUNT(*) FROM d JOIN bookmarks b ON b.id = d.id WHERE b.type = 0
        """, (tg_id,)).fetchone()[0]
        is_local = (title or "").lower() == "local"
        out.append(TabGroup(id=tg_id, title=title or "(unnamed)",
                            num_children=cnt, is_local=is_local,
                            is_private=False, window_id=wid))
    con.close()
    return out


def load_bookmarks(parent: int | None = None) -> list[Bookmark]:
    con = open_ro(SAFARI_TABS_DB)
    if parent is None:
        # Real top-level bookmark folders. Excluded:
        #   special_id != 0  → reserved system slots (Recovered/pinned/etc.)
        #   in windows_tab_groups → shown elsewhere as tab groups
        #   empty title or num_children == 0 → system placeholders / private
        rows = con.execute("""
            SELECT id, parent, type, title, COALESCE(url,''), num_children,
                   order_index, last_modified
            FROM bookmarks
            WHERE deleted = 0
              AND (parent IS NULL OR parent = 0)
              AND type = 1
              AND special_id = 0
              AND num_children > 0
              AND title IS NOT NULL AND title != ''
              AND title NOT IN ('Private', 'privatePinned', 'recentlyClosed', 'Recovered', 'Local')
              AND id NOT IN (SELECT tab_group_id FROM windows_tab_groups)
            ORDER BY title
        """).fetchall()
    else:
        rows = con.execute("""
            SELECT id, parent, type, title, COALESCE(url,''), num_children,
                   order_index, last_modified
            FROM bookmarks
            WHERE deleted = 0 AND parent = ?
            ORDER BY order_index
        """, (parent,)).fetchall()
    con.close()
    return [Bookmark(id=r[0], parent=r[1], type=r[2], title=r[3] or "",
                     url=r[4], num_children=r[5] or 0,
                     order_index=r[6] or 0, last_modified=r[7])
            for r in rows]


def load_bookmark_tree(root: int) -> dict:
    """Return nested dict: {bookmark, children: [bookmark, ...]}."""
    con = open_ro(SAFARI_TABS_DB)
    def walk(node_id: int) -> dict:
        row = con.execute("""
            SELECT id, parent, type, COALESCE(title,''), COALESCE(url,''),
                   num_children, order_index, last_modified
            FROM bookmarks WHERE id = ? AND deleted = 0
        """, (node_id,)).fetchone()
        if not row:
            return {}
        bm = Bookmark(id=row[0], parent=row[1], type=row[2], title=row[3],
                      url=row[4], num_children=row[5] or 0,
                      order_index=row[6] or 0, last_modified=row[7])
        children = []
        if bm.type == 1:
            child_rows = con.execute("""
                SELECT id FROM bookmarks
                WHERE parent = ? AND deleted = 0
                ORDER BY order_index
            """, (node_id,)).fetchall()
            for (cid,) in child_rows:
                children.append(walk(cid))
        return {"bm": bm, "children": children}
    tree = walk(root)
    con.close()
    return tree


def load_cloud_tabs(device_filter: str | None = None) -> list[CloudTab]:
    if not CLOUD_TABS_DB.exists():
        return []
    con = open_ro(CLOUD_TABS_DB)
    rows = con.execute("""
        SELECT t.device_uuid, COALESCE(d.device_name,''),
               COALESCE(d.device_type_identifier,''),
               COALESCE(t.title,''), COALESCE(t.url,''), t.last_viewed_time
        FROM cloud_tabs t
        LEFT JOIN cloud_tab_devices d ON d.device_uuid = t.device_uuid
        ORDER BY d.device_name, t.last_viewed_time DESC
    """).fetchall()
    con.close()
    out = [CloudTab(*r) for r in rows]
    if device_filter:
        f = device_filter.lower()
        out = [c for c in out if f in (c.device_name or "").lower()]
    return out


def load_history(since: datetime | None = None,
                 match: str | None = None,
                 limit: int | None = None) -> list[HistoryItem]:
    con = open_ro(HISTORY_DB)
    sql = """
        SELECT i.id, i.url,
               COALESCE(MAX(v.title),'') AS title,
               i.visit_count,
               MAX(v.visit_time) AS last_visit
        FROM history_items i
        LEFT JOIN history_visits v ON v.history_item = i.id
        GROUP BY i.id
    """
    having = []
    params: list = []
    if since:
        cocoa_since = (since - COCOA_EPOCH).total_seconds()
        having.append("last_visit >= ?")
        params.append(cocoa_since)
    if match:
        having.append("(i.url LIKE ? OR title LIKE ?)")
        like = f"%{match}%"
        params += [like, like]
    if having:
        sql += " HAVING " + " AND ".join(having)
    sql += " ORDER BY last_visit DESC"
    if limit:
        sql += f" LIMIT {int(limit)}"
    out = []
    for row in con.execute(sql, params):
        out.append(HistoryItem(id=row[0], url=row[1] or "",
                               title=row[2] or "", visit_count=row[3] or 0,
                               last_visit=row[4]))
    con.close()
    return out


# =====================================================================
# Filter helpers (for tabs and cloud tabs)
# =====================================================================

def filter_tabs(tabs: list[Tab], match: str | None,
                domain: str | None) -> list[Tab]:
    if match:
        pat = re.compile(match, re.I)
        tabs = [t for t in tabs if pat.search(t.title or "") or pat.search(t.url or "")]
    if domain:
        d = domain.lower()
        tabs = [t for t in tabs if d in (t.url or "").lower()]
    return tabs


# =====================================================================
# Output: markdown helpers
# =====================================================================

def md_link(title: str, url: str) -> str:
    title = (title or "").replace("|", "\\|").replace("\n", " ").strip() or "(untitled)"
    return f"- [{title}]({url})"


def write_md(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)


# =====================================================================
# Subcommands
# =====================================================================

def cmd_status(args) -> int:
    win = load_windows()
    cloud = load_cloud_tabs()
    cloud_devices: dict[str, int] = defaultdict(int)
    for c in cloud:
        cloud_devices[c.device_name or c.device_uuid] += 1

    tabs = load_tabs()
    tg = load_tabgroups()

    con = open_ro(SAFARI_TABS_DB)
    bm_total = con.execute("SELECT COUNT(*) FROM bookmarks WHERE deleted=0 AND type=0").fetchone()[0]
    bm_folders = con.execute("SELECT COUNT(*) FROM bookmarks WHERE deleted=0 AND type=1").fetchone()[0]
    con.close()
    con2 = open_ro(HISTORY_DB)
    h_items = con2.execute("SELECT COUNT(*) FROM history_items").fetchone()[0]
    h_visits = con2.execute("SELECT COUNT(*) FROM history_visits").fetchone()[0]
    con2.close()

    print("Safari overview")
    print(f"  Windows:       {len(win)}")
    for w in win:
        print(f"    window {w.id:<3} {w.total_tabs:>4} tabs across "
              f"{len(w.tab_groups)} tab group(s)")
    print(f"  Total open tabs:    {sum(w.total_tabs for w in win)}")
    print(f"  Tab groups:         {len(tg)}")
    print(f"  Bookmarks (URLs):   {bm_total}")
    print(f"  Bookmark folders:   {bm_folders}")
    print(f"  iCloud tabs:        {len(cloud)}")
    for n, c in sorted(cloud_devices.items(), key=lambda x: -x[1]):
        print(f"    {n}: {c}")
    print(f"  History URLs:       {h_items} ({h_visits} total visits)")
    return 0


def cmd_windows(args) -> int:
    win = load_windows()
    if args.json:
        out = []
        for w in win:
            out.append({
                "id": w.id, "scene_id": w.scene_id,
                "total_tabs": w.total_tabs,
                "tab_groups": [
                    {"id": g.id, "title": g.title, "tabs": g.num_children,
                     "is_local": g.is_local}
                    for g in w.tab_groups
                ],
            })
        print(json.dumps(out, indent=2, ensure_ascii=False))
        return 0
    for w in win:
        print(f"Window {w.id} ({w.total_tabs} tabs)")
        for g in w.tab_groups:
            kind = "[Local]" if g.is_local else ""
            print(f"  {g.num_children:>4}  {g.title}  {kind}")
        print()
    return 0


def cmd_tabgroups(args) -> int:
    tg = load_tabgroups()
    if args.json:
        out = [{"id": g.id, "title": g.title, "tabs": g.num_children,
                "window_id": g.window_id, "is_local": g.is_local} for g in tg]
        print(json.dumps(out, indent=2, ensure_ascii=False))
        return 0
    for g in sorted(tg, key=lambda g: -g.num_children):
        kind = "Local" if g.is_local else "Group"
        print(f"  {g.num_children:>4}  {kind:<5}  win{g.window_id:<3}  {g.title}")
    print(f"\n{len(tg)} tab groups across {len({g.window_id for g in tg})} windows")
    return 0


def cmd_tabs(args) -> int:
    tabs = load_tabs(window_id=args.window, tab_group_name=args.tabgroup)
    tabs = filter_tabs(tabs, args.match, args.domain)
    if args.json:
        out = [{"id": t.id, "title": t.title, "url": t.url,
                "tab_group_id": t.tab_group_id,
                "last_modified": cocoa_to_iso(t.last_modified)}
               for t in tabs]
        print(json.dumps(out, indent=2, ensure_ascii=False))
        return 0
    if args.csv:
        w = csvmod.writer(sys.stdout)
        w.writerow(["id","tab_group_id","title","url","last_modified"])
        for t in tabs:
            w.writerow([t.id, t.tab_group_id, t.title, t.url,
                        cocoa_to_iso(t.last_modified)])
        return 0
    for i, t in enumerate(tabs):
        title = (t.title or "(untitled)")[:60]
        print(f"  {i:>4}  {title:<60}  {t.url[:80]}")
    print(f"\n{len(tabs)} tab(s)")
    return 0


def cmd_bookmarks(args) -> int:
    if args.tree:
        # full tree from each top-level folder
        roots = load_bookmarks(parent=None)
        for r in roots:
            print(f"\n# {r.title}  ({r.num_children})")
            tree = load_bookmark_tree(r.id)
            print(_render_tree(tree, depth=0, max_depth=args.depth))
        return 0
    # list mode: top-level folders + counts
    roots = load_bookmarks(parent=None)
    if args.json:
        out = [{"id": r.id, "title": r.title, "children": r.num_children,
                "last_modified": cocoa_to_iso(r.last_modified)} for r in roots]
        print(json.dumps(out, indent=2, ensure_ascii=False))
        return 0
    for r in sorted(roots, key=lambda r: -r.num_children):
        print(f"  {r.num_children:>4}  {r.title}")
    print(f"\n{len(roots)} top-level bookmark folders")
    return 0


def _render_tree(node: dict, depth: int = 0, max_depth: int = 99) -> str:
    if not node:
        return ""
    bm = node["bm"]
    indent = "  " * depth
    if bm.type == 0:
        return f"{indent}- [{bm.title or '(untitled)'}]({bm.url})"
    out = [f"{indent}- **{bm.title or '(unnamed folder)'}** ({bm.num_children})"]
    if depth >= max_depth:
        return "\n".join(out)
    for c in node.get("children", []):
        out.append(_render_tree(c, depth + 1, max_depth))
    return "\n".join(out)


def cmd_icloud_tabs(args) -> int:
    cloud = load_cloud_tabs(device_filter=args.device)
    cloud = [c for c in cloud
             if not args.match or re.search(args.match, c.title or "", re.I)
             or re.search(args.match, c.url or "", re.I)]
    by_device: dict[str, list[CloudTab]] = defaultdict(list)
    for c in cloud:
        by_device[c.device_name or c.device_uuid].append(c)
    if args.json:
        out = {}
        for d, items in by_device.items():
            out[d] = [{"title": c.title, "url": c.url,
                       "last_modified": cocoa_to_iso(c.last_modified)}
                      for c in items]
        print(json.dumps(out, indent=2, ensure_ascii=False))
        return 0
    for d, items in sorted(by_device.items(), key=lambda x: -len(x[1])):
        print(f"\n{d} ({len(items)})")
        for c in items[:args.limit] if args.limit else items:
            t = (c.title or "(untitled)")[:60]
            print(f"    {t:<60}  {c.url[:80]}")
    print(f"\n{len(cloud)} iCloud tabs from {len(by_device)} device(s)")
    return 0


def cmd_history(args) -> int:
    since = None
    if args.since:
        since = datetime.fromisoformat(args.since).replace(tzinfo=timezone.utc)
    elif args.last:
        n, unit = re.match(r"^(\d+)([dwmy])$", args.last).groups()
        delta = {"d": "days", "w": "weeks", "m": "days", "y": "days"}[unit]
        mult = {"d": 1, "w": 7, "m": 30, "y": 365}[unit]
        since = datetime.now(timezone.utc) - timedelta(**{delta: int(n) * mult})
    items = load_history(since=since, match=args.match, limit=args.limit or 200)
    if args.json:
        out = [{"url": h.url, "title": h.title, "visit_count": h.visit_count,
                "last_visit": cocoa_to_iso(h.last_visit)} for h in items]
        print(json.dumps(out, indent=2, ensure_ascii=False))
        return 0
    for h in items:
        date = cocoa_to_iso(h.last_visit)[:10]
        title = (h.title or "")[:50]
        print(f"  {date}  {h.visit_count:>4}×  {title:<50}  {h.url[:80]}")
    print(f"\n{len(items)} history item(s)")
    return 0


def cmd_search(args) -> int:
    q = args.query
    pat = re.compile(q, re.I)
    print(f"=== Tabs matching /{q}/ ===")
    tabs = filter_tabs(load_tabs(), q, None)
    for t in tabs[:30]:
        print(f"  [open]    {t.title[:60]:<60}  {t.url[:80]}")
    if len(tabs) > 30:
        print(f"  ... +{len(tabs)-30} more")

    print(f"\n=== Bookmarks matching /{q}/ ===")
    con = open_ro(SAFARI_TABS_DB)
    rows = con.execute("""
        SELECT title, COALESCE(url,'') FROM bookmarks
        WHERE deleted=0 AND type=0 AND (title LIKE ? OR url LIKE ?)
        LIMIT 30
    """, (f"%{q}%", f"%{q}%")).fetchall()
    con.close()
    for title, url in rows:
        print(f"  [bm]      {(title or '')[:60]:<60}  {url[:80]}")

    print(f"\n=== History matching /{q}/ (last 90d) ===")
    since = datetime.now(timezone.utc) - timedelta(days=90)
    hist = load_history(since=since, match=q, limit=30)
    for h in hist:
        d = cocoa_to_iso(h.last_visit)[:10]
        print(f"  [{d}] {h.visit_count:>3}×  {h.title[:55]:<55}  {h.url[:80]}")
    return 0


def cmd_export(args) -> int:
    """Full markdown vault dump."""
    env = load_env()
    vault = Path(env["VAULT_PATH"])
    vault.mkdir(parents=True, exist_ok=True)

    # 1. windows + tab groups + tabs
    windows = load_windows()
    win_dir = vault / "windows"
    tg_dir = vault / "tabgroups"
    win_dir.mkdir(parents=True, exist_ok=True)
    tg_dir.mkdir(parents=True, exist_ok=True)

    for w in windows:
        lines = [f"---",
                 f"window_id: {w.id}",
                 f"scene_id: \"{w.scene_id}\"",
                 f"total_tabs: {w.total_tabs}",
                 f"tab_groups: {len(w.tab_groups)}",
                 f"is_last_session: {str(w.is_last_session).lower()}",
                 f"---", "",
                 f"# Window {w.id}",
                 f"",
                 f"- **Total tabs**: {w.total_tabs}",
                 f"- **Tab groups**: {len(w.tab_groups)}",
                 ""]
        for g in w.tab_groups:
            lines.append(f"## {g.title} ({g.num_children}){' — Local' if g.is_local else ''}")
            lines.append("")
            for t in load_tabs(tab_group_name=None):
                pass
            tabs = []
            con = open_ro(SAFARI_TABS_DB)
            tab_rows = con.execute("""
                WITH RECURSIVE d(id) AS (
                  SELECT id FROM bookmarks WHERE id = ?
                  UNION ALL
                  SELECT b.id FROM bookmarks b JOIN d ON b.parent = d.id
                  WHERE b.deleted = 0
                )
                SELECT b.id, COALESCE(b.title,''), COALESCE(b.url,''), b.order_index
                FROM d JOIN bookmarks b ON b.id = d.id
                WHERE b.type = 0 ORDER BY b.parent, b.order_index
            """, (g.id,)).fetchall()
            con.close()
            for tid, title, url, oi in tab_rows:
                lines.append(md_link(title, url))
            lines.append("")
        write_md(win_dir / f"window-{w.id}.md", "\n".join(lines))

    # 2. tab groups: one .md per group with all tabs
    all_groups = sorted(load_tabgroups(), key=lambda g: -g.num_children)
    # disambiguate name collisions across windows: "Local" appears N times
    used_slugs: dict[str, int] = {}
    tg_files: list[tuple[TabGroup, str]] = []
    for g in all_groups:
        base = slugify(g.title)
        if g.is_local:
            base = f"local-window-{g.window_id}"
        n = used_slugs.get(base, 0)
        used_slugs[base] = n + 1
        slug = base if n == 0 else f"{base}-{n+1}"
        tg_files.append((g, slug))

    tg_index = ["# Tab Groups", "",
                f"_{len(all_groups)} groups across "
                f"{len({g.window_id for g in all_groups})} window(s)._", ""]
    for g, slug in tg_files:
        kind = "Local" if g.is_local else "Group"
        tg_index.append(f"- [{g.title}](./{slug}.md) — {g.num_children} tabs "
                        f"(window {g.window_id}, {kind})")
        # write per-group page
        body = [f"---",
                f"title: \"{(g.title or '').replace(chr(34), chr(92)+chr(34))}\"",
                f"window_id: {g.window_id}",
                f"tab_group_id: {g.id}",
                f"is_local: {str(g.is_local).lower()}",
                f"tab_count: {g.num_children}",
                f"---", "",
                f"# {g.title}",
                "",
                f"- **Window**: {g.window_id}",
                f"- **Kind**: {kind}",
                f"- **Tabs**: {g.num_children}",
                ""]
        con = open_ro(SAFARI_TABS_DB)
        tab_rows = con.execute("""
            WITH RECURSIVE d(id, depth) AS (
              SELECT id, 0 FROM bookmarks WHERE id = ?
              UNION ALL
              SELECT b.id, d.depth+1 FROM bookmarks b JOIN d ON b.parent = d.id
              WHERE b.deleted = 0
            )
            SELECT b.id, b.parent, b.type, COALESCE(b.title,''),
                   COALESCE(b.url,''), b.num_children, b.order_index, d.depth
            FROM d JOIN bookmarks b ON b.id = d.id
            WHERE b.deleted = 0
            ORDER BY b.parent, b.order_index
        """, (g.id,)).fetchall()
        con.close()
        # render as nested list, with sub-folders + their tabs
        # build a parent->children map
        kids: dict[int, list[tuple]] = defaultdict(list)
        rec_root_id = g.id
        for r in tab_rows:
            if r[0] == rec_root_id:
                continue
            kids[r[1]].append(r)
        def render_node(node_id: int, depth: int) -> list[str]:
            lines = []
            for r in kids.get(node_id, []):
                _id, parent, type_, title, url, num_kids, oi, _d = r
                indent = "  " * depth
                if type_ == 0:
                    lines.append(f"{indent}- [{title or '(untitled)'}]({url})")
                else:
                    lines.append(f"{indent}- **{title or '(unnamed)'}** ({num_kids})")
                    lines.extend(render_node(_id, depth + 1))
            return lines
        body.extend(render_node(rec_root_id, 0))
        body.append("")
        write_md(tg_dir / f"{slug}.md", "\n".join(body))
    write_md(tg_dir / "_index.md", "\n".join(tg_index))

    # 3. bookmarks: per top-level folder
    bm_dir = vault / "bookmarks"
    bm_dir.mkdir(parents=True, exist_ok=True)
    roots = load_bookmarks(parent=None)
    bm_index = ["# Bookmark Folders", ""]
    for r in sorted(roots, key=lambda r: -r.num_children):
        slug = slugify(r.title)
        bm_index.append(f"- [{r.title}](./{slug}.md) — {r.num_children}")
        tree = load_bookmark_tree(r.id)
        body = [f"---", f"title: \"{r.title}\"", f"children: {r.num_children}",
                f"---", "", f"# {r.title}", ""]
        body.append(_render_tree(tree, depth=0, max_depth=10))
        write_md(bm_dir / f"{slug}.md", "\n".join(body))
    write_md(bm_dir / "_index.md", "\n".join(bm_index))

    # 4. iCloud tabs
    cloud = load_cloud_tabs()
    cloud_dir = vault / "cloud-tabs"
    cloud_dir.mkdir(parents=True, exist_ok=True)
    by_device: dict[str, list[CloudTab]] = defaultdict(list)
    for c in cloud:
        by_device[c.device_name or "unknown"].append(c)
    cloud_index = ["# iCloud Tabs (synced from other devices)", ""]
    for device, items in by_device.items():
        slug = slugify(device)
        cloud_index.append(f"- [{device}](./{slug}.md) — {len(items)} tabs")
        body = [f"---", f"device: \"{device}\"", f"tab_count: {len(items)}",
                f"---", "", f"# {device} ({len(items)} tabs)", ""]
        for c in items:
            body.append(md_link(c.title, c.url))
        write_md(cloud_dir / f"{slug}.md", "\n".join(body))
    write_md(cloud_dir / "_index.md", "\n".join(cloud_index))

    # 5. history (optional, can be huge)
    if args.with_history:
        hist_dir = vault / "history"
        hist_dir.mkdir(parents=True, exist_ok=True)
        since = datetime.now(timezone.utc) - timedelta(days=args.history_days or 90)
        items = load_history(since=since)
        # group by month
        by_month: dict[str, list[HistoryItem]] = defaultdict(list)
        for h in items:
            dt = cocoa_to_dt(h.last_visit)
            if not dt:
                continue
            by_month[dt.strftime("%Y-%m")].append(h)
        hist_index = [f"# Browsing history — last {args.history_days or 90} days", ""]
        for month in sorted(by_month, reverse=True):
            ms = by_month[month]
            hist_index.append(f"- [{month}](./{month}.md) — {len(ms)} URLs")
            body = [f"# History — {month}", "",
                    f"_{len(ms)} unique URLs visited this month_", ""]
            for h in ms:
                d = cocoa_to_iso(h.last_visit)[:10]
                body.append(f"- `{d}` ({h.visit_count}×) "
                            f"[{(h.title or '(untitled)')[:80]}]({h.url})")
            write_md(hist_dir / f"{month}.md", "\n".join(body))
        write_md(hist_dir / "_index.md", "\n".join(hist_index))

    # top-level INDEX
    index = [
        "# Safari Vault",
        "",
        f"Generated {datetime.now().isoformat(timespec='seconds')}.",
        f"Read-only snapshot — Safari's own data is unchanged.",
        "",
        "## Navigation",
        "",
        f"- [Windows](./windows/) ({len(windows)} window(s), "
        f"{sum(w.total_tabs for w in windows)} open tabs)",
        f"- [Tab groups](./tabgroups/_index.md)",
        f"- [Bookmarks](./bookmarks/_index.md) "
        f"({sum(r.num_children for r in roots)} URLs across {len(roots)} folders)",
        f"- [iCloud tabs](./cloud-tabs/_index.md) ({len(cloud)} tabs from "
        f"{len(by_device)} device(s))",
    ]
    if args.with_history:
        index.append(f"- [History](./history/_index.md) (last {args.history_days or 90} days)")
    write_md(vault / "INDEX.md", "\n".join(index))

    print(f"Vault written to: {vault}")
    print(f"  Windows:        {len(windows)}")
    print(f"  Tab groups:     {len(load_tabgroups())}")
    print(f"  Bookmarks:      {sum(r.num_children for r in roots)} across "
          f"{len(roots)} top-level folders")
    print(f"  iCloud tabs:    {len(cloud)} from {len(by_device)} device(s)")
    if args.with_history:
        print(f"  History:        last {args.history_days or 90} days")
    return 0


# =====================================================================
# argparse
# =====================================================================

def main() -> int:
    p = argparse.ArgumentParser(prog="safari-export")
    sub = p.add_subparsers(dest="cmd", required=True)

    sp = sub.add_parser("status", help="Counts overview")
    sp.set_defaults(func=cmd_status)

    sp = sub.add_parser("windows", help="List Safari windows + tab-group breakdown")
    sp.add_argument("--json", action="store_true")
    sp.set_defaults(func=cmd_windows)

    sp = sub.add_parser("tabgroups", help="List named tab groups + counts")
    sp.add_argument("--json", action="store_true")
    sp.set_defaults(func=cmd_tabgroups)

    sp = sub.add_parser("tabs", help="List open tabs (filtered)")
    sp.add_argument("--window", type=int, help="Only this window id")
    sp.add_argument("--tabgroup", help="Tab group title (case-sensitive)")
    sp.add_argument("--match", help="Regex (title or url)")
    sp.add_argument("--domain", help="Substring match on URL host")
    sp.add_argument("--json", action="store_true")
    sp.add_argument("--csv", action="store_true")
    sp.set_defaults(func=cmd_tabs)

    sp = sub.add_parser("bookmarks", help="List bookmark folders or full tree")
    sp.add_argument("--tree", action="store_true",
                    help="Render full tree (markdown). Default lists top-level folders.")
    sp.add_argument("--depth", type=int, default=10, help="Max depth for --tree")
    sp.add_argument("--json", action="store_true")
    sp.set_defaults(func=cmd_bookmarks)

    sp = sub.add_parser("icloud-tabs", help="Tabs synced from other devices")
    sp.add_argument("--device", help="Substring match on device name")
    sp.add_argument("--match", help="Regex (title or url)")
    sp.add_argument("--limit", type=int, help="Per-device cap")
    sp.add_argument("--json", action="store_true")
    sp.set_defaults(func=cmd_icloud_tabs)

    sp = sub.add_parser("history", help="Browsing history")
    sp.add_argument("--last", help="e.g. 7d, 30d, 12m, 1y")
    sp.add_argument("--since", help="ISO date (YYYY-MM-DD)")
    sp.add_argument("--match", help="Substring (title or url)")
    sp.add_argument("--limit", type=int, default=200)
    sp.add_argument("--json", action="store_true")
    sp.set_defaults(func=cmd_history)

    sp = sub.add_parser("search", help="Cross-search tabs + bookmarks + history")
    sp.add_argument("query")
    sp.set_defaults(func=cmd_search)

    sp = sub.add_parser("export", help="Full markdown vault dump")
    sp.add_argument("--with-history", action="store_true",
                    help="Include browsing history pages")
    sp.add_argument("--history-days", type=int, default=90,
                    help="How many days of history (default 90)")
    sp.set_defaults(func=cmd_export)

    args = p.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
