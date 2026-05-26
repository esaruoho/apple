---
layout: default
title: "Bulk Exporters: Reminders + Voice Memos + Safari + Stickies + Console + Audio MIDI + Image Capture"
---

# Bulk Exporters: Reminders + Voice Memos + Safari + Stickies + Console + Audio MIDI + Image Capture


[← Back to home](./)
### Meta tool: `bin/app-plist-probe.py`

Scans every Apple-app plist under `~/Library/Containers/com.apple.*/Data/Library/Preferences/` and `~/Library/Preferences/com.apple.*.plist`, decodes top-level keys, recursively unwraps NSKeyedArchiver blobs, and reports which apps have user-extractable data. **Tells us which apps deserve a dedicated exporter without per-app probing.**

Live numbers on this Mac: **1,934 plists across 518 apps; 576 plists across 481 apps have non-trivial user data.** Top hits by interesting-key count: `com.apple.mobilelogic` 635, `com.apple.logic10` 522, `com.apple.Music` 461, `com.apple.Safari` 156, `com.apple.iMovieApp` 147, `com.apple.Preview` 109, `com.apple.podcasts` 105, `com.apple.finder` 100, `com.apple.mail` 91, `com.apple.Pages/Numbers/Keynote` 72/73/56.

Full survey at `dictionaries/all-apps-plist-survey.md` (3,246 lines).

Usage:
```bash
bin/app-plist-probe.py                            # short summary
bin/app-plist-probe.py --md --interesting-only > survey.md
bin/app-plist-probe.py --app voicememos           # one app
bin/app-plist-probe.py --grep tesla               # search values across all plists
```

Two read-only catalog/export packages live at the repo root, mirroring
the `notes-exporter/` and `imessage-exporter/` shape. Both write only into a
user-configurable vault path; never modify Apple's data.

### Exporter SQLite access — use the shared helper

Every Apple SQLite store uses WAL journaling and the owning app typically stays
running. Naive `sqlite3.connect(file:…?mode=ro)` either contends with the
writer, or with `?immutable=1` silently ignores the `-wal` sibling and serves
stale data. **All exporters consult `bin/lib/apple_sqlite_snapshot.py`:**

- `snapshot_open_persistent(path)` — copies `.sqlite + -wal + -shm` to a temp
  dir, opens the copy read-only, registers `atexit` cleanup. Drop-in replacement
  for `sqlite3.connect`. Use for live apps where WAL freshness matters and the
  file is small/medium (≤ ~100 MB): Shortcuts, Notes, Safari, Messages, Calendar.
- `open_immutable(path)` — opens the live file with `?mode=ro&immutable=1`. Fast,
  no copy, but ignores the `-wal`. Use for large files where snapshot cost
  outweighs WAL freshness: Mail Envelope Index (~1 GB), Photos.sqlite (~3 GB),
  or apps the user typically closes before export (Voice Memos).

When adding a new exporter: `sys.path.insert(0, str(ROOT.parent / "bin" / "lib"))`
then `from apple_sqlite_snapshot import snapshot_open_persistent` (or
`open_immutable`). Never write a bare `sqlite3.connect` against an Apple store
— pick the right mode in the helper.

### `mail-exporter/` — Envelope Index SQLite + read-only smart-mailbox surface

