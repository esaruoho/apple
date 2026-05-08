# photos-exporter

Apple Photos library catalog via the `Photos.sqlite` database. The
Photos sdef is limited; the SQLite at
`~/Pictures/Photos Library.photoslibrary/database/Photos.sqlite` is
the real surface. Read-only (`?mode=ro&immutable=1`).

**Disk-lean by design**: never copies image files. The vault holds
metadata only — albums, smart albums, keywords, GPS, favorites,
filenames, dimensions, dates. The 3.2 GB photo library stays at
Apple's path.

```bash
photos-exporter status                            # 77,033 assets / 4,787 albums on this Mac
photos-exporter albums --limit 30                 # by photo count
photos-exporter albums --smart-only               # 23 smart albums
photos-exporter album "Pampula"                   # 4,700 assets in this album
photos-exporter keywords --limit 50
photos-exporter places --limit 50                 # photos with GPS
photos-exporter favorites --limit 100
photos-exporter export                            # full vault
photos-exporter export --heads-only               # albums index only, no asset lists
photos-exporter export --per-album-limit 1000     # cap per-album md size
```

Vault layout:

```
~/work/apple/exported/photos/
├── INDEX.md
├── keywords.md
├── albums/
│   ├── _index.md                       4,787 album index
│   ├── pampula.md                      one md per album, with date+filename+dims+GPS per asset
│   ├── pampula2.md
│   └── ...
└── by-year/
    └── _index.md                       counts per year
```

Live numbers on this Mac (2026-05-08):
- **77,033 assets** (videos + photos)
- **4,787 albums** (4,764 user + 23 smart)
- **585 favorites**
- Top albums: Pampula 4,700 / Pampula2 2,774 / WhatsApp 680 / Linna 489 / Tomas Camera 487

## Schema gotchas

- The album↔asset join table is `Z_<N>ASSETS` where `<N>` changes
  with macOS schema version. We auto-detect at runtime by globbing
  `Z_[0-9]*ASSETS`. On macOS 15.6.1 it's `Z_30ASSETS` with
  columns `Z_30ALBUMS` (FK to ZGENERICALBUM) + `Z_3ASSETS`
  (FK to ZASSET).
- Smart albums have `ZGENERICALBUM.ZKIND = 1505`. Folders are
  different kinds (3571–3573 for system/sync albums) and excluded
  by the `ZTITLE NOT NULL` filter.
- `ZASSET.ZLATITUDE = -180` is the sentinel for "no GPS"; filter it
  out when listing places.
- `ZASSET.ZKIND = 1` is video, `0` is photo. Subtypes via
  `ZKINDSUBTYPE` (Live Photo, slo-mo, panorama, screenshot, etc.) —
  not surfaced in this version.

## Phase 2 (not built)

- **Faces / People** — `ZPERSON` + `ZDETECTEDFACE` tables. iCloud
  Photos must be enabled for this data to be present.
- **Memories** — `ZMEMORY` table.
- **Captions / titles** — `ZASSETDESCRIPTION` table.
- **Originals symlinking** — like voice-memos-exporter does for
  m4a, but for the original .HEIC / .JPG / .MOV files under
  `~/Pictures/Photos Library.photoslibrary/originals/<bucket>/`.
  Disk-cheap; would let Obsidian preview Photos assets via symlink.
- **Shared albums** — `ZSHARE` + `ZCLOUDSHAREDALBUMINVITATIONRECORD`.
- **Captions / OCR** — `ZCHARACTERRECOGNITIONATTRIBUTES` holds Live
  Text per asset.
