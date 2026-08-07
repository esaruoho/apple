# =============================================================================
# REPORT CARD: usb-port-revive — recover a wedged USB-C / Thunderbolt port
#                                without paying the cost of a restart
# Skin: macOS kernel USB log + IOKit + power management
# SESSION >> features/usb-port-revive.session.md
#
# WHAT THIS CARD SPAWNS
#   Codespace:  bin/port-revive             the diagnose + recovery ladder (Python stdlib)
#               bin/usb-reenumerate.c       IOKit helper, USBDeviceReEnumerate (C, clang)
#               bin/.build/usb-reenumerate  compiled on demand by port-revive
#   Thinkspace: the distinction between a DEVICE wedge (a device or hub stops
#               responding; the controller is fine) and a ROOT-PORT wedge (the
#               receptacle itself goes dark; nothing plugged in is even seen).
#               They look identical from userspace. Only the kernel log tells
#               them apart, and only a *silence* signature does it reliably.
#   Areaspace:  owns USB/Thunderbolt port diagnosis and recovery, plus
#               snapshotting Claude Code sessions so that a restart is cheap.
#               Does NOT own: Syncthing, Cloudcity, the Mini. Laptop-local only.
#
# THE ORIGINATING INCIDENT (2026-08-07, verified from the kernel log)
#   16:42:44  AppleUSBIORequest: mouse + NS1081 endpoints: 0xe00002ed
#             (transaction error), repeatedly
#   16:42:45  AppleUSB30Hub@00200000: hub failed control request with 0xe00002d8
#             AppleUSB30Hub: hardwareException type 0x00000001
#             terminateDevice: destroying NS1081, then AX88179A
#   16:43:19  USB Billboard Device re-enumerates  <- the bus was still alive here
#   16:43:19  ...then NOTHING. 2m28s of total kernel USB silence.
#   16:45:47  reboot — the only thing that brought the port back
#   No overcurrent message anywhere, so this is not a power latch. It is a
#   transaction-timeout cascade that took the XHCI root port down with it.
#
# HARDWARE UNDER TEST
#   VIA Labs VL8xx hub pair (USB2 0x2109:2817 + USB3 0x2109:0817) behind one
#   USB-C link, carrying: NS1081 disk bridge, AX88179A gigabit ethernet,
#   Logitech mouse, DP Billboard device.
#
# RESULT
#   Feature commits: see `git log --follow bin/port-revive`
#   Delivery: direct-push to main, no PR
#   Files changed: bin/port-revive (new), bin/usb-reenumerate.c (new),
#                  features/usb-port-revive.feature (new),
#                  features/usb-port-revive.session.md (new)
# =============================================================================

