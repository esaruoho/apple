#!/usr/bin/env python3
"""mail-exporter — Apple Mail.app catalog via Envelope Index SQLite.

Mail is Tier 1 (sdef + App Intents) but for bulk message metadata
the Envelope Index SQLite at ~/Library/Mail/V*/MailData/Envelope Index
is far faster than walking the AppleScript dictionary across hundreds
of thousands of messages. Read-only via ?mode=ro&immutable=1.

Subcommands (read-only):
  status      counts overview
  mailboxes   list IMAP/local mailboxes + unread/total
  top-senders most frequent sender addresses (--limit 50)
  subjects    search subjects (--match REGEX)
  search      cross-search subject + sender + date filter
  export      per-mailbox markdown vault

Note: actual message bodies live in MBOX directories under
~/Library/Mail/V*/<account>/<mailbox>.mbox/Data/...emlx files. For
search-by-content the Spotlight index is the right tool. This
exporter focuses on metadata and mailbox topology.
"""

from __future__ import annotations

import argparse
import json
import os
import plistlib
import re
import sqlite3
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from pathlib import Path
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_ENV = ROOT / ".env"
COCOA_EPOCH = datetime(2001, 1, 1, tzinfo=timezone.utc)

# WAL-safe Apple SQLite snapshot helper. The Envelope Index is ~1 GB on a
# real user's machine; copying it every export is costly. Use immutable —
# Mail.app's WAL turnover is slow and a few minutes of staleness is fine.
sys.path.insert(0, str(ROOT.parent / "bin" / "lib"))
from apple_sqlite_snapshot import open_immutable  # noqa: E402


def find_envelope_index() -> Path:
    """The V<N> dir number changes across macOS versions; pick the highest."""
    base = Path(os.path.expanduser("~/Library/Mail"))
    if not base.exists():
        sys.exit("~/Library/Mail not found")
    cands = []
    for v in base.glob("V*"):
        if v.is_dir() and (v / "MailData" / "Envelope Index").exists():
            try:
                num = int(v.name[1:])
            except ValueError:
                continue
            cands.append((num, v / "MailData" / "Envelope Index"))
    if not cands:
        sys.exit("No V*/MailData/Envelope Index found under ~/Library/Mail")
    cands.sort(reverse=True)
    return cands[0][1]


DB_PATH = find_envelope_index()


def load_env() -> dict[str, str]:
    env: dict[str, str] = {}
    if DEFAULT_ENV.exists():
        for line in DEFAULT_ENV.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            env[k.strip()] = os.path.expanduser(v.strip().strip('"').strip("'"))
    env.setdefault("VAULT_PATH", os.path.expanduser("~/work/apple/exported/mail"))
    env["VAULT_PATH"] = os.path.expanduser(env["VAULT_PATH"])
    return env


def open_ro() -> sqlite3.Connection:
    return open_immutable(DB_PATH)


def cocoa_to_iso(z: float | None) -> str:
    if z is None:
        return ""
    dt = COCOA_EPOCH + timedelta(seconds=float(z))
    return dt.strftime("%Y-%m-%d %H:%M")


SLUG_RE = re.compile(r"[^a-zA-Z0-9._-]+")


def slugify(s: str, max_len: int = 60) -> str:
    s = SLUG_RE.sub("-", (s or "").strip()).strip("-")
    return (s[:max_len] or "untitled").lower()


def humanize_mailbox_url(url: str) -> str:
    """imap://UUID/INBOX → INBOX, local://UUID/Drafts → Drafts."""
    m = re.match(r"^(imap|pop|local|smtp|ews)://[^/]+/(.+)$", url)
    if m:
        return unquote(m.group(2))
    return url


# =====================================================================
# Subcommands
# =====================================================================

def cmd_status(args) -> int:
    con = open_ro()
    n_msgs = con.execute("SELECT COUNT(*) FROM messages").fetchone()[0]
    n_subj = con.execute("SELECT COUNT(*) FROM subjects").fetchone()[0]
    n_mbox = con.execute("SELECT COUNT(*) FROM mailboxes").fetchone()[0]
    n_unread = con.execute("SELECT COUNT(*) FROM messages WHERE read = 0").fetchone()[0]
    con.close()
    print("Mail overview")
    print(f"  DB:           {DB_PATH} ({DB_PATH.stat().st_size:,} bytes)")
    print(f"  Messages:     {n_msgs:,}")
    print(f"  Unread:       {n_unread:,}")
    print(f"  Subjects:     {n_subj:,}")
    print(f"  Mailboxes:    {n_mbox}")
    return 0


