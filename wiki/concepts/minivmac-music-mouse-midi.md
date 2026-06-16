---
description: Getting MIDI in/out of Music Mouse running in Mini vMac — why stock Mini vMac can't, the midivmac fork, and the native Eventide MacMM alternative.
---

# MIDI into/out of Music Mouse on Mini vMac

Context: the 1989 classic Music Mouse (`APPL`/`LAS0`) runs in Mini vMac (Mac II,
System 7.5.5) via the `musicmouse` command — see `~/Downloads/MusicMouse-MiniVMac/HOW-TO-RUN.md`.
Question: can we send MIDI to it?

## The blocker: stock Mini vMac has no MIDI

Mini vMac **emulates the Mac's two serial ports (modem + printer) but attaches
nothing to them.** Classic-Mac MIDI flowed over those serial ports (a MIDI
interface clocked the SCC at 31250 baud). With nothing attached, the build we
set up (and every stock Mini vMac / Basilisk II) has **no MIDI in or out** — the
bytes go nowhere. ([gryphel FAQ](https://www.gryphel.com/c/minivmac/faq.html))

## The fix: `midivmac` (jariseon's fork)

A community fork bridges the emulated serial ports to host **CoreMIDI virtual
ports**, named **"Mini vMac Modem"** and **"Mini vMac Printer"**. Parses
note + SysEx, both directions. ([E-Maculation thread](https://www.emaculation.com/forum/viewtopic.php?t=10420))

- Source: a **patch against Mini vMac v36.04** (not a GitHub repo; Google-Drive patch).
- Prebuilt binary: **Intel (x86_64) only**. No arm64 build published.
- On Apple Silicon: run the Intel build under **Rosetta 2** (Rosetta is installed
  on this Mac), or apply the patch to 36.04 source and compile a `mcar` (arm64) build.
- Routing: host MIDI source → "Mini vMac Modem" via macOS **IAC Driver** (Audio MIDI
  Setup) or a patchbay (MidiPipe / OSX MIDI PatchBay). Inside the emulated Mac,
  point Music Mouse at the matching serial port (modem vs printer).

## Reality check: which direction Music Mouse actually uses

The original Music Mouse is a **mouse-played instrument whose primary MIDI is
OUTPUT** (drives external synths). Its **MIDI INPUT is used to receive MIDI
*clock* for syncing** to a DAW / external gear (plus a "MIDI Thru" passthrough).
So "send MIDI to it" = **sync its tempo**, not play it with note input.
([retiary.org revision history](http://retiary.org/ls/progs/mm_revision_history.html))

- Want Music Mouse to **play your synths / record into a DAW** → that's MIDI
  **OUT** of the emulator ("Mini vMac Modem" appears as a MIDI *source*). midivmac does this.
- Want to **sync Music Mouse to your DAW clock** → MIDI **IN**; midivmac does this too.

## The clean alternative: native Eventide MacMM

Eventide shipped a **modern native macOS port** ("MacMM", the program the PDFs in
`~/Downloads/*Music-Mouse-*-OSX-*.pdf` + `MacMM Manual.pdf` document — P/N 209382,
©2026). It has **full CoreMIDI in/out + External Clock Sync** with no emulator,
no Rosetta, no serial hacks — Music Mouse shows up as a selectable MIDI device.
If MIDI integration is the actual goal, this is the right tool. It is an
**Eventide paid product** (not currently on this machine; only the manuals are).
([Eventide](https://www.eventideaudio.com/software/music-mouse/))

## Decision

| Goal | Path |
|---|---|
| Faithful 1989 app **+** MIDI (clock-sync in, notes out) | `midivmac` — Rosetta Intel build, or compile arm64 from the 36.04 patch |
| Just want Music Mouse with real MIDI, least friction | Native **Eventide MacMM** (buy/download), skip the emulator |
| The mouse-played classic, no MIDI | the current `musicmouse` setup is already done |

## Status: built (2026-06-15)

`midivmac` path is live: `musicmouse --midi` (`~/work/apple/bin/musicmouse`) runs
`repo/midivmac.app`. Concrete facts learned building it:

- midivmac is **x86_64** (Mac II variation) → runs under **Rosetta 2** on Apple
  Silicon; needs **MacII.ROM** (the same one our System 7.5.5 setup uses). Got it
  from the E-Maculation thread's Google-Drive links (prebuilt app zip + a unified
  diff against Mini vMac 36.04) — both still live; saved under `midivmac/`.
- CoreMIDI ports verified with a Swift `MIDIGetNumberOfDestinations/Sources` probe:
  **"Mini vMac modem"** + **"Mini vMac printer"**, each as both source AND
  destination. They exist only while the emulator runs.
- **TCC gotcha (cost a debugging detour):** an emulator launched from `~/Downloads`
  (or Desktop/Documents) hangs on a *"would like to access files in your Downloads
  folder"* prompt — until granted it never mounts its disks, never boots, never
  creates the MIDI ports. Fix: keep the install in a **non-TCC-protected** folder
  (`~/Applications/MusicMouse-MiniVMac`). Robust + survives a Downloads cleanup.
- Note-input limitation confirmed: the original Music Mouse takes MIDI **clock**
  (sync) and MIDI Thru, but incoming **notes do not play it**. Note-driven
  behavior belongs to a reimplementation (e.g. the Renoise/Paketti Music Mouse engine).
