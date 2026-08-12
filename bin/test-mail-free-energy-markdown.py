#!/usr/bin/env python3
"""Regression check for mail-free-energy-analysis Markdown email rendering."""
from pathlib import Path

ns = {"__name__": "mailfe_render_probe"}
exec(compile(Path("bin/mail-free-energy-analysis").read_text(), "bin/mail-free-energy-analysis", "exec"), ns)

sample = """## Heading

| Claimed Phenomenon | Implied Reservoir |
|---|---|
| **Resonance** | *ambient field* |

1. First
- Bullet with `code`
"""

html = ns["md_to_html"](sample)
checks = {
    "table": "<table" in html and "<th" in html and "<td" in html,
    "strong": "<strong>Resonance</strong>" in html,
    "em": "<em>ambient field</em>" in html,
    "ordered": "<ol>" in html and "<li>First</li>" in html,
    "code": "<code>code</code>" in html,
}
for name, ok in checks.items():
    print(f"{name}: {'ok' if ok else 'FAIL'}")
if not all(checks.values()):
    raise SystemExit(1)
