# Session: usb-port-revive

The spawning conversation for `features/usb-port-revive.feature`. Faithful, not
flattering — including the two corrections Esa made mid-turn and the two wrong
verdict heuristics I shipped before the third one worked.

## How to get back

- Transcript: `file:///Users/esaruoho/.claude/projects/-Users-esaruoho-work-apple/8c3da0f8-4600-4f8d-87b5-94e7a5bbbac8.jsonl`
- Session ID: `8c3da0f8-4600-4f8d-87b5-94e7a5bbbac8`
- Resume: `cd /Users/esaruoho/work/apple && claude --resume 8c3da0f8-4600-4f8d-87b5-94e7a5bbbac8`
- Date: 2026-08-07, ~16:45–17:05 EEST (machine had booted at 16:45:47 after the incident)

## The request

> "Sometimes one of the Thunderball thunderbolt USB parts stops functioning and
> it only resumes functioning when I laptop and that's extremely frustrating. Is
> there some way for you to figure out what might be going on and maybe write a
> script that lets me refresh it instead of having to you know restart it because
> I just had to call something like eight claude sessions and that's a lot and
> now I have to remember what they were and to start them."

Two problems in one sentence: the port fault, and the collateral damage of the
restart. The second half is the part that actually hurts, and it is fixable with
certainty even when the first half is not.

## Correction 1 — I solved the wrong problem first

I probed the hardware, found the VIA Labs hub pair with the NS1081 / AX88179A /
mouse behind it, and immediately built `bin/usb-reenumerate.c` around
`USBDeviceReEnumerate` — a software replug of a device or hub. I framed it as
the answer.

Esa, mid-turn:

> "no, i mean, anything i plugged into that 2nd usb-c port which is the port the
> hub is now on, if i plugged in a regular ethernet adapter, power adapter,
> anything, nothing was recognized. the port was dead, until i restarted."

And immediately after:

> "there is no replug that fixes a port that has stopped working, and which
> resumes working only after i restart the LAPTOP itself."

He was right, and the second message is the sharper statement of it: a device
reset is definitionally inapplicable when there is no device. I had pattern-
matched "USB device stops working" to the tool I knew how to build rather than
to the fault he described. The re-enumerate helper was kept, but demoted to
rung 1 of a ladder and explicitly documented as unable to help the actual fault.

## Correction 2 — I claimed silence I had not verified

I told him the log showed "total silence from the USB subsystem" from 16:42:45
until the reboot. That came from grepping only *error* lines and seeing no
matches in the gap — not from looking at the full log.

The full log contradicted it: the USB Billboard Device re-enumerated
successfully at **16:43:19**, meaning the bus was still alive 34 seconds after
the fault I had blamed. The genuine silence is 16:43:19 → shutdown, 2m28s.

The conclusion survived; the evidence for it did not. Corrected in-turn.

## Three verdict heuristics, two of them wrong

1. **"Did the subsystem log anything after the last error?"** — keyed off the
   last boot, so it returned ROOT-PORT WEDGE whenever the newest error was
   post-boot. Right answer, wrong reason. Rejected.
2. **"Find the longest silence gap that starts with an error line."** — the
   longest gap in any window is ordinary idle time (15 minutes of nobody
   touching anything), and the line before the real silence was a benign
   successful enumeration, not an error. Verdict flipped to DEVICE WEDGE.
   Rejected.
3. **"Measure the silence that ends AT THE BOOT, counting only kernel
   `[com.apple.usb` lines."** — this is the one that encodes what Esa actually
   described: it stayed dead however long he kept plugging things in, and only
   the restart fixed it. Correct: 2m28s, 17 preceding errors.

Heuristic 3 needed one more fix: launchd's `usbd`/`usbmuxd` SIGKILL lines fire
*during shutdown*, i.e. inside the very gap being measured, and reported the
silence as 25 seconds. Filtering to kernel bus traffic gave the true 2m28s.

The general lesson, worth keeping: when the signal you are measuring is an
absence, anything that logs during the absence will destroy the measurement.

## What I refused to overclaim

Rung 2 (sleep/wake) is graded `@untested` and says so loudly in both the card
and the tool's own output. Sleep power-gates the Type-C PHYs on Apple Silicon,
which is a real mechanism and the reason to try it — but nobody has ever
observed it clearing *this* fault, because the fault has always been met with a
restart. The ledger at `~/.local/state/apple/port-revive-ledger.jsonl` exists so
the next incident settles it instead of re-arguing it.

There is no userspace API on Apple Silicon to power-cycle a Type-C root port.
Saying so plainly is better than inventing a rung that does not exist.

## The part that definitely works

`port-revive sessions --save` captured all 9 running sessions with correct
resume commands, including the Paketti path with spaces in it (which needed
`shlex.quote` — caught in testing). Whatever happens with rung 2, the restart
no longer costs the sessions.

## Side effects surfaced

- `pmset -g` shows several `caffeinate` assertions holding
  `PreventUserIdleSystemSleep`. The machine may therefore rarely idle-sleep on
  its own, which means it rarely gets the sleep-driven port re-init "for free".
  `pmset sleepnow` is a forced sleep and is not blocked by those assertions
  (`PreventSystemSleep` is 0), so rung 2 will still fire.
- The hub moved receptacles across the reboot: it was at locationID `0x001…` /
  `0x002…` before, and is at `0x021…` / `0x022…` now.

## "do we know that this works?" — the verification pass

Esa asked the right question, and the answer at that moment was **partly**. What
followed found three defects, one of them severe.

Before the pass, only two things were genuinely exercised: `--list`, and
`sessions --save/--restore`. The verdict logic had been *fitted* to the single
incident it was built from (n=1, tuned until it produced the answer I already
knew — worth remembering as a caveat, not a validation). Everything on the
recovery side was written but never run.

### Defect 1 (severe): `watch` gave a false "port is DEAD"

Triggering a known-good re-enumerate underneath a running `watch` produced
`0 USB event(s) ... SILENCE — that port is dead`. The command would have told
Esa a perfectly healthy port was dead. Two independent causes:

- Live kernel USB lines carry sender `IOUSBHostFamily` and do **not** match
  `subsystem CONTAINS "usb"` when streaming — even though the identical lines
  **do** match that predicate when read back via `log show`. Same log, same
  lines, different matching behaviour depending on which verb reads it.
- Enumeration lines are debug level; `log stream` drops those without
  `--level debug`.

Only an end-to-end test with a *known* event could have caught this. Reading the
code would not have.

### Defect 2: `watch` hung forever on a quiet bus

Blocking `readline()` inside a deadline loop meant `--seconds` was never
honoured when nothing was logging — i.e. it hung in precisely the dead-port case
it exists to diagnose. Replaced with `select()`.

### Defect 3: `fix` demanded root it did not need

Re-enumerating the Billboard device succeeds as a normal user. The up-front
`geteuid()` gate would have sent Esa to sudo unnecessarily. Now it tries first
and mentions sudo only if an open actually fails.

### What the pass positively established

Rung 1 genuinely works, proven two independent ways rather than by exit code:

- device count polled across a reset: 6 -> 5 -> 6 within about a second
- kernel log, live: `terminateDevice: ... reset API call` followed by
  `enumerateDeviceComplete_block_invoke: enumerated ... at 480 Mbps`

### What remains unverified, and honestly cannot be verified on demand

Rung 2 (sleep/wake) is still `@untested`. It cannot be tested without the fault
being present, and the fault is intermittent. The ledger is the mechanism for
settling it. The verdict logic also remains fitted to one incident; the second
occurrence is the first real test of it.
