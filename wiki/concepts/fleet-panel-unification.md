---
description: The unified inter-computer script runner — Fleet (device roster) + Apple Panel (action registry) merged into one fabric. Pick a machine, see its capabilities, run a script there, get the result back. Honors Syncthing-default transport.
---

# Fleet × Panel — the inter-computer script runner

> The idealized version is that **Fleet and Apple Panel are the same thing**:
> a roster of every device that *also* exposes, per device, every script/worker
> it can run — so you select a machine, see its capabilities, run one, and the
> result comes back. Control devices and fetch information from them, use
> workers, run scripts — all from one window.

## The two halves, today

| | **Fleet.app** | **Apple Panel** |
|---|---|---|
| Answers | "What machines exist?" | "What can THIS machine do?" |
| Cards are | peer Macs | runnable actions |
| Tech | SwiftUI + Bonjour + Syncthing | Python HTTP server + web UI |
| Already has | live roster, machine cards, **`route(file:toInbox:)`** remote dispatch | curated **ACTIONS** registry, **`/run`** executor (loopback) |

The seam between them is tiny because the plumbing already exists:

- `bin/machine-card` already publishes `ports.channels` (incl. a `panel` http
  channel + a `file-drop-bridge` command inbox) and `skills[]` with `inbox` +
  `verb`.
- Fleet already reads peer cards (Bonjour live + Syncthing) and already drops
  jobs into a peer's Syncthing-mirrored inbox.
- Panel already has a **curated** registry (no arbitrary shell) and a `/run`
  endpoint that validates an action id and runs it with argv (no shell).

## The unified model

```
┌─ Fleet (the one window) ─────────────────────────────┐
│  ROSTER          this Mac · Mini · MacBook · …        │  ← Bonjour + Syncthing (exists)
│  per machine →   CAPABILITY CARDS (its Panel registry)│  ← NEW: publish registry into card
│  click Run on a card →   dispatch to that machine     │  ← localhost: local /run
│                                                       │     remote: Syncthing panel-inbox
│  result renders inline                                │  ← panel-results/, mirrored back
└───────────────────────────────────────────────────────┘
```

Three transports, picked by where the target is — **Syncthing is the default**,
network HTTP is never required (honors the global "robust wins over brittle"
rule; no network-exposed remote-code surface):

| Target | How a run is dispatched |
|---|---|
| **localhost** | local Panel `/run` (inline) |
| **off-LAN / asleep peer** | Syncthing `panel-inbox/<job>.json`; peer's panel-worker runs it, writes `panel-results/<job>.json`, Syncthing mirrors it back |
| **reachable peer, want a live answer from a real app** | **eppc / Remote Apple Events** — `bin/eppc-probe` over `eppc://user@host`, synchronous, ~4s (the **APPS · eppc** face). Built 2026-06-01. See [[apple-events-and-remote]] |

Three transports now live: **local `--run`** (curated scripts, inline) ·
**Syncthing panel-inbox** (curated scripts, async, the robust default) · **eppc**
(the peer's *actual apps*, synchronous, opportunistic). eppc drives Finder/Music/
etc. and returns values; it needs Remote Application Scripting on + reachability,
so it's the fast path, not the default.

### Why a `panel-inbox` worker, not network HTTP

Exposing each machine's `/run` on the LAN would be remote code execution over
the wire. Instead, every machine runs a **panel-worker** that watches its own
`~/work/comms/queue/panel-inbox/`, validates each job against its OWN curated
registry (same `ACTION_BY_ID` guard the HTTP server uses), runs it, and writes
the result. This is the **5th instance of the trigger→worker chassis** (Finder
tag, Voice Memo `#process`, Stickies, Mail flag, now Panel jobs). The registry
is the allowlist; Syncthing is the transport; nothing new is exposed.

## Build increments (each independently shippable)

1. **Publish + render local registry in Fleet.** `bin/machine-card` gains a
   `panel_actions` face (id, label, group, kind, arg) read from the panel
   registry. Fleet renders, per machine card, that machine's action cards.
   Clicking Run on THIS machine calls the local panel `/run`. *No remote risk —
   proves the merge.*
2. **Remote dispatch via Syncthing.** Add `bin/panel-worker` (watches
   `panel-inbox/`, runs via the curated registry, writes `panel-results/`).
   Fleet's Run on a remote card drops a job + polls the result. Reuses Fleet's
   existing `route()`.
3. **Unify the shell.** Fleet becomes the single app; the Panel web UI stays as
   the localhost-only fallback. `/fleet` is the one entry point: roster + run.

## Constraints carried in

- **Apple-native only** (SwiftUI/AppKit/Network + Python stdlib). No new deps.
- **Curated registry is the security boundary.** A machine only ever runs its
  own registered actions; a job names an action id + arg, never a command.
- **Syncthing-default, SSH/HTTP opportunistic.** See global rule; the Mini is
  Tailscale/Syncthing-reached, never assume a live socket.
- `.app` bundles are build artifacts (gitignored); commit Swift + build.sh only.

## Related

- [[companion-mac-fabric]] · the whitelabeled comms package this rides on
- [[finder-tag-pipeline]] · the trigger→worker chassis, instance #1
- [[mail-flag-pipeline]] · chassis instance #4
- Apple Panel: `bin/apple-panel` (registry + `/run`) · `panel-app/PanelApp.swift` (native webview)
- Fleet: `fleet/Fleet.swift` (roster + `route()`) · `bin/machine-card` (the card)
