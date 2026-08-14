---
description: Contour ShuttlePro v1 (0x0b33:0x0010) — a 13-button jog/shuttle USB HID controller with no macOS driver, and the report layout needed to write one.
---

# Contour ShuttlePro v1

## ⚠️ Esa's unit is dead (diagnosed 2026-08-14)

**Do not re-run this diagnosis.** The unit does not enumerate at USB level on
**three hosts, two operating systems, four USB controllers**:

| Host | Path | Result |
|---|---|---|
| MacBook Pro (Apple Silicon) | VIA Labs hub, arbitrary port | absent from `ioreg -rc IOUSBHostDevice` |
| MacBook Pro | VIA hub, **the exact socket a Logitech mouse enumerated in seconds earlier** | absent |
| XP32Bit PC | native USB-A — an OS with in-box support for this device | absent |
| CloudcityMacMini | native USB-A, no hub | `CONTOUR_2867=0`, `PIENG_1523=0` |

This is **not** a driver, TCC, or HID-layer problem. An unrecognised or
driverless device still enumerates — that is what the Norelsys and ASIX entries
in the same tree are. Absence at the USB layer means no handshake at all.

Most likely cause: **the captive cable**, which on v1 fails at the strain relief
where it enters the housing. Second candidate: the internal cable-to-PCB
connector backing out (a known v1 failure; the case is screwed, not glued, so
re-seating is feasible). The report layout below is therefore **still
unconfirmed against real hardware** — confirm with `hidprobe watch` if a working
unit ever appears.

**Method note for the next session:** this Mac does **not** log USB attach/detach
at default log level — a confirmed replug of a working mouse produced zero
kernel log lines. `log show`/`log stream` are useless as USB presence evidence
here. `ioreg -rc IOUSBHostDevice` is the reliable detector. Parse it as XML
(`ioreg -a`) — a line-based `awk` over the flat output mispairs `idVendor` with
`idProduct` when IOKit emits those keys in a different order.

---


A jog/shuttle USB controller from Contour A/V Solutions (~2002), sold for video
editing. Esa owns one. **Contour ships no working macOS driver for it** — the
current download, `ContourDesign Mac Driver v6.0.5.dmg`, is
`com.contourdesign.mouse.app` (the RollerMouse/Qt app) and contains **zero**
Shuttle references. v1 is long EOL.

That is fine, because the device needs no driver in the kernel sense: it is a
**well-formed USB HID device** and everything about it can be read from
user space with `IOHIDManager`. See [`usb-hid-probing.md`](../concepts/usb-hid-probing.md)
for the probe tool, and [`hardware-controllers.md`](../concepts/hardware-controllers.md)
for how controller input reaches scripts here generally.

## Identity

| Device | VID | PID | Buttons |
|---|---|---|---|
| **ShuttlePro v1** | `0x0b33` | `0x0010` | **13** |
| ShuttlePro v1 (variant seen in the wild) | `0x0b33` | `0x0011` | 13 |
| ShuttlePro v1 (PI Engineering rebadge) | `0x05f3` | `0x0240` | 13 |
| ShuttleXpress | `0x0b33` | `0x0020` | 5 |
| ShuttlePro v2 | `0x0b33` | `0x0030` | 15 |

Only `0020` and `0030` are in `usb.ids`; **v1 is absent from the public database**,
which is why `lsusb`-style lookups come back unnamed. Match on **VID `0x0b33`
alone** and branch on PID, plus a separate matcher for `0x05f3:0x0240`.

USB product string is `Contour Design ShuttlePRO` — no "v1" in it.

## Input report — 5 bytes, no report ID

Reports are **unnumbered** (no report-ID prefix), so byte 0 is really the
shuttle. The device sends a **full state snapshot on every change**; there are
no delta events, so a driver diffs against its own previous report.

| Byte | Field | Type | Meaning |
|---|---|---|---|
| 0 | Shuttle ring | **int8** | −7 … 0 … +7. Absolute, spring-returns to 0. 15 positions. |
| 1 | Jog wheel | **uint8** | Free-running counter that **wraps** 255→0 and 0→255. 10 detents/rev. |
| 2 | — | — | Unused, always 0. |
| 3–4 | Buttons | **uint16 LE** | Bitmask; bit *n* set = button *n+1* held. |

Accept **5 or 6** byte reports — EMATech's implementation sees 6 with byte 5
unused. Parse offsets 0–4 either way.

**Hardware quirk:** the jog wheel *swallows the first tick when reversing
direction*. Compensate in the delta logic, or a reversal appears to do nothing.

