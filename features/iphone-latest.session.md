# iPhoneLatest.app — session

## How to get back

- Transcript: file:///Users/esaruoho/.claude/projects/-Users-esaruoho-work-apple/80e0eb8a-1733-48c4-8ec5-10bc261249c6.jsonl
- Session ID: `80e0eb8a-1733-48c4-8ec5-10bc261249c6`
- Resume: `claude --resume 80e0eb8a-1733-48c4-8ec5-10bc261249c6`
- Transcript start: `2026-11-10T08:44:59.023Z` (first timestamp in the transcript, verified)
- Card: [iphone-latest.feature](iphone-latest.feature)

## What happened

Esa wanted to show something on the desk in a Claude chat. The phone was on a cable to the laptop, so why wouldn't a menu-bar "newest photo" thumbnail just drag into Terminal?

**Round 1: USB.** `bin/iphone-latest` (ImageCaptureCore import → sips JPEG → clipboard) worked on the first try. Esa asked for a separate menu-bar icon instead of AppleToolbox, then live auto-refresh. That turned into a long run of failures, each found only when Esa tested:
- the 2 s session close/reopen loop killed iOS's item stream;
- two concurrent ImageCaptureCore sessions;
- -9934 "not ready" downloads;
- a stale catalog when a session is opened while the phone is locked;
- photos with no creationDate yet, out-of-order arrival, and the IMG_ counter wrapping;
- a refresh-callback race that left the ⏳ stuck.

What finally made the work evidence-based was per-step app logging. It showed iOS publishing new photos one at a time, 15–60 s after the shot, and sessions going stale. Esa was rightly frustrated by fixes being guessed instead of measured. That lesson is recorded in `iphone-latest/FINDINGS.md`.

Esa asked to drop the clipboard (drag only) and to get notifications. Notifications worked, but the delay stayed.

**Round 2: Continuity Camera.** Esa asked for it. The first attempts left "Import from iPhone" grey. A probe app showed AppKit only activates `importFromDeviceIdentifier` in the main menu, which fixed it. Esa then asked for one click straight to Take Photo. That version over-triggered: double-click and icon-dismiss both re-fired the camera, so the camera kept popping up. The final spec, in Esa's words: *"A BIG BUTTON, A RESULT, A DRAG."* The app was rewritten lean (504 → ~240 lines, all USB, watcher and notification code removed), gained a dismiss-click guard, a folder row, a proper icon, `SMAppService` Open at Login, and an install at `/Applications/iPhoneLatest.app`.

Esa: *"i think this is the best thing we've done thus far."*