- **Catalog side:** SQLite at `~/Library/Mail/V*/MailData/Envelope Index` (~1 GB on a real user's Mac). Open `?mode=ro&immutable=1` via `apple_sqlite_snapshot.open_immutable`. Subcommands: `status`, `mailboxes`, `top-senders`, `subjects --match REGEX`, `search --subject/--sender/--since`, `export --per-mailbox-limit`, `xref --calendar`. Live numbers: 331,867 messages / 181,698 unique subjects / 25 mailboxes on Esa's Mac.
- **Smart-mailbox side (read-only — see the "Mail Smart Mailboxes" section above for why writes don't stick):** Subcommands `smartboxes list / show <name> / dump / export / diff <snap> [--write]`. Reads `SyncedSmartMailboxes.plist` (definitions) + `SmartMailboxesLocalProperties.plist` (per-Mac UI state — sort order, filters, unread count, focus). Decodes the full criterion tree including recursive `Compound` AND/OR groups.
- **Phase 2 omitted on purpose:** `compose`, `mark-read`, `flag`, `smartboxes add-from / remove-from / create` — message-state write actions are in Mail's sdef but message bodies live as `.emlx` files in `~/Library/Mail/V*/<account>/<mailbox>.mbox/Data/...`. Smart-mailbox writes specifically are blocked by Mail's revert-on-launch behaviour (analysis/mail/smart-mailboxes.md).

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

### `stickies-exporter/` — Tier 5 dark, but textutil unlocks it

Stickies has no AppleScript dictionary (`sdef` errors -192), no App Intents, no URL scheme. But each note is a `.rtfd` bundle in the app container, and `textutil` (Apple-native CLI, no install) converts to txt / html / docx / rtf.

Storage: `~/Library/Containers/com.apple.Stickies/Data/Library/Stickies/<UUID>.rtfd/TXT.rtf`

Subcommands (Phase 1, all read-only): `status`, `list [--match REGEX] [--since DATE]`, `cat <selector> [--rtf|--html|--with-meta]`, `export [--include-rtf]` (writes markdown vault to `exported/stickies/<date>__<slug>__<uuid8>.md`).

Selector grammar reused from voice-memos / safari: UUID prefix / title-or-body substring / `#N` / `latest`.

Quirks worth remembering:
- **Sticky background color** (yellow / pink / blue / etc.) is NOT in the rtfd — it's a per-window UI choice in Stickies, set via the Color menu, never persisted to disk.
- **Window position** is also not persisted on disk on this Mac. Stickies derives it from defaults at launch and saves NSWindow restore state somewhere private.
- **Text and link colors** ARE in the rtfd's `\colortbl` (parsed and surfaced in the .md frontmatter).

Phase 2 (omitted): `create`, `append`, `delete`. These need a quit-Stickies-first guard because Stickies overwrites the .rtfd directory on next quit based on its in-memory state — racing the disk-write would lose new notes. Will land with explicit `--write` confirmation when needed.

Live numbers on this Mac: 10 stickies, 18 KB on disk, 393 chars total. Free-energy / archive research stubs (Stubblefield, Bill Beatty, Jeane Manning, Sand Battery, Leedskalnin, Kentucky Water Fuel Museum, etc.) — heavy overlap with the Tesla/Free-Energy archive corpus, candidate for `xref --free-energy` cross-reference.

Detail in `dictionaries/stickies/stickies-extraction-research.md`.

### `console-exporter/` — `log` CLI is the Console.app back-door

Console.app: no sdef, no App Intents, no URL scheme. **The `log` CLI is strictly more powerful than the GUI** — predicate filtering, time windows, signposts, streaming.

Subcommands: `status`, `show --last 1h --process X --subsystem Y --error --match REGEX`, `subsystems --last 6h --top 50` (counts distinct subsystem:category pairs), `diag-list / diag-export` (walks `~/Library/Logs/DiagnosticReports/` + `/Library/Logs/DiagnosticReports/`), `export --last 1h --error --label errors-1h` (saves a timestamped markdown query page to `exported/console/queries/`).

Live numbers: 30 user diagnostic reports, 136 system reports, ~193k log lines per 5 minutes on this Mac.

### `audio-midi-exporter/` — `system_profiler` + MIDI Configurations

Audio MIDI Setup: no sdef, no App Intents. Back-door: `system_profiler SPAudioDataType -xml` and `SPMIDIDataType -xml` for live device state, plus `~/Library/Audio/MIDI Configurations/*.mcfg` for saved Studio layouts.

Subcommands: `status`, `audio [--json]`, `midi [--json]`, `configurations`, `export` (markdown vault with audio.md + midi.md + configurations/ symlinks).

Live on this Mac: 8 audio devices (CalDigit Thunderbolt 3 dock, MacBook Pro Speakers/Mic, Microsoft Teams Audio, LoomAudioDevice, Audio Hijack to Loopback, Aggregate Device), 0 MIDI devices currently connected, 1 saved MIDI config.

Phase 2 (omitted): `set-default-output`, `change-sample-rate`, `watch` (Core Audio notifications observer).

### `image-capture-exporter/` — AVFoundation + system_profiler + Swift

Image Capture: no sdef, no App Intents. Two back-doors:
1. **AVFoundation** via `/usr/bin/swift` for video capture devices — built-in webcam, Continuity Camera, virtual cameras (OBS, Insta360), external USB.
2. **`system_profiler SPUSBDataType`** for connected iOS / iPadOS / Watch devices and USB scanners.

Subcommands: `status`, `cameras [--json]`, `ios-devices`, `scanners`, `prefs` (reads `com.apple.imagecapture.plist`), `snap [--camera SUBSTR] [--out PATH]` (WRITE — captures one JPG via `take_photo.swift`), `export` (full markdown vault).

Two Swift snippets ship in the package:
- `scripts/list_cameras.swift` — emits AVFoundation device list as JSON
- `scripts/take_photo.swift` — single-frame capture session, writes JPG

Live on this Mac: 3 cameras (FaceTime HD Camera, Insta360 Virtual Camera, OBS Virtual Camera), 0 iOS devices, 0 scanners.

Phase 2 (omitted): `download-from-ios` (ImageCaptureCore framework via Objective-C bridging), `watch` (IOKit DAEvents on USB attach/detach), `record-video`, mDNS-discovered network scanners.

### Apps STILL completely dark (Tier 6 unchanged)

Launchpad and Time Machine remain Tier 6 — no scriptable surface, no plist with the data, no CLI back-door comparable to what we have for everything else. (Time Machine has `tmutil` for backup operations, but no API for browsing backup *content*.) Mission Control has been **reclassified from Tier 6 to Tier 5** since `~/Library/Preferences/com.apple.spaces.plist` exposes `SpacesDisplayConfiguration` with the full Monitor → Spaces tree (1.5 KB plist, single-key but rich nested structure).

Live findings on this Mac: 4,769 URL instances → 3,088 unique → 1,391 duplicated. Worst offender: a Renoise Forums root URL in 13 open tabs + 11 iCloud tabs (24 locations, 6,527 history visits). One Google Sheets URL in 8 tabs + 1 pinned + 8 iCloud = 17 places.

Phase 2 (deliberately omitted, awaiting Esa's reorganization decisions): close-tab, move-tab, archive-window-to-bookmarks. The `cloud_tab_close_requests` table in `CloudTabs.db` would propagate close requests to other devices via iCloud — explicitly never written from this tool.

Detail in `dictionaries/safari/safari-extraction-research.md`.
