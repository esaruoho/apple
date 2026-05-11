# preview-exporter

Apple Preview recent docs + per-file metadata → markdown vault.

## Data sources

- **Recent docs:** the LSSharedFileList entry at
  `~/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.ApplicationRecentDocuments/com.apple.preview.sfl3`
  decoded via the shared `bin/lib/sfl3_resolver.py` (NSKeyedArchiver UID
  walker + Foundation bookmark resolver).
- **Per-file metadata:** `/usr/bin/mdls` against each resolved path — page
  count, kind, content type, title, subject, file size, FS create/modify,
  encryption status.

## What is NOT extracted

PDF annotations live inside each PDF file as standard `/Annot` dictionaries.
Preview writes them there, not in an Apple sidecar. Extracting annotation
contents would require a PDF parser (PyMuPDF, pdfplumber); those are not
Apple-native dependencies and are out of scope for this package.

## Subcommands

```bash
./scripts/preview-exporter status          # recent count + per-extension breakdown
./scripts/preview-exporter recents [--limit N] [--json]
./scripts/preview-exporter export          # vault under VAULT_PATH
```

## Vault layout

```
exported/preview/
├── _index.md                  master list of recent docs
└── recents/<slug>.md          one sidecar per recent doc with mdls
                               frontmatter (path, kind, pages, size, etc.)
```
