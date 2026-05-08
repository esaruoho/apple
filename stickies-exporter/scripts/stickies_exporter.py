#!/usr/bin/env python3
"""stickies-exporter — read-only catalog + markdown vault for Apple Stickies.

Stickies has no AppleScript dictionary, no App Intents, no URL scheme
(macOS 15.6.1 — "Tier 5: Nearly Dark"). Notes live as .rtfd bundles
under the Stickies app container; we read them with macOS-native
`textutil`. No third-party dependencies.

Subcommands (Phase 1, all read-only):
  list       UUID, title, char count, modified, link/text colors
  cat        Print one sticky's text (selector grammar)
  export     Write each sticky to the vault as markdown + frontmatter
  status     Counts overview

Selector: UUID prefix / title substring / #N / latest
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_ENV = ROOT / ".env"

STICKIES_DIR = Path(os.path.expanduser(
    "~/Library/Containers/com.apple.Stickies/Data/Library/Stickies"
))


def load_env() -> dict[str, str]:
    env: dict[str, str] = {}
    if DEFAULT_ENV.exists():
        for line in DEFAULT_ENV.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            env[k.strip()] = os.path.expanduser(v.strip().strip('"').strip("'"))
    env.setdefault("VAULT_PATH", os.path.expanduser("~/work/apple/exported/stickies"))
    env["VAULT_PATH"] = os.path.expanduser(env["VAULT_PATH"])
    return env


# =====================================================================
# Read .rtfd bundles via textutil
# =====================================================================

def textutil_to_text(rtfd: Path) -> str:
    proc = subprocess.run(
        ["textutil", "-convert", "txt", "-encoding", "UTF-8", "-stdout", str(rtfd)],
        capture_output=True, text=True, check=False,
    )
    return proc.stdout if proc.returncode == 0 else ""


def textutil_to_html(rtfd: Path) -> str:
    proc = subprocess.run(
        ["textutil", "-convert", "html", "-encoding", "UTF-8", "-stdout", str(rtfd)],
        capture_output=True, text=True, check=False,
    )
    return proc.stdout if proc.returncode == 0 else ""


def read_rtf(rtfd: Path) -> str:
    inner = rtfd / "TXT.rtf"
    if inner.exists():
        try:
            return inner.read_text(encoding="utf-8", errors="replace")
        except Exception:
            return ""
    return ""


# Pull color table entries — one rgb per slot. First slot is always "default".
COLORTBL_RE = re.compile(r"\\colortbl;([^}]*)}", re.S)
RGB_RE = re.compile(r"\\red(\d+)\\green(\d+)\\blue(\d+)")


def parse_colors(rtf: str) -> list[str]:
    m = COLORTBL_RE.search(rtf)
    if not m:
        return []
    out: list[str] = []
    for r, g, b in RGB_RE.findall(m.group(1)):
        out.append(f"#{int(r):02X}{int(g):02X}{int(b):02X}")
    return out


# =====================================================================
# Data model
# =====================================================================

@dataclass
class Sticky:
    uuid: str
    rtfd_path: Path
    text: str
    modified_iso: str
    char_count: int
    colors: list[str]      # parsed from \colortbl

    @property
    def title(self) -> str:
        for line in (self.text or "").splitlines():
            line = line.strip()
            if line:
                return line[:120]
        return "(empty)"

    @property
    def link_color(self) -> str:
        # Slot 2 in Stickies' colortbl is typically the link color.
        return self.colors[1] if len(self.colors) > 1 else ""

    @property
    def text_color(self) -> str:
        return self.colors[2] if len(self.colors) > 2 else ""


def load_stickies() -> list[Sticky]:
    if not STICKIES_DIR.exists():
        sys.exit(f"Stickies directory not found at {STICKIES_DIR}.\n"
                 "Grant Full Disk Access to Terminal in System Settings → Privacy & Security.")
    out: list[Sticky] = []
    for rtfd in sorted(STICKIES_DIR.glob("*.rtfd")):
        uuid = rtfd.stem
        text = textutil_to_text(rtfd)
        rtf = read_rtf(rtfd)
        colors = parse_colors(rtf)
        try:
            mtime = datetime.fromtimestamp(rtfd.stat().st_mtime, tz=timezone.utc)
            modified_iso = mtime.strftime("%Y-%m-%d %H:%M:%S")
        except OSError:
            modified_iso = ""
        out.append(Sticky(
            uuid=uuid, rtfd_path=rtfd,
            text=text or "",
            modified_iso=modified_iso,
            char_count=len(text or ""),
            colors=colors,
        ))
    out.sort(key=lambda s: s.modified_iso, reverse=True)
    return out


# =====================================================================
# Selectors + slug
# =====================================================================

SLUG_RE = re.compile(r"[^a-zA-Z0-9._-]+")


def slugify(s: str, max_len: int = 50) -> str:
    s = SLUG_RE.sub("-", (s or "").strip()).strip("-")
    return (s[:max_len] or "untitled").lower()


def resolve_selector(stickies: list[Sticky], sel: str) -> Sticky:
    if sel == "latest":
        return stickies[0]
    if sel.startswith("#"):
        return stickies[int(sel[1:])]
    if re.fullmatch(r"\d{4}-\d{2}-\d{2}", sel):
        for s in stickies:
            if s.modified_iso.startswith(sel):
                return s
        raise SystemExit(f"No sticky modified on {sel}")
    if re.fullmatch(r"[0-9A-Fa-f-]{4,}", sel):
        sel_u = sel.upper()
        hits = [s for s in stickies if s.uuid.upper().startswith(sel_u)]
        if len(hits) == 1:
            return hits[0]
        if len(hits) > 1:
            raise SystemExit(f"UUID prefix {sel!r} matches {len(hits)} stickies — narrow it.")
    sub = sel.lower()
    hits = [s for s in stickies if sub in (s.title or "").lower()
            or sub in (s.text or "").lower()]
    if len(hits) == 1:
        return hits[0]
    if len(hits) > 1:
        lines = "\n".join(f"  #{i:<3} {s.modified_iso[:10]}  {s.uuid[:8]}  {s.title}"
                          for i, s in enumerate(hits[:10]))
        raise SystemExit(f"Selector {sel!r} matched {len(hits)} stickies. Top results:\n{lines}\n"
                         "Narrow with UUID prefix or '#N' index.")
    raise SystemExit(f"No sticky matches selector {sel!r}.")


# =====================================================================
# Subcommands
# =====================================================================

def cmd_status(args) -> int:
    env = load_env()
    stickies = load_stickies()
    total_chars = sum(s.char_count for s in stickies)
    print("Stickies overview")
    print(f"  Source dir:    {STICKIES_DIR}")
    print(f"  Vault target:  {env['VAULT_PATH']}")
    print(f"  Stickies:      {len(stickies)}")
    print(f"  Total chars:   {total_chars}")
    print(f"  Total bytes on disk: "
          f"{sum(int(p.stat().st_size) for p in STICKIES_DIR.rglob('*') if p.is_file())}")
    if stickies:
        print(f"  Most recent:   {stickies[0].modified_iso} — {stickies[0].title}")
        print(f"  Oldest:        {stickies[-1].modified_iso} — {stickies[-1].title}")
    return 0


def cmd_list(args) -> int:
    stickies = load_stickies()
    if args.match:
        pat = re.compile(args.match, re.I)
        stickies = [s for s in stickies
                    if pat.search(s.title or "") or pat.search(s.text or "")]
    if args.since:
        stickies = [s for s in stickies if s.modified_iso >= args.since]
    if args.json:
        out = [{
            "uuid": s.uuid, "title": s.title, "char_count": s.char_count,
            "modified": s.modified_iso, "rtfd_path": str(s.rtfd_path),
            "colors": s.colors, "link_color": s.link_color,
            "text_color": s.text_color,
        } for s in stickies]
        print(json.dumps(out, indent=2, ensure_ascii=False))
        return 0
    for i, s in enumerate(stickies):
        print(f"  {i:>3}  {s.modified_iso[:16]}  {s.uuid[:8]}  "
              f"{s.char_count:>5}c  {s.title}")
    print(f"\n{len(stickies)} sticky/stickies")
    return 0


def cmd_cat(args) -> int:
    stickies = load_stickies()
    s = resolve_selector(stickies, args.selector)
    if args.rtf:
        print(read_rtf(s.rtfd_path), end="")
        return 0
    if args.html:
        print(textutil_to_html(s.rtfd_path), end="")
        return 0
    if args.with_meta:
        print(f"# {s.title}")
        print(f"# UUID: {s.uuid}")
        print(f"# Modified: {s.modified_iso}")
        print(f"# Path: {s.rtfd_path}")
        if s.colors:
            print(f"# Colors: {s.colors}")
        print()
    print(s.text, end="")
    return 0


def write_md(env: dict, s: Sticky, include_rtf: bool) -> Path:
    out_dir = Path(env["VAULT_PATH"])
    out_dir.mkdir(parents=True, exist_ok=True)
    date_prefix = s.modified_iso[:10] or "undated"
    stem = f"{date_prefix}__{slugify(s.title)}__{s.uuid[:8]}"
    md_path = out_dir / f"{stem}.md"
    fm_lines = ["---",
                f'uuid: "{s.uuid}"',
                f'title: "{s.title.replace(chr(34), chr(92)+chr(34))}"',
                f'modified: "{s.modified_iso}"',
                f"char_count: {s.char_count}",
                f"colors: {json.dumps(s.colors)}"]
    if s.link_color:
        fm_lines.append(f'link_color: "{s.link_color}"')
    if s.text_color:
        fm_lines.append(f'text_color: "{s.text_color}"')
    fm_lines.append(f'rtfd_source: "{s.rtfd_path}"')
    fm_lines.append("---")
    fm_lines.append("")
    fm_lines.append(f"# {s.title}")
    fm_lines.append("")
    body = (s.text or "").rstrip()
    if body and body.split("\n", 1)[0].strip() == s.title:
        # avoid duplicating the title line
        body = body.split("\n", 1)[1] if "\n" in body else ""
    if body:
        fm_lines.append(body)
        fm_lines.append("")
    md_path.write_text("\n".join(fm_lines))

    if include_rtf:
        # Symlink the .rtfd next to the .md so Obsidian users can still
        # double-click to open the live version in TextEdit.
        link_path = out_dir / f"{stem}.rtfd"
        if link_path.exists() or link_path.is_symlink():
            link_path.unlink()
        link_path.symlink_to(s.rtfd_path)
    return md_path


def cmd_export(args) -> int:
    env = load_env()
    stickies = load_stickies()
    if args.match:
        pat = re.compile(args.match, re.I)
        stickies = [s for s in stickies
                    if pat.search(s.title or "") or pat.search(s.text or "")]
    Path(env["VAULT_PATH"]).mkdir(parents=True, exist_ok=True)
    n = 0
    for s in stickies:
        write_md(env, s, include_rtf=args.include_rtf)
        n += 1
    print(f"Wrote {n} sticky/stickies to {env['VAULT_PATH']}")
    if args.include_rtf:
        print("(RTFD bundles symlinked alongside the .md files)")
    return 0


# =====================================================================
# argparse
# =====================================================================

def main() -> int:
    p = argparse.ArgumentParser(prog="stickies-exporter")
    sub = p.add_subparsers(dest="cmd", required=True)

    sp = sub.add_parser("status", help="Counts overview")
    sp.set_defaults(func=cmd_status)

    sp = sub.add_parser("list", help="List all stickies")
    sp.add_argument("--match", help="Regex over title or body (case-insensitive)")
    sp.add_argument("--since", help="Modified on/after YYYY-MM-DD")
    sp.add_argument("--json", action="store_true")
    sp.set_defaults(func=cmd_list)

    sp = sub.add_parser("cat", help="Print one sticky's text")
    sp.add_argument("selector", help="UUID prefix / title substring / #N / latest")
    sp.add_argument("--rtf", action="store_true", help="Print raw RTF instead of plain text")
    sp.add_argument("--html", action="store_true", help="Print HTML conversion")
    sp.add_argument("--with-meta", action="store_true",
                    help="Prepend metadata header lines")
    sp.set_defaults(func=cmd_cat)

    sp = sub.add_parser("export", help="Write each sticky to vault as markdown + frontmatter")
    sp.add_argument("--match", help="Regex over title or body")
    sp.add_argument("--include-rtf", action="store_true",
                    help="Symlink each .rtfd next to its .md (Obsidian-friendly)")
    sp.set_defaults(func=cmd_export)

    args = p.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
