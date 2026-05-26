---
layout: default
title: Spotlight — the final Sal mile
---

# Spotlight — the final Sal mile

[← Back to home](./)

> *"The final Sal mile: should eventually work from Spotlight."*
> Every script in this repo should be one ⌘-Space away.

There are exactly **5 ways** to make automation reachable from Spotlight on macOS.

## Path 1: `osacompile` to `.app`

Compile any `.applescript` to a standalone `.app` bundle. Spotlight indexes every `.app` automatically via Launch Services.

```bash
osacompile -o /Applications/AppleToolbox/Apple-Workflows/Music-PlayPause.app \
  scripts/workflows/music/music-playpause.applescript

mdls -name kMDItemContentType /Applications/AppleToolbox/Apple-Workflows/Music-PlayPause.app
# → "com.apple.application-bundle"
```

**Critical gotcha:** the compiled `.app` must have a `CFBundleIdentifier` in its `Info.plist` for Spotlight to index it. `osacompile` does NOT add one by default. Fix:

```bash
/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string com.example.my-script" \
  MyScript.app/Contents/Info.plist
```

[`bin/spotlight-export.sh`](https://github.com/esaruoho/apple/blob/main/bin/spotlight-export.sh) does this automatically for every workflow script under `scripts/workflows/`. Naming matters: `Music-PlayPause.app` becomes searchable as "Music PlayPause" — Spotlight matches any word.

## Path 2: Shortcuts (best for App Intents width)

Every Shortcut is automatically Spotlight-indexed. Zero extra steps.

```bash
shortcuts run "Music PlayPause"   # CLI
# ⌘-Space → "Music PlayPause" → ⏎  # Spotlight
```

[`bin/shortcut-gen.py`](https://github.com/esaruoho/apple/blob/main/bin/shortcut-gen.py) emits signed `.shortcut` files; [`bin/batch-import.sh`](https://github.com/esaruoho/apple/blob/main/bin/batch-import.sh) imports them all.

## Path 3: `osascript` shebang

A plain `.applescript` with `#!/usr/bin/osascript` and `chmod +x` is runnable from CLI, but **not** Spotlight (Spotlight indexes apps, not arbitrary executables). Use Path 1 or wrap in a Shortcut.

## Path 4: Automator workflows

Save as **Application** in Automator. Same Spotlight indexability as Path 1. See [Automator vs Shortcuts](./automator-vs-shortcuts) for when each fits.

## Path 5: Tag-based .app generator (the Finder-toolbar flavour)

[`/tag-app`](./finder-tag-pipeline) generates one `Tag <Name>.app` per Finder tag the user has actually used. Lives at `/Applications/AppleToolbox/Apple-Tag-Apps/`. Spotlight indexes them all. ⌘-Space → "Tag process" → ⏎ tags the current Finder selection.

## Two gotchas worth their own write-up

### APFS Spotlight indexing

Some Mac users have Spotlight refusing to index their `/Applications/AppleToolbox/` folder because of APFS metadata corruption. Fix: `sudo mdutil -E /` to rebuild the entire root index. See the full diagnosis in the [source page](https://github.com/esaruoho/apple/blob/main/wiki/concepts/spotlight-automation.md).

### TCC + `mdimporter`

After installing a new `mdimporter`, you may need to grant Full Disk Access to `mdworker_shared` (the Spotlight indexing daemon). Symptoms: new file types don't show up in search even though `mdimport <file>` works fine standalone.

## What lives where

| Path | Compiled to | Indexed by |
|---|---|---|
| `scripts/workflows/finder/*.applescript` | `/Applications/AppleToolbox/Apple-Workflows/Finder-*.app` | Spotlight (via Path 1) |
| `bin/build-tag-app` output | `/Applications/AppleToolbox/Apple-Tag-Apps/Tag-*.app` | Spotlight (via Path 1) |
| `bin/shortcut-gen.py` output | Shortcuts.app | Spotlight (via Path 2) |
| `bin/build-*-shortcut.py` files | Specific signed `.shortcut` files (Quick Actions etc.) | Spotlight + Shortcuts.app (Path 2) |

## Read more

- Source-of-truth: [`wiki/concepts/spotlight-automation.md`](https://github.com/esaruoho/apple/blob/main/wiki/concepts/spotlight-automation.md) — full 5 paths, APFS bug walkthrough, TCC fix, the Sal-rule reasoning.
- Sal's principle: [Sal corpus → WWSD](./wwsd) — *"Spotlight is the canonical launch surface; if your tool isn't there, the user can't find it."*

---

[← Back to home](./) | [Triggers ←](./triggers) | [Tiers ←](./tiers) | [Sal corpus ←](./sal-corpus) | [Chassis ←](./chassis) | [ASObjC ←](./asobjc) | [Finder-tag ←](./finder-tag-pipeline)
