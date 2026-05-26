# MacStudio

> Pro desktop, headless-friendly, M-series Max/Ultra. Same software stack as the laptops, more thermal headroom, more I/O.

## Role

The "no-laptop-form-factor-tax" desktop. Sits between MacMini (small, server-oriented) and MacPro (workstation, PCIe). For automation purposes, behaves like an always-on MacBookPro.

## Automation surface

Identical to MacBookPro. Every AppleScript, Shortcut, App Intent, Cocoa class, Carbon hotkey works the same. The skill makes no automation-level distinction between Studio and Pro laptop.

## Cross-device fabric

Full Continuity cluster member when paired with iPhone/iPad/Watch. Receives AirDrop, Handoff, AirPlay. Can be a Sidecar **client** (using iPad as display) but the all-in-one geometry of iMac and the portable nature of MBP are more typical Sidecar setups.

## Trigger surface

Same as MacBookPro — but because Studio is typically desk-mounted and always-on, it's a viable alternative to MacMini for LaunchAgent-driven recurring work.

## Painpoints specific to Studio

- **No internal display** — multi-monitor automation must assume external displays only; lid-state checks (relevant on portables) are moot here
- **M-Max/Ultra heat dump** — sustained workloads dump real heat; ambient noise from fans becomes audible during long renders, which matters if the Studio is in a recording space

## Cross-refs

- For server-style always-on duties, prefer: [MacMini.md](MacMini.md)
- For full automation surface description: [MacBookPro.md](MacBookPro.md)
