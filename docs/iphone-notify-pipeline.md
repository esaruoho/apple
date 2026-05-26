---
layout: default
title: "iPhone Notify Pipeline — iCloud Drive → Shortcuts Personal Automation"
---

# iPhone Notify Pipeline — iCloud Drive → Shortcuts Personal Automation


[← Back to home](./)
> ⛔ **ARCHITECTURALLY ABANDONED 2026-05-26.** This page describes an iCloud-Drive-folder-watch design that **cannot work on iOS** — Apple does not expose a "When File is Added to Folder" trigger in iOS Shortcuts Personal Automation. The trigger exists on Mac Shortcuts only. Confirmed via the full Personal Automation trigger inventory in [`ios-personal-automation-triggers.md`](ios-personal-automation-triggers.md). Painpoint: [`../../painpoints/SHORTCUTS-001-ios-no-file-folder-trigger.md`](../../painpoints/SHORTCUTS-001-ios-no-file-folder-trigger.md).
>
> **The replacement architecture is iMessage-to-self.** `bin/notify-iphone` is now a thin wrapper around `bin/imessage` — the iMessage bubble IS the iOS push notification (APNs, banner, sound, lock screen, Notification Center). No iCloud Drive folder, no iPhone Shortcut, no Personal Automation. See project memory `feedback_imessage_is_the_iphone_banner.md` for the lesson.
>
> The page is preserved below as historical context — what we tried, what failed, why. Do not re-implement.

---

# iPhone Notify Pipeline (ORIGINAL, ABANDONED) — iCloud Drive → Shortcuts Personal Automation

The phone-side twin of [`NotifyInboxWatcher`](../entities/appletoolbox.md). Mac
writes a JSON; iPhone banners it. Apple-native, no APNs, no Pushover, no
third-party app.

## Architecture

```
Mac worker (any)              iCloud Drive                  iPhone
─────────────────             ────────────                  ──────
notifyPhone(...)       →  ~/Library/Mobile Documents/  →   Shortcuts
   (Swift, AppleToolbox)     com~apple~CloudDocs/             Personal
                             notify-iphone/<id>.json          Automation
bin/notify-iphone      →                                  →   Show
   (CLI, any script)                                          Notification
```

Mac drops a `.json` into the `notify-iphone/` folder inside iCloud Drive.
iCloud syncs the file to the iPhone in seconds. A Shortcuts Personal
Automation watches that folder and banners the contents.

This is the **third notify transport** in AppleToolbox, joining:

1. `notify()` — local `osascript display notification` (same Mac)
2. `NotifyInboxWatcher` — Syncthing `~/work/comms/queue/notify-inbox/` (any peer Mac → this Mac)
3. `notifyPhone()` / `bin/notify-iphone` — iCloud Drive (this Mac → iPhone)

Same JSON contract across (2) and (3), so worker code can fan out to both
laptop and phone with a single payload shape.

## JSON contract

```json
{
  "title":    "OCR done",
  "subtitle": "lookthrough batch 4",
  "body":     "foo.pdf is now searchable (12 pages, 38 KB text)",
  "sender":   "ocr-worker",
  "url":      "shortcuts://run-shortcut?name=Open%20OCR%20Result",
  "id":       "ocr-1716700000-ab12cd34",
  "sound":    "default"
}
```

- `title` — required.
- `subtitle`, `body`, `sender`, `id`, `sound` — optional.
- `url` — optional URL the iPhone notification can open when tapped. Use
  `https://…`, `shortcuts://run-shortcut?…`, `mailto:`, app URL schemes, etc.
  The iPhone has no concept of the Mac's `open_path` / `reveal_path`, so use
  `url` instead.

## Mac side

### CLI

```bash
notify-iphone --title "Build green" --body "ray-browser nightly succeeded"
notify-iphone --title "Mail flag pipeline" --url "shortcuts://run-shortcut?name=Open%20Inbox"
echo '{"title":"…","body":"…"}' | notify-iphone --stdin
notify-iphone --status                # show drop folder + queue depth
```

Source: `bin/notify-iphone`. Stdlib Python, no deps.

### Swift (from AppleToolbox or any helper)

```swift
notifyPhone(title: "Voice memo done",
            body: "transcript ready: 2026-05-26-team-sync",
            url: "shortcuts://run-shortcut?name=Open%20Transcript")
```

