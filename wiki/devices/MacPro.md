# MacPro

> Workstation tower. PCIe expansion. M-series Ultra. For automation purposes, behaves like a MacStudio with slots.

## Role

The top of the Mac line. The reason it exists in this skill at all: PCIe-attached audio interfaces, MDM-controlled creative-studio Macs, and edge cases where someone needs to script a specific PCIe device's vendor driver.

For Esa's setup, MacPro is not in active use — included here for completeness so the device atlas is honest.

## Automation surface

Identical to MacBookPro / MacStudio. Apple-silicon MacPro shares the same Cocoa/AppleScript/Shortcuts stack.

PCIe-specific automation is per-card: audio interfaces expose CoreAudio devices, GPUs (on Intel MacPro only) expose Metal devices. None of this is MacPro-specific in software terms — it's just where the cards live.

## Cross-device fabric

Same as MacStudio — full Continuity cluster member.

## Trigger surface

Same as MacStudio / MacBookPro.

## Painpoints specific to MacPro

- **PCIe driver compatibility** — third-party kexts have been progressively locked out; modern audio interfaces are USB-C / Thunderbolt, not PCIe
- **Apple-silicon MacPro removed eGPU support** — Metal compute is on-die only
- **Physical size** affects nothing about automation but everything about whether it lives in the same room as the keyboard

## Cross-refs

- For typical pro desktop work, [MacStudio.md](MacStudio.md) is the more relevant page
