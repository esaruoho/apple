#!/usr/bin/env python3
"""Health-check the Apple skill wiki.

Karpathy's lint pass: orphans, oversized pages, broken cross-refs, regressions.

Checks:
  1. ORPHAN — wiki page with zero inbound links from any other wiki page or
     from skill.md / README.md / CLAUDE.md / MEMORY.md.
  2. OVERSIZED — pages over 250 lines (Karpathy soft cap; further split candidate).
  3. BROKEN-REF — markdown link to a wiki/ path that doesn't exist on disk.
  4. REGRESSION — `## From skill.md` markers (left over from split, should never recur).
  5. NO-H1 — page without a top-level H1 (means the index generator falls back to filename).
  6. STALE-FRONTMATTER — memory-style `metadata.type` from promoted memory files (cosmetic).

Usage:
    python3 bin/wiki-lint.py            # report all
    python3 bin/wiki-lint.py --orphans  # only orphan warnings
    python3 bin/wiki-lint.py --strict   # exit 1 if any finding (for CI)
"""
import re, sys, pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
WIKI = ROOT / "wiki"
MEM = pathlib.Path("/Users/esaruoho/.claude/projects/-Users-esaruoho-work-apple/memory/MEMORY.md")

SOFT_CAP_LINES = 250
EXTRA_SEARCH = [ROOT / "skill.md", ROOT / "README.md", ROOT / "CLAUDE.md", MEM,
                ROOT / "wiki" / "INDEX.md", ROOT / "wiki" / "README.md",
                ROOT / "wiki" / "log.md"]


def all_wiki_pages() -> list[pathlib.Path]:
    return [p for p in sorted(WIKI.rglob("*.md")) if p.name not in {"INDEX.md", "log.md"}]


def all_searchable_text() -> str:
    chunks = []
    for p in all_wiki_pages() + EXTRA_SEARCH:
        if p.exists():
            chunks.append(p.read_text())
    return "\n".join(chunks)


def main():
    strict = "--strict" in sys.argv
    only_orphans = "--orphans" in sys.argv

    pages = all_wiki_pages()
    haystack = all_searchable_text()
    findings: list[tuple[str, str]] = []

    for page in pages:
        rel = page.relative_to(ROOT)
        text = page.read_text()
        lines = text.splitlines()

        # ORPHAN: relative path or basename mentioned anywhere?
        rel_str = str(rel)               # "wiki/entities/sal-soghoian.md"
        wiki_rel = str(page.relative_to(WIKI))  # "entities/sal-soghoian.md"
        basename = page.name              # "sal-soghoian.md"
        # Count mentions outside the file itself
        haystack_minus_self = haystack.replace(text, "", 1)
        if (rel_str not in haystack_minus_self
                and wiki_rel not in haystack_minus_self
                and basename not in haystack_minus_self):
            findings.append(("ORPHAN", str(rel)))

        if only_orphans:
            continue

        # OVERSIZED — skip auto-generated content
        if len(lines) > SOFT_CAP_LINES and "compiled/" not in str(rel):
            findings.append(("OVERSIZED", f"{rel} ({len(lines)} lines)"))

        # REGRESSION
        if "## From skill.md" in text:
            findings.append(("REGRESSION", f"{rel} has ## From skill.md marker"))

        # NO-H1 (after optional frontmatter)
        body = text
        if body.startswith("---\n"):
            end = body.find("\n---\n", 4)
            if end != -1:
                body = body[end + 5:]
        if not re.match(r"\s*# ", body):
            findings.append(("NO-H1", str(rel)))

        # STALE-FRONTMATTER (memory-style metadata: block)
        if re.search(r"^\s*type:\s*(project|reference|feedback|user)\b", text, re.M):
            findings.append(("STALE-FM", f"{rel} has memory-type frontmatter"))

        # BROKEN-REF: links to wiki/<path>.md that don't exist
        for m in re.finditer(r"\]\(([^)]+\.md)\)", text):
            target = m.group(1).split("#")[0]
            if target.startswith("http"):
                continue
            # Resolve relative to the page's directory
            try:
                resolved = (page.parent / target).resolve()
            except Exception:
                continue
            if not resolved.exists():
                # Ignore links to non-wiki paths (analysis/, sources/, etc.)
                if "wiki/" in str(resolved) or resolved.is_relative_to(WIKI) if hasattr(resolved, "is_relative_to") else False:
                    findings.append(("BROKEN-REF", f"{rel} → {target}"))

    # Summary
    by_kind: dict[str, list[str]] = {}
    for kind, msg in findings:
        by_kind.setdefault(kind, []).append(msg)

    order = ["REGRESSION", "BROKEN-REF", "ORPHAN", "OVERSIZED", "NO-H1", "STALE-FM"]
    for kind in order:
        if kind not in by_kind:
            continue
        items = by_kind[kind]
        print(f"\n[{kind}]  {len(items)} finding(s):")
        for m in items:
            print(f"  - {m}")

    total = sum(len(v) for v in by_kind.values())
    print(f"\n{total} finding(s) across {len(pages)} wiki pages.")
    if strict and total > 0:
        sys.exit(1)


if __name__ == "__main__":
    main()
