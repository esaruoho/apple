---
description: The macOS app-icon grid — inset, corner radius, and the iconutil size table. Get these wrong and the icon renders visibly oversized next to every other Dock icon.
---

# Making a macOS app icon the right size

Every Apple-native app in this repo generates its `.icns` programmatically (AppKit drawing +
`iconutil`, no third-party asset pipeline). The numbers below are not stylistic — they are the
macOS icon grid. Ignore them and the icon looks **deranged**: too big, hard-edged, and obviously
not designed alongside the system icons.

## The rule

**The rounded square is NOT full-bleed.** Apple's macOS template places an **824×824 shape on a
1024×1024 canvas**. The remaining border is transparent, and it is what makes every Dock icon
appear the same size.

| Quantity | Value | As a fraction of the canvas |
|---|---|---|
| Canvas | 1024 × 1024 | 1.0 |
| Shape | 824 × 824 | **0.8047** |
| Inset per side | 100 | **0.0977** (repo uses 0.098) |
| Corner radius | ~185 | **0.2237–0.2248 of the SHAPE**, not of the canvas |

So:

```swift
let inset  = size * 0.098          // per side
let shape  = NSRect(x: inset, y: inset, width: size - 2*inset, height: size - 2*inset)
let radius = shape.width * 0.2237  // of the shape, NOT the canvas
```

Add a soft contact shadow if you want it to sit like a system icon:

```swift
ctx.setShadow(offset: CGSize(width: 0, height: -A * 0.012), blur: A * 0.045,
              color: NSColor(calibratedWhite: 0, alpha: 0.35).cgColor)
```

## The gotcha that bites after you fix the inset

**Scale ALL interior geometry to the inset art square, never to the canvas.** Having inset the
shape, every glyph, stroke width and offset must be measured against the *shape* size — otherwise
the contents overflow the smaller rounded rect and clip.

```swift
let M = S * 0.0977, A = S - 2*M            // margin, art size
let cx = M + A/2, cy = M + A/2             // centre of the ART, not of the canvas
let body = NSRect(x: cx - A*0.29, y: cy - A*0.1875, width: A*0.58, height: A*0.375)
```

Measured failure (2026-08-14, iPhoneMirror): v1 drew the background at `0…S` and every element at
`S * k`. It looked oversized. Insetting the background alone then pushed the phone glyph and the
rotation arc past the rounded edge, because they were still measured against `S`.

## The `iconutil` size table

`iconutil -c icns AppIcon.iconset -o AppIcon.icns` expects exactly these filenames. Render each at
its true pixel size — do not upscale one image:

```
icon_16x16.png     16      icon_16x16@2x.png     32
icon_32x32.png     32      icon_32x32@2x.png     64
icon_128x128.png  128      icon_128x128@2x.png  256
icon_256x256.png  256      icon_256x256@2x.png  512
icon_512x512.png  512      icon_512x512@2x.png 1024
```

## Wiring it into the bundle

1. `Info.plist`: `<key>CFBundleIconFile</key><string>AppIcon</string>` (no `.icns` extension).
2. Copy `AppIcon.icns` into `YourApp.app/Contents/Resources/`.
3. **Run `lsregister -f` on the bundle** — Launch Services caches `Info.plist`, so a new icon can
   otherwise stay invisible. See [`../lessons/`](../lessons/) and the project memory
   `feedback_lsregister_after_app_bundle_changes.md`.

```bash
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP"
```

## Legibility at 16 px

The 16 px rendering is the real test — it appears in the menu bar, Finder lists and tab bars. One
bold silhouette survives; fine detail turns to mud. Draw the mark, render `icon_16x16.png`, and
**look at it** before shipping.

## Implementations in this repo

- [`../../iphonemirror/make-icon.swift`](../../iphonemirror/make-icon.swift) — Swift, all ten sizes in
  one process, grid constants named `M` / `A`.
- `guidance/scripts/make-icon.sh` — bash + `xcrun swift` heredoc per size, SF Symbol on a gradient
  badge. Uses `0.098` / `0.2237`.
- `topbar/scripts/make-icon.sh` — same shape, AppleToolbox's glyph.

- [`macos-about-and-support-window.md`](macos-about-and-support-window.md) — the About panel
  draws the icon at **64pt**; oversized-looking icons have a second cause there.

## Related

- [`app-icon-extraction.md`](app-icon-extraction.md) — pulling icons *out* of existing apps
- [`../../features/iphonemirror-rotated-live-mirror.feature`](../../features/iphonemirror-rotated-live-mirror.feature)
