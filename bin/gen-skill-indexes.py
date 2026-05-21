#!/usr/bin/env python3
"""Regenerate the four INDEX.md files for the Apple skill router.

Produces:
  scripts/workflows/INDEX.md  — 301 workflow scripts, one line each
  bin/INDEX.md                — 72 CLI tools, one line each
  dictionaries/INDEX.md       — 68 scripting dictionaries, one line each
  EXPORTERS.md                — 19 bulk exporters, one line each

Grep-friendly format: each entry is one line. `grep image INDEX.md` finds
image-related entries across all apps without scanning unrelated content.

Re-run after adding scripts. Wire into /workflow-catalog later.
"""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCRIPT_EXTS = {".applescript", ".scpt", ".sh", ".swift", ".py", ".js"}


def first_comment(path: Path) -> str:
    """Pull the first human description line from a script header.

    Skips any Triggers:/Category: lines so they don't get mistaken for the
    description.
    """
    try:
        with path.open(encoding="utf-8", errors="replace") as f:
            for line in f:
                s = line.strip()
                if not s:
                    continue
                # Skip shebang
                if s.startswith("#!"):
                    continue
                # AppleScript: -- text
                if s.startswith("--"):
                    body = s.lstrip("- ").strip()
                    if re.match(r"^(Triggers|Category|App|Usage|Generated)\s*:", body, re.I):
                        continue
                    return body
                # Shell/Python: # text  (but not section dividers like # ---)
                if s.startswith("#") and not re.match(r"^#+\s*[-=]{3,}", s):
                    body = s.lstrip("# ").strip()
                    if re.match(r"^(Triggers|Category|App|Usage|Generated)\s*:", body, re.I):
                        continue
                    return body
                # Swift/JS: // text
                if s.startswith("//"):
                    body = s.lstrip("/ ").strip()
                    if re.match(r"^(Triggers|Category|App|Usage|Generated)\s*:", body, re.I):
                        continue
                    return body
                # First non-comment line — give up
                return ""
    except Exception:
        return ""
    return ""


def extract_triggers(path: Path) -> str:
    """Return the comma-joined trigger list from a script's Triggers: header.

    Empty string if no Triggers: line is present.
    """
    try:
        with path.open(encoding="utf-8", errors="replace") as f:
            for i, line in enumerate(f):
                if i > 20:
                    break
                m = re.match(r"^\s*(?:--|#|//)\s*Triggers:\s*(.+)$", line.strip(), re.I)
                if m:
                    return m.group(1).strip()
    except Exception:
        pass
    return ""


def gen_workflows_index() -> str:
    """One line per workflow script, grouped by app."""
    wf_root = ROOT / "scripts" / "workflows"
    apps = sorted(d for d in wf_root.iterdir() if d.is_dir())
    total = 0
    lines: list[str] = []
    for app_dir in apps:
        scripts = sorted(
            p for p in app_dir.iterdir()
            if p.is_file() and p.suffix in SCRIPT_EXTS
        )
        if not scripts:
            continue
        lines.append(f"\n## {app_dir.name} ({len(scripts)})\n")
        for s in scripts:
            desc = first_comment(s) or "(no description)"
            triggers = extract_triggers(s)
            rel = s.relative_to(ROOT)
            trig_part = f" — triggers: {triggers}" if triggers else ""
            lines.append(f"`{s.stem}` — {desc}{trig_part} — `{rel}`")
            total += 1

    header = [
        f"# Workflows Index — {total} scripts across {len(apps)} apps",
        "",
        "**Grep this file to find the right script without scanning every app.**",
        "Grep by trigger keyword (`grep airdrop`), by app name (`^## finder`), or by description token.",
        "",
        "Format: `script-name` — description — triggers: a, b, c — `path`",
        "Regenerate: `python3 bin/gen-skill-indexes.py`",
        "Re-seed trigger headers after adding scripts: `python3 bin/seed-script-triggers.py`",
    ]
    return "\n".join(header) + "\n" + "\n".join(lines) + "\n"


