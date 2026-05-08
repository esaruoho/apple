---
name: apple
description: Product Manager of Automation Technologies — the role Apple eliminated, continued as open-source
domain: global
version: 3.5.0
generated: 2026-04-02T00:00:00Z
tags: [applescript, macos, automation, hardware-controllers, finder, system-events, workflow, sdef, scripting-dictionary, sal-soghoian, data-type-chaining, app-intents, shortcuts, url-schemes, painpoints, thought-multiplier, bbs, ray-browser]
triggers:
  keywords:
    primary: [applescript, apple script, osascript, apple]
    secondary: [loupedeck, streamdeck, contour shuttle, macos automation, finder, system events, activate app, bring to front, sal, what would sal do, wwsd, shortcuts, app intents, siri phrases, painpoint]
---

# Apple Skill

> Product Manager of Automation Technologies — the role Apple eliminated in November 2016, continued as open-source. 66 apps probed across 13 layers, 1,254 Siri phrases, 246 Shortcuts actions, 111 URL schemes, 31 scripting dictionaries. The credo lives on: *"The power of the computer should reside in the hands of the one using it."*

## User Context

- **User**: Esa Juhani Ruoho ([@esaruoho](https://github.com/esaruoho)) — software tester, UI enthusiast, amateur scripter, automation/workflow obsessive, and user experience evaluator
- **OS**: macOS Sequoia (Darwin)
- **Hardware controllers**: Loupedeck Live, Contour Shuttle Pro, Stream Deck, and any programmable controller that can trigger shell commands
- **Use case**: Hardware buttons, keyboard shortcuts, Siri, and CLI all trigger AppleScripts via osascript to launch/activate apps, automate workflows, and optimize the workday

## Boot Protocol

On the first Apple-related turn in a session:

1. Run `python3 bin/sal-archive-status.py --write analysis/sal/current-status.md`
2. Read the generated status from `analysis/sal/current-status.md`
3. Report the current archive state in plain language:
   - recovered download/media totals
   - missing package targets
   - remaining video queue
   - next recommended preservation or curriculum step
4. Treat that generated file as the live Sal archive dashboard for the rest of the session

If the user asks "what's left", "what did we get", "continue", or "boot up Apple skill", refresh the status first unless they clearly only want unrelated scripting help.

## Hardware Controller Integration

Any programmable controller (Loupedeck Live, Stream Deck, Contour Shuttle Pro, etc.) that can run shell commands works with these scripts:

```bash
osascript /path/to/script.scpt
# or inline:
osascript -e 'tell application "Finder" to activate'
# or Shortcuts:
shortcuts run "Shortcut Name"
```

For hardware-triggered scripts:
- **Fast** — no unnecessary delays
- **Reliable** — handle edge cases (app not running, etc.)
- **Single-purpose** — one button = one action

## Apple-Native Only — No Third-Party Dependencies

**Rule for this skill:** every solution uses Apple-shipped technologies only. No Homebrew, no `pip install`, no `npm`, no third-party CLIs (`imagesnap`, `ffmpeg`, etc.). The apple skill is about using Apple to the max.

When a problem looks like it needs an external CLI, write the equivalent in:
- **AppleScript** (with AppleScriptObjC bridge for framework access)
- **Swift one-liner** via `/usr/bin/swift <file.swift>` (interpreter ships with macOS — zero install)
- **`do shell script`** with macOS-native binaries (`mdfind`, `defaults`, `osascript`, `screencapture`, `say`, `diskutil`, `networksetup`, `ioreg`, `system_profiler`, `pmset`, etc.)
- **Shortcuts** + Run AppleScript / Run Shell Script actions

Concrete example (recorded 2026-05-08): `Take My Picture` originally used `imagesnap` (Homebrew) — replaced with `bin/sal-take-photo.swift` running via `/usr/bin/swift`. Native AVFoundation call, no install required.

If a task genuinely cannot be done Apple-native, document why and ask before introducing a dependency.

## AppleScript Best Practices

1. **Activate apps**: Use `tell application "AppName" to activate`
2. **Check if running**: `if application "AppName" is running then`
3. **System Events for UI**: `tell application "System Events"` for keystroke simulation, menu clicks, window manipulation
4. **Error handling**: Wrap risky operations in `try ... on error ... end try`
5. **Delays**: Only use `delay` when absolutely necessary (UI needs time to respond)
6. **Finder operations**: Finder is always running on macOS — just activate it
7. **AppleScript + CLI combo**: Run `osascript script.scpt &` in background from bash — fire and forget
8. **Use scripting dictionaries**: Before writing a script, check `dictionaries/<app>.md` for available commands, classes, and properties
9. **Use `shortcuts run`**: The `shortcuts` CLI bridges AppleScript (depth) to App Intents (width) — Sal's AND not OR

## The Automation Atlas — 10 Tiers

The README is the Automation Atlas — every Apple app tiered by automation depth. Key findings:

### Tier 1: Fully Automatable (AppleScript + Intents + URL schemes)
Mail (10 layers, 164 Siri phrases), Notes (318 Siri phrases, 50 actions — Siri champion), Finder (25 cmds, 67 phrases), Music (31 cmds, 123 phrases), Keynote, Numbers, Pages, Reminders, Shortcuts

### Tier 2: Deep AppleScript, No Intents
System Events (31 cmds, **89 classes** — deepest dictionary), TV, Photos, QuickTime, Logic Pro, iMovie, Terminal, TextEdit, Script Editor, Safari, Calendar, Contacts, Messages, Final Cut Pro, Automator

### Tier 3: Intents But No AppleScript
Freeform (144 phrases), Books (125 phrases), Weather (149 phrases), Maps (17 queries), Preview (35 phrases), Voice Memos (45 phrases), Home, Calculator, App Store, News, Tips

### Tier 4: URL Schemes Only
FaceTime, Passwords, Podcasts, Stocks, Find My, Font Book, Dictionary, Screen Sharing

### Tier 5: Nearly Dark
Activity Monitor, Audio MIDI Setup, Disk Utility, Image Capture, Screenshot, System Settings, Photo Booth, Stickies, Console, Chess, Grapher, VoiceOver Utility, Clock, Migration Assistant

### Tier 6: Completely Dark
Launchpad, Mission Control, Time Machine

### Tier 8: Accessibility API
System Settings panes opened directly via Accessibility API scripting. Scripts in `scripts/workflows/accessibility/`.

### Tier 9: Distributed Notifications
Cross-process notification observation and posting via `NSDistributedNotificationCenter`. System-wide event monitoring.

### Tier 10: IOKit / Hardware
Direct hardware state queries: battery, USB, Bluetooth, audio devices, CPU, memory, disk via `ioreg`, `system_profiler`, and IOKit framework. Scripts in `scripts/workflows/hardware/`.

**Key insight**: Every "dark" app is a GUI wrapper around a CLI tool that's more powerful (diskutil > Disk Utility, screencapture > Screenshot, tmutil > Time Machine, defaults > System Settings).

## Scripting Dictionaries (Domain Knowledge)

**31 apps extracted** to `dictionaries/` via `bin/sdef-extract.py`. Each app has:
- `<app>.yaml` — machine-readable: commands, classes, properties, data types
- `<app>.md` — human-readable: full scripting reference with descriptions
- `<app>-examples.md` — ready-to-use AppleScript snippets
- `<app>-probe.yaml` — 13-layer automation probe (from app-probe.py)
- `<app>-probe.md` — human-readable probe results

**Data type chaining** (`dictionaries/_index.yaml`): maps which apps produce/consume which data types — the Automator patent (US 7,428,535) vision realized as a lookup table.

### Key Chains Discovered
- **Image Events → 7 apps**: Produces `alias`/`file` → feeds into Automator, Logic Pro, Preview, Script Editor, TextEdit, iMovie, System Information
- **System Events → 9 apps**: Produces `file` → feeds into Music, Photos, Keynote, Numbers, Pages, QuickTime, Terminal, Mail, Bluetooth
- **Mail → Mail**: `outgoing message` loops back for mail merge workflows
- **Contacts → Contacts**: `person` type for contact manipulation
- **12 apps produce `document`** → feeds into Keynote, Numbers, Pages, QuickTime
- **System Events** is the universal bridge (89 classes, 31 commands) — it can control ANY app's UI

## App Intelligence Layers (13 Layers via app-probe.py)

`bin/app-probe.py` extracts **13 layers** from every Apple app into `dictionaries/<app>/<app>-probe.yaml`:

| # | Layer | Source | Method |
|---|-------|--------|--------|
| 1 | Scripting Dictionary | App bundle | `sdef` tool |
| 2 | URL Schemes | Info.plist `CFBundleURLTypes` | `plistlib` |
| 3 | Document Types | Info.plist `CFBundleDocumentTypes` | `plistlib` |
| 4 | **App Intents / Siri Phrases** | `Metadata.appintents/extract.actionsdata` | `json.load` |
| 5 | NSServices | Info.plist `NSServices` | `plistlib` |
| 6 | User Activity Types | Info.plist `NSUserActivityTypes` | `plistlib` |
| 7 | Entitlements | App binary | `codesign --entitlements` |
| 8 | Linked Frameworks | App binary | `otool -L` |
| 9 | Spotlight Metadata | Spotlight index | `mdls` |
| 10 | LaunchServices | LS database | `lsregister -dump` (opt-in) |
| 11 | Plugin Extensions | `Contents/PlugIns/*.appex` | Directory scan |
| 12 | Notification Actions | Info.plist `UNUserNotificationCenter` | `plistlib` |
| 13 | CLI Tools | `/usr/bin/*` | Path check |

**66 apps, 378 layer hits, 20 with App Intents, 35 with URL schemes, 32 CLI tools.**

Cross-app index: `dictionaries/_probe-index.yaml` — URL scheme registry, App Intents summary, framework matrix, services map.

## Apple's Automation Architecture — 7 Layers

Discovered through framework analysis:

```
Layer 1: Apple Events / OSA        ← osascript, OSAKit, ScriptingBridge (DEPTH)
Layer 2: Automator                  ← AMWorkflow, AMAction
Layer 3: Intents (legacy, ObjC)     ← INIntent, 14 apps
Layer 4: AppIntents (modern, Swift) ← 82 protocols, 23 apps (WIDTH)
Layer 5: Shortcuts/WorkflowKit      ← Visual composition of Layer 4
Layer 6: Siri/AssistantSchema       ← Natural language routing
Layer 7: Apple Intelligence         ← GenerativeAssistantActions
```

The `shortcuts run` CLI is the bridge: Layer 1 scripts can invoke Layer 4-6 actions.

**160+ private frameworks** power the automation stack internally, including 80+ Siri frameworks, WorkflowKit (Shortcuts engine), ActionKit, and bridge frameworks like `_Photos_AppIntents`.

## Sal Hand-Crafted Conformance — Siri Phrase Rules

**Every Siri phrase MUST be hand-crafted.** No auto-deriving from filenames. The phrase is the user interface — it must sound like something a human would say out loud. This is WWSD Principle 11.

Derived from Sal Soghoian's 251 dictation commands (dictationcommands.com). Full analysis: `analysis/siri-phrase-humanization.md`.

**8 mandatory patterns:**

| # | Pattern | Example |
|---|---------|---------|
| 1 | **Articles** — "the", "a", "my" | "empty **the** trash", "make **a** new folder" |
| 2 | **Question forms for queries** | "**how many** tabs are open", "**what's** playing" |
| 3 | **Conversational verbs** — "make" not "create", "show me" not "list", "turn on" not "toggle" | "**show me** my playlists" |
| 4 | **Deictic context** — "this", "these" for current selection | "archive **this** email", "export **these** photos" |
| 5 | **No app name residue** — the phrase stands alone | "compile this script" not "Editor Compile" |
| 6 | **Prepositions** — "to", "from", "as", "in" | "export this **as** a PDF", "add this **to** favorites" |
| 7 | **Full natural sentences** — not abbreviated labels | "make a new document from the clipboard" not "New From Clipboard" |
| 8 | **Describe outcomes** — what happens, not which menu item | "when was the last backup" not "Machine Latest Backup" |

**Implementation:** `PHRASE_OVERRIDES` dict in `bin/shortcut-gen.py` — 296 entries, one per script. When adding a new workflow script, you MUST add a hand-crafted phrase to this dict. The test: say it out loud. If it sounds like a menu label, rewrite it.

**The generic fallback in `siri_phrase_from_name()` exists only as safety net. It should never be reached for shipped scripts.**

## CLI Tool Intelligence

**16,176 man pages** on macOS. Key automation CLI tools:

| Tool | What It Does |
|------|-------------|
| `shortcuts run/list` | Run any Shortcut from CLI — the bridge to App Intents |
| `osascript` | Execute AppleScript/JXA |
| `defaults` | Read/write any app preference |
| `screencapture` | Programmable screenshots (more flags than the GUI) |
| `mdfind` / `mdls` | Spotlight search + metadata from CLI |
| `mdutil` | Manage Spotlight indexes — check status, enable/disable, rebuild |
| `mdimport` | Force-import files into Spotlight index |
| `lsregister` | Register/unregister apps with LaunchServices |
| `textutil` | Convert between txt, rtf, html, doc, docx |
| `sips` | Scriptable image processing |
| `/usr/libexec/PlistBuddy` | Surgical nested plist editing (deeper than `defaults`) |
| `networksetup` | Full network configuration |
| `tmutil` | Time Machine from CLI |
| `diskutil` | Disk management from CLI |
| `system_profiler` | Full system info as JSON |
| `ioreg` | I/O Registry / hardware tree |

## macOS Installer Download & Bootable USB

Procedure for downloading a full macOS installer (Tahoe / Sequoia / Sonoma) and writing it to a bootable USB **without ever risking the host Mac upgrading itself**.

### Why this is safe
`softwareupdate --fetch-full-installer` writes `Install macOS <Name>.app` to `/Applications/` and stops. macOS does **not** auto-launch installers. Only three actions actually upgrade the host: double-clicking the .app, clicking "Upgrade Now" in System Settings → Software Update, or clicking Install on a banner. The procedure below avoids all three and removes the .app once the USB is written.

### Discovery
```bash
softwareupdate --list-full-installers
```
Lists every installer Apple is currently serving (Title / Version / Size / Build). Pick the version string for `--full-installer-version`.

### Step 1 — Lock down auto-update (defensive, run once)
```bash
sudo softwareupdate --schedule off
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool false
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool false
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool false
sudo defaults write /Library/Preferences/com.apple.commerce AutoUpdate -bool false
sudo defaults write /Library/Preferences/com.apple.commerce AutoUpdateRestartRequired -bool false
```
Belt-and-suspenders: System Settings → General → Software Update → Automatic Updates → ⓘ → toggle all five switches off.

### Step 2 — Download in a new Terminal window with live progress
```bash
osascript -e 'tell application "Terminal" to activate' \
         -e 'tell application "Terminal" to do script "sudo softwareupdate --fetch-full-installer --full-installer-version 26.4.1"'
```
The new window prompts for sudo password, then shows `PercentComplete=NN` updates. ~10–60 minutes depending on connection. Pattern: spawning the long task in Terminal.app via `osascript` so the user can watch — same idiom as `bin/ask` and the dictation flow.

### Step 3 — Verify host did not upgrade
```bash
ls -la "/Applications/Install macOS Tahoe.app"
sw_vers   # must still show YOUR version, not the new one
```

### Step 4 — Erase the USB
USB needs ≥16 GB. Identify it with `diskutil list external` — confirm size and name before erasing. Then:
```bash
diskutil eraseDisk JHFS+ Tahoe GPT /dev/diskN
```
- Format **must** be JHFS+ (Mac OS Extended Journaled), **not** APFS — `createinstallmedia` rejects APFS.
- Scheme **must** be GPT (GUID Partition Map), **not** MBR — required for boot.

### Step 5 — Write installer to USB (new window, watchable)
```bash
osascript -e 'tell application "Terminal" to activate' \
         -e 'tell application "Terminal" to do script "sudo /Applications/Install\\ macOS\\ Tahoe.app/Contents/Resources/createinstallmedia --volume /Volumes/Tahoe --nointeraction"'
```
20–45 minutes. Volume auto-renames from `Tahoe` to `Install macOS Tahoe`.

### Step 6 — Eject and reclaim disk space
```bash
diskutil eject "/Volumes/Install macOS Tahoe"
sudo rm -rf "/Applications/Install macOS Tahoe.app"
```
After this, the only installer on the host lives on the USB. Software Update may still *show* the version as available (it's a current release) but nothing installs without a click.

### Booting the USB on the target Mac
- **Apple Silicon:** Shut down → hold Power until "Loading startup options" appears → pick the USB → Continue.
- **Intel:** Shut down → power on while holding **⌥ Option** → pick the USB.

### Stopping a download mid-fetch
The foreground `softwareupdate --fetch-full-installer` process responds to Ctrl-C in its Terminal window. Background `softwareupdated` daemons (CoreServices + MobileSoftwareUpdate) are normal system helpers, not the user's fetch — leave them alone. After abort, check `ls /Applications/Install\ macOS*.app` — if absent, no partial state to clean up.

### Sal-like principle
Six-phase manual procedure (lockdown → fetch → verify → erase → write → cleanup) collapsed into a runbook. Each step is a single command or a single GUI toggle; nothing in between. The pattern: **identify the dangerous default (auto-upgrade), neutralize it explicitly, then run the safe verb (`fetch-full-installer`), then verify**. Same shape as `spotlight-export.sh` (compile → inject CFBundleIdentifier → codesign → done) — declare intent, neutralize the gotcha, ship.

## Apple ID Credential Recovery & Re-Authentication

How to recover or change an Apple ID password when the user can't remember it, and how to propagate the new password across signed-in devices.

### Three reset paths, fastest first

1. **Change via trusted device (skips 1-hour Account Recovery wait)**
   - iPhone: Settings → [name at top] → Sign-In & Security → Change Password → device passcode → new password
   - Mac: System Settings → [name at top] → Sign-In & Security → Change Password → Mac login password → new password
   - Key insight: requires only the **device passcode**, not the old Apple ID password
   - Try every signed-in device — trust state is per-device, not account-wide. If one device hits the 1-hour wait, another may not

2. **Look up a saved copy in Passwords.app or Keychain Access**
   - Apple does **not** store the Apple ID password as cleartext in Keychain by default — it stores auth tokens. So most Keychain entries (`idmsa.apple.com`, `appleid.apple.com`, `iCloud`) are tokens, not passwords
   - The cleartext is only there if Safari autofill saved it from a sign-in to `appleid.apple.com` or `iCloud.com`
   - Passwords.app: search `apple` / `icloud` → look for "Internet password" type entries
   - Keychain Access (`/System/Applications/Utilities/Keychain Access.app`): login keychain → Passwords category → search `apple`/`icloud`/`idmsa` → double-click → "Show password"
   - Terminal scan (entry names only, no passwords): `security dump-keychain login.keychain | grep -i 'apple\|icloud\|idmsa'`
   - Also check Notes.app, Reminders, browser autofill (Chrome, Firefox, Brave, Arc), and any password manager (1Password, Bitwarden)

3. **Account Recovery (1-hour minimum, can be 1-3 days)**
   - Last resort, only when no trusted device can do path 1 and no saved cleartext exists in path 2

### Triggering iPhone re-auth after a password change

After changing the Apple ID password on one device, other signed-in devices need to accept the new password. The "Verification Required" banner usually appears within a minute, but if it doesn't:

| Trigger | Action |
|---------|--------|
| Banner check | Open Settings — banner appears at the top with "iCloud Sign-In Required" or "Verification Required" |
| App Store | Open App Store → tap profile icon → prompt |
| Media & Purchases | Settings → [name] → Media & Purchases → Sign In → Use Existing Apple ID |
| iCloud toggle | Settings → [name] → iCloud → toggle Photos or iCloud Drive off/on |
| Mail | Pull-to-refresh the iCloud inbox; fetch fails and prompts |
| Messages / FaceTime | Settings → Messages or FaceTime → tap the Apple ID line |
| Airplane mode | Toggle on/off — push services re-handshake, banner appears within ~30 seconds |
| Restart | Power off / on — banner appears on first Settings open |

Heavy fallback: Settings → [name] → Sign Out → re-sign-in. Avoid unless lighter prompts fail — wipes on-device iCloud data and triggers a slow re-download; iMessage history can be lost if iCloud Messages was off.

### Why this lives in the Apple skill

Apple ID credential management is an Apple operating-system surface, same as Spotlight, Software Update, or System Events. The recovery paths intersect with every other layer (Mac login password unlocks Keychain, device passcode unlocks Apple ID change, iCloud services drive the re-auth prompts). This is automation-of-self before automation-of-apps.

## Messages/iMessage Automation

Messages has the **thinnest sdef** — 3 commands: `send`, `login`, `logout`. Write-only by design.

**What works:** Send text/files to participants, list 201 chats, list participants with handles, URL schemes (`imessage://`, `sms://`) open compose window

**What doesn't work:** Read message content, search, delete, react, auto-reply, access history. No App Intents for sending. The only Intent is Focus Mode filtering.

**Workaround:** `~/Library/Messages/chat.db` (SQLite) is readable with Full Disk Access but SIP-protected.

## Bulk Exporters: Reminders + Voice Memos + Safari

Two read-only catalog/export packages live at the repo root, mirroring
the `notes-exporter/` and `imessage-exporter/` shape. Both write only into a
user-configurable vault path; never modify Apple's data.

### `reminders-exporter/`
- AppleScript-driven (Reminders.app has a real sdef).
- Parallel-array fetch (`id of every reminder of theList`) — orders of magnitude faster than `repeat with R in theReminders` and avoids two AppleScript landmines:
  1. `«class isot»` ISO-date coercion **hangs osascript indefinitely** on Reminders objects on macOS 15.6.1 — replaced with manual `((year of d) as text) & "-" & ...` assembly.
  2. `id of <saved-reminder-list-variable>` returns reference list, not strings — must apply `id of` to the freshly-derived `every reminder` expression directly.
- Live numbers on Esa's Mac: 23 lists / 2,547 reminders / 520 active when completed-skipped.

### `voice-memos-exporter/` — Voice Memos has NO scripting dictionary
- `sdef /System/Applications/VoiceMemos.app` returns error -192. Direct SQLite + filesystem reads only.
- DB: `~/Library/Group Containers/group.com.apple.VoiceMemos.shared/Recordings/CloudRecordings.db`. Audio: plain `.m4a` next to it.
- Title gotcha: `ZCUSTOMLABEL` often holds the system default ("New Recording N" / ISO timestamp). User-edited title lives in `ZENCRYPTEDTITLE` (column is misnamed — plaintext) and `ZCUSTOMLABELFORSORTING`.
- Date column `ZDATE` is Cocoa epoch (seconds since 2001-01-01 UTC) — add 978307200 to get Unix epoch.
- Encoder string in m4a metadata identifies the recording device (`com.apple.VoiceMemos (iPad Version 15.6.1 …)` → "iPad", "iPhone", "Mac", or `iOS X.Y`). ffprobe extracts it.

### `tsrp` atom — Apple's auto-generated transcripts ARE on disk

Apple's on-device transcripts (Voice Memos.app → tap Transcribe) are
appended to the m4a file itself in a custom trailer atom:

- **Detection bit**: `ZCLOUDRECORDING.ZFLAGS & 0x08` is set when a transcript exists. Verified across 13 recordings on this Mac (7 from 2026 made on iPad, 6 older). Other ZFLAGS bits observed: `0x04` always set on synced recordings, `0x200`/`0x400` set on iPad recordings (semantics unconfirmed).
- **Storage**: ASCII marker `tsrp` near the end of the .m4a, immediately followed by a JSON object: `{"locale": ..., "attributedString": {"attributeTable": [...], "runs": [...]}}`.
- **Format**: `runs` is a flat array alternating `[text_str, attribute_index, text_str, attribute_index, ...]`. Each `attribute_index` indexes into `attributeTable`, where every entry has `{"timeRange": [start_sec, end_sec]}`. Concatenating even-indexed strings reconstructs full transcript text with per-fragment time alignment.
- **Quality**: Apple's transcript engine on macOS 15.6.1 is **English-only** and performs poorly on Finnish-mixed speech. Use Whisper (`whisp --fi`) for real transcripts — Apple's are kept primarily for inventory and benchmarking.

Implementation: `voice-memos-export transcripts --extract`. Detail in
`dictionaries/voice-memos/voice-memos-extraction-research.md` and
`voice-memos-cli-feasibility.md`. Capability roadmap (search,
diarization, summarize, watch daemon, BBS pipeline) in
`voice-memos-capability-map.md`. Disk-lean operations philosophy
(symlink-only, ~14 MB total vault even after Phase 2 transcribe + index)
in `voice-memos-disk-lean-ops.md`.

### `safari-exporter/` — Safari has a real sdef AND three SQLite stores

Unlike Voice Memos, Safari has a complete AppleScript dictionary AND
exposes its data in three on-disk SQLite databases. The export package
reads them all (`?mode=ro&immutable=1`) without ever touching Safari's
state.

Data sources:
- `~/Library/Containers/com.apple.Safari/Data/Library/Safari/SafariTabs.db` — windows, tab groups, open tabs, bookmarks (all unified in one `bookmarks` table where `type=0` is leaf URL and `type=1` is folder/tab-group)
- `~/Library/Containers/com.apple.Safari/Data/Library/Safari/CloudTabs.db` — tabs synced from other devices via iCloud
- `~/Library/Safari/History.db` — full browsing history

Subcommands: `status`, `windows`, `tabgroups`, `tabs --window/--tabgroup/--match/--domain`, `bookmarks --tree`, `icloud-tabs --device`, `history --last/--since/--match`, `search` (cross-search tabs+bookmarks+history), `export` (full markdown vault).

Vault layout:
```
windows/window-N.md        per window, tabs grouped by tab-group
tabgroups/<slug>.md         per tab group, full tab list with nesting
bookmarks/<topic>.md        per top-level folder, full nested tree
cloud-tabs/<device>.md      per remote device
history/YYYY-MM.md          per month
INDEX.md                    navigation
```

Schema gotchas (codified so future probes don't waste time):

1. `bookmarks` table holds bookmarks AND tab-groups AND open tabs — same table, distinguished only by `type` and `parent`.
2. `windows_tab_groups.tab_group_id = 0` is the synthetic bookmarks root, NOT a real tab group. Including it would pollute window tab counts with 1300+ phantom "tabs". Always `WHERE wtg.tab_group_id != 0`.
3. `cloud_tabs.last_viewed_time` (not `last_modified`).
4. `history_visits.visit_time` (not `last_visit`); compute per-item `last_visit` via `MAX(visit_time)` aggregate.
5. Top-level bookmark folders need filtering: `special_id = 0`, `num_children > 0`, exclude reserved titles (`Private`, `privatePinned`, `recentlyClosed`, `Recovered`, `Local`) — otherwise the index is full of empty system slots.
6. The `bookmark_title_words` table is a free FTS-style word index for title search — already populated by Safari, so search across all 2,800+ bookmarks is fast without building an index.

Live numbers on this Mac (2026-05-08): 6 windows / 2,477 open tabs / 20 tab groups / 2,886 bookmarks / 1,899 iCloud tabs from RayMac+iPhone+CloudcityMacMini / 52,442 history URLs across 147,033 visits. Vault size after `export --with-history --history-days 30`: 2.5 MB; without history: 1.3 MB.

**`dedupe` subcommand** (added 2026-05-08): walks every URL leaf in the Safari archive (open tabs, pinned, bookmarks, iCloud tabs), canonicalises each URL (strips utm_*/fbclid/gclid/mc_cid/igshid/ref tracking params, lowercases host, drops fragment), then writes one `urls/<blake2b12>__<slug>.md` per unique URL. Frontmatter lists every place the URL appears: window + tab group, pinned bookmark folder, iCloud device, history visit count, last-visit date. Plus a `_duplicates.md` ranked by location count.

Live findings on this Mac: 4,769 URL instances → 3,088 unique → 1,391 duplicated. Worst offender: a Renoise Forums root URL in 13 open tabs + 11 iCloud tabs (24 locations, 6,527 history visits). One Google Sheets URL in 8 tabs + 1 pinned + 8 iCloud = 17 places.

Phase 2 (deliberately omitted, awaiting Esa's reorganization decisions): close-tab, move-tab, archive-window-to-bookmarks. The `cloud_tab_close_requests` table in `CloudTabs.db` would propagate close requests to other devices via iCloud — explicitly never written from this tool.

Detail in `dictionaries/safari/safari-extraction-research.md`.

## Sal Soghoian — The Automation Oracle

When triggered by "sal", "what would sal do", or "wwsd", channel Sal Soghoian's philosophy.
Full profile with all quotes: `sal-soghoian.md`

**Core credo**: "The power of the computer should reside in the hands of the one using it."

**His position on Shortcuts**: AND, not OR. Shortcuts = width (every app, every device). AppleScript = depth (every property, every object, every class). Both should coexist. He proposed "AutomationKit" — a cross-platform framework incorporating user automation openness with developer plugins, including an Apple Event bridge.

**Key quotes:**
- "Shortcuts is succeeding in bringing user automation to the masses."
- "Solution apps are great, emojis are fun, but there's nothing like really great automation tools."
- "That goes double for the accessibility community."
- "I'm dreadfully afraid of a future where MacOS is devolved to iOS's state" — John Gruber
- "Automation is a fundamental human concept. We always look for ways to automate stuff." (CCATP #559)
- "Everyone can automate." — his proposed intermediate level between "everyone can code" and just using apps (CCATP #559)
- "AppleScript is so foundational, it can understand the environment that you're in." (CCATP #559)
- "When you stop wanting to learn, then you're just marking time. You join God's waiting room." (CCATP #559)

**Sal's Web Empire** (7+ self-hosted domains, no institutional backing):
macosxautomation.com (hub), iworkautomation.com (Keynote/Numbers/Pages — **last updated Oct 2014, critical risk**), photosautomation.com (Photos), configautomation.com (Apple Configurator), dictationcommands.com (voice commands), omni-automation.com (JavaScript, active), cmddconf.com (conference). Full analysis in `sal-soghoian.md` → "Sal's Web Empire" section. Archive state now lives in `sources/sal/`, `indexes/sal-*.yaml`, and `analysis/sal/current-status.md`, refreshed via `bin/sal-archive-status.py`.

**30 Principles** (WWSD) — full list with sourced quotes in `sal-soghoian.md`. Tier 1 (#13-#27) is sourced to primary spoken-Sal across six transcribed interviews (~155 min) under `sources/sal/transcripts/youtube/`. Tier 2 (#28-#30) is sourced to the **recovered WWDC 2016 session 717 transcript** (`sources/sal/wwdc2016-session-717/717-transcript.txt`, 524 lines). Deep analysis in `analysis/sal/transcripts-analysis.md`, `analysis/sal/transcripts-analysis-pass2.md`, and `analysis/sal/wwdc2016-session-717-transcript-analysis.md`.

**Tier 0 — Retrofit from Sal's site corpus + WIRED 2018:**
1. User comes first — empower, don't create dependency
2. Solve a real problem — every script needs a "why"
3. Keep it local — on-device, protect data, avoid the food chain
4. Make it readable — English-like syntax is a feature
5. Build incrementally — start working, then expand
6. Use the whole toolkit — AppleScript + shell + System Events + Automator + Shortcuts
7. Think in workflows — data producers → transformers → consumers
8. Tell apps what, not how — use scripting dictionaries
9. Educate and share — community grows through generosity
10. Never give up on automation
11. **Name commands like speech, not labels** — the phrase IS the interface (251 hand-crafted dictationcommands.com phrases)
12. **Sit in the hallway** — institutions don't give your work an audience; Sal camped 10am–5pm to ambush Jobs

**Tier 1 — Sourced to spoken Sal (interviews 2012–2023):**
13. **Attachment is the universal trigger** — *"plug it in, something happens"* (MTC2019)
14. **Insight = Perspective × Time** — Sal's explicit method (MTC2019)
15. **The boring trajectory is the strategic one** — appliance > personal-device cool factor (MTC2019)
16. **Primitives compose; rewrites don't** — AppleScript→Automator→Configurator→APU share substrate
17. **Bet-the-farm on the awakening** — drop everything when the box turns blue (TWiT 2018)
18. **Teach the makers** — Apple recruited Sal because he was teaching at trade shows the Apple staff attended (TWiT 2018)
19. **Make them come to you** — said no for a year, joined on his terms (TWiT 2018)
20. **The institution is not the relationship** — friendship survives the org chart (MTC2019)
21. **Observer + Participant simultaneously** — replaces left-brain/right-brain framing (ProGuide 2023)
22. **Forward Motion with a paddle** — can't undo, can adjust (ProGuide 2023)
23. **The Carpenter Move — look for the underlying principle** — sourced to Sal's master-carpenter father (MacVoices 2017 + ProGuide 2023, two independent transcripts)
24. **Bill on outcome, not on hours** — AT&T $3,000 / 10-minute script (ProGuide 2023)
25. **Speak the receiver's language** — Patton-themed midnight email to Steve Jobs won AppleScript its peer-development-language status (ProGuide 2023)
26. **Pay in what cash can't buy** — Lego Millennium Falcon kits to engineers who refused cash (ProGuide 2023)
27. **Authorization is the bridge between conflicting principles** — user-installed scripts resolved automation-vs-security (ProGuide 2023)

**Tier 2 — Sourced to recovered WWDC 2016 session 717 (Beyond Dictation: Enhanced Voice Control for macOS Apps), 2026-05-07:**
28. **Procedural vs task-oriented commands** — *"It's like describing how to make a peanut butter sandwich. You hold the jar with this hand, you turn the top this way."* (line 132). User commands name the **task**, not the steps. A task-oriented command is a self-multiplying primitive; a procedural one has to be re-expanded every invocation. (session 717, lines 132–138, 250–253)
29. **Voice is a peer modality to touch, keys, and cursor** — *"speech is no longer just an assistive technology. And now voice is a peer to touch keys and cursor."* (line 515). Voice is a fourth fundamental input on equal footing with the others — not text entry, not assistive — and **only on the Mac** can users program it themselves via AppleScript / Automator / JavaScript. This positioning sentence is the most likely trigger for the session pull. (session 717, lines 512–519)
30. **The seven-purpose framework — when to build a voice command** — Sal's closing decision tool: build a voice command when a workflow scores 3+ on these criteria: (1) need to remain in context, (2) multi-step (≥3 manual steps), (3) requires dexterity, (4) moves data between apps, (5) transforms data type, (6) does something not in the app's UI, (7) does something the user wants but doesn't know how. (session 717, lines 480–504)

**Recognition rule (companion to all 30):** Listen for the trigger phrases — *"there's got to be a better way"* and *"I don't want to do this."* Each utterance is a script that hasn't been written yet (MacVoices 2017).

**Primary sources captured in sal-soghoian.md:**
- Full FAQ from macosxautomation.com/about.html (November 2016)
- MacStories manifesto: "App Extensions Are Not a Replacement for User Automation" (January 2017)
- **Chit Chat Across the Pond #559** (August 13, 2018) — Sal + Ray Robertson interview. Berklee details, "sinking ship" origin story, "automation is a fundamental human concept," "everyone can automate," Siri Shortcuts architecture, environmental awareness quote, Ray Robertson profile. Transcript: `~/work/whisp/CCATP_2018_08_13.txt`
- Omni Show: Shortcuts as "component automation" (October 2021)
- Rebooting interview: "Shortcuts is just beginning to reach its potential" (2023-24)
- Community reactions: Gruber, Snell, Cheeseman, Gotow, Weatherhead
- **Future work**: Scrape @macautomation Twitter/X feed for years of automation tips and commentary, archive iWorkAutomation.com (Sal's own reference site)

## Vocal Shortcuts (macOS 15 Sequoia, Apple Silicon)

`bin/list-vocal-shortcuts.py` reads the user's Vocal Shortcuts entries.

**Storage location** (reverse-engineered 2026-05-07 from a live entry):
`~/Library/Preferences/com.apple.Accessibility.plist` → key `AVSPreferenceKey` → bytes containing UTF-8 JSON array.

**Each entry shape:**
```json
{"name": "where is olga",
 "associatedShortcut": {"name": "Find Olga",
   "type": {"siriShortcut": {"id": "<Shortcut UUID from Shortcuts.app>"}},
   "id": "<internal id>"},
 "identifier": "<entry UUID>"}
```

**Trigger surface position:** Vocal Shortcuts is the Sequoia replacement for Sal's pre-2017 Custom Commands plist runtime (which Apple removed). It is now the canonical voice-trigger layer for the 588 CitrusPeel commands and the 73 triple-channel-eligible workflows from the Sal seven-purpose audit (WWSD #30). Vocal Shortcuts can ONLY trigger Shortcuts (or Siri Requests / Accessibility primitives), not arbitrary AppleScript — so the wiring is always: spoken phrase → Vocal Shortcut → Shortcut → Run AppleScript action → DC-XXX library handler.

**Read** is verified working. **Write** programmatically is theoretical — the daemon reads the plist but each phrase requires manual user training (saying it 3x). UI scripting via `bin/vocal-shortcuts-ui-import.applescript` is the practical write path.

Full schema documentation: `analysis/sal/vocal-shortcuts-storage-format.md`. Apple Silicon only — Vocal Shortcuts is unavailable on Intel Macs.

## HomePod Climate Sensor

`homepod/` — reads HomePod temperature/humidity via `shortcuts run "HomePod Sensors"`, logs to JSONL, serves live dashboard on port 3007. Calibrated +0.45C temp, +4.5% humidity. LaunchAgent runs every 10 min. Pattern: HomeKit sensor → Shortcuts → CLI → bash → structured data.

## Esa's Bash Profile — macOS Patterns

See `bash-aliases.md` for Apple-native aliases extracted from `~/.bash_profile`.
Key pattern: `osascript script.scpt &` — fire-and-forget AppleScript from bash (used in `ask()` function).

## Public/Private Split

**Public** (pushed to GitHub `esaruoho/apple`):
- README.md, skill.md, scripts/, dictionaries/, bin/, patents/, sal-soghoian.md, scripts.md

**Private** (gitignored, local only):
- bash-aliases.md, whiteboards/, icons/
- retained Sal media under `sources/sal/**/*.mp4`, `*.m4v`, `*.mov`, `*.mp3`, `*.m4a`

## Sal Archive Operations

Use the repo's archive tooling instead of ad hoc summaries:

- `python3 bin/sal-archive-status.py --write analysis/sal/current-status.md`
  Refreshes the live archive dashboard and remaining-work list.
- `python3 bin/sal-index-download-targets.py`
  Rebuilds the machine-readable download/media target index from the mirrored pages.
- `python3 bin/sal-recover-downloads.py --site macosxautomation.com --asset-type zip --strategy live-direct --mark-failures`
  Recovers missing bundles with live fetch first and Wayback fallback.

Rules:

- Do not claim a site is "done" unless the generated status says the missing queue is zero or the remaining gaps are explicitly documented.
- Keep `.failed` markers for dead URLs so the archive remains honest.
- Keep large recovered media local-only for later transcription rather than pushing them into git history.

## Whiteboards Generated

34 whiteboards across 5 sets in `whiteboards/`:

| Set | Boards | Topic |
|-----|--------|-------|
| `bash-aliases/` | 5 | macOS bash patterns, osascript integration |
| `automation-atlas/` | 5 | Full scriptability map, CLI tools |
| `sal-soghoian/` | 4 | Sal's career, philosophy, WWSD |
| `sdef-deep-dive/` | 10 | Atlas deep dive: all 4 tiers, CLI tools, terminal automation |
| `sdef-understanding/` | 10 | How Sal connected every app: sdef architecture, data type chains, narrative |

## Loupedeck Window Management — Native Window Snapping

No Magnet, no Rectangle — pure System Events + NSScreen. Physical controls for window tiling.

**Scripts:** `scripts/workflows/system-events/` (source `.applescript`) + `compiled/` (`.scpt` for Loupedeck)

| Control | File | Subroutine | Action |
|---------|------|------------|--------|
| **Button** | `HideAllOthers.scpt` | — | Hide all other apps (native, bypasses menu bar) |
| **Button** | `MosaicWindows.scpt` | — | Tile all frontmost app windows into auto-grid |
| **Knob ↻** | `MosaicKnob.scpt` | `more` | Show one more window, retile grid |
| **Knob ↺** | `MosaicKnob.scpt` | `less` | Show one fewer window, retile grid |

**Workflow:** Hide All Others (focus on one app) → turn knob to dial in how many windows you see. Physical focus control.

**Key design decisions:**
- **Valid steps only**: 1→2→3→4→6→8→9→12→16 — skips counts that leave empty grid cells
- **Explicit layouts for 1-4**: 1=full, 2=side-by-side columns, 3=three columns, 4=2x2 grid. Only 6+ uses ratio optimizer.
- **Always main screen**: uses `NSScreen.main` (keyboard focus screen). No multi-monitor detection — it was unreliable and sent windows to wrong screens.
- **Screen-aware filtering**: only tiles windows already on the main screen — won't pull windows from other screens. Checks each window's position against screen bounds with 10px tolerance.
- **No window hiding**: excess windows left untouched. No minimize, no off-screen moves. Just tile the first N.
- **Two-pass tiling**: resize all first, then position (prevents Safari overlap)
- **Loupedeck subroutines**: one `.scpt` with `on more()` / `on less()` handlers — Loupedeck calls the right one per knob direction

**AppleScript gotchas solved:**
- `use framework "AppKit"` inside handlers breaks `osacompile` → use `do shell script "swift -e '...'"` for NSScreen
- AppleScript `word` eats hyphens → comma delimiters + `text item delimiters` for negative coords
- Safari auto-adjusts position after resize → resize first pass, position second pass

**Design lessons (earned the hard way):**
- Multi-monitor coordinate flipping is fragile — `NSScreen.main` is simple and correct
- Never hide/minimize windows the user didn't ask to hide — just tile fewer, leave the rest
- Ratio optimizer picks wrong layouts for small counts (stacked instead of side-by-side) — use explicit layouts
- Simple beats clever: the final version is shorter and works better than the "smart" one
- Counting all process windows pulls off-screen windows onto the main screen — filter by position first

## Loupedeck Whiteboard Browser — 2,684 Boards on a Knob

Browse every whiteboard across `~/work/` and `~/.claude/skills/` with a physical knob. No dialogs, no picking — press Browse to load all 2,684 PNGs into a flat list, then turn the knob to scroll.

**Scripts:** `scripts/workflows/system-events/` (source `.applescript`) + `compiled/` (`.scpt` for Loupedeck)

| Control | File | Subroutine | Action |
|---------|------|------------|--------|
| **Button** | `WhiteboardKnob.scpt` | `browse` | Scan all whiteboards, load flat list, show first |
| **Knob ↻** | `WhiteboardKnob.scpt` | `next` | Next board (wraps around) |
| **Knob ↺** | `WhiteboardKnob.scpt` | `prev` | Previous board (wraps around) |
| **Knob press** | `WhiteboardKnob.scpt` | `open` | Open current board in Preview |

**Alternative wiring** (wrapper scripts, no subroutine needed): `WhiteboardBrowse.scpt`, `WhiteboardNext.scpt`, `WhiteboardPrev.scpt`, `WhiteboardOpen.scpt`

**State files:**
- `/tmp/whiteboard-knob-files` — flat sorted list of all PNG paths (one per line)
- `/tmp/whiteboard-knob-index` — current position (1-based)
- `/tmp/whiteboard-knob-current` — current PNG path (bridge for external consumers)

**Design decisions:**
- Flat list over folder picker — 2,684 boards scrollable without dialogs
- `sed -n` for random access into the file list (no loading entire list into AppleScript)
- macOS notification on every turn shows `WhiteboardKnob 42/2684` — always know where you are
- Wrap-around navigation — board 1 after last, last before board 1

**Loupedeck wiring (critical):** Use **Custom → AppleScript** in Loupedeck action search. NOT Custom → Run (that opens Script Editor). The dialog has three fields: file path, subroutine, arguments.

## Sal-Like Tools

Tools in this repo that follow Sal's philosophy: one action, one result.

| Tool | Command | What it does |
|------|---------|-------------|
| `ghc` | `ghc owner/repo` | Clone a GitHub repo + launch Claude Code + generate a permanent project skill. 7 steps → 1. |
| `ask` | `ask` | Launch Claude Code + trigger macOS dictation simultaneously. AppleScript + CLI fusion. |
| `app-probe` | `python3 bin/app-probe.py` | Extract 13 automation layers from 66 apps in 60 seconds. |
| `sdef-extract` | `python3 bin/sdef-extract.py` | Extract scripting dictionaries for 31 apps. |
| `workflow-gen` | `python3 bin/workflow-gen.py` | Generate 288 workflow scripts from curated recipes across 31 apps. |
| `spotlight-export` | `./bin/spotlight-export.sh` | Compile workflows to .app bundles in /Applications/ — Spotlight-reachable. |
| `shortcut-gen` | `python3 bin/shortcut-gen.py` | Generate signed .shortcut files for Siri/Spotlight/Shortcuts app. |
| `auto-gen` | `python3 bin/auto-gen.py` | Auto-generate 121 scripts from YAML dictionaries. |
| `batch-import` | `bin/batch-import.sh` | Import all shortcuts into Shortcuts.app with folder organization. |
| `extract-icons` | `./bin/extract-icons.sh` | Extract 64 app icons as PNG for Loupedeck buttons. |
| `github-watcher` | `github-watcher.sh` | PR & CI awareness bot — polls repos, macOS notifications on changes. LaunchAgent. |
| `prwhy` | `prwhy.py` | Strategic PR viewer — PRs grouped by project pillar with the WHY. |
| `props` | `props` / `props 2373` | PR Operations TUI — curses triage with CI polling, rebase, build, conflict→Claude handoff. |
| `prbuild` | `prbuild` / `prbuild 2373` | Trigger Mac DMG builds, watch progress, download when done. 9 steps → 1. |
| `ghd` | `ghd` | Open GitHub Watcher dashboard (localhost:3008). |
| `slideshow` | `python3 bin/slideshow.py /path` | Fullscreen slideshow on any screen. Folder → presentation. One command. |

## Slideshow — Folder → Fullscreen Presentation

**Underlying principle:** A folder of images is a presentation waiting to happen. Any folder, any screen, sequential or random. The same seed as WhiteboardKnob (folder → browse images) but unattended — auto-advance instead of manual knob control.

```bash
python3 bin/slideshow.py /path/to/images              # sequential on secondary screen
python3 bin/slideshow.py --shuffle /path/to/images     # random order
python3 bin/slideshow.py --interval 3 /path            # 3 seconds per slide
python3 bin/slideshow.py --screen 0 /path              # force main screen
python3 bin/slideshow.py                               # folder picker dialog
```

**Controls:** Escape/Q=quit, Right/Space=next, Left=prev, P=pause (counter turns orange)

**Architecture:** Python + Pillow + tkinter. Swift one-liner detects all screens via `NSScreen`. No Preview, no Finder, no permissions issues — Python reads files directly.

**Pattern relationship:**
- **WhiteboardKnob** = manual browse (Loupedeck knob, one image at a time, user-paced)
- **Slideshow** = unattended display (auto-advance, any screen, ambient)
- Same input (folder of images), different interaction model. The folder is the data; the tool is the lens.

**Wrapper scripts:** Any project can create a thin shell wrapper that calls `slideshow.py` with a hardcoded folder. The tool stays generic; the wrapper carries the context.

## GitHub Watcher — PR & CI Awareness

`github-watcher/` — monitors open-source repos for PR and CI changes, sends macOS notifications, serves a live dashboard.

**Architecture** (same pattern as HomePod climate sensor):
```
gh CLI (poll) → JSON state files (diff) → display notification (alert) → Python server (dashboard)
```

**Components:**

| File | Purpose |
|------|---------|
| `github-watcher.sh` | Poller — runs every 10 min via LaunchAgent, diffs state, sends notifications |
| `dashboard-server.py` | Web dashboard on port 3008 — two-column grid, grouped by project |
| `dashboard.html` | Dashboard UI — auto-refreshes every 60s, links to GitHub |
| `prwhy.py` | Strategic PR viewer — groups PRs by project-specific pillars |
| `props.py` | PR Operations TUI — curses list/detail/action views with inline triage, rebase, builds, conflict→Claude |
| `prbuild.py` | Mac DMG build trigger — fzf picker, watch run, extract DMG name, download |
| `repos.json` | Single config file — add/remove repos here, both watcher and dashboard read it |
| `com.esa.github-watcher.plist` | LaunchAgent for poller (every 10 min) |
| `com.esa.github-dashboard.plist` | LaunchAgent for dashboard server (KeepAlive) |

**Per-project strategic pillars** (used by `prwhy`):

| Project | Pillars |
|---------|---------|
| Apple | Automation, Probing, Tools, Documentation |
| Paketti | Workflow, Instruments, Import/Export, UI, Bug Fixes |
| CircuitJS1 | Simulation Accuracy, New Components, Visual/UX, Import/Export, Example Circuits, Bug Fixes |
| LENR Academy | Content, Discovery, UI/UX, Infrastructure |

**Notifications sent on:** new PR opened, PR closed/merged, CI run failed, CI run recovered.

## Spotlight Integration — The Final Sal Mile

Every workflow script can be compiled to a Spotlight-reachable `.app` via `osacompile`. Full guide: `spotlight-automation.md`.

**5 paths to Spotlight:**

| # | Method | Best For | How |
|---|--------|----------|-----|
| 1 | `osacompile` to .app | AppleScripts (our workflows) | `osacompile -o ~/Applications/X.app script.applescript` |
| 2 | Shortcuts | App Intents width | Create Shortcut with "Run AppleScript" action |
| 3 | Automator Quick Actions | Context-dependent (selected files/text) | Save to `~/Library/Services/` |
| 4 | Automator Application | Multi-action pipelines | Save as .app to `~/Applications/` |
| 5 | Shell wrapper | CLI tools (ghc, ask, etc.) | `osacompile -o X.app -e 'do shell script "cmd"'` |

**Pipeline:** `sdef-extract.py` (extract) → `workflow-gen.py` (generate) → `spotlight-export.sh` (export to Spotlight)

```bash
# Export all 288 workflows as Spotlight-reachable apps
./bin/spotlight-export.sh

# Then: Cmd+Space → "Music PlayPause" → Enter
```

**Critical `osacompile` gotcha:** Apps compiled with `osacompile` have NO `CFBundleIdentifier` in their `Info.plist`. Without a bundle ID, Spotlight ignores them. `spotlight-export.sh` injects one via PlistBuddy.

**APFS Spotlight bug:** On APFS Macs, `/Applications/` lives on the Data volume (`/System/Volumes/Data`). If indexing is disabled on that volume, Spotlight can't find ANY installed apps — only system apps in `/System/Applications/`. Diagnose with `mdutil -sa`. Fix with `sudo mdutil -i on /System/Volumes/Data && sudo mdutil -E /System/Volumes/Data`. Full troubleshooting guide in `spotlight-automation.md`.

**14 Apple apps use CoreSpotlight framework** for content indexing: App Store, Books, Calendar, Freeform, Mail, Maps, News, Notes, Photos, Podcasts, Reminders, System Settings, Tips, Voice Memos.

## Patents

| Patent | Title | Relevance |
|--------|-------|-----------|
| US 7,428,535 B1 | Automatic Relevance Filtering | The Automator patent — context-aware action filtering, data type bridging, modular workflows |

Full analysis: `patents/US7428535-analysis.md`

## Knowledge Files

| File | Purpose |
|------|---------|
| `skill.md` | This file — skill definition + knowledge base (public) |
| `README.md` | **The Automation Atlas** — 66 apps tiered by automation depth |
| `sal-soghoian.md` | **Sal Soghoian knowledge base** — full profile, quotes, Shortcuts position, community reactions, @macautomation scraping plan |
| `spotlight-automation.md` | **Spotlight integration guide** — 5 paths to make scripts Cmd+Space reachable |
| `scripts.md` | Catalog of all AppleScripts (64 launchers + 288 workflows = 273 scripts) |
| `scripts/launchers/` | 64 app launcher scripts (every Apple app + utility) |
| `scripts/workflows/` | **288 workflow scripts** across 31 apps — the action layer |
| `dictionaries/` | **31 scripting dictionaries + 66 probe files** |
| `dictionaries/_index.yaml` | Data type chaining index — cross-app workflow compatibility |
| `dictionaries/_probe-index.yaml` | 13-layer probe index — URL schemes, App Intents, frameworks, services |
| `bin/app-probe.py` | 13-layer automation probe |
| `bin/sdef-extract.py` | Scripting dictionary extractor |
| `bin/workflow-gen.py` | Workflow script generator (288 recipes across 31 apps) |
| `bin/spotlight-export.sh` | Compile workflows to Spotlight-reachable .app bundles |
| `bin/extract-icons.sh` | App icon extractor for Loupedeck |
| `bin/ghc` | GitHub Clone + Claude skill generator |
| `bin/ask` | Voice dictation + Claude launcher |
| `patents/` | Apple automation patents and analyses |
| `icons/` | 64 app icons as 256x256 PNG (gitignored, regenerable) |
| `whiteboards/` | 34 visual educational whiteboards (gitignored) |

## Core Principle: Pattern Reusability

**If you can identify a pattern of manual labour, and organize it, then that pattern becomes an underlying principle — which allows for any other reorganization of the pattern.**

This is the deepest lesson from this project. Every tool here proves it:

1. **HomePod climate** identified the pattern: periodic poll → state diff → notification → dashboard. That's manual labour (checking the thermometer) organized into a principle (LaunchAgent + bash + JSON state + Python server).

2. **GitHub Watcher** reused the exact same principle for a completely different domain. The pattern didn't care whether it was reading temperature or PRs. The underlying structure — poll, diff, notify, display — transferred wholesale.

3. **prwhy** added a layer: the same PR data, reorganized by *strategic meaning* instead of chronology. Same input, different principle applied, different insight produced.

4. **The sdef pipeline** is the same thing at a different scale: `sdef-extract` (poll apps) → `workflow-gen` (organize into recipes) → `spotlight-export` (make reachable) → `shortcut-gen` (make triggerable). Each step is a reorganization of what the previous step produced.

5. **props** extended the pattern from passive monitoring to active triage. Same PR data, but now you can act on it — rebase, build, merge — without leaving the terminal. And when it hits a wall (merge conflicts), it hands off to Claude Code with full context. The pattern scaled from "watch and notify" to "watch, triage, act, and delegate" without breaking the underlying architecture.

This is what Sal understood intuitively. Automator's patent (US 7,428,535) is literally about this: actions that produce typed data, fed into actions that consume it, with automatic relevance filtering. The pattern is: **identify the manual step → extract the principle → apply it everywhere.**

The practical test: when you build something, ask "what is the underlying pattern here, and where else could it apply?" If the answer is "only here," you've built a script. If the answer is "anywhere there's periodic state to watch," you've built a principle.

## Self-Learning Behavior

**This skill is self-updating.** Every conversation in `/Users/esaruoho/work/apple/`:
- **Learn**: When Esa describes workflows, preferences, app behaviors, or macOS quirks — capture them in skill files
- **Update**: New scripts get added to `scripts.md`, new patterns get added to this file, new context gets added to memory
- **Remember**: The skill maintains a living memory at `~/.claude/projects/-Users-esaruoho-work-apple/memory/MEMORY.md`
- **Grow**: Over time this skill accumulates deep knowledge of Esa's exact macOS setup, apps, workflows, and automation needs
- **Push**: All knowledge goes to GitHub `esaruoho/apple` so nothing is lost

When Esa tells you something new about his setup, apps, or preferences — **write it down immediately**. Don't wait to be asked.

## Whiteboard Integration

The Apple skill uses the **BBS Whiteboard skill** (`~/.claude/skills/whiteboard/`) to generate visual educational whiteboards. When Esa asks for whiteboards in this workspace:

```bash
~/.claude/skills/whiteboard/bin/whiteboard-generate.sh --full --count N --text "content"
```

Output goes to `/Users/esaruoho/work/apple/whiteboards/`

## App Icon Extraction

When Esa says "gimme logo of Photos" or "icon for Mail":

1. **Single icon:** `./bin/extract-icons.sh --app Photos --open`
2. **All icons:** `./bin/extract-icons.sh --open`
3. **Custom size:** `./bin/extract-icons.sh --size 512`

Icons are 256x256 PNG by default — ideal for Loupedeck Live button icons.

## iCloud.com URL Shortcuts

Direct-access subdomains for iCloud services (as of March 2023). Useful for automation workflows that open specific iCloud apps in a browser.

**Working:**
| URL | Redirects to |
|-----|-------------|
| `reminders.icloud.com` | `icloud.com/#reminders` |
| `notes.icloud.com` | `icloud.com/#notes2` |
| `mail.icloud.com` | `icloud.com/#mail` |
| `calendar.icloud.com` | `icloud.com/#calendar` |
| `photos.icloud.com` | `icloud.com/#photos` |
| `iclouddrive.icloud.com` / `drive.icloud.com` | `icloud.com/#iclouddrive` |
| `find.icloud.com` | `icloud.com/#find` (extra password prompt) |
| `keynote.icloud.com` | `icloud.com/#keynote` |
| `pages.icloud.com` | `icloud.com/#pages` |
| `numbers.icloud.com` | `icloud.com/#numbers` |
| `contacts.icloud.com` | `icloud.com/#contacts` |
| `settings.icloud.com` | `icloud.com/#settings` |

**Not working (as of 2023):** `fmf.icloud.com`, `findmyfriends.icloud.com`

Source: [Esa's Medium article (2016, updated 2023)](https://esaruoho.medium.com/apples-icloud-services-quick-urls-and-future-improvements-67256b841809)

## Thought Multiplier

Type once, radiate to many, catch every rebound. A system built inside Ray Browser that turns a single typed thought into multiple simultaneous outputs.

### Architecture

```
Layer 1: SEED CAPTURE -----> Studio app (pinned tab, text field)
Layer 2: THE FORK ----------> Agent Scripter pipeline (5 parallel branches)
Layer 3: DESTINATIONS ------> Archive, LLM, Browser, Email, Graph
Layer 4: REBOUND CAPTURE ---> Dashboard showing all branch outputs
Layer 5: SELF-UPDATING -----> Studio versioning (conversational refinement)
```

### Files

| File | Purpose |
|------|---------|
| `thought-multiplier/architecture.md` | Full architecture document |
| `thought-multiplier/studio-prompts.md` | Exact prompts to paste into Ray Studio |
| `thought-multiplier/agent-scripter-pipeline.md` | Agent Scripter JSON pipeline specs |
| `thought-multiplier/archive-schema.md` | JSONL archive format specification |
| `thought-multiplier/studio-apps/seed-capture.html` | Seed Capture Studio app (Phase 1) |
| `thought-multiplier/studio-apps/rebound-dashboard.html` | Rebound Dashboard (Phase 5) |
| `thought-multiplier/studio-apps/graph-viewer.html` | Thought Graph visualization (Phase 4) |
| `bin/thought-archive.py` | CLI archive manager (stats, search, add, export) |

### Three Lineages

- **Sal Soghoian**: Data type chaining, one-input parallel pipelines, user-first power
- **Walter Russell (RBI)**: Self-Multiplication (P2), Rebound (P3), Dead Centers (P5)
- **BBS/Cloudcity**: The operating system that replaces siloed internet — this IS the BBS ingest surface

### Why Only Ray Browser

AI Agent (18 tools) + Agent Scripter (visual pipelines) + Studio (app factory) + Phi-4 (local LLM) + BGE embeddings + Chat with Tabs + Studio versioning + Privacy screening. No other browser has even three of these.

## Patterns Catalog

See `scripts.md` for the growing catalog of AppleScripts created for Loupedeck Live buttons.
