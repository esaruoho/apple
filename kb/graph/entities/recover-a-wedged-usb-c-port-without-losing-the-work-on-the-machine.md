---
name: Recover a wedged USB-C port without losing the work on the machine
slug: recover-a-wedged-usb-c-port-without-losing-the-work-on-the-machine
kind: feature
confidence: 0.6
updated: 2026-11-02
---

## Summary
Convey feature: features/usb-port-revive.feature.

## Claims
- Scenario (L54): Classify a fault that only a restart recovered
- Scenario (L65): launchd service churn must not be mistaken for bus activity
- Scenario (L75): An ordinary idle gap must not be read as a wedge
- Scenario (L86): Software replug of a device or hub that wedged
- Scenario (L103): Root is not assumed to be required
- Scenario (L114): Rung 1 is honest about not applying to a dead port
- Scenario (L124): Sleep/wake as the only reboot-free lever on the port hardware
- Scenario (L139): Rung 2 never fires by accident
- Scenario (L148): Tell a dead port apart from an empty port
- Scenario (L158): The watch predicate must match LIVE kernel USB lines
- Scenario (L172): Watch must survive silence, because silence is the finding
- Scenario (L185): A restart must not cost the day's sessions
- Scenario (L199): Automatically snapshot sessions when a wedge is detected
- Scenario (L207): Establish the root cause rather than only recovering from it

## Relationships