Feature: Recover a wedged USB-C port without losing the work on the machine
  As someone whose second USB-C port intermittently goes completely dead
  I want to tell the two failure modes apart and try every reboot-free lever
  So that a restart is the last resort rather than the first, and so that when
  a restart IS unavoidable it does not cost me eight Claude Code sessions

  # ---------------------------------------------------------------- diagnose

  @built @hw-verified
  Scenario: Classify a fault that only a restart recovered
    Given the kernel USB log contains transaction errors and a hub hardwareException
    And after the last bus event the subsystem stays silent until the next boot
    When I run `port-revive diagnose --since 1h`
    Then the verdict is "ROOT-PORT WEDGE — and the restart is what recovered it"
    And it reports the measured silence and the error count preceding it
    # Verified 2026-08-07 against the real incident: reports 0:02:28 of silence
    # and 17 errors in the preceding 10 minutes.
    # bin/port-revive :: cmd_diagnose

  @built @hw-verified
  Scenario: launchd service churn must not be mistaken for bus activity
    Given launchd logs usbd and usbmuxd being SIGKILLed during shutdown
    When the silence before the reboot is measured
    Then only kernel "[com.apple.usb" lines count as the subsystem talking
    # This bug was live during development: counting launchd lines reported the
    # silence as 0:00:25 instead of 0:02:28 and flipped the verdict to the wrong
    # branch. The shutdown noise sits inside the very gap being measured.
    # bin/port-revive :: cmd_diagnose, `stamped` filter

  @built @hw-verified
  Scenario: An ordinary idle gap must not be read as a wedge
    Given the machine simply had nothing plugged or unplugged for 15 minutes
    When the fault is classified
    Then the verdict anchors on silence that ends AT THE BOOT, not on the longest gap
    # Also live during development: the longest gap in the window was a benign
    # 15-minute idle stretch that dominated the maximum.
    # bin/port-revive :: cmd_diagnose, boot-anchored branch

  # ------------------------------------------------------------------ rung 1

  @built @hw-verified
  Scenario: Software replug of a device or hub that wedged
    Given a device or hub is still enumerated but has stopped responding
    When I run `sudo port-revive fix`
    Then each matching hub is re-enumerated via IOUSBLib USBDeviceReEnumerate
    And the device count before and after is reported
    # USBDeviceReEnumerate requires IOUSBDeviceInterface187 or newer; the helper
    # walks 942 -> 187 and uses the first that answers. Devices with a kernel
    # driver attached need USBDeviceOpenSeize, not USBDeviceOpen.
    # bin/usb-reenumerate.c :: cmd_reset

  @built @hw-verified
  Scenario: Rung 1 is honest about not applying to a dead port
    Given the port is dead and therefore nothing downstream is enumerated
    When I run `port-revive fix`
    Then it states there is no device object left to reset
    And it moves to rung 2 rather than pretending to have done something
    # bin/port-revive :: cmd_fix, empty-targets branch

  # ------------------------------------------------------------------ rung 2

  @built @untested
  Scenario: Sleep/wake as the only reboot-free lever on the port hardware
    Given the root port has wedged and rung 1 cannot apply
    When I run `port-revive fix --sleep`
    Then running Claude Code sessions are snapshotted first
    And the attempt is written to the ledger
    And the machine sleeps via `pmset sleepnow`
    # GRADE IS @untested DELIBERATELY. On Apple Silicon, system sleep power-gates
    # the Type-C PHYs and XHCI controllers and wake re-initialises them, which is
    # why this is the right thing to try. Whether it clears THIS fault has never
    # been observed, because the fault has so far always been met with a restart.
    # The ledger exists to settle the question the next time it happens.
    # Do not upgrade this grade without an actual observed recovery.
    # bin/port-revive :: cmd_fix, rung 2

  @built @hw-verified
  Scenario: Rung 2 never fires by accident
    Given sleeping is disruptive
    When I run `port-revive fix` without `--sleep`
    Then it explains rung 2 and exits without sleeping
    # bin/port-revive :: cmd_fix, `if not args.sleep`

  # ------------------------------------------------------------------- live

  @built @untested
  Scenario: Tell a dead port apart from an empty port
    Given ioreg cannot distinguish "nothing plugged in" from "port not responding"
    When I run `port-revive watch` and plug something into the suspect port
    Then any streamed line means the controller saw it and the port is alive
    And total silence means the port is dead at the controller level
    # bin/port-revive :: cmd_watch

  # --------------------------------------------------------------- sessions

  @built @hw-verified
  Scenario: A restart must not cost the day's sessions
    Given several Claude Code sessions are running across different repos
    When I run `port-revive sessions --save`
    Then each session's cwd and session id are recorded
    And `port-revive sessions --restore` prints a ready-to-paste resume command each
    # Verified 2026-08-07: captured all 9 live sessions with correct ids.
    # Session ids come from `--resume` in argv, or the newest transcript under
    # ~/.claude/projects/<cwd with / replaced by ->. cwd via lsof.
    # Paths containing spaces are shlex-quoted (the Paketti .xrnx path needs it).
    # bin/port-revive :: claude_sessions, cmd_sessions

  # ------------------------------------------------------------- known gaps

  @todo
  Scenario: Automatically snapshot sessions when a wedge is detected
    Given the wedge signature is recognisable in the live log stream
    When the signature appears
    Then sessions should be snapshotted without being asked
    # Not built. Would need a always-running watcher; deliberately not added,
    # since an always-on log stream costs battery for a fault seen occasionally.

  @todo
  Scenario: Establish the root cause rather than only recovering from it
    Given the fault is a transaction-timeout cascade with no overcurrent
    Then it is still unknown whether the trigger is the VIA hub firmware, the
    cable, the NS1081 bridge, or the Mac's Type-C PHY
    # The ledger plus `diagnose` output across several incidents is the evidence
    # base for answering this. One incident is not a pattern.
