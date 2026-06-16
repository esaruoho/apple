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

**Goal:** eventually have these talk to the Mac Fleet too. The natural path is the **same pattern we use for HertsiMacPro**: the Mini, being on the workspace LAN, *probes* a node it can reach and publishes a Machine Card on its behalf (a node too limited to self-report is shown, not a worker — see the `machine-card-probe` design). For the legacy boxes the transport differs from SSH:
- **XP**: reachable over **SMB / RDP** (and possibly a tiny polled agent or SNMP); the Mini could probe basic shape (OS, name, up/down) and surface a card. Screen access via RDP through the same `ssh -L` relay trick (forward 3389 instead of 5900).
- **DOS PC**: no IP stack of its own in the usual sense — it sits behind/beside the XP box on the LAN. Most likely surfaced *through* the XP node (XP as its bridge) rather than directly.

None of this is built yet — it's the hoped-for extension. When it happens it should reuse `machine-card-probe.sh` (static-IP, mDNS-independent) and the `fleet-files` relay, not a new mechanism.

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
