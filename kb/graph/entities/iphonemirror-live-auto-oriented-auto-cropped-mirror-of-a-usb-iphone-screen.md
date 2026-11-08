---
name: iPhoneMirror — live, auto-oriented, auto-cropped mirror of a USB iPhone screen
slug: iphonemirror-live-auto-oriented-auto-cropped-mirror-of-a-usb-iphone-screen
kind: feature
confidence: 0.6
updated: 2026-11-08
---

## Summary
Convey feature: features/iphonemirror-rotated-live-mirror.feature.

## Claims
- Scenario (L29): A Lightning iPhone is found at all
- Scenario (L39): The live feed is rotated, which QuickTime cannot do
- Scenario (L47): Orientation is chosen by reading the SCENE, not the chrome
- Scenario (L58): OCR garbage from upside-down chrome is rejected
- Scenario (L67): Camera.app's mode wheel is cropped out by default
- Scenario (L75): Camera.app's ICON control row is also cropped out
- Scenario (L91): Bare invocation just works
- Scenario (L100): Detection does not deadlock the main thread
- Scenario (L109): The device is single-client, and that is explained not swallowed
- Scenario (L116): The crop constant is calibrated, and nudgeable when it is not right
- Scenario (L126): Space hides every other app
- Scenario (L137): It ships the SHARED Help and donate panel, like every app here
- Scenario (L148): It has a real app icon, on the macOS icon grid
- Scenario (L164): There is exactly ONE copy of the app, in /Applications
- Scenario (L177): Several phones at once, ticked on and off from a menu
- Scenario (L190): Unticking a device does not crash the app
- Scenario (L204): Each device remembers its own calibration
- Scenario (L214): Continuity Cameras are offered but never auto-opened
- Scenario (L224): Detection is CONTINUOUS, not one-shot
- Scenario (L238): Menu rows never swap slots
- Scenario (L247): A device row never vanishes while you reach for it
- Scenario (L258): A saved calibration seeds, it does not lock
- Scenario (L267): A yanked cable leaves the window alone
- Scenario (L278): The screen-capture assistant is kept alive
- Scenario (L288): Continuity Cameras get no Vision pass at all
- Scenario (L296): Layout is one keypress before a take
- Scenario (L311): ⌘0 rescues minimised windows
- Scenario (L331): Front-window commands hit the window you clicked
- Scenario (L343): The picture does not flip on its own
- Scenario (L360): Orientation can be hard-locked for a demo
- Scenario (L370): A Continuity Camera that flaps does not flap its window
- Scenario (L381): Device enumeration must be LIVE, not a per-process snapshot
- Scenario (L397): recburn can bake the phone feed in directly

## Relationships
