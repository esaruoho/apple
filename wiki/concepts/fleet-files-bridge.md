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

To keep the catalog fresh, re-run `index … --publish` (one-shot, on demand). A
periodic refresh belongs in the Mini's **Cloudcity-Boot `systems.yaml`** (NOT a
nohup/daemon — see the repo ground rule), reading Hertsi over the LAN it already
shares.