**The shuttle has no detent events.** "Shuttle held at −3 keeps scrubbing left"
is a driver-side synthesis (a repeating timer), not something the device sends.

## Button bit map (13 buttons)

Bitmask in the LE u16 at bytes 3–4:

| Bit | Mask | Byte.bit | # | Position |
|---|---|---|---|---|
| 0 | `0x0001` | b3.0 | K1 | top row, leftmost |
| 1 | `0x0002` | b3.1 | K2 | top row |
| 2 | `0x0004` | b3.2 | K3 | top row |
| 3 | `0x0008` | b3.3 | K4 | top row, rightmost |
| 4 | `0x0010` | b3.4 | K5 | 2nd row, leftmost |
| 5 | `0x0020` | b3.5 | K6 | 2nd row |
| 6 | `0x0040` | b3.6 | K7 | 2nd row, centre (above jog) |
| 7 | `0x0080` | b3.7 | K8 | 2nd row |
| 8 | `0x0100` | b4.0 | K9 | 2nd row, rightmost |
| 9 | `0x0200` | b4.1 | K10 | below jog, upper-left |
| 10 | `0x0400` | b4.2 | K11 | below jog, upper-right |
| 11 | `0x0800` | b4.3 | K12 | above palm rest, lower-left |
| 12 | `0x1000` | b4.4 | K13 | above palm rest, lower-right |
| 13–14 | `0x2000` / `0x4000` | b4.5/6 | K14/K15 | **v2 only** — always 0 on v1 |

```
      K1  K2  K3  K4
    K5  K6  K7  K8  K9
             Jog
      K10        K11
     K12          K13
```

**This table is from the literature, not yet from Esa's unit.** Confirm it with
`hidprobe watch` before building anything on top of it — v1 has the thinnest
open-source coverage of the three models.

## macOS specifics

- **Input Monitoring (TCC) is the gate.** `IOHIDManagerOpen` fails with
  `kIOReturnNotPermitted` without it, and the gate is **not** limited to
  keyboards — it covers all `IOHIDManager` access. Check with
  `hidprobe access`. The grant is **per-binary**, so running under iTerm grants
  *iTerm*; a shipped `.app` needs its own grant (same shape as the
  Screen-Recording problem in
  [`feedback_screencapture_without_tcc_returns_wallpaper`](../../../.claude/projects/-Users-esaruoho-work-apple/memory/feedback_screencapture_without_tcc_returns_wallpaper.md)).
- **Synthesizing keystrokes is a second, separate grant: Accessibility.**
  Reading = Input Monitoring; `CGEventPost` = Accessibility. Two prompts.
- **Open shared (`kIOHIDOptionsTypeNone`), not seized.** The descriptor exposes
  buttons and generic axes — no keyboard or consumer usages — so macOS does
  **not** turn Shuttle input into keystrokes on its own. Nothing to defend
  against, and seizing only creates conflicts.
- **Old Contour kext.** If a Contour driver was ever installed, look for
  `com.contourdesign.shuttle.kext` (or a newer `.dext`) claiming the device
  before blaming your own code. It uninstalls badly; leftovers live in
  `/Library` and `~/Library/Application Support`.
- **Settle time.** Allow ~1 s after USB attach before the HID node is openable.

## Prior art worth reading

| Repo | Stack | Value |
|---|---|---|
| [hopejr/ShuttleControlUSB](https://github.com/hopejr/ShuttleControlUSB) | Node + node-hid, cross-platform | **Best reference.** `ShuttlePIDs.js` / `ShuttleDefs.js` carry explicit per-device button masks *including v1*. |
| [c0deous/Contour-ShuttlePRO-V1-…](https://github.com/c0deous/Contour-ShuttlePRO-V1-Linux-Custom-Implementation) | Python evdev | The only **v1-specific** repo; enumerates exactly 13 buttons. |
| [EMATech/OpenContourShuttle](https://github.com/EMATech/OpenContourShuttle) | Python hidapi + Qt | Documents the 6-byte report and the direction-reversal tick quirk. |
| [agraef/ShuttlePRO](https://github.com/agraef/ShuttlePRO) | C, Linux evdev | Best source for the K1–K15 layout and the `.shuttlerc` config-language design. |
| [psacchitella/ShuttleProV2_macOS](https://github.com/psacchitella/ShuttleProV2_macOS) | Python hidapi + Quartz | macOS reference for the read → CGEvent path. |
| [LinuxCNC `shuttle(1)`](https://linuxcnc.org/docs/html/man/man1/shuttle.1.html) | C, hidraw | Canonical device table and axis semantics. |
