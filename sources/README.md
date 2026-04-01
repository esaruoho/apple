# Source Archives

This directory stores verbatim source material collected from external Apple automation sites.

Rules:
- Treat `mirror/` as immutable once captured.
- Store original downloads in `assets/` with original file names when possible.
- Keep capture metadata in `manifest.yaml`.
- Put derived notes, rewrites, and normalized script copies elsewhere in the repo.

Primary source families:
- `sal/` for Sal Soghoian-owned or Sal-authored sites

Acquisition flow:
1. Mirror pages and downloads into `sources/<family>/<site>/mirror/` and `assets/`
2. Record provenance in `manifest.yaml`
3. Extract runnable code into `scripts/`
4. Add teaching notes in `analysis/`
5. Update machine-readable lookups in `indexes/`
