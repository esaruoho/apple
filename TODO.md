# Apple Repo TODO

Working state. Cross items off as they land. Updated 2026-05-11.

---

## Session 2026-05-11 — Vocal Shortcuts coverage tooling + WAL helper

**Shipped:**
- `bin/lib/apple_sqlite_snapshot.py` — WAL-safe snapshot helper; 7 exporters refactored
- `bin/vocal-shortcuts-suggest.py` — orphans/drift/suggestions report + `--fix-drift`
- `bin/vocal-shortcuts-router-verify.py` — confirms 38/39 audit-matched candidates route through Hey Sal
- `bin/capture-vocal-shortcut-schemas.py` — interactive helper for the two unobserved action kinds
- 6 findings codified in `analysis/sal/vocal-shortcuts-session-findings-2026-05-11.md`
- Trigger-stack comparative analysis in `analysis/sal/vocal-shortcuts-in-the-trigger-stack.md`

### Open from this session — execute next

- [ ] **Run `bin/capture-vocal-shortcut-schemas.py`** — 5-min interactive session in front of System Settings to lock down `siriRequest` + `accessibility` JSON shapes. Updates `analysis/sal/vocal-shortcuts-storage-format.md` once both shapes captured.
- [x] **Fixed matcher bug: "show me hide dock" → wrong target.** Root cause: "show" + "hide" both scored as content words → tie → arbitrary winner. Fix: added 10-entry `COMMAND_PREFIXES` table and `strip_command_prefix()`; when the utterance opens with one ("show me", "run", "do", "tell me", etc.) we score only the stripped form, so prefix verbs no longer contaminate overlap. Added "me" + "i" to `STOPWORDS`. Router-verify now reports **39/39 full-match, 0 partial**.
- [ ] **Execute the daemon-reload probe** (`analysis/sal/vocal-shortcuts-daemon-reload-probe.md`). 3-terminal procedure; ~15 min. Result: identify the signal System Settings fires on Vocal Shortcut add/edit/delete.
- [ ] **Execute the plist-write-firing test** (`analysis/sal/vocal-shortcuts-plist-write-firing-test.md`). `bin/avs-prefs-write.py` built 2026-05-11; helper has list/dump/backup/restore/remove-id/add/reload-cfprefsd/kick-daemons subcommands with auto-timestamped backups on every write. 6-step manual experiment remaining.
- [ ] **Bind 5 top router-verified candidates through Hey Sal** — pick from the 38 full-match candidates by Sal-purpose score; verify each runs cleanly end-to-end via voice. No new training needed.

---

## Session 2026-05-08 — bulk exporter family + Hey Sal v0

**Shipped today (21 user-runnable tools):**
- 15 `<name>-exporter` packages: notes / imessage / reminders / voice-memos / safari / stickies / console / audio-midi / image-capture / calendar / finder / music / mail / photos / iwork
- 5 cross-package bin/ tools: `apple-grand-search`, `apple-grand-export`, `hey-sal`, `apple-summarize`, `apple-bootstrap`
- 1 meta tool: `bin/app-plist-probe.py` (1,934 plists across 518 apps surveyed)
- 6 Loupedeck reference scripts under `scripts/exporter-loupedeck/`
- The `tsrp`-atom discovery for Apple's auto-transcripts in Voice Memos
- Mission Control reclassified Tier 6 → Tier 5
- The Tier 5 dark **three back-door pattern** codified (CLI / Swift / plist+textutil)
- Sal email draft at `analysis/sal/correspondence/2026-05-08-sal-status-update-draft.md`
- WWSD walk-through at `analysis/sal/wwsd-applied-2026-05-08.md`

### Open from this session — finish next