def cmd_mailboxes(args) -> int:
    con = open_ro()
    rows = con.execute("""
        SELECT ROWID, url, total_count, unread_count
        FROM mailboxes
        ORDER BY total_count DESC
    """).fetchall()
    con.close()
    if args.json:
        print(json.dumps([{
            "id": r[0], "url": r[1], "name": humanize_mailbox_url(r[1]),
            "total": r[2], "unread": r[3]
        } for r in rows], indent=2, ensure_ascii=False))
        return 0
    for r in rows:
        name = humanize_mailbox_url(r[1])
        print(f"  {r[2]:>8}  unread {r[3]:>5}  {name}")
    print(f"\n{len(rows)} mailbox(es)")
    return 0


def cmd_top_senders(args) -> int:
    con = open_ro()
    rows = con.execute("""
        SELECT a.address, a.comment, COUNT(*) AS n
        FROM messages m
        JOIN addresses a ON a.ROWID = m.sender
        GROUP BY m.sender
        ORDER BY n DESC
        LIMIT ?
    """, (args.limit or 50,)).fetchall()
    con.close()
    for addr, comment, n in rows:
        label = f"{comment} <{addr}>" if comment else addr
        print(f"  {n:>6}  {label}")
    return 0


def cmd_subjects(args) -> int:
    con = open_ro()
    if args.match:
        rows = con.execute("""
            SELECT s.subject, COUNT(m.ROWID) AS n
            FROM subjects s
            JOIN messages m ON m.subject = s.ROWID
            WHERE s.subject LIKE ?
            GROUP BY s.ROWID
            ORDER BY n DESC
            LIMIT ?
        """, (f"%{args.match}%", args.limit or 100)).fetchall()
    else:
        rows = con.execute("""
            SELECT subject, COUNT(*) FROM messages m
            JOIN subjects s ON s.ROWID = m.subject
            GROUP BY s.ROWID ORDER BY 2 DESC LIMIT ?
        """, (args.limit or 50,)).fetchall()
    con.close()
    for subj, n in rows:
        print(f"  {n:>5}  {subj[:120]}")
    return 0


def cmd_search(args) -> int:
    con = open_ro()
    where = ["1=1"]
    params: list = []
    if args.subject:
        where.append("s.subject LIKE ?"); params.append(f"%{args.subject}%")
    if args.sender:
        where.append("(a.address LIKE ? OR a.comment LIKE ?)")
        params += [f"%{args.sender}%", f"%{args.sender}%"]
    if args.since:
        cocoa_since = (datetime.fromisoformat(args.since)
                       .replace(tzinfo=timezone.utc) - COCOA_EPOCH).total_seconds()
        where.append("m.date_received >= ?"); params.append(cocoa_since)
    sql = f"""
        SELECT m.ROWID, s.subject, a.address, a.comment, m.date_received,
               mb.url, m.read, m.flagged
        FROM messages m
        JOIN subjects s ON s.ROWID = m.subject
        LEFT JOIN addresses a ON a.ROWID = m.sender
        LEFT JOIN mailboxes mb ON mb.ROWID = m.mailbox
        WHERE {' AND '.join(where)}
        ORDER BY m.date_received DESC
        LIMIT ?
    """
    rows = con.execute(sql, params + [args.limit or 50]).fetchall()
    con.close()
    for mid, subj, addr, comment, drcv, mburl, rd, fl in rows:
        sender = comment or addr or "?"
        date = cocoa_to_iso(drcv)[:16]
        flags = ""
        if not rd: flags += "● "
        if fl: flags += "★ "
        print(f"  {date}  {flags}{(subj or '')[:60]:<60}  {sender[:30]}")
    return 0


def write_md(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)


