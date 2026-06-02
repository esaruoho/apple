---
layout: default
title: Trigger → worker chassis
---

# Trigger → worker chassis

[← Back to home](./)

Four pipelines in this repo share the same shape. Once you've seen one, you've seen all four — and the fifth one you build will follow it too.

> **The chassis:** *(filesystem-or-OS event) → debounce + lock → worker dispatch → result handler.*

## The four instances

### 1. Finder tag → action

You tag a file with `process` in Finder. [`bin/tag-watcher`](https://github.com/esaruoho/apple/blob/main/bin/tag-watcher) (FSEvents + xattr poll fallback) notices, locks, and hands the path to [`bin/tag-result-handler`](https://github.com/esaruoho/apple/blob/main/bin/tag-result-handler) which routes based on which tag fired (`process`, `needs-ocr`, etc.). Full pipeline doc: [`wiki/concepts/finder-tag-pipeline.md`](https://github.com/esaruoho/apple/blob/main/wiki/concepts/finder-tag-pipeline.md).

The companion [`/tag-app`](./) command generates one Finder-toolbar `.app` per tag name so the tag itself is one click away.

### 2. Voice Memo `#process` → whisp

You record a Voice Memo with `#process` in the title. A watcher polls Voice Memos.app's database, extracts the `.m4a` + the `tsrp` auto-transcript atom (see [the gotcha](https://github.com/esaruoho/apple/blob/main/wiki/concepts/voice-memos-tsrp-atom.md)), hands the audio to the whisp pipeline (OpenAI Whisper local, with hallucination-loop stripping). Result: a richer transcript than the OS-provided one, summarized, filed, and a notification fires when done.

### 3. Stickies → Claude

You edit a Sticky note. FSEvents inside the AppleToolbox process notices, debounces, and dispatches a worker that reads the note as the next prompt for Claude. The note is the trigger surface. Doc: [`wiki/concepts/stickies-claude-trigger.md`](https://github.com/esaruoho/apple/blob/main/wiki/concepts/stickies-claude-trigger.md).

### 4. Mail flag → routing

You flag a Mail message with one of seven colors. A poll (Mail Rules cannot trigger on user-flagging — only on incoming-mail attributes) notices the flag, walks the per-color contract in [`bin/mail-flag-config.json`](https://github.com/esaruoho/apple/blob/main/bin/mail-flag-config.json), and fans out: writes the `.eml`, extracts attachments, renders the body as markdown, files them in per-color destinations. Doc: [`wiki/concepts/mail-flag-pipeline.md`](https://github.com/esaruoho/apple/blob/main/wiki/concepts/mail-flag-pipeline.md).

### 5. Mail account pristine backup (`/backup-mailbox`)

You type `/backup-mailbox esa@raybrowser.com`. The tool resolves the Mail account → V10 directory UUID via AppleScript (Mail must be running for its scripting suite to answer — otherwise every property accessor errors with `-2741`), quits Mail so no `.emlx` is mid-write, `rsync`s `~/Library/Mail/V10/<UUID>/` to `~/Backups/mail-<prefix>-YYYY-MM-DD/`, renames every top-level `*.mbox` with the slug prefix (`INBOX.mbox` → `<prefix>-inbox.mbox`, `[Gmail].mbox` → `<prefix>-gmail.mbox`), and verifies `.emlx` counts source vs backup. The result is drop-in restorable — copy the folder back under `~/Library/Mail/V10/` on any Mac and relaunch Mail. Doc: [`wiki/concepts/mail-backup.md`](https://github.com/esaruoho/apple/blob/main/wiki/concepts/mail-backup.md).

---

## What makes the chassis reusable

Every instance has the same five rules. Violating any of them re-introduces a bug we've already fixed.

### 1. Lock before dispatch

FSEvents fires N times per save (one `.rtfd` write triggers ~3–5 events on Sequoia). Without `mkdir`-style lock, two worker processes race and dispatch twice. (2026-05-25 incident: Stickies opened two iTerm windows per save. Fix in [`30eef70`](https://github.com/esaruoho/apple/commit/30eef70).)

### 2. Belt + suspenders triggers

FSEvents is fast but unreliable across sandboxes; the periodic `Timer` poll is slow but exhaustive. Run both. Lock dedupes them.

### 3. Run inside AppleToolbox, not a bare LaunchAgent

TCC silently filters directory listings for LaunchAgent-spawned bash inside app containers. The watcher needs to live inside an app with Full Disk Access — that's [AppleToolbox](https://github.com/esaruoho/apple/tree/main/topbar). Full debugging story: [`feedback_launchd_cannot_read_app_containers.md`](https://github.com/esaruoho/apple/blob/main/.claude/projects/-Users-esaruoho-work-apple/memory/feedback_launchd_cannot_read_app_containers.md) (in private project memory, summarized in [`wiki/entities/appletoolbox.md`](https://github.com/esaruoho/apple/blob/main/wiki/entities/appletoolbox.md)).

### 4. Calibrate the sensor

If the trigger is a measurement (HomePod climate sensor, Voice Memos transcript confidence, tag colour), measure the bias once against a trusted reference and apply the offset before downstream code consumes the value. HomePod reads 0.45 °C and 4.5 % low against a professional olosuhdemittaus instrument; we add those offsets.

### 5. Result handler is separate from the watcher

`tag-watcher` notices, `tag-result-handler` decides what to do. Mail-flag dispatch is in `bin/mail-flag-worker`, separate from the poller. Keeping the noticing and the doing apart lets you swap one without touching the other.

---

## Adding a fifth

When the next "X happens → script runs" idea arrives, the chassis already exists. New watcher = new entry in AppleToolbox's `Timer` callback list + an FSEvents subscription, dispatching to a new worker in `bin/`. The four pipelines above give the precedent for every nuance.

Skill memory: [Mail flag pipeline as the fourth instance of the chassis](https://github.com/esaruoho/apple/blob/main/.claude/projects/-Users-esaruoho-work-apple/memory/mail_flag_pipeline.md).

---

[← Back to home](./) | [Triggers ←](./triggers) | [Tiers ←](./tiers) | [Sal corpus ←](./sal-corpus)
