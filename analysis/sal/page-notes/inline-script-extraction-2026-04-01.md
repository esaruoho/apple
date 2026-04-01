# Inline Script Extraction 2026-04-01

This note documents the first successful extraction pass of runnable AppleScript examples from the preserved Sal site corpus.

## What Was Extracted

- `597` inline AppleScript examples were decoded from `applescript://com.apple.scripteditor` links embedded in archived HTML.
- These examples were normalized into [`scripts/sal`](/Users/esaruoho/work/apple/scripts/sal).
- The extracted corpus was indexed in [`sal-scripts.yaml`](/Users/esaruoho/work/apple/indexes/sal-scripts.yaml).

Per-site totals:

- `macosxautomation.com`: `380`
- `iworkautomation.com`: `215`
- `configautomation.com`: `2`
- `photosautomation.com`: `0`
- `dictationcommands.com`: `0`

## What This Means

The archive now preserves more than lesson pages and screenshots. It also preserves runnable source-derived AppleScript examples at scale.

The strongest preserved script corpus currently comes from:

- `macosxautomation.com`
- `iworkautomation.com`

Those two sites appear to have relied heavily on inline Script Editor links, which made extraction feasible even when separate download bundles were not captured.

## What Was Not Recovered In This Pass

- ZIP installers
- packaged workflow bundles
- standalone `.scpt` downloads
- downloadable example archives linked from preserved pages but not present in the mirror

This means the extracted corpus is substantial, but it is not yet the full downloadable script library Sal originally published.

## Method

Extractor:

- [`sal-extract-inline-applescript.py`](/Users/esaruoho/work/apple/bin/sal-extract-inline-applescript.py)

Method summary:

1. scan archived HTML for `applescript://` Script Editor URLs
2. decode URL-encoded script content
3. normalize line endings to LF
4. write `.applescript` files under `scripts/sal/<site>/...`
5. write sidecar provenance YAML for each extracted script
6. regenerate the machine-readable script index

## Validation Notes

- the resulting index resolves to `597` records
- extracted sample scripts were spot-checked from `iworkautomation.com` and `configautomation.com`
- Wayback-backed output paths were normalized to original site-path layout instead of archive-internal `web/...` paths

## Next Recovery Targets

- recover linked ZIP downloads from preserved pages where the links are known but the files are missing
- extract lesson-to-source-script mappings for the highest-value curriculum modules
- prioritize scripts referenced by:
  - Keynote examples
  - Pages examples
  - Services tutorials
  - Configurator workflow pages
