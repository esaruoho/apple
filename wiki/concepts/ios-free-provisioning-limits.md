---
description: Building an iOS app on a free Personal Team — where the team id actually lives, the 3-device cap, and the fact that the device list is not viewable anywhere
---

# iOS free provisioning limits

What it takes to get a locally-built iOS app onto a phone with a **free** Apple ID (no paid
Developer Program), and where it stops. Established 2026-08-17 building [[dualcam]].

## Find the team id in a file, not in a screenshot

Automatic signing needs `DEVELOPMENT_TEAM`. A hardcoded one is wrong the moment the project
moves machines, and the error it produces points at the wrong thing:

```
error: No Account for Team "XXXXXXXXXX". Add a new account in Accounts settings…
```

That reads like "you are not signed in" when the real cause is a stale id baked into the
project. The signed-in team is readable here:

```bash
defaults read com.apple.dt.Xcode IDEProvisioningTeamManagerLastSelectedTeamID
# or: ~/Library/Preferences/com.apple.dt.Xcode.plist → IDEProvisioningTeamByIdentifier
```

`dualcam/build.sh` reads it at build time and passes `DEVELOPMENT_TEAM=` on the command line,
so nothing is hardcoded. **Do not ask a human to screenshot Xcode for this** — it is a plist.

A keychain identity is NOT proof of a usable team: `security find-identity` can show an
`Apple Development: … (TEAMID)` certificate for a team the signed-in account has no access to
(e.g. a former employer's). That certificate is what produces the misleading error above.

## The caps

- **3 iPhone devices**, and they cannot be removed — the allowance resets annually. Hitting it
  gives, at build time:
  `Communication with Apple failed: Your development team has reached the maximum number of
  registered iPhone devices.`
- Building with `-destination 'generic/platform=iOS'` **never registers the device**. Xcode has
  no idea which phone you mean, so the profile is built without it and the install fails with
  `ApplicationVerificationFailed` / `0xe8008012 (This provisioning profile cannot be installed
  on this device)`. Build with `-destination "id=<UDID>"` to have the device registered.

## The device list is not viewable. Anywhere.

Xcode ▸ Settings ▸ Accounts ▸ Personal Team shows **"On Device Testing — 3 Provisioned
Devices"** as *static text*. There is no disclosure arrow, no clickable row. Verified by
screenshot after claiming otherwise twice.

And:

- Free teams get **no developer.apple.com portal**, so there is nothing to browse there.
- Nothing is cached locally: no device registry in `~/Library/Developer/Xcode`, none in Xcode's
  prefs, none in the keychain.
- The `.mobileprovision` files only echo back the device(s) in *that* profile. On this Mac all
  three profiles list the same single UDID while Apple counts three registered iPhones — so the
  other two are invisible.

**Therefore: the count is knowable, the membership is not.** Neither which devices, nor when
they were added. The only untried lever is the *Download Manual Profiles* button on that pane,
which may or may not hand back profiles covering the others.

## What this means for a multi-phone rig

Free provisioning cannot carry one: 3 devices maximum, and apps built this way stop launching
after a short window regardless of the profile's 1-year expiry date. A permanent 4-phone
installation needs the paid Apple Developer Program (100 devices). Free provisioning carries
*one test*, not a rig.

## Installing, once signing is sorted

1. **Developer Mode** on the phone: Settings ▸ Privacy & Security ▸ Developer Mode ▸ On, then
   reboot. The option only appears after a development-signed app has been sent to the device.
2. Wait for the phone to be **stably** back — see [[iphone-capture-over-usb]] for why one
   sighting is not enough.
3. `xcrun devicectl device install app --device <identifier> <App.app>`, with the identifier
   taken from `--json-output`, never from the table's last column (that is the model).

Related: [[iphone-capture-over-usb]], [[dualcam]].
