---
description: Make a LAN-only fleet peer's files available + queryable from anywhere on the tailnet by hopping through the always-on Mini (SSH ProxyJump, not a subnet router), plus an on-demand published file catalog. bin/fleet-files.
---

# Bridging a LAN-only Mac onto Tailscale via the Mini

## The ask

HertsiMacPro (`192.168.32.169`, 10.11.6) is **LAN-only** — not on the tailnet.
The Mini (`cloudcity`) is on **both** the LAN (`192.168.32.102`) and Tailscale
(`100.117.30.102`). Make Hertsi's files available + queryable via Tailscale,
through the Mini.

## Why NOT a subnet router

The textbook answer is `tailscale up --advertise-routes=192.168.32.169/32` on the
Mini. **Blocked here:** the Mini runs the **App Store / GUI Tailscale**, which is
sandboxed and can't advertise routes; IP forwarding is off. macOS subnet routers
are brittle even when available. Robust wins over brittle → don't route, **jump**.

(The Mini's `tailscale` CLI *is* now in PATH for status/ping/netcheck — a wrapper
at `/opt/homebrew/bin/tailscale` calling the bundle's **lowercase** `tailscale`
binary, mirroring RayMac. NB the bundle also has a capital-`Tailscale` GUI binary
that fatals with "bundleIdentifier unknown to the registry" if invoked as a CLI —
wrap the lowercase one. Route advertising stays blocked regardless.)

## The mechanism — SSH ProxyJump (zero new infra)

```
RayMac ──(Tailscale)──▶ cloudcity ──(LAN)──▶ hertsimacpro
ssh -J cloudcity esaruoho@hertsimacpro
```

The Mini is purely a TCP jump host; auth is end-to-end RayMac→Hertsi (our key is
already authorized on Hertsi; legacy OpenSSH 6.9 needs
`PubkeyAcceptedAlgorithms=+ssh-rsa`). No daemon, no IP forwarding, no route
approval. Works from anywhere the Mini is reachable on the tailnet. The jump host
resolves Hertsi by **bare hostname** (router DNS), so Hertsi's DHCP churn never
breaks the alias.

## bin/fleet-files

| verb | does |
|---|---|
| `setup <peer>` | writes a managed `~/.ssh/config` block → `ssh hertsi`, `sftp hertsi`, `rsync -e ssh hertsi:`, `sshfs hertsi:` all work tailnet-wide |
| `ls <peer> [path]` | list a remote dir through the jump |
| `index <peer> [path] [--publish]` | build a `path⇥size⇥mtime` catalog; `--publish` drops it in the Syncthing queue (`fleet-index/<peer>.tsv`) so **every** tailnet machine can search it even when the peer is asleep |
| `find <term> [--peer P]` | fixed-string (`grep -iF`, backtracking-safe) search of the catalog(s) |
| `mount <peer> [path]` | sshfs-mount locally, or print the `sftp://` Finder route |
| `screen <peer>` | Screen Sharing from anywhere — `ssh -L 5901→peer:5900` through the Mini, opens `vnc://localhost:5901` (`--stop` to tear down) |
| `finder <peer>` | File Sharing + Quick Look from anywhere — `ssh -L 1445→peer:445`, opens `smb://localhost:1445` (mounts in Finder; spacebar Quick Look works) |

`screen`/`finder` exist because **VNC and SMB aren't SSH** — ProxyJump (which
carries `ssh hertsi`/`sftp`/`rsync`) can't forward them, so a port-forward tunnel
through the Mini does. Peer accepted by registry key *or* friendly alias. Both use
the live IP from `peers.json`. Dependency: Mini up + peer awake on the LAN.
Verified 2026-06-15: `Hertsi:5900` and `:445` both OPEN from the Mini; tunnels
forward localhost→Mini→Hertsi over Tailscale.

Known peer registry in the script: `hertsimacpro` (user esaruoho, via cloudcity,
legacy-rsa, alias `hertsi`). Add more peers by extending `PEERS`.

## Proof (2026-06-15)

- `ssh hertsi` → `MacPro, 10.11.6` (through the Mini).
- `fleet-files index hertsimacpro '$HOME' --publish` → **58,221 files** cataloged.
- `fleet-files find ".pdf" --peer hertsimacpro` → 73 hits; `.jpg` → 29,573 — all
  answered from the **local published catalog, no live connection to Hertsi**.