def cmd_export(args) -> int:
    env = load_env()
    vault = Path(env["VAULT_PATH"])
    vault.mkdir(parents=True, exist_ok=True)
    con = open_ro()

    # mailboxes
    rows = con.execute("""
        SELECT ROWID, url, total_count, unread_count
        FROM mailboxes
        ORDER BY total_count DESC
    """).fetchall()
    mbox_dir = vault / "mailboxes"
    mbox_dir.mkdir(parents=True, exist_ok=True)
    idx = ["# Mailboxes", ""]
    for mid, url, total, unread in rows:
        name = humanize_mailbox_url(url)
        slug = slugify(name)
        idx.append(f"- [{name}](./{slug}.md) — {total:,} msgs ({unread} unread)")
        # per-mailbox: top 200 latest message headers
        msg_rows = con.execute("""
            SELECT s.subject, COALESCE(a.comment,''), COALESCE(a.address,''),
                   m.date_received, m.read, m.flagged
            FROM messages m
            JOIN subjects s ON s.ROWID = m.subject
            LEFT JOIN addresses a ON a.ROWID = m.sender
            WHERE m.mailbox = ?
            ORDER BY m.date_received DESC
            LIMIT ?
        """, (mid, args.per_mailbox_limit or 200)).fetchall()
        body = ["---",
                f'mailbox: "{name}"',
                f'url: "{url}"',
                f'total_count: {total}',
                f'unread_count: {unread}',
                f'sample_size: {len(msg_rows)}',
                "---", "",
                f"# {name} ({total:,} messages, {unread} unread)", ""]
        for subj, comment, addr, drcv, rd, fl in msg_rows:
            sender = (comment or addr or "?")[:40]
            date = cocoa_to_iso(drcv)[:16]
            flags = ""
            if not rd: flags += "●"
            if fl: flags += "★"
            body.append(f"- `{date}` {flags}  **{(subj or '(no subject)')[:80]}** — {sender}")
        write_md(mbox_dir / f"{slug}.md", "\n".join(body))
    write_md(mbox_dir / "_index.md", "\n".join(idx))

    # top senders
    senders = con.execute("""
        SELECT a.address, a.comment, COUNT(*) AS n
        FROM messages m JOIN addresses a ON a.ROWID = m.sender
        GROUP BY m.sender ORDER BY n DESC LIMIT 200
    """).fetchall()
    body = ["# Top Senders (top 200 by message count)", ""]
    for addr, comment, n in senders:
        label = f"{comment} <{addr}>" if comment else addr
        body.append(f"- {n:>5}  {label}")
    write_md(vault / "top-senders.md", "\n".join(body))

    con.close()
    n_msgs = open_ro().execute("SELECT COUNT(*) FROM messages").fetchone()[0]
    index = ["# Mail Vault", "",
             f"Generated {datetime.now().isoformat(timespec='seconds')}.", "",
             f"- Messages: {n_msgs:,}",
             f"- [Mailboxes](./mailboxes/_index.md) ({len(rows)})",
             f"- [Top senders](./top-senders.md)", ""]
    write_md(vault / "INDEX.md", "\n".join(index))
    print(f"Wrote vault: {vault}")
    print(f"  mailboxes: {len(rows)}  messages: {n_msgs:,}")
    return 0


