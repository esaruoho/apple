---
layout: default
title: "Safari export schema gotchas + safari-export package"
---

---
description: Six SafariTabs/CloudTabs/History.db schema landmines that wasted probes on 2026-05-08, plus the layout of ~/work/apple/safari-export/ which reads them all read-only.
---

# Safari export schema gotchas + safari-export package


[← Back to home](./)
## Where Safari data lives

Three SQLite stores, all readable with Full Disk Access already granted on Esa's Mac:

- `~/Library/Containers/com.apple.Safari/Data/Library/Safari/SafariTabs.db` — windows, tab groups, open tabs, bookmarks (one unified `bookmarks` table)
- `~/Library/Containers/com.apple.Safari/Data/Library/Safari/CloudTabs.db` — tabs synced from other devices via iCloud
- `~/Library/Safari/History.db` — full browsing history

**Always open these read-only**: `sqlite3.connect(f"file:{path}?mode=ro&immutable=1", uri=True)`. Safari is usually running and writes WAL — read-only opens avoid any risk of corrupting the journal.

## Six schema gotchas (each one wasted a probe before being identified)

1. **Unified `bookmarks` table**: this single table holds bookmarks AND tab-group rows AND open-tab rows AND bookmark folders. Distinguished only by `type` (0 = leaf URL, 1 = folder/group) and `parent`. There is no separate "tabs" table.

2. **`windows_tab_groups.tab_group_id = 0`**: this row references the synthetic bookmarks root, NOT a real tab group. Including it makes a window appear to contain the entire 2,800-bookmark tree as "tabs". Always exclude with `WHERE wtg.tab_group_id != 0`.

3. **`cloud_tabs.last_viewed_time`** (NOT `last_modified`). The schema column is named differently from what the API name suggests.

4. **`history_visits.visit_time`** (NOT `last_visit`). The "last visit" of an item is a `MAX(visit_time)` aggregate over its history_visits rows; there is no precomputed column.

5. **Top-level bookmark filtering**: querying `WHERE parent IS NULL OR parent = 0` returns lots of system reserved slots (Recovered, Private, privatePinned, recentlyClosed, Local). Filter properly with: `special_id = 0 AND num_children > 0 AND title NOT IN ('Private', 'privatePinned', 'recentlyClosed', 'Recovered', 'Local') AND id NOT IN (SELECT tab_group_id FROM windows_tab_groups)`.

6. **Free FTS**: the `bookmark_title_words` table is already populated by Safari with one row per title-word. Use it for fast bookmark search; no need to build your own index.

## What `safari-export` provides

Subcommands at `~/work/apple/safari-export/scripts/safari-export`:

- `status` — counts overview
- `windows` — windows with tab-group breakdown
- `tabgroups` — named tab groups by tab count
- `tabs --window N --tabgroup NAME --match REGEX --domain HOST`
- `bookmarks [--tree --depth N]`
- `icloud-tabs --device NAME --match REGEX --limit N`
- `history --last 7d --since DATE --match REGEX`
- `search QUERY` — cross-search tabs + bookmarks + history
- `export [--with-history --history-days N]` — full markdown vault

Vault layout: `windows/window-N.md`, `tabgroups/<slug>.md` (per group, full tab list with nesting), `bookmarks/<topic>.md`, `cloud-tabs/<device>.md`, `history/YYYY-MM.md`, `INDEX.md`.

## Cardinality on Esa's Mac (snapshot 2026-05-08)

- 6 Safari windows
- 2,477 open tabs (Window 3 alone: 1,453 across 15 tab groups; Window 5: 493)
- 20 named tab groups
- 2,886 bookmarks across 64 folders (8 user-curated top-level)
- 1,899 iCloud-synced tabs from 3 other devices: RayMac (1,482), esaiPhone16Pro (416), CloudcityMacMini stub (1)
- 52,442 unique history URLs across 147,033 visits

## `dedupe` subcommand (added 2026-05-08)

`safari-export dedupe` walks every URL leaf across all sources (open tabs, pinned, bookmarks, iCloud tabs), canonicalises (strips utm_*/fbclid/gclid/mc_cid/igshid/ref/feature/spm tracking params, lowercases host, drops fragment), and writes one `urls/<blake2b12>__<slug>.md` per unique URL. Frontmatter lists every place that URL appears + history visit count.

Numbers on Esa's Mac: 4,769 instances → 3,088 unique → 1,391 in 2+ places. Top dup: forum.renoise.com root in 24 places (13 open tabs + 11 iCloud), 6,527 history visits. Lackluster Google Sheet in 17 places (8 tabs + 1 pinned + 8 iCloud).

Stable blake2b filenames let Obsidian/grep across rounds without reshuffling files.

## Phase 2 NOT built (intentional)

`close-tab`, `move-tab --from --to`, `archive-window` (write to bookmarks then close). Esa wants to study the topology before any reorg. The `cloud_tab_close_requests` table in `CloudTabs.db` would propagate close requests across devices via iCloud — never write to it without explicit request.

## Lesson

When an app stores user data in SQLite, the column names often don't match the API surface (`last_viewed_time` vs `last_modified`, `visit_time` vs `last_visit`). And junction tables like `windows_tab_groups` can have synthetic-root rows that look real but represent system structure rather than user data. Run `.schema` on every table before writing queries; sample rows for distinct values of foreign-key columns; verify against live counts (compare DB-derived count against the AppleScript `count of tabs of window N` to catch phantoms early).