Source: `topbar/AppleToolbox.swift` (search for `notifyPhone`).

## iPhone side — one-time Shortcuts setup

1. On iPhone: **Files** app → **Browse** → **iCloud Drive**. Confirm the
   `notify-iphone/` folder exists (created the first time you run the CLI
   or `notifyPhone()` on the Mac).
2. **Shortcuts** app → **Automation** tab → **+** → **New Automation**.
3. **When** → scroll to **File** category → **File** → set **Folder** to
   `iCloud Drive / notify-iphone`. Set **File** = *Any*. Set **Run** =
   **Immediately** (so it fires without confirmation).
4. **Next** → **New Blank Automation**.
5. Add these actions in order:

   | # | Action                         | Notes                                                  |
   |---|--------------------------------|--------------------------------------------------------|
   | 1 | **Get Contents of File**       | input = Shortcut Input (the added file)                |
   | 2 | **Get Dictionary from Input**  | parses the JSON                                        |
   | 3 | **Get Dictionary Value**       | key = `title`                                          |
   | 4 | **Set Variable** → `t`         | value = the dictionary value                           |
   | 5 | **Get Dictionary Value**       | key = `body`                                           |
   | 6 | **Set Variable** → `b`         |                                                        |
   | 7 | **Get Dictionary Value**       | key = `url`                                            |
   | 8 | **Set Variable** → `u`         |                                                        |
   | 9 | **Show Notification**          | Title = `t`, Body = `b`                                |
   | 10| **If** `u` *has any value*     |                                                        |
   | 11| ↳ **Open URLs** = `u`          | (optional — only if you want auto-open on tap)         |
   | 12| **End If**                     |                                                        |
   | 13| **Delete Files** = Shortcut Input | so the folder doesn't accumulate; safe — sync is one-way Mac→phone |

6. **Done**. The automation now fires every time a new `.json` lands in
   `notify-iphone/`.

## Gotchas

- **iCloud Drive must be enabled** on both Mac (System Settings → Apple ID →
  iCloud → Drive on) and iPhone (Settings → [Apple ID] → iCloud → Drive on).
- **Sync delay is usually 2-15 s.** If the iPhone is on cellular with iCloud
  cellular sync off, sync waits for Wi-Fi. For latency-critical paths, use
  iMessage-to-self instead (instant push via APNs).
- **Personal Automation only — not Home / Calendar.** "Run Immediately" is
  what avoids the "tap to confirm" prompt.
- **Atomic writes are mandatory.** `bin/notify-iphone` and `notifyPhone()`
  both stage to `.<id>.json.tmp` and rename, so the iPhone never sees a
  partially-written JSON. If you write your own dropper, do the same.
- **Step 13 (Delete Files) is recommended** — without it the folder grows
  unbounded and the iPhone re-processes nothing (Shortcuts only fires on
  *new* additions), but Files-app browsing slows down with thousands of
  stale entries.
- **Sound handling is limited.** Show Notification on iOS doesn't expose
  custom sound files; the `sound` field in the JSON is currently advisory.
  For a louder alert, add a **Play Sound** action after Show Notification.
- **Tap behavior:** Show Notification by itself does *not* run the rest of
  the automation on tap — the actions all run when the file lands.
  Conditional Open URLs (step 11) fires immediately, not on tap. If you
  want true on-tap routing, replace Show Notification with a notification
  whose body is a `shortcuts://` URL the user can long-press to open.

## When to use which transport

| Need                                                | Use                              |
|-----------------------------------------------------|----------------------------------|
| Banner on this Mac, no payload                      | `notify()`                       |
| Banner on this Mac with Open/Reveal actions         | drop into `notify-inbox/`        |
| Banner on iPhone, away from desk                    | `notifyPhone()` / `notify-iphone`|
| Instant push to phone (sub-second, cellular OK)     | iMessage to self via `osascript` |
| Persistent alarm on phone (lock-screen sticky)      | Reminders with `remind me date`  |

Fan-out is fine — worker code can call both `notify-iphone --title X --body Y`
and drop a JSON into `notify-inbox/` so the same event banners both surfaces.

## See also

- `wiki/entities/appletoolbox.md` — the menu-bar host
- `wiki/concepts/finder-tag-pipeline.md` — first instance of the trigger→worker chassis
- `wiki/concepts/mail-flag-pipeline.md` — fourth instance of the same chassis