def gen_bin_index() -> str:
    """One line per CLI tool in bin/."""
    bin_dir = ROOT / "bin"
    tools = sorted(
        p for p in bin_dir.iterdir()
        if p.is_file() and (p.stat().st_mode & 0o111)
    )
    lines: list[str] = []
    for t in tools:
        desc = first_comment(t)
        # bin scripts often have `# toolname — description` on line 2; strip name
        m = re.match(rf"^{re.escape(t.name)}\s*[—\-:]\s*(.+)$", desc)
        if m:
            desc = m.group(1).strip()
        desc = desc or "(no description)"
        rel = t.relative_to(ROOT)
        lines.append(f"`{t.name}` — {desc} — `{rel}`")

    header = [
        f"# CLI Tools Index — {len(tools)} tools in bin/",
        "",
        "**Grep this file to find the right tool. Each is callable from PATH if bin/ is on it.**",
        "",
        "Format: `tool-name` — description — `path`",
        "Regenerate: `python3 bin/gen-skill-indexes.py`",
        "",
    ]
    return "\n".join(header) + "\n".join(lines) + "\n"


def gen_dictionaries_index() -> str:
    """One line per probed app."""
    dict_root = ROOT / "dictionaries"
    apps = sorted(d for d in dict_root.iterdir() if d.is_dir())
    lines: list[str] = []
    for app_dir in apps:
        name = app_dir.name
        files = {p.name for p in app_dir.iterdir() if p.is_file()}
        # Detect what's present
        flags = []
        if f"{name}.md" in files:
            flags.append("ref")
        if f"{name}-examples.md" in files:
            flags.append("ex")
        if f"{name}.sdef.xml" in files:
            flags.append("sdef")
        if f"{name}.jxa.md" in files:
            flags.append("jxa")
        if f"{name}-probe.yaml" in files or f"{name}-probe.md" in files:
            flags.append("probe")
        flag_str = ",".join(flags) if flags else "—"

        # Try to pull header line from main .md
        desc = ""
        md = app_dir / f"{name}.md"
        if md.exists():
            try:
                with md.open(encoding="utf-8", errors="replace") as f:
                    for line in f:
                        if line.startswith("> ") and "extracted" in line.lower():
                            desc = line[2:].strip()
                            break
                        if line.startswith("> ") and any(c.isdigit() for c in line):
                            desc = line[2:].strip()
                            break
            except Exception:
                pass

        rel = app_dir.relative_to(ROOT)
        lines.append(f"`{name}` — [{flag_str}] — {desc or '(no summary)'} — `{rel}/`")

    header = [
        f"# Scripting Dictionaries Index — {len(apps)} apps probed",
        "",
        "**Grep this file to find which apps have sdef coverage.**",
        "",
        "Flags: `ref`=<app>.md, `ex`=examples.md, `sdef`=sdef.xml, `jxa`=jxa.md, `probe`=probe data",
        "",
        "Format: `app-name` — [flags] — summary — `path/`",
        "Regenerate: `python3 bin/gen-skill-indexes.py`",
        "",
    ]
    return "\n".join(header) + "\n".join(lines) + "\n"


def gen_exporters_index() -> str:
    """One line per *-exporter/ directory at repo root."""
    exporters = sorted(
        d for d in ROOT.iterdir()
        if d.is_dir() and d.name.endswith("-exporter")
    )
    lines: list[str] = []
    for ex in exporters:
        name = ex.name
        readme = ex / "README.md"
        desc = ""
        if readme.exists():
            try:
                with readme.open(encoding="utf-8", errors="replace") as f:
                    for line in f:
                        s = line.strip()
                        if not s or s.startswith("#"):
                            continue
                        if s.startswith(">") or s.startswith("!"):
                            continue
                        desc = s
                        break
            except Exception:
                pass
        rel = ex.relative_to(ROOT)
        lines.append(f"`{name}` — {desc or '(no README summary)'} — `{rel}/`")

    header = [
        f"# Bulk Exporters Index — {len(exporters)} exporters",
        "",
        "**The agent should ONLY read a specific exporter's directory when the user's question is about that data source.**",
        "An AppleScript question never needs to touch any exporter. A 'where are my safari bookmarks' question reads ONLY `safari-exporter/`.",
        "",
        "Format: `exporter-name` — purpose — `path/`",
        "Regenerate: `python3 bin/gen-skill-indexes.py`",
        "",
    ]
    return "\n".join(header) + "\n".join(lines) + "\n"


def write(path: Path, text: str) -> None:
    path.write_text(text, encoding="utf-8")
    print(f"wrote {path.relative_to(ROOT)} ({len(text.splitlines())} lines)")


def main() -> None:
    write(ROOT / "scripts" / "workflows" / "INDEX.md", gen_workflows_index())
    write(ROOT / "bin" / "INDEX.md", gen_bin_index())
    write(ROOT / "dictionaries" / "INDEX.md", gen_dictionaries_index())
    write(ROOT / "wiki" / "compiled" / "EXPORTERS.md", gen_exporters_index())


if __name__ == "__main__":
    main()
