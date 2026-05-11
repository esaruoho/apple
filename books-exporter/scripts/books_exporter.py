#!/usr/bin/env python3
"""
books-exporter — Apple Books library, collections, and annotations to markdown.

Two SQLite stores under ~/Library/Containers/com.apple.iBooksX/Data/Documents/:

  - BKLibrary/BKLibrary-1-091020131601.sqlite — books (ZBKLIBRARYASSET) +
    collections (ZBKCOLLECTION) + membership (ZBKCOLLECTIONMEMBER)
  - AEAnnotation/AEAnnotation_v10312011_1727_local.sqlite — highlights and
    notes (ZAEANNOTATION). Joins to books by ZANNOTATIONASSETID = book ZASSETID.

The filenames contain build timestamps; we glob the first match.

Subcommands:
  status                library + annotation counts
  list                  books, optionally filtered
  collections           collection tree with counts
  annotations [--book]  highlights / notes
  export                full vault under VAULT_PATH

Vault layout:
  exported/books/
    _index.md                    master list
    collections/<slug>/_index.md per-collection list
    by-id/<asset-id>.md          one file per book (with annotations
                                 inlined if any)
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sqlite3
import sys
from collections import defaultdict
from datetime import datetime, timedelta, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_ENV = ROOT / ".env"
BOOKS_BASE = Path.home() / "Library/Containers/com.apple.iBooksX/Data/Documents"
COCOA_EPOCH = datetime(2001, 1, 1, tzinfo=timezone.utc)

sys.path.insert(0, str(ROOT.parent / "bin" / "lib"))
from apple_sqlite_snapshot import snapshot_open_persistent  # noqa: E402


def load_env() -> dict[str, str]:
    env: dict[str, str] = {}
    if DEFAULT_ENV.exists():
        for line in DEFAULT_ENV.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            env[k.strip()] = os.path.expanduser(v.strip().strip('"').strip("'"))
    env.setdefault("VAULT_PATH", os.path.expanduser("~/work/apple/exported/books"))
    env["VAULT_PATH"] = os.path.expanduser(env["VAULT_PATH"])
    return env


def slugify(s: str) -> str:
    s = re.sub(r"[^a-zA-Z0-9._-]+", "-", s).strip("-").lower()
    return (s or "untitled")[:80]


def find_db(subdir: str, glob: str) -> Path | None:
    d = BOOKS_BASE / subdir
    if not d.exists():
        return None
    hits = list(d.glob(glob))
    return hits[0] if hits else None


def library_db() -> Path | None:
    return find_db("BKLibrary", "BKLibrary-*.sqlite")


def annotation_db() -> Path | None:
    return find_db("AEAnnotation", "AEAnnotation_*.sqlite")


def cocoa_to_iso(z: float | None) -> str:
    if z is None:
        return ""
    return (COCOA_EPOCH + timedelta(seconds=z)).isoformat()


# =====================================================================
# Queries
# =====================================================================

def fetch_books() -> list[dict]:
    db = library_db()
    if not db:
        return []
    con = snapshot_open_persistent(db)
    try:
        rows = con.execute("""
            SELECT Z_PK, ZASSETID, ZTITLE, ZAUTHOR, ZGENRE, ZYEAR, ZKIND,
                   ZPATH, ZSTOREID, ZSORTAUTHOR, ZSORTTITLE,
                   ZCREATIONDATE, ZLASTOPENDATE, ZREADINGPROGRESS,
                   ZBOOKDESCRIPTION
            FROM ZBKLIBRARYASSET
            ORDER BY ZSORTAUTHOR COLLATE NOCASE, ZSORTTITLE COLLATE NOCASE
        """).fetchall()
    except sqlite3.OperationalError as e:
        print(f"library query failed: {e}", file=sys.stderr)
        rows = []
    con.close()
    out = []
    for r in rows:
        (pk, aid, title, author, genre, year, kind, path, store, sa, st,
         cd, lod, prog, desc) = r
        out.append({
            "pk": pk, "asset_id": aid or "",
            "title": title or "(untitled)",
            "author": author or "",
            "genre": genre or "",
            "year": year or "",
            "kind": kind or "",
            "path": path or "",
            "store_id": store or "",
            "created": cocoa_to_iso(cd),
            "last_open": cocoa_to_iso(lod),
            "progress": float(prog) if prog is not None else 0.0,
            "description": desc or "",
        })
    return out


def fetch_collections() -> tuple[list[dict], dict[str, list[str]]]:
    """Return (collections, {asset_id -> [collection_name]})."""
    db = library_db()
    if not db:
        return [], {}
    con = snapshot_open_persistent(db)
    cols = con.execute("""
        SELECT Z_PK, ZTITLE, ZLASTMODIFICATION, ZSORTKEY
        FROM ZBKCOLLECTION
        WHERE ZDELETEDFLAG = 0 AND ZHIDDEN = 0
        ORDER BY ZSORTKEY ASC
    """).fetchall()
    membership = defaultdict(list)
    by_pk = {c[0]: (c[1] or "(unnamed)") for c in cols}
    try:
        mem = con.execute("""
            SELECT ZASSETID, ZCOLLECTION
            FROM ZBKCOLLECTIONMEMBER
            WHERE ZASSETID IS NOT NULL
        """).fetchall()
        for asset, col_pk in mem:
            if asset and col_pk in by_pk:
                membership[asset].append(by_pk[col_pk])
    except sqlite3.OperationalError:
        pass
    con.close()
    collections = [{"pk": c[0], "name": by_pk[c[0]],
                    "modified": cocoa_to_iso(c[2]),
                    "sort_key": c[3] or 0} for c in cols]
    return collections, membership


def fetch_annotations() -> list[dict]:
    db = annotation_db()
    if not db:
        return []
    con = snapshot_open_persistent(db)
    try:
        rows = con.execute("""
            SELECT ZANNOTATIONASSETID, ZANNOTATIONSELECTEDTEXT,
                   ZANNOTATIONNOTE, ZANNOTATIONREPRESENTATIVETEXT,
                   ZANNOTATIONLOCATION, ZANNOTATIONSTYLE,
                   ZANNOTATIONCREATIONDATE, ZANNOTATIONMODIFICATIONDATE,
                   ZANNOTATIONUUID
            FROM ZAEANNOTATION
            WHERE ZANNOTATIONDELETED = 0
              AND (ZANNOTATIONSELECTEDTEXT IS NOT NULL
                   OR ZANNOTATIONNOTE IS NOT NULL)
            ORDER BY ZANNOTATIONASSETID, ZANNOTATIONCREATIONDATE
        """).fetchall()
    except sqlite3.OperationalError as e:
        print(f"annotation query failed: {e}", file=sys.stderr)
        rows = []
    con.close()
    out = []
    for r in rows:
        aid, sel, note, rep, loc, style, cd, md, uuid = r
        out.append({
            "asset_id": aid or "",
            "selected_text": sel or "",
            "note": note or "",
            "representative": rep or "",
            "location": loc or "",
            "style": style,
            "created": cocoa_to_iso(cd),
            "modified": cocoa_to_iso(md),
            "uuid": uuid or "",
        })
    return out


# =====================================================================
# Subcommands
# =====================================================================

def cmd_status(args) -> int:
    books = fetch_books()
    collections, _ = fetch_collections()
    annotations = fetch_annotations()
    finished = sum(1 for b in books if b["progress"] >= 0.95)
    started = sum(1 for b in books if 0 < b["progress"] < 0.95)
    print("Apple Books overview")
    print(f"  Total books:       {len(books)}")
    print(f"  Finished (>=95%):  {finished}")
    print(f"  In progress:       {started}")
    print(f"  Untouched:         {len(books) - finished - started}")
    print(f"  Collections:       {len(collections)}")
    print(f"  Annotations:       {len(annotations)}")
    print(f"  Library DB:        {library_db() or '(missing)'}")
    print(f"  Annotation DB:     {annotation_db() or '(missing)'}")
    return 0


def cmd_list(args) -> int:
    books = fetch_books()
    if args.author:
        rx = re.compile(re.escape(args.author), re.I)
        books = [b for b in books if rx.search(b["author"])]
    if args.match:
        rx = re.compile(re.escape(args.match), re.I)
        books = [b for b in books if rx.search(b["title"])]
    if args.json:
        print(json.dumps(books, indent=2, ensure_ascii=False))
        return 0
    for b in books:
        author = f"  {b['author']}" if b['author'] else ""
        prog = f"  [{int(b['progress']*100)}%]" if b['progress'] else ""
        print(f"  {b['title']}{author}{prog}")
    print(f"\n{len(books)} book(s)")
    return 0


def cmd_collections(args) -> int:
    collections, membership = fetch_collections()
    reverse = defaultdict(list)
    for asset, cols in membership.items():
        for col in cols:
            reverse[col].append(asset)
    for col in collections:
        n = len(reverse.get(col["name"], []))
        print(f"  {col['name']}: {n}")
    return 0


def cmd_annotations(args) -> int:
    anns = fetch_annotations()
    books = {b["asset_id"]: b for b in fetch_books()}
    if args.book:
        rx = re.compile(re.escape(args.book), re.I)
        matched = [aid for aid, b in books.items() if rx.search(b["title"])]
        anns = [a for a in anns if a["asset_id"] in matched]
    if args.json:
        print(json.dumps(anns, indent=2, ensure_ascii=False))
        return 0
    by_book = defaultdict(list)
    for a in anns:
        by_book[a["asset_id"]].append(a)
    for aid, items in by_book.items():
        b = books.get(aid)
        title = b["title"] if b else f"(asset {aid})"
        print(f"\n# {title} ({len(items)} annotation(s))")
        for a in items:
            if a["selected_text"]:
                print(f"  > {a['selected_text'][:200]}")
            if a["note"]:
                print(f"    note: {a['note'][:200]}")
    print(f"\n{len(anns)} annotation(s) across {len(by_book)} book(s)")
    return 0


def render_book_md(b: dict, anns: list[dict]) -> str:
    yaml = ["---", f"title: {json.dumps(b['title'], ensure_ascii=False)}"]
    if b["author"]:
        yaml.append(f"author: {json.dumps(b['author'], ensure_ascii=False)}")
    if b["asset_id"]:
        yaml.append(f"asset_id: {b['asset_id']}")
    if b["genre"]:
        yaml.append(f"genre: {json.dumps(b['genre'], ensure_ascii=False)}")
    if b["year"]:
        yaml.append(f"year: {b['year']}")
    if b["kind"]:
        yaml.append(f"kind: {b['kind']}")
    if b["created"]:
        yaml.append(f"added: {b['created']}")
    if b["last_open"]:
        yaml.append(f"last_open: {b['last_open']}")
    yaml.append(f"progress: {b['progress']:.3f}")
    if anns:
        yaml.append(f"annotations: {len(anns)}")
    yaml.append("---")
    body = [f"# {b['title']}"]
    if b["author"]:
        body.append(f"_by {b['author']}_")
    body.append("")
    if b["description"]:
        body.append(b["description"])
        body.append("")
    if anns:
        body.append("## Highlights & notes")
        body.append("")
        for a in anns:
            if a["selected_text"]:
                body.append(f"> {a['selected_text']}")
            if a["note"]:
                body.append(f"\n_{a['note']}_")
            if a["created"]:
                body.append(f"\n— _{a['created']}_")
            body.append("")
    return "\n".join(yaml) + "\n\n" + "\n".join(body) + "\n"


def cmd_export(args) -> int:
    env = load_env()
    vault = Path(env["VAULT_PATH"])
    (vault / "by-id").mkdir(parents=True, exist_ok=True)
    (vault / "collections").mkdir(parents=True, exist_ok=True)

    books = fetch_books()
    collections, membership = fetch_collections()
    annotations = fetch_annotations()
    ann_by_book = defaultdict(list)
    for a in annotations:
        ann_by_book[a["asset_id"]].append(a)

    for b in books:
        anns = ann_by_book.get(b["asset_id"], [])
        fname = b["asset_id"] or f"pk-{b['pk']}"
        (vault / "by-id" / f"{slugify(fname)}.md").write_text(render_book_md(b, anns))

    # per-collection indexes
    reverse = defaultdict(list)
    for asset, cols in membership.items():
        for col in cols:
            reverse[col].append(asset)
    by_asset = {b["asset_id"]: b for b in books}
    for col in collections:
        cdir = vault / "collections" / slugify(col["name"])
        cdir.mkdir(parents=True, exist_ok=True)
        items = [by_asset.get(a) for a in reverse.get(col["name"], [])]
        items = [i for i in items if i]
        lines = [f"# {col['name']} ({len(items)})", ""]
        for b in sorted(items, key=lambda x: x["title"].lower()):
            fname = slugify(b["asset_id"] or f"pk-{b['pk']}")
            n_ann = len(ann_by_book.get(b["asset_id"], []))
            ann_note = f" — {n_ann} annotation(s)" if n_ann else ""
            lines.append(f"- [{b['title']}](../../by-id/{fname}.md){ann_note}")
        (cdir / "_index.md").write_text("\n".join(lines) + "\n")

    # master
    master = [
        "# Books",
        "",
        f"- **Total:** {len(books)}",
        f"- **Collections:** {len(collections)}",
        f"- **Annotations:** {len(annotations)} across {len(ann_by_book)} book(s)",
        "",
        "## Collections",
        "",
    ]
    for col in collections:
        n = len(reverse.get(col["name"], []))
        master.append(f"- [{col['name']}](./collections/{slugify(col['name'])}/_index.md) — {n}")
    master.append("")
    master.append("## All books (by author / title)")
    master.append("")
    for b in books:
        fname = slugify(b["asset_id"] or f"pk-{b['pk']}")
        author = f" — {b['author']}" if b["author"] else ""
        master.append(f"- [{b['title']}](./by-id/{fname}.md){author}")
    (vault / "_index.md").write_text("\n".join(master) + "\n")
    print(f"wrote {len(books)} book(s), {len(collections)} collection(s), "
          f"{len(annotations)} annotation(s) to {vault}")
    return 0


def main() -> int:
    p = argparse.ArgumentParser(prog="books-exporter")
    sub = p.add_subparsers(dest="cmd", required=True)
    sub.add_parser("status").set_defaults(func=cmd_status)
    sp = sub.add_parser("list")
    sp.add_argument("--author"); sp.add_argument("--match")
    sp.add_argument("--json", action="store_true")
    sp.set_defaults(func=cmd_list)
    sub.add_parser("collections").set_defaults(func=cmd_collections)
    sp = sub.add_parser("annotations")
    sp.add_argument("--book", help="filter to books whose title matches")
    sp.add_argument("--json", action="store_true")
    sp.set_defaults(func=cmd_annotations)
    sub.add_parser("export").set_defaults(func=cmd_export)
    args = p.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
