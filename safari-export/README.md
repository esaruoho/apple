# safari-export

Read-only catalog + markdown vault for Safari data: windows, tab groups,
open tabs across all windows, bookmarks, iCloud tabs synced from other
devices, and browsing history. Same shape as `voice-memos-export/` and
`reminders-export/`. Apple's stores are never modified.

Source of truth: SQLite databases in
`~/Library/Containers/com.apple.Safari/Data/Library/Safari/`
(`SafariTabs.db`, `CloudTabs.db`) and `~/Library/Safari/History.db`.
Background analysis in
[`../dictionaries/safari/safari-extraction-research.md`](../dictionaries/safari/safari-extraction-research.md).

## Install

```bash
cd ~/work/apple/safari-export
cp .env.example .env          # set VAULT_PATH if you don't want ~/safari-vault
chmod +x scripts/safari-export
```

Terminal needs Full Disk Access (System Settings → Privacy & Security)
to read Safari's container.

## Commands

### `status` — quick overview

```bash
safari-export status
```

Prints window-by-window tab counts, bookmark/folder totals, iCloud-tab
counts per device, and history size.

### `windows` — windows + tab-group breakdown

```bash
safari-export windows
safari-export windows --json
```

Each window's tab groups + tab counts. The "Local" tab group is the
default uncategorized group of each window.

### `tabgroups` — named tab groups

```bash
safari-export tabgroups
safari-export tabgroups --json
```

