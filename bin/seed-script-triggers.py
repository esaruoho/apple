#!/usr/bin/env python3
"""Seed `-- Triggers:` and `-- Category:` header lines into every workflow script.

Auto-seeded from filename tokens + first-line description + app name. Hand-correct
afterwards by editing the headers directly. Re-running this script is safe — it
skips any file that already has a Triggers: line.

Output format inserted into .applescript files:

    -- <description>           (existing)
    -- App: <name>             (existing)
    -- Triggers: a, b, c       (new — inserted)
    -- Category: <name>        (new — inserted)
    -- Usage: ...              (existing)

For .sh files, uses # as the comment marker instead of --.

Run after adding new workflow scripts. The gen-skill-indexes.py generator picks
up these triggers and surfaces them in scripts/workflows/INDEX.md.
"""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
WORKFLOWS = ROOT / "scripts" / "workflows"

# Words that don't help as triggers — too generic or grammatical.
STOPWORDS = {
    "a", "an", "and", "or", "the", "of", "in", "on", "at", "to", "for", "from",
    "with", "by", "as", "is", "it", "this", "that", "into", "via", "then",
    "but", "if", "when", "all", "any", "your", "my", "current", "be", "are",
    "was", "were", "has", "have", "had", "do", "does", "did", "use", "using",
    "via", "use", "etc", "no", "not", "yes", "its", "their", "them",
}
# Common Apple-domain verbs that ARE useful keywords — keep these even though short.
KEEP_SHORT = {"app", "use", "run", "set", "get", "ax", "mac", "tab", "pdf", "tv",
              "jxa", "url", "wav", "mp3", "css", "ipa", "rss"}


def tokenize(text: str) -> list[str]:
    """Lowercase + split on non-alphanumeric. Drop stopwords and tiny tokens."""
    tokens = re.split(r"[^a-zA-Z0-9]+", text.lower())
    out = []
    for t in tokens:
        if not t:
            continue
        if t in STOPWORDS:
            continue
        if len(t) < 3 and t not in KEEP_SHORT:
            continue
        out.append(t)
    return out


def seed_triggers_for(path: Path) -> tuple[list[str], str]:
    """Derive (triggers, category) for a script from filename + first description."""
    app_dir = path.parent.name  # e.g. "image-events"
    name_tokens = tokenize(path.stem)  # filename minus extension

    # Drop the redundant app-prefix tokens (e.g. "finder" from finder-close-windows)
    app_prefix_tokens = set(tokenize(app_dir))
    name_tokens = [t for t in name_tokens if t not in app_prefix_tokens]

    # First-line description
    desc = ""
    try:
        with path.open(encoding="utf-8", errors="replace") as f:
            for line in f:
                s = line.strip()
                if not s or s.startswith("#!"):
                    continue
                if s.startswith("--"):
                    desc = s.lstrip("- ").strip()
                    break
                if s.startswith("#"):
                    desc = s.lstrip("# ").strip()
                    break
                break  # first non-comment line — stop looking
    except Exception:
        pass
    desc_tokens = tokenize(desc)

    # Combine: name tokens first (highest signal), then description tokens.
    seen = set()
    merged = []
    for t in name_tokens + desc_tokens:
        if t in seen:
            continue
        seen.add(t)
        merged.append(t)

    # Limit to a reasonable cap — too many tokens defeats the purpose.
    triggers = merged[:8]

    # Category from app directory name → Title Case With Spaces
    category = " ".join(w.capitalize() for w in app_dir.split("-"))

    return triggers, category


def comment_marker(path: Path) -> str | None:
    if path.suffix == ".applescript":
        return "--"
    if path.suffix == ".sh":
        return "#"
    return None


def already_has_triggers(text: str, marker: str) -> bool:
    """Idempotency check. Look at first 12 lines for an existing Triggers: line."""
    head = "\n".join(text.splitlines()[:12])
    pattern = rf"^\s*{re.escape(marker)}\s*Triggers:"
    return bool(re.search(pattern, head, re.MULTILINE))


def insert_after_app_line(text: str, marker: str, triggers: list[str], category: str) -> tuple[str, str]:
    """Insert two header lines after the first `-- App:` / `# App:` line. If no
    App line exists, insert after the first description comment.

    Returns (new_text, reason) where reason describes where insertion happened.
    """
    lines = text.splitlines(keepends=True)
    trig_line = f"{marker} Triggers: {', '.join(triggers)}\n" if triggers else f"{marker} Triggers: (none — hand-correct)\n"
    cat_line = f"{marker} Category: {category}\n"

    # Look for `-- App:` line first
    app_pat = re.compile(rf"^\s*{re.escape(marker)}\s*App:", re.IGNORECASE)
    for i, line in enumerate(lines):
        if app_pat.match(line):
            lines.insert(i + 1, trig_line)
            lines.insert(i + 2, cat_line)
            return "".join(lines), "after-App"

    # No App line — insert after first comment line
    comment_pat = re.compile(rf"^\s*{re.escape(marker)}")
    for i, line in enumerate(lines):
        if line.startswith("#!"):  # skip shebang
            continue
        if comment_pat.match(line):
            lines.insert(i + 1, trig_line)
            lines.insert(i + 2, cat_line)
            return "".join(lines), "after-first-comment"

    # No comments at all — prepend
    new_text = trig_line + cat_line + text
    return new_text, "prepended"


def process(path: Path) -> str:
    """Returns one of: 'skip-binary', 'skip-existing', 'seeded:<reason>', 'error:<msg>'."""
    marker = comment_marker(path)
    if marker is None:
        return "skip-binary"
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except Exception as e:
        return f"error:read:{e}"

    if already_has_triggers(text, marker):
        return "skip-existing"

    triggers, category = seed_triggers_for(path)
    new_text, reason = insert_after_app_line(text, marker, triggers, category)

    try:
        path.write_text(new_text, encoding="utf-8")
    except Exception as e:
        return f"error:write:{e}"
    return f"seeded:{reason}"


def main() -> None:
    targets: list[Path] = []
    for p in sorted(WORKFLOWS.rglob("*")):
        if not p.is_file():
            continue
        if p.suffix in (".applescript", ".sh"):
            targets.append(p)

    counts: dict[str, int] = {}
    samples: dict[str, list[str]] = {}
    for p in targets:
        result = process(p)
        counts[result] = counts.get(result, 0) + 1
        if result.startswith("seeded:") and len(samples.get("seeded", [])) < 3:
            samples.setdefault("seeded", []).append(str(p.relative_to(ROOT)))

    print(f"Processed {len(targets)} files")
    for k, v in sorted(counts.items()):
        print(f"  {k}: {v}")
    if "seeded" in samples:
        print("Sample seeded files (verify these by hand):")
        for s in samples["seeded"]:
            print(f"  {s}")


if __name__ == "__main__":
    main()
