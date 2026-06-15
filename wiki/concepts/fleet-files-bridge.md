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

Known peer registry in the script: `hertsimacpro` (user esaruoho, via cloudcity,
legacy-rsa, alias `hertsi`). Add more peers by extending `PEERS`.

## Proof (2026-06-15)

- `ssh hertsi` → `MacPro, 10.11.6` (through the Mini).
- `fleet-files index hertsimacpro '$HOME' --publish` → **58,221 files** cataloged.
- `fleet-files find ".pdf" --peer hertsimacpro` → 73 hits; `.jpg` → 29,573 — all
  answered from the **local published catalog, no live connection to Hertsi**.

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
- **`convey/systems.yaml`** registers it as service `fleet-files-refresh`
  (pane "Fleet Files Refresh"). Deploy = Mini pulls apple+convey, then
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
