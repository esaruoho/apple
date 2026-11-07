// render-candidates.swift — renders 4 candidate icons for Fleet.app
// Follows wiki/concepts/macos-app-icon-sizing.md:
//   - 824x824 squircle on 1024x1024 canvas (inset 0.098, corner radius 0.2237 of shape)
//   - Drop contact shadow
//   - Scales geometry to inset art square A
// Run: xcrun swift fleet/render-candidates.swift

import AppKit
import Foundation

struct IconContext {
    let size: CGFloat
    let M: CGFloat
    let A: CGFloat
    let art: NSRect
    let cx: CGFloat
    let cy: CGFloat
    let rep: NSBitmapImageRep
    let ctx: CGContext

    init(size S: CGFloat) {
        self.size = S
        self.M = S * 0.098
        self.A = S - 2 * M
        self.art = NSRect(x: M, y: M, width: A, height: A)
        self.cx = art.midX
        self.cy = art.midY

        let px = Int(S)
        self.rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
                                   bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                   isPlanar: false, colorSpaceName: .deviceRGB,
                                   bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: self.rep)
        self.ctx = NSGraphicsContext.current!.cgContext
        self.ctx.setShouldAntialias(true)
    }

    func finish() -> Data {
        NSGraphicsContext.restoreGraphicsState()
        return rep.representation(using: .png, properties: [:])!
    }

    func drawBackground(colors: [NSColor], angle: CGFloat = -90) {
        // Drop contact shadow
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -A * 0.012), blur: A * 0.045,
                      color: NSColor(calibratedWhite: 0, alpha: 0.38).cgColor)
        let shadowPath = NSBezierPath(roundedRect: art, xRadius: A * 0.2237, yRadius: A * 0.2237)
        NSColor(calibratedWhite: 0.05, alpha: 1).setFill()
        shadowPath.fill()
        ctx.restoreGState()

        // Badge body
        let badge = NSBezierPath(roundedRect: art, xRadius: A * 0.2237, yRadius: A * 0.2237)
        badge.addClip()
        let grad = NSGradient(colors: colors)!
        grad.draw(in: art, angle: angle)

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
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// CANDIDATE A: Fleet Formation (3 Macs in formation on a shared network rail)
// ─────────────────────────────────────────────────────────────────────────────
func renderCandidateA(size S: CGFloat) -> Data {
    let ic = IconContext(size: S)
    let A = ic.A, cx = ic.cx, cy = ic.cy

    ic.drawBackground(colors: [
        NSColor(calibratedRed: 0.07, green: 0.12, blue: 0.22, alpha: 1.0),
        NSColor(calibratedRed: 0.03, green: 0.05, blue: 0.11, alpha: 1.0)
    ])

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

    return ic.finish()
}

