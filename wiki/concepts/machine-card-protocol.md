---
description: A uniform, zero-token self-descriptor every computer in the fleet emits — shape, ports, running, skills — so any machine can introduce itself ("what kinda computer are you?") and advertise its capabilities to the others.
---

# Machine Card protocol

> *"A true apple skill is able to, zero-token, roll me a knowledge of this computer, and display next to it another computer we can connect to."* — Esa, 2026-06-01

`apple-report` answers **one** of the four questions, for **one** machine, as a 679-line text dump recomputed every call. That's a small portion of the protocol, and an inefficient one. The Machine Card is the whole thing: a small structured descriptor that **every** computer publishes, in the **same shape**, readable with **zero LLM tokens**, so the fleet can be laid out side-by-side and machines can discover each other's skills.

## The four faces of a card

A computer, in Esa's framing, has a shape, access ports, information running in it, and — added in the same conversation — a set of skills derived from the software on it. Those are the four faces:

| Face | Answers | Source (this Mac) | Changes |
|---|---|---|---|
| **shape** | *"what kind of computer are you?"* — chip, cores, RAM, GPU, storage, displays, enclosure, model id | `apple-report --json` → `hardware`, `gpu`, `memory`, `storage`, `ai` | rarely → **cache** |
| **ports** | *"how do I reach you?"* — physical I/O (Thunderbolt/USB/HDMI/Ethernet) **and** reachability channels (Tailscale SSH, Syncthing queue, file-drop bridge, iMessage, 127.0.0.1 panel, MCP servers) | `system_profiler SPThunderboltDataType`/`SPUSBDataType` + the channel table below | semi-static → **cache** |
| **running** | *"what's alive right now?"* — processes, daemons, services, queue depths, thermal/CPU/mem, battery | `ps`/`pmset`/queue scan; for peers, the `*-heartbeat.json` files | live → **cheap quick scan** |
| **skills** | *"what can you do for me?"* — capabilities derived from installed software + running services | `~/.claude/skills/` enumeration + which heartbeats are warm | on install → **cache, refresh on dir mtime** |

The efficiency win over `apple-report` is the split: **shape/ports/skills are cached, only `running` recomputes.** "Roll me a knowledge of this computer" is then near-instant.

## Public/private split — what is safe to post

"Exact shape" mixes identifying fields with descriptive ones. The scan (`apple-report --json`) produces all of it; the protocol **carves a postable subset**. Classify every field on two axes — stable vs volatile, public vs private — and **only the stable+public quadrant is written to the synced queue**:

|  | **Public — safe to post** | **Private — local-only, never posted** |
|---|---|---|
| **Stable** | 🟢 **THE POSTABLE CARD**: `chip`, `model_name`, `model_identifier`, `cores_*`, `ram_gb`, `gpu_cores`, SSD capacity, `macos_version`/`build`, all `ai.*` | 🔴 `serial`, `model_number` (configure-to-order purchase id), `boot_rom`, Ethernet/Wi-Fi MAC addresses, battery serial |
| **Volatile** | 🟡 coarse liveness: up/down, battery %, queue depths | 🔴 exact IPs, Wi-Fi SSID, precise load, **security posture** (`FileVault Off`, SIP) |

Judgment calls: **hostname** becomes the card's `id` (you need a stable name to address the peer — a feature, not a leak); **security booleans** stay local-only.

This is the repo's [public/private split doctrine](../../README.md) (the `.gitignore` philosophy) applied to live machine data. It drives the two emitter modes:

- `machine-card` → **full**, local-only — feeds this machine's own panel (serial, FileVault, IPs and all).
- `machine-card --public` → **the green quadrant only** — what gets written to the Syncthing queue. The Mini runs the identical tool with `--public`; neither machine reaches into the other; nothing private crosses the wire.

## Transport — Syncthing-default, robust over brittle

Each machine publishes its own card; nobody reaches into anybody else.

- **This machine (local):** card computed on demand — `apple-report --json` + skill enumeration + a cheap process scan.
- **Peer machines (the Mini):** a timer writes the machine's card to its Syncthing-mirrored queue, exactly like the 12 service heartbeats already do. The local Mac **reads the peer card from the synced folder** — no SSH, no mDNS, no Tailscale dependency for the read path. (SSH stays the last-resort verb channel per the global rule.)

The transport is **already running**. `~/work/comms/queue/*-heartbeat.json` proves the Mini publishes liveness for `pakettibot`, `voicebox`, `whisp`, `ocr`, `merlib-mirror`, `repo-puller`, `spine` (+ guardians). The protocol just adds **one** more published file per machine — the full card — alongside the per-service heartbeats it already emits. Warm heartbeats double as the peer's live **skills** advertisement: a warm `whisp-heartbeat.json` *is* the Mini saying "I can transcribe."

## Skill advertisement — the handshake

The fourth face makes the fleet conversational. Each card carries a `skills` list keyed off:
1. **Installed software** — the skill loader (`~/.claude/skills/`), installed `.app` bundles, CLIs on PATH.
2. **Live services** — a warm heartbeat means the capability is not just installed but *running and reachable now*.

So "which machine can OCR this?" is answered by reading cards, not by asking an LLM: the Mini's card lists `ocr` with a warm heartbeat → route there via its `ocr-inbox` port. This is Bonjour-for-skills over the channel that already exists.

