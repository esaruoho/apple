---
description: Bootstrap tag-button .apps for every Finder tag you've ever used. Auto-discovers tag names + colors from xattrs of all your tagged files. Drops one Tag <Name>.app per tag into /Applications/AppleToolbox/Apple-Tag-Apps/ — ⌘-drag the ones you want onto Finder toolbar. With args, builds a specific subset. Usage `/tag-app` (default: discover all), `/tag-app --dry-run` (preview only), `/tag-app <name> [color]` (single), `/tag-app <n1> <n2:color> ...` (explicit list).
allowed-tools: Bash
argument-hint: (none = discover all) | --dry-run | <name> [color] | <n1>[:c] <n2>[:c]...
---

Use Bash (one call, then stop). If `$ARGUMENTS` is a single tag name with no flags, prefer the single-tag builder; otherwise pass through to the bulk builder which defaults to `--discover`.

```
/Users/esaruoho/work/apple/bin/build-tag-apps $ARGUMENTS
```

After build, tell the user (one line):
- Opened `/Applications/AppleToolbox/Apple-Tag-Apps/` with one colored `Tag X.app` per tag. ⌘-drag the ones you want onto a Finder window's toolbar to pin them. Then: select files → click an icon → tagged (drops work too). The .app route is the ONLY way to get custom one-click buttons in Finder's toolbar — Customize Toolbar's palette refuses Shortcuts/Quick Actions/Services. Full gotcha: `wiki/concepts/finder-toolbar-locked.md`.