// ─────────────────────────────────────────────────────────────────────────────
// CANDIDATE B: Connected Machine Cards (3 Side-by-Side Cards with Telemetry)
// ─────────────────────────────────────────────────────────────────────────────
func renderCandidateB(size S: CGFloat) -> Data {
    let ic = IconContext(size: S)
    let A = ic.A, cx = ic.cx, cy = ic.cy

    ic.drawBackground(colors: [
        NSColor(calibratedRed: 0.05, green: 0.15, blue: 0.32, alpha: 1.0),
        NSColor(calibratedRed: 0.02, green: 0.07, blue: 0.18, alpha: 1.0)
    ])

    // Three side-by-side cards (CardView layout)
    let cardW = A * 0.225
    let cardH = A * 0.46
    let cardRadius = A * 0.04
    let cardY = cy - A * 0.05

    let offsets: [CGFloat] = [-A * 0.26, 0.0, A * 0.26]
    for (idx, offX) in offsets.enumerated() {
        let isLocal = (idx == 1) // center is local
        let cX = cx + offX
        let rect = NSRect(x: cX - cardW / 2, y: cardY - cardH / 2 + (isLocal ? A * 0.03 : -A * 0.01),
                          width: cardW, height: cardH)

        // Card background
        let path = NSBezierPath(roundedRect: rect, xRadius: cardRadius, yRadius: cardRadius)
        if isLocal {
            NSColor(calibratedRed: 0.10, green: 0.22, blue: 0.42, alpha: 0.95).setFill()
        } else {
            NSColor(calibratedRed: 0.06, green: 0.14, blue: 0.28, alpha: 0.85).setFill()
        }
        path.fill()

        // Card border
        if isLocal {
            NSColor(calibratedRed: 0.30, green: 0.65, blue: 1.0, alpha: 0.95).setStroke()
            path.lineWidth = A * 0.022
        } else {
            NSColor(calibratedWhite: 1.0, alpha: 0.25).setStroke()
            path.lineWidth = A * 0.012
        }
        path.stroke()

        // Header bar inside card
        let hdrH = cardH * 0.18
        let hdrRect = NSRect(x: rect.minX, y: rect.maxY - hdrH, width: cardW, height: hdrH)
        let hdrPath = NSBezierPath(roundedRect: hdrRect, xRadius: cardRadius, yRadius: cardRadius)
        (isLocal ? NSColor(calibratedRed: 0.16, green: 0.35, blue: 0.65, alpha: 0.8) :
                   NSColor(calibratedWhite: 1.0, alpha: 0.08)).setFill()
        hdrPath.fill()

        // Card header icon dot (Green for local, blue/white for peers)
        let dotR = cardW * 0.10
        let dotOval = NSBezierPath(ovalIn: NSRect(x: rect.minX + cardW * 0.15, y: rect.maxY - hdrH * 0.5 - dotR / 2,
                                                 width: dotR, height: dotR))
        if isLocal {
            NSColor(calibratedRed: 0.19, green: 0.82, blue: 0.35, alpha: 1.0).setFill()
        } else {
            NSColor(calibratedWhite: 1.0, alpha: 0.50).setFill()
        }
        dotOval.fill()

        // Telemetry horizontal bars inside card
        let barStartX = rect.minX + cardW * 0.15
        let barMaxW = cardW * 0.70
        let barSpacing = (cardH - hdrH) / 5.0
        let fractions: [CGFloat] = isLocal ? [0.85, 0.45, 0.70, 0.60] : [0.55, 0.70, 0.40, 0.50]
        let barColors: [NSColor] = isLocal ? [
            NSColor(calibratedRed: 0.20, green: 0.85, blue: 1.0, alpha: 0.9),
            NSColor(calibratedRed: 0.19, green: 0.82, blue: 0.35, alpha: 0.9),
            NSColor(calibratedRed: 1.00, green: 0.60, blue: 0.20, alpha: 0.9),
            NSColor(calibratedWhite: 1.0, alpha: 0.4)
        ] : [
            NSColor(calibratedWhite: 1.0, alpha: 0.35),
            NSColor(calibratedWhite: 1.0, alpha: 0.30),
            NSColor(calibratedWhite: 1.0, alpha: 0.25),
            NSColor(calibratedWhite: 1.0, alpha: 0.20)
        ]

        for i in 0..<4 {
            let barY = rect.maxY - hdrH - CGFloat(i + 1) * barSpacing + A * 0.01
            let bar = NSBezierPath()
            bar.move(to: NSPoint(x: barStartX, y: barY))
            bar.line(to: NSPoint(x: barStartX + barMaxW * fractions[i], y: barY))
            bar.lineWidth = A * 0.015
            bar.lineCapStyle = .round
            barColors[i].setStroke()
            bar.stroke()
        }

        // Drop line from card bottom to rail
        let dropLine = NSBezierPath()
        dropLine.move(to: NSPoint(x: cX, y: rect.minY))
        dropLine.line(to: NSPoint(x: cX, y: cy - A * 0.25))
        dropLine.lineWidth = isLocal ? A * 0.016 : A * 0.010
        (isLocal ? NSColor(calibratedRed: 0.30, green: 0.65, blue: 1.0, alpha: 0.8) :
                   NSColor(calibratedWhite: 1.0, alpha: 0.3)).setStroke()
        dropLine.stroke()
    }

    // Common network rail connecting the cards
    let railY = cy - A * 0.25
    let railW = A * 0.68
    let rail = NSBezierPath()
    rail.move(to: NSPoint(x: cx - railW / 2, y: railY))
    rail.line(to: NSPoint(x: cx + railW / 2, y: railY))
    rail.lineWidth = A * 0.020
    rail.lineCapStyle = .round
    NSColor(calibratedRed: 0.25, green: 0.70, blue: 1.0, alpha: 0.85).setStroke()
    rail.stroke()

    // 3 connector node terminals on rail
    for offX in offsets {
        let nodeR = A * 0.025
        let node = NSBezierPath(ovalIn: NSRect(x: cx + offX - nodeR, y: railY - nodeR, width: nodeR * 2, height: nodeR * 2))
        if offX == 0.0 {
            NSColor(calibratedRed: 0.19, green: 0.82, blue: 0.35, alpha: 1.0).setFill()
        } else {
            NSColor(calibratedRed: 0.25, green: 0.70, blue: 1.0, alpha: 1.0).setFill()
        }
        node.fill()
        NSColor.white.setStroke()
        node.lineWidth = A * 0.006
        node.stroke()
    }

    return ic.finish()
}

