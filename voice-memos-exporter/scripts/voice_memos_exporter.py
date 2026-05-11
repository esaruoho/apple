#!/usr/bin/env python3
"""voice-memos-exporter — Apple Voice Memos read-only catalog + audio export.

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

# WAL-safe Apple SQLite snapshot helper (bin/lib/apple_sqlite_snapshot.py).
# Voice Memos DB is small but Voice Memos.app may be running — use immutable
# for speed (the user typically isn't writing to it during exports).
sys.path.insert(0, str(ROOT.parent / "bin" / "lib"))
from apple_sqlite_snapshot import open_immutable  # noqa: E402

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
    flags_raw: int = 0

    @property
    def m4a(self) -> Path | None:
        if not self.path:
            return None
        return VM_REC_DIR / self.path

    @property
    def m4a_exists(self) -> bool:
        p = self.m4a
        return bool(p and p.exists())

    @property
    def has_apple_transcript(self) -> bool:
        # Empirical: ZFLAGS bit 3 (mask 0x08) is set when Voice Memos has
        # generated an auto-transcript. Verified against on-disk `tsrp` atom
        # in seven 2026 iPad recordings + six older 2024-2026 recordings.
        return bool(self.flags_raw & 0x08)


def open_db() -> sqlite3.Connection:
    if not VM_DB.exists():
        sys.exit(f"Voice Memos DB not found at {VM_DB}.\n"
                 "Grant Full Disk Access to Terminal in System Settings → Privacy & Security.")
    return open_immutable(VM_DB)


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
            flagged=bool((zflags or 0) & 0x4),
            evicted=zev is not None,
            flags_raw=int(zflags or 0),
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
    if args.with_transcripts:
        memos = [m for m in memos if m.has_apple_transcript]
    if args.without_transcripts:
        memos = [m for m in memos if not m.has_apple_transcript]
    cache = load_audio_cache() if args.audio else {}
    if args.audio:
        for m in memos:
            get_audio_info(m, cache)
        save_audio_cache(cache)
    if args.json:
        out = []
        for m in memos:
            row = {
                "uuid": m.uuid,
                "title": m.title,
                "date": m.date_iso,
                "duration_seconds": round(m.duration, 1),
                "path": m.path,
                "evicted": m.evicted,
                "folder": m.folder,
                "apple_transcript": m.has_apple_transcript,
                "flags_raw": m.flags_raw,
            }
            if args.audio:
                row["audio"] = get_audio_info(m, cache) or None
            out.append(row)
        print(json.dumps(out, indent=2, ensure_ascii=False))
        return 0
    if args.csv:
        cols = ["idx","uuid","date","duration_seconds","storage","apple_transcript","title","path"]
        if args.audio:
            cols += ["sample_rate","channels","bit_rate","codec","device"]
        print(",".join(cols))
        for i, m in enumerate(memos):
            title = (m.title or "").replace('"', '""')
            row = [str(i), m.uuid, m.date_iso, f"{m.duration:.1f}",
                   "cloud" if m.evicted else "local",
                   "yes" if m.has_apple_transcript else "no",
                   f'"{title}"', m.path or ""]
            if args.audio:
                a = get_audio_info(m, cache)
                row += [str(a.get("sample_rate","")), str(a.get("channels","")),
                        str(a.get("bit_rate","")), a.get("codec",""), a.get("device","")]
            print(",".join(row))
        return 0
    n = len(memos)
    if not n:
        print("(no recordings match)")
        return 0
    for i, m in enumerate(memos):
        if m.evicted:
            stor = "CLD"
        elif m.m4a_exists:
            stor = "   "
        else:
            stor = "MIS"
        tr = " T " if m.has_apple_transcript else "   "
        line = (f"{i:>4} {m.date_iso}  {fmt_dur(m.duration):>9}  {stor} {tr} "
                f"{(m.title or '?'):<46}")
        if args.audio:
            a = get_audio_info(m, cache)
            if a:
                kbps = a.get("bit_rate", 0) // 1000 if a.get("bit_rate") else 0
                line += f"  {a.get('codec',''):<5} {a.get('sample_rate',0)//1000}k {a.get('channels',0)}ch {kbps}kbps  {a.get('device','')}"
        else:
            line += f"  {m.path or ''}"
        print(line)
    print(f"\n{n} recording(s) match.  T = Apple-generated transcript present")
    return 0


# ---------- transcripts subcommand ----------

def cmd_transcripts(args) -> int:
    memos = filter_memos(load_memos(), args)
    flagged = [m for m in memos if m.has_apple_transcript]
    if args.list_only or (not args.extract and not args.selector):
        print(f"Voice memos with auto-generated Apple transcripts: {len(flagged)}")
        for i, m in enumerate(flagged):
            print(f"  {i:>3}  {m.date_iso}  {fmt_dur(m.duration):>9}  "
                  f"{(m.title or '?'):<50}  {m.uuid[:8]}")
        if not flagged:
            print("(none — your archive has no recordings with Apple's auto-transcripts)")
        return 0

    targets: list[Memo]
    if args.extract and args.all:
        targets = flagged
    elif args.selector:
        targets = [resolve_selector(memos, args.selector)]
    else:
        print("Pass a selector, --all, or omit to list.", file=sys.stderr)
        return 2

    env = load_env()
    n_extracted = n_skipped = 0
    for m in targets:
        if not m.m4a_exists:
            print(f"  ! {m.title}: m4a missing", file=sys.stderr)
            continue
        j = find_tsrp_atom(m.m4a)
        if j is None:
            n_skipped += 1
            print(f"  - {m.title}: no tsrp atom found")
            continue
        text = transcript_to_text(j, with_timestamps=not args.no_timestamps)
        if args.print:
            print(f"\n=== {m.date_iso}  {fmt_dur(m.duration)}  {m.title} ===")
            print(text or "(empty)")
            n_extracted += 1
            continue
        # write to vault next to the .md sidecar
        year = m.date_dt.strftime("%Y")
        month = m.date_dt.strftime("%m")
        out_dir = Path(env["VAULT_PATH"]) / year / month
        out_dir.mkdir(parents=True, exist_ok=True)
        stem = f"{m.date_dt.strftime('%Y-%m-%d__%H%M')}__{slugify(m.title)}__{m.uuid[:8]}"
        out = out_dir / f"{stem}.apple-transcript.txt"
        locale = ((j.get("locale") or {}).get("identifier") or "")
        header = (f"# Apple auto-generated transcript\n"
                  f"# Source: {m.path}\n"
                  f"# UUID: {m.uuid}\n"
                  f"# Recorded: {m.date_iso}  ({fmt_dur(m.duration)})\n"
                  f"# Locale: {locale}\n"
                  f"# Title: {m.title}\n\n")
        out.write_text(header + (text or "") + "\n")
        n_extracted += 1
        print(f"  → {out.relative_to(Path(env['VAULT_PATH']).parent)}")
    print(f"\nExtracted: {n_extracted}  Skipped: {n_skipped}")
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


# ---------- audio metadata (ffprobe, cached) ----------

AUDIO_CACHE_FILE = ROOT / ".audio-meta.cache.json"


def load_audio_cache() -> dict:
    if AUDIO_CACHE_FILE.exists():
        try:
            return json.loads(AUDIO_CACHE_FILE.read_text())
        except Exception:
            return {}
    return {}


def save_audio_cache(cache: dict) -> None:
    AUDIO_CACHE_FILE.write_text(json.dumps(cache, indent=2, ensure_ascii=False))


def _humanize_device(encoder: str) -> str:
    if not encoder:
        return ""
    # examples observed:
    # "com.apple.VoiceMemos (iPad Version 15.6.1 (Build 24G90))"
    # "com.apple.VoiceMemos (iPhone Version 16.2 (Build 20C5058d))"
    # "com.apple.VoiceMemos (esaSoftability's MacBook Pro (null))"
    # "com.apple.VoiceMemos (iOS 13.0)"
    m = re.search(r"\(([^()]+(?:\([^()]+\))?)\)\s*$", encoder)
    inner = m.group(1) if m else encoder
    if "iPad" in inner:
        return "iPad"
    if "iPhone" in inner:
        return "iPhone"
    if "MacBook" in inner or "Mac" in inner:
        return "Mac"
    if "iOS" in inner:
        return f"iOS ({inner.split()[1] if ' ' in inner else inner})"
    return inner.split(" Version")[0].strip()


def probe_audio(path: Path) -> dict:
    """Run ffprobe; return {sr, channels, bit_rate, codec, encoder, device}."""
    try:
        proc = subprocess.run(
            ["ffprobe", "-v", "quiet", "-print_format", "json",
             "-show_format", "-show_streams", str(path)],
            capture_output=True, text=True, check=False, timeout=15,
        )
        if proc.returncode != 0:
            return {}
        d = json.loads(proc.stdout)
        st = (d.get("streams") or [{}])[0]
        fmt_tags = (d.get("format") or {}).get("tags") or {}
        encoder = fmt_tags.get("encoder", "")
        return {
            "sample_rate": int(st.get("sample_rate") or 0),
            "channels": int(st.get("channels") or 0),
            "bit_rate": int(st.get("bit_rate") or 0),
            "codec": st.get("codec_name") or "",
            "encoder": encoder,
            "device": _humanize_device(encoder),
        }
    except Exception:
        return {}


def get_audio_info(memo: Memo, cache: dict) -> dict:
    """Cached probe. Cache key = uuid + filename + size + mtime."""
    if memo.evicted or not memo.m4a_exists:
        return {}
    p = memo.m4a
    try:
        st = p.stat()
        ckey = f"{memo.uuid}:{p.name}:{st.st_size}:{int(st.st_mtime)}"
    except OSError:
        return {}
    if ckey in cache:
        return cache[ckey]
    info = probe_audio(p)
    cache[ckey] = info
    return info


# ---------- Apple-generated transcript extraction ----------

TSRP_MARKER = b"tsrp"


def find_tsrp_atom(path: Path) -> dict | None:
    """Scan the m4a tail for the `tsrp` Apple-Intelligence transcript atom.

    The atom is appended after the audio data as a JSON-serialized
    NSAttributedString containing per-word time-aligned runs.
    Returns the parsed JSON, or None if no transcript is embedded.
    """
    try:
        size = path.stat().st_size
    except OSError:
        return None
    # Transcripts cluster near the end. Read the last 256 KB; for very
    # long recordings the transcript can be larger, so fall back to a
    # full scan if the marker isn't in the tail.
    chunk = min(size, 262144)
    with open(path, "rb") as f:
        f.seek(size - chunk)
        tail = f.read()
        idx = tail.rfind(TSRP_MARKER)
        if idx < 0 and chunk < size:
            f.seek(0)
            data = f.read()
            idx = data.rfind(TSRP_MARKER)
            if idx < 0:
                return None
            after = data[idx + 4:]
        else:
            if idx < 0:
                return None
            after = tail[idx + 4:]
    after = after.rstrip(b"\x00")
    try:
        s = after.decode("utf-8", errors="ignore")
    except Exception:
        return None
    depth = 0
    end = 0
    for i, c in enumerate(s):
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                end = i + 1
                break
    if not end:
        return None
    try:
        return json.loads(s[:end])
    except Exception:
        return None


def transcript_to_text(j: dict, with_timestamps: bool = True) -> str:
    """Walk the parsed tsrp JSON and return readable text.

    `runs` alternates [text, attribute_index, text, attribute_index, ...].
    Each attribute_index points into `attributeTable`, where each entry
    is `{"timeRange": [start_sec, end_sec]}`.
    """
    attr = j.get("attributedString") or {}
    runs = attr.get("runs") or []
    table = attr.get("attributeTable") or []
    out_lines: list[str] = []
    cur_text: list[str] = []
    cur_start: float | None = None
    cur_end: float | None = None
    SEG_GAP = 2.0  # break to a new line after a 2 s gap

    def flush() -> None:
        if not cur_text:
            return
        text = "".join(cur_text).strip()
        if not text:
            cur_text.clear()
            return
        if with_timestamps and cur_start is not None:
            mm = int(cur_start // 60)
            ss = int(cur_start % 60)
            out_lines.append(f"[{mm:02d}:{ss:02d}] {text}")
        else:
            out_lines.append(text)
        cur_text.clear()

    for i in range(0, len(runs) - 1, 2):
        text = runs[i]
        attr_idx = runs[i + 1]
        if not isinstance(text, str):
            text = str(text)
        if not isinstance(attr_idx, int) or attr_idx >= len(table):
            cur_text.append(text)
            continue
        tr = table[attr_idx].get("timeRange") or []
        if len(tr) != 2:
            cur_text.append(text)
            continue
        seg_start, seg_end = tr
        if cur_start is None:
            cur_start = seg_start
            cur_end = seg_end
            cur_text.append(text)
        elif seg_start - (cur_end or seg_start) > SEG_GAP:
            flush()
            cur_start = seg_start
            cur_end = seg_end
            cur_text.append(text)
        else:
            cur_end = seg_end
            cur_text.append(text)
    flush()
    return "\n".join(out_lines)


SLUG_RE = re.compile(r"[^a-zA-Z0-9._-]+")


def slugify(s: str, max_len: int = 60) -> str:
    s = SLUG_RE.sub("-", s).strip("-")
    return (s[:max_len] or "untitled").lower()


def write_sidecar(env: dict, m: Memo, audio_target: Path | None,
                   audio_info: dict | None = None) -> Path:
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
        "apple_transcript": m.has_apple_transcript,
        "flags_raw": m.flags_raw,
        "audio_in_vault": audio_target.name if audio_target else "",
        "source_db": str(VM_DB),
    }
    if audio_info:
        fm.update({
            "sample_rate": audio_info.get("sample_rate", 0),
            "channels": audio_info.get("channels", 0),
            "bit_rate": audio_info.get("bit_rate", 0),
            "codec": audio_info.get("codec", ""),
            "encoder": audio_info.get("encoder", ""),
            "device": audio_info.get("device", ""),
        })
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
    if audio_info:
        kbps = (audio_info.get("bit_rate") or 0) // 1000
        lines.append(f"- **Audio**: {audio_info.get('codec','?')}  "
                     f"{audio_info.get('sample_rate',0)} Hz  "
                     f"{audio_info.get('channels',0)} ch  "
                     f"{kbps} kbps")
        if audio_info.get("device"):
            lines.append(f"- **Recorded on**: {audio_info['device']}")
    if m.has_apple_transcript:
        lines.append("- **Apple transcript**: ✅ embedded in m4a (extract via "
                     "`voice-memos-export transcripts --extract`)")
    if m.evicted:
        lines.append("- **Storage**: ☁️ cloud-only on this Mac")
    elif audio_target:
        lines.append(f"- **Audio file**: `{audio_target.name}` (next to this file)")
    lines.append("")
    md_path.write_text("\n".join(lines))
    return md_path


def cmd_xref(args) -> int:
    """Match each recording against ±window-minute Calendar events.

    Uses the Calendar SQLite store directly (read-only) so we don't need
    AppleScript or the calendar-exporter binary. Events with overlapping
    time ranges score the recording.
    """
    cal_db = Path(os.path.expanduser(
        "~/Library/Group Containers/group.com.apple.calendar/Calendar.sqlitedb"
    ))
    if not cal_db.exists():
        print(f"Calendar DB not found at {cal_db}", file=sys.stderr)
        return 1

    memos = filter_memos(load_memos(), args)
    if not memos:
        print("(no recordings to xref)", file=sys.stderr)
        return 0

    cal = open_immutable(cal_db)
    window_secs = args.window * 60

    out_rows: list[dict] = []
    for m in memos:
        if not m.date_dt:
            continue
        # Convert recording start (UTC) to Cocoa epoch for SQL comparison
        start_cocoa = (m.date_dt - COCOA_EPOCH).total_seconds()
        rows = cal.execute("""
            SELECT ci.summary, c.title, ci.start_date, ci.end_date,
                   COALESCE(l.title,'') AS location
            FROM CalendarItem ci
            LEFT JOIN Calendar c ON c.ROWID = ci.calendar_id
            LEFT JOIN Location l ON l.ROWID = ci.location_id
            WHERE ci.start_date BETWEEN ? AND ?
            ORDER BY ABS(ci.start_date - ?)
            LIMIT 5
        """, (start_cocoa - window_secs, start_cocoa + window_secs, start_cocoa)).fetchall()
        if rows:
            out_rows.append({
                "memo_uuid": m.uuid,
                "memo_title": m.title,
                "memo_date": m.date_iso,
                "events": [
                    {
                        "summary": r[0] or "(no title)",
                        "calendar": r[1] or "?",
                        "start": cocoa_to_dt(r[2]).strftime("%Y-%m-%d %H:%M") if r[2] else "",
                        "location": r[4],
                    }
                    for r in rows
                ],
            })
    cal.close()

    if args.json:
        print(json.dumps(out_rows, indent=2, ensure_ascii=False))
        return 0

    for row in out_rows:
        print(f"\n{row['memo_date']}  {row['memo_title']}")
        for e in row["events"]:
            loc = f"  @ {e['location']}" if e['location'] else ""
            print(f"   ↔  {e['start']}  [{e['calendar']}]  {e['summary']}{loc}")
    print(f"\n{len(out_rows)}/{len(memos)} recording(s) had Calendar matches "
          f"within ±{args.window} min")
    return 0


def cmd_export(args) -> int:
    env = load_env()
    memos = load_memos()
    if not args.all and not args.selector:
        print("Pass a selector, or --all to export everything.", file=sys.stderr)
        return 2
    targets = memos if args.all else [resolve_selector(memos, args.selector)]
    targets = filter_memos(targets, args)

    Path(env["VAULT_PATH"]).mkdir(parents=True, exist_ok=True)
    cache = load_audio_cache() if args.audio else {}
    n_audio = n_md = n_skipped = 0

    for m in targets:
        audio_target: Path | None = None
        if not m.evicted and m.m4a_exists:
            year = m.date_dt.strftime("%Y")
            month = m.date_dt.strftime("%m")
            out_dir = Path(env["VAULT_PATH"]) / year / month
            out_dir.mkdir(parents=True, exist_ok=True)
            stem = f"{m.date_dt.strftime('%Y-%m-%d__%H%M')}__{slugify(m.title)}__{m.uuid[:8]}"
            audio_target = out_dir / f"{stem}.m4a"
            if audio_target.exists() and not args.force:
                # leave existing symlink/copy in place; rewrite sidecar anyway
                n_skipped += 1
            else:
                if args.copy_audio:
                    shutil.copy2(m.m4a, audio_target)
                else:
                    if audio_target.exists() or audio_target.is_symlink():
                        audio_target.unlink()
                    audio_target.symlink_to(m.m4a)
                n_audio += 1
        ainfo = get_audio_info(m, cache) if args.audio else None
        write_sidecar(env, m, audio_target, ainfo)
        n_md += 1
    if args.audio:
        save_audio_cache(cache)

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
    sp.add_argument("--audio", action="store_true",
                    help="Include sample rate / channels / bit rate / codec / device (cached ffprobe)")
    sp.add_argument("--with-transcripts", action="store_true",
                    help="Only recordings with Apple-generated transcripts")
    sp.add_argument("--without-transcripts", action="store_true",
                    help="Only recordings without Apple transcripts")
    sp.add_argument("--json", action="store_true")
    sp.add_argument("--csv", action="store_true")
    sp.set_defaults(func=cmd_list)

    sp = sub.add_parser("transcripts",
                         help="List or extract Apple-generated auto-transcripts (no Whisper)")
    add_filter_args(sp)
    sp.add_argument("selector", nargs="?",
                    help="Single recording (omit to list all transcripted)")
    sp.add_argument("--list-only", action="store_true",
                    help="Just count and list — no extraction")
    sp.add_argument("--extract", action="store_true",
                    help="Write .apple-transcript.txt files")
    sp.add_argument("--all", action="store_true",
                    help="With --extract: process every transcripted recording")
    sp.add_argument("--print", action="store_true",
                    help="Print transcript to stdout instead of writing")
    sp.add_argument("--no-timestamps", action="store_true",
                    help="Plain text without [MM:SS] markers")
    sp.set_defaults(func=cmd_transcripts)

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

    sp = sub.add_parser("xref", help="Cross-reference recordings against Calendar events (±N min window)")
    add_filter_args(sp)
    sp.add_argument("--calendar", action="store_true", help="Match against Calendar events (default)")
    sp.add_argument("--window", type=int, default=30,
                    help="Time window in minutes around recording start (default 30)")
    sp.add_argument("--json", action="store_true")
    sp.set_defaults(func=cmd_xref)

    sp = sub.add_parser("export", help="Copy/symlink m4a + write .md sidecars to vault")
    add_filter_args(sp)
    sp.add_argument("selector", nargs="?", help="Single-recording selector (omit with --all)")
    sp.add_argument("--all", action="store_true")
    sp.add_argument("--copy-audio", action="store_true",
                    help="Copy m4a (default: symlink, saves disk)")
    sp.add_argument("--force", action="store_true",
                    help="Overwrite existing audio in vault")
    sp.add_argument("--audio", action="store_true",
                    help="Probe + bake sample rate / channels / device into sidecars")
    sp.add_argument("--json", action="store_true")
    sp.add_argument("--csv", action="store_true")
    sp.set_defaults(func=cmd_export)

    args = p.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