## Waking a sleeping peer — the Mini as alarm clock

Wake-on-LAN is a link-local broadcast; it does **not** route over Tailscale. So
the Mini (on the peer's LAN) sends the magic packet on your behalf.

- **`bin/fleet-wake <peer|MAC> [--wait]`** — sends the WoL packet. Runs on the
  Mini; from elsewhere: `ssh cloudcity '~/work/apple/bin/fleet-wake hertsi --wait'`.
- The peer's **MAC** is captured + carried forward in `peers.json` by
  `fleet-files-refresh` (kept even while the peer is asleep — exactly when needed).
- **Auto-wake:** `fleet-files screen/finder <peer>` checks the map; if the peer is
  down it asks the Mini to WoL it first, waits, then opens the tunnel
  (`--no-wake` to skip). `fleet-files wake <peer>` does just the wake.

Requirements on the peer: `pmset womp 1` (Wake for network access) + asleep, not
powered off, on a wired link. Verified 2026-06-15: Hertsi already has `womp 1`
**and `sleep 0`** (never sleeps — display-only), so it's effectively always-on;
the wake path is insurance + the real win for laptops like olgas-mbp (capture its
MAC once while awake; note laptops on battery/lid-closed often ignore WoL).
"Keep it open" = `sudo pmset -a sleep 0 disksleep 0` on the peer (needs its sudo;
Hertsi is already there).

## Available vs queryable — two layers

- **Available** = byte access on demand: `ssh/sftp/rsync/sshfs hertsi` via the jump.
- **Queryable** = search without waking the peer: the published catalog
  (`~/work/comms/queue/fleet-index/<peer>.tsv`) syncs to every tailnet machine.

## Maintained fabric — convey / comms / cloudcity-boot

The bridge is kept alive by a Mini service, not by hand:

- **comms** carries the state: `comms/queue/fleet-index/peers.json` (live IP +
  up/down + OS per peer) and `<host>.tsv` catalogs — Syncthing-distributed to
  every machine.
- **`bin/fleet-files-refresh`** (one-shot, runs on the Mini): resolves each
  peer's current LAN IP **locally** (dscacheutil/arp/ping — no SSH, no mDNS
  round-trip) and publishes `peers.json`; `--index` also rebuilds catalogs
  (load-gated: skipped when 1-min loadavg > 4 so it never piles onto a busy Mini).
- **`bin/fleet-files-refresh-loop`** is the Cloudcity-Boot pane worker: cheap
  IP-map every 10 min, full catalog ~hourly. Crash-only while-true, NO nohup.
- **The Mini's `systems.yaml`** registers it as a service. `systems.yaml` is the
  gitignored private per-machine instance config (companion-mac-fabric), so this
  entry is added to the **Mini's own copy**, not committed. Paste:

  ```yaml
  - name: fleet-files-refresh
    does: maintain the LAN-only-peer Tailscale bridge — live IP-map (10m) + catalogs (~1h)
    kind: service
    worker: apple/bin/fleet-files-refresh-loop
    launch: pane "Fleet Files Refresh"   # crash-only while-true; IP-map cheap, catalog load-gated
  ```

  Deploy = Mini pulls apple, add the entry to the Mini's `systems.yaml`, then
  `!pk cloudcity restart` **when the Mini is free** (a restart relaunches panes —
  don't do it mid-render or you kill in-flight convey jobs).
- **`fleet-files setup`** consumes `peers.json` and pins each ssh-config
  `HostName` to the live IP (falls back to bare hostname if the map is absent or
  the peer is down).

**Why the IP-pin matters (2026-06-15):** while the Mini ran a 2-hour convey
splice, its `mDNSResponder` pegged at 99% and `ProxyJump hertsimacpro` failed with
"nodename nor servname… not known". Pinning the jump to the map's IP fixed it
instantly — `ssh hertsi` reached Hertsi at Mini load **6.57**. The cheap IP-map is
the thing that keeps the bridge alive exactly when the Mini is busiest.

The index step needs the **Mini's own key** on each peer (one-time
`ssh-copy-id esaruoho@<peer>` from the Mini); the IP-map needs neither SSH nor
mDNS, so it always works.
