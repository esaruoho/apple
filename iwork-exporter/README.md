# iwork-exporter

Pages + Numbers + Keynote catalog. On macOS Sequoia, Apple ships
**two parallel iWork installs**:

- **Regular iWork** (App Store, `com.apple.iWork.Pages` /
  `.Numbers` / `.Keynote`, v14.x).
- **Creator Studio** (newer experimental, `com.apple.Pages` /
  `.Numbers` / `.Keynote`, v15.x).

Both have full AppleScript sdefs. Recent documents are stored in
LSSharedFileList `.sfl3` files (NSKeyedArchiver bplist) and
**shared across both variants** — the .sfl3 doesn't distinguish
which app version opened the doc.

```bash
iwork-exporter status                           # which apps installed + recent counts
iwork-exporter apps                             # full app inventory
iwork-exporter apps --json
iwork-exporter recents --app pages
iwork-exporter recents --app numbers --limit 30
iwork-exporter recents --app keynote --json
iwork-exporter all-recents                      # combined view
iwork-exporter export                           # markdown vault
```

Live numbers on Esa's Mac (2026-05-08):

```
5 iWork apps installed:
  Pages     regular         v14.5    com.apple.iWork.Pages
  Numbers   regular         v14.5    com.apple.iWork.Numbers
  Pages     creator-studio  v15.2.1  com.apple.Pages
  Numbers   creator-studio  v15.2.1  com.apple.Numbers
  Keynote   creator-studio  v15.2.1  com.apple.Keynote

Recent pages:    populated
Recent numbers:  populated
Recent keynote:  populated  (note: only Creator Studio has Keynote on this Mac)
```

## .sfl3 NSKeyedArchiver decode

Earlier finder-exporter version had a naive .sfl3 walk that returned
0 results. iwork-exporter ships a **proper UID resolver** that walks
the `$objects` array, replaces every UID reference with the resolved
object, and reconstructs `NSDictionary` (NS.keys + NS.objects) and
`NSArray` (NS.objects) into native Python dicts and lists.

Each item resolved typically has:
- `Name` — display title
- `Bookmark` — Apple bookmark blob (we extract the embedded
  `file://` URL via regex)
- `order` — list ordering
- `dateAdded` — when it became recent

The same resolver should also drop into finder-exporter for proper
RecentDocuments / FavoriteItems decoding (Phase 2 backport).

## Phase 2 (not built)

- **Document-level inspection**: open each .pages / .numbers / .key
  bundle and read its `metadata.plist` for thumbnail, theme, page
  count, last save, password-protected flag.
- **Templates** — list installed iWork templates from
  `~/Library/Containers/com.apple.iWork.Pages/Data/Library/Application Support/User Templates/Pages.localized/`.
- **Cross-variant compare** — diff Regular vs Creator Studio recents
  to see which docs are open where.
- **Live AppleScript** — `tell application "Pages" to get name of every
  document` for active session state.
