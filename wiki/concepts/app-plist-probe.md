---
description: bin/app-plist-probe.py scans every Apple-app plist and reports which apps have user-extractable data. Use this BEFORE deciding what to build next. Built 2026-05-08.
---

# app-plist-probe meta tool + top mineable apps

## Tool

`~/work/apple/bin/app-plist-probe.py`

Walks `~/Library/Containers/com.apple.*/Data/Library/Preferences/` and `~/Library/Preferences/com.apple.*.plist`. Decodes top-level keys, recursively unwraps NSKeyedArchiver blobs, filters noise (window frames, migration flags, NSToolbar/NSSplitView/NSStatusItem/NSNavLastRoot/etc.), and reports which apps actually persist user data worth exporting.

```bash
bin/app-plist-probe.py                              # short summary
bin/app-plist-probe.py --md --interesting-only > survey.md
bin/app-plist-probe.py --app voicememos             # one app
bin/app-plist-probe.py --grep tesla                 # value-search across ALL plists
```

## Live numbers on Esa's Mac (2026-05-08)

- 1,934 plists scanned across 518 apps
- 576 plists across 481 apps have non-trivial user data
- Full survey at `dictionaries/all-apps-plist-survey.md` (3,246 lines)

## Top 30 most-mineable apps (by interesting-key count)

```
   635  com.apple.mobilelogic            ← Logic Pro (mobile)
   522  com.apple.logic10                ← Logic Pro (full)
   461  com.apple.Music
   156  com.apple.Safari                 ← already covered by safari-exporter
   152  com.apple.audio.AudioComponentCache
   147  com.apple.iMovieApp
   146  com.apple.universalaccessAuthWarning
   109  com.apple.Preview
   105  com.apple.podcasts
   100  com.apple.finder
    91  com.apple.mail
    73  com.apple.Pages
    72  com.apple.Numbers
    65  com.apple.routined               ← Siri Suggestions / "Routine"
    60  com.apple.iWork.Numbers
    59  com.apple.iWork.Pages
    58  com.apple.dt.Xcode
    57  com.apple.Photos
    56  com.apple.Keynote
    52  com.apple.MobileSMS              ← already covered by imessage-exporter
    52  com.apple.madrid                 ← iMessage / Continuity backend
    52  com.apple.universalaccess
    49  com.apple.iBooksX
    47  com.apple.TV
    47  com.apple.siri.DialogEngine
    44  com.apple.Notes                  ← already covered by notes-exporter
    43  com.apple.iCal                   ← Calendar (next obvious target)
    40  com.apple.knowledge-agent
    39  com.apple.SetupAssistant
    39  com.apple.remindd                ← Reminders (already covered by reminders-exporter)
```

## How to use this for prioritisation

When deciding what to crack next:

1. **Already covered**: Safari, MobileSMS (iMessage), Notes, remindd (Reminders).
2. **Ready candidates** (high key count + clear user data):
   - Music (461 keys) — playlists, smart playlists, library state
   - iMovieApp (147) — projects, theatre, autosaved drafts
   - Preview (109) — recent docs, annotations metadata
   - podcasts (105) — subscriptions, listening progress
   - finder (100) — sidebar, tags, recent locations, label colors
   - mail (91) — accounts, signatures, mailboxes (combine with `~/Library/Mail/V*` MBOX walking for actual messages)
   - Pages / Numbers / Keynote (72/72/56) — recents, templates, autosaved
   - Photos (57) — combined with the Photos.app SQLite (`~/Pictures/Photos Library.photoslibrary/database/photos.db`) is a goldmine
   - iCal / Calendar (43) — combined with `~/Library/Calendars/` ICS files
3. **Logic Pro** (635 + 522) is by far the largest plist surface but mostly user-prefs not project content; the actual value is `~/Music/Logic/` projects (.logicx bundles).

## Pattern: plist + actual-data combo

Many apps split state between a small "preferences" plist (covered by this probe) and a large data store (SQLite, MBOX, .logicx, .photoslibrary, .icloud, etc.). The plist tells us the app exists and may name the data location; the data store needs its own per-app investigation. So always combine `app-plist-probe` with a hunt for the matching data dir under `~/Library/Application Support/<vendor>/<app>/`, `~/Music/`, `~/Pictures/`, `~/Documents/`, etc.

## How to apply when starting a new exporter

```bash
# 1. Is this app's plist worth mining?
bin/app-plist-probe.py --md --app <name>

# 2. Where does the actual data live?
find ~/Library ~/Pictures ~/Music ~/Documents -maxdepth 3 -iname '*<app>*' 2>/dev/null
mdfind "kMDItemContentType == 'com.apple.<app>.<format>'" | head

# 3. Is there a CLI back-door?
which <obvious-cli> 2>/dev/null
system_profiler -listDataTypes | grep -i <topic>

# 4. Is there a framework back-door?
ls /System/Library/Frameworks/ | grep -i <topic>
```

If any of these turn up structured data, the build template from `tier_5_backdoor_pattern.md` applies.
