# Wiki Log

Append-only chronological record of wiki ingests, queries, lint passes, and structural changes.

Format: `## [YYYY-MM-DD] <verb> | <summary>` so the log is greppable:

```bash
grep "^## " wiki/log.md | tail -5    # last 5 entries
grep "ingest" wiki/log.md            # all ingests
```

---

## [2026-05-21] migrate | wiki/ skeleton created — 20 root .md files moved into entities/concepts/lessons/compiled

Initial three-layer split per Karpathy LLM Wiki post. Raw sources stay in `sources/` / `dictionaries/` / `patents/` / `whiteboards/`; executing layers stay in `bin/` / `commands/` / `scripts/`; the new `wiki/` is the LLM-owned knowledge layer. 50 cross-ref rewrites in skill.md / README.md / CLAUDE.md. Generators (`bin/workflow-gen.py`, `bin/gen-skill-indexes.py`) updated to write into `wiki/compiled/`.

## [2026-05-21] ingest | 14 standalone memory files promoted from memory/ into wiki/

`app_plist_probe`, `clipboard_rich_text_recipe`, `mail_smartbox_writes_dead`, `quicktime_pro_scriptability_cliff`, `safari_export_schema_gotchas`, `sal_cross_decade_lineages`, `steve-jobs-rbi`, `tier_5_backdoor_pattern`, `vocal_shortcuts_trigger_position`, `voice_memos_tsrp_atom` → `wiki/concepts/`. `hey_sal_v0_seven_layers`, `sal_session_717_replication_state`, `wwdc_archive_complete` → `wiki/operations/`. `whiteboard_knob` → `wiki/entities/`. One session-recap deleted. MEMORY.md trimmed 301 → 96 lines.

## [2026-05-21] migrate | skill.md tome → index (1,265 → 130 lines)

38 H2 sections extracted to wiki/ pages. New skill.md keeps frontmatter + User Context + conditional Boot Protocol + wiki index. Boot now skips `sal-archive-status.py` unless the message mentions Sal / WWSD / archive / transcript / dashboard / status.

## [2026-05-21] lint | dedup pass — 12 pages had "## From skill.md" appendices, all merged

App-probe, pattern-reusability, thought-multiplier, loupedeck-window-management, whiteboard-knob, sal-like, mail-smart-mailboxes-dead, vocal-shortcuts-trigger, github-watcher rewritten to single coherent pages. Sal-soghoian, automation-tiers, spotlight-automation: appendix stripped (existing top covered everything in deeper detail). One unique nugget saved: principles #28-30 (WWDC 2016 Session 717 Tier 2) inserted into sal-soghoian.md as new Tier 2 section.

## [2026-05-21] build | wiki-index + wiki-lint pipeline + INDEX.md + log.md

`bin/wiki-index.py` auto-generates `wiki/INDEX.md` from filesystem walk + frontmatter/H1/first-paragraph. `bin/wiki-lint.py` checks orphans, oversized pages (>250 lines), broken cross-refs, `## From skill.md` regressions, missing H1, stale memory-type frontmatter. Slash wrappers: `/wiki-index` and `/wiki-lint`. skill.md shrunk further by replacing inline index with pointer to `wiki/INDEX.md`.

## [2026-05-22] build | ASObjC promoted to Tier 1.5 — default tool order changed

After Sal's 2026-05-22 reply to Esa pointing at AppleScriptObjective-C for file management + tags, the skill discovered a missing tier. ASObjC has shipped since macOS 10.6 (2009) but had zero wiki coverage. Promoted to Tier 1.5 in the automation atlas (between AppleScript and App Intents) and made the **default** in the language-order hierarchy. New artifacts:

- `wiki/concepts/asobjc.md` (concept page, postmortem, migration recipes, pre-flight rules)
- `bin/asobjc-tag-demo.applescript` (minimum-viable read pilot)
- `bin/tag-asobjc.applescript` (A/B reimplementation of `bin/tag` core I/O — names-only)
- `bin/tag-asobjc-full.applescript` (color-preserving pilot using NSPropertyListSerialization + xattr round-trip)
- `bin/cocoa-class-probe` (SDK-header + ObjC-runtime probe — PUBLIC / RUNTIME-ONLY / ABSENT; required before any Cocoa class name appears in a proposal)

Tool-order patches applied to `skill.md`, `wiki/concepts/wwsd-decision-tree.md`, `wiki/concepts/apple-native-only.md`. Comparison matrix in WWSD now has an explicit AppleScript+ASObjC row. Memory rules: `feedback_check_both_taxonomy_axes` (root-cause of missing tier) + `feedback_probe_before_naming_cocoa_classes` (no more hallucinated class names).

Two findings worth carrying forward: (1) `NSURLTagNamesKey` is names-only — color preservation requires the NSPropertyListSerialization + xattr round-trip recipe; (2) `NSSavedSearch` is ABSENT in public headers — the `.savedSearch` plist IS the API, so `bin/smart` and `bin/show` stay in Python (`plistlib`).

## [2026-05-22] migration | "Delete Immediately" Quick Action → ASObjC NSFileManager