def cmd_xref_calendar(args) -> int:
    """Match received messages to ±window-min Calendar events.

    Pulls each message's date_received, scans the Calendar SQLite store for
    events whose start_date is within the window, and reports the candidate
    correlations. Useful for "what did I get emailed about during that
    meeting" reconstructions.
    """
    cal_db = Path(os.path.expanduser(
        "~/Library/Group Containers/group.com.apple.calendar/Calendar.sqlitedb"
    ))
    if not cal_db.exists():
        print(f"Calendar DB not found at {cal_db}", file=sys.stderr)
        return 1

    since = None
    if args.since:
        try:
            since_dt = datetime.fromisoformat(args.since).replace(tzinfo=timezone.utc)
            since = (since_dt - COCOA_EPOCH).total_seconds()
        except ValueError:
            sys.exit(f"--since must be ISO date (YYYY-MM-DD): {args.since}")

    mail = open_ro()
    q = """
        SELECT m.ROWID, s.subject, a.address, m.date_received
        FROM messages m
        JOIN subjects s ON s.ROWID = m.subject
        JOIN addresses a ON a.ROWID = m.sender
        WHERE m.date_received IS NOT NULL
    """
    params: list = []
    if since is not None:
        q += " AND m.date_received >= ?"
        params.append(since)
    q += " ORDER BY m.date_received DESC LIMIT ?"
    params.append(args.limit or 200)
    msgs = mail.execute(q, params).fetchall()
    mail.close()

    cal = open_immutable(cal_db)
    window_secs = args.window * 60
    hits = []
    for rowid, subj, addr, t_recv in msgs:
        events = cal.execute("""
            SELECT ci.summary, c.title, ci.start_date
            FROM CalendarItem ci
            LEFT JOIN Calendar c ON c.ROWID = ci.calendar_id
            WHERE ci.start_date BETWEEN ? AND ?
            ORDER BY ABS(ci.start_date - ?)
            LIMIT 3
        """, (t_recv - window_secs, t_recv + window_secs, t_recv)).fetchall()
        if events:
            hits.append({"rowid": rowid, "subject": subj, "sender": addr,
                         "received": cocoa_to_iso(t_recv),
                         "events": [{
                             "summary": e[0] or "(no title)",
                             "calendar": e[1] or "?",
                             "start": cocoa_to_iso(e[2]),
                         } for e in events]})
    cal.close()

    if args.json:
        print(json.dumps(hits, indent=2, ensure_ascii=False))
        return 0
    for h in hits:
        print(f"\n{h['received']}  [{h['sender']}]  {h['subject']}")
        for e in h["events"]:
            print(f"   ↔  {e['start']}  [{e['calendar']}]  {e['summary']}")
    print(f"\n{len(hits)}/{len(msgs)} message(s) had Calendar matches "
          f"within ±{args.window} min")
    return 0


# ---------------------------------------------------------------------------
# Smart Mailboxes — plist-backed, NOT in Mail's sdef
#
# Definitions live in SyncedSmartMailboxes.plist; per-Mac UI state (sort,
# filters, unread count) in SmartMailboxesLocalProperties.plist. Both files
# are read-safe at any time.
#
# Write side is intentionally NOT exposed here. Proven empirically on
# 2026-05-13: editing the plist while Mail is quit lands on disk, but
# Mail overwrites it with its own canonical version within ~1 second of
# launch (size 12835→12597, mtime jumps to Mail's write time, our edit
# is gone). The only viable write path is UI-scripting Mail's own "Edit
# Smart Mailbox" sheet. See analysis/mail/smart-mailboxes.md for the
# full diagnostic + schema.
# ---------------------------------------------------------------------------

SPECIAL_MAILBOX_TYPE = {
    0: "Inbox", 1: "Drafts", 2: "Outbox", 3: "Sent",
    4: "Trash", 5: "Junk", 6: "Archive",
}
DATE_UNIT_TYPE = {1: "day", 2: "week", 3: "month", 4: "year"}


def find_smartbox_plists() -> tuple[Path, Path | None]:
    """Locate the SyncedSmartMailboxes + LocalProperties plists in the
    highest-V MailData dir. Returns (synced, local-or-None)."""
    md = DB_PATH.parent  # ~/Library/Mail/V*/MailData
    synced = md / "SyncedSmartMailboxes.plist"
    local = md / "SmartMailboxesLocalProperties.plist"
    if not synced.exists():
        sys.exit(f"Smart mailbox definitions not found at {synced}")
    return synced, (local if local.exists() else None)


def load_smartboxes() -> tuple[list[dict], dict[str, dict]]:
    """Return (definitions_list, local_props_by_mailbox_id)."""
    synced_path, local_path = find_smartbox_plists()
    with open(synced_path, "rb") as f:
        defs = plistlib.load(f)
    locals_by_id: dict[str, dict] = {}
    if local_path:
        with open(local_path, "rb") as f:
            for _outer_id, entry in plistlib.load(f).items():
                info = entry.get("MailboxUserInfo", {}) or {}
                mid = info.get("MailboxID")
                if mid:
                    locals_by_id[mid] = {
                        "unread": entry.get("MailboxUnreadCount", 0),
                        "sort_order": info.get("SortOrder", ""),
                        "descending": info.get("SortedDescending") == "YES",
                        "filters": [f.get("FilterIdentifier", "")
                                    for f in info.get("SelectedFilters", []) or []],
                        "threaded": info.get("DisplayInThreadedMode") == "YES",
                        "focus": info.get("FocusEnabled") == "YES",
                    }
    return defs, locals_by_id


