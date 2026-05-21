---
description: Health-check the Apple wiki. Orphans, oversized pages, broken cross-refs, regressions.
---

Lint the wiki. Reports orphans (no inbound link), oversized pages (>250 lines), broken markdown cross-refs, "From skill.md" regressions, pages missing H1, stale memory-style frontmatter.

```bash
python3 /Users/esaruoho/work/apple/bin/wiki-lint.py $ARGUMENTS
```

Flags: `--orphans` (only orphan check), `--strict` (exit 1 if any finding).
