#!/usr/bin/env swift
// render-tag-icon.swift — render a colored SF-Symbol tag icon as a .icns file.
// Usage: swift render-tag-icon.swift <color-name> <out.icns>
// Color: none|gray|green|purple|blue|yellow|red|orange

import AppKit
import Foundation

let args = CommandLine.arguments
guard args.count == 3 else {
    FileHandle.standardError.write("usage: render-tag-icon <color> <out.icns>\n".data(using: .utf8)!)
    exit(2)
}
let colorName = args[1].lowercased()
let outPath = args[2]

let colorMap: [String: NSColor] = [
    "none":   .systemGray,
    "gray":   .systemGray,
    "grey":   .systemGray,
    "green":  .systemGreen,
    "purple": .systemPurple,
    "blue":   .systemBlue,
    "yellow": .systemYellow,
    "red":    .systemRed,
    "orange": .systemOrange,
]
guard let tint = colorMap[colorName] else {
    FileHandle.standardError.write("unknown color: \(colorName)\n".data(using: .utf8)!)
    exit(2)
}

// Resolve the SF Symbol "tag.fill" as an NSImage. macOS 11+.
let cfg = NSImage.SymbolConfiguration(pointSize: 800, weight: .bold)
guard var sym = NSImage(systemSymbolName: "tag.fill", accessibilityDescription: "tag")?
        .withSymbolConfiguration(cfg) else {
    FileHandle.standardError.write("SF Symbol unavailable\n".data(using: .utf8)!)
    exit(1)
}

func renderPNG(size: Int, tint: NSColor, symbol: NSImage) -> Data {
    let pixel = CGFloat(size)
    let canvas = NSImage(size: NSSize(width: pixel, height: pixel))
    canvas.lockFocus()

    // Transparent background — macOS app icon will float on whatever Finder paints.
    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: pixel, height: pixel).fill()

    // Tint the symbol by drawing it through a fill-with-color mask.
    let symRect = NSRect(x: pixel * 0.08, y: pixel * 0.08,
                         width: pixel * 0.84, height: pixel * 0.84)
    let img = NSImage(size: symRect.size)
    img.lockFocus()
    symbol.draw(in: NSRect(origin: .zero, size: symRect.size),
                from: .zero, operation: .sourceOver, fraction: 1.0)
    tint.set()
    NSRect(origin: .zero, size: symRect.size).fill(using: .sourceAtop)
    img.unlockFocus()
    img.draw(in: symRect, from: .zero, operation: .sourceOver, fraction: 1.0)

    canvas.unlockFocus()

    guard let tiff = canvas.tiffRepresentation,
          let rep  = NSBitmapImageRep(data: tiff),
          let png  = rep.representation(using: .png, properties: [:]) else {
        FileHandle.standardError.write("png encode failed at \(size)\n".data(using: .utf8)!)
        exit(1)
    }
    return png
}

let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
    .appendingPathComponent("tagicon-\(UUID().uuidString).iconset")
try? FileManager.default.removeItem(at: tmp)
try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)

let entries: [(Int, String)] = [
    (16,  "icon_16x16.png"),
    (32,  "icon_16x16@2x.png"),
    (32,  "icon_32x32.png"),
    (64,  "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024,"icon_512x512@2x.png"),
]
for (size, name) in entries {
    let data = renderPNG(size: size, tint: tint, symbol: sym)
    try data.write(to: tmp.appendingPathComponent(name))
}

let proc = Process()
proc.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
proc.arguments = ["-c", "icns", tmp.path, "-o", outPath]
try proc.run()
proc.waitUntilExit()
try? FileManager.default.removeItem(at: tmp)

if proc.terminationStatus != 0 {
    FileHandle.standardError.write("iconutil failed\n".data(using: .utf8)!)
    exit(1)
}
print("wrote \(outPath)")
