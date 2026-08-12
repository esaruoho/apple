// Overlay — P0 of the spatial overlay (wiki/operations/spatial-overlay-plan.md).
//
// A transparent, click-through canvas floating over every window, one per screen per
// Space, that you flip into draw mode with ⌃⌥⌘D and out with Esc.
//
// The three things P0 has to get right, and how:
//
//   Click-through   `ignoresMouseEvents = true` by default. The overlay is invisible
//                   to the pointer, so the Mac stays completely usable with it up.
//                   Draw mode is the only state in which it eats input.
//
//   Spaces          NO private CGS/SkyLight API, no Space IDs. A canvas is an
//                   ordinary *managed* window created while you are in a Space, so
//                   macOS slides it away with that Space for free. `isOnActiveSpace`
//                   (public) is all we need to ask, and we never order a canvas
//                   forward that isn't already here — that would drag it across.
//
//   Data model      Strokes are OverlayObjects from OverlayCore, not view state. They
//                   carry actor, lifetime, anchor and a bounding box from day one, so
//                   P1 can hand an agent `object.cropRect(...)` without a rewrite.
//
// AppKit only — no SwiftUI scene, no Homebrew, no Electron. SwiftUI appears solely to
// host the shared Help panel, which every app in this repo ships.
//
// FEATURE-CARD >> overlay/overlay.feature

import Cocoa
import SwiftUI
import Carbon.HIToolbox   // RegisterEventHotKey — global hotkey, needs no permission

// ─────────────────────────────── the panel ───────────────────────────────

/// Borderless, and able to take the keyboard.
///
/// A borderless window refuses key status unless you override this; without it Esc
/// and ⌘Z never arrive and draw mode is a one-way door. That is not hypothetical —
/// it is the bug Esa hit on the first real run.
final class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    /// Never main: this must not present itself as the app's primary window, or the
    /// window menu and Cmd-Tab start treating a transparent sheet of glass as a doc.
    override var canBecomeMain: Bool { false }
}

// ─────────────────────────────── the canvas view ───────────────────────────────

final class InkView: NSView {

    let store = OverlayStore()
    weak var manager: OverlayManager?

    /// The stroke currently under the pointer. Kept out of the store until mouseUp so
    /// an in-progress drag can never be undone, saved, or shipped to an agent.
    private var live: [CGPoint] = []

    /// What a drag does. `.region` — the default — selects a rectangle, because the
    /// primary gesture of this app is "this bit", not "draw me a picture". `f`
    /// switches to freehand ink.
    enum Tool { case region, ink }
    /// The pen is the default: "draw a cube and get a cube" is the headline, and a
    /// marquee is the secondary gesture for asking about part of the screen (`r`).
    var tool: Tool = .ink

    /// The last selected rectangle, and the on-screen buttons acting on it. Buttons
    /// are painted by draw() and hit-tested by mouseDown, so they are always where
    /// they look like they are.
    var askableRegion: CGRect?
    var askButtonRect: CGRect?
    var makeButtonRect: CGRect?
    var chatButtonRect: CGRect?
    /// A ✕ hit target per object, so anything on screen can be thrown away by
    /// clicking it. Rebuilt on every draw so it always matches what is painted.
    var dismissTargets: [(rect: CGRect, id: String)] = []

    /// Where each object's chip was actually painted this frame. A callout's
    /// `points` are its target and its anchor — NOT the box the text ended up in —
    /// so placing the ✕ from the raw points dropped it right on top of the words.
    var paintedRects: [String: CGRect] = [:]

    /// Pointer position, for hover. Without it the ✕ gave no feedback at all: the
    /// crosshair stayed a crosshair and nothing lit up, so there was no way to tell
    /// it was a control.
    var hoverPoint: CGPoint?

    /// Strokes currently being rendered by Image Playground. They pulse in place —
    /// "I am working on THIS" — which is what a sketch turning into a picture should
    /// look like. It replaced a text bubble saying "rendering your drawing…", which
    /// told you nothing about which drawing and looked like more clutter.
    var renderingIDs: Set<String> = [] {
        didSet { syncPulse() }
    }
    private var pulseTimer: Timer?
    private var pulsePhase: CGFloat = 0

