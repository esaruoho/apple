---
description: Federate a legacy macOS app (e.g. Quartz Composer) from the fleet node that has it to a node that needs it, and launch it remotely — the OS-compat gate, the pipeline, and the Quartz Composer proof case.
---

# Fleet app deployment — legacy apps as a routable fleet asset

## What the fleet actually gains

The handshake (`bin/fleet --handshake`) gives **observability** (who's up, their shape)
and the Mini gives a few **routable services** (ocr/voicebox/whisp/pakettibot via
Syncthing inboxes). The next gain is **capability sharing across OS generations**:
the union of *what each machine can run*. An old Mac that still runs software the
new Macs can't becomes a *service* the whole fleet draws on.

Concrete case: **Quartz Composer**. Apple removed it from "Additional Tools for
Xcode" around macOS 11, and it is not downloadable without an Apple-ID developer
session. But a fleet node still holds a working copy → the fleet can deploy +
launch it elsewhere.

## The asset (as of 2026-06-15)

- **esarMBP** (macOS 10.14.6 Mojave, Intel i7-4980HQ) holds
  `/Applications/Xcode Additional Tools/Graphics/Quartz Composer.app`
  — **QC 4.6.2 (build 154)**, 35 MB, arch `x86_64 + i386`.
- HertsiMacPro (10.11.6) does **not** have the app (only OS framework stubs).

## The hard OS-compat gate

`Quartz Composer.app` links:

```
/System/Library/Frameworks/Quartz.framework/Versions/A/Frameworks/QuartzComposer.framework
```

Apple **removed** that sub-framework in **macOS 11 Big Sur**. Therefore a *copied*
QC.app launches only on a target whose OS still ships it:

| Target macOS | Copied QC.app runs? |
|---|---|
| 10.6 – 10.15 (Intel) | ✅ yes — OS ships the framework |
| 11+ Intel | ❌ no — framework gone from the OS |
| 11+ Apple Silicon | ❌ no — needs Rosetta **and** the missing framework |

**Decision rule:** if the target is ≤ 10.15 Intel → deploy-the-app. Otherwise →
don't copy; run QC *on the node that has it* (esarMBP) and treat that node as the
fleet's QC service.

## The deploy pipeline (peer → peer)

1. **Confirm target reachable + its OS** — handshake card or `ssh <target> sw_vers`.
   (Requires the target powered on with Remote Login enabled.)
2. **Gate on OS** per the table above.
3. **Copy** the `.app` source→target. Either peer-to-peer rsync, or relay via the
   coordinating Mac (RayMac), or the Syncthing queue for hands-off transfer.
4. **Launch remotely** — the hard part. A bare `ssh <target> 'open <app>'` fails
   with **LSOpenURLsWithRole() error -10825** *even when the same user is logged
   into the desktop* (Dock + WindowServer running). An SSH session lives in the
   **system Mach bootstrap**; LaunchServices lives in the user's **Aqua/GUI
   bootstrap**. Same uid, different namespace — `open` can't reach the LS server.

   Routes tested on HertsiMacPro (10.11.6, esaruoho logged in at console, uid 504):
   - bare `open "<app>"` → -10825 ❌
   - `osascript -e 'tell application "X" to activate'` → -1728 (Apple Events also
     can't cross from the system bootstrap) ❌
   - `launchctl asuser 504 open <app>` → "Could not switch to audit session:
     Operation not permitted" — **asuser needs root** ❌
   - `sudo -n launchctl asuser 504 open <app>` → no passwordless sudo ❌

   **Working launch routes (pick one):**
   - **(a) Scoped passwordless sudo** — one sudoers line per peer allowing
     `launchctl asuser <uid> open *`, then `fleet-app launch` works over plain SSH.
     Minimal, low blast-radius.
   - **(b) In-session agent** — a per-user **LaunchAgent** watcher (loaded at login,
     so it runs *inside* the Aqua bootstrap and CAN `open` GUI apps) reading a
     launch-inbox. This is the fleet's trigger→worker chassis applied to GUI
     launch; survives reboots; ground-rule compliant (a login-scoped agent, not a
     nohup daemon or SSH-launched `&`). Heavier to stand up.
   - **(c) Manual** — `fleet-app` deploys + registers; the user double-clicks on
     the target's own desktop. Deploy is the unobtainable-asset win; launch is local.

   `fleet-app launch` judges success by whether the **process actually comes up**
   (pgrep), not launchctl's noisy rc.

## olgas-mbp status (2026-06-15)

- Logged in as `esaruoho` (Esa's account — legit fleet member).
- Currently **powered off** (MAC absent from ARP). Targeted by the handshake
  (`esaruoho@olgas-mbp`, router DNS → 192.168.32.103) — auto-joins when awake.
- **Blocked on:** power on + Remote Login. Then read its OS → apply the gate.

## Naming / reachability note

The handshake reaches LAN peers by **bare hostname** (router DNS resolves
`olgas-mbp`/`esarmbp`/`hertsimacpro`), not `.local` mDNS (dead on this wired
subnet). Legacy sshd (OpenSSH 6.9 on 10.11) needs
`-o PubkeyAcceptedAlgorithms=+ssh-rsa` to verify a modern RSA key — the handshake
already passes this.
