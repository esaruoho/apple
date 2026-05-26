---
layout: default
title: Finder tag pipeline
---

# Finder tag pipeline

[← Back to home](./)

> **A Finder tag is a routing signal.** You tag a file with `needs-ocr` and the file goes through Syncthing to the Mac Mini's OCR worker, the worker writes status back, and a local watcher reads it and updates the file's tags in real time. **You tag it. Nothing else.**

This page walks the first and best-developed instance of the [trigger → worker chassis](./chassis).

## What lives where

| Path | What it is |
|---|---|
| [`bin/tag`](https://github.com/esaruoho/apple/blob/main/bin/tag) | xattr CRUD on `_kMDItemUserTags`. Subcommands: list, add, set, remove, clear, find, find-all/any, link, rename, colors. |
| [`bin/tag-smart`](https://github.com/esaruoho/apple/blob/main/bin/tag-smart) | Writes `.savedSearch` plists to `~/Library/Saved Searches/`. |
| [`bin/tag-finder-selection`](https://github.com/esaruoho/apple/blob/main/bin/tag-finder-selection) | osascript wrapper around `bin/tag` that operates on the current Finder selection. |
| [`bin/tag-trinity`](https://github.com/esaruoho/apple/blob/main/bin/tag-trinity) | Stamp a shared `trinity-<slug>` link-tag across N files (binds conversation md ↔ app ↔ skill). |
| [`bin/tag-send-to-ocr`](https://github.com/esaruoho/apple/blob/main/bin/tag-send-to-ocr) | Tag Finder selection `needs-ocr:red` and fire watcher immediately. |
| [`bin/tag-watcher`](https://github.com/esaruoho/apple/blob/main/bin/tag-watcher) | Dispatcher. `mdfind` per TRIGGER, filter, copy to queue inbox, stamp queued tag. |
| [`bin/tag-result-handler`](https://github.com/esaruoho/apple/blob/main/bin/tag-result-handler) | Closes the loop. Reads heartbeat + `worker-status/`. Stamps processing/complete/failed. Replaces image-only PDF with OCR'd version when result returns. |
| [`bin/tag-retry-failed`](https://github.com/esaruoho/apple/blob/main/bin/tag-retry-failed) | Re-submits `download_failed` Mac Mini jobs; distinguishes `ocr-engine-failed` (real engine choke → manual triage). |
| [`bin/build-tag-app`](https://github.com/esaruoho/apple/blob/main/bin/build-tag-app) + [`build-tag-apps`](https://github.com/esaruoho/apple/blob/main/bin/build-tag-apps) | Generates one colored `Tag <Name>.app` per tag for Finder toolbar pinning. See [the Apple-way bootstrap](https://github.com/esaruoho/apple/blob/main/wiki/concepts/finder-toolbar-locked.md). |
| `~/Library/LaunchAgents/com.esa.tag-watcher.plist` | LaunchAgent — fires watcher + result-handler every 60s. |

## The four-tag OCR state machine

| Tags carried | Meaning | Stamped by |
|---|---|---|
| `needs-ocr:red` | Tagged, not yet dispatched | User (Cmd-I / right-click / 🧰 menu / `/tag add` / toolbar button) |
| `needs-ocr` + `ocr-queued:yellow` | In local inbox, awaiting Mac Mini | `tag-watcher` on dispatch |
| `needs-ocr` + `ocr-processing:blue` | Mac Mini actively OCRing this file | `tag-result-handler` (heartbeat current_job match) |
| `ocr-complete:green` | OCR'd version replaced the original; `.txt` sidecar dropped next to it | `tag-result-handler` when `<basename>_ocr.pdf` appears in `ocr-results/` |
| `ocr-failed:orange` | Mac Mini gave up (download_failed) — retryable | `tag-result-handler` (worker-status/failed/) |
| `ocr-engine-failed:red` | GLM-OCR choked on content — same engine = same fail | `tag-retry-failed` (replaces ocr-failed for non-retryable engine errors) |

Watcher's `find_pending` correctly excludes anything carrying `ocr-queued` / `ocr-processing` / `ocr-complete`, so the same file never re-dispatches.

## The talkback channel

The Mac Mini doesn't touch tags. It can't — the archive isn't Syncthing-shared with it. Only the queue folders are. So the Mini writes per-job YAML-ish text files into `~/work/comms/queue/worker-status/{pending,priority,processing,done,failed}/`. Syncthing carries those `.job` files back to this Mac. `tag-result-handler.worker_status_sync()` reads them every 60s and reflects the state onto archive originals (resolved via `tag-watcher-map.json` first, then fallback `rglob` of `~/work/merlib-dump/*.pdf`).

**Local-side tagging based on Mac Mini's signals is functionally equivalent to the Mac Mini doing it. No SSH. No port-forward. No remote tag mutation.**

## The Smart-Folder layer

Every status / subject / state has a `.savedSearch` under `~/Library/Saved Searches/`. The directory is itself a Smart Folder ("All Smart Folders.savedSearch", scope = that directory, filter = `kMDItemFSName == "*.savedSearch"`) so the discovery layer is bootstrapped.

Live folders (as of 2026-05-26):

- **Pipeline state**: PDFs needing OCR · PDFs needing analysis · OCR failed (needs triage) · OCR engine failed
- **Subject corpora**: Bearden · Tesla · Schauberger · Russell · Moray · Dollard · Bedini · Hilarion
- **Conversation trinity**: Trinity — `tagging-tool-2026-05-21` (binds conversation md ↔ `bin/tag*` scripts ↔ MEMORY.md)
- **Meta**: All Smart Folders

`bin/tag-smart "<Title>" <tag>[,<tag>] [--scope <dir>] [--any]` creates them. `--tmp` writes to `/tmp` and opens for throwaway browsing.

## Generalising the pattern

The same dispatch shape (tag → Syncthing inbox → Mac Mini worker → `.job` status sidecars → tag mutation) is wired for `needs-transcription` (audio/video → Whisp). New triggers go into the `TRIGGERS` dict in [`bin/tag-watcher`](https://github.com/esaruoho/apple/blob/main/bin/tag-watcher). Adding a fifth subject corpus or a sixth state takes one Smart Folder + a colour assignment.

## The Finder-toolbar layer

`/tag-app` walks every Spotlight-tagged file under `~`, picks each tag's most-common color from xattrs, and generates one `Tag <Name>.app` per tag in `/Applications/AppleToolbox/Apple-Tag-Apps/`. ⌘-drag any of them onto a Finder window's toolbar for true one-click tagging of the current selection.

**Why .app and not a Shortcut:** Finder's Customize Toolbar palette only lists 19 built-in items — no Shortcuts, no Quick Actions, no Services. The .app route is the only Apple-blessed one-click toolbar button. Full gotcha + bootstrap: [`wiki/concepts/finder-toolbar-locked.md`](https://github.com/esaruoho/apple/blob/main/wiki/concepts/finder-toolbar-locked.md).

## Read more

- Source-of-truth: [`wiki/concepts/finder-tag-pipeline.md`](https://github.com/esaruoho/apple/blob/main/wiki/concepts/finder-tag-pipeline.md)
- Finder-toolbar gotcha + bootstrap: [`wiki/concepts/finder-toolbar-locked.md`](https://github.com/esaruoho/apple/blob/main/wiki/concepts/finder-toolbar-locked.md)
- The chassis pattern: [chassis page](./chassis)

---

[← Back to home](./) | [Triggers ←](./triggers) | [Tiers ←](./tiers) | [Sal corpus ←](./sal-corpus) | [Chassis ←](./chassis) | [ASObjC ←](./asobjc)
