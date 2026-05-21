# App Probe

`bin/app-probe.py` — 13-layer automation probe that extracts ALL automation knowledge from 66 Apple apps into `dictionaries/<app>/<app>-probe.yaml`.

## The 13 layers

| # | Layer | Source | Method |
|---|-------|--------|--------|
| 1 | Scripting Dictionary | App bundle | `sdef` tool |
| 2 | URL Schemes | Info.plist `CFBundleURLTypes` | `plistlib` |
| 3 | Document Types | Info.plist `CFBundleDocumentTypes` | `plistlib` |
| 4 | **App Intents / Siri Phrases** | `Metadata.appintents/extract.actionsdata` | `json.load` |
| 5 | NSServices | Info.plist `NSServices` | `plistlib` |
| 6 | User Activity Types | Info.plist `NSUserActivityTypes` | `plistlib` |
| 7 | Entitlements | App binary | `codesign --entitlements` |
| 8 | Linked Frameworks | App binary | `otool -L` |
| 9 | Spotlight Metadata | Spotlight index | `mdls` |
| 10 | LaunchServices | LS database | `lsregister -dump` (opt-in) |
| 11 | Plugin Extensions | `Contents/PlugIns/*.appex` | Directory scan |
| 12 | Notification Actions | Info.plist `UNUserNotificationCenter` | `plistlib` |
| 13 | CLI Tools | `/usr/bin/*` | Path check |

## Totals

**66 apps, 378 layer hits, 20 with App Intents, 35 with URL schemes, 32 CLI tools.**

## Gotchas

- **App Intents data format:** `actions` / `queries` can be dict or list; `enums` is always a list.

## Cross-app index

`dictionaries/_probe-index.yaml` — URL scheme registry, App Intents summary, framework matrix, services map.

Companion: [`app-plist-probe`](app-plist-probe.md) for the plist mining layer.