def describe_criterion(c: dict, indent: int = 0) -> list[str]:
    """Render one criterion (recursive for Compound) as indented text lines."""
    pad = "  " * indent
    header = c.get("Header", "?")
    name = c.get("Name")
    out: list[str] = []
    if header == "Compound":
        combiner = "AND" if c.get("AllCriteriaMustBeSatisfied") else "OR"
        title = f"{pad}group ({combiner})"
        if name:
            title += f"  # {name}"
        out.append(title)
        for sub in c.get("Criteria", []) or []:
            out.extend(describe_criterion(sub, indent + 1))
        return out
    if header == "NotInTrashMailbox":
        out.append(f"{pad}NOT in Trash")
    elif header == "NotInJunkMailbox":
        out.append(f"{pad}NOT in Junk")
    elif header == "NotInASpecialMailbox":
        smt = c.get("SpecialMailboxType")
        out.append(f"{pad}NOT in {SPECIAL_MAILBOX_TYPE.get(smt, f'Special#{smt}')}")
    elif header == "InSpecialMailbox":
        smt = c.get("SpecialMailboxType")
        out.append(f"{pad}IN {SPECIAL_MAILBOX_TYPE.get(smt, f'Special#{smt}')}")
    elif header == "DateLastViewed":
        qual = c.get("Qualifier", "?")
        expr = c.get("Expression", "")
        unit = DATE_UNIT_TYPE.get(c.get("DateUnitType"), "?")
        rel = " (relative)" if c.get("DateIsRelative") else ""
        out.append(f"{pad}DateLastViewed {qual} {expr} {unit}{rel}")
    elif header == "DateReceived" or header == "DateSent":
        qual = c.get("Qualifier", "?")
        expr = c.get("Expression", "")
        unit = DATE_UNIT_TYPE.get(c.get("DateUnitType"), "?")
        rel = " (relative)" if c.get("DateIsRelative") else ""
        out.append(f"{pad}{header} {qual} {expr} {unit}{rel}")
    else:
        # Generic: From/To/Cc/Subject/MessageContent/etc.
        qual = c.get("Qualifier")
        expr = c.get("Expression")
        bits = [pad + header]
        if qual:
            bits.append(qual)
        if expr is not None:
            bits.append(repr(expr))
        out.append(" ".join(bits))
    if name and header != "Compound":
        out[-1] += f"  # {name}"
    return out


def cmd_smartboxes_list(args) -> int:
    defs, locals_by_id = load_smartboxes()
    if args.json:
        print(json.dumps([{
            "name": d.get("MailboxName"),
            "id": d.get("MailboxID"),
            "criteria_count": len(d.get("MailboxCriteria", []) or []),
            "children": len(d.get("MailboxChildren", []) or []),
            "combiner": "AND" if d.get("MailboxAllCriteriaMustBeSatisfied") else "OR",
            "ui": locals_by_id.get(d.get("MailboxID"), {}),
        } for d in defs], indent=2, ensure_ascii=False))
        return 0
    print(f"Smart mailboxes ({len(defs)}) — {find_smartbox_plists()[0]}")
    for d in defs:
        mid = d.get("MailboxID", "")
        name = d.get("MailboxName", "?")
        combiner = "AND" if d.get("MailboxAllCriteriaMustBeSatisfied") else "OR"
        nc = len(d.get("MailboxCriteria", []) or [])
        ui = locals_by_id.get(mid, {})
        unread = ui.get("unread", "—")
        sort = ui.get("sort_order", "")
        suffix = f"  [unread {unread}"
        if sort:
            arrow = "↓" if ui.get("descending") else "↑"
            suffix += f", sort {sort}{arrow}"
        if ui.get("filters"):
            suffix += f", filter {'+'.join(ui['filters'])}"
        suffix += "]"
        print(f"  {name}  ({combiner}, {nc} criteria){suffix}")
    return 0