- [ ] **Send the Sal email** — draft is ready in `analysis/sal/correspondence/2026-05-08-sal-status-update-draft.md`. Trim to ~300 words before sending. Subject line options included. Same Gmail thread as the April exchange.
- [x] **Backported the .sfl3 NSKeyedArchiver UID resolver to `finder-exporter`** (2026-05-11). Extracted the resolver to `bin/lib/sfl3_resolver.py` + `bin/lib/resolve_bookmark.swift` for future exporters. `finder-exporter` now returns **50 recent docs** + populated favorites list (was zero). Markdown export enriched to surface resolved paths. iwork-exporter still uses its local copy; consolidating is low-priority maintenance.
- [ ] **`voice-memos-exporter transcribe`** — `whisp` wrapper for bulk Whisper. Apple's tsrp transcripts are English-only and poor on Finnish; Whisper with `--fi` is the practical path. Flags: `--lang fi/en`, `--chunked` for >30 min recordings.
- [ ] **`voice-memos-exporter watch`** — fswatch on Recordings/, auto-transcribe new .m4a, Discord ping via pakettibot inbox.
- [ ] **`safari-exporter close-tab <selector>`** — UI-script Safari to close one tab from a per-URL .md file. Phase 2 write action.
- [ ] **`safari-exporter consolidate --to-bookmarks`** — for each duplicate URL in `_duplicates.md`, keep one tab in its themed group, bookmark the rest, close the rest.
- [ ] **`stickies-exporter create / append / delete`** — quit-Stickies-first-then-write, with `--write` confirmation flag.
- [ ] **`reminders-exporter create / complete`** — AppleScript via Reminders' sdef.
- [ ] **`image-capture-exporter download-from-ios <device>`** — ImageCaptureCore via Objective-C bridging.
- [ ] **`image-capture-exporter watch`** — IOKit DAEvents observer for USB attach/detach with hook command.

### Next cross-package xref subcommands (template ready)

The voice-memos→calendar xref proved the pattern. Drop the same idiom into:

- [x] `voice-memos-exporter xref --notes` — shipped 2026-05-11. Notes bodies are protobuf (not SQL-searchable); restricted to ZTITLE1 with ≥2 distinct ≥3-char token overlap. First run surfaced clean matches like "Mauri Rantala" ↔ a Facebook URL note, and "Inkiväärikuja 6 7" ↔ three property-related notes.
- [ ] `safari-exporter xref --notes` — match open-tab URLs against Notes.app body URL mentions
- [x] `mail-exporter xref --calendar` — shipped 2026-05-11; default ±60 min, optional `--since YYYY-MM-DD` + `--limit`, JSON or text.
- [x] `photos-exporter xref --calendar` — shipped 2026-05-11; default ±10 min, surfaces event location alongside summary; first run with `--since 2026-05-01` returned 4 photo↔event correlations.
- [ ] `reminders-exporter xref --calendar` — match reminder due_date to events near it

### Next exporter targets — Tier 2

(All have full sdefs; plist-probe already showed user data is there.)

- [ ] **`preview-exporter`** — recent docs + annotation history (109 plist keys + per-doc PDF metadata)
- [ ] **`podcasts-exporter`** — subscriptions + listening progress (105 plist keys + Podcasts SQLite)
- [ ] **`books-exporter`** — library + annotations + highlights (`~/Library/Containers/com.apple.iBooksX/Data/Documents/`)
- [ ] **`tv-exporter`** — same idea as Books for the TV library
- [ ] **`contacts-exporter`** — Contacts sdef + `~/Library/Application Support/AddressBook/AddressBook-v22.abcddb`
- [x] **`shortcuts-exporter`** — shipped 2026-05-11. Reads Shortcuts.sqlite via the WAL-safe snapshot helper. Subcommands: status / list / folders / show / export. Per-Shortcut markdown with YAML frontmatter under `exported/shortcuts/by-uuid/<uuid>.md` + folder indexes + master `_index.md`. First run: 278 Shortcuts catalogued across 5 folders. Action contents (NSKeyedArchiver bplists) not yet decoded — metadata-only export.

### Next exporter targets — Tier 5 dark via back-door pattern

- [ ] **`disk-utility-exporter`** — wrap `diskutil list` / `diskutil info` / `diskutil apfs list`
- [ ] **`activity-monitor-exporter`** — `ps`/`top`/`vmstat`/`iotop` snapshots + `ioreg` hardware state
- [ ] **`screenshot-exporter`** — wrap `screencapture` with named regions, scheduled captures, OCR via macOS Vision (Swift one-liner)
- [ ] **`photo-booth-exporter`** — `~/Pictures/Photo Booth Library/Pictures/*` + `Recents.plist` + AVFoundation `take` (the `take_photo.swift` from `image-capture-exporter` already exists)
- [ ] **`clock-exporter`** — `mobiletimer.plist` for World Clock cities + `defaults` for menu-bar prefs + alarms/timers
- [ ] **`spaces-exporter`** (a.k.a. mission-control-exporter) — `com.apple.spaces.plist` per-monitor Space tree
- [ ] **`system-settings-exporter`** — meta-package over `defaults` reads of every settings domain

