# Sal Script Library

Normalized runnable scripts extracted from Sal-authored sources live here.

Current first-pass extraction status:

- `597` inline AppleScript examples extracted from archived HTML
- `380` examples from `macosxautomation.com`
- `215` examples from `iworkautomation.com`
- `2` examples from `configautomation.com`
- `0` extracted examples so far from `photosautomation.com` and `dictationcommands.com`

Goals:
- Keep source-derived scripts grouped by site
- Preserve provenance for every extracted script
- Separate verbatim source captures from cleaned runnable copies
- Distinguish inline script extraction from downloaded bundles that still need recovery

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

Current extraction method:

- decode `applescript://` Script Editor URLs embedded in archived HTML
- normalize the decoded code into `.applescript` files
- write per-script provenance sidecars as `.yaml`
- regenerate `indexes/sal-scripts.yaml` from the extracted corpus

Current limitations:

- downloadable ZIP installers and script bundles are not yet recovered here unless they appeared inline as script URLs
- some preserved sites are partial Wayback slices, so absence here does not prove absence on the original site
