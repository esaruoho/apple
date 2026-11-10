# iPhoneLatest 📱

**Take a photo with your iPhone, drag it into any chat.**

A tiny Apple-native menu-bar app. One click on 📱 opens the iPhone's camera. Take the shot, tap **Use Photo**, and it appears as a thumbnail under the icon, ready to drag into Terminal, Claude, Mail or Messages.

No AirDrop, no emailing yourself, no iCloud wait, no cable needed.

## Use

| Action | Result |
|---|---|
| Click **📱** | The iPhone camera opens. Shoot, tap **Use Photo**, and the thumbnail appears. |
| **Drag** the thumbnail | Drops the JPEG into any app or chat. |
| Click **📱** again, thumbnail open | Closes it. |
| **📂 Open iPhone-Latest folder** | Every photo you've taken, in Finder. |
| **Right-click 📱** | Help / Support · Open folder · **Open at Login** · Quit |

Every photo is kept (never overwritten) in `~/Pictures/iPhone-Latest/Continuity-<yyyyMMdd-HHmmss>.jpg`.

## Claude can ask for a photo

- `bin/iphone-snap` opens `iphonelatest://take`, waits for your shot, and prints the JPEG path. A Claude session then Reads the path and sees the photo.
- MCP tool **`take_iphone_photo`** (`bin/iphone-snap-mcp`, dependency-free stdio server) is available in every Claude Code session:
  `claude mcp add iphone -s user -- ~/work/apple/bin/iphone-snap-mcp`

## Requirements

- macOS 13+ and an iPhone on the **same Apple ID**, with **Wi-Fi + Bluetooth** on (Continuity Camera).

## Install / build

```bash
iphone-latest/build.sh      # compile → sign → /Applications/iPhoneLatest.app → launch
```

On first launch it registers itself to **Open at Login** (Apple's `SMAppService`). Toggle it from right-click 📱 ▸ Open at Login, or in System Settings ▸ General ▸ Login Items.

## How it works

Continuity Camera through Apple's own "Import from iPhone ▸ Take Photo" mechanism, the same one Finder, Notes and TextEdit use:

- `NSMenuItem.importFromDeviceIdentifier` lives in the app's **main menu**. A probe showed AppKit only activates it there; pop-up menus stay grey.
- AppKit fills in the device submenu only after the menu has been opened once, so the first click opens it and cancels it after 0.4 s, then fires **Take Photo** directly.
- The photo comes back through `NSServicesMenuRequestor.readSelection(from:)`, gets saved as JPEG and shown as a draggable `NSImageView`. The drag starts only after the mouse actually moves.

## Why not the USB cable?

We tried that first, and it's documented in [`FINDINGS.md`](FINDINGS.md). Over USB, iOS publishes new photos to ImageCaptureCore late and unreliably: one at a time, 15–60 s after the shot, with stale catalogs after reopening the session. Continuity Camera returns the shot in a few seconds, every time.

## Files

- `main.swift` — the app (~240 lines)
- `build.sh` — build + install
- `make-icon.swift` — renders `AppIcon.icns`
- `FINDINGS.md` — the USB investigation
- Report card: [`../features/iphone-latest.feature`](../features/iphone-latest.feature)
- Shared Help + donate panel: [`../shared/SupportHelp.swift`](../shared/SupportHelp.swift)
