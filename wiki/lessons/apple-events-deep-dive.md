---
description: A hands-on deep dive into Local and Remote Apple Events — the anatomy of an event, how AppleScript compiles to one, the TCC gate, and how one Mac drives another over eppc. Companion to the concept page.
---

# Apple Events — Local & Remote, the deep dive

Apple Events are the structured messages one program sends another to make it act
or return data. They are the bedrock of Mac automation since System 7 (1991).
This page is the hands-on version of [[apple-events-and-remote]].

## Part 1 — Local Apple Events (one Mac)

### Anatomy of an event

Every Apple Event is identified by two four-character codes:

- **Event class** (`AEEventClass`) — which suite, e.g. `aevt` (required), `core` (standard).
- **Event ID** (`AEEventID`) — which verb in that suite.

Plus a tree of **typed parameters** (`AEDesc` descriptors): a direct object
(`----`), named parameters, and **object specifiers** (`obj `) that describe
targets like "the 3rd word of document 1" as nested records.

The events nearly every app must handle (the **required suite**):

| class/ID | meaning |
|---|---|
| `aevt`/`oapp` | open application |
| `aevt`/`odoc` | open documents |
| `aevt`/`pdoc` | print documents |
| `aevt`/`quit` | quit |

The **standard suite** (`core`) adds the verbs scripting leans on:
`getd` (get data), `setd` (set), `cnte` (count), `doex` (exists), `crel` (make),
`delo` (delete), `move`, `clon` (duplicate).

### How AppleScript becomes an Apple Event

You never hand-assemble four-char codes. AppleScript reads the target app's
**scripting dictionary** (`.sdef`) — the human terms ("name", "window", "make")
mapped to codes and an object model — and compiles your English into events.

```applescript
tell application "Finder" to get name of home
```

compiles to a `core`/`getd` event whose object specifier resolves
`home → name property`, sends it to Finder, and Finder replies with a string.

You can even write **raw** events with chevrons when there's no terminology:

```applescript
tell application "Safari" to «event aevtquit»
```

### Ways to send locally

- `osascript -e '…'` (AppleScript) or `osascript -l JavaScript -e '…'` (JXA)
- compiled `.scpt`, Script Editor, Automator's & Shortcuts' "Run AppleScript"
- from code: `NSAppleScript`, `NSAppleEventDescriptor`, or the C API `AESendMessage`
- **System Events** — the system's scripting bridge app: process lists, UI
  scripting, defaults, folder actions. `tell application "System Events" to …`

### The security gate (TCC Automation)

Since macOS Mojave, the *first* time process A sends an Apple Event to app B,
macOS prompts **"A wants to control B"** and records the decision per
(source → target) pair in Privacy & Security → **Automation**. Sandboxed senders
also need the `com.apple.security.automation.apple-events` entitlement. This is
why a script that worked in Terminal silently does nothing under launchd — the
launchd context never got the grant.

### Apple Events vs App Intents (don't confuse them)

- **Apple Events / AppleScript** — classic, dictionary-based, works against *any*
  scriptable app, returns rich values. The thing this page is about.
- **App Intents / Shortcuts** — modern, Swift-declarative, per-app, surfaced in
  Shortcuts/Siri/Spotlight. **Not built on Apple Events** — a parallel surface.

Some apps are scriptable but expose no App Intents, and vice versa. Knowing which
layer an app supports tells you how to automate it. See [[automation-tiers]].

## Part 2 — Remote Apple Events (one Mac → another)

The *same* events, addressed to a process on a different Mac. Apple's oldest
distributed-computing feature — System 7 "Program Linking" / the PPC Toolbox,
today **Sharing → Remote Apple Events**.

- **Daemon:** `com.apple.eppc` (a LaunchDaemon) listening on TCP **3031**.
- **Protocol:** `eppc` = Event Program-to-Program Communication.
- **Address:** `eppc://[user@]host[/app]`. In AppleScript:
  ```applescript
  tell application "Finder" of machine "eppc://esaruoho@studio.local"
      get the name of every disk
  end tell
  ```
  Any scriptable app on the far Mac, **synchronous**, real return values.
- **Auth:** you authenticate as a *user account on the target* (keychain /
  Kerberos / directory). Password-in-URL is legacy and usually blocked now.
- **Enable (on the target, admin):** the Sharing toggle, or
  `sudo systemsetup -setremoteappleevents on` — this loads `com.apple.eppc` and
  opens 3031. Verify with `lsof -nP -iTCP:3031`.

### The `using terms from` trick

To compile `tell app "X" of machine "eppc://…"`, the *local* machine needs X's
dictionary. If the local Mac lacks app X, wrap it so it compiles against a local
dictionary but runs remotely:

```applescript
using terms from application "Finder"
    tell application "Finder" of machine "eppc://esaruoho@studio.local"
        get the name of the startup disk
    end tell
end using terms from
```

### Reality check (modern macOS)

- It's **LAN/Bonjour oriented**. Same subnet is the reliable case.
- Over Tailscale/VPN it *can* work (the launchd socket binds all interfaces) only
  if the firewall allows 3031 on that interface — not guaranteed.
- Auth is the usual friction on Sequoia/Tahoe.
- It is literally remote-code-execution surface — only on trusted networks.
- **Tested 2026-06-01:** not live on CloudcityMacMini (`com.apple.eppc` unloaded,
  3031 closed on Tailscale + LAN). See [[apple-events-and-remote]].

### Where it sits for Fleet

Three transports, by trade-off:

| Transport | Sync? | Runs | Reach | Default? |
|---|---|---|---|---|
| local `apple-panel --run` | inline | curated scripts | this Mac | — |
| Syncthing panel-inbox | async | curated scripts | any peer, eventually | **yes (robust)** |
| Remote Apple Events / eppc | **sync** | **the real apps** | peer reachable now | opportunistic |

eppc is the only one that drives the peer's *actual apps* and returns values live.
It's also the most brittle (off by default, LAN-bound, auth/TCC). So: durable work
on Syncthing; reach for eppc when the peer is live and you want a real app's answer
now. Same posture as SSH.

## Related
- [[apple-events-and-remote]] · the concept-level companion
- [[automation-tiers]] · where Apple Events sit among the automation tiers
- [[fleet-panel-unification]] · the runner eppc would join as a third transport
- [[wwsd-decision-tree]] · choosing Apple Events vs Shortcuts vs shell
