---
description: What Apple Events are (the bedrock of all Mac automation) and Remote Apple Events / eppc — the native way one Mac drives another. The third Fleet transport: synchronous, real-time, drives the actual apps on a peer.
---

# Apple Events & Remote Apple Events — the native inter-machine channel

## What an Apple Event is

An **Apple Event** is the structured message one macOS process sends to another to
ask it to *do* something or *return* data. It has been the foundation of Mac
automation since System 7 (1991).

- Each event carries an **event class + event ID** (historic four-char codes,
  e.g. `core`/`getd` = "get data") and a tree of typed parameters
  (**AEDesc** descriptors).
- **Everything scriptable rides on Apple Events.** AppleScript, JXA, `osascript`,
  Automator's "Run AppleScript", Shortcuts' "Run AppleScript", Mail-rule scripts —
  all of them *compile down to Apple Events*. When you write
  `tell application "Finder" to get name of front window`, AppleScript turns that
  into Apple Events that Finder's event handlers answer.
- An app declares what events it understands in its **scripting dictionary**
  (`.sdef`) — the verbs/nouns you browse in Script Editor's Library. That
  terminology is the human layer over the raw four-char codes.
- **Locally, TCC gates them.** Privacy & Security → Automation is "X wants to
  control Y" — permission to send Apple Events from one app to another.

Apple Events are the deepest, most durable automation layer Apple ships. Shortcuts
and App Intents are the modern face; Apple Events are the bedrock under them. This
is Sal Soghoian's whole domain. See [[automation-architecture-7-layers]].

## Remote Apple Events (what "I enabled it" turns on)

The same messages, sent to **another Mac over the network**. This is Apple's
oldest inter-computer automation — "Program Linking" in System 7, today
**System Settings → General → Sharing → Remote Apple Events**
(`sudo systemsetup -setremoteappleevents on`).

- **Transport:** the `eppc` protocol (Event Program-to-Program Communication),
  TCP **port 3031**. Addressed by URL: `eppc://user@host/`.
- **Syntax:**
  ```applescript
  tell application "Finder" of machine "eppc://esaruoho@cloudcitymacmini"
      get version
  end tell
  ```
  You can drive **any scriptable app** on the remote Mac — Finder, Music, Keynote,
  Mail, Safari, System Events — and get **real return values back, synchronously**.
- **Auth:** you authenticate as a user account on the *remote* Mac (login
  keychain / Kerberos / directory). Only the **target** needs Remote Apple Events
  ON; the sender just needs to reach it. Password-in-URL is legacy and often
  blocked on modern macOS.

## Where it fits Fleet — a third transport

Fleet's runner now has two execution paths; Apple Events is a qualitatively
different third one:

| Transport | Nature | Runs | Reach |
|---|---|---|---|
| **local `apple-panel --run`** | inline | curated registry actions | this Mac |
| **Syncthing panel-inbox** (built) | async, robust, survives sleep/offline | curated registry actions | any peer, eventually |
| **Remote Apple Events / eppc** | **synchronous, real-time, returns values** | **the actual apps** on the peer | peer reachable *now* |

The leap: Apple Events let Fleet do more than "run my scripts on the Mini." It can
**tell the Mini's Finder to reveal a file, its Music to play, its System Events to
report the frontmost app — and get the answer back immediately.** That is the
native-Apple realization of "every device responds to commands."

## The honest caveat (robust vs brittle)

Remote Apple Events is powerful but **brittle**, exactly like SSH:
- The peer must be reachable *right now*; eppc was designed for LAN/Bonjour, so
  over Tailscale it needs the Tailscale name/IP and port 3031 open.
- Auth and TCC can prompt or fail in non-GUI contexts.

So per the standing rule (*robust wins over brittle*, [[feedback]] / cloudcity
skill): **Apple Events is the opportunistic fast path; Syncthing stays the
default.** Use eppc when the peer is live and you want a synchronous result from a
real app; fall back to the Syncthing job runner otherwise. Same posture as SSH.

**Verify before designing on it:** send one real event
(`tell app "Finder" of machine "eppc://<user>@cloudcitymacmini" to get version`)
and confirm it authenticates and returns. If it does, wire an "Apple Events"
transport into Fleet alongside the Syncthing one.

## Tested 2026-06-01 — eppc was NOT live (robust-beats-brittle, confirmed)

Tried to prove the eppc channel laptop → CloudcityMacMini and it did **not** work:
- `com.apple.eppc.plist` ships on the Mini but is **not loaded** (`launchctl print
  system/com.apple.eppc` empty, nothing in `launchctl list`). So nothing listens.
- Port **3031 closed** from both Tailscale (`100.117.30.102`) and LAN
  (`192.168.32.102`).
- Can't enable remotely — `systemsetup -setremoteappleevents on` needs admin and the
  file-drop bridge runs unprivileged.

Meanwhile the **Syncthing panel-inbox runner worked**: ran `report` on the Mini,
got the Mini's real spec back (`Mac mini Mac14,12 · M2 Pro · 32 GB · macOS 26.3`),
`ok: True`, ~17s. That is the durable channel; eppc stays a *would-be* fast path
that has to be switched on (admin, on the Mini) and is LAN-bound by nature.

To revisit eppc: enable Remote Apple Events on the Mini, confirm `lsof -iTCP:3031`
shows launchd, be on the same LAN (or open 3031 to the Tailscale interface), then
`osascript -e 'tell app "Finder" of machine "eppc://esaruoho@cloudcitymacmini" to get version'`.

## Related
- [[automation-architecture-7-layers]] · where Apple Events sit under Shortcuts/App Intents
- [[fleet-panel-unification]] · the runner this becomes a third transport for
- [[wwsd-decision-tree]] · when to reach for AppleScript/Apple Events vs other tiers
