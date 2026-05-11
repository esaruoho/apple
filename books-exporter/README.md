# books-exporter

Apple Books library, collections, and annotations → markdown vault.

## Data sources

Under `~/Library/Containers/com.apple.iBooksX/Data/Documents/`:

- `BKLibrary/BKLibrary-*.sqlite` — `ZBKLIBRARYASSET` (books), `ZBKCOLLECTION`,
  `ZBKCOLLECTIONMEMBER` (collection membership by `ZASSETID`)
- `AEAnnotation/AEAnnotation_*.sqlite` — `ZAEANNOTATION` (highlights + notes),
  joined to books by `ZANNOTATIONASSETID = book.ZASSETID`

Both filenames carry a build-timestamp suffix; the exporter globs the first
match. Read-only via the WAL-safe snapshot helper.

## Subcommands

```bash
./scripts/books-exporter status              # library + annotation counts
./scripts/books-exporter list [--author X] [--match TITLE]
./scripts/books-exporter collections         # collection tree with counts
./scripts/books-exporter annotations [--book TITLE]
./scripts/books-exporter export              # vault under VAULT_PATH
```

## Vault layout

```
exported/books/
├── _index.md                    master list
├── collections/<slug>/_index.md per-collection list
└── by-id/<asset-id>.md          one file per book; annotations inlined
                                 as block-quote highlight + italic note
```

Each per-book `.md` has YAML frontmatter (title, author, asset_id, genre,
year, kind, added, last_open, progress, annotations) plus body with
description and any inline annotations.

## What is NOT yet decoded

Annotation `ZANNOTATIONLOCATION` is a CFI (Canonical Fragment Identifier)
or chapter-index string — the format varies per book kind. The exporter
surfaces the raw string but doesn't render it as a navigable link into
the book. Same for `ZANNOTATIONSTYLE` (highlight color enum).
