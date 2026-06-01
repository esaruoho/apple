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

## Tested 2026-06-01 — first NOT live, then VERIFIED WORKING after enabling

**First pass (before it was enabled):** eppc did not work — `com.apple.eppc` not
loaded, port 3031 closed on Tailscale + LAN. Can't enable remotely (needs admin;
the file-drop bridge is unprivileged).

**Second pass (after Esa enabled "Remote Application Scripting" on the Mini): IT
WORKS, including over Tailscale.**
- 3031 now **OPEN** from the laptop on both `100.117.30.102` (Tailscale) and
  `192.168.32.102` (LAN). Firewall is off, so the Tailscale interface reaches it.
- `tell application "Finder" of machine "eppc://esaruoho@cloudcitymacmini" to get
  version` → **`26.3`** (the Mini's macOS), `exit 0`, authenticated seamlessly
  (no password prompt — same user/keychain context).
- Drove the Mini's Finder live: `Macintosh HD · free 241 GB / 494 GB`;
  `get name of home` → `esaruoho`. **~4.4s per `osascript` invocation** (mostly
  connection + auth setup; once connected, events are sub-second).

### Gotchas found
- **`launchctl list` / `lsof -iTCP:3031` as the user show "not loaded" even when it
  IS listening** — launchd (pid 1, system domain) holds the socket and spawns
  AEServer on demand. Trust a TCP probe (`nc -z host 3031`), not user-context lsof.
- **Faceless apps must already be running on the remote.** `System Events of machine
  eppc://…` returned **-600 "Application isn't running"** — it doesn't auto-launch
  over eppc. Finder/Music (always-running or auto-launching) are fine.
- Seamless auth here is same-username + reachable; cross-account would prompt.

### Auth reality — eppc re-prompts EVERY connection (settled 2026-06-01)
My earlier "authenticated seamlessly" was wrong — those prompts were landing on
Esa's screen and he was typing them. The hard truth, after a long investigation:
- **Each `osascript … eppc://…` is a fresh process → fresh connection → fresh
  auth dialog** ("Authorization is required for 'Finder' on eppc://cloudcitymacmini").
- A **hand-created `eppc` keychain item (even `-T /usr/bin/osascript`) is NOT honored** —
  still prompts.
- Worse, the dialog's **"Add to keychain"/"Remember" creates a NEW item each time
  instead of matching the prior one** → duplicate eppc creds pile up (we found 2,
  cleared them). Even after clearing to ZERO and saving exactly ONE clean credential
  with "Add to keychain" checked, **the very next connection still prompted**
  (screenshot-confirmed, macOS Sequoia 15.6.1 → Mini Tahoe 26.3).
- Conclusion: **the keychain does not give silent eppc reuse on current macOS.**
  Treat eppc as **one password prompt per connection**, full stop. Do NOT spend
  more time trying to cache it — this is settled.

**Mitigations (the only real ones):**
- **One-connection "snapshot" probe** (`bin/eppc-probe … snapshot`) bundles several
  reads into a SINGLE connection → one prompt per readout instead of one per field.
- For zero-auth cross-machine work, use the **Syncthing panel-inbox runner** — it
  never authenticates interactively. eppc/APPS is the "live answer, costs a password"
  tool; Syncthing is the daily driver.
- A persistent resident osascript holding one connection could auth once for many
  events, but the first connect still prompts and it's a heavier build — not pursued.

Verdict: eppc is a **real, live third transport** for Fleet — synchronous, drives
the peer's actual apps, ~4s/call, faster than the Syncthing runner. Syncthing stays
the durable default (survives sleep/offline); eppc is the live fast path when the
peer is up.

## Related
- [[automation-architecture-7-layers]] · where Apple Events sit under Shortcuts/App Intents
- [[fleet-panel-unification]] · the runner this becomes a third transport for
- [[wwsd-decision-tree]] · when to reach for AppleScript/Apple Events vs other tiers