// ─────────────────────────────────────────────────────────────────────────────
// CANDIDATE C: Canonical Header Symbol Elevation (Bold & Ultra-Legible)
// ─────────────────────────────────────────────────────────────────────────────
func renderCandidateC(size S: CGFloat) -> Data {
    let ic = IconContext(size: S)
    let A = ic.A, cx = ic.cx, cy = ic.cy

    ic.drawBackground(colors: [
        NSColor(calibratedRed: 0.08, green: 0.18, blue: 0.38, alpha: 1.0),
        NSColor(calibratedRed: 0.03, green: 0.08, blue: 0.20, alpha: 1.0)
    ])

    // Precision elevation of "rectangle.connected.to.line.below"
    let hostW = A * 0.54
    let hostH = A * 0.36
    let hostY = cy + A * 0.07

    // Host Display/Card
    let hostRect = NSRect(x: cx - hostW / 2, y: hostY - hostH / 2, width: hostW, height: hostH)
    let hostPath = NSBezierPath(roundedRect: hostRect, xRadius: A * 0.06, yRadius: A * 0.06)

    // Inner glass fill
    let hostGrad = NSGradient(colors: [
        NSColor(calibratedRed: 0.12, green: 0.28, blue: 0.54, alpha: 0.95),
        NSColor(calibratedRed: 0.06, green: 0.15, blue: 0.32, alpha: 0.95)
    ])!
    hostGrad.draw(in: hostRect, angle: -90)

    // Host outer stroke
    NSColor.white.setStroke()
    hostPath.lineWidth = A * 0.032
    hostPath.stroke()

    // Status dot in top-left of the host card
    let statusR = A * 0.032
    let statusCenter = NSPoint(x: hostRect.minX + A * 0.09, y: hostRect.maxY - A * 0.09)
    let statusDot = NSBezierPath(ovalIn: NSRect(x: statusCenter.x - statusR, y: statusCenter.y - statusR,
                                               width: statusR * 2, height: statusR * 2))
    NSColor(calibratedRed: 0.19, green: 0.82, blue: 0.35, alpha: 1.0).setFill()
    statusDot.fill()

    // Telemetry lines inside the host card
    let line1 = NSBezierPath()
    line1.move(to: NSPoint(x: statusCenter.x + A * 0.06, y: statusCenter.y))
    line1.line(to: NSPoint(x: hostRect.maxX - A * 0.09, y: statusCenter.y))
    line1.lineWidth = A * 0.018
    line1.lineCapStyle = .round
    NSColor(calibratedWhite: 1.0, alpha: 0.7).setStroke()
    line1.stroke()

    let line2 = NSBezierPath()
    line2.move(to: NSPoint(x: hostRect.minX + A * 0.09, y: hostRect.minY + A * 0.11))
    line2.line(to: NSPoint(x: hostRect.maxX - A * 0.14, y: hostRect.minY + A * 0.11))
    line2.lineWidth = A * 0.018
    line2.lineCapStyle = .round
    NSColor(calibratedRed: 0.20, green: 0.85, blue: 1.0, alpha: 0.85).setStroke()
    line2.stroke()

    // Central drop trunk connecting card down to bus
    let trunkY_bottom = cy - A * 0.20
    let trunk = NSBezierPath()
    trunk.move(to: NSPoint(x: cx, y: hostRect.minY))
    trunk.line(to: NSPoint(x: cx, y: trunkY_bottom))
    trunk.lineWidth = A * 0.032
    NSColor.white.setStroke()
    trunk.stroke()

    // Main horizontal network bus line
    let busW = A * 0.66
    let busLine = NSBezierPath()
    busLine.move(to: NSPoint(x: cx - busW / 2, y: trunkY_bottom))
    busLine.line(to: NSPoint(x: cx + busW / 2, y: trunkY_bottom))
    busLine.lineWidth = A * 0.032
    busLine.lineCapStyle = .round
    NSColor.white.setStroke()
    busLine.stroke()

    // Left & Right terminal drops (showing peer connections)
    let leftX = cx - busW * 0.38
    let rightX = cx + busW * 0.38
    let peerDropH = A * 0.08

    for pX in [leftX, rightX] {
        let pDrop = NSBezierPath()
        pDrop.move(to: NSPoint(x: pX, y: trunkY_bottom))
        pDrop.line(to: NSPoint(x: pX, y: trunkY_bottom - peerDropH))
        pDrop.lineWidth = A * 0.024
        pDrop.lineCapStyle = .round
        NSColor(calibratedWhite: 1.0, alpha: 0.8).setStroke()
        pDrop.stroke()

        // Terminal node disc
        let discR = A * 0.030
        let disc = NSBezierPath(ovalIn: NSRect(x: pX - discR, y: trunkY_bottom - peerDropH - discR,
                                              width: discR * 2, height: discR * 2))
        NSColor(calibratedRed: 0.20, green: 0.85, blue: 1.0, alpha: 1.0).setFill()
        disc.fill()
        NSColor.white.setStroke()
        disc.lineWidth = A * 0.008
        disc.stroke()
    }

    return ic.finish()
}

