---
description: Rename a Mac headlessly over SSH — the three scutil names (HostName / LocalHostName / ComputerName), why you must set all three, and the Bonjour flush that applies it.
---

# Rename a Mac via SSH

A Mac has **three** independent names. Renaming "the computer" means setting all three with `scutil --set` and flushing Bonjour — no GUI, works over SSH, works back to at least macOS 10.11.

## The one-liner

Run from any Mac that can reach the target (here via the `HertsiMacPro` SSH alias, which tunnels through the Mini). `-t` gives `sudo` a TTY to prompt for the password:

```bash
ssh -t HertsiMacPro 'sudo scutil --set HostName HertsiMacPro && \
  sudo scutil --set LocalHostName HertsiMacPro && \
  sudo scutil --set ComputerName HertsiMacPro && \
  sudo dscacheutil -flushcache && \
  sudo killall -HUP mDNSResponder && \
  scutil --get ComputerName'
```

Confirm with the trailing `scutil --get ComputerName` (and on a *fresh* login, the shell prompt).

## The three names — set ALL of them

| Name | Set with | Drives | If you skip it |
|---|---|---|---|
| **HostName** | `scutil --set HostName X` | the kernel/UNIX hostname → `hostname`, `socket.gethostname()`, the `user@host` shell prompt | **Unset is the dangerous case:** macOS derives the hostname from DHCP/Bonjour, where it can collide, gain a ` (2)` suffix, or garble. Pin it. |
| **LocalHostName** | `scutil --set LocalHostName X` | the Bonjour/mDNS name → `X.local` | `.local` resolution keeps the old name |
| **ComputerName** | `scutil --set ComputerName X` | the friendly name → Finder Sharing, AirDrop, and anything displaying the human name (e.g. Fleet) | the human-facing name stays old even though the hostname changed |

Setting only `ComputerName` (the obvious one) leaves `gethostname()` and `.local` stale — the classic half-rename.

## Apply it: flush + HUP mDNSResponder

```bash
sudo dscacheutil -flushcache      # drop the DNS cache
sudo killall -HUP mDNSResponder   # re-register Bonjour with the new LocalHostName
```

`killall -HUP mDNSResponder` is also the fix when mDNSResponder is **storming at 100%** from a name conflict (an unset `HostName` colliding on the network). That storm can destabilise the whole network stack — see [[mac-mini]] / the fleet lessons below.

## Gotchas

- **The shell prompt is stale** until you start a *new* login shell — `%m`/`\h` was captured at session start. `scutil --get ComputerName` (or a fresh `ssh`) shows the truth.
- **`-t` is required for `sudo` over SSH** — without a TTY, `sudo` can't prompt and fails with "no tty present".
- **No passwordless sudo?** You must run it interactively (`ssh -t … '…'`) or on the machine; you can't pipe the password.
- **Reaching a LAN-only / old Mac:** if the target can't run Tailscale (e.g. a 2008 Mac Pro on 10.11), SSH to it via the Mini as a `ProxyJump` host — the alias's `HostName` should be the **static LAN IP**, not `*.local` (mDNS is fragile). See [[fleet-files-bridge]].
- **Pin after every macOS major upgrade** — an upgrade can reset `HostName` to unset, which restarts the whole DHCP/Bonjour-derivation mess.

## Why this is in the toolbox

Renaming headlessly keeps a machine's identity stable, which is what the fleet relies on: the Machine Card's `id` and display name come from these values. A garbled or suffixed name splits one Mac into two cards in Fleet. Full incident + the `machine-card` canonicalisation that hardens against it: [[machine-card-protocol]], and the project lesson `feedback_machine_card_canonical_name` / `feedback_mini_mdns_storm_breaks_lan_from_panes`.
