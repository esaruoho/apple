// make-icon.swift — generates fleet/AppIcon.icns (Option A: Fleet Formation)
// Apple-native: AppKit drawing + iconutil. Run: xcrun swift make-icon.swift
// Follows wiki/concepts/macos-app-icon-sizing.md:
//   - 824x824 squircle on 1024x1024 canvas (inset 0.098, corner radius 0.2237 of shape)
//   - Drop contact shadow
//   - Scales geometry to inset art square A

import AppKit
import Foundation

func drawFleetIcon(size S: CGFloat) -> NSBitmapImageRep {
    let px = Int(S)
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                               isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let ctx = NSGraphicsContext.current!.cgContext
    ctx.setShouldAntialias(true)

    // macOS app-icon grid: rounded square is NOT full bleed.
    // 824x824 shape on a 1024x1024 canvas.
    let M = S * 0.098
    let A = S - 2 * M
    let art = NSRect(x: M, y: M, width: A, height: A)
    let cx = art.midX, cy = art.midY

    // Drop contact shadow
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -A * 0.012), blur: A * 0.045,
                  color: NSColor(calibratedWhite: 0, alpha: 0.38).cgColor)
    let shadowPath = NSBezierPath(roundedRect: art, xRadius: A * 0.2237, yRadius: A * 0.2237)
    NSColor(calibratedWhite: 0.05, alpha: 1).setFill()
    shadowPath.fill()
    ctx.restoreGState()

    // Badge body: deep navy / space slate gradient
    let badge = NSBezierPath(roundedRect: art, xRadius: A * 0.2237, yRadius: A * 0.2237)
    badge.addClip()
    let grad = NSGradient(colors: [
        NSColor(calibratedRed: 0.07, green: 0.12, blue: 0.22, alpha: 1.0),
        NSColor(calibratedRed: 0.03, green: 0.05, blue: 0.11, alpha: 1.0)
    ])!
    grad.draw(in: art, angle: -90)

    // Subtle top rim highlight (Apple specular bevel)
    ctx.saveGState()
    let rim = NSBezierPath(roundedRect: art.insetBy(dx: A * 0.006, dy: A * 0.006),
                           xRadius: A * 0.22, yRadius: A * 0.22)
    rim.lineWidth = A * 0.012
    let rimGrad = NSGradient(colors: [
        NSColor(white: 1.0, alpha: 0.22),
        NSColor(white: 1.0, alpha: 0.02),
        NSColor(white: 0.0, alpha: 0.20)
    ])!
    rimGrad.draw(in: rim.bounds, angle: -90)
    ctx.restoreGState()

    // Soft ambient blue glow in center
    let glowRect = NSRect(x: cx - A * 0.35, y: cy - A * 0.30, width: A * 0.70, height: A * 0.60)
    let glowGrad = NSGradient(colors: [
        NSColor(calibratedRed: 0.10, green: 0.35, blue: 0.65, alpha: 0.35),
        NSColor(calibratedRed: 0.10, green: 0.35, blue: 0.65, alpha: 0.0)
    ])!
    glowGrad.draw(in: glowRect, relativeCenterPosition: .zero)

    // Shared Network Bus / Rail (beneath all machines)
    let busY = cy - A * 0.23
    let busW = A * 0.68
    let busRect = NSRect(x: cx - busW / 2, y: busY - A * 0.012, width: busW, height: A * 0.024)
    let busPath = NSBezierPath(roundedRect: busRect, xRadius: A * 0.012, yRadius: A * 0.012)
    NSColor(calibratedRed: 0.15, green: 0.45, blue: 0.75, alpha: 0.45).setFill()
    busPath.fill()

    // Inner bright data bus line
    let coreLine = NSBezierPath()
    coreLine.move(to: NSPoint(x: cx - busW * 0.45, y: busY))
    coreLine.line(to: NSPoint(x: cx + busW * 0.45, y: busY))
    coreLine.lineWidth = A * 0.014
    coreLine.lineCapStyle = .round
    NSColor(calibratedRed: 0.25, green: 0.70, blue: 1.0, alpha: 0.85).setStroke()
    coreLine.stroke()

    // Helper: Draw a stylized Mac screen + stand
    func drawMac(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, isHost: Bool) {
        // Connector drop from stand down to bus
        let drop = NSBezierPath()
        drop.move(to: NSPoint(x: x, y: y - h * 0.15))
        drop.line(to: NSPoint(x: x, y: busY))
        drop.lineWidth = isHost ? A * 0.018 : A * 0.012
        (isHost ? NSColor(calibratedRed: 0.25, green: 0.70, blue: 1.0, alpha: 0.8) :
                  NSColor(calibratedRed: 0.20, green: 0.40, blue: 0.60, alpha: 0.5)).setStroke()
        drop.stroke()

        // Stand foot
        let footW = w * 0.36, footH = h * 0.08
        let footRect = NSRect(x: x - footW / 2, y: y - h * 0.15 - footH / 2, width: footW, height: footH)
        let foot = NSBezierPath(roundedRect: footRect, xRadius: footH * 0.4, yRadius: footH * 0.4)
        (isHost ? NSColor(calibratedWhite: 0.75, alpha: 0.9) : NSColor(calibratedWhite: 0.45, alpha: 0.7)).setFill()
        foot.fill()

        // Display body (bezel)
        let bodyRect = NSRect(x: x - w / 2, y: y - h / 2, width: w, height: h)
        let body = NSBezierPath(roundedRect: bodyRect, xRadius: w * 0.08, yRadius: w * 0.08)
        (isHost ? NSColor(calibratedWhite: 0.12, alpha: 0.95) : NSColor(calibratedWhite: 0.08, alpha: 0.85)).setFill()
        body.fill()
        (isHost ? NSColor(calibratedWhite: 0.85, alpha: 0.9) : NSColor(calibratedWhite: 0.50, alpha: 0.6)).setStroke()
        body.lineWidth = isHost ? A * 0.022 : A * 0.014
        body.stroke()

        // Glass screen inset
        let screenInsetX = w * 0.07, screenInsetY = h * 0.09
        let screenRect = bodyRect.insetBy(dx: screenInsetX, dy: screenInsetY)
        let screen = NSBezierPath(roundedRect: screenRect, xRadius: w * 0.04, yRadius: w * 0.04)

        ctx.saveGState()
        screen.addClip()
        if isHost {
            let sGrad = NSGradient(colors: [
                NSColor(calibratedRed: 0.08, green: 0.24, blue: 0.46, alpha: 1.0),
                NSColor(calibratedRed: 0.04, green: 0.12, blue: 0.26, alpha: 1.0)
            ])!
            sGrad.draw(in: screenRect, angle: -90)
        } else {
            let sGrad = NSGradient(colors: [
                NSColor(calibratedRed: 0.05, green: 0.14, blue: 0.26, alpha: 1.0),
                NSColor(calibratedRed: 0.02, green: 0.07, blue: 0.15, alpha: 1.0)
            ])!
            sGrad.draw(in: screenRect, angle: -90)
        }
        ctx.restoreGState()

        // Telemetry lines on screen (mimicking Machine Card data)
        let lineCount = isHost ? 3 : 2
        let lineStartX = screenRect.minX + screenRect.width * 0.15
        let lineW = screenRect.width * 0.70
        let spacing = screenRect.height / CGFloat(lineCount + 1)
        for i in 1...lineCount {
            let lineY = screenRect.maxY - CGFloat(i) * spacing
            let bar = NSBezierPath()
            bar.move(to: NSPoint(x: lineStartX, y: lineY))
            let fraction: CGFloat = (i == 1) ? 0.75 : ((i == 2) ? 0.50 : 0.85)
            bar.line(to: NSPoint(x: lineStartX + lineW * fraction, y: lineY))
            bar.lineWidth = isHost ? A * 0.016 : A * 0.011
            bar.lineCapStyle = .round
            if isHost && i == 1 {
                NSColor(calibratedRed: 0.20, green: 0.85, blue: 1.0, alpha: 0.9).setStroke()
            } else {
                NSColor(calibratedWhite: 1.0, alpha: isHost ? 0.45 : 0.25).setStroke()
            }
            bar.stroke()
        }
    }

    // Stepped-back peer Macs (Left & Right)
    let peerW = A * 0.32, peerH = A * 0.24
    let peerY = cy + A * 0.06
    drawMac(x: cx - A * 0.25, y: peerY, w: peerW, h: peerH, isHost: false)
    drawMac(x: cx + A * 0.25, y: peerY, w: peerW, h: peerH, isHost: false)

    // Center Host Mac (Front & larger)
    let hostW = A * 0.44, hostH = A * 0.33
    let hostY = cy - A * 0.01
    drawMac(x: cx, y: hostY, w: hostW, h: hostH, isHost: true)

    // Central Live Connection Beacon (Pulsing Emerald Green Dot on bus)
    let dotR = A * 0.038
    let dotCenter = NSPoint(x: cx, y: busY)

    // Glow halo
    let haloRect = NSRect(x: dotCenter.x - dotR * 2.2, y: dotCenter.y - dotR * 2.2,
                          width: dotR * 4.4, height: dotR * 4.4)
    let halo = NSGradient(colors: [
        NSColor(calibratedRed: 0.19, green: 0.82, blue: 0.35, alpha: 0.65),
        NSColor(calibratedRed: 0.19, green: 0.82, blue: 0.35, alpha: 0.0)
    ])!
    halo.draw(in: haloRect, relativeCenterPosition: .zero)

    // Green dot body
    let dot = NSBezierPath(ovalIn: NSRect(x: dotCenter.x - dotR, y: dotCenter.y - dotR, width: dotR * 2, height: dotR * 2))
    NSColor(calibratedRed: 0.19, green: 0.82, blue: 0.35, alpha: 1.0).setFill()
    dot.fill()
    NSColor.white.setStroke()
    dot.lineWidth = A * 0.008
    dot.stroke()

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let fm = FileManager.default
let scriptDir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent().path
let setDir = "\(scriptDir)/AppIcon.iconset"
let outIcns = "\(scriptDir)/AppIcon.icns"

try? fm.removeItem(atPath: setDir)
try! fm.createDirectory(atPath: setDir, withIntermediateDirectories: true)

// The sizes iconutil expects, including @2x variants.
let specs: [(name: String, px: CGFloat)] = [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024),
]

for s in specs {
    let rep = drawFleetIcon(size: s.px)
    let data = rep.representation(using: .png, properties: [:])!
    try! data.write(to: URL(fileURLWithPath: "\(setDir)/\(s.name)"))
}

// Compile .iconset to .icns using macOS iconutil
let proc = Process()
proc.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
proc.arguments = ["-c", "icns", setDir, "-o", outIcns]
try! proc.run()
proc.waitUntilExit()

try? fm.removeItem(atPath: setDir)
print("Successfully generated \(outIcns)")
