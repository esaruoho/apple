#!/bin/bash
# Generate Guidance.icns — white "connected nodes" glyph on an indigo badge.
# Pure Apple-native pipeline: xcrun swift (AppKit render) + iconutil. Safe to re-run.
# Output: guidance/Guidance.icns

set -e
cd "$(dirname "$0")/.."
ICONSET="Guidance.iconset"
OUT="Guidance.icns"

rm -rf "$ICONSET" "$OUT"
mkdir -p "$ICONSET"

render() {
    local size=$1
    local out=$2
    xcrun swift - "$size" "$out" <<'SWIFT'
import Cocoa
let size = CGFloat(Int(CommandLine.arguments[1])!)
let outPath = CommandLine.arguments[2]

let img = NSImage(size: NSSize(width: size, height: size))
img.lockFocus()

// Rounded-rect badge inset ~10% (macOS Big Sur+ icon spec).
let inset = size * 0.098
let shape = NSRect(x: inset, y: inset, width: size - 2 * inset, height: size - 2 * inset)
let radius = shape.width * 0.2237
let bg = NSBezierPath(roundedRect: shape, xRadius: radius, yRadius: radius)
bg.addClip()
let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.42, green: 0.36, blue: 0.93, alpha: 1),
    NSColor(calibratedRed: 0.20, green: 0.16, blue: 0.55, alpha: 1),
])!
gradient.draw(in: shape, angle: -90)

// White SF Symbol (the same "connected nodes" mark the app uses in its header).
let cfg = NSImage.SymbolConfiguration(pointSize: shape.height * 0.52, weight: .semibold)
    .applying(NSImage.SymbolConfiguration(paletteColors: [.white]))
if let sym = NSImage(systemSymbolName: "point.3.connected.trianglepath.dotted",
                     accessibilityDescription: nil)?.withSymbolConfiguration(cfg) {
    let s = sym.size
    let r = NSRect(x: shape.midX - s.width / 2, y: shape.midY - s.height / 2,
                   width: s.width, height: s.height)
    sym.draw(in: r)
}

img.unlockFocus()

guard let tiff = img.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let data = rep.representation(using: .png, properties: [:]) else {
    fputs("PNG encode failed at \(Int(size))px\n", stderr); exit(2)
}
try data.write(to: URL(fileURLWithPath: outPath))
SWIFT
}

render 16   "$ICONSET/icon_16x16.png"
render 32   "$ICONSET/icon_16x16@2x.png"
render 32   "$ICONSET/icon_32x32.png"
render 64   "$ICONSET/icon_32x32@2x.png"
render 128  "$ICONSET/icon_128x128.png"
render 256  "$ICONSET/icon_128x128@2x.png"
render 256  "$ICONSET/icon_256x256.png"
render 512  "$ICONSET/icon_256x256@2x.png"
render 512  "$ICONSET/icon_512x512.png"
render 1024 "$ICONSET/icon_512x512@2x.png"

iconutil -c icns "$ICONSET" -o "$OUT"
rm -rf "$ICONSET"
echo "Built: $(pwd)/$OUT ($(du -h "$OUT" | cut -f1))"
