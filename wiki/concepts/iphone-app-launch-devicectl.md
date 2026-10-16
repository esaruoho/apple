---
description: Launch (and suspend/resume/signal) ANY app on a USB-tethered, paired iPhone from the Mac command line via Xcode's CoreDevice `xcrun devicectl` — no jailbreak, no custom app, no URL scheme. The remote-app-control capability.
---

# Commanding iPhone apps from the Mac — `xcrun devicectl`

**You can launch any installed iOS app on a tethered iPhone, from the Mac
terminal, with no jailbreak, no sideloaded helper, no URL scheme.** The lever is
Xcode's CoreDevice tool `xcrun devicectl` (part of the Command Line Tools /
Xcode, `/usr/bin/xcrun`). Verified 2026-10-16 on esaiPhone16Pro (iPhone 16 Pro,
iPhone17,1) by launching Compass (`com.apple.compass`) → exit 0, app foregrounded
on the phone. **No permission prompt appeared on the phone** — the existing
pairing/trust is sufficient; the developer-disk-image services are enabled on the
fly by devicectl itself.

This is the general capability behind `bin/compass --open`. It generalises: the
phone becomes a scriptable surface — boot any app, then read it back via the
screen-OCR path ([`iphone-usb-capture-probe.md`](iphone-usb-capture-probe.md)).

## Preconditions

- iPhone connected by USB and **paired/trusted** with this Mac (one-time "Trust
  This Computer"). Once trusted, no further prompt per launch.
- Xcode or the Command Line Tools installed (`xcrun devicectl --version` → 506.7
  as of writing).
- The device shows as `available (paired)` in `xcrun devicectl list devices`.
- The phone does **not** need to be a registered development device, and the app
  does **not** need to be your own. Apple system apps launch fine.

## The four commands

```bash
# 1. Find the device (grab its UUID identifier)
xcrun devicectl list devices
#   Name           Identifier                             State
#   esaiPhone16Pro 3C55D532-8471-567F-9BBA-9FB0B9C954BE   available (paired)

DID=3C55D532-8471-567F-9BBA-9FB0B9C954BE   # or use --device esaiPhone16Pro (name works too)

# 2. Enumerate installed apps + bundle IDs (186 apps incl. Apple system apps)
xcrun devicectl device info apps --device "$DID" --include-all-apps
#   Compass   com.apple.compass        | Camera com.apple.camera | Maps com.apple.Maps
#   Measure   com.apple.measure        | Settings com.apple.Preferences  ...
#   (default, WITHOUT --include-all-apps, shows only developer/3rd-party apps)

# 3. Launch an app by bundle id (foregrounds it on the phone)
xcrun devicectl device process launch --device "$DID" com.apple.compass
#   -> "Launched application with com.apple.compass bundle identifier."

# 4. Process control on the running app
xcrun devicectl device process suspend  --device "$DID" --pid <pid>
xcrun devicectl device process resume   --device "$DID" --pid <pid>
xcrun devicectl device process signal   --device "$DID" --pid <pid> --signal SIGKILL
xcrun devicectl device process sendMemoryWarning --device "$DID" --pid <pid>
```

**Scripting rule (Apple's own):** human stdout is NOT stable across releases.
For programs, pass `--json-output <path>` and parse the JSON file — that is the
only supported machine interface. (`bin/compass` scrapes stdout for the launch
case only, which is low-risk; anything richer should use `-j`.)

## Getting an app to the "right position"

`launch` takes positional **command-line arguments** after the bundle id, and
environment variables via the host-side `DEVICECTL_CHILD_<NAME>` prefix:

```bash
# args:  ... launch --device "$DID" <bundle-id> arg1 arg2
# env:   DEVICECTL_CHILD_FOO=bar xcrun devicectl device process launch ...
xcrun devicectl device process launch --device "$DID" \
  --environment-variables '{"LANG":"en_US.UTF-8"}' com.example.app -- --flag value
```

**Caveat (honest):** most App Store apps ignore `argv`/env — iOS apps aren't
argv-driven the way CLIs are. `launch` reliably gets the app **open and
foregrounded**; to land on a *specific screen inside* an app you generally need
that app's **URL scheme / Universal Link**, which is a different mechanism
(opening a URL on the device, not passing argv). So the honest capability today
is: **boot any app to its launch state**. Deep-linking to an exact position is a
per-app follow-up (URL scheme where one exists). Do not overclaim "right
position" as solved for arbitrary apps — it is solved for *launch*.

## Also available (not yet exercised here)

`xcrun devicectl device` also exposes: `info` (details/apps/files/lockState),
`install`/`uninstall app`, `copy` files to/from the device, `manage` pairing.
`devicectl list`, `diagnose`, `manage` are the other top-level subcommands.

## Relationship to the rest of the stack

- **Launch side (this page):** `devicectl` — Mac → phone, commands IN.
- **Read side:** [`iphone-usb-capture-probe.md`](iphone-usb-capture-probe.md) —
  phone screen → Mac, pixels OUT, via CoreMediaIO/AVFoundation (`bin/iphone-screen`).
- **Worked combo:** [`../../features/iphone-compass.feature`](../../features/iphone-compass.feature)
  — launch Compass + OCR its heading to find East (`bin/compass`).

## Gotcha log

- `info apps` default view hides Apple system apps; use `--include-all-apps`
  (186 apps on the test phone) or `--bundle-id com.apple.compass` to confirm one.
- Device identifier column in `list devices` is a UUID; extract it with a UUID
  regex, not column counting — the `State` field ("available (paired)") contains
  a space and breaks `$N` indexing. (`bin/compass open_compass()` does this.)
- A successful **launch** does NOT imply screen-capture works — the two are
  independent. On 2026-10-16 Compass launched fine while `iphone-screen --list`
  still saw 0 capture devices even with the phone unlocked (capture-side issue,
  tracked in the capture-probe page, not a launch problem).