def cmd_smartboxes_show(args) -> int:
    defs, locals_by_id = load_smartboxes()
    name = args.name
    hits = [d for d in defs if d.get("MailboxName") == name]
    if not hits:
        # case-insensitive fallback
        hits = [d for d in defs if (d.get("MailboxName") or "").lower() == name.lower()]
    if not hits:
        names = ", ".join(repr(d.get("MailboxName")) for d in defs)
        sys.exit(f"No smart mailbox named {name!r}. Known: {names}")
    d = hits[0]
    mid = d.get("MailboxID", "")
    if args.json:
        print(json.dumps({
            "definition": d,
            "ui_state": locals_by_id.get(mid, {}),
        }, indent=2, ensure_ascii=False, default=str))
        return 0
    print(f"Smart mailbox: {d.get('MailboxName')}")
    print(f"  ID:        {mid}")
    print(f"  Type:      {d.get('MailboxType')} (7 == smart)")
    combiner = "AND" if d.get("MailboxAllCriteriaMustBeSatisfied") else "OR"
    print(f"  Combiner:  {combiner}")
    children = d.get("MailboxChildren") or []
    if children:
        print(f"  Children:  {len(children)} nested smart mailboxes")
    ui = locals_by_id.get(mid)
    if ui:
        print(f"  Unread:    {ui['unread']}")
        sort_arrow = "↓" if ui["descending"] else "↑"
        print(f"  Sort:      {ui['sort_order']}{sort_arrow}"
              f"   threaded={ui['threaded']}   focus={ui['focus']}")
        if ui["filters"]:
            print(f"  Filters:   {', '.join(ui['filters'])}")
    print("  Criteria:")
    for c in d.get("MailboxCriteria", []) or []:
        for line in describe_criterion(c, indent=2):
            print(line)
    return 0


def cmd_smartboxes_dump(args) -> int:
    """Raw plist contents as JSON — for piping into jq."""
    defs, locals_by_id = load_smartboxes()
    print(json.dumps({
        "definitions": defs,
        "local_properties": locals_by_id,
    }, indent=2, ensure_ascii=False, default=str))
    return 0


def cmd_smartboxes_export(args) -> int:
    """Write one markdown file per smart mailbox into the vault."""
    env = load_env()
    vault = Path(env["VAULT_PATH"]) / "smartboxes"
    vault.mkdir(parents=True, exist_ok=True)
    defs, locals_by_id = load_smartboxes()

    index_lines = ["# Smart Mailboxes", "",
                   f"Source: `{find_smartbox_plists()[0]}`", "",
                   f"Count: **{len(defs)}**", "",
                   "| Name | Combiner | Criteria | Unread | Sort |",
                   "|------|----------|----------|--------|------|"]
    for d in defs:
        name = d.get("MailboxName", "?")
        mid = d.get("MailboxID", "")
        combiner = "AND" if d.get("MailboxAllCriteriaMustBeSatisfied") else "OR"
        nc = len(d.get("MailboxCriteria", []) or [])
        ui = locals_by_id.get(mid, {})
        unread = ui.get("unread", "—")
        sort = ui.get("sort_order", "")
        if sort:
            sort += "↓" if ui.get("descending") else "↑"
        slug = slugify(name)
        index_lines.append(f"| [{name}]({slug}.md) | {combiner} | {nc} | {unread} | {sort} |")

        body = [f"# {name}", "",
                f"- **ID:** `{mid}`",
                f"- **Combiner:** {combiner}",
                f"- **MailboxType:** {d.get('MailboxType')}"]
        children = d.get("MailboxChildren") or []
        if children:
            body.append(f"- **Children:** {len(children)} nested")
        if ui:
            body.append(f"- **Unread:** {ui['unread']}")
            arrow = "↓" if ui["descending"] else "↑"
            body.append(f"- **Sort:** {ui['sort_order']}{arrow}")
            if ui["filters"]:
                body.append(f"- **Filters:** {', '.join(ui['filters'])}")
            body.append(f"- **Threaded:** {ui['threaded']}   **Focus:** {ui['focus']}")
        body += ["", "## Criteria", "", "```"]
        for c in d.get("MailboxCriteria", []) or []:
            body.extend(describe_criterion(c, indent=0))
        body.append("```")
        write_md(vault / f"{slug}.md", "\n".join(body) + "\n")

    write_md(vault / "_index.md", "\n".join(index_lines) + "\n")
    print(f"Wrote {len(defs)} smartbox(es) + index to {vault}")
    return 0


