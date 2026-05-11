#!/usr/bin/env python3
"""calendar-exporter — Apple Calendar via SQLite + AppleScript.

Two back-doors for completeness:
  - `~/Library/Group Containers/group.com.apple.calendar/Calendar.sqlitedb`
    for full event history (read-only, ?mode=ro&immutable=1)
  - Calendar sdef via osascript for live counts / verification

Subcommands (all read-only):
  status      counts overview
  calendars   list all calendars + colors + per-calendar event count
  events      list events (--since / --until / --calendar / --match / --json)
  upcoming    next N events from today
  export      markdown vault: per-calendar .md + per-month index
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sqlite3
import subprocess
import sys
from collections import defaultdict
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# WAL-safe Apple SQLite snapshot helper. Calendar agent writes continuously
# (event reminders, sync deltas); snapshot to see uncommitted WAL state.
sys.path.insert(0, str(ROOT.parent / "bin" / "lib"))
from apple_sqlite_snapshot import snapshot_open_persistent  # noqa: E402
DEFAULT_ENV = ROOT / ".env"
DB_PATH = Path(os.path.expanduser(
    "~/Library/Group Containers/group.com.apple.calendar/Calendar.sqlitedb"
))
COCOA_EPOCH = datetime(2001, 1, 1, tzinfo=timezone.utc)


def load_env() -> dict[str, str]:
    env: dict[str, str] = {}
    if DEFAULT_ENV.exists():
        for line in DEFAULT_ENV.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            env[k.strip()] = os.path.expanduser(v.strip().strip('"').strip("'"))
    env.setdefault("VAULT_PATH", os.path.expanduser("~/work/apple/exported/calendar"))
    env["VAULT_PATH"] = os.path.expanduser(env["VAULT_PATH"])
    return env


def open_ro() -> sqlite3.Connection:
    if not DB_PATH.exists():
        sys.exit(f"Calendar DB not found at {DB_PATH}.")
    return snapshot_open_persistent(DB_PATH)


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
# Loaders
# =====================================================================

@dataclass
class Calendar:
    rowid: int
    title: str
    color: str
    event_count: int


@dataclass
class Event:
    rowid: int
    summary: str
    description: str
    location: str
    start: float | None
    end: float | None
    start_tz: str
    all_day: bool
    calendar_id: int
    calendar_title: str
    status: int
    url: str
    last_modified: float | None


def load_calendars() -> list[Calendar]:
    con = open_ro()
    rows = con.execute("""
        SELECT c.ROWID, COALESCE(c.title,''), COALESCE(c.color,''),
          (SELECT COUNT(*) FROM CalendarItem WHERE calendar_id = c.ROWID) AS n
        FROM Calendar c
        ORDER BY c.title
    """).fetchall()
    con.close()
    return [Calendar(rowid=r[0], title=r[1], color=r[2], event_count=r[3]) for r in rows]


def load_events(args=None) -> list[Event]:
    con = open_ro()
    where = ["1=1"]
    params: list = []
    if args and args.since:
        cocoa_since = (datetime.fromisoformat(args.since)
                       .replace(tzinfo=timezone.utc) - COCOA_EPOCH).total_seconds()
        where.append("ci.start_date >= ?")
        params.append(cocoa_since)
    if args and args.until:
        cocoa_until = (datetime.fromisoformat(args.until)
                       .replace(tzinfo=timezone.utc) - COCOA_EPOCH).total_seconds()
        where.append("ci.start_date <= ?")
        params.append(cocoa_until)
    if args and args.calendar:
        where.append("c.title LIKE ?")
        params.append(f"%{args.calendar}%")
    if args and args.match:
        where.append("(ci.summary LIKE ? OR ci.description LIKE ? OR ci.url LIKE ?)")
        like = f"%{args.match}%"
        params += [like, like, like]
    sql = f"""
        SELECT ci.ROWID, COALESCE(ci.summary,''), COALESCE(ci.description,''),
               COALESCE(l.title,''),
               ci.start_date, ci.end_date, COALESCE(ci.start_tz,''),
               ci.all_day, ci.calendar_id, COALESCE(c.title,''),
               COALESCE(ci.status,0), COALESCE(ci.url,''), ci.last_modified
        FROM CalendarItem ci
        LEFT JOIN Calendar c ON c.ROWID = ci.calendar_id
        LEFT JOIN Location l ON l.ROWID = ci.location_id
        WHERE {' AND '.join(where)}
        ORDER BY ci.start_date DESC
    """
    if args and args.limit:
        sql += f" LIMIT {int(args.limit)}"
    out = []
    for row in con.execute(sql, params):
        out.append(Event(
            rowid=row[0], summary=row[1], description=row[2], location=row[3],
            start=row[4], end=row[5], start_tz=row[6], all_day=bool(row[7]),
            calendar_id=row[8], calendar_title=row[9],
            status=row[10], url=row[11], last_modified=row[12],
        ))
    con.close()
    return out


# =====================================================================
# Subcommands
# =====================================================================

def cmd_status(args) -> int:
    cals = load_calendars()
    total = sum(c.event_count for c in cals)
    print(f"Calendar overview")
    print(f"  Calendars:    {len(cals)}")
    print(f"  Total events: {total}")
    print(f"  DB:           {DB_PATH} ({DB_PATH.stat().st_size} bytes)")
    return 0


def cmd_calendars(args) -> int:
    cals = load_calendars()
    if args.json:
        print(json.dumps([{
            "rowid": c.rowid, "title": c.title,
            "color": c.color, "event_count": c.event_count,
        } for c in cals], indent=2, ensure_ascii=False))
        return 0
    for c in sorted(cals, key=lambda c: -c.event_count):
        color = c.color[:9].ljust(9) if c.color else " " * 9
        print(f"  {c.event_count:>5}  {color}  {c.title}")
    print(f"\n{len(cals)} calendar(s)")
    return 0


def cmd_events(args) -> int:
    events = load_events(args)
    if args.json:
        print(json.dumps([{
            "rowid": e.rowid, "summary": e.summary,
            "calendar": e.calendar_title,
            "start": cocoa_to_iso(e.start), "end": cocoa_to_iso(e.end),
            "location": e.location, "all_day": e.all_day, "url": e.url,
        } for e in events], indent=2, ensure_ascii=False))
        return 0
    for e in events:
        d = cocoa_to_iso(e.start)[:16]
        loc = f"  @ {e.location[:30]}" if e.location else ""
        print(f"  {d}  [{e.calendar_title[:20]:<20}]  {e.summary}{loc}")
    print(f"\n{len(events)} event(s)")
    return 0


def cmd_upcoming(args) -> int:
    n = args.n or 20
    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    fake_args = argparse.Namespace(since=today, until=None, calendar=None,
                                    match=None, limit=n)
    events = sorted(load_events(fake_args),
                    key=lambda e: e.start or 0)[:n]
    for e in events:
        d = cocoa_to_iso(e.start)[:16]
        loc = f"  @ {e.location[:30]}" if e.location else ""
        print(f"  {d}  [{e.calendar_title[:20]:<20}]  {e.summary}{loc}")
    return 0


def write_md(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)


def cmd_export(args) -> int:
    env = load_env()
    vault = Path(env["VAULT_PATH"])
    vault.mkdir(parents=True, exist_ok=True)
    cals = load_calendars()

    cal_dir = vault / "calendars"
    cal_dir.mkdir(parents=True, exist_ok=True)
    cal_index = ["# Calendars", ""]
    for c in sorted(cals, key=lambda c: -c.event_count):
        slug = slugify(c.title) or f"calendar-{c.rowid}"
        cal_index.append(f"- [{c.title}](./{slug}.md) — {c.event_count} events  "
                         f"(color {c.color or '?'})")
        # per-calendar md
        events = load_events(argparse.Namespace(
            since=None, until=None, calendar=c.title, match=None, limit=None,
        ))
        body = ["---",
                f'calendar: "{c.title}"',
                f'event_count: {c.event_count}',
                f'color: "{c.color}"',
                "---",
                "",
                f"# {c.title} ({c.event_count} events)",
                ""]
        for e in events:
            d = cocoa_to_iso(e.start)
            duration = ""
            if e.end and e.start:
                mins = int((e.end - e.start) / 60)
                if e.all_day:
                    duration = " (all day)"
                elif mins:
                    if mins >= 1440:
                        duration = f" ({mins // 1440}d)"
                    elif mins >= 60:
                        duration = f" ({mins // 60}h{mins % 60}m)" if mins % 60 else f" ({mins // 60}h)"
                    else:
                        duration = f" ({mins}m)"
            loc = f"  @ {e.location}" if e.location else ""
            body.append(f"- `{d}`{duration}  **{e.summary or '(untitled)'}**{loc}")
            if e.description:
                body.append(f"  - {e.description[:200]}")
            if e.url:
                body.append(f"  - [{e.url}]({e.url})")
        write_md(cal_dir / f"{slug}.md", "\n".join(body))
    write_md(cal_dir / "_index.md", "\n".join(cal_index))

    # by-year index
    year_dir = vault / "by-year"
    year_dir.mkdir(parents=True, exist_ok=True)
    all_events = load_events(argparse.Namespace(
        since=None, until=None, calendar=None, match=None, limit=None,
    ))
    by_year: dict[str, list[Event]] = defaultdict(list)
    for e in all_events:
        dt = cocoa_to_dt(e.start)
        if dt:
            by_year[dt.strftime("%Y")].append(e)
    year_idx = ["# Events by Year", ""]
    for y in sorted(by_year, reverse=True):
        es = by_year[y]
        year_idx.append(f"- [{y}](./{y}.md) — {len(es)} events")
        body = [f"# {y} ({len(es)} events)", ""]
        for e in sorted(es, key=lambda e: e.start or 0):
            d = cocoa_to_iso(e.start)[:16]
            body.append(f"- `{d}` [{e.calendar_title[:20]}] **{e.summary}**")
        write_md(year_dir / f"{y}.md", "\n".join(body))
    write_md(year_dir / "_index.md", "\n".join(year_idx))

    index = ["# Calendar Vault", "",
             f"Generated {datetime.now().isoformat(timespec='seconds')}.",
             "",
             f"- [Calendars](./calendars/_index.md) ({len(cals)})",
             f"- [By year](./by-year/_index.md) ({len(all_events)} events total)", ""]
    write_md(vault / "INDEX.md", "\n".join(index))
    print(f"Wrote vault: {vault}")
    print(f"  calendars: {len(cals)}  events: {len(all_events)}")
    return 0


def main() -> int:
    p = argparse.ArgumentParser(prog="calendar-exporter")
    sub = p.add_subparsers(dest="cmd", required=True)

    sub.add_parser("status", help="counts").set_defaults(func=cmd_status)
    sp = sub.add_parser("calendars", help="list all calendars")
    sp.add_argument("--json", action="store_true")
    sp.set_defaults(func=cmd_calendars)

    sp = sub.add_parser("events", help="list events with filters")
    sp.add_argument("--since", help="YYYY-MM-DD")
    sp.add_argument("--until", help="YYYY-MM-DD")
    sp.add_argument("--calendar", help="calendar title substring")
    sp.add_argument("--match", help="regex over summary/description/url")
    sp.add_argument("--limit", type=int)
    sp.add_argument("--json", action="store_true")
    sp.set_defaults(func=cmd_events)

    sp = sub.add_parser("upcoming", help="next N events from today")
    sp.add_argument("-n", type=int, help="default 20")
    sp.set_defaults(func=cmd_upcoming)

    sub.add_parser("export", help="full markdown vault").set_defaults(func=cmd_export)

    args = p.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
