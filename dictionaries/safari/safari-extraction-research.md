# Safari — Extraction Research

> Read-only study. Generated 2026-05-08 from live probe of Esa's Mac
> (macOS 15.6.1). No actions taken; nothing modified. This document
> describes WHAT can be accessed, WHERE it lives, and HOW to query it.
> A `safari-export/` package would follow the `voice-memos-export/` shape.

## Live numbers on this Mac

```
7 Safari windows tracked
1,499 open tabs across those windows  (+ private-browsing groups, untouched)
2,974 bookmarks/folders/groups in the local store
22 (window × tab-group) relationships
2 Safari profiles
1,922 iCloud-synced tabs from 3 other devices
52,443 unique URLs in browsing history (147,035 visits)
1,494 history tags
```

User estimate was 8 windows; DB shows 7. Likely a brand-new window
not yet flushed to disk, or a private-mode window that doesn't persist.

## Question 1 — Can we access bookmarks? **YES**

Two stores, both readable with no special permission beyond Full Disk
Access (already granted on this Mac):

### A. Modern store: SQLite

```
~/Library/Containers/com.apple.Safari/Data/Library/Safari/SafariTabs.db
```

The `bookmarks` table holds **everything** — bookmarks, bookmark
folders, AND tab groups AND tab leaves. They're all the same kind of
record, distinguished by `type` and `parent`:

