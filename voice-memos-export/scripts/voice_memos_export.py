#!/usr/bin/env python3
"""voice-memos-export — Apple Voice Memos read-only catalog + audio export.

Subcommands (all read-only as far as the Voice Memos data is concerned):
  list      Filtered listing of recordings (date/duration/title/storage filters)
  stats     Aggregates: hours per year, place clusters, series detection
  open      Open a recording in Voice Memos.app, QuickTime, or Finder
  export    Copy or symlink m4a into a vault, write .md sidecar with metadata

Selector grammar (used by `open` and single-target `export`):
  - UUID prefix          2EC8B
  - Title substring      "Mauri"
  - Date YYYY-MM-DD      2026-05-07
  - Index #N (0-based)   #0 = newest
  - "latest" keyword     latest
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import sqlite3
import subprocess
import sys
from collections import Counter
from dataclasses import dataclass, asdict
from datetime import datetime, timedelta, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_ENV = ROOT / ".env"
STATE_FILE = ROOT / ".state.json"

VM_DB = Path(os.path.expanduser(
    "~/Library/Group Containers/group.com.apple.VoiceMemos.shared/Recordings/CloudRecordings.db"
))
VM_REC_DIR = VM_DB.parent

COCOA_EPOCH = datetime(2001, 1, 1, tzinfo=timezone.utc)


def cocoa_to_dt(z: float | None) -> datetime | None:
    if z is None:
        return None
    return COCOA_EPOCH + timedelta(seconds=z)


def fmt_dur(secs: float) -> str:
    if secs < 60:
        return f"{secs:.1f}s"
    m, s = divmod(int(secs), 60)
    if m < 60:
        return f"{m}:{s:02d}"
    h, m = divmod(m, 60)
    return f"{h}:{m:02d}:{s:02d}"


def load_env() -> dict[str, str]:
    env: dict[str, str] = {}
    if DEFAULT_ENV.exists():
        for line in DEFAULT_ENV.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            env[k.strip()] = os.path.expanduser(v.strip().strip('"').strip("'"))
    env.setdefault("VAULT_PATH", os.path.expanduser("~/voice-memos-vault"))
    env["VAULT_PATH"] = os.path.expanduser(env["VAULT_PATH"])
    return env


@dataclass
class Memo:
    pk: int
    uuid: str
    title: str
    raw_label: str | None
    date_iso: str
    date_dt: datetime
    duration: float
    path: str | None
    folder: int | None
    flagged: bool
    evicted: bool

    @property
    def m4a(self) -> Path | None:
        if not self.path:
            return None
        return VM_REC_DIR / self.path

    @property
    def m4a_exists(self) -> bool:
        p = self.m4a
        return bool(p and p.exists())


def open_db() -> sqlite3.Connection:
    if not VM_DB.exists():
        sys.exit(f"Voice Memos DB not found at {VM_DB}.\n"
                 "Grant Full Disk Access to Terminal in System Settings → Privacy & Security.")
    # read-only via uri
    uri = f"file:{VM_DB}?mode=ro"
    return sqlite3.connect(uri, uri=True)


def load_memos() -> list[Memo]:
    con = open_db()
    cur = con.execute("""
        SELECT
          Z_PK, ZUNIQUEID,
          COALESCE(NULLIF(ZENCRYPTEDTITLE,''), NULLIF(ZCUSTOMLABELFORSORTING,''), NULLIF(ZCUSTOMLABEL,''), '?'),
          ZCUSTOMLABEL,
          ZDATE, ZDURATION, ZPATH, ZFOLDER, ZFLAGS, ZEVICTIONDATE
        FROM ZCLOUDRECORDING
        ORDER BY ZDATE DESC
    """)
    out = []
    for pk, uuid, title, raw_label, zdate, zdur, zpath, zfolder, zflags, zev in cur:
        dt = cocoa_to_dt(zdate)
        out.append(Memo(
            pk=pk, uuid=uuid or "",
            title=title or "?",
            raw_label=raw_label,
            date_iso=dt.strftime("%Y-%m-%d %H:%M:%S") if dt else "",
            date_dt=dt or datetime(1970, 1, 1, tzinfo=timezone.utc),
            duration=float(zdur or 0.0),
            path=zpath,
            folder=zfolder,
            flagged=bool((zflags or 0) & 0x4),  # heuristic — Apple uses bit flags
            evicted=zev is not None,
        ))
    con.close()
    return out


# ---------- filtering ----------

DURATION_RE = re.compile(r"^(\d+(?:\.\d+)?)\s*(s|m|h|sec|min|hr|hrs|seconds|minutes|hours)?$", re.I)


def parse_duration(s: str) -> float:
    m = DURATION_RE.match(s.strip())
    if not m:
        raise ValueError(f"Bad duration spec: {s!r} (try '30s', '5m', '1h')")
    n = float(m.group(1))
    unit = (m.group(2) or "s").lower()[:1]
    return n * {"s": 1, "m": 60, "h": 3600}[unit]


def filter_memos(memos: list[Memo], args) -> list[Memo]:
    out = memos
    if args.since:
        try:
            since_dt = datetime.fromisoformat(args.since).replace(tzinfo=timezone.utc)
        except ValueError:
            # accept YYYY-MM
            since_dt = datetime.strptime(args.since, "%Y-%m").replace(tzinfo=timezone.utc)
        out = [m for m in out if m.date_dt >= since_dt]
    if args.until:
        until_dt = datetime.fromisoformat(args.until).replace(tzinfo=timezone.utc)
        out = [m for m in out if m.date_dt <= until_dt]
    if args.in_:
        # year or year-month
        token = args.in_
        if len(token) == 4:
            out = [m for m in out if m.date_dt.strftime("%Y") == token]
        else:
            out = [m for m in out if m.date_dt.strftime("%Y-%m") == token]
    if args.longer_than:
        n = parse_duration(args.longer_than)
        out = [m for m in out if m.duration >= n]
    if args.shorter_than:
        n = parse_duration(args.shorter_than)
        out = [m for m in out if m.duration <= n]
    if args.match:
        pat = re.compile(args.match, re.I)
        out = [m for m in out if pat.search(m.title or "")]
    if args.at:
        sub = args.at.lower()
        out = [m for m in out if sub in (m.title or "").lower()]
    if args.evicted:
        out = [m for m in out if m.evicted]
    if args.local:
        out = [m for m in out if not m.evicted]
    if args.sort == "duration":
        out.sort(key=lambda m: m.duration, reverse=True)
    elif args.sort == "title":
        out.sort(key=lambda m: (m.title or "").lower())
    # default already date desc
    return out


# ---------- selector resolution ----------

def resolve_selector(memos: list[Memo], sel: str) -> Memo:
    if sel == "latest":
        return memos[0]
    if sel.startswith("#"):
        idx = int(sel[1:])
        return memos[idx]
    # date YYYY-MM-DD: pick first match (newest with that date)
    if re.fullmatch(r"\d{4}-\d{2}-\d{2}", sel):
        for m in memos:
            if m.date_iso.startswith(sel):
                return m
        raise SystemExit(f"No recording on {sel}")
    # UUID prefix (case-insensitive, hex chars/dashes only)
    if re.fullmatch(r"[0-9A-Fa-f-]{4,}", sel):
        sel_u = sel.upper()
        hits = [m for m in memos if m.uuid.upper().startswith(sel_u)]
        if len(hits) == 1:
            return hits[0]
        if len(hits) > 1:
            raise SystemExit(f"UUID prefix {sel!r} matches {len(hits)} recordings — narrow it.")
    # title substring
    sub = sel.lower()
    hits = [m for m in memos if sub in (m.title or "").lower()]
    if len(hits) == 1:
        return hits[0]
    if len(hits) > 1:
        # if multiple, prefer exact case-insensitive title match
        exact = [m for m in hits if (m.title or "").lower() == sub]
        if len(exact) == 1:
            return exact[0]
        lines = "\n".join(f"  #{i:<3} {m.date_iso}  {fmt_dur(m.duration):>8}  {m.title}"
                          for i, m in enumerate(hits[:10]))
        raise SystemExit(f"Selector {sel!r} matched {len(hits)} recordings. Top results:\n{lines}\n"
                         f"Narrow with UUID prefix or '#N' index.")
    raise SystemExit(f"No recording matches selector {sel!r}.")


# ---------- subcommands ----------

def cmd_list(args) -> int:
    memos = filter_memos(load_memos(), args)
    if args.json:
        out = [{
            "uuid": m.uuid,
            "title": m.title,
            "date": m.date_iso,
            "duration_seconds": round(m.duration, 1),
            "path": m.path,
            "evicted": m.evicted,
            "folder": m.folder,
        } for m in memos]
        print(json.dumps(out, indent=2, ensure_ascii=False))
        return 0
    if args.csv:
        print("idx,uuid,date,duration_seconds,storage,title,path")
        for i, m in enumerate(memos):
            title = (m.title or "").replace('"', '""')
            print(f'{i},{m.uuid},{m.date_iso},{m.duration:.1f},'
                  f'{"cloud" if m.evicted else "local"},"{title}",{m.path or ""}')
        return 0
    n = len(memos)
    if not n:
        print("(no recordings match)")
        return 0
    for i, m in enumerate(memos):
        flag = "CLD" if m.evicted else ("   " if m.m4a_exists else "MIS")
        print(f"{i:>4} {m.date_iso}  {fmt_dur(m.duration):>9}  {flag}  "
              f"{(m.title or '?'):<48}  {m.path or ''}")
    print(f"\n{n} recording(s) match.")
    return 0


PLACE_PREFIXES = (
    "Inkiväärikuja", "Sahaajankatu", "Kauppakeskus Columbus", "Family Hotel",
    "Lintuparvenkuja", "Vuosaaren", "Lillkallvik", "Putouskuja", "Kaivokatu",
    "Marjaniemen", "Roihuvuorentie", "Sofia-keskus", "Itäkeskus",
    "Espoonlahti-Saunalahti", "Tapulimäki", "Haartmaninkatu", "Mäntykorvenkuja",
    "Pampula", "Marjan Mökki", "Hertford", "Velingrad", "Carrer Helena",
    "Oakland International Airport", "Lapinlahden Puisto", "Lintulahdenkatu",
    "Hiekkalaituri", "Ketsuppipuristelua",
)


def cmd_stats(args) -> int:
    memos = filter_memos(load_memos(), args)
    if not memos:
        print("(no recordings)")
        return 0
    total_dur = sum(m.duration for m in memos)
    print(f"Total recordings:  {len(memos)}")
    print(f"Total duration:    {fmt_dur(total_dur)}  ({total_dur/3600:.1f} hours)")
    print(f"Date range:        {memos[-1].date_iso} → {memos[0].date_iso}")
    print(f"Local on disk:     {sum(1 for m in memos if not m.evicted)}")
    print(f"Cloud-only:        {sum(1 for m in memos if m.evicted)}")
    print()

    print("By year:")
    by_year: dict[str, list[Memo]] = {}
    for m in memos:
        y = m.date_dt.strftime("%Y")
        by_year.setdefault(y, []).append(m)
    for y in sorted(by_year, reverse=True):
        ms = by_year[y]
        td = sum(x.duration for x in ms)
        print(f"  {y}  {len(ms):>4} recordings  {fmt_dur(td):>10}")
    print()

    print("Place clusters (by title prefix):")
    cluster_counts = Counter()
    for m in memos:
        for p in PLACE_PREFIXES:
            if (m.title or "").lower().startswith(p.lower()):
                cluster_counts[p] += 1
                break
    for p, n in cluster_counts.most_common(15):
        print(f"  {n:>4}  {p}")
    print()

    print("Longest 10 recordings:")
    for m in sorted(memos, key=lambda m: m.duration, reverse=True)[:10]:
        print(f"  {fmt_dur(m.duration):>10}  {m.date_iso[:10]}  {m.title}")
    print()

    print("Shortest 5 (likely accidental taps):")
    for m in sorted(memos, key=lambda m: m.duration)[:5]:
        print(f"  {fmt_dur(m.duration):>10}  {m.date_iso[:10]}  {m.title}")
    return 0


def cmd_open(args) -> int:
    memos = load_memos()
    m = resolve_selector(memos, args.selector)
    print(f"→ {m.date_iso}  {fmt_dur(m.duration)}  {m.title}")
    if m.evicted or not m.m4a_exists:
        print("  (cloud-only or audio missing) — opening in Voice Memos.app to trigger download")
        subprocess.run(["open", "-a", "Voice Memos"], check=False)
        return 0
    target = m.m4a
    if args.reveal:
        subprocess.run(["open", "-R", str(target)], check=False)
    elif args.quicktime:
        subprocess.run(["open", "-a", "QuickTime Player", str(target)], check=False)
    else:
        subprocess.run(["open", "-a", "Voice Memos"], check=False)
        # also reveal in Finder so user can play directly
        subprocess.run(["open", "-R", str(target)], check=False)
    return 0


SLUG_RE = re.compile(r"[^a-zA-Z0-9._-]+")


def slugify(s: str, max_len: int = 60) -> str:
    s = SLUG_RE.sub("-", s).strip("-")
    return (s[:max_len] or "untitled").lower()


def write_sidecar(env: dict, m: Memo, audio_target: Path | None) -> Path:
    year = m.date_dt.strftime("%Y")
    month = m.date_dt.strftime("%m")
    out_dir = Path(env["VAULT_PATH"]) / year / month
    out_dir.mkdir(parents=True, exist_ok=True)
    stem = f"{m.date_dt.strftime('%Y-%m-%d__%H%M')}__{slugify(m.title)}__{m.uuid[:8]}"
    md_path = out_dir / f"{stem}.md"
    fm = {
        "uuid": m.uuid,
        "title": m.title,
        "raw_label": m.raw_label or "",
        "date": m.date_iso,
        "duration_seconds": round(m.duration, 2),
        "duration_human": fmt_dur(m.duration),
        "path": m.path or "",
        "evicted": m.evicted,
        "audio_in_vault": audio_target.name if audio_target else "",
        "source_db": str(VM_DB),
    }
    lines = ["---"]
    for k, v in fm.items():
        if isinstance(v, str):
            lines.append(f'{k}: "{v.replace(chr(34), chr(92)+chr(34))}"')
        else:
            lines.append(f"{k}: {json.dumps(v)}")
    lines.append("---")
    lines.append("")
    lines.append(f"# {m.title}")
    lines.append("")
    lines.append(f"- **Recorded**: {m.date_iso}")
    lines.append(f"- **Duration**: {fmt_dur(m.duration)} ({m.duration:.1f}s)")
    if m.evicted:
        lines.append("- **Storage**: ☁️ cloud-only on this Mac")
    elif audio_target:
        lines.append(f"- **Audio**: `{audio_target.name}` (next to this file)")
    lines.append("")
    md_path.write_text("\n".join(lines))
    return md_path


def cmd_export(args) -> int:
    env = load_env()
    memos = load_memos()
    if not args.all and not args.selector:
        print("Pass a selector, or --all to export everything.", file=sys.stderr)
        return 2
    targets = memos if args.all else [resolve_selector(memos, args.selector)]
    targets = filter_memos(targets, args)

    Path(env["VAULT_PATH"]).mkdir(parents=True, exist_ok=True)
    n_audio = n_md = n_skipped = 0

    for m in targets:
        # decide audio destination
        audio_target: Path | None = None
        if not m.evicted and m.m4a_exists:
            year = m.date_dt.strftime("%Y")
            month = m.date_dt.strftime("%m")
            out_dir = Path(env["VAULT_PATH"]) / year / month
            out_dir.mkdir(parents=True, exist_ok=True)
            stem = f"{m.date_dt.strftime('%Y-%m-%d__%H%M')}__{slugify(m.title)}__{m.uuid[:8]}"
            audio_target = out_dir / f"{stem}.m4a"
            if audio_target.exists() and not args.force:
                n_skipped += 1
            else:
                if args.copy_audio:
                    shutil.copy2(m.m4a, audio_target)
                else:
                    if audio_target.exists():
                        audio_target.unlink()
                    audio_target.symlink_to(m.m4a)
                n_audio += 1
        write_sidecar(env, m, audio_target)
        n_md += 1

    mode = "copied" if args.copy_audio else "symlinked"
    print(f"\nVault: {env['VAULT_PATH']}")
    print(f"Sidecars written: {n_md}")
    print(f"Audio files {mode}: {n_audio}")
    print(f"Audio skipped (already in vault): {n_skipped}")
    return 0


# ---------- argparse ----------

def add_filter_args(p: argparse.ArgumentParser) -> None:
    p.add_argument("--since", help="Only recordings on/after YYYY-MM[-DD]")
    p.add_argument("--until", help="Only recordings on/before YYYY-MM-DD")
    p.add_argument("--in", dest="in_", help="Only year YYYY or year-month YYYY-MM")
    p.add_argument("--longer-than", help="Min duration (e.g. 30s, 5m, 1h)")
    p.add_argument("--shorter-than", help="Max duration (e.g. 30s, 5m, 1h)")
    p.add_argument("--match", help="Title regex (case-insensitive)")
    p.add_argument("--at", help="Title substring (case-insensitive)")
    p.add_argument("--evicted", action="store_true", help="Cloud-only recordings")
    p.add_argument("--local", action="store_true", help="Recordings with audio on disk")
    p.add_argument("--sort", choices=["date", "duration", "title"], default="date")


def main() -> int:
    p = argparse.ArgumentParser(prog="voice-memos-export")
    sub = p.add_subparsers(dest="cmd", required=True)

    sp = sub.add_parser("list", help="Filtered listing")
    add_filter_args(sp)
    sp.add_argument("--json", action="store_true")
    sp.add_argument("--csv", action="store_true")
    sp.set_defaults(func=cmd_list)

    sp = sub.add_parser("stats", help="Aggregate statistics")
    add_filter_args(sp)
    sp.add_argument("--json", action="store_true")
    sp.add_argument("--csv", action="store_true")
    sp.set_defaults(func=cmd_stats)

    sp = sub.add_parser("open", help="Open a recording (Voice Memos / QuickTime / Finder)")
    sp.add_argument("selector")
    sp.add_argument("--quicktime", action="store_true", help="Open in QuickTime Player")
    sp.add_argument("--reveal", action="store_true", help="Reveal in Finder only")
    sp.set_defaults(func=cmd_open)

    sp = sub.add_parser("export", help="Copy/symlink m4a + write .md sidecars to vault")
    add_filter_args(sp)
    sp.add_argument("selector", nargs="?", help="Single-recording selector (omit with --all)")
    sp.add_argument("--all", action="store_true")
    sp.add_argument("--copy-audio", action="store_true",
                    help="Copy m4a (default: symlink, saves disk)")
    sp.add_argument("--force", action="store_true",
                    help="Overwrite existing audio in vault")
    sp.add_argument("--json", action="store_true")
    sp.add_argument("--csv", action="store_true")
    sp.set_defaults(func=cmd_export)

    args = p.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