def cmd_smartboxes_diff(args) -> int:
    """Compare current definitions against a saved snapshot file."""
    snap = Path(os.path.expanduser(args.snapshot))
    defs, _ = load_smartboxes()
    if args.write:
        snap.parent.mkdir(parents=True, exist_ok=True)
        with open(snap, "wb") as f:
            plistlib.dump(defs, f, fmt=plistlib.FMT_XML)
        print(f"Wrote snapshot: {snap}")
        return 0
    if not snap.exists():
        sys.exit(f"No snapshot at {snap}. Run with --write to create one.")
    with open(snap, "rb") as f:
        prev = plistlib.load(f)

    def by_id(seq):
        return {d.get("MailboxID"): d for d in seq if d.get("MailboxID")}

    cur, old = by_id(defs), by_id(prev)
    added = [cur[k].get("MailboxName") for k in cur.keys() - old.keys()]
    removed = [old[k].get("MailboxName") for k in old.keys() - cur.keys()]
    changed = []
    for k in cur.keys() & old.keys():
        if cur[k] != old[k]:
            changed.append((cur[k].get("MailboxName"), old[k].get("MailboxName")))
    if not (added or removed or changed):
        print(f"No changes since {snap}")
        return 0
    if added:
        print("Added:")
        for n in added:
            print(f"  + {n}")
    if removed:
        print("Removed:")
        for n in removed:
            print(f"  - {n}")
    if changed:
        print("Changed:")
        for new_n, old_n in changed:
            label = new_n if new_n == old_n else f"{old_n} → {new_n}"
            print(f"  ~ {label}")
    return 0


def main() -> int:
    p = argparse.ArgumentParser(prog="mail-exporter")
    sub = p.add_subparsers(dest="cmd", required=True)
    sub.add_parser("status").set_defaults(func=cmd_status)
    sp = sub.add_parser("mailboxes"); sp.add_argument("--json", action="store_true"); sp.set_defaults(func=cmd_mailboxes)
    sp = sub.add_parser("top-senders"); sp.add_argument("--limit", type=int); sp.set_defaults(func=cmd_top_senders)
    sp = sub.add_parser("subjects")
    sp.add_argument("--match"); sp.add_argument("--limit", type=int)
    sp.set_defaults(func=cmd_subjects)
    sp = sub.add_parser("search")
    sp.add_argument("--subject"); sp.add_argument("--sender")
    sp.add_argument("--since"); sp.add_argument("--limit", type=int)
    sp.set_defaults(func=cmd_search)
    sp = sub.add_parser("export")
    sp.add_argument("--per-mailbox-limit", type=int,
                    help="Max headers per mailbox in vault (default 200)")
    sp.set_defaults(func=cmd_export)

    sp = sub.add_parser("smartboxes", help="read Smart Mailboxes (plist-backed; not in Mail.sdef)")
    sb = sp.add_subparsers(dest="action", required=True)
    sb_list = sb.add_parser("list", help="list smart mailboxes with combiner + unread + sort")
    sb_list.add_argument("--json", action="store_true")
    sb_list.set_defaults(func=cmd_smartboxes_list)
    sb_show = sb.add_parser("show", help="show one smart mailbox criteria tree")
    sb_show.add_argument("name")
    sb_show.add_argument("--json", action="store_true")
    sb_show.set_defaults(func=cmd_smartboxes_show)
    sb_dump = sb.add_parser("dump", help="raw plist contents as JSON")
    sb_dump.set_defaults(func=cmd_smartboxes_dump)
    sb_export = sb.add_parser("export", help="write one .md per smart mailbox to the vault")
    sb_export.set_defaults(func=cmd_smartboxes_export)
    sb_diff = sb.add_parser("diff", help="diff current definitions vs a saved snapshot")
    sb_diff.add_argument("snapshot", help="path to snapshot .plist")
    sb_diff.add_argument("--write", action="store_true",
                         help="write current state to snapshot instead of comparing")
    sb_diff.set_defaults(func=cmd_smartboxes_diff)

    sp = sub.add_parser("xref", help="cross-reference messages against Calendar events")
    sp.add_argument("--calendar", action="store_true",
                    help="match messages to Calendar events (required selector)")
    sp.add_argument("--window", type=int, default=60,
                    help="±minutes around message date_received (default 60)")
    sp.add_argument("--since", help="ISO date YYYY-MM-DD lower bound")
    sp.add_argument("--limit", type=int, default=200)
    sp.add_argument("--json", action="store_true")
    sp.set_defaults(func=cmd_xref_calendar)

    args = p.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
