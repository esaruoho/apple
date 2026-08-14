---
description: Reverse-engineering any USB HID device on macOS with IOHIDManager and bin/hidprobe — enumerate, dump the report descriptor, watch live reports byte-by-byte.
---

# USB + HID probing (`bin/usbprobe`, `bin/hidprobe`)

**Two layers, two tools, and the order matters.**
[`bin/usbprobe`](../../bin/usbprobe) answers *is the device on the bus at all?*
(`list` · `tree` · `watch` · `find` · `doctor`). Only when the answer is yes does
[`bin/hidprobe`](../../bin/hidprobe) — the rest of this page — become relevant.

Ask the USB question first, because **absence at the USB layer is never a driver
problem.** macOS enumerates hardware it has never heard of; a device missing from
`usbprobe list` has completed no USB handshake at all, and that is a cable, port,
or device fault that no code can fix. Confusing the two layers means writing a
driver for something the Mac is not electrically talking to.

```bash
usbprobe doctor          # what's present + an ordered checklist if yours isn't
usbprobe find 0x0b33     # present/absent for one vendor, by id or name
usbprobe watch           # poll for attach/detach (see the log warning below)
```

`usbprobe` is Python stdlib over `ioreg -a` XML. Three things it gets right that
a naive version does not: it **parses the XML** rather than grepping flat `ioreg`
output (which mispairs `idVendor` with `idProduct` when IOKit emits the keys in a
different order); it **dedups interface nodes**, which inherit their parent's
ids and otherwise count one device several times; and it treats a failed `ioreg`
as an error rather than an empty list, so "nothing found" can never be confused
with "the command broke".

> **`log stream` / `log show` are NOT USB presence evidence.** At default log
> level this Mac logs *nothing* on USB attach — a confirmed replug of a working
> mouse produced zero kernel lines across a 10-minute window. Poll `ioreg`
> (`usbprobe watch`) instead. This cost two rounds of a real diagnosis.

## HID probing (`bin/hidprobe`)

macOS can talk to **any** HID device with no driver, no kext, and no Homebrew —
`IOHIDManager` is public API and the HID parser is in the OS. When a device has
no macOS driver (Contour ShuttlePro, an old game controller, a foot pedal), the
work is not "write a kernel driver", it is "read the reports and decide what
they mean". [`bin/hidprobe`](../../bin/hidprobe) is the tool for that.

Self-building Swift, same pattern as `apple-ner`: the bash wrapper compiles
`bin/hidprobe.swift` into `~/.cache/apple/` on first use or after any edit.

## The four subcommands

```bash
hidprobe list [--json]            # every HID device: VID, PID, name, usage, report size
hidprobe elements   <sel>         # the report descriptor, PARSED by the OS
hidprobe descriptor <sel>         # the report descriptor, raw bytes
hidprobe watch <sel> [--seize] [--raw|--parsed|--both]
hidprobe access [--request]       # Input Monitoring (TCC) status
```

`<sel>` is `--vid 0x0b33 --pid 0x0010`, or `--name Shuttle` (substring, case
insensitive), or `--index N` from the `list` output.

## The order to use them in

1. **`access`** first. Everything else silently fails without it — see below.
2. **`list`** to find the device and get its VID/PID.
3. **`elements`** *before* touching a single control. macOS has already parsed
   the device's report descriptor for you: this prints every field with its
   usage page, usage, bit size, bit count and logical range. On a well-formed
   device this is most of the protocol, for free, with no guessing.
4. **`watch`** to confirm the mapping against physical reality — which bit is
   which button, which byte is the wheel, what the resting value is.

Step 3 is the one people skip. Do not skip it: guessing byte offsets from a hex
dump when the OS will hand you a labelled field table is wasted effort.

## `watch` — reading the bytes

For each input report it prints the hex with **changed bytes highlighted**,
plus unsigned and signed views of every byte, plus — for each byte that
changed — a before/after bit pattern and the delta:

```
[   4.182] #17 id=0 len=5
   hex  00 a4 00 08 00
   u8     0 164   0   8   0
   i8     0 -92   0   8   0
   byte[3] 00000000 -> 00001000   (0 -> 8, delta 8)
```

That bit-diff line is what turns a button press into a bit number in one press.
`--parsed` instead prints named `UsagePage/Usage = value` events decoded through
the descriptor; `--both` shows both, which is the fastest way to correlate "bit
11 of my raw dump" with "the OS calls that Button12".

**`watch` waits for the device.** It registers a hotplug matching callback, so
you can start it *before* plugging in and catch the very first report. It also
reports detach. This matters: some devices only reveal their init behaviour at
attach time, and some need ~1 s of settle before the HID node opens.

Output is line-buffered, so `hidprobe watch … | tee capture.log` works live.

## Input Monitoring is the gate, and it is per-binary

`IOHIDManagerOpen` returns `kIOReturnNotPermitted` without an **Input
Monitoring** grant. The trap: this gate is **not limited to keyboards**. Every
`IOHIDManager` open goes through it, including a vendor-usage device that could
not possibly type anything.

```bash
hidprobe access             # GRANTED / DENIED / UNKNOWN (never asked)
hidprobe access --request   # prompt for it
```

The grant follows the **binary that runs**, not the script. Running `hidprobe`
in iTerm grants *iTerm*. An `.app` you ship needs its own grant — the same shape
of problem as the Screen Recording one, where the shell test passes because
iTerm holds the grant and the app then silently gets nothing.

**Reading input and synthesizing input are two different permissions.** Reading
HID = Input Monitoring. Posting `CGEvent`s to drive other apps = **Accessibility**.
A controller-to-keystroke driver needs both, and will prompt twice.

Known bug (openradar 7381305): calling `AXIsProcessTrustedWithOptions(NULL)`
first can break `IOHIDRequestAccess()`. Ask for Input Monitoring before
Accessibility.

## Shared vs seized

Open shared (`kIOHIDOptionsTypeNone`) by default — that is what `watch` does.
`--seize` (`kIOHIDOptionsTypeSeizeDevice`) takes the device away from the whole
system and is only worth it when the device's usages make macOS *itself*
interpret the input, e.g. a device that declares keyboard usages would otherwise
type into whatever is frontmost while you probe it. A device made of Button and
Generic Desktop axis usages needs no seizing; macOS does nothing with it.

If open fails with `0xe00002c1` the device is already claimed exclusively —
find and quit the vendor driver.

## When the descriptor is empty

`descriptor` printing nothing means the device exposes no
`kIOHIDReportDescriptorKey` through IOKit. `elements` still works, because the
OS parsed the descriptor at match time even if it does not republish the bytes.
Only if *both* come back empty is a device genuinely opaque — and then the
question is whether it is HID at all, which `ioreg -rc IOUSBHostDevice` answers.
(Note `system_profiler SPUSBDataType` can return an entirely empty tree on
Apple Silicon — see [`iphone-usb-capture-probe.md`](iphone-usb-capture-probe.md).)

## Related

- [`contour-shuttlepro.md`](../entities/contour-shuttlepro.md) — the first device
  probed with this tool; report layout and button bit map.
- [`hardware-controllers.md`](hardware-controllers.md) — how controller input
  reaches AppleScripts and shell commands here.
- [`iphone-usb-capture-probe.md`](iphone-usb-capture-probe.md) — the other USB
  reverse-engineering page; why enumeration alone never proves absence.