    private func syncPulse() {
        if renderingIDs.isEmpty {
            pulseTimer?.invalidate(); pulseTimer = nil; pulsePhase = 0
            needsDisplay = true
            return
        }
        guard pulseTimer == nil else { return }
        // 20fps is plenty for a breathing opacity and costs nothing measurable.
        pulseTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) {
            [weak self] _ in
            guard let self = self else { return }
            self.pulsePhase += 0.05
            for o in self.store.objects where self.renderingIDs.contains(o.id) {
                self.setNeedsDisplay(o.bounds.insetBy(dx: -CGFloat(o.width) - 4,
                                                      dy: -CGFloat(o.width) - 4))
            }
        }
    }

    /// 0.25…1.0, a smooth breath rather than a blink.
    private var pulseAlpha: CGFloat {
        0.25 + 0.75 * (0.5 + 0.5 * sin(pulsePhase * 3.0))
    }

    var colorHex = Hex.palette[0]
    var strokeWidth: Double = 3
    var displayName = ""

    var mode: OverlayMode = .passthrough {
        didSet {
            guard mode != oldValue else { return }
            // Dropping the live stroke on a mode flip prevents a half-drawn line
            // being stranded on screen when you hit Esc mid-drag.
            live = []
            // Leaving draw mode must take the offer with it. Esa hit esc, went back
            // to his app, and was still being asked whether to render a blank space.
            askableRegion = nil
            askButtonRect = nil
            makeButtonRect = nil
            chatButtonRect = nil
            needsDisplay = true
            if mode == .draw { NSCursor.crosshair.set() } else { NSCursor.arrow.set() }
        }
    }

    override var acceptsFirstResponder: Bool { mode == .draw }
    override var isOpaque: Bool { false }

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
    }
    required init?(coder: NSCoder) { fatalError("not used") }

    // ── drawing ──

    override func draw(_ dirtyRect: NSRect) {
        NSGraphicsContext.current?.cgContext.setShouldAntialias(true)
        // Filled as objects paint themselves; read afterwards to place the ✕ badges.
        paintedRects.removeAll(keepingCapacity: true)

        // Spotlights dim everything outside themselves, so they are painted first and
        // always in full — a spotlight clipped to a dirty rect would leave a bright
        // rectangle where the previous frame's dimming used to be.
        let spotlights = store.objects.filter { $0.kind == .spotlight }
        if !spotlights.isEmpty {
            for s in spotlights { render(s) }
        }

        for object in store.objects where object.kind != .spotlight {
            // Only paint what intersects the invalidated rect. Without this, every
            // mouse-drag sample would re-stroke the entire canvas.
            let box = paintedBounds(of: object)
            guard box.isNull || box.intersects(dirtyRect) else { continue }
            render(object)
        }

        if !live.isEmpty {
            if tool == .region, live.count >= 2 {
                drawMarquee(Geometry.bounds([live[0], live[live.count - 1]]))
            } else {
                stroke(points: live, hex: colorHex, width: strokeWidth)
            }
        }

        // The action buttons live above everything, including the mode chrome.
        askButtonRect = nil; makeButtonRect = nil; chatButtonRect = nil
        dismissTargets = []
        if mode == .draw {
            // Everything that is not raw ink gets a ✕. Esa had a screen full of
            // generated images and callouts with no way to remove any of them.
            for o in store.objects where o.kind != .ink && o.kind != .line {
                drawDismissBadge(for: o)
            }
            if let region = askableRegion { drawRegionActions(for: region) }
        }

        if mode == .draw { drawModeChrome() }
    }

    /// The live selection rectangle: dashed, so it reads as "I am choosing a region"
    /// rather than "I am drawing a rectangle you will have to erase".
    private func drawMarquee(_ rect: CGRect) {
        color(colorHex).withAlphaComponent(0.12).setFill()
        NSBezierPath(rect: rect).fill()
        let path = NSBezierPath(rect: rect)
        path.lineWidth = 2
        path.setLineDash([6, 4], count: 2, phase: 0)
        color(colorHex).setStroke()
        path.stroke()

        let size = "\(Int(rect.width)) × \(Int(rect.height))"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .medium),
            .foregroundColor: NSColor.white]
        let measured = (size as NSString).size(withAttributes: attrs)
        let tag = CGRect(x: rect.minX, y: rect.maxY + 4,
                         width: measured.width + 12, height: measured.height + 6)
        NSColor.black.withAlphaComponent(0.75).setFill()
        NSBezierPath(roundedRect: tag, xRadius: 4, yRadius: 4).fill()
        (size as NSString).draw(at: CGPoint(x: tag.minX + 6, y: tag.minY + 3),
                                withAttributes: attrs)
    }

    /// The two things you can do with a selected region, as real clickable buttons.
    ///
    /// Both were keystrokes before, with nothing on screen to suggest they existed —
    /// Esa selected a region and reasonably concluded nothing could happen next.
    ///
    ///   Ask about this   crop → Vision OCR → FoundationModels → answer at the region
    ///   Make an image    crop → prompt → Image Playground → picture INTO the region
    /// A ✕ in the corner of an object. Only in draw mode — in passthrough the
    /// overlay must not offer anything to click.
    private func drawDismissBadge(for o: OverlayObject) {
        // Use where the object was actually PAINTED. A callout's points are its
        // target and its anchor, not the box the text landed in, so deriving the
        // badge from them put the ✕ straight on top of the words.
        let box = paintedRects[o.id] ?? (o.kind.isRectangular ? o.rect : o.bounds)
        guard box.width > 1, box.height > 1 else { return }

        let size: CGFloat = 20
        // Sits just OUTSIDE the corner, overlapping only its own rounding — it
        // never covers content.
        var badge = CGRect(x: box.maxX - size * 0.35, y: box.maxY - size * 0.35,
                           width: size, height: size)
        badge.origin.x = min(max(2, badge.origin.x), bounds.maxX - size - 2)
        badge.origin.y = min(max(2, badge.origin.y), bounds.maxY - size - 2)

        let hot = hoverPoint.map { badge.insetBy(dx: -4, dy: -4).contains($0) } ?? false

        // A shadow separates it from whatever is underneath, which is the whole
        // reason it reads as a control rather than a drawn dot.
        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.5)
        shadow.shadowBlurRadius = hot ? 7 : 4
        shadow.shadowOffset = NSSize(width: 0, height: -1)
        shadow.set()
        (hot ? NSColor(srgbRed: 0.95, green: 0.26, blue: 0.21, alpha: 1)
             : NSColor(srgbRed: 0.17, green: 0.17, blue: 0.19, alpha: 0.96)).setFill()
        NSBezierPath(ovalIn: hot ? badge.insetBy(dx: -2, dy: -2) : badge).fill()
        NSGraphicsContext.restoreGraphicsState()

        let ring = NSBezierPath(ovalIn: hot ? badge.insetBy(dx: -2, dy: -2) : badge)
        ring.lineWidth = 1
        NSColor.white.withAlphaComponent(hot ? 0.9 : 0.45).setStroke()
        ring.stroke()

        let target = hot ? badge.insetBy(dx: -2, dy: -2) : badge
        let cross = NSBezierPath()
        let inset: CGFloat = hot ? 7.5 : 6.5
        cross.move(to: CGPoint(x: target.minX + inset, y: target.minY + inset))
        cross.line(to: CGPoint(x: target.maxX - inset, y: target.maxY - inset))
        cross.move(to: CGPoint(x: target.minX + inset, y: target.maxY - inset))
        cross.line(to: CGPoint(x: target.maxX - inset, y: target.minY + inset))
        cross.lineWidth = 2
        cross.lineCapStyle = .round
        NSColor.white.setStroke()
        cross.stroke()

        // Generous hit area: a 20pt circle is a small target for a crosshair.
        dismissTargets.append((badge.insetBy(dx: -6, dy: -6), o.id))
    }

    private func drawRegionActions(for region: CGRect) {
        // Plain verbs. "Ask about this" told Esa nothing about what it would do —
        // he asked outright what he could turn into text. Now the button says so.
        let titles = ["Ask…  ⌘T",
                      "Read text here  ⌘⏎",
                      tool == .ink ? "Render drawing  ⌥⏎" : "Make image here  ⌥⏎"]
        let font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        let attrs: [NSAttributedString.Key: Any] = [.font: font,
                                                    .foregroundColor: NSColor.white]
        let sizes = titles.map { ($0 as NSString).size(withAttributes: attrs) }
        let widths = sizes.map { $0.width + 26 }
        let height = sizes[0].height + 14
        let gap: CGFloat = 8
        let total = widths.reduce(0, +) + gap

        // Prefer just below the region; flip above if that would fall off screen.
        var y = region.minY - height - 8
        if y < 8 { y = min(bounds.maxY - height - 8, region.maxY + 8) }
        var x = min(max(8, region.midX - total / 2), bounds.maxX - total - 8)

        let fills = [NSColor(srgbRed: 0.13, green: 0.68, blue: 0.35, alpha: 0.97),
                     NSColor(srgbRed: 0.04, green: 0.52, blue: 1.0, alpha: 0.97),
                     NSColor(srgbRed: 0.68, green: 0.32, blue: 0.87, alpha: 0.97)]
        for (index, title) in titles.enumerated() {
            let button = CGRect(x: x, y: y, width: widths[index], height: height)
            let hot = hoverPoint.map { button.contains($0) } ?? false

            NSGraphicsContext.saveGraphicsState()
            let shadow = NSShadow()
            shadow.shadowColor = NSColor.black.withAlphaComponent(hot ? 0.55 : 0.35)
            shadow.shadowBlurRadius = hot ? 10 : 5
            shadow.shadowOffset = NSSize(width: 0, height: -2)
            shadow.set()
            (hot ? fills[index].blended(withFraction: 0.18, of: .white) ?? fills[index]
                 : fills[index]).setFill()
            NSBezierPath(roundedRect: button, xRadius: 9, yRadius: 9).fill()
            NSGraphicsContext.restoreGraphicsState()

            let edge = NSBezierPath(roundedRect: button, xRadius: 9, yRadius: 9)
            edge.lineWidth = 1
            NSColor.white.withAlphaComponent(hot ? 0.75 : 0.3).setStroke()
            edge.stroke()
            (title as NSString).draw(at: CGPoint(x: button.minX + 13, y: button.minY + 7),
                                     withAttributes: attrs)
            switch index {
            case 0: chatButtonRect = button
            case 1: askButtonRect = button
            default: makeButtonRect = button
            }
            x += widths[index] + gap
        }
    }

    /// How much of the canvas an object actually covers, including its stroke width
    /// and any chip that hangs off its geometry.
    private func paintedBounds(of object: OverlayObject) -> CGRect {
        let slack = CGFloat(object.width) + 4
        switch object.kind {
        case .label, .callout, .sticker:
            // Text extends well past the anchor point; be generous rather than
            // compute the layout twice.
            return object.bounds.insetBy(dx: -400, dy: -80)
        default:
            return object.bounds.insetBy(dx: -slack, dy: -slack)
        }
    }

    // ── the object vocabulary ──

    private func render(_ o: OverlayObject) {
        switch o.kind {
        case .ink, .line:
            stroke(points: o.points, hex: o.colorHex, width: o.width,
                   alpha: renderingIDs.contains(o.id) ? pulseAlpha : 1)

        case .arrow:
            guard o.points.count >= 2 else { return }
            drawArrow(from: o.points[0], to: o.points[1], hex: o.colorHex, width: o.width)

        case .box:
            let path = NSBezierPath(roundedRect: o.rect, xRadius: 4, yRadius: 4)
            path.lineWidth = CGFloat(o.width)
            color(o.colorHex).setStroke()
            path.stroke()

        case .highlight:
            // A marker pen, not a paint bucket: translucent enough to read through.
            color(o.colorHex).withAlphaComponent(0.3).setFill()
            NSBezierPath(roundedRect: o.rect, xRadius: 3, yRadius: 3).fill()

        case .spotlight:
            // Even-odd fill of (whole canvas + the hole) dims everything outside.
            let path = NSBezierPath(rect: bounds)
            path.append(NSBezierPath(roundedRect: o.rect, xRadius: 6, yRadius: 6))
            path.windingRule = .evenOdd
            NSColor.black.withAlphaComponent(0.55).setFill()
            path.fill()
            let ring = NSBezierPath(roundedRect: o.rect, xRadius: 6, yRadius: 6)
            ring.lineWidth = CGFloat(o.width)
            color(o.colorHex).setStroke()
            ring.stroke()

        case .label:
            guard let p = o.points.first else { return }
            paintedRects[o.id] = drawChip(o.text ?? "", at: p, hex: o.colorHex,
                                          actor: o.actor, centred: true)

        case .callout:
            guard o.points.count >= 2 else { return }
            let target = o.points[0], chip = o.points[1]
            let leader = NSBezierPath()
            leader.move(to: chip)
            leader.line(to: target)
            leader.lineWidth = max(1, CGFloat(o.width) - 1)
            color(o.colorHex).withAlphaComponent(0.85).setStroke()
            leader.stroke()
            // A dot on the thing being talked about, so the reference is unambiguous.
            color(o.colorHex).setFill()
            let r = max(3, CGFloat(o.width))
            NSBezierPath(ovalIn: CGRect(x: target.x - r, y: target.y - r,
                                        width: r * 2, height: r * 2)).fill()
            paintedRects[o.id] = drawChip(o.text ?? "", at: chip, hex: o.colorHex,
                                          actor: o.actor, centred: true)

        case .image:
            // The generated picture, drawn INTO the box that asked for it.
            guard let path = o.imagePath, let img = NSImage(contentsOfFile: path) else {
                // Never leave a silent empty frame: say the file is missing.
                color(o.colorHex).setStroke()
                let missing = NSBezierPath(roundedRect: o.rect, xRadius: 6, yRadius: 6)
                missing.lineWidth = 2
                missing.setLineDash([5, 4], count: 2, phase: 0)
                missing.stroke()
                drawChip("image missing", at: CGPoint(x: o.rect.midX, y: o.rect.midY),
                         hex: o.colorHex, actor: o.actor, centred: true)
                return
            }
            // Aspect-fit inside the rect so a square generation is not stretched.
            let scale = min(o.rect.width / img.size.width, o.rect.height / img.size.height)
            let size = NSSize(width: img.size.width * scale, height: img.size.height * scale)
            let frame = CGRect(x: o.rect.midX - size.width / 2,
                               y: o.rect.midY - size.height / 2,
                               width: size.width, height: size.height)
            NSColor.black.withAlphaComponent(0.35).setFill()
            NSBezierPath(roundedRect: frame.insetBy(dx: -3, dy: -3),
                         xRadius: 8, yRadius: 8).fill()
            img.draw(in: frame)
            paintedRects[o.id] = frame
            let edge = NSBezierPath(roundedRect: frame, xRadius: 5, yRadius: 5)
            edge.lineWidth = 2
            color(o.colorHex).setStroke()
            edge.stroke()

        case .sticker:
            guard let p = o.points.first, let text = o.text else { return }
            let size = max(18, CGFloat(o.width) * 8)
            let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: size)]
            let measured = (text as NSString).size(withAttributes: attrs)
            (text as NSString).draw(at: CGPoint(x: p.x - measured.width / 2,
                                                y: p.y - measured.height / 2),
                                    withAttributes: attrs)
        }
    }

    private func drawArrow(from tail: CGPoint, to head: CGPoint, hex: String, width: Double) {
        let w = CGFloat(width)
        let angle = atan2(head.y - tail.y, head.x - tail.x)
        let headLength = max(10, w * 4)

        // Stop the shaft short of the tip so the line doesn't poke through the head.
        let stop = CGPoint(x: head.x - cos(angle) * headLength * 0.8,
                           y: head.y - sin(angle) * headLength * 0.8)
        let shaft = NSBezierPath()
        shaft.move(to: tail)
        shaft.line(to: stop)
        shaft.lineWidth = w
        shaft.lineCapStyle = .round
        color(hex).setStroke()
        shaft.stroke()

        let spread = CGFloat.pi / 7
        let barb = NSBezierPath()
        barb.move(to: head)
        barb.line(to: CGPoint(x: head.x - cos(angle - spread) * headLength,
                              y: head.y - sin(angle - spread) * headLength))
        barb.line(to: CGPoint(x: head.x - cos(angle + spread) * headLength,
                              y: head.y - sin(angle + spread) * headLength))
        barb.close()
        color(hex).setFill()
        barb.fill()
    }

    /// A text chip. Agent provenance rides along as a small tag rather than a colour
    /// convention, so several agents can annotate at once without a colour war.
    /// A text chip that WRAPS and stays on screen.
    ///
    /// The first version measured the text on one line and made the chip that wide,
    /// so a model answer ran straight off the edge of the display and was clipped
    /// mid-word. Text is now laid out to a maximum width, the height follows the
    /// wrapped text, and the whole chip is clamped inside the canvas.
    ///
    /// Agent provenance rides along as a small tag rather than a colour convention,
    /// so several agents can annotate at once without a colour war.
    @discardableResult
    private func drawChip(_ text: String, at p: CGPoint, hex: String,
                          actor: String, centred: Bool) -> CGRect {
        guard !text.isEmpty else { return .null }

        let maxWidth: CGFloat = min(420, max(180, bounds.width - 80))
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        let font = NSFont.systemFont(ofSize: 13, weight: .medium)
        let attrs: [NSAttributedString.Key: Any] = [.font: font,
                                                    .foregroundColor: NSColor.white,
                                                    .paragraphStyle: paragraph]
        let body = NSAttributedString(string: text, attributes: attrs)
        let bodyBox = body.boundingRect(
            with: NSSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading])

        let showActor = !actor.hasPrefix("human:")
        let tagFont = NSFont.monospacedSystemFont(ofSize: 9, weight: .regular)
        let tagAttrs: [NSAttributedString.Key: Any] = [
            .font: tagFont, .foregroundColor: NSColor.white.withAlphaComponent(0.65)]
        let tagSize = showActor
            ? (actor as NSString).size(withAttributes: tagAttrs) : NSSize.zero

        let width = max(bodyBox.width, tagSize.width) + 22
        let height = bodyBox.height + (showActor ? tagSize.height + 3 : 0) + 14

        var x = centred ? p.x - width / 2 : p.x
        var y = p.y - height / 2
        // Clamp into the canvas so nothing is ever painted off the edge.
        x = min(max(6, x), max(6, bounds.maxX - width - 6))
        y = min(max(6, y), max(6, bounds.maxY - height - 6))
        let chip = CGRect(x: x, y: y, width: width, height: height)

        color(hex).withAlphaComponent(0.94).setFill()
        NSBezierPath(roundedRect: chip, xRadius: 7, yRadius: 7).fill()

        var textY = chip.minY + 7
        if showActor {
            (actor as NSString).draw(at: CGPoint(x: chip.minX + 11, y: textY),
                                     withAttributes: tagAttrs)
            textY += tagSize.height + 3
        }
        body.draw(with: CGRect(x: chip.minX + 11, y: textY,
                               width: maxWidth, height: bodyBox.height),
                  options: [.usesLineFragmentOrigin, .usesFontLeading])
        return chip
    }

    private func stroke(points: [CGPoint], hex: String, width: Double,
                        alpha: CGFloat = 1) {
        guard points.count > 1 else {
            // A single-point stroke is a dot — a zero-length NSBezierPath paints
            // nothing at all, so it gets an explicit disc instead.
            if let p = points.first {
                color(hex).setFill()
                let r = CGFloat(width) / 2
                NSBezierPath(ovalIn: CGRect(x: p.x - r, y: p.y - r,
                                            width: r * 2, height: r * 2)).fill()
            }
            return
        }
        let path = NSBezierPath()
        path.lineWidth = CGFloat(width)
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.move(to: points[0])
        for p in points.dropFirst() { path.line(to: p) }
        color(hex).withAlphaComponent(alpha).setStroke()
        path.stroke()
    }

    private func color(_ hex: String) -> NSColor {
        guard let c = Hex.parse(hex) else { return .systemRed }
        return NSColor(srgbRed: c.r, green: c.g, blue: c.b, alpha: c.a)
    }

    /// The part of the canvas that is not underneath the menu bar or the Dock.
    ///
    /// The first version of the mode indicator drew a 3pt border at the screen's
    /// extreme edges and a chip 18pt off the bottom — i.e. exactly under the menu bar
    /// (level 24) and the Dock (level 20), both of which sit above .floating. Esa saw
    /// nothing at all and reasonably concluded draw mode had not turned on.
    private var unobscured: CGRect {
        guard let screen = window?.screen else { return bounds }
        return CGRect(x: screen.visibleFrame.minX - screen.frame.minX,
                      y: screen.visibleFrame.minY - screen.frame.minY,
                      width: screen.visibleFrame.width,
                      height: screen.visibleFrame.height)
    }

    /// Draw mode has to be unmistakable — an overlay that silently eats your clicks
    /// is indistinguishable from a frozen Mac.
    private func drawModeChrome() {
        let area = unobscured

        let border = NSBezierPath(rect: area.insetBy(dx: 3, dy: 3))
        border.lineWidth = 6
        color(colorHex).withAlphaComponent(0.9).setStroke()
        border.stroke()

        let text = tool == .region
            ? "REGION  ·  drag a box over anything  →  Read text here  ·  f = pen  ·  Ask… types a question  ·  ✕ removes  ·  esc = clear + exit"
            : "PEN  ·  sketch, then Render drawing  ·  r = box a screen area  ·  Ask… types a question  ·  ✕ removes  ·  esc = clear + exit"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: NSColor.white,
        ]
        let size = (text as NSString).size(withAttributes: attrs)
        let swatchWidth: CGFloat = 44
        let chip = CGRect(x: area.midX - (size.width + swatchWidth + 34) / 2,
                          // BOTTOM, not top. At the top it sat on the menu bar and
                          // covered AppleToolbox — the status readout hid the thing
                          // it was reporting about.
                          y: area.minY + 14,
                          width: size.width + swatchWidth + 34,
                          height: size.height + 14)
        color(colorHex).withAlphaComponent(0.95).setFill()
        NSBezierPath(roundedRect: chip, xRadius: 9, yRadius: 9).fill()
        (text as NSString).draw(at: CGPoint(x: chip.minX + 12, y: chip.minY + 7),
                                withAttributes: attrs)

        // The live colour and width, shown as an actual swatch rather than a number.
        let swatch = CGRect(x: chip.maxX - swatchWidth - 12,
                            y: chip.midY - CGFloat(strokeWidth) / 2,
                            width: swatchWidth, height: max(2, CGFloat(strokeWidth)))
        NSColor.white.setFill()
        NSBezierPath(roundedRect: swatch,
                     xRadius: CGFloat(strokeWidth) / 2,
                     yRadius: CGFloat(strokeWidth) / 2).fill()
    }

    /// Cursor rects only apply to a KEY window, and this panel may not be key on
    /// every macOS configuration. A tracking area with .activeAlways works either
    /// way, so the crosshair is not hostage to activation succeeding.
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas { removeTrackingArea(area) }
        addTrackingArea(NSTrackingArea(rect: bounds,
                                       options: [.mouseEnteredAndExited, .mouseMoved,
                                                 .activeAlways, .inVisibleRect],
                                       owner: self, userInfo: nil))
    }

    override func mouseEntered(with event: NSEvent) { track(event) }
    override func mouseMoved(with event: NSEvent) { track(event) }
    override func mouseExited(with event: NSEvent) {
        hoverPoint = nil
        NSCursor.arrow.set()
        needsDisplay = true
    }

    private func track(_ event: NSEvent) {
        guard mode == .draw else { hoverPoint = nil; return }
        let p = convert(event.locationInWindow, from: nil)
        let wasOver = overControl(hoverPoint)
        hoverPoint = p
        let isOver = overControl(p)
        // A crosshair over a close button told Esa nothing. Controls get the
        // pointing hand, and the control under the pointer lights up.
        (isOver ? NSCursor.pointingHand : NSCursor.crosshair).set()
        if wasOver != isOver || isOver { needsDisplay = true }
    }

    /// Is `p` over something clickable? Shared by the cursor and the hover paint so
    /// they can never disagree about where the controls are.
    private func overControl(_ p: CGPoint?) -> Bool {
        guard let p = p else { return false }
        if dismissTargets.contains(where: { $0.rect.contains(p) }) { return true }
        if let r = askButtonRect, r.contains(p) { return true }
        if let r = makeButtonRect, r.contains(p) { return true }
        if let r = chatButtonRect, r.contains(p) { return true }
        return false
    }

    // ── pointer ──

    override func mouseDown(with event: NSEvent) {
        guard mode == .draw else { return }
        let p = convert(event.locationInWindow, from: nil)

        // The Ask button is part of the canvas, so a click on it must be caught here
        // before it is mistaken for the start of a new drag.
        // A ✕ wins over everything: getting rid of something must never be
        // outcompeted by an action button sitting near it.
        if let hit = dismissTargets.first(where: { $0.rect.contains(p) }) {
            store.remove(id: hit.id)
            askableRegion = nil
            needsDisplay = true
            manager?.persist()
            return
        }
        if let button = chatButtonRect, button.contains(p) {
            manager?.openChat(for: askableRegion)
            needsDisplay = true
            return
        }
        if let button = askButtonRect, button.contains(p) {
            manager?.askLastRegion()
            askableRegion = nil
            needsDisplay = true
            return
        }
        if let button = makeButtonRect, button.contains(p) {
            manager?.imagineLastRegion()
            askableRegion = nil
            needsDisplay = true
            return
        }

        live = [p]
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard mode == .draw, !live.isEmpty else { return }
        let p = convert(event.locationInWindow, from: nil)

        if tool == .region {
            // A marquee is defined by two corners, so the live shape is start→now and
            // the whole previous rectangle has to be repainted, not just a segment.
            let old = Geometry.bounds([live[0], live[live.count - 1]])
            live = [live[0], p]
            let new = Geometry.bounds([live[0], p])
            setNeedsDisplay(old.union(new).insetBy(dx: -8, dy: -8))
            return
        }

        let previous = live[live.count - 1]
        live.append(p)
        // Invalidate just the segment that appeared, padded for line width and caps.
        let pad = CGFloat(strokeWidth) + 4
        setNeedsDisplay(Geometry.bounds([previous, p]).insetBy(dx: -pad, dy: -pad))
    }

    override func mouseUp(with event: NSEvent) {
        guard mode == .draw, !live.isEmpty else { return }
        let drawn = live
        live = []

        let object: OverlayObject
        if tool == .region {
            let rect = Geometry.bounds([drawn[0], drawn[drawn.count - 1]])
            // A click, not a drag. Don't leave a degenerate 0x0 box behind.
            guard rect.width > 12, rect.height > 12 else {
                needsDisplay = true
                return
            }
            object = OverlayObject(kind: .box,
                                   points: [rect.origin,
                                            CGPoint(x: rect.maxX, y: rect.maxY)],
                                   colorHex: colorHex, width: strokeWidth,
                                   actor: "human:esa", lifetime: .persistent,
                                   anchor: OverlayAnchor(type: .screen, display: displayName))
        } else {
            // NO shape snapping. It was added so "draw a square" would work with
            // the pen, and it promptly turned Esa's cross into a square — silently
            // destroying the thing he actually drew. A drawing tool that edits your
            // drawing is not a drawing tool. ShapeDetect stays available for
            // measuring a region; it no longer rewrites ink.
            object = OverlayObject(points: Geometry.decimate(drawn, minDistance: 1.5),
                                   colorHex: colorHex, width: strokeWidth,
                                   actor: "human:esa", lifetime: .persistent,
                                   anchor: OverlayAnchor(type: .screen, display: displayName))
        }

        store.add(object)
        // Buttons appear the moment you let go — for a marquee, over the marquee; for
        // ink, over the WHOLE drawing so far, because a cube is several strokes and
        // the action applies to the drawing, not to the last line of it.
        if object.kind == .box {
            askableRegion = object.rect
        } else {
            var box = CGRect.null
            for o in store.objects where o.kind == .ink || o.kind == .line {
                box = box.isNull ? o.bounds : box.union(o.bounds)
            }
            askableRegion = box.isNull ? nil : box.insetBy(dx: -12, dy: -12)
        }
        needsDisplay = true
        manager?.persist()
    }

    // ── keyboard ──

    override func keyDown(with event: NSEvent) {
        let cmd = event.modifierFlags.contains(.command)
        let shift = event.modifierFlags.contains(.shift)

        switch Int(event.keyCode) {
        case kVK_Escape:
            // Esc wipes the canvas as well as leaving draw mode. Esa pressed it
            // repeatedly expecting a clean screen and kept getting a screen still
            // full of marks. Nothing is lost — everything is mirrored to
            // ~/.overlay/store/session.json.
            manager?.clearScratchHere()
            manager?.setMode(.passthrough)
            return
        case kVK_ANSI_Z where cmd:
            _ = shift ? store.redo() : store.undo()
            needsDisplay = true
            manager?.persist()
            return
        case kVK_Delete where cmd:
            store.clear()
            needsDisplay = true
            manager?.persist()
            return
        default:
            break
        }

        switch event.charactersIgnoringModifiers {
        case let c? where !cmd && "123456".contains(c) && c.count == 1:
            let index = Int(c)! - 1
            colorHex = Hex.palette[index]
            needsDisplay = true
        case "["?:
            strokeWidth = max(1, strokeWidth - 1); needsDisplay = true
        case "]"?:
            strokeWidth = min(48, strokeWidth + 1); needsDisplay = true
        default:
            super.keyDown(with: event)
        }
    }
}

