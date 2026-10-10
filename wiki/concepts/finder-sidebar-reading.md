---
description: Read Finder Favorites from the sfl3 archive and resolve bookmarks with AppleScriptObjective-C, without changing the sidebar.
---
# Reading Finder Sidebar Favorites

Verified locally on 2026-10-10, macOS Sequoia 15.6.1 (24G90).

**Finder Favorites can be read without UI scripting.** Read the persisted shared-file-list archive, then resolve each item's bookmark using Foundation. The [editing warning](finder-sidebar-locked.md) concerns modification and the deprecated LSSharedFileList API; it does not mean reading is impossible.

## Where the data lives

```text
~/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.FavoriteItems.sfl3
```

On this Mac it is a binary plist containing an NSKeyedArchiver graph. The decoded root is a dictionary with `items` and `properties`. Each of the 35 items has `visibility`, `CustomItemProperties`, `Bookmark` (binary bookmark data), and `uuid`. This observed archive uses standard NSDictionary/NSArray objects; a private SFLListItem class is not needed to decode this particular file.

The list preserves persisted item order. This is a disk snapshot, not proof of the exact visible sidebar: Finder can filter entries using visibility/settings, and its running state may differ from disk. Locations, Tags, and other sidebar sections are separate concerns.

## Tested read-only recipe

Save this as `/tmp/read-finder-favorites.applescript`, then run `osascript /tmp/read-finder-favorites.applescript`:

```applescript
use framework "Foundation"
use scripting additions
on run
 set storePath to (system attribute "HOME") & "/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.FavoriteItems.sfl3"
 set archiveData to current application's NSData's dataWithContentsOfFile:storePath
 set root to current application's NSKeyedUnarchiver's unarchiveObjectWithData:archiveData
 set itemList to root's objectForKey:"items"
 set rows to {}
 repeat with itemRef in itemList
  set bookmarkData to itemRef's objectForKey:"Bookmark"
  set opts to (current application's NSURLBookmarkResolutionWithoutUI as integer) + (current application's NSURLBookmarkResolutionWithoutMounting as integer)
  set {resolvedURL, isStale, resolveError} to current application's NSURL's URLByResolvingBookmarkData:bookmarkData options:opts relativeToURL:(missing value) bookmarkDataIsStale:(reference) |error|:(reference)
  if resolvedURL is missing value then
   set end of rows to "UNRESOLVED"
  else
   set end of rows to (resolvedURL's absoluteString() as text) & " stale=" & (isStale as text)
  end if
 end repeat
 return rows
end run
```

The result is a list of absolute URL strings plus stale flags. Keep URLs intact: one local entry resolved to `nwnode://domain-AirDrop`, rather than a filesystem path. File URLs can contain percent escapes; use the resolved URL's `path()` if a decoded filesystem path is specifically required, and only for file URLs.

`withoutUI` suppresses resolution UI; `withoutMounting` prevents mounting a volume while resolving. See Apple's [withoutUI](https://developer.apple.com/documentation/foundation/nsurl/bookmarkresolutionoptions/withoutui) and [withoutMounting](https://developer.apple.com/documentation/foundation/nsurl/bookmarkresolutionoptions/withoutmounting) documentation. Stale bookmark data can still resolve; report its stale status rather than silently rewriting the store.

## Validation and limits

- The recipe resolved **35/35 saved entries**, all with `stale=false`, including ordinary folders, iCloud paths, saved searches, and AirDrop. No Finder restart or sidebar edit was needed.
- `bin/cocoa-class-probe NSURL NSData NSKeyedUnarchiver` confirmed public classes before use.
- The run exited successfully; macOS also emitted `com.apple.hiservices-xpcservice` connection-invalid diagnostics. These accompanied successful output and were not evidence of an unreadable store.
- No Accessibility or Finder Automation request occurred in this run: the script calls Foundation rather than controlling applications. Filesystem privacy and sandbox restrictions can still affect other callers.
- This is a minimal local diagnostic for a trusted system-created archive. `unarchiveObjectWithData:` is deprecated and is not a secure decoder for arbitrary untrusted files. A production reader should use secure decoding with an explicit class allowlist, check missing/unreadable files and unexpected schemas, and report per-item errors.
- The `.sfl3` filename and archive schema are implementation details, not an Apple-supported Finder sidebar API. On another OS, inspect the actual file first; older systems may use `.sfl2`. Do not infer compatibility from this one-machine verification.
- `plistlib` can inspect the archive safely as data, but `$objects` contains both collection nodes and metadata. Follow `$top.root` and `plistlib.UID` references to the root `items` array; scanning every byte blob or extracting strings is not reliable URL resolution.
- Reading the store does not justify editing it, killing `sharedfilelistd`, or using the deprecated LSSharedFileList mutation path.

The user's actual Favorites URLs were used for verification but are deliberately omitted from this public knowledge page.

## Related

- [Finder sidebar editing constraints](finder-sidebar-locked.md)
- [AppleScriptObjective-C](asobjc.md)
- [Finder settings](finder-settings.md)
