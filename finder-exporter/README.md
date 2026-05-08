# finder-exporter

Finder tags, sidebar favorites, recent documents, recent
applications, recent hosts/servers, iCloud items. Three back-doors:

- `mdfind 'kMDItemUserTags == "*"'` for every tagged file
- `~/Library/Application Support/com.apple.sharedfilelist/*.sfl3` (NSKeyedArchiver bplist) for recents/favorites
- `~/Library/Preferences/com.apple.finder.plist` for tag colors / sidebar disclosure

```bash
finder-exporter status
finder-exporter tags                       # tag → file count
finder-exporter tag-files Paketti --limit 50
finder-exporter recents
finder-exporter favorites
finder-exporter export                     # full vault
```

Vault: `~/work/apple/exported/finder/` with `tags/<tag>.md` per
unique tag plus `recents.md`, `favorites.md`, etc.

Live on this Mac: 865 tagged files, multiple sfl3 lists.