Sorted by tab count. Distinguishes `Local` (a window's default group)
from `Group` (a user-named tab group).

### `tabs` — open tabs (filtered)

```bash
safari-export tabs                          # all open tabs across all windows
safari-export tabs --window 5               # tabs in window 5 only
safari-export tabs --tabgroup "Free Energy"
safari-export tabs --match 'kortela|grotz'  # title or URL regex
safari-export tabs --domain youtube.com
safari-export tabs --json
safari-export tabs --csv
```

### `bookmarks` — bookmark folders or full tree

```bash
safari-export bookmarks                     # top-level folders + counts
safari-export bookmarks --tree              # full hierarchy as markdown
safari-export bookmarks --tree --depth 3    # cap nesting depth
safari-export bookmarks --json
```

System slots (Private, recentlyClosed, Recovered) and tab groups are
excluded — only real bookmark folders are listed.

### `icloud-tabs` — synced from other devices

```bash
safari-export icloud-tabs
safari-export icloud-tabs --device iPhone   # one device only
safari-export icloud-tabs --match "tesla"
safari-export icloud-tabs --limit 20        # cap per device
safari-export icloud-tabs --json
```

### `history` — browsing history

```bash
safari-export history --last 7d
safari-export history --last 30d --match "kortela"
safari-export history --since 2026-01-01
safari-export history --json --limit 1000
```

`--last` accepts `d` (days), `w` (weeks), `m` (months ≈ 30d), `y`
(years ≈ 365d).

### `dedupe` — one .md per UNIQUE URL across all sources

Walks every URL leaf in your Safari archive (open tabs, pinned tabs,
bookmarks, iCloud-synced tabs from other devices), canonicalises each
URL (strips utm_* / fbclid / gclid / mc_cid / igshid / ref tracking
params, lowercases host, drops fragment), then writes one
`urls/<hash>__<slug>.md` per unique URL. Each file's frontmatter lists
**every place that URL appears**: which window, which tab group,
whether pinned, which bookmark folder path, which iCloud devices,
plus the history visit count and last-visit date.

```bash
safari-export dedupe --summary-only        # just print stats
safari-export dedupe                       # write urls/ + _duplicates.md
safari-export dedupe --no-history          # skip history visit-count enrichment
```

Output:

```
$VAULT_PATH/
├── _duplicates.md        ranked list of URLs in 2+ places
└── urls/
    ├── <12-char hash>__<slug>.md           one per unique URL
    └── ...
```

Live numbers on Esa's Mac: **4,769 URL instances → 3,088 unique →
1,391 duplicated (≥2 locations)**. Top offender: a single Renoise
Forums URL appearing in **13 open tabs + 11 iCloud tabs = 24 places**
(visited 6,527 times in history). The "Lackluster / Esa Ruoho /
Paketti / Teosto" Google Sheet is in 8 open tabs + 1 pinned + 8 iCloud
tabs = 17 places.

Each per-URL file looks like:

```yaml
---
url: "https://forum.renoise.com"
title: "(1) Renoise Forums"
location_count: 24
is_duplicate: true
open_tabs: 13
bookmarks: 0
pinned: 0
icloud_tabs: 11
icloud_devices:
  - "RayMac"
  - "esaiPhone16Pro"
history_visits: 6527
history_last_visit: "2026-05-07 18:28:30"
hash: 5c39383eb2c1e32634d6c34d
---

# (1) Renoise Forums
<https://forum.renoise.com>

## Open in 13 tab(s)
- Window 3 → Local `Local` (order 189)
- Window 3 → Group `Renoise` (order 57)
- ...

## iCloud tab on 11 device(s)
- RayMac
- esaiPhone16Pro
- ...

## History
- Visited 6527 time(s) (last: 2026-05-07 18:28:30)
```

Filename uses a stable blake2b-12 hash of the canonical URL, so re-running
`dedupe` produces the same filenames — drop the `urls/` folder into
Obsidian and Esa can grep, link, sort by `location_count`, or sort by
`history_visits` to make reorg decisions per URL.

Vault size after `dedupe`: 12 MB across 3,088 markdown files.

### `search` — cross-search tabs + bookmarks + history

```bash
safari-export search "kortela"
safari-export search "russell|tesla|schauberger"
```

Returns matches in three sections: open tabs, bookmarks, history (last
90 days). Up to 30 results per section.

### `export` — full markdown vault

```bash
safari-export export                                # everything except history
safari-export export --with-history --history-days 90
```

Writes to `$VAULT_PATH` (default `~/safari-vault`).

## Vault layout

```
~/safari-vault/
├── INDEX.md                       navigation
├── windows/
│   ├── window-3.md                Window 3: 1453 tabs, grouped by tab-group
│   ├── window-5.md
│   └── ...
├── tabgroups/
│   └── _index.md                  all named tab groups, sorted by tab count
├── bookmarks/
│   ├── _index.md
│   ├── merlib.md                  one md per top-level bookmark folder
│   ├── tomas.md
│   ├── paketti.md
│   └── ...                        full bookmark tree as nested list
├── cloud-tabs/
│   ├── _index.md
│   ├── raymac.md                  1,500 RayMac tabs
│   ├── esaiphone16pro.md          416 iPhone tabs
│   └── ...
└── history/
    ├── _index.md
    └── 2026-04.md                 history per month, sorted by visit time
```

Each window page lists tabs grouped by tab-group. Each bookmark page
shows the full nested tree. Each cloud-tabs page lists titles + URLs.
History pages list `date | visit-count | title | URL`. Default symlink
philosophy from `voice-memos-export/` doesn't apply here — there's no
audio to symlink, just URLs.

## Live numbers on Esa's Mac

```
6 windows
2,477 open tabs (Window 3 = 1,453 across 15 groups; Window 5 = 493)
20 named tab groups
2,886 bookmarks across 64 folders (8 user-curated top-level folders)
1,899 iCloud-synced tabs from 3 other devices
  RayMac (MacBook Pro 14"): 1,482
  esaiPhone16Pro:           416
  CloudcityMacMini sync:    1
52,442 unique URLs in browsing history (147,033 visits)
```

Vault size after `export --with-history --history-days 30`: **2.5 MB**.

## Safety

- All SQLite reads use `?mode=ro&immutable=1` URI to avoid any chance
  of WAL corruption while Safari is running.
- No subcommand modifies Apple's data. There is no `close-tab`,
  `delete-bookmark`, or `move-tab` here. Any such write actions will
  arrive in a future Phase 2 with explicit confirmation prompts.
- The `cloud_tab_close_requests` table in `CloudTabs.db` could
  propagate close requests to other devices via iCloud — never written
  to from this tool.

## What's not in this package (yet)

- **Live AppleScript fallback** for tabs not yet flushed to the DB.
  The DB lags Safari by a few seconds when tabs are opened/closed
  rapidly. For most cases the DB is current.
- **Full-text indexing of tab content** (HTML / page text). Possible
  via Safari's AppleScript `source` and `text` per-tab, but expensive
  on 2,477 tabs. Future opt-in.
- **Reading List archive extraction**. The legacy
  `~/Library/Safari/Bookmarks.plist` carries embedded article text for
  saved Reading List items.
- **Write actions**: close-tab, move-tab, dedupe, archive-window
  (write to bookmarks then close). Will need explicit Esa confirmation
  per action.