### Next exporter targets — Tier 4 URL schemes

- [ ] **`facetime-exporter`** — recent calls if any persist; ContactsKit cross-reference
- [ ] **`stocks-exporter`** — tracked tickers + alerts
- [ ] **`weather-exporter`** — saved locations + alert conditions
- [ ] **`maps-exporter`** — saved locations + recent searches + favorite places + offline regions

### Hey Sal v1 — when macOS 26 lands

- [ ] **Swap rule-based intent classifier for `LanguageModelSession`** (FoundationModels Swift framework). The dispatch loop stays the same; replace the regex bank with a Swift one-liner that emits `{exporter, subcommand, args}` JSON. Detection trick is already in `bin/apple-summarize` — instantiate `LanguageModelSession()`, not just `import FoundationModels`.
- [ ] **Vocal Shortcuts trigger** — register "Hey Sal" as a macOS Vocal Shortcut that pipes the captured utterance into `bin/hey-sal --speak`.
- [x] **More intent patterns** — 3 of 4 shipped 2026-05-11: `remind me to X [tomorrow|today|at Y]`, `play [track|song] X`, `draft/compose email to X about Y`. Each handler shells out via osascript through the app's sdef — no exporter subcommand dependency. The 4th ("show me photos from <month>") deferred: photos-exporter needs a date-range search subcommand first.

### Cross-package layer — still missing

- [ ] **`apple-grand-stats`** — daily / weekly / monthly digest derived from all the per-package exports. Hours recorded today (Voice Memos), URLs visited (Safari history), reminders completed, Photo Booth captures, mail received, etc.

### Documentation refresh