// ─────────────────────────────── one canvas ───────────────────────────────

/// A canvas is a panel + its view, bound to one display and (implicitly) to whatever
/// Space it was born in. There is no Space identifier anywhere in this type, on
/// purpose — see the header note.
final class Canvas {
    let panel: OverlayPanel
    let view: InkView
    let displayID: CGDirectDisplayID
    let displayName: String

    init(screen: NSScreen, manager: OverlayManager) {
        displayID = (screen.deviceDescription[
            NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
        displayName = screen.localizedName

        // NOT .nonactivatingPanel. It reads like the polite choice, and it is a trap:
        // on an .accessory app it makes NSApp.activate a no-op, so the panel never
        // becomes key — which silently costs you keyDown (no Esc, no ⌘Z, no colour
        // keys) and cursor rects (no crosshair). Draw mode is a MODE; owning the
        // keyboard while it is on is correct, and Esc gives it straight back.
        panel = OverlayPanel(contentRect: screen.frame,
                             styleMask: [.borderless],
                             backing: .buffered,
                             defer: false,
                             screen: screen)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        // NOT .canJoinAllSpaces: a screen-anchored annotation belongs to the Space it
        // was drawn in, and an ordinary managed window already behaves that way.
        // .fullScreenAuxiliary lets it also appear over a fullscreen app's Space.
        panel.collectionBehavior = [.fullScreenAuxiliary]
        panel.ignoresMouseEvents = true
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = false

        view = InkView(frame: NSRect(origin: .zero, size: screen.frame.size))
        view.manager = manager
        view.displayName = displayName
        view.autoresizingMask = [.width, .height]
        panel.contentView = view

        // Regardless, not makeKeyAndOrderFront: bringing the canvas up must never
        // activate this app or steal focus from what you were doing.
        panel.orderFrontRegardless()
    }

    var isHere: Bool { panel.isOnActiveSpace }
    var isEmpty: Bool { view.store.objects.isEmpty }

    func matches(screen: NSScreen) -> Bool {
        let id = (screen.deviceDescription[
            NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
        return id == displayID
    }
}

// ─────────────────────────────── the manager ───────────────────────────────

final class OverlayManager {

    private(set) var canvases: [Canvas] = []
    private(set) var mode: OverlayMode = .passthrough

    /// Whatever was frontmost when draw mode began, so Esc can hand focus back
    /// instead of dumping you on the Finder. Public API only — there is no
    /// "activate the previous app" call, so we remember it ourselves.
    private var appBeforeDraw: NSRunningApplication?

    /// A canvas is created per (display × Space visited). Visiting many Spaces would
    /// otherwise grow this without bound, so empty ones are reaped on exit and this
    /// is the hard backstop.
    private let maxCanvases = 32

    var onModeChange: ((OverlayMode) -> Void)?

    /// The self-test drives real panels but must not yank focus away from whatever
    /// Esa is doing, so it turns this off. Always true in normal operation.
    var activatesOnDraw = true

    init() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main) { [weak self] _ in self?.screensChanged() }
    }

    // ── canvases ──

    var here: [Canvas] { canvases.filter { $0.isHere } }

    /// Make sure every display has a canvas on the Space you are looking at right now.
    func ensureCanvasesHere() {
        for screen in NSScreen.screens {
            let existing = here.contains { $0.matches(screen: screen) }
            guard !existing, canvases.count < maxCanvases else {
                if canvases.count >= maxCanvases {
                    NSLog("Overlay: canvas cap (\(maxCanvases)) reached — not creating another")
                }
                continue
            }
            canvases.append(Canvas(screen: screen, manager: self))
        }
    }

    /// Throw away canvases that hold nothing and are somewhere else. Keeps a long
    /// session from accumulating a transparent window per Space you ever passed through.
    private func reapEmptyElsewhere() {
        let doomed = canvases.filter { !$0.isHere && $0.isEmpty }
        for c in doomed { c.panel.orderOut(nil); c.panel.close() }
        canvases.removeAll { c in doomed.contains { $0 === c } }
    }

    private func screensChanged() {
        for canvas in canvases {
            guard let screen = NSScreen.screens.first(where: { canvas.matches(screen: $0) })
            else { continue }
            canvas.panel.setFrame(screen.frame, display: true)
        }
    }

    // ── mode ──

    func toggleMode() { setMode(mode.toggled) }

    func setMode(_ new: OverlayMode) {
        if new == .draw { ensureCanvasesHere() }

        mode = new
        for canvas in canvases {
            canvas.panel.ignoresMouseEvents = new.ignoresMouseEvents
            canvas.view.mode = new
        }

        if new == .draw {
            appBeforeDraw = NSWorkspace.shared.frontmostApplication
            if activatesOnDraw { NSApp.activate(ignoringOtherApps: true) }
            if let target = canvasUnderPointer() ?? here.first {
                target.panel.makeKeyAndOrderFront(nil)
                target.panel.makeFirstResponder(target.view)
                // Activation is not guaranteed on the first attempt for a menu-bar
                // app. Retry once on the next runloop turn rather than leaving Esa
                // in a mode whose keyboard silently does nothing.
                if activatesOnDraw, !target.panel.isKeyWindow {
                    DispatchQueue.main.async {
                        NSRunningApplication.current.activate(options: [.activateAllWindows])
                        target.panel.makeKeyAndOrderFront(nil)
                        target.panel.makeFirstResponder(target.view)
                        if !target.panel.isKeyWindow {
                            NSLog("Overlay: panel still not key — keyboard shortcuts "
                                + "will not work; ⌃⌥⌘D and the menu still will")
                        }
                    }
                }
            }
        } else {
            // Ordering out and back drops key status without hiding the ink. Only
            // canvases already on this Space are touched — ordering a canvas from
            // another Space forward would physically drag it here.
            for canvas in here {
                canvas.panel.orderOut(nil)
                canvas.panel.orderFrontRegardless()
            }
            appBeforeDraw?.activate()
            appBeforeDraw = nil
            reapEmptyElsewhere()
        }

        // Draw mode is only usable if the panel actually took the keyboard. Log it
        // every time: "the hotkey fired but nothing worked" is otherwise impossible
        // to tell apart from "the hotkey never fired".
        if new == .draw, let panel = here.first?.panel {
            NSLog("Overlay: draw mode — appActive=\(NSApp.isActive) "
                + "key=\(panel.isKeyWindow) firstResponder="
                + "\(String(describing: type(of: panel.firstResponder ?? NSNull())))")
        }

        onModeChange?(new)
    }

    private func canvasUnderPointer() -> Canvas? {
        let mouse = NSEvent.mouseLocation
        return here.first { NSMouseInRect(mouse, $0.panel.frame, false) }
    }

    // ── actions the menu bar drives ──

    func undoHere() {
        for canvas in here { _ = canvas.view.store.undo(); canvas.view.needsDisplay = true }
        persist()
    }

    func redoHere() {
        for canvas in here { _ = canvas.view.store.redo(); canvas.view.needsDisplay = true }
        persist()
    }

    func clearHere() {
        for canvas in here { canvas.view.store.clear(); canvas.view.needsDisplay = true }
        persist()
    }

    /// What Esc does: remove the working marks, keep the finished work.
    ///
    /// Esc used to clear EVERYTHING, which was added because Esa could not get rid
    /// of anything — and then it destroyed his rendered images too, so drawing a
    /// second thing wiped the first picture. Scribbles and results are different
    /// things: ink is scaffolding, a render is the output. Esc clears scaffolding.
    func clearScratchHere() {
        for canvas in here {
            let store = canvas.view.store
            for o in store.objects where o.kind != .image {
                store.remove(id: o.id)
            }
            canvas.view.askableRegion = nil
            canvas.view.needsDisplay = true
        }
        persist()
    }

    /// Pen settings live on the canvas but are chosen globally, so switching display
    /// mid-session doesn't silently reset the colour you just picked.
    func setColor(index: Int) {
        guard Hex.palette.indices.contains(index) else { return }
        for canvas in canvases {
            canvas.view.colorHex = Hex.palette[index]
            canvas.view.needsDisplay = true
        }
    }

    /// The drag tool is global, not per-canvas, so moving between displays doesn't
    /// silently put you back in a different mode than the one you chose.
    func setTool(_ tool: InkView.Tool) {
        for canvas in canvases {
            canvas.view.tool = tool
            canvas.view.needsDisplay = true
        }
    }

    func nudgeWidth(_ delta: Double) {
        for canvas in canvases {
            canvas.view.strokeWidth = min(48, max(1, canvas.view.strokeWidth + delta))
            canvas.view.needsDisplay = true
        }
    }

    func clearAll() {
        for canvas in canvases { canvas.view.store.clear(); canvas.view.needsDisplay = true }
        persist()
    }

    var markCount: Int { canvases.reduce(0) { $0 + $1.view.store.objects.count } }

    /// Remove every mark posted by one actor, or all marks if `actor` is nil. This is
    /// how an agent cleans up after itself without touching a human's ink.
    func clear(actor: String?) {
        for canvas in canvases {
            let store = canvas.view.store
            let doomed = store.objects.filter { actor == nil || $0.actor == actor }
            for o in doomed { store.remove(id: o.id) }
            if !doomed.isEmpty { canvas.view.needsDisplay = true }
        }
        syncTTLCollector()
        persist()
    }

    // ── the agent side ──

    /// Put posted objects on screen. Returns nil on success or a reason on rejection;
    /// the inbox uses that verdict to decide whether to consume or quarantine a file.
    ///
    /// Posting never changes the input mode. An agent may draw all over the screen
    /// while Esa keeps typing — the overlay stays click-through throughout.
    @discardableResult
    func post(_ requests: [PostRequest]) -> String? {
        ensureCanvasesHere()
        guard !here.isEmpty else { return "no canvas available on the active Space" }

        var failures: [String] = []
        var touched = Set<ObjectIdentifier>()

        for request in requests {
            // An agent may name a display; otherwise the mark lands on the first
            // canvas of the Space currently in front of Esa.
            let target = request.display.flatMap { name in
                here.first { $0.displayName == name }
            } ?? here[0]

            do {
                let object = try request.resolve(in: target.view.bounds)
                target.view.store.add(object)
                touched.insert(ObjectIdentifier(target))
            } catch let e as PostRequest.PostError {
                failures.append(e.description)
            } catch {
                failures.append("\(error)")
            }
        }

        for canvas in canvases where touched.contains(ObjectIdentifier(canvas)) {
            canvas.view.needsDisplay = true
        }
        if !touched.isEmpty { persist(); syncTTLCollector() }

        return failures.isEmpty ? nil : failures.joined(separator: "; ")
    }

    // ── ask: the point of the whole thing ──

    /// Take the last shape drawn, crop the screen to it, and hand that region to a
    /// model. The squiggle is a SELECTION GESTURE, not a drawing: circle part of a
    /// whiteboard and this is what turns it into "look at this bit and tell me".
    ///
    /// Steps, in order, and why:
    ///   1. the last object's cropRect — the region the human indicated
    ///   2. hide every canvas, so the ink itself is not in the screenshot
    ///   3. `screencapture -x -R` — Apple-shipped, no prompt, no library
    ///   4. restore the canvases, drop a "thinking" mark so something visibly happens
    ///   5. hand the PNG to bin/overlay-ask, which OCRs it and asks a model, then
    ///      posts the answer back through the ordinary inbox as a callout
    /// Screen Recording is not optional for "ask", and its failure mode is vicious.
    ///
    /// Without the grant macOS does NOT refuse the screenshot — it hands back the
    /// desktop with every window stripped out. So the crop looks plausible, the OCR
    /// succeeds, and the answer confidently describes the user's WALLPAPER. Esa spent
    /// a morning being told his screen said "WORLD WIRELESS" because that is what his
    /// desktop picture says.
    ///
    /// Note the ad-hoc signature caveat: `codesign -s -` gives a new cdhash on every
    /// rebuild, so TCC forgets the grant each time Overlay.app is rebuilt and it must
    /// be re-added. That is why this checks on every ask rather than once at launch.
    private func hasScreenRecording() -> Bool {
        if CGPreflightScreenCaptureAccess() { return true }
        // Fires the system prompt the first time; a no-op once the user has answered.
        _ = CGRequestScreenCaptureAccess()
        return CGPreflightScreenCaptureAccess()
    }

    private func demandScreenRecording(on canvas: Canvas, at region: CGRect) {
        canvas.view.store.add(OverlayObject(
            kind: .callout,
            points: [CGPoint(x: region.midX, y: region.midY),
                     CGPoint(x: region.midX, y: region.maxY + 46)],
            colorHex: "#FF9F0A", width: 3, actor: "agent:ask",
            lifetime: .session, anchor: OverlayAnchor(type: .screen),
            text: "Grant Overlay Screen Recording — without it macOS returns your "
                + "wallpaper, not your screen. Opening Settings…"))
        canvas.view.needsDisplay = true
        persist()
        NSWorkspace.shared.open(URL(string:
            "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
        NSLog("Overlay: ask blocked — no Screen Recording grant; captures would be "
            + "desktop-only. Re-add Overlay.app after every rebuild (ad-hoc signed).")
    }

    /// Generate a picture from the selected region and drop it INTO that region.
    /// Same capture path as ask; different tool on the other end.
    /// Rasterise the human's own ink to a white-background PNG.
    ///
    /// This is what makes "draw a cube, get a cube" work: Image Playground accepts
    /// the drawing itself as a concept, so nothing has to put the word "cube" into
    /// words. No screenshot, no OCR, no Screen Recording grant — just the strokes.
    private func rasterizeInk(_ objects: [OverlayObject], within frame: CGRect? = nil,
                              pad: CGFloat = 24) -> (URL, CGRect)? {
        let frameRect = frame
        var strokes = objects.filter { $0.kind == .ink || $0.kind == .line }
        // A canvas frame scopes the render to what was drawn INSIDE it, so several
        // sketches can live on one screen and be sent one at a time.
        if let frame = frame {
            strokes = strokes.filter { frame.intersects($0.bounds) }
        }
        guard !strokes.isEmpty else { return nil }

        var box = CGRect.null
        for o in strokes { box = box.isNull ? o.bounds : box.union(o.bounds) }
        guard !box.isNull, box.width > 4, box.height > 4 else { return nil }
        // Inside a canvas frame the frame itself is the output rectangle, so the
        // render lands exactly where the frame was drawn.
        let frame = frameRect ?? box.insetBy(dx: -pad, dy: -pad)

        let image = NSImage(size: frame.size)
        image.lockFocus()
        // White, not clear: the generator reads this as a sketch on paper, and a
        // transparent background composites to black and swamps the drawing.
        NSColor.white.setFill()
        NSBezierPath(rect: CGRect(origin: .zero, size: frame.size)).fill()
        NSColor.black.setStroke()
        for o in strokes {
            guard o.points.count > 1 else { continue }
            let path = NSBezierPath()
            // Thin ink barely registers; the drawn weight is a UI choice, not intent.
            path.lineWidth = max(5, CGFloat(o.width) * 1.6)
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            path.move(to: CGPoint(x: o.points[0].x - frame.minX,
                                  y: o.points[0].y - frame.minY))
            for p in o.points.dropFirst() {
                path.line(to: CGPoint(x: p.x - frame.minX, y: p.y - frame.minY))
            }
            path.stroke()
        }
        image.unlockFocus()

        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else { return nil }
        let url = OverlayPaths.asks
            .appendingPathComponent("drawing-\(Int(Date().timeIntervalSince1970)).png")
        try? FileManager.default.createDirectory(at: OverlayPaths.asks,
                                                 withIntermediateDirectories: true)
        do { try png.write(to: url) } catch { return nil }
        return (url, frame)
    }

    func imagineLastRegion(prompt: String? = nil) {
        // If there is ink on this canvas, THE DRAWING IS THE SUBJECT. Only fall back
        // to photographing the screen when the user selected a region instead of
        // drawing something.
        // Prefer a canvas frame: if boxes exist, use the LAST one that actually has
        // ink in it, so "draw an area, sketch in it, send it" works.
        let canvasFrame: CGRect? = here.first?.view.store.objects
            .last(where: { o in
                o.kind == .box && here.first!.view.store.objects.contains {
                    ($0.kind == .ink || $0.kind == .line) && o.rect.intersects($0.bounds)
                }
            })?.rect

        if let canvas = here.first(where: { !$0.view.store.objects.isEmpty }),
           let (png, frame) = rasterizeInk(canvas.view.store.objects, within: canvasFrame) {
            // The drawing itself shows that it is working, by breathing. No bubble.
            let pulsing = Set(canvas.view.store.objects
                .filter { ($0.kind == .ink || $0.kind == .line)
                       && (canvasFrame == nil || canvasFrame!.intersects($0.bounds)) }
                .map(\.id))
            canvas.view.renderingIDs = pulsing
            canvas.view.askableRegion = nil
            canvas.view.needsDisplay = true

            runTool("/Users/esaruoho/work/apple/bin/overlay-imagine",
                    args: [png.path, "--from-drawing"]
                        + (prompt.map { ["--prompt", $0] } ?? [])) { output in
                canvas.view.renderingIDs = []
                let path = output.split(separator: "\n").last.map(String.init) ?? ""
                if FileManager.default.fileExists(atPath: path) {
                    // The render replaces the sketch, in the same place and at the
                    // same size — you drew a cube there, now a cube is there.
                    for o in canvas.view.store.objects
                        where (o.kind == .ink || o.kind == .line || o.kind == .box)
                           && o.actor.hasPrefix("human:")
                           && (canvasFrame == nil
                               || canvasFrame!.intersects(o.kind == .box ? o.rect : o.bounds)) {
                        canvas.view.store.remove(id: o.id)
                    }
                    canvas.view.store.add(OverlayObject(
                        kind: .image,
                        points: [frame.origin, CGPoint(x: frame.maxX, y: frame.maxY)],
                        colorHex: "#AF52DE", width: 2, actor: "agent:imagine",
                        lifetime: .session,
                        anchor: OverlayAnchor(type: .screen), imagePath: path))
                } else {
                    canvas.view.store.add(OverlayObject(
                        kind: .callout,
                        points: [CGPoint(x: frame.midX, y: frame.midY),
                                 CGPoint(x: frame.midX, y: frame.maxY + 46)],
                        colorHex: "#FF9F0A", width: 3, actor: "agent:imagine",
                        lifetime: .session, anchor: OverlayAnchor(type: .screen),
                        text: OverlayManager.wrap(output)))
                }
                canvas.view.needsDisplay = true
                self.persist()
            }
            return
        }

        captureLastRegion(waiting: "imagining…", waitColor: "#AF52DE") {
            png, region, canvas, placeholder in
            self.runTool("/Users/esaruoho/work/apple/bin/overlay-imagine",
                         args: [png.path] + (prompt.map { ["--prompt", $0] } ?? [])) {
                output in
                canvas.view.store.remove(id: placeholder)
                let path = output.split(separator: "\n").last.map(String.init) ?? ""
                if FileManager.default.fileExists(atPath: path) {
                    canvas.view.store.add(OverlayObject(
                        kind: .image,
                        points: [region.origin,
                                 CGPoint(x: region.maxX, y: region.maxY)],
                        colorHex: "#AF52DE", width: 2, actor: "agent:imagine",
                        lifetime: .session,
                        anchor: OverlayAnchor(type: .screen), imagePath: path))
                } else {
                    canvas.view.store.add(OverlayObject(
                        kind: .callout,
                        points: [CGPoint(x: region.midX, y: region.midY),
                                 CGPoint(x: region.midX, y: region.maxY + 46)],
                        colorHex: "#FF9F0A", width: 3, actor: "agent:imagine",
                        lifetime: .session, anchor: OverlayAnchor(type: .screen),
                        text: OverlayManager.wrap(output.isEmpty
                                                  ? "image generation failed" : output)))
                }
                canvas.view.needsDisplay = true
                self.persist()
            }
        }
    }

    /// Open the typing field for a region, then run the ask with what was typed.
    /// The question is kept on screen above the answer so the pair reads as an
    /// exchange rather than a bare pronouncement.
    func openChat(for region: CGRect?) {
        // Canvases are created lazily on first use, so asking to chat before ever
        // entering draw mode found nothing and returned in silence.
        ensureCanvasesHere()
        guard let canvas = here.first else {
            NSLog("Overlay: chat — no canvas on this Space")
            return
        }
        let anchorView = region
            ?? canvas.view.store.objects.last.map { $0.kind.isRectangular ? $0.rect : $0.bounds }
            ?? CGRect(x: canvas.view.bounds.midX - 150,
                      y: canvas.view.bounds.midY - 80, width: 300, height: 160)
        // Panel coordinates are global; the canvas covers its screen exactly.
        let origin = canvas.panel.frame.origin
        let anchorGlobal = anchorView.offsetBy(dx: origin.x, dy: origin.y)

        chat?.close()
        let panel = ChatPanel(anchor: anchorGlobal, context: "Overlay — ask about this region",
                              onSubmit: { [weak self] text in
            guard let self = self else { return }
            // Show the question immediately, anchored to the same region.
            canvas.view.store.add(OverlayObject(
                kind: .label,
                points: [CGPoint(x: anchorView.midX, y: anchorView.maxY + 34)],
                colorHex: "#5E5CE6", width: 3, actor: "human:esa",
                lifetime: .session, anchor: OverlayAnchor(type: .screen),
                text: "you: " + text))
            canvas.view.needsDisplay = true
            self.persist()
            self.askLastRegion(question: text)
        }, onCancel: { [weak self] in self?.chat = nil })
        chat = panel
        panel.present()
    }

    func askLastRegion(question: String? = nil) {
        captureLastRegion(waiting: "thinking…", waitColor: "#0A84FF") {
            png, region, canvas, placeholder in
            self.runTool("/Users/esaruoho/work/apple/bin/overlay-ask",
                         args: [png.path] + (question.map { ["--question", $0] } ?? [])) {
                output in
                canvas.view.store.remove(id: placeholder)
                canvas.view.store.add(OverlayObject(
                    kind: .callout,
                    points: [CGPoint(x: region.midX, y: region.midY),
                             CGPoint(x: region.midX, y: region.maxY + 46)],
                    colorHex: "#34C759", width: 3, actor: "agent:ask",
                    lifetime: .session, anchor: OverlayAnchor(type: .screen),
                    text: OverlayManager.wrap(output)))
                canvas.view.needsDisplay = true
                self.persist()
            }
        }
    }

    /// Shared front half of both actions: find the selected region, screenshot it,
    /// and put a placeholder up so something visibly happens straight away.
    ///
    /// The completion runs on the main queue with the crop, the region in view
    /// coordinates, its canvas, and the placeholder's id to replace.
    private func captureLastRegion(waiting: String, waitColor: String,
                                   then body: @escaping (URL, CGRect, Canvas, String) -> Void) {
        guard let canvas = here.first(where: { !$0.view.store.objects.isEmpty })
                        ?? here.first,
              let last = canvas.view.store.objects.last(where: { $0.kind != .image
                                                              && $0.kind != .callout })
                      ?? canvas.view.store.objects.last else {
            NSLog("Overlay: nothing selected to act on")
            return
        }

        let crop = last.cropRect(in: canvas.view.bounds, pad: 8)
        guard crop.width > 8, crop.height > 8 else {
            NSLog("Overlay: the region is too small to be worth capturing")
            return
        }

        // Checked BEFORE capturing: without the grant macOS returns the desktop
        // wallpaper rather than failing, which yields a confident answer about
        // entirely the wrong picture.
        guard hasScreenRecording() else {
            demandScreenRecording(on: canvas, at: crop)
            return
        }

        // View coords are this canvas's screen frame; lift them to AppKit global.
        let origin = canvas.panel.frame.origin
        let global = CGRect(x: crop.minX + origin.x, y: crop.minY + origin.y,
                            width: crop.width, height: crop.height)

        // screencapture speaks top-left, measured from the top of the PRIMARY display.
        let primary = NSScreen.screens.first { $0.frame.origin == .zero } ?? NSScreen.screens[0]
        let top = primary.frame.height - global.maxY
        let spec = "\(Int(global.minX)),\(Int(top)),\(Int(global.width)),\(Int(global.height))"

        let png = OverlayPaths.asks
            .appendingPathComponent("region-\(Int(Date().timeIntervalSince1970)).png")
        try? FileManager.default.createDirectory(at: OverlayPaths.asks,
                                                 withIntermediateDirectories: true)

        // The overlay must not photograph itself. Hiding is instant but the window
        // server needs a beat to composite, hence the async hop rather than a sleep.
        for c in canvases { c.panel.alphaValue = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            guard let self = self else { return }
            let capture = Process()
            capture.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            capture.arguments = ["-x", "-R", spec, png.path]
            try? capture.run()
            capture.waitUntilExit()

            for c in self.canvases { c.panel.alphaValue = 1 }

            guard FileManager.default.fileExists(atPath: png.path) else {
                NSLog("Overlay: screencapture produced nothing for \(spec)")
                return
            }

            let placeholder = OverlayObject(
                kind: .callout,
                points: [CGPoint(x: crop.midX, y: crop.midY),
                         CGPoint(x: crop.midX, y: crop.maxY + 46)],
                colorHex: waitColor, width: 3, actor: "agent:ask",
                lifetime: .session, anchor: OverlayAnchor(type: .screen), text: waiting)
            canvas.view.store.add(placeholder)
            canvas.view.needsDisplay = true

            body(png, crop, canvas, placeholder.id)
        }
    }

    /// Run one of the helper tools off the main thread and hand its stdout back on
    /// the main thread. Image generation in particular takes minutes, so this must
    /// never touch the run loop.
    private func runTool(_ path: String, args: [String],
                         then body: @escaping (String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: path)
            process.arguments = args
            // A GUI app's child gets a minimal PATH, and these tools shell out
            // internally — without this, OCR silently returns nothing.
            var env = ProcessInfo.processInfo.environment
            env["PATH"] = "/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin"
            env["HOME"] = NSHomeDirectory()
            process.environment = env

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = Pipe()

            var output = ""
            do {
                try process.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()
                output = String(data: data, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if output.isEmpty {
                    output = "\(URL(fileURLWithPath: path).lastPathComponent) gave no "
                           + "output (exit \(process.terminationStatus))"
                }
            } catch {
                output = "could not run \(path): \(error.localizedDescription)"
            }
            DispatchQueue.main.async { body(output) }
        }
    }

    /// A model answer is a paragraph; a callout chip is one line. Take the first
    /// sentence-ish chunk so the thing on screen stays readable — the full text is in
    /// the store for anyone who wants it.
    static func wrap(_ text: String, limit: Int = 300) -> String {
        let flat = text.replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespaces)
        guard flat.count > limit else { return flat }
        let cut = flat.prefix(limit)
        if let space = cut.lastIndex(of: " ") { return String(cut[..<space]) + "…" }
        return String(cut) + "…"
    }

    // ── TTL collection ──

    /// Ephemeral marks need a clock, but an overlay that ticks forever is a battery
    /// leak. The collector only exists while something ephemeral is on screen, and
    /// stops itself the moment the last one is gone.
    private var chat: ChatPanel?
    private var ttlCollector: Timer?

    /// Exposed so the self-test can assert that nothing is ticking at idle.
    var hasTTLCollector: Bool { ttlCollector != nil }

    func syncTTLCollector() {
        let hasEphemeral = canvases.contains { canvas in
            canvas.view.store.objects.contains { $0.lifetime == .ephemeral }
        }
        if hasEphemeral, ttlCollector == nil {
            ttlCollector = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {
                [weak self] _ in self?.collectExpired()
            }
        } else if !hasEphemeral, let timer = ttlCollector {
            timer.invalidate()
            ttlCollector = nil
        }
    }

    private func collectExpired() {
        let now = Date().timeIntervalSince1970
        var removed = 0
        for canvas in canvases {
            let n = canvas.view.store.expire(now: now)
            if n > 0 { removed += n; canvas.view.needsDisplay = true }
        }
        if removed > 0 { persist() }
        syncTTLCollector()
    }

    /// Mirror every canvas to ~/.overlay/store/session.json.
    ///
    /// P0 writes but deliberately does NOT restore: without a durable Space identity
    /// (no public API gives one), restoring would splatter yesterday's ink onto
    /// whichever Space happened to be frontmost. The file exists so the state is
    /// inspectable, testable, and readable by P1's agent side.
    func persist() {
        let all = canvases.flatMap { $0.view.store.objects }
        do {
            try OverlayStore(objects: all).save(to: OverlayPaths.session)
        } catch {
            NSLog("Overlay: could not write \(OverlayPaths.session.path): \(error)")
        }
    }
}

// ─────────────────────────────── app ───────────────────────────────

final class AppDelegate: NSObject, NSApplicationDelegate {

    let manager = OverlayManager()
    private var statusItem: NSStatusItem!
    private var hotKeyRef: EventHotKeyRef?
    private var drawKeyRefs: [EventHotKeyRef] = []
    private var clearHotKeyRef: EventHotKeyRef?
    private var helpWindow: NSWindow?
    private var inbox: InboxWatcher?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // --selftest drives the real panels in-process and exits. It runs from inside
        // applicationDidFinishLaunching so there is a live window server and run loop
        // to answer questions like isOnActiveSpace.
        if CommandLine.arguments.contains("--selftest") {
            manager.activatesOnDraw = false
            let code = OverlaySelfTest.run(manager: manager)
            exit(Int32(code))
        }

        buildStatusItem()
        registerHotKey()
        startInbox()
        registerControlChannel()
        manager.onModeChange = { [weak self] mode in
            self?.refreshStatusItem()
            self?.setDrawModeKeys(active: mode == .draw)
        }
        refreshStatusItem()

        NotificationCenter.default.addObserver(
            forName: .showAppHelp, object: nil, queue: .main) { [weak self] _ in
                self?.showHelp(nil)
            }

        NSLog("Overlay: ready — ⌃⌥⌘D toggles draw mode; "
            + "screenRecording=\(CGPreflightScreenCaptureAccess())")
    }

    // ── menu bar ──

    private func buildStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        let menu = NSMenu()
        let draw = NSMenuItem(title: "Draw Mode", action: #selector(toggleDraw), keyEquivalent: "")
        draw.target = self
        menu.addItem(draw)

        // First real item, because this is what someone opens the menu to find.
        let wipe = NSMenuItem(title: "Clear Everything  ⌃⌥⌘C",
                              action: #selector(clearAll), keyEquivalent: "")
        wipe.target = self
        menu.addItem(wipe)
        menu.addItem(.separator())

        for (title, selector, key) in [
            ("Undo Last Mark", #selector(undoHere), "z"),
            ("Clear This Canvas", #selector(clearHere), ""),
        ] {
            let item = NSMenuItem(title: title, action: selector, keyEquivalent: key)
            item.target = self
            menu.addItem(item)
        }

        menu.addItem(.separator())
        let reveal = NSMenuItem(title: "Reveal Store in Finder",
                                action: #selector(revealStore), keyEquivalent: "")
        reveal.target = self
        menu.addItem(reveal)

        let help = NSMenuItem(title: "Overlay Help…", action: #selector(showHelp), keyEquivalent: "?")
        help.target = self
        menu.addItem(help)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Overlay",
                                action: #selector(NSApplication.terminate(_:)),
                                keyEquivalent: "q"))
        statusItem.menu = menu
    }

    private func refreshStatusItem() {
        guard let button = statusItem.button else { return }
        let drawing = manager.mode == .draw
        // SF Symbols rather than emoji: they inherit the menu-bar metrics instead of
        // needing a U+FE0F nudge to render at the right size.
        button.image = NSImage(systemSymbolName: drawing ? "pencil.circle.fill" : "pencil",
                               accessibilityDescription: drawing ? "Overlay — drawing" : "Overlay")
        button.toolTip = drawing
            ? "Overlay — DRAW mode (esc to exit)"
            : "Overlay — click-through (⌃⌥⌘D to draw)"
        statusItem.menu?.item(at: 0)?.state = drawing ? .on : .off
        statusItem.menu?.item(at: 0)?.title = drawing ? "Draw Mode  ⌃⌥⌘D" : "Draw Mode  ⌃⌥⌘D"
    }

    // ── actions ──

    @objc func toggleDraw() { manager.toggleMode() }
    @objc func undoHere() { manager.undoHere() }
    @objc func clearHere() { manager.clearHere() }
    @objc func clearAll() { manager.clearAll() }

    @objc func revealStore() {
        try? FileManager.default.createDirectory(at: OverlayPaths.store,
                                                 withIntermediateDirectories: true)
        NSWorkspace.shared.selectFile(OverlayPaths.session.path,
                                      inFileViewerRootedAtPath: OverlayPaths.store.path)
    }

    @objc func showHelp(_ sender: Any?) {
        if let existing = helpWindow {
            NSApp.activate(ignoringOtherApps: true)
            existing.makeKeyAndOrderFront(nil)
            return
        }
        // The shared panel every app in this repo ships — one Help, one donation list.
        let view = AppHelpView(
            appName: "Overlay",
            tagline: "A spatial blackboard over your desktop. Draw on top of anything; "
                   + "the overlay is invisible to the mouse until you ask for it.",
            usage: [
                ("pencil.circle", "⌃⌥⌘D toggles draw mode. Esc leaves it."),
                ("cursorarrow.click", "Outside draw mode every click goes straight through."),
                ("rectangle.on.rectangle", "Marks stay in the Space you drew them in."),
                ("paintpalette", "1–6 pick a colour, [ and ] change the width."),
                ("arrow.uturn.backward", "⌘Z undo, ⇧⌘Z redo, ⌘⌫ clears the canvas."),
            ],
            note: "P0. Marks are mirrored to ~/.overlay/store/session.json but are not "
                + "restored on launch — macOS exposes no durable Space identity, so "
                + "restoring would drop old ink onto the wrong desktop.")

        let hosting = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hosting)
        window.title = "Overlay Help"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.center()
        helpWindow = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    // ── agent ingress ──

    private func startInbox() {
        inbox = InboxWatcher { [weak self] requests in
            guard let self = self else { return "overlay is shutting down" }
            let failure = self.manager.post(requests)
            self.refreshStatusItem()
            return failure
        }
        inbox?.start()
    }

    /// Control verbs arrive as distributed notifications so `bin/overlay clear` needs
    /// nothing but a one-line osascript. The object field carries the actor to filter
    /// on, or is empty for "everything".
    private func registerControlChannel() {
        let center = DistributedNotificationCenter.default()
        center.addObserver(forName: OverlayControl.clear, object: nil, queue: .main) {
            [weak self] note in
            let actor = (note.object as? String).flatMap { $0.isEmpty ? nil : $0 }
            self?.manager.clear(actor: actor)
            NSLog("Overlay: control clear actor=\(actor ?? "*")")
            self?.refreshStatusItem()
        }
        center.addObserver(forName: OverlayControl.draw, object: nil, queue: .main) {
            [weak self] _ in
            self?.manager.toggleMode()
        }
        // "ask about the last thing I drew" — same entry point as ⌘Return in draw
        // mode, so the CLI and the keyboard cannot drift apart.
        center.addObserver(forName: OverlayControl.probe, object: nil, queue: .main) {
            [weak self] _ in
            // Ground truth: capture the full screen ignoring the preflight, so the
            // PNG itself can be inspected for whether any window is present. The
            // preflight API and the actual capture can disagree for an ad-hoc app.
            let out = "/tmp/overlay-probe.png"
            for c in self?.manager.canvases ?? [] { c.panel.alphaValue = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                let p = Process()
                p.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
                p.arguments = ["-x", out]
                var env = ProcessInfo.processInfo.environment
                env["PATH"] = "/usr/bin:/bin:/usr/sbin:/sbin"
                p.environment = env
                try? p.run(); p.waitUntilExit()
                for c in self?.manager.canvases ?? [] { c.panel.alphaValue = 1 }
                NSLog("Overlay: probe capture -> \(out) exit=\(p.terminationStatus) "
                    + "preflight=\(CGPreflightScreenCaptureAccess())")
            }
        }
        center.addObserver(forName: OverlayControl.chat, object: nil, queue: .main) {
            [weak self] _ in self?.manager.openChat(for: nil)
        }
        center.addObserver(forName: OverlayControl.imagine, object: nil, queue: .main) {
            [weak self] note in
            let prompt = (note.object as? String).flatMap { $0.isEmpty ? nil : $0 }
            self?.manager.imagineLastRegion(prompt: prompt)
        }
        center.addObserver(forName: OverlayControl.ask, object: nil, queue: .main) {
            [weak self] note in
            let question = (note.object as? String).flatMap { $0.isEmpty ? nil : $0 }
            self?.manager.askLastRegion(question: question)
        }
    }

    // ── global hotkey ──

    /// ⌃⌥⌘D. Not ⌥⌘D: per feedback_carbon_hotkey_gotchas the ⌃⌥⌘‹letter› family is
    /// the one that reliably survives iTerm2 / Karabiner / other menu-bar apps
    /// swallowing the keystroke before HIToolbox sees it.
    private func registerHotKey() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                 eventKind: UInt32(kEventHotKeyPressed))
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), { _, eventRef, userData -> OSStatus in
            guard let userData = userData, let eventRef = eventRef else { return noErr }
            var id = EventHotKeyID()
            GetEventParameter(eventRef,
                              EventParamName(kEventParamDirectObject),
                              EventParamType(typeEventHotKeyID),
                              nil, MemoryLayout<EventHotKeyID>.size, nil, &id)
            let me = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()
            NSLog("Overlay: hotkey fired id=\(id.id)")
            DispatchQueue.main.async {
                switch id.id {
                case 1:  me.toggleDraw()
                case 3:  me.manager.clearAll()   // ⌃⌥⌘C — always available
                default: me.handleDrawKey(id.id)   // Esc / undo / colours / width
                }
            }
            return noErr
        }, 1, &spec, selfPtr, nil)

        let mods = UInt32(controlKey | optionKey | cmdKey)
        let id = EventHotKeyID(signature: OSType(0x4F564C44), id: 1)   // 'OVLD'
        let status = RegisterEventHotKey(UInt32(kVK_ANSI_D), mods, id,
                                         GetApplicationEventTarget(), 0, &hotKeyRef)
        if status != noErr {
            NSLog("Overlay: ⌃⌥⌘D registration failed with OSStatus \(status)")
        }

        // ⌃⌥⌘C — wipe everything, armed ALWAYS, not just in draw mode.
        //
        // Esa ended up looking at a generated image he could not remove: the ✕ only
        // exists in draw mode and Esc is only armed in draw mode, so from
        // passthrough there was no way out at all. There is now always one key that
        // clears the screen, whatever state the overlay is in.
        let clearID = EventHotKeyID(signature: OSType(0x4F564C43), id: 3)   // 'OVLC'
        let clearStatus = RegisterEventHotKey(UInt32(kVK_ANSI_C), mods, clearID,
                                              GetApplicationEventTarget(), 0, &clearHotKeyRef)
        if clearStatus != noErr {
            NSLog("Overlay: ⌃⌥⌘C registration failed with OSStatus \(clearStatus)")
        }
    }

    /// Every draw-mode key, registered globally for exactly as long as draw mode is on.
    ///
    /// The view's `keyDown` handles all of these too — but only when the panel is the
    /// key window, and on a menu-bar (.accessory) app it never becomes key: macOS's
    /// cooperative activation refuses to let a background app take focus, so
    /// `NSApp.activate` is a no-op. Measured, not assumed: `appActive=false key=false`
    /// in the log on the very first real run, which is why Esa got a canvas he could
    /// draw on but no Esc, no ⌘Z and no colours.
    ///
    /// Carbon hotkeys need no permission, no activation and no key window — they fire
    /// whatever is frontmost. Grabbing bare 1-6 and [ ] globally is only acceptable
    /// because it lasts precisely as long as the mode does, and the mode is now
    /// impossible to miss. Leaving draw mode hands every key straight back.
    private func setDrawModeKeys(active: Bool) {
        if active {
            guard drawKeyRefs.isEmpty else { return }
            // (virtual key, modifiers, id)
            var wanted: [(Int, UInt32, UInt32)] = [
                (kVK_Escape,     0,                    2),   // exit — the escape hatch
                (kVK_ANSI_Z,     UInt32(cmdKey),              20),   // undo
                (kVK_ANSI_Z,     UInt32(cmdKey | shiftKey),   21),   // redo
                (kVK_Delete,     UInt32(cmdKey),              22),   // clear canvas
                (kVK_ANSI_LeftBracket,  0,             23),   // thinner
                (kVK_ANSI_RightBracket, 0,             24),   // thicker
                (kVK_ANSI_T,     UInt32(cmdKey),              32),   // TYPE a question
                (kVK_Return,     UInt32(cmdKey),              30),   // ASK about the region
                (kVK_Return,     UInt32(optionKey),           31),   // MAKE AN IMAGE of it
                (kVK_ANSI_F,     0,                           26),   // freehand pen
                (kVK_ANSI_R,     0,                           27),   // region select
            ]
            let numbers = [kVK_ANSI_1, kVK_ANSI_2, kVK_ANSI_3,
                           kVK_ANSI_4, kVK_ANSI_5, kVK_ANSI_6]
            for (index, key) in numbers.enumerated() {
                wanted.append((key, 0, UInt32(10 + index)))   // colour 1-6
            }

            for (key, mods, id) in wanted {
                var ref: EventHotKeyRef?
                let hotKeyID = EventHotKeyID(signature: OSType(0x4F564C4B), id: id)  // 'OVLK'
                let status = RegisterEventHotKey(UInt32(key), mods, hotKeyID,
                                                 GetApplicationEventTarget(), 0, &ref)
                if status == noErr, let ref = ref {
                    drawKeyRefs.append(ref)
                } else {
                    NSLog("Overlay: draw-mode key id=\(id) failed with OSStatus \(status)")
                }
            }
            NSLog("Overlay: draw-mode keys armed (\(drawKeyRefs.count)/\(wanted.count))")
        } else {
            for ref in drawKeyRefs { UnregisterEventHotKey(ref) }
            drawKeyRefs.removeAll()
        }
    }

    /// Apply a draw-mode key to whichever canvases are on this Space.
    fileprivate func handleDrawKey(_ id: UInt32) {
        guard manager.mode == .draw else { return }
        switch id {
        case 2:  manager.clearScratchHere(); manager.setMode(.passthrough)
        case 20: manager.undoHere()
        case 21: manager.redoHere()
        case 22: manager.clearHere()
        case 23: manager.nudgeWidth(-1)
        case 24: manager.nudgeWidth(+1)
        case 32: manager.openChat(for: nil)
        case 30: manager.askLastRegion()
        case 31: manager.imagineLastRegion()
        case 26: manager.setTool(.ink)
        case 27: manager.setTool(.region)
        case 10...15: manager.setColor(index: Int(id) - 10)
        default: break
        }
    }
}

// ─────────────────────────────── main ───────────────────────────────

@main
enum OverlayMain {
    /// NSApplication.delegate is weak, so the delegate has to be owned by something
    /// that outlives main() — a local `let` would be released before the run loop
    /// ever calls applicationDidFinishLaunching.
    static let delegate = AppDelegate()