First production-shipped ASObjC migration. `bin/build-delete-now-shortcut.py` rebuilt with the embedded AppleScript body using `NSFileManager removeItemAtURL:error:` instead of `do shell script "/bin/rm -rf"`. Per-item typed `NSError` summary dialog on failure. Smoke-tested on shell-hostile filenames: normal, spaces, `Ünicode-böld‐文件.txt`, directories, and a missing path — all handled correctly without shell quoting. Shortcut regenerated and signed.

New AppleScript idiom logged in `wiki/concepts/asobjc.md`: don't destructure dual-returns with `set {a, b} to ...` (ambiguous type inference yields cryptic compile errors); use `set r to (...)` then `item 1 of r` / `item 2 of r` instead.

## [2026-06-01] build | Fleet × Panel — the inter-computer script runner + eppc transport

Unified Fleet (device roster) and Apple Panel (action registry) into one runner: pick a machine, see its capabilities, run a script there, get the result back. `bin/apple-panel` gained `--actions-json` + `--run <id>` (one curated executor); `bin/machine-card` publishes `panel_actions[]` (computed LIVE, not cached — caching it for 6h is what briefly emptied the Mini's card). `fleet/Fleet.swift` renders a RUN face per card + dispatches: localhost via `apple-panel --run`, peer via `bin/panel-worker` over the Syncthing `panel-inbox`/`panel-results` (5th trigger→worker chassis instance; curated id is the allowlist, no network exec). Mini's panel-worker wired into Cloudcity-Boot pane-8 wrapper. `bin/syncthing-nudge` (POST /rest/db/scan) cut remote-run latency from ~38–76s to ~6s. Native `panel-app/ApplePanel.app` (WKWebView) wraps the panel as a real Mac app (fixed a stdout-block-buffering hang via `python3 -u`). Third transport added: **eppc / Remote Application Scripting** — `bin/eppc-probe` drives a peer's REAL apps (Finder/etc.) synchronously, ~4s; APPS·eppc face on peer cards. eppc auth is per-connection (keychain doesn't reliably cache it on Sequoia→Tahoe — settled, see `wiki/concepts/apple-events-and-remote.md`); `bin/eppc-auth` + the one-connection "snapshot" probe mitigate. Docs: `wiki/concepts/fleet-panel-unification.md`, `apple-events-and-remote.md`, `lessons/apple-events-deep-dive.md`. Also shipped `bin/disk-overview` (`/disk-overview`) — Disk-Utility-style volume snapshot.

## [2026-06-01] build | Apple Silicon on-device ML as an automation surface

Probed + mapped the stack (Vision, NaturalLanguage, Speech, SoundAnalysis, Core ML, Create ML, and macOS-26 FoundationModels) in `wiki/concepts/apple-silicon-ml.md`. Shipped Apple-native tools: `bin/vision-ocr` (Vision OCR, ~2s/page; great on single-column, interleaves columns + garbles math on multi-column academic scans, so it's opt-in not the archive default); `bin/fm` (FoundationModels on-device LLM — proven on the Mini, `--check`→available, ~2s replies); `bin/speech-transcribe` (Speech STT — run-loop gotcha: SFSpeechRecognizer callbacks come on the main run loop, spin RunLoop.main, don't block on a semaphore); `bin/transcribe-bench` (Apple Speech vs Whisper). Honest benchmark: Whisper more accurate (punctuation/casing), Apple Speech ~5× faster.

## [2026-06-01] incident | "Mini bridge dead" is usually LAPTOP disk — bridge-doctor

The recurring "OMG the Mini is dead" was a misdiagnosis: stale heartbeats / file-bridge timeouts were caused by THIS laptop hitting Syncthing's `minDiskFree` guard (1% of 1.8TB ≈ 18GB) — below it, Syncthing silently won't write incoming files (47 "insufficient space" errors), so the Mini's heartbeats/outbox never land. The Mini was healthy throughout. Freeing ~30GB of caches (Whisper models, huggingface, Homebrew) cleared it and the bridge round-trip recovered instantly. Shipped `bin/bridge-doctor` (`/bridge-doctor`) — checks laptop disk vs the guard FIRST, then folder errors + heartbeats, plain verdict. Memory rule `feedback_bridge_dead_is_laptop_disk`. Diagnosis order: disk first, SSH second, panic never.

## [2026-06-01] fix | Blank _ocr.pdf — pdf-lib copyPages corrupts CCITTFax; rebuilt 7, fixed upstream

PDFWorkshop produced 7 blank/corrupt `_ocr.pdf` (of 371). Root cause (read from batch-ocr.mjs): `buildOcrPdf` used pdf-lib `copyPages`, which corrupts CCITTFax-G4 image streams on fax-scanned books — CoreGraphics AND MuPDF both fail to decode. The `.txt` text was always intact. Built `bin/ocr-pdf-rebuild` (clean scan + `.txt` → searchable PDF via PyMuPDF: preserves images, adds invisible text layer). Located all 7 originals in `merlib-dump/sources` + the Mini's uploads; rebuilt all 7 into proper searchable PDFs placed next to their sources as `_ocr.pdf`. Fixed the root cause upstream: PDFWorkshop `buildOcrPdf` now uses PyMuPDF (`build_ocr_pdf.py`), node-checked + live-tested, committed `1589f05`. Ledger: `wiki/operations/blank-ocr-pdfs.md` (RESOLVED).
