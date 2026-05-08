# stickies-exporter

Read-only catalog + markdown vault for Apple Stickies notes. Sixth
member of the Apple bulk-exporter family.

Stickies has **no AppleScript dictionary**, no App Intents, no URL
scheme — Tier 5 dark. But each note is just a `.rtfd` bundle in the
app container, and `textutil` (Apple-native, ships with macOS)
converts it to text / html / docx / rtf. No third-party dependencies.

Source: `~/Library/Containers/com.apple.Stickies/Data/Library/Stickies/<UUID>.rtfd/`

Background:
[`../dictionaries/stickies/stickies-extraction-research.md`](../dictionaries/stickies/stickies-extraction-research.md)

## Install

```bash
cd ~/work/apple/stickies-exporter
cp .env.example .env
chmod +x scripts/stickies-exporter
```

Terminal needs Full Disk Access (System Settings → Privacy &
Security) to read the Stickies app container.

## Selector grammar

Used by `cat`:

| Selector | Example | Notes |
|----------|---------|-------|
| `latest` | `latest` | most-recently-modified |
| `#N` | `#0`, `#3` | 0-based, sorted by modified-desc |
| YYYY-MM-DD | `2026-04-07` | first match modified that day |
| UUID prefix | `1ECCD6E3` | 4+ hex chars |
| Title or body substring | `"Stubblefield"` | case-insensitive |

## Commands

### `status` — overview

```bash
stickies-exporter status
```

### `list` — all stickies

```bash
stickies-exporter list
stickies-exporter list --match 'beatty|manning|tesla'
stickies-exporter list --since 2026-04-01
stickies-exporter list --json
```

Columns: index, modified date, UUID prefix, char count, title.

### `cat` — print one sticky

```bash
stickies-exporter cat latest
stickies-exporter cat "Stubblefield"
stickies-exporter cat 1ECCD6E3
stickies-exporter cat #0 --with-meta
stickies-exporter cat 1ECCD6E3 --rtf            # raw RTF
stickies-exporter cat 1ECCD6E3 --html           # HTML conversion
```

### `export` — markdown vault dump

```bash
stickies-exporter export                        # text only
stickies-exporter export --include-rtf          # also symlink .rtfd next to .md
stickies-exporter export --match 'energy|tesla'
```

Default vault path: `~/work/apple/exported/stickies/` (override in `.env`).

Vault layout:

```
~/work/apple/exported/stickies/
├── 2026-04-07__stubblefield__1ECCD6E3.md
├── 2026-04-07__imploosio__23D4B1CE.md
├── 2026-04-07__stubblefield__1ECCD6E3.rtfd     ← only with --include-rtf (symlink)
└── ...
```

Sidecar frontmatter:

```yaml
---
uuid: "1ECCD6E3-5958-4D1E-974B-7E19CDFB9AAA"
title: "Stubblefield"
modified: "2026-04-05 21:12:00"
char_count: 12
colors: ["#FFFFFF", "#3E80E9", "#85858E"]
link_color: "#3E80E9"
text_color: "#85858E"
rtfd_source: "/Users/esaruoho/Library/Containers/com.apple.Stickies/Data/Library/Stickies/1ECCD6E3-5958-4D1E-974B-7E19CDFB9AAA.rtfd"
---

# Stubblefield

…note body…
```

`colors` is the parsed `\colortbl` from the RTF stream. By
convention in Stickies the second slot is the link color and the
third is the text color (slot 0 is the default white).

## What's NOT in this package

- **Sticky background color** (the yellow / pink / blue note color).
  That's a per-window UI choice in Stickies — not stored in the rtfd.
- **Window position** — also not persisted to disk on this Mac.
- **Phase 2 write actions** (`create`, `append`, `delete`). Those
  need a quit-Stickies-first guard to avoid in-memory overwrite,
  plus an explicit `--write` flag. Coming when Esa needs them.
- **Cross-reference** with the free-energy archive (Stubblefield,
  Bill Beatty, Jeane Manning, Sand Battery, Leedskalnin overlap
  heavily) — Phase 3.

## Live numbers on Esa's Mac

```
10 stickies on disk
total bytes (rtfd bundles): ~17 KB
vault size after `export --include-rtf`: ~22 KB
```

Topics: Stubblefield, imploosio, Sand Battery, Orthogonal fields,
Bill Beatty, Jeane Manning, Kentucky Water Fuel Museum, Falstad
CircuitJS URL, Leedskalnin, "Process Esko Leikas audio recording to
transcript". Free-energy / archive research stubs.
