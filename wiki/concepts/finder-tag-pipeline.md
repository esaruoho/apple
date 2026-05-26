# Finder Tag Pipeline — Tag a File, Mac Mini Processes It

> 📖 **Public:** [Finder-tag pipeline](https://esaruoho.github.io/apple/finder-tag-pipeline)

Built 2026-05-21 in conversation `09-46-57-i-have-an-apple-question-for-you-what-do-you-know-about-tags-claude-code.md`.

## The principle

A Finder tag is a routing signal. Tag a file with `needs-ocr` and the file goes through Syncthing to CloudcityMacMini's PDFWorkshop OCR worker, the worker writes status back into `~/work/comms/queue/worker-status/`, Syncthing carries that status home, and a local LaunchAgent reads it and updates the file's tags in real time. **You tag it. Nothing else.**

This generalises: the same dispatch shape (tag → Syncthing inbox → Mac Mini worker → `.job` status sidecars → tag mutation) is wired for `needs-transcription` (audio/video → Whisp). New triggers go into `TRIGGERS` dict in `bin/tag-watcher`.

## What lives where

| Path | What it is |
|---|---|
| `bin/tag` | xattr CRUD on `_kMDItemUserTags`. Subcommands: list, add, set, remove, clear, find, find-all/any, link, rename, colors. |
| `bin/tag-smart` | Writes `.savedSearch` plists to `~/Library/Saved Searches/` (or `/tmp` with `--tmp`). |
| `bin/tag-finder-selection` | osascript-driven Finder-selection wrapper around bin/tag. Modes: prompt / list / clear / trinity / `--tag <spec>`. |
| `bin/tag-trinity` | Stamp a shared `trinity-<slug>` link-tag across N files (binds conversation md ↔ app ↔ skill). |
| `bin/tag-send-to-ocr` | Tag Finder selection `needs-ocr:red` + fire watcher immediately. |
| `bin/tag-watcher` | Dispatcher. mdfind for each TRIGGER, filter, copy to queue inbox, stamp queued tag. |
| `bin/tag-result-handler` | Closes the loop. Reads heartbeat + worker-status/. Stamps processing/complete/failed. Replaces image-only PDF with OCR'd version when result returns. |
| `bin/tag-retry-failed` | Re-submits download_failed Mac Mini jobs; distinguishes `ocr-engine-failed` (real engine choke → manual triage). |
| `bin/com.esa.tag-watcher.plist` | LaunchAgent — fires watcher + result-handler every 60 sec. |
| `bin/build-send-to-ocr-shortcut.py` | Builds the Finder Quick Action so right-click → Quick Actions → Send to OCR works. |
| `commands/tag.md` | `/tag` slash dispatcher (forwards to bin/tag or bin/tag-smart). |

## The four-tag OCR state machine

| Tags carried | Meaning | Stamped by |
|---|---|---|
| `needs-ocr:red` | Tagged, not yet dispatched | User (Cmd-I / right-click / 🧰 menu / `/tag add`) |
| `needs-ocr` + `ocr-queued:yellow` | In our local inbox, awaiting Mac Mini, OR Mac Mini has the `.job` in `worker-status/pending/` | `tag-watcher` (on dispatch) AND `tag-result-handler` (when worker-status/pending/ shows a job for it) |
| `needs-ocr` + `ocr-processing:blue` | Mac Mini actively OCRing this file right now | `tag-result-handler` (heartbeat current_job match OR worker-status/processing/) |
| `ocr-complete:green` | OCR'd version replaced the original; `.txt` sidecar dropped next to it | `tag-result-handler` (when `<basename>_ocr.pdf` appears in `ocr-results/`) |
| `ocr-failed:orange` | Mac Mini gave up (download_failed) — retryable | `tag-result-handler` (worker-status/failed/ or done/ with error:) |
| `ocr-engine-failed:red` | GLM-OCR choked on content — same engine = same fail | `tag-retry-failed` (replaces ocr-failed for non-retryable engine errors) |

Watcher's `find_pending` correctly excludes anything carrying `ocr-queued` / `ocr-processing` / `ocr-complete`, so the same file never re-dispatches.

## The talkback channel

Mac Mini's PDFWorkshop worker writes per-job YAML-ish text files into `~/work/comms/queue/worker-status/{pending,priority,processing,done,failed}/`. Filename pattern: `<jobnum>_<basename>.job`. Syncthing carries those `.job` files back to this Mac.

`tag-result-handler.worker_status_sync()` reads them every 60 sec and reflects the state onto archive originals (resolved via `tag-watcher-map.json` first, then fallback `rglob` of `~/work/merlib-dump/*.pdf`).

Mac Mini doesn't touch tags. It can't — the archive isn't Syncthing-shared with it. Only the queue folders are. Local-side tagging based on Mac Mini's signals is functionally equivalent.

## The Smart-Folder layer

Every status / subject / state has a `.savedSearch` under `~/Library/Saved Searches/`. The directory is itself a Smart Folder ("All Smart Folders.savedSearch", scope = that directory, filter = `kMDItemFSName == "*.savedSearch"`) so the discovery layer is bootstrapped.

Current Smart Folders (2026-05-21):

- **Pipeline state**: PDFs needing OCR · PDFs needing analysis · OCR failed (needs triage) · OCR engine failed (different OCR needed)
- **Subject corpora**: Bearden corpus · Tesla corpus · Schauberger corpus · Russell corpus · Moray corpus · Dollard corpus · Bedini corpus · Hilarion corpus
- **Conversation trinity**: Trinity — tagging-tool-2026-05-21 (binds the conversation md ↔ bin/tag* scripts ↔ MEMORY.md)
- **Meta**: All Smart Folders

`bin/tag-smart "<Title>" <tag>[,<tag>] [--scope <dir>] [--any]` creates them. `--tmp` writes to /tmp + opens for throwaway browsing.

AppleToolbox menu-bar (`🧰 → 🏷 Tags → 🗂 Smart Folders ▸`) enumerates the directory at menu-open time — newly-created Smart Folders show up automatically without rebuilding the app.

## The recursion-guard footnote

`bbs-ocr-submit.sh` uses `cp -p`, which preserves xattrs. That means the inbox copy inherits the `needs-ocr` tag from the original — and Spotlight indexes it as a needs-ocr-tagged file. Without a guard, the watcher would keep dispatching the inbox copy into itself, producing `20260521-152544-20260521-152439-20260521-150112-<file>.pdf` triply-prefixed names.

`tag-watcher.find_pending` now refuses any path under `~/work/comms/queue/` (`is_under_queue()`). Same applies to anything else under that Syncthing-shared tree — never dispatch from inside the transport.

## Discoverability for future Claude sessions

When the user says any of:

- "tag this file" / "OCR this" / "send to Mac Mini"
- "how do tags work here"
- "what's the OCR pipeline"
- "send for OCR"
- "needs-ocr" / "ocr-failed" / "ocr-complete"
- "Smart Folder" / "saved search"
- "talkback" / "tag sync" / "Mac Mini status"

→ this page is the entry point. Don't reinvent.

## Operational commands

```bash
# Status: shows Mac Mini's queue depths + local tag counts
~/work/apple/bin/tag-watcher --status

# Fire dispatch now (LaunchAgent does this every 60s anyway)
~/work/apple/bin/tag-watcher

# Reconcile results, sync worker-status
~/work/apple/bin/tag-result-handler

# Reset a stuck file (strip queued/processing/complete so it's re-eligible)
~/work/apple/bin/tag-watcher --reset /path/to/file.pdf

# Retry Mac Mini failures (download_failed only by default)
~/work/apple/bin/tag-retry-failed --kick
~/work/apple/bin/tag-retry-failed --force   # also retry ocr_failed
~/work/apple/bin/tag-retry-failed --dry-run

# Build a Smart Folder for any tag
~/work/apple/bin/tag-smart "<Title>" <tag>[,<tag>] [--scope <dir>] [--any]
```

## Why three places stamp the same tag

`ocr-queued:yellow` is stamped by both `tag-watcher` (when we dispatch) AND `tag-result-handler.worker_status_sync()` (when Mac Mini's pending/ shows a `.job` for it). That's intentional: the watcher catches files we just dispatched; the worker-status sync catches files from yesterday's submissions that pre-date our map.json. Together they cover the whole archive, not just files this session touched.

`ocr-complete:green` strips `needs-ocr`, `ocr-queued`, AND `ocr-processing` before stamping. Three-state transition, one place.
