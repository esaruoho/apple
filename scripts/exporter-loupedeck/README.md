# exporter-loupedeck

AppleScript wrappers that bind exporter actions to Loupedeck Live /
Stream Deck / Contour Shuttle Pro buttons. Each `.scpt` is
self-contained — point the controller at it.

These are **reference scripts**: copy + edit for your own bindings.
The mapping below is what Esa uses on his Loupedeck Live.

## How Loupedeck binds them

In Loupedeck Service:

1. Add a `Custom → AppleScript` action on a button.
2. Point at one of the `.scpt` files (compile via `osacompile -o
   foo.scpt foo.applescript` or use the `bin/compile-loupedeck.sh`
   helper).
3. (Optional) set Subroutine + Arguments on knob actions if the
   script defines a handler.

## Reference bindings

| Button | What it shows / does | Script |
|--------|----------------------|--------|
| Today | Today's calendar events | `today.applescript` |
| Latest recording | Open newest Voice Memo | `latest-recording.applescript` |
| Snap | Capture a JPG via FaceTime camera | `snap.applescript` |
| Tabs status | Total open tabs across windows | `tabs-status.applescript` |
| Hey Sal | Trigger Hey Sal voice mode | `hey-sal.applescript` |
| Reminders status | Per-list open reminder counts | `reminders.applescript` |

## Why hardware controllers

Sal Soghoian's WWDC 2016 session 717 closes with: **"voice is a peer
to touch, keys, and cursor."** Loupedeck buttons are touch. Hey Sal
is voice. Same data layer underneath; different physical surfaces.
Every script here invokes the exporter binaries the same way.
