#!/usr/bin/env python3
"""
contacts-exporter — Apple Contacts to markdown vault.

Reads AddressBook v22 SQLite stores in ~/Library/Application Support/AddressBook/
Sources/<UUID>/AddressBook-v22.abcddb (one DB per account: iCloud / Google /
local). For each source we iterate ZABCDRECORD and pull related rows from
ZABCDEMAILADDRESS, ZABCDPHONENUMBER, ZABCDPOSTALADDRESS, ZABCDURLADDRESS,
ZABCDSOCIALPROFILE — joined by ZOWNER → ZABCDRECORD.Z_PK.

Subcommands:
  status                 source count + contact count
  list                   flat list of all contacts (across all sources)
  search QUERY           substring match against name + organization
  show NAME              full details for one contact
  export                 write the vault under VAULT_PATH

Vault layout:
  exported/contacts/
    _index.md                  master alphabetical list
    by-source/<uuid>/_index.md per-source breakdown
    by-name/<slug>.md          one file per contact (with frontmatter)
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sqlite3
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_ENV = ROOT / ".env"
SOURCES_DIR = Path.home() / "Library/Application Support/AddressBook/Sources"

sys.path.insert(0, str(ROOT.parent / "bin" / "lib"))
from apple_sqlite_snapshot import open_immutable  # noqa: E402


def load_env() -> dict[str, str]:
    env: dict[str, str] = {}
    if DEFAULT_ENV.exists():
        for line in DEFAULT_ENV.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            env[k.strip()] = os.path.expanduser(v.strip().strip('"').strip("'"))
    env.setdefault("VAULT_PATH", os.path.expanduser("~/work/apple/exported/contacts"))
    env["VAULT_PATH"] = os.path.expanduser(env["VAULT_PATH"])
    return env


def slugify(s: str) -> str:
    s = re.sub(r"[^a-zA-Z0-9._-]+", "-", s).strip("-").lower()
    return s or "untitled"


def find_sources() -> list[Path]:
    if not SOURCES_DIR.exists():
        return []
    return sorted(SOURCES_DIR.glob("*/AddressBook-v22.abcddb"))


_APPLE_LABEL_RE = re.compile(r"_\$!<(\w+)>!\$_")


def _clean_label(label: str | None) -> str:
    if not label:
        return ""
    m = _APPLE_LABEL_RE.match(label)
    return m.group(1) if m else label


def fetch_records(db_path: Path) -> list[dict]:
    con = open_immutable(db_path)
    try:
        records = con.execute("""
            SELECT Z_PK, ZFIRSTNAME, ZMIDDLENAME, ZLASTNAME, ZNICKNAME,
                   ZORGANIZATION, ZTITLE, ZJOBTITLE, ZDEPARTMENT
            FROM ZABCDRECORD
            WHERE ZFIRSTNAME IS NOT NULL
               OR ZLASTNAME IS NOT NULL
               OR ZORGANIZATION IS NOT NULL
            ORDER BY COALESCE(ZSORTINGLASTNAME, ZLASTNAME, ZORGANIZATION) COLLATE NOCASE
        """).fetchall()
    except sqlite3.OperationalError:
        # older schemas may lack ZJOBTITLE / ZDEPARTMENT
        records = con.execute("""
            SELECT Z_PK, ZFIRSTNAME, ZMIDDLENAME, ZLASTNAME, ZNICKNAME,
                   ZORGANIZATION, ZTITLE, NULL, NULL
            FROM ZABCDRECORD
            WHERE ZFIRSTNAME IS NOT NULL OR ZLASTNAME IS NOT NULL OR ZORGANIZATION IS NOT NULL
            ORDER BY COALESCE(ZLASTNAME, ZORGANIZATION) COLLATE NOCASE
        """).fetchall()

    pks = [r[0] for r in records]
    if not pks:
        con.close()
        return []
    placeholders = ",".join("?" * len(pks))

    emails = defaultdict(list)
    for owner, addr, label in con.execute(
        f"SELECT ZOWNER, ZADDRESS, ZLABEL FROM ZABCDEMAILADDRESS "
        f"WHERE ZOWNER IN ({placeholders}) ORDER BY ZORDERINGINDEX", pks
    ):
        emails[owner].append({"address": addr, "label": _clean_label(label)})

    phones = defaultdict(list)
    for owner, full, label in con.execute(
        f"SELECT ZOWNER, ZFULLNUMBER, ZLABEL FROM ZABCDPHONENUMBER "
        f"WHERE ZOWNER IN ({placeholders}) ORDER BY ZORDERINGINDEX", pks
    ):
        phones[owner].append({"number": full, "label": _clean_label(label)})

    addrs = defaultdict(list)
    for owner, street, city, state, postal, country, label in con.execute(
        f"SELECT ZOWNER, ZSTREET, ZCITY, ZSTATE, ZSAMA, ZCOUNTRYNAME, ZLABEL "
        f"FROM ZABCDPOSTALADDRESS WHERE ZOWNER IN ({placeholders})", pks
    ):
        addrs[owner].append({"street": street or "", "city": city or "",
                             "state": state or "", "postal": postal or "",
                             "country": country or "", "label": _clean_label(label)})

    urls = defaultdict(list)
    try:
        for owner, url, label in con.execute(
            f"SELECT ZOWNER, ZURL, ZLABEL FROM ZABCDURLADDRESS "
            f"WHERE ZOWNER IN ({placeholders})", pks
        ):
            urls[owner].append({"url": url, "label": _clean_label(label)})
    except sqlite3.OperationalError:
        pass

    socials = defaultdict(list)
    try:
        for owner, service, user in con.execute(
            f"SELECT ZOWNER, ZSERVICENAME, ZUSERNAME FROM ZABCDSOCIALPROFILE "
            f"WHERE ZOWNER IN ({placeholders})", pks
        ):
            socials[owner].append({"service": service or "", "username": user or ""})
    except sqlite3.OperationalError:
        pass

    con.close()

    out: list[dict] = []
    for pk, fn, mn, ln, nick, org, title, job, dept in records:
        parts = [p for p in (fn, mn, ln) if p]
        display = " ".join(parts) or org or "(unnamed)"
        out.append({
            "pk": pk,
            "display": display,
            "first": fn or "", "middle": mn or "", "last": ln or "",
            "nickname": nick or "",
            "organization": org or "",
            "title": title or "",
            "job_title": job or "",
            "department": dept or "",
            "emails": emails.get(pk, []),
            "phones": phones.get(pk, []),
            "addresses": addrs.get(pk, []),
            "urls": urls.get(pk, []),
            "socials": socials.get(pk, []),
            "source": db_path.parent.name,
        })
    return out


def all_contacts() -> list[dict]:
    out: list[dict] = []
    for src in find_sources():
        out.extend(fetch_records(src))
    return out


# =====================================================================
# Subcommands
# =====================================================================

def cmd_status(args) -> int:
    sources = find_sources()
    print("Contacts overview")
    print(f"  Sources: {len(sources)}")
    total = 0
    for src in sources:
        rows = fetch_records(src)
        print(f"    {len(rows):>5}  {src.parent.name}")
        total += len(rows)
    print(f"  Total contacts: {total}")
    return 0


def cmd_list(args) -> int:
    contacts = all_contacts()
    if args.json:
        print(json.dumps(contacts, indent=2, ensure_ascii=False))
        return 0
    for c in contacts:
        org = f"  [{c['organization']}]" if c["organization"] else ""
        primary_email = c["emails"][0]["address"] if c["emails"] else ""
        primary_email = f"  <{primary_email}>" if primary_email else ""
        print(f"  {c['display']}{org}{primary_email}")
    print(f"\n{len(contacts)} contact(s)")
    return 0


def cmd_search(args) -> int:
    contacts = all_contacts()
    q = args.query.lower()
    hits = [c for c in contacts
            if q in c["display"].lower()
            or q in (c["organization"] or "").lower()
            or any(q in e["address"].lower() for e in c["emails"])]
    if args.json:
        print(json.dumps(hits, indent=2, ensure_ascii=False))
        return 0
    for c in hits:
        org = f"  [{c['organization']}]" if c["organization"] else ""
        print(f"  {c['display']}{org}")
    print(f"\n{len(hits)} match(es) for {args.query!r}")
    return 0


def render_contact(c: dict) -> str:
    body = [f"# {c['display']}", ""]
    if c["organization"]:
        body.append(f"**Org** {c['organization']}")
    if c["job_title"] or c["department"]:
        parts = [c["job_title"], c["department"]]
        body.append(f"**Role** {' — '.join(p for p in parts if p)}")
    body.append("")
    if c["emails"]:
        body.append("## Email")
        for e in c["emails"]:
            label = f" _({e['label']})_" if e['label'] else ""
            body.append(f"- {e['address']}{label}")
        body.append("")
    if c["phones"]:
        body.append("## Phone")
        for p in c["phones"]:
            label = f" _({p['label']})_" if p['label'] else ""
            body.append(f"- {p['number']}{label}")
        body.append("")
    if c["addresses"]:
        body.append("## Address")
        for a in c["addresses"]:
            label = f" _({a['label']})_" if a['label'] else ""
            line = ", ".join(p for p in (a['street'], a['city'], a['state'],
                                         a['postal'], a['country']) if p)
            body.append(f"- {line}{label}")
        body.append("")
    if c["urls"]:
        body.append("## URLs")
        for u in c["urls"]:
            label = f" _({u['label']})_" if u['label'] else ""
            body.append(f"- {u['url']}{label}")
        body.append("")
    if c["socials"]:
        body.append("## Social")
        for s in c["socials"]:
            body.append(f"- {s['service']}: {s['username']}")
        body.append("")
    body.append(f"_source: {c['source']}_")
    return "\n".join(body) + "\n"


def cmd_show(args) -> int:
    contacts = all_contacts()
    q = args.name.lower()
    hits = [c for c in contacts if q in c["display"].lower()]
    if not hits:
        sys.exit(f"no contact matching {args.name!r}")
    for c in hits[:5]:
        print(render_contact(c))
    if len(hits) > 5:
        print(f"... and {len(hits)-5} more")
    return 0


def cmd_export(args) -> int:
    env = load_env()
    vault = Path(env["VAULT_PATH"])
    (vault / "by-name").mkdir(parents=True, exist_ok=True)
    (vault / "by-source").mkdir(parents=True, exist_ok=True)

    contacts = all_contacts()
    by_source: dict[str, list[dict]] = defaultdict(list)
    for c in contacts:
        slug = slugify(c["display"]) or f"contact-{c['pk']}"
        # Disambiguate name collisions by appending pk
        target = vault / "by-name" / f"{slug}.md"
        i = 0
        while target.exists():
            i += 1
            target = vault / "by-name" / f"{slug}-{i}.md"
        target.write_text(render_contact(c))
        by_source[c["source"]].append({"slug": target.stem, "display": c["display"]})

    # per-source indexes
    for src, items in by_source.items():
        sdir = vault / "by-source" / src
        sdir.mkdir(parents=True, exist_ok=True)
        lines = [f"# Source {src} ({len(items)})", ""]
        for it in sorted(items, key=lambda x: x["display"].lower()):
            lines.append(f"- [{it['display']}](../../by-name/{it['slug']}.md)")
        (sdir / "_index.md").write_text("\n".join(lines) + "\n")

    # master index
    master = ["# Contacts", "", f"- **Total:** {len(contacts)}",
              f"- **Sources:** {len(by_source)}", "", "## Sources", ""]
    for src in sorted(by_source):
        master.append(f"- [{src}](./by-source/{src}/_index.md) — {len(by_source[src])}")
    master.append("")
    master.append("## All contacts (alphabetical)")
    master.append("")
    for c in sorted(contacts, key=lambda x: x["display"].lower()):
        slug = slugify(c["display"]) or f"contact-{c['pk']}"
        target = vault / "by-name" / f"{slug}.md"
        if not target.exists():
            # collision suffixed
            for cand in (vault / "by-name").glob(f"{slug}-*.md"):
                target = cand
                break
        master.append(f"- [{c['display']}](./by-name/{target.stem}.md)")
    (vault / "_index.md").write_text("\n".join(master) + "\n")

    print(f"wrote {len(contacts)} contact(s) across {len(by_source)} source(s) to {vault}")
    return 0


def main() -> int:
    p = argparse.ArgumentParser(prog="contacts-exporter", description=__doc__.splitlines()[1])
    sub = p.add_subparsers(dest="cmd", required=True)
    sub.add_parser("status").set_defaults(func=cmd_status)
    sp = sub.add_parser("list"); sp.add_argument("--json", action="store_true"); sp.set_defaults(func=cmd_list)
    sp = sub.add_parser("search"); sp.add_argument("query"); sp.add_argument("--json", action="store_true"); sp.set_defaults(func=cmd_search)
    sp = sub.add_parser("show"); sp.add_argument("name"); sp.set_defaults(func=cmd_show)
    sub.add_parser("export").set_defaults(func=cmd_export)
    args = p.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