## Render — apple-panel grows a Fleet view

`bin/apple-panel` already renders capability **cards** on 127.0.0.1. The protocol's natural display surface: a two-pane (N-pane) Fleet layout — **this Mac's card on the left, the peer's card on the right, the live channels drawn between them.** Each face is a section; warm/cold dots show liveness; the `ports` face is clickable (each reachability channel is a real connect action).

## Build increments

1. **`bin/machine-card`** — emits this machine's card as JSON `{identity, shape, ports, running, skills}`. Wraps `apple-report --json` for shape/ai, adds ports + skills + live scan. `--cache` writes shape/ports/skills to `~/.cache/apple/machine-card.json`; default run refreshes only `running`.
2. **Peer publisher** — a Cloudcity timer that runs `machine-card` on the Mini and drops it to `~/work/comms/queue/machine-card-<host>.json` (Syncthing-mirrored). Reuses the existing heartbeat-writer pattern.
3. **`bin/fleet`** — reads the local card + every `machine-card-*.json` in the queue, prints the fleet side-by-side (text), `--json` for machines.
4. **apple-panel Fleet view** — two-pane render with channels drawn between, ports as connect buttons.
5. **`/machine-card` + `/fleet`** zero-roundtrip slashes via `commands/install.sh`.

## Why this is the apple skill, not a bolt-on

It's the [zero-roundtrip pattern](../../README.md) (bin + slash, no token after invocation), the [Syncthing-default channel](MacMini.md) (robust over brittle), and Apple-native throughout (`system_profiler`, `pmset`, `ps`, stdlib JSON). It turns `apple-report` from a one-machine dump into the fleet's nervous system.

## Relationship to the Companion-Mac fabric

The Machine Card is the **descriptor layer**; [`companion-mac/`](companion-mac-fabric.md) is the **transport layer** beneath it.

- companion-mac = how machines *talk*: Syncthing queues, workers, heartbeats (`lib/heartbeat.sh`), repo-puller, SSH preflight, boot-app panes.
- machine-card + fleet = how machines *describe themselves and discover each other's skills*: the four faces, published over that transport.

`machine-card --publish` writes into companion-mac's `queue/`, and `lib/heartbeat.sh` is the natural carrier for the card. The peer publisher (increment 2) should be a companion-mac heartbeat/service, not a bespoke timer.

**Whitelabel rule (must fix):** companion-mac's seam is *no private-instance detail in public mechanism code*. Today `machine-card` hardcodes a Cloudcity `SERVICES` map and `fleet` hardcodes `PEER_HEARTBEAT_HOST`/`SERVICE_VERB`. Those belong in the gitignored `companion.conf` (`$COMPANION_HOST`, `SERVICES`) or be discovered from the queue — not baked into the tool. `fleet` already discovers services from the `*-heartbeat.json` glob; the rest should follow.

## Known issues (2026-06-01, verified live)

1. **Heartbeat `ts` came in three formats** — int seconds, int ms (Node services), ISO-8601 string. `machine-card` did `time.time() - float(ts)`, so ms timestamps went negative → clamped to 0 → *every Node service read as warm forever*. **Fixed**: shared `ts_to_epoch()` in both `machine-card` and `fleet`; verified both now agree (0 warm, services cold at ~400s).
2. **Warm threshold vs sync lag** — the Mini's heartbeats arrive ~6–8 min stale on the laptop (Syncthing latency), so `WARM=180s` marks a healthy Mini cold from here. Threshold must account for sync lag (likely ~600s; tune to actual beat cadence + sync interval).
3. **Service attribution (open — needs host-stamped heartbeats)** — `machine-card` on RayMac lists the Mini's queue services (`ocr`, `whisp`, …) inside RayMac's *own* warm skills, because the Syncthing queue mirrors those heartbeats to every machine. The `fleet --handshake` network view inherits this: it shows `whisp on RayMac` when whisp only runs on the Mini. **Root cause:** the heartbeats carry no `host` field (and only `pakettibot` carries a `pid`), so a reader genuinely cannot tell who wrote a heartbeat. **Fix:** stamp `"host"` into every heartbeat at the source — one line in companion-mac's `lib/heartbeat.sh` — then `compute_skills` marks a service warm-as-mine only when `heartbeat.host == this machine`. Generic, whitelabel-clean (no per-service process patterns), but touches the transport package and needs a redeploy. Until then, treat handshake skill→host attribution as "warm somewhere in the fleet," not per-machine truth.

4. **Running-data publish fix not yet deployed to the Mini's passive publisher** — `public_card()` no longer coarsens running (load/mem/uptime/top now travel), proven live via `fleet --handshake` (SSH-stdin carries the fixed emitter). But the Mini's resident `machine-card-publish.sh` still runs its committed (coarse) clone, so the *Syncthing-published* `machine-card-CloudcityMacMini.json` stays thin until the fix is committed+pushed+pulled. The active handshake is rich now; the passive published card is not.

## Cross-refs

- `apple-report` — the shape seed (`bin/apple-report --json`)
- `bin/apple-panel` — the render surface
- [MacMini](../devices/MacMini.md) — the canonical peer; channel hierarchy
- `~/.claude/CLAUDE.md` — Syncthing-default mandatory rule
- Existing transport proof: `~/work/comms/queue/*-heartbeat.json`