// ─────────────────────────────────────────────────────────────────────────────
// CANDIDATE D: Bonjour Radar / Active Discovery Mesh
// ─────────────────────────────────────────────────────────────────────────────
func renderCandidateD(size S: CGFloat) -> Data {
    let ic = IconContext(size: S)
    let A = ic.A, cx = ic.cx, cy = ic.cy

    ic.drawBackground(colors: [
        NSColor(calibratedRed: 0.04, green: 0.10, blue: 0.16, alpha: 1.0),
        NSColor(calibratedRed: 0.01, green: 0.04, blue: 0.08, alpha: 1.0)
    ])

    // Concentric discovery sonar rings radiating out
    let radii: [CGFloat] = [A * 0.16, A * 0.28, A * 0.40]
    for r in radii {
        let circle = NSBezierPath(ovalIn: NSRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
        NSColor(calibratedRed: 0.15, green: 0.65, blue: 0.85, alpha: 0.25).setStroke()
        circle.lineWidth = A * 0.012
        circle.stroke()
    }

    // 4 Cross-hair / mesh axis lines
    let axis = NSBezierPath()
    axis.move(to: NSPoint(x: cx - A * 0.42, y: cy))
    axis.line(to: NSPoint(x: cx + A * 0.42, y: cy))
    axis.move(to: NSPoint(x: cx, y: cy - A * 0.42))
    axis.line(to: NSPoint(x: cx, y: cy + A * 0.42))
    axis.lineWidth = A * 0.008
    NSColor(calibratedRed: 0.15, green: 0.65, blue: 0.85, alpha: 0.18).setStroke()
    axis.stroke()

    // Satellite peer nodes located on the rings
    let peers: [(angle: CGFloat, dist: CGFloat, isOnline: Bool)] = [
        (40.0,  radii[1], true),
        (140.0, radii[1], true),
        (225.0, radii[2], true),
        (315.0, radii[0], true)
    ]

    for p in peers {
        let rad = p.angle * .pi / 180.0
        let px = cx + cos(rad) * p.dist
        let py = cy + sin(rad) * p.dist

        // Connecting vector ray from center to peer
        let ray = NSBezierPath()
        ray.move(to: NSPoint(x: cx, y: cy))
        ray.line(to: NSPoint(x: px, y: py))
        ray.lineWidth = A * 0.010
        NSColor(calibratedRed: 0.20, green: 0.80, blue: 1.0, alpha: 0.45).setStroke()
        ray.stroke()

        // Satellite node icon (mini rounded card)
        let sW = A * 0.14, sH = A * 0.10
        let sRect = NSRect(x: px - sW / 2, y: py - sH / 2, width: sW, height: sH)
        let sCard = NSBezierPath(roundedRect: sRect, xRadius: sW * 0.15, yRadius: sW * 0.15)
        NSColor(calibratedRed: 0.08, green: 0.20, blue: 0.32, alpha: 0.95).setFill()
        sCard.fill()
        NSColor(calibratedRed: 0.20, green: 0.80, blue: 1.0, alpha: 0.90).setStroke()
        sCard.lineWidth = A * 0.014
        sCard.stroke()

        // Status beacon on satellite
        let beaconR = A * 0.020
        let beacon = NSBezierPath(ovalIn: NSRect(x: px - beaconR, y: py - beaconR, width: beaconR * 2, height: beaconR * 2))
        NSColor(calibratedRed: 0.19, green: 0.82, blue: 0.35, alpha: 1.0).setFill()
        beacon.fill()
    }

    // Central Host Mac Icon
    let cW = A * 0.28, cH = A * 0.20
    let cRect = NSRect(x: cx - cW / 2, y: cy - cH / 2, width: cW, height: cH)
    let cCard = NSBezierPath(roundedRect: cRect, xRadius: cW * 0.15, yRadius: cW * 0.15)
    NSColor(calibratedWhite: 0.10, alpha: 0.95).setFill()
    cCard.fill()
    NSColor.white.setStroke()
    cCard.lineWidth = A * 0.024
    cCard.stroke()

    // Host center screen
    let cScreenRect = cRect.insetBy(dx: cW * 0.10, dy: cH * 0.12)
    let cScreen = NSBezierPath(roundedRect: cScreenRect, xRadius: cW * 0.06, yRadius: cW * 0.06)
    let cGrad = NSGradient(colors: [
        NSColor(calibratedRed: 0.15, green: 0.45, blue: 0.85, alpha: 1.0),
        NSColor(calibratedRed: 0.05, green: 0.20, blue: 0.45, alpha: 1.0)
    ])!
    cGrad.draw(in: cScreenRect, angle: -90)

    // Center active beacon
    let cBeaconR = A * 0.028
    let cBeacon = NSBezierPath(ovalIn: NSRect(x: cx - cBeaconR, y: cy - cBeaconR, width: cBeaconR * 2, height: cBeaconR * 2))
    NSColor(calibratedRed: 0.19, green: 0.82, blue: 0.35, alpha: 1.0).setFill()
    cBeacon.fill()
    NSColor.white.setStroke()
    cBeacon.lineWidth = A * 0.006
    cBeacon.stroke()

    return ic.finish()
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN: Render all candidates at 512px and 128px
// ─────────────────────────────────────────────────────────────────────────────
let outDir = "fleet/preview"
let candidates: [(id: String, name: String, fn: (CGFloat) -> Data)] = [
    ("a", "candidate_a_fleet_formation", renderCandidateA),
    ("b", "candidate_b_machine_cards",  renderCandidateB),
    ("c", "candidate_c_header_symbol",  renderCandidateC),
    ("d", "candidate_d_bonjour_radar",  renderCandidateD),
]

for c in candidates {
    let d512 = c.fn(512)
    try! d512.write(to: URL(fileURLWithPath: "\(outDir)/\(c.name)_512.png"))

    let d128 = c.fn(128)
    try! d128.write(to: URL(fileURLWithPath: "\(outDir)/\(c.name)_128.png"))

    let d32 = c.fn(32)
    try! d32.write(to: URL(fileURLWithPath: "\(outDir)/\(c.name)_32.png"))

    let d16 = c.fn(16)
    try! d16.write(to: URL(fileURLWithPath: "\(outDir)/\(c.name)_16.png"))
    print("Rendered: \(c.name) (512, 128, 32, 16)")
}
print("Done rendering all 4 candidates!")
