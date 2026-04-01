# Sal Script Library

Normalized runnable scripts extracted from Sal-authored sources live here.

Goals:
- Keep source-derived scripts grouped by site
- Preserve provenance for every extracted script
- Separate verbatim source captures from cleaned runnable copies

Per-site layout:

```text
scripts/sal/<site-slug>/
  <category>/
    script-name.applescript
    script-name.yaml
```

Suggested sidecar metadata fields:
- `source_url`
- `source_title`
- `source_domain`
- `retrieved_at`
- `apps`
- `automation_layers`
- `concepts`
- `original_format`
- `normalization_notes`