| `type` | meaning |
|--------|---------|
| `0` | Leaf (a bookmark URL or an open tab) |
| `1` | Folder (a bookmark folder, a tab group, or a window's "Local" tab group) |

Key columns: `id`, `parent` (FK to another bookmarks row), `type`,
`title`, `url`, `num_children`, `order_index`, `last_modified`,
`deleted`, `external_uuid`, `subtype`, plus sync state and CloudKit
record fields.

Indexes already exist for `parent+type+order_index`, `url`, and a
`bookmark_title_words` full-text-style table (23,944 word entries) —
queries for "find all bookmarks containing X" are fast.

**Top-level bookmark folders on this Mac** (with leaf counts):

```
228  Renoise
182  YouTube
103  MERLib
 97  Free Energy
 96  Tomas
 86  Learning
 82  Shopping
 74  Music
 65  Apple
 54  Lackluster
 48  Mental Health
 40  Ray
 27  pinned
 23  Steve Jobs
  2  Recipes
```

That's the **organized** part of the picture. Tabs from open windows
sit in separate tab-group rows ("Local" entries below).

### B. Legacy store: plist

```
~/Library/Safari/Bookmarks.plist     (8 MB on this Mac)
```

XML-serializable property list with a hierarchical `Children` tree.
Includes Reading List with embedded fetched-article archives. Probably
a legacy / sync-mirror of the SQLite store; both are kept in sync.
SQLite is the canonical place to query.

## Question 2 — Can we access tab groups? **YES**

Tab groups are also rows in `bookmarks` (type=1) but the relationship
to windows lives in two join tables:

```sql
-- Which windows show which tab groups
SELECT w.id AS window_id, b.id AS tab_group_id, b.title, b.num_children
FROM windows_tab_groups wtg
JOIN windows w ON w.id = wtg.window_id
JOIN bookmarks b ON b.id = wtg.tab_group_id
WHERE b.deleted = 0;
```

**On this Mac**: 22 (window, tab-group) pairs across 7 windows. Window
3 is the "messy" one — it has 16 tab groups inside it:

```
window 3 ─┬─ Renoise            228 tabs
          ├─ YouTube            182 tabs
          ├─ Free Energy         97 tabs
          ├─ Learning            86 tabs
          ├─ Shopping            82 tabs
          ├─ Music               74 tabs
          ├─ Apple               65 tabs
          ├─ Mental Health       48 tabs
          ├─ Lackluster          54 tabs
          ├─ Steve Jobs          23 tabs
          ├─ ModPlugTracker      22 tabs
          ├─ Costs Nothing       26 tabs
          ├─ Metricool            8 tabs
          ├─ Recipes              2 tabs
          ├─ Root                23 tabs
          └─ Local              461 tabs   ← uncategorized
```

So the chaos is partly self-organized: most of those 600+ tabs already
live in a themed tab group. The hard problem is the "Local" tab group
of each window, which holds all the *uncategorized* tabs (461 + 486 +
242 + ... = the bulk of the 1,499).

`windows_unnamed_tab_groups` is empty on this Mac — there's no extra
category we missed.

`windows_profiles` has 2 entries — there are **two Safari profiles** on
this account.

## Question 3 — Can we access open tabs across windows? **YES, three ways**

### A. The SafariTabs.db SQLite store (the answer for "all 8 windows")

Every open tab is a `bookmarks` row with `type=0`, `parent` pointing at
the tab group it's in, `url` set, and `title` set. To list all tabs in
a window, walk the bookmark tree from `windows.local_tab_group_id`:

```sql
WITH RECURSIVE tg(id) AS (
  SELECT local_tab_group_id FROM windows WHERE id = ?win_id
  UNION ALL
  SELECT b.id FROM bookmarks b JOIN tg ON b.parent = tg.id
  WHERE b.deleted = 0
)
SELECT b.title, b.url, b.parent, b.order_index
FROM tg JOIN bookmarks b ON b.id = tg.id
WHERE b.type = 0
ORDER BY b.parent, b.order_index;
```

**Live counts per window**:

| Window | Tabs |
|--------|------|
| 5 | 486 |
| 3 | 461 |
| 6 | 242 |
| 24 | 149 |
| 27 | 140 |
| 14 | 20 |
| 28 | 1 |

Total: **1,499 tabs** (matches Esa's "600/300/200" estimate).

### B. Live AppleScript (only the running session)

```applescript
tell application "Safari"
  repeat with w in windows
    repeat with t in tabs of w
      log (URL of t) & "  →  " & (name of t)
    end repeat
  end repeat
end tell
```

Pros: live URL + page title + index + visible flag + HTML `source` +
plain `text`. Can `do JavaScript` per tab. Can `close` a tab.

Cons: only the currently-running Safari sees these. The DB has
everything including tabs in inactive tab groups; AppleScript only
walks the visible/active hierarchy reliably.

`add reading list item` is also available as a top-level command.

### C. iCloud tabs from other devices: CloudTabs.db

```
~/Library/Containers/com.apple.Safari/Data/Library/Safari/CloudTabs.db
```

`cloud_tabs` table — 1,922 rows here, broken down by device:

```
RayMac           (MacBook Pro 14" 2023)   1,503 tabs
esaiPhone16Pro   (iPhone 16 Pro)            416 tabs
CloudcityMacMini (this Mac, sync stub)         1 tab
```

So iCloud sees Esa's iPhone tabs (416) and his RayMac tabs (1,503). That's
**~1,920 additional tabs** beyond what's open on this Mac. RayMac alone
is in the same shambles tier.

`cloud_tab_close_requests` is empty — that table queues tab-close
operations to push to other devices via iCloud. We could write to it to
remotely close a tab on iPhone or RayMac, but only as part of an
explicit reorganization pass.

## Bonus — History.db

```
~/Library/Safari/History.db
```

| table | rows | meaning |
|-------|------|---------|
| `history_items` | 52,443 | unique URLs ever visited |
| `history_visits` | 147,035 | individual visit events |
| `history_tags` | 1,494 | manual tags (the `2025-01-08` import retained tag info) |
| `history_items_to_tags` | 1,794 | which item has which tag |

Useful for the reorg: "for each open tab, when did I last visit
this URL?" → keep recently-visited tabs, sweep the rest.

## What this enables (no actions yet)

A `safari-export/` package mirroring `voice-memos-export/` could offer:

```
safari-export windows                    # 7 windows + tab-group breakdown
safari-export tabgroups                  # 22 named tab groups + counts
safari-export tabs                       # all 1,499 open tabs
safari-export tabs --window 5            # one window's tabs
safari-export tabs --tabgroup "Free Energy"
safari-export bookmarks --top-level      # 23 top-level folders
safari-export bookmarks --tree           # full hierarchy as markdown
safari-export icloud-tabs                # 1,922 tabs from iPhone + RayMac
safari-export history --last 30d
safari-export search "kortela|grotz"     # match across tabs + bookmarks + history
```

And later, with explicit Esa-driven action commands:

```
safari-export consolidate --to-bookmarks --window 5 --untag "Local"
safari-export dedupe                     # detect duplicate URLs across windows/devices
safari-export dump --md                  # everything → markdown vault
```

## Disk-lean approach (same philosophy as voice-memos-export)

Vault would store:
- One `windows.md` with the window-tabgroup-tab tree
- One `bookmarks/<topic>.md` per top-level folder (Renoise, YouTube, …) — markdown link list
- One `tabgroups/<name>.md` per named tab group
- A `cloud-tabs/<device>.md` per iCloud-synced device

No HTML caching. No Reading List archives. Just URL + title + last-visit
timestamp from history. The whole 1,499-tab archive should compress to
under 1 MB of markdown.

## Permissions / safety

- All reads above use the Safari Group Container (`~/Library/Safari/`)
  and the App Container (`~/Library/Containers/com.apple.Safari/`).
  Both readable with Full Disk Access (granted on this Mac).
- DBs use SQLite WAL mode — open them **read-only** (`file:...?mode=ro`)
  to avoid any chance of WAL corruption mid-Safari-write.
- Writing to `cloud_tab_close_requests` would propagate close commands
  via iCloud — never do this without explicit Esa request.
- AppleScript `do JavaScript` requires "Allow JavaScript from Apple
  Events" (Develop menu). Reading `URL`, `name`, `index` of tabs does
  not.

## Open questions for Esa to decide before any reorganization

1. The 461- and 486-tab "Local" groups in windows 3 and 5 — keep them
   open in-window, move to existing tab groups by topic, or convert all
   to bookmarks under the corresponding folders?
2. iCloud tabs from RayMac (1,503) — these are tabs Esa intentionally
   keeps on the work laptop. Pull into a "RayMac mirror" tab group on
   this Mac, leave alone, or drop entirely?
3. `Steve Jobs` (23 bookmarks), `Renoise` (228), `Free Energy` (97) and
   the rest — are these the canonical homes for matching open tabs, or
   were they just bookmarked separately and the open-tab equivalents
   should be deduped?
4. Profiles — there are two. Is one of them the "work" profile and one
   the "personal", or do both have your themed tab groups?

Once those are answered we can write the action commands; until then,
this study + the read-only `safari-export list/tabs/bookmarks` commands
are the scope.
