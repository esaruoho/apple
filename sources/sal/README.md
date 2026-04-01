# Sal Source Archive

This directory is the canonical archive for Sal Soghoian source material.

Each site gets its own capsule:

```text
sources/sal/<site>/
  mirror/
  assets/
  manifest.yaml
```

Conventions:
- `mirror/` contains untouched captured HTML and supporting files
- `assets/` contains downloaded scripts, PDFs, ZIP files, and images
- `manifest.yaml` records origin URLs, capture timestamps, status, and extraction progress

Follow-on destinations:
- Extract runnable code to `scripts/sal/<site-slug>/`
- Store page and concept notes in `analysis/sal/`
- Update `indexes/sal-sites.yaml`, `indexes/sal-scripts.yaml`, and `indexes/sal-concepts.yaml`