- [x] **`automation-tiers.md` refresh** — verified 2026-05-11 that the standalone file has no per-app classification list (it's all surface-level tier descriptions). skill.md summary tier list updated to put Mission Control under Tier 5; the body-text reclassification note at line 541 was already there.
- [ ] **`exported/README.md` cardinality refresh** — auto-update the live numbers each time `apple-grand-export` runs.
- [ ] **`bin/app-plist-probe.py --diff`** — diff two snapshots of the survey to catch new apps / new keys after macOS updates. Run after each system update; commit the diff so the repo tracks Apple's evolution.

### Sal philosophy threading

- [ ] **The Cellular Trinity** — link each exporter to one of Sal's automation-architecture layers (URL schemes / AppleScript / Shortcuts / App Intents). Each package's README declares which layer(s) it operates at.
- [ ] **The Carpenter Move** — every exporter, in its README's "Phase 2" section, names the *underlying principle* it shares with at least one other package. Builds a navigable mesh of pattern-reuse.

---

## Sal archive — pre-existing (older session, still valid)

### Right now — transcription pipeline (built, not yet fired)

- [ ] **Fire Track A from Discord:** `!pk cloudcity bash /Users/esaruoho/work/apple/bin/sal-transcribe-youtube.sh`
  - Submits 16 YouTube interview URLs to whisp-worker queue
  - whisp-worker daemon runs through them autonomously
  - Sync step copies transcripts into `sources/sal/transcripts/youtube/` and commits
  - Wall-clock estimate: ~3-4 hours of audio across 16 videos → ~1 hour of transcription on M2 Pro turbo
- [ ] **Fire Track B from Discord:** `!pk cloudcity bash /Users/esaruoho/work/apple/bin/sal-transcribe-podcasts.sh`
  - First run resolves the 24 Apple Podcasts URLs to MP3 enclosure URLs via iTunes Lookup + RSS XPath
  - Then downloads each MP3, runs `whisp`, organizes transcripts under `sources/sal/transcripts/podcasts/<show>/`
  - Wall-clock estimate: ~25 hours of audio across 24 episodes → ~2 hours of transcription + ~30 min download
- [ ] **Verify resolver coverage:** after Track B's first run, inspect `analysis/sal/apple-podcast-mp3-urls.yaml` — any entries with `status: no-match` or `status: feed-fetch-failed` need manual mp3_url override before re-running.
- [ ] **Optional: enable Discord summary** — set `POST_DISCORD=1` when invoking the podcast script so a `.cmd` lands in pakettibot inbox at completion.

### After transcripts arrive

- [ ] Re-run `bin/sal-archive-status.py --write analysis/sal/current-status.md` to refresh the dashboard.
- [ ] Update `indexes/sal-interviews-discovered.yaml` to add `transcript_path:` next to each YouTube + podcast entry.
- [ ] Cross-link transcripts into `indexes/sal-lessons.yaml` where they support a curriculum module.
- [ ] Spot-check 3 transcripts for proper-noun accuracy (Soghoian variants, Ray Robertson, Allison Sheridan, etc.). If hallucinations are bad, re-run that subset with explicit `--prompt` containing the proper-noun registry.

### Sal archive — remaining gaps (3 dead URLs)

- [ ] `https://macosxautomation.com/405/us/media/apple/applescript/2008/aperturepdfworkflows.zip` — Wayback only has 404 captures, Apple CDN dead, Sal-only recovery path
- [ ] `https://macosxautomation.com/applescript/apps/Script_Geek.zip` — same; try MacUpdate, oldapps.com, MacRumors forum threads before nudging Sal
- [ ] `https://macosxautomation.com/applescript/apps/Script_Geek_old.zip` — same as Script_Geek.zip

### CMD-D conference site mirror (not yet done)

`bin/sal-discover-interviews.py` surfaced 75 Wayback snapshots of `cmddconf.com` including the 2017 program page, bootcamp materials, and speaker headshots. Worth mirroring like we did `dictationcommands/`.

- [ ] Add `cmddconf.com` to `bin/sal-mirror.py` (or whatever site-mirror tool is canonical) and pull a clean offline copy under `sources/sal/cmddconf.com/`
- [ ] Index the bootcamp materials (`Alert-Utilities.zip`, `FileManagerLib_stuff.zip`, `installer.zip`) in `indexes/sal-download-targets.yaml` so they're cross-referenced with the conference page

### Discovery script — known limitations to fix later

- [ ] Wayback CDX `twitter.com/macautomation` rate-limits to 503 even with backoff. Use a different scraper (`snscrape` is broken since Twitter API change; `nitter` mirrors are mostly down). Defer until a working tool surfaces.
- [ ] Most Mac journalism site searches now resolve via the DDG fallback (TidBITS, MacStories) but Six Colors / Daring Fireball / MacRumors still return 0 hits. Try Google Custom Search proxy or per-site sitemap.xml parsing.
- [ ] PodcastIndex.org has an API but requires signup. If the iTunes Search results miss any episodes, integrate it as another source.
- [ ] Add YouTube channel-handle probe (e.g. `@macautomation` or whatever Sal's own channel is) instead of relying on keyword search.

### Skill / tooling refinements

- [ ] Codify the discovery + transcription workflow into a section of `skill.md` once the first transcripts land and the runbook is proven end-to-end.
- [ ] Generate whiteboards for the new sections: Sal preservation pipeline, the @cloudcity remote-run pattern, the file-drop bridge.

### Lower-confidence Apple Podcasts matches (verify before processing)

- [ ] **Examining #64 — Mac Mini M1 & AI Retrospective** — likely mentions Sal in retrospective context, may not be a primary interview. Verify by listening to the first ~5 minutes before adding to `apple-podcast-episodes.txt`.
- [ ] **Gig Gab — The Value of Prep Time** — Working Musician's Podcast; matched the Sal filter via a passing "Apple"/"automation" mention. Probably false positive. Verify or drop.

### Deferred / nice-to-have

- [ ] Build `bin/sal-mirror.py` site auto-mirror so adding new Sal-related domains is one command (`sal-mirror cmddconf.com`).
- [ ] Add a per-show RSS-feed monitor: when a show that's hosted Sal once publishes a new episode mentioning him, auto-queue.
- [ ] Wire the @macautomation Twitter archive recovery via a different route (snscrape unreliable; consider a paid TwitterAPI relay just for one-time historical scrape).