    static func main() {
        let app = NSApplication.shared
        // .accessory: an overlay has no business owning a Dock tile or a Cmd-Tab
        // slot. The menu-bar pencil is the whole visible surface when not drawing.
        app.setActivationPolicy(.accessory)
        app.delegate = delegate
        app.run()
    }
}

// ─────────────────────────────── chat ───────────────────────────────

/// A text field anchored to a region: the missing half of "spatial chat".
///
/// Everything before this could annotate a region and answer a fixed question about
/// it. There was no way to TYPE — every question came from the command line or a
/// hardcoded default, which is not a conversation.
///
/// This is a separate small panel rather than a field inside the canvas because the
/// canvas is a borderless overlay that macOS will not hand the keyboard to on a
/// menu-bar app. A titled panel that the user CLICKS becomes key normally, because
/// the click itself is the activation the window server wants.
final class ChatPanel: NSPanel, NSTextFieldDelegate {

    private let field = NSTextField()
    private let onSubmit: (String) -> Void
    private let onCancel: () -> Void

    override var canBecomeKey: Bool { true }

    init(anchor: CGRect, question: String = "", context: String,
         onSubmit: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        self.onSubmit = onSubmit
        self.onCancel = onCancel

        let width: CGFloat = 460, height: CGFloat = 92
        super.init(contentRect: NSRect(x: 0, y: 0, width: width, height: height),
                   styleMask: [.titled, .closable, .utilityWindow],
                   backing: .buffered, defer: false)

        title = context
        isFloatingPanel = true
        level = .floating
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        collectionBehavior = [.fullScreenAuxiliary]

        let label = NSTextField(labelWithString: "Ask about this region  ·  ⏎ send  ·  esc cancel")
        label.font = .systemFont(ofSize: 11)
        label.textColor = .secondaryLabelColor

        field.placeholderString = "What is this? What's wrong here? Explain it…"
        field.stringValue = question
        field.font = .systemFont(ofSize: 14)
        field.bezelStyle = .roundedBezel
        field.delegate = self
        field.target = self
        field.action = #selector(submit)

        let stack = NSStackView(views: [label, field])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        stack.edgeInsets = NSEdgeInsets(top: 12, left: 14, bottom: 12, right: 14)
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView = NSView()
        contentView!.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView!.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView!.trailingAnchor),
            stack.topAnchor.constraint(equalTo: contentView!.topAnchor),
            field.widthAnchor.constraint(equalToConstant: width - 28),
        ])

        // Sit just under the region being asked about, clamped on screen.
        let screen = NSScreen.screens.first { $0.frame.intersects(anchor) } ?? NSScreen.main!
        var origin = CGPoint(x: anchor.midX - width / 2, y: anchor.minY - height - 12)
        if origin.y < screen.visibleFrame.minY + 8 { origin.y = anchor.maxY + 12 }
        origin.x = min(max(screen.visibleFrame.minX + 8, origin.x),
                       screen.visibleFrame.maxX - width - 8)
        setFrameOrigin(origin)
    }

    func present() {
        // Becoming a REGULAR app is what actually lets a menu-bar app take the
        // keyboard. .accessory apps are refused activation by macOS cooperative
        // activation — measured earlier in this app: appActive=false, key=false,
        // every time — which is why the canvas uses global Carbon hotkeys instead.
        // Typing needs a real key window, so the policy is flipped for exactly as
        // long as the field is open and restored the moment it closes.
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        makeKeyAndOrderFront(nil)
        makeFirstResponder(field)

        // Activation can land a runloop turn late; check after it has settled.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            guard let self = self else { return }
            if !self.isKeyWindow {
                NSApp.activate(ignoringOtherApps: true)
                self.makeKeyAndOrderFront(nil)
                self.makeFirstResponder(self.field)
            }
            NSLog("Overlay: chat key=\(self.isKeyWindow) policy=regular")
        }
    }

    /// Always hand the Dock slot back, whichever way the panel was dismissed.
    private func restorePolicy() {
        NSApp.setActivationPolicy(.accessory)
    }

    override func close() {
        restorePolicy()
        super.close()
    }

    @objc private func submit() {
        let text = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { onCancel(); close(); return }
        onSubmit(text)
        close()
    }

    /// Esc cancels. Without this the field swallows it and the panel is a trap —
    /// the same mistake as draw mode's first version.
    func control(_ control: NSControl, textView: NSTextView,
                 doCommandBy selector: Selector) -> Bool {
        if selector == #selector(NSResponder.cancelOperation(_:)) {
            onCancel(); close(); return true
        }
        return false
    }
}
