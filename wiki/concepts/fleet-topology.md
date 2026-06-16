---
description: Physical + network topology of the Mac Fleet — where each machine lives, which roams, how LAN-only/legacy nodes join via the Mini bridge, and the future XP/DOS goal.
---

# Fleet Topology

Where the fleet physically is, how the machines reach each other, and what's planned to join. The mechanics of cards/probing/bridging live in [[machine-card-protocol]], [[fleet-files-bridge]], and [[fleet-machine-card-app]]; this page is the *map*.

## The workspace site

**Sahaajankatu 20–22 E, Yrityskeskus Linna, Herttoniemi (Helsinki).** ~15 minutes away by car. Three Macs live here, on one LAN:

| Machine | Role | Reach |
|---|---|---|
| **CloudcityMacMini** (`cloudcity`) | always-on server / bridge / worker host (Cloudcity-Boot, Syncthing, OCR/voicebox/whisp/pakettibot/FM) | Tailscale (`cloudcity` / `cloudcitymacmini`) + LAN `192.168.32.101` |
| **HertsiMacPro** (`hertsi`) | 2008 Mac Pro, macOS 10.11 — display-only fleet node, too old to self-report | LAN-only `192.168.32.169`; reached via the Mini as SSH `ProxyJump` |
| **esarMBP** | MacBook (macOS 10.14) at the site | LAN; bridge peer via the Mini |

The Mini is the anchor: it's on **both** the workspace LAN *and* the tailnet, so it's how everything off-site is reached.

## The roaming node

**RayMac** — this laptop. Esa's primary machine; it lives *off-site* and only **occasionally travels to the workspace** to be on the LAN directly. Most of the time it talks to the site machines remotely:
- to the Mini: directly over **Tailscale**.
- to the LAN-only Macs (Hertsi, esarMBP): through the Mini as an **SSH `ProxyJump` / `ssh -L` relay** (see [[fleet-files-bridge]]). This is why `ssh HertsiMacPro` and `fleet-files screen hertsi` work from anywhere — the Mini does the LAN hop.

So "RayMac is at the workspace" is the exception, not the rule. Anything that must work while RayMac is remote routes through the Mini.

## Legacy / non-Mac nodes (future work)

Also on the workspace LAN, **not yet on the fleet**:
- **XP32Bit** — a Windows XP 32-bit desktop.
- **DOS PC** — a DOS machine, **LAN-connected to the XP box**.

**Goal:** eventually have these talk to the Mac Fleet too. **Feasibility: yes** — plugged into the same hub, XP gets a LAN IP (`192.168.32.x`) and the Mini (already LAN + Tailscale) bridges it to the world exactly as it does HertsiMacPro: **RayMac → Tailscale → Mini → XP**. XP never faces the public internet — it's reachable only through the tailnet + Mini relay. **Never port-forward XP to the internet; always relay through the Mini** (a 20-year-old OS must stay behind the bridge).

The concrete plan (reuse the Hertsi mechanism; only the transport changes):

- **XP — talk / compile / run commands:** install a small **SSH server on XP** (freeSSHd, Bitvise, or Cygwin sshd). Then it's a real fleet node: `ssh XP32Bit` via `ProxyJump cloudcity`, run a compiler remotely (TASM/TLINK etc.), `fleet-files` it. This is the cleanest path and it sidesteps the SMB headache.
- **XP — files / folders:** **SFTP over that same SSH** (preferred), or XP's native **SMB**. Caveat: XP speaks only **SMB1**, which modern macOS clients resist — that's exactly why SSH/SFTP is the better path.
- **XP — screen (VIEW):** **VNC server on XP** (UltraVNC/TightVNC) → forward 5900 through the Mini, identical to Hertsi's `fleet-files screen`. RDP (3389) works only if it's XP **Pro**; XP **Home** has no RDP server → use VNC.
- **DOS PC — indirect, through a share:** no SSH/VNC server exists for DOS. It maps a **network share** (hosted on XP or a NAS) as a drive letter. Reach it by writing into that share via the XP/SSH path → the DOS box sees the files on its mapped drive. A "compile-on-XP, drop the artifact into the DOS share" loop is the realistic shape.

**Security posture — XP stays OFFLINE while on the LAN (decided default).** The Mini reaches XP over the *local subnet only*, so XP needs no internet at all. Same-subnet traffic uses no gateway; the default gateway is consulted only for destinations outside the LAN. Therefore:
- Give XP a **static LAN IP with the default gateway left BLANK** (e.g. `192.168.32.50/24`, gateway empty, DNS empty, IP outside the DHCP pool). XP can then talk to the Mini (`.101`) and the DOS share, but has **no route to the internet** — offline, yet fully LAN-reachable, so `RayMac → Tailscale → Mini → XP` still works end-to-end.
- **DOS ↔ XP is untouched** by this (purely local, same subnet, never used a gateway).
- Behind the router's **NAT**, XP was never inbound-reachable from the internet anyway; the danger is only outbound/UPnP. Belt-and-suspenders: **block XP's MAC from WAN** at the router and **disable UPnP**.
- Residual risk is *lateral* (a compromised LAN peer), not internet: keep XP's **Windows Firewall on, scoped to allow only the Mini's IP** to its SSH/SMB/VNC ports.
- Principle: **the Mini is XP's only uplink** — XP speaks to the LAN, the Mini speaks to the world, you ride through the Mini. Never port-forward XP; never give it a gateway.

**Open questions to settle by a read-only probe** (do this FIRST, before installing anything — once XP is on the hub, from the Mini: ping, find its IP, port-scan 22/445/3389/5900): is it XP **Pro or Home** (decides RDP), and is SMB1 on? Probe `machine-card-probe.sh`-style (static IP, mDNS-independent) and surface a card; the Mini *probes and publishes on its behalf*, a shown node not a worker.

None of this is built yet — hoped-for extension. Reuse `machine-card-probe.sh` + the `fleet-files` relay, not a new mechanism.

## One-glance summary

```
                 off-site                          Sahaajankatu 20-22E (workspace LAN)
              ┌───────────┐     Tailscale      ┌──────────────────────────────────────┐
              │  RayMac    │ ─────────────────▶ │  CloudcityMacMini  (.101, anchor)     │
              │ (roaming,  │                    │   ├─ ProxyJump/ssh-L ─▶ HertsiMacPro  │
              │  visits    │ ── occasional ───▶ │   │                     (.169, 10.11) │
              │  rarely)   │    in-person LAN   │   ├─ ─────────────────▶ esarMBP        │
              └───────────┘                    │   └─ (future) ────────▶ XP32Bit ─ DOS  │
                                               └──────────────────────────────────────┘
```

See also: [[machine-card-protocol]] · [[fleet-files-bridge]] · [[fleet-machine-card-app]] · [[rename-mac-via-ssh]] · device pages under `wiki/devices/`.
