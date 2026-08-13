// OverlayCore — the platform-neutral core of the spatial overlay.
//
// Deliberately contains NO AppKit and NO window/pixel assumptions. Per the plan
// (wiki/operations/spatial-overlay-plan.md §2) the core knows only:
//
//     surface · region · object · anchor · actor · lifetime · provenance
//
// An AppKit adapter (Overlay.swift) resolves those into NSPanels and pixels. Keeping
// the split honest now is what lets P2 add window anchors and P4 add a Fleet peer's
// screen without rewriting the semantics.
//
// Everything here is pure: same input → same output, no I/O except the explicit
// save/load on OverlayStore. That is what makes overlay-tests.swift possible.

import Foundation
import CoreGraphics

// ─────────────────────────────── anchors ───────────────────────────────

/// What an object is pinned to. The resolver chain degrades left-to-right: an
/// `.element` anchor that can no longer be found falls back to its `.window`, and a
/// window that has closed falls back to `.display`.
public enum OverlayAnchorKind: String, Codable, Sendable {
    case screen     // absolute on this display, this Space
    case display    // absolute on a named display, any Space
    case window     // relative to another app's window  (P2)
    case element    // relative to an AX element         (P4)
    case region     // relative to a Vision-detected region (P4)
}

/// A rectangle in 0…1 units of some parent surface. Never pixels — this is what
/// survives window moves, resizes, resolution changes and display swaps.
public struct NormRect: Codable, Equatable, Sendable {
    public var x: Double, y: Double, w: Double, h: Double
    public init(x: Double, y: Double, w: Double, h: Double) {
        self.x = x; self.y = y; self.w = w; self.h = h
    }
}

public struct OverlayAnchor: Codable, Equatable, Sendable {
    public var type: OverlayAnchorKind
    /// Display identity — `NSScreen.localizedName` in the AppKit adapter.
    public var display: String?
    /// Bundle identifier of the owning app, for `.window` / `.element`.
    public var app: String?
    public var windowTitle: String?
    public var windowNumber: Int?
    /// Where inside the parent surface this sits, normalized.
    public var rel: NormRect?

    public init(type: OverlayAnchorKind = .screen,
                display: String? = nil,
                app: String? = nil,
                windowTitle: String? = nil,
                windowNumber: Int? = nil,
                rel: NormRect? = nil) {
        self.type = type; self.display = display; self.app = app
        self.windowTitle = windowTitle; self.windowNumber = windowNumber; self.rel = rel
    }

    public static let screen = OverlayAnchor(type: .screen)
}

/// How long an object lives. Agents get TTLs so they cannot litter the screen
/// forever; human ink defaults to `.persistent`.
public enum Lifetime: String, Codable, Sendable {
    case ephemeral   // seconds
    case session     // until the app quits
    case space       // until explicitly removed
    case window      // dies with its anchor window
    case persistent  // stored indefinitely
}

// ─────────────────────────────── geometry ───────────────────────────────

public enum Geometry {

    /// Bounding box of a point list. Empty list → `.null` (not `.zero`, so callers
    /// can distinguish "no points" from "a zero-size point at the origin").
    public static func bounds(_ points: [CGPoint]) -> CGRect {
        guard let first = points.first else { return .null }
        var minX = first.x, maxX = first.x, minY = first.y, maxY = first.y
        for p in points.dropFirst() {
            minX = min(minX, p.x); maxX = max(maxX, p.x)
            minY = min(minY, p.y); maxY = max(maxY, p.y)
        }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    /// Absolute point → 0…1 of `parent`. A zero-width or zero-height parent yields 0
    /// on that axis rather than a NaN, so a degenerate window can't poison the store.
    public static func normalize(_ p: CGPoint, in parent: CGRect) -> CGPoint {
        CGPoint(x: parent.width  == 0 ? 0 : (p.x - parent.minX) / parent.width,
                y: parent.height == 0 ? 0 : (p.y - parent.minY) / parent.height)
    }

    public static func denormalize(_ p: CGPoint, in parent: CGRect) -> CGPoint {
        CGPoint(x: parent.minX + p.x * parent.width,
                y: parent.minY + p.y * parent.height)
    }

    public static func normalize(_ r: CGRect, in parent: CGRect) -> NormRect {
        let o = normalize(r.origin, in: parent)
        return NormRect(x: Double(o.x),
                        y: Double(o.y),
                        w: parent.width  == 0 ? 0 : Double(r.width  / parent.width),
                        h: parent.height == 0 ? 0 : Double(r.height / parent.height))
    }

    public static func denormalize(_ n: NormRect, in parent: CGRect) -> CGRect {
        CGRect(x: parent.minX + CGFloat(n.x) * parent.width,
               y: parent.minY + CGFloat(n.y) * parent.height,
               width:  CGFloat(n.w) * parent.width,
               height: CGFloat(n.h) * parent.height)
    }

    /// Grow a rect by `pad` on every side, then clip it to `limit`. This is how a
    /// stroke's bounding box becomes a *crop* rect — the seam P1 hands to the model.
    public static func padded(_ r: CGRect, by pad: CGFloat, clampedTo limit: CGRect) -> CGRect {
        guard !r.isNull else { return .null }
        return r.insetBy(dx: -pad, dy: -pad).intersection(limit)
    }

    /// Drop points closer than `minDistance` to the previous kept point. Trackpads
    /// emit far more samples than the ink needs, and every one of them would be
    /// serialized to disk and re-sent to an agent otherwise.
    public static func decimate(_ points: [CGPoint], minDistance: CGFloat) -> [CGPoint] {
        guard let first = points.first, minDistance > 0 else { return points }
        var out = [first]
        for p in points.dropFirst() {
            let last = out[out.count - 1]
            if hypot(p.x - last.x, p.y - last.y) >= minDistance { out.append(p) }
        }
        // The final sample is where the pointer actually stopped; keep it even if it
        // fell inside the threshold. The guard is on the INPUT count, not the output:
        // a two-point flick shorter than minDistance would otherwise collapse to one
        // point, and a one-point stroke draws nothing at all.
        if points.count > 1, let last = points.last, out[out.count - 1] != last {
            out.append(last)
        }
        return out
    }
}

// ─────────────────────────────── colors ───────────────────────────────

/// Colors travel as hex strings so the store stays platform-neutral (an NSColor
/// would not survive the trip to a Fleet peer or a JSON inbox).
public enum Hex {
    /// `#RRGGBB` or `#RRGGBBAA`, with or without the `#`. Returns nil if malformed —
    /// callers substitute a default rather than crashing on agent-supplied input.
    public static func parse(_ s: String) -> (r: Double, g: Double, b: Double, a: Double)? {
        var t = s.hasPrefix("#") ? String(s.dropFirst()) : s
        t = t.uppercased()
        guard t.count == 6 || t.count == 8, t.allSatisfy({ $0.isHexDigit }) else { return nil }
        guard let v = UInt32(t, radix: 16) else { return nil }
        if t.count == 6 {
            return (Double((v >> 16) & 0xFF) / 255, Double((v >> 8) & 0xFF) / 255,
                    Double(v & 0xFF) / 255, 1.0)
        }
        return (Double((v >> 24) & 0xFF) / 255, Double((v >> 16) & 0xFF) / 255,
                Double((v >> 8) & 0xFF) / 255, Double(v & 0xFF) / 255)
    }

    /// The P0 palette, bound to number keys 1…6 in draw mode.
    public static let palette = ["#FF3B30", "#FFCC00", "#34C759",
                                 "#0A84FF", "#FF2D55", "#FFFFFF"]
}

// ─────────────────────────────── objects ───────────────────────────────

/// The vocabulary an agent has for pointing at things.
///
/// `points` means something different per kind, and that meaning is the contract:
///
///   ink        a polyline — every point
///   line       [tail, head]
///   arrow      [tail, head]      — drawn with a head at points[1]
///   box        [cornerA, cornerB] — outlined
///   highlight  [cornerA, cornerB] — translucent marker fill
///   spotlight  [cornerA, cornerB] — everything OUTSIDE is dimmed
///   label      [position]         — a text chip
///   callout    [target, chip]     — a text chip with a leader line to the target
///   sticker    [position]         — `text` drawn large (emoji works)
///   image      [cornerA, cornerB] — a PNG drawn INTO the rect (`imagePath`).
///                                   This is the generated half of the loop: draw a
///                                   box, get a picture back in the box.
public enum ObjectKind: String, Codable, Sendable, CaseIterable {
    case ink, line, arrow, box, highlight, spotlight, label, callout, sticker, image

    /// Kinds whose rectangle is defined by two opposite corners.
    public var isRectangular: Bool {
        self == .box || self == .highlight || self == .spotlight || self == .image
    }

    /// Kinds that carry text and are meaningless without it.
    public var needsText: Bool {
        self == .label || self == .callout || self == .sticker
    }

    /// How many points the kind requires to render at all.
    public var minimumPoints: Int {
        switch self {
        case .ink:                                  return 1
        case .label, .sticker:                      return 1
        case .line, .arrow, .callout:               return 2
        case .box, .highlight, .spotlight, .image:  return 2
        }
    }
}

/// One thing on the blackboard.
public struct OverlayObject: Codable, Equatable, Sendable {
    public var id: String
    public var kind: ObjectKind
    /// Absolute points in the *canvas surface's* coordinate space. `anchor.rel`
    /// carries the normalized form once the object is pinned to something (P2).
    public var points: [CGPoint]
    public var colorHex: String
    public var width: Double
    /// Provenance: `human:esa`, `agent:fm`, `agent:claude`, … Never a bare boolean.
    public var actor: String
    public var lifetime: Lifetime
    public var created: Double
    public var anchor: OverlayAnchor
    /// Label / callout / sticker content. Optional so P0's files still decode.
    public var text: String?
    /// For `.image`: an absolute path to the PNG rendered inside the rect.
    public var imagePath: String?
    /// Set when the mark is attached to another app's window rather than the screen.
    /// The binding is durable (selectors + normalized rect); the resolution is not.
    public var binding: WindowBinding?
    public var resolution: Resolution?

    public init(id: String = UUID().uuidString,
                kind: ObjectKind = .ink,
                points: [CGPoint],
                colorHex: String = Hex.palette[0],
                width: Double = 3,
                actor: String = "human:esa",
                lifetime: Lifetime = .persistent,
                created: Double = Date().timeIntervalSince1970,
                anchor: OverlayAnchor = .screen,
                text: String? = nil,
                imagePath: String? = nil,
                binding: WindowBinding? = nil,
                resolution: Resolution? = nil) {
        self.id = id; self.kind = kind; self.points = points
        self.colorHex = colorHex; self.width = width; self.actor = actor
        self.lifetime = lifetime; self.created = created; self.anchor = anchor
        self.text = text; self.imagePath = imagePath
        self.binding = binding; self.resolution = resolution
    }

    public var bounds: CGRect { Geometry.bounds(points) }

    /// The rectangle a two-corner kind describes. Corners may arrive in any order —
    /// an agent saying "from (500,400) to (200,100)" means the same rect as the
    /// reverse, so this normalises rather than producing a negative size.
    public var rect: CGRect {
        guard points.count >= 2 else { return bounds }
        return Geometry.bounds([points[0], points[1]])
    }

    /// Enough points, and text where text is mandatory. Agent-supplied objects are
    /// checked against this before they are allowed onto the screen — a `callout`
    /// with one point would otherwise render as an invisible nothing.
    public var isRenderable: Bool {
        guard points.count >= kind.minimumPoints else { return false }
        if kind.needsText, (text ?? "").isEmpty { return false }
        // An image object with no file is an empty frame — worse than nothing.
        if kind == .image, (imagePath ?? "").isEmpty { return false }
        return true
    }

    /// The rect an agent should be shown for this object: the ink's box plus enough
    /// margin that whatever was circled is actually inside the crop.
    public func cropRect(in surface: CGRect, pad: CGFloat = 24) -> CGRect {
        Geometry.padded(bounds, by: pad, clampedTo: surface)
    }
}

// ─────────────────────────────── shape recognition ───────────────────────────────

/// What a freehand stroke was probably meant to be.
///
/// This is the bridge from "Esa scribbled something" to "there is a REGION here that a
/// model should look at". Drawing a rough square around part of a whiteboard is the
/// most natural way to say *this bit* — recognising it turns the ink into a crop rect
/// with an intent attached, instead of a decorative squiggle.
public enum ShapeGuess: String, Codable, Sendable {
    case rectangle, ellipse, line, arrow, freehand
}

public struct ShapeResult: Equatable, Sendable {
    public let shape: ShapeGuess
    /// 0…1. Below ~0.6 the caller should treat the stroke as freehand and not
    /// silently replace what the human actually drew.
    public let confidence: Double
    public let rect: CGRect
}

public enum ShapeDetect {

    /// Classify a stroke. Pure geometry — no model, no training, no network.
    ///
    /// The tests are deliberately cheap and in this order:
    ///   1. too few points        → freehand
    ///   2. endpoints far apart   → line-ish (straight?) else freehand
    ///   3. closed, and the path length matches the bounding box perimeter → rectangle
    ///   4. closed, and it matches the inscribed ellipse's circumference   → ellipse
    public static func classify(_ points: [CGPoint],
                                closeTolerance: CGFloat = 0.22) -> ShapeResult {
        let box = Geometry.bounds(points)
        guard points.count >= 4, !box.isNull else {
            return ShapeResult(shape: .freehand, confidence: 0, rect: box)
        }

        let diagonal = hypot(box.width, box.height)
        guard diagonal > 1 else {
            return ShapeResult(shape: .freehand, confidence: 0, rect: box)
        }

        let gap = hypot(points[0].x - points[points.count - 1].x,
                        points[0].y - points[points.count - 1].y)
        let closed = gap <= diagonal * closeTolerance

        let length = pathLength(points)

        if !closed {
            // A straight line's path length equals the distance between its ends.
            let span = hypot(points[points.count - 1].x - points[0].x,
                             points[points.count - 1].y - points[0].y)
            let straightness = span == 0 ? 0 : min(1, span / max(length, 0.0001))
            if straightness > 0.93 {
                return ShapeResult(shape: .line, confidence: straightness, rect: box)
            }
            return ShapeResult(shape: .freehand, confidence: 1 - straightness, rect: box)
        }

        // Closed. Compare the traced length against the two candidate ideals.
        let perimeter = 2 * (box.width + box.height)
        // Ramanujan's approximation — exact enough at these scales and cheap.
        let a = box.width / 2, b = box.height / 2
        let h = (a + b) == 0 ? 0 : pow(a - b, 2) / pow(a + b, 2)
        let circumference = Double.pi * Double(a + b) * (1 + 3 * Double(h) / (10 + (4 - 3 * Double(h)).squareRoot()))

        let rectError = perimeter == 0 ? 1 : abs(length - Double(perimeter)) / Double(perimeter)
        let ellipseError = circumference == 0 ? 1 : abs(length - circumference) / circumference

        // A very thin closed shape is a scribble, not a square.
        let aspect = min(box.width, box.height) / max(box.width, box.height)
        guard aspect > 0.06 else {
            return ShapeResult(shape: .freehand, confidence: 0, rect: box)
        }

        let bestError = min(rectError, ellipseError)
        guard bestError < 0.35 else {
            return ShapeResult(shape: .freehand, confidence: 1 - min(1, bestError), rect: box)
        }
        return ShapeResult(shape: rectError <= ellipseError ? .rectangle : .ellipse,
                           confidence: max(0, 1 - bestError / 0.35),
                           rect: box)
    }

    public static func pathLength(_ points: [CGPoint]) -> Double {
        guard points.count > 1 else { return 0 }
        var total = 0.0
        for i in 1..<points.count {
            total += Double(hypot(points[i].x - points[i - 1].x,
                                  points[i].y - points[i - 1].y))
        }
        return total
    }
}

// ─────────────────────────────── the agent API ───────────────────────────────

/// One posted object, as an agent writes it into `~/.overlay/inbox/*.json`.
///
/// Deliberately forgiving in what it accepts and strict in what it produces: an agent
/// may give absolute pixels (`rect` / `at` / `points`) or normalized 0…1 (`rel`), and
/// `resolve(in:)` turns any of them into one validated OverlayObject. Anything the app
/// cannot render is rejected here rather than painted as an invisible artefact.
public struct PostRequest: Decodable, Sendable {
    /// Held as a raw string, not an ObjectKind, so a typo produces "unknown kind
    /// 'hilight' — expected one of …" instead of an opaque DecodingError.
    public var kind: String?
    /// Normalized 0…1 of the target surface — the form an agent should prefer, since
    /// it needs to know nothing about the display's pixel size.
    public var rel: NormRect?
    /// Absolute [x, y, w, h].
    public var rect: [Double]?
    /// Absolute single position [x, y] — for label / sticker.
    public var at: [Double]?
    /// Absolute polyline, for ink and for arrows that want an exact tail and head.
    public var points: [[Double]]?
    public var text: String?
    public var imagePath: String?
    public var color: String?
    public var width: Double?
    public var actor: String?
    public var ttl: String?
    public var display: String?

    public enum PostError: Error, CustomStringConvertible, Equatable {
        case unknownKind(String)
        case noGeometry
        case missingText(ObjectKind)
        case badColor(String)
        case badTTL(String)
        case missingImage
        case notRenderable(ObjectKind)

        public var description: String {
            switch self {
            case .unknownKind(let k):
                return "unknown kind '\(k)' — expected one of "
                     + ObjectKind.allCases.map(\.rawValue).joined(separator: ", ")
            case .noGeometry:
                return "no geometry: give one of rel, rect, at or points"
            case .missingText(let k):  return "kind '\(k.rawValue)' requires text"
            case .badColor(let c):     return "colour '\(c)' is not #RRGGBB or #RRGGBBAA"
            case .missingImage:
                return "kind 'image' requires imagePath (an absolute path to a PNG)"
            case .badTTL(let t):
                return "unknown ttl '\(t)' — expected one of ephemeral, session, "
                     + "space, window, persistent"
            case .notRenderable(let k):
                return "not enough points for kind '\(k.rawValue)'"
            }
        }
    }

    /// Turn the request into a real object positioned on `surface`.
    public func resolve(in surface: CGRect,
                        now: Double = Date().timeIntervalSince1970) throws -> OverlayObject {
        let kind: ObjectKind
        if let raw = self.kind {
            guard let k = ObjectKind(rawValue: raw) else { throw PostError.unknownKind(raw) }
            kind = k
        } else {
            kind = .box
        }

        let lifetime: Lifetime
        if let raw = ttl {
            guard let l = Lifetime(rawValue: raw) else { throw PostError.badTTL(raw) }
            lifetime = l
        } else {
            // Agent marks default to .session, not .persistent: an agent that forgets
            // to clean up should not leave ink on the desktop forever.
            lifetime = .session
        }

        if let color = color, Hex.parse(color) == nil { throw PostError.badColor(color) }
        if kind.needsText, (text ?? "").isEmpty { throw PostError.missingText(kind) }
        if kind == .image, (imagePath ?? "").isEmpty { throw PostError.missingImage }

        var resolved: [CGPoint] = []
        if let points = points, !points.isEmpty {
            resolved = points.compactMap { p in
                p.count >= 2 ? CGPoint(x: p[0], y: p[1]) : nil
            }
        } else if let rel = rel {
            let r = Geometry.denormalize(rel, in: surface)
            resolved = corners(of: r, kind: kind)
        } else if let rect = rect, rect.count >= 4 {
            let r = CGRect(x: rect[0], y: rect[1], width: rect[2], height: rect[3])
            resolved = corners(of: r, kind: kind)
        } else if let at = at, at.count >= 2 {
            resolved = [CGPoint(x: at[0], y: at[1])]
        } else {
            throw PostError.noGeometry
        }

        let object = OverlayObject(
            kind: kind,
            points: resolved,
            colorHex: color ?? Hex.palette[3],       // agent default: blue, not human red
            width: width ?? 3,
            actor: actor ?? "agent:unknown",
            lifetime: lifetime,
            created: now,
            anchor: OverlayAnchor(type: .screen, display: display),
            text: text,
            imagePath: imagePath)

        guard object.isRenderable else { throw PostError.notRenderable(kind) }
        return object
    }

    /// A rect given for a single-point kind collapses to its centre, so `label` and
    /// `sticker` can be posted with the same `rel` an agent used for a `box`.
    private func corners(of r: CGRect, kind: ObjectKind) -> [CGPoint] {
        if kind == .label || kind == .sticker {
            return [CGPoint(x: r.midX, y: r.midY)]
        }
        if kind == .callout {
            // Target the rect's centre; float the chip above its top edge.
            return [CGPoint(x: r.midX, y: r.midY),
                    CGPoint(x: r.midX, y: r.maxY + 40)]
        }
        if kind == .ink || kind == .line || kind == .arrow {
            return [CGPoint(x: r.minX, y: r.minY), CGPoint(x: r.maxX, y: r.maxY)]
        }
        return [CGPoint(x: r.minX, y: r.minY), CGPoint(x: r.maxX, y: r.maxY)]
    }

    /// Decode one inbox file. Accepts either a single object or an array of them, so
    /// an agent can drop a whole annotation set atomically.
    public static func decodeBatch(_ data: Data) throws -> [PostRequest] {
        let decoder = JSONDecoder()
        if let one = try? decoder.decode(PostRequest.self, from: data) { return [one] }
        return try decoder.decode([PostRequest].self, from: data)
    }
}

// ─────────────────────────────── store ───────────────────────────────

/// One canvas' worth of objects, plus undo. Deliberately a plain value-semantics
/// holder with explicit save/load — no observers, no didSet side effects, so the
/// tests can drive it without a run loop.
public final class OverlayStore {
    public private(set) var objects: [OverlayObject] = []
    private var redoStack: [OverlayObject] = []

    public init(objects: [OverlayObject] = []) { self.objects = objects }

    public func add(_ o: OverlayObject) {
        objects.append(o)
        // A new mark invalidates the redo branch, exactly like a text editor.
        redoStack.removeAll()
    }

    @discardableResult
    public func undo() -> Bool {
        guard let last = objects.popLast() else { return false }
        redoStack.append(last)
        return true
    }

    @discardableResult
    public func redo() -> Bool {
        guard let last = redoStack.popLast() else { return false }
        objects.append(last)
        return true
    }

    public func clear() {
        redoStack.append(contentsOf: objects.reversed())
        objects.removeAll()
    }

    public func remove(id: String) {
        objects.removeAll { $0.id == id }
    }

    /// Drop objects whose lifetime has run out, returning how many went. `.ephemeral`
    /// is the only TTL that time alone can evaluate; the anchor-dependent ones land
    /// in P2/P4. The count is what lets the caller skip a redraw when nothing changed.
    @discardableResult
    public func expire(now: Double, ephemeralSeconds: Double = 5) -> Int {
        let before = objects.count
        objects.removeAll { $0.lifetime == .ephemeral && now - $0.created > ephemeralSeconds }
        return before - objects.count
    }

    // JSON is the wire format, the disk format and the agent API — one shape, so an
    // agent posting an object and the app saving one cannot drift apart.
    private static func encoder() -> JSONEncoder {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }

    public func encoded() throws -> Data { try Self.encoder().encode(objects) }

    public static func decode(_ data: Data) throws -> [OverlayObject] {
        try JSONDecoder().decode([OverlayObject].self, from: data)
    }

    public func save(to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        try encoded().write(to: url, options: .atomic)
    }

    public static func load(from url: URL) throws -> OverlayStore {
        OverlayStore(objects: try decode(try Data(contentsOf: url)))
    }
}

// ─────────────────────────────── mode ───────────────────────────────

/// The one bit of state that decides whether the Mac is usable.
///
/// `passthrough` — the overlay is invisible to the pointer; clicks land in Safari.
/// `draw`        — the overlay eats the pointer and you are marking up the screen.
public enum OverlayMode: String, Codable, Sendable {
    case passthrough, draw

    public var ignoresMouseEvents: Bool { self == .passthrough }
    public var toggled: OverlayMode { self == .draw ? .passthrough : .draw }
}

/// Where the overlay keeps its state. `~/.overlay/` rather than a sandboxed
/// container so `bin/overlay` (and, from P1, any agent) can read and write it.
public enum OverlayPaths {
    public static var root: URL {
        URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".overlay")
    }
    public static var store: URL { root.appendingPathComponent("store") }
    public static var inbox: URL { root.appendingPathComponent("inbox") }
    /// Screen crops taken by "ask", kept so an answer can be traced to a picture.
    public static var asks: URL { root.appendingPathComponent("asks") }
    public static var session: URL { store.appendingPathComponent("session.json") }
}

// ─────────────────────── depth planes ───────────────────────

/// Who owns a mark, expressed as height above the screen.
///
/// From the "Why Overlay Matters" essay §14: depth communicates ownership without
/// turning the desktop into a game. Screen content is plane 0 and is not ours; the
/// human's own marks sit just above it; an agent's proposals sit above those; a
/// warning sits highest of all. Rendered with shadow, scale and draw order — not
/// with louder colours, which is the trap the source thread warned about.
public enum DepthPlane: Int, Comparable, Sendable {
    case screen = 0     // not drawn by us — the thing being annotated
    case human  = 1     // ink, boxes, the user's own selections
    case agent  = 2     // answers, generated images, agent annotations
    case alert  = 3     // warnings, unresolved anchors, things needing attention

    public static func < (a: DepthPlane, b: DepthPlane) -> Bool {
        a.rawValue < b.rawValue
    }

    /// Plane from provenance and intent. Colour is consulted only for the alert
    /// case, because "this needs attention" is the one distinction the actor string
    /// does not already carry.
    public static func of(actor: String, colorHex: String = "", alert: Bool = false)
        -> DepthPlane {
        if alert || colorHex.uppercased() == "#FF9F0A" { return .alert }
        if actor.hasPrefix("human:") { return .human }
        if actor.lowercased().contains("security") { return .alert }
        return .agent
    }

    /// How far above the screen this plane reads. Higher planes cast a longer, softer
    /// shadow and sit fractionally larger — the cues the eye already uses for height.
    public var shadow: (radius: Double, offsetY: Double, alpha: Double) {
        switch self {
        case .screen: return (0, 0, 0)
        case .human:  return (4, -1, 0.30)
        case .agent:  return (10, -3, 0.42)
        case .alert:  return (18, -5, 0.55)
        }
    }

    /// Very slight — enough to read as nearer, not enough to look like a mistake.
    public var scale: Double {
        switch self {
        case .screen: return 1.0
        case .human:  return 1.0
        case .agent:  return 1.01
        case .alert:  return 1.03
        }
    }
}

// ─────────────────────── motion ───────────────────────

/// Easing and arrival timing.
///
/// From the essay §13 and §16: an element that simply appears tells the eye nothing,
/// whereas a marker that travels to its target says *actor A is referring to object
/// B*. And the model does not need to think at 60fps for its pointer to move at
/// 60fps — it emits a semantic event and the renderer produces the frames.
public enum Motion {

    /// The essay's own figure, and a good one: long enough to be followed by eye,
    /// short enough not to be in the way.
    public static let arrivalSeconds: Double = 0.28
    /// A departing object gets slightly longer, so a disappearance is never a glitch.
    public static let departureSeconds: Double = 0.45

    /// Decelerating. Fast out of the gate, settles gently — reads as a thing coming
    /// to rest rather than a value being interpolated.
    public static func easeOut(_ t: Double) -> Double {
        let clamped = min(max(t, 0), 1)
        return 1 - pow(1 - clamped, 3)
    }

    /// Overshoots slightly and settles back, which is what physical arrival looks
    /// like. Used for a marker landing on its target.
    public static func easeOutBack(_ t: Double, overshoot: Double = 1.7) -> Double {
        let clamped = min(max(t, 0), 1)
        let c = clamped - 1
        return 1 + (overshoot + 1) * pow(c, 3) + overshoot * pow(c, 2)
    }

    /// 0…1 of the way through an arrival that began at `created`.
    public static func arrival(created: Double, now: Double,
                               duration: Double = arrivalSeconds) -> Double {
        guard duration > 0 else { return 1 }
        return min(max((now - created) / duration, 0), 1)
    }

    /// Interpolate a point along the travel from `from` to `to`.
    public static func lerp(_ from: CGPoint, _ to: CGPoint, _ t: Double) -> CGPoint {
        CGPoint(x: from.x + (to.x - from.x) * CGFloat(t),
                y: from.y + (to.y - from.y) * CGFloat(t))
    }

    /// How visible an ephemeral object should be as its lifetime runs out.
    ///
    /// A TTL object used to blink out of existence at the tick that collected it.
    /// Fading over the last stretch makes the lifetime itself perceptible — you can
    /// see a thing is temporary before it is gone.
    public static func fadeOut(created: Double, now: Double,
                               lifetime: Double, over: Double = 0.8) -> Double {
        let remaining = (created + lifetime) - now
        if remaining >= over { return 1 }
        if remaining <= 0 { return 0 }
        return easeOut(remaining / over)
    }
}

/// How firmly a mark is attached to what it refers to.
///
/// The anchoring work is not built yet, so today only two of these occur: everything
/// screen-anchored is `.firm`, and an image whose file has vanished is `.lost`. The
/// grammar exists now so that when window and AX anchors land, degradation is
/// already visible rather than silent — which is the whole point of the
/// Observation/Anchor/Resolution split.
public enum Attachment: String, Codable, Sendable {
    case firm         // resolved, confident
    case loosening    // resolution degrading — drawn dashed and dimmed
    case ambiguous    // more than one candidate — never silently guess
    case lost         // target gone

    public var opacity: Double {
        switch self {
        case .firm: return 1.0
        case .loosening: return 0.62
        case .ambiguous: return 0.7
        case .lost: return 0.4
        }
    }

    public var isDashed: Bool { self != .firm }
}

// ═══════════════════ Surface · Observation · Anchor · Resolution ═══════════════════
//
// The SDD's central argument, and it is right:
//
//     Historical observation is immutable. Anchor resolution is revisable.
//
// Three different things exist the moment someone circles a button, and conflating
// them is the failure mode that matters: an old observation silently changing meaning
// because a current anchor now resolves somewhere new.
//
//   Observation  what was actually seen, then. Evidence. Never edited.
//   Anchor       how we believe the intended thing can be found again. Selectors.
//   Resolution   what that anchor maps to NOW. Revisable, gradeable, possibly absent.
//
// None of this knows about NSScreen, CGWindowID or AXUIElement — those are runtime
// details of one resolver. What persists is selector semantics.

/// What kind of thing is being addressed. Only `.localDisplay` is implemented; the
/// rest exist so the persisted ontology is not "the Mac desktop" from day one.
/// Deliberately NOT eight adapters — one enum case each, no speculative machinery.
public enum SurfaceKind: String, Codable, Sendable {
    case localDisplay, window, captured, browser, remote, image, video
}

/// Identity of a surface, plus an epoch.
///
/// The epoch is the part people forget. Display arrangement, resolution and scale all
/// change; a geometry recorded under one arrangement is not comparable with one
/// recorded under another. Bumping the epoch makes that mismatch detectable instead
/// of silently wrong.
public struct SurfaceRef: Codable, Equatable, Sendable {
    public var kind: SurfaceKind
    public var id: String
    public var epoch: Int

    public init(kind: SurfaceKind = .localDisplay, id: String, epoch: Int = 0) {
        self.kind = kind; self.id = id; self.epoch = epoch
    }
}

/// One way of describing the intended target.
///
/// Flat rather than an enum with associated values, because this shape is the JSON
/// that agents write and read, and it matches the SDD's example verbatim. Several
/// selectors describe the SAME target — there is no universal UI identifier, so the
/// design is deliberately redundant.
public enum AnchorSelectorKind: String, Codable, Sendable {
    case accessibility          // app + role + name  — most semantic, least available
    case text                   // an exact quote, with context
    case windowFingerprint      // app + title (+ pid/number as runtime hints)
    case windowNormalizedRect   // 0…1 within a window
    case surfaceNormalizedRect  // 0…1 within the surface — the last resort
}

public struct AnchorSelector: Codable, Equatable, Sendable {
    public var kind: AnchorSelectorKind
    public var application: String?
    public var windowTitle: String?
    /// Runtime hints. Recorded for this-session speed, NEVER the durable identity —
    /// a window number is meaningless after a restart.
    public var windowNumber: Int?
    public var pid: Int?
    public var role: String?
    public var name: String?
    public var exact: String?
    public var context: String?
    public var rect: NormRect?

    public init(kind: AnchorSelectorKind, application: String? = nil, windowTitle: String? = nil,
                windowNumber: Int? = nil, pid: Int? = nil, role: String? = nil,
                name: String? = nil, exact: String? = nil, context: String? = nil,
                rect: NormRect? = nil) {
        self.kind = kind; self.application = application; self.windowTitle = windowTitle
        self.windowNumber = windowNumber; self.pid = pid; self.role = role
        self.name = name; self.exact = exact; self.context = context; self.rect = rect
    }

    /// Does this selector still mean anything after the owning process restarts?
    /// A window number does not. An app + title + role does.
    public var survivesRestart: Bool {
        switch kind {
        case .accessibility:         return application != nil && role != nil
        case .text:                  return !(exact ?? "").isEmpty
        case .windowFingerprint:     return application != nil
        case .windowNormalizedRect:  return false   // meaningless without its window
        case .surfaceNormalizedRect: return true    // survives, but says nothing semantic
        }
    }

    /// How much a match on this selector alone is worth.
    ///
    /// Weighted by SPECIFICITY, not by category. An app+title window fingerprint is
    /// more precise than a title substring, while an app-ONLY fingerprint is much
    /// less precise than either — all three share a kind, so ranking by kind alone
    /// sorted the broad one above the narrow one. Caught by the test that expected
    /// app+title to win.
    public var weight: Double {
        switch kind {
        case .accessibility:
            // role + name is a real semantic address; role alone is not.
            return (name?.isEmpty == false) ? 1.0 : 0.55
        case .windowFingerprint:
            let titled = (windowTitle?.isEmpty == false)
            return titled ? 0.85 : 0.5
        case .text:
            return 0.8
        case .windowNormalizedRect:  return 0.3
        case .surfaceNormalizedRect: return 0.1
        }
    }
}

/// How we believe the intended thing can be found again. Ordered strongest-first.
public struct SpatialAnchor: Codable, Equatable, Sendable {
    public var selectors: [AnchorSelector]

    public init(selectors: [AnchorSelector]) {
        self.selectors = selectors.sorted { $0.weight > $1.weight }
    }

    public var survivesRestart: Bool { selectors.contains { $0.survivesRestart } }
    public var best: AnchorSelector? { selectors.first }
}

/// What was actually seen, at one moment. Immutable evidence.
public struct Observation: Codable, Equatable, Sendable {
    public var id: String
    public var surface: SurfaceRef
    public var t: Double
    /// Where it was, in surface-normalized units — never raw pixels.
    public var rect: NormRect
    /// Path to the crop, and a digest of it. The digest is what lets a later approval
    /// prove it is talking about the same picture the human was shown.
    public var cropPath: String?
    public var cropDigest: String?
    public var ocr: String?

    public init(id: String = UUID().uuidString, surface: SurfaceRef, t: Double,
                rect: NormRect, cropPath: String? = nil, cropDigest: String? = nil,
                ocr: String? = nil) {
        self.id = id; self.surface = surface; self.t = t; self.rect = rect
        self.cropPath = cropPath; self.cropDigest = cropDigest; self.ocr = ocr
    }
}

/// The lifecycle of "can we still find it?".
public enum ResolutionState: String, Codable, Sendable {
    case unresolved, resolving
    case resolved, ambiguous, unavailable
    case stale, occluded, destroyed, reacquiring

    /// Is it safe to act on this? Only a single confident match is.
    /// Ambiguity fails closed — never act on a guess.
    public var actionable: Bool { self == .resolved }

    /// How it should look, connecting the epistemic state to the visual grammar.
    public var attachment: Attachment {
        switch self {
        case .resolved:                          return .firm
        case .stale, .occluded, .reacquiring:    return .loosening
        case .ambiguous:                         return .ambiguous
        case .unresolved, .resolving,
             .unavailable, .destroyed:           return .lost
        }
    }
}

public struct Resolution: Codable, Equatable, Sendable {
    public var state: ResolutionState
    /// Which selector actually matched, so a later reader can judge the quality.
    public var method: AnchorSelectorKind?
    public var confidence: Double
    public var rect: NormRect?
    public var surfaceEpoch: Int
    public var t: Double
    /// How many candidates matched. More than one is ambiguity, not a tie to break.
    public var candidates: Int
    /// A stable-ish description of the thing matched — "Safari|Settings" — so two
    /// resolutions can be compared by REFERENT rather than by pixels.
    public var targetID: String?

    public init(state: ResolutionState, method: AnchorSelectorKind? = nil,
                confidence: Double = 0, rect: NormRect? = nil,
                surfaceEpoch: Int = 0, t: Double = 0, candidates: Int = 0,
                targetID: String? = nil) {
        self.state = state; self.method = method; self.confidence = confidence
        self.rect = rect; self.surfaceEpoch = surfaceEpoch; self.t = t
        self.candidates = candidates; self.targetID = targetID
    }

    public static let unresolved = Resolution(state: .unresolved)

    /// Grade a resolver's candidate list. This is the one rule that keeps the system
    /// honest: zero is unavailable, one is resolved, more than one is AMBIGUOUS —
    /// never "pick the closest".
    public static func grade(candidates: Int, method: AnchorSelectorKind,
                             confidence: Double? = nil,
                             rect: NormRect?, surfaceEpoch: Int, t: Double,
                             targetID: String? = nil) -> Resolution {
        switch candidates {
        case 0:
            return Resolution(state: .unavailable, method: method, confidence: 0,
                              surfaceEpoch: surfaceEpoch, t: t, candidates: 0)
        case 1:
            return Resolution(state: .resolved, method: method,
                              confidence: confidence ?? method.weightForConfidence, rect: rect,
                              surfaceEpoch: surfaceEpoch, t: t, candidates: 1,
                              targetID: targetID)
        default:
            return Resolution(state: .ambiguous, method: method, confidence: 0,
                              rect: rect, surfaceEpoch: surfaceEpoch, t: t,
                              candidates: candidates)
        }
    }

    /// A resolution taken under a different surface arrangement is stale, whatever it
    /// said at the time — the coordinates are not comparable.
    public func staleness(againstEpoch current: Int) -> Resolution {
        guard surfaceEpoch != current, state == .resolved else { return self }
        var copy = self
        copy.state = .stale
        return copy
    }
}

private extension AnchorSelectorKind {
    /// Confidence for a single clean match, by how semantic the selector is.
    var weightForConfidence: Double {
        AnchorSelector(kind: self).weight
    }
}

/// A reference to something in a visual environment, usable with no annotation drawn.
///
/// This is the durable unit. Overlay produces and consumes these; it does not own the
/// concept — an agent, a mission or a transcript can hold one and resolve it later.
public struct SpatialReference: Codable, Equatable, Sendable {
    public var id: String
    public var surface: SurfaceRef
    public var observation: Observation
    public var anchor: SpatialAnchor
    public var resolution: Resolution
    public var actor: String
    public var createdAt: Double

    public init(id: String = UUID().uuidString, surface: SurfaceRef,
                observation: Observation, anchor: SpatialAnchor,
                resolution: Resolution = .unresolved,
                actor: String, createdAt: Double) {
        self.id = id; self.surface = surface; self.observation = observation
        self.anchor = anchor; self.resolution = resolution
        self.actor = actor; self.createdAt = createdAt
    }

    /// Re-resolving NEVER touches the observation. That is the whole doctrine, made
    /// mechanical: this returns a copy with a new resolution and identical evidence.
    public func resolved(_ new: Resolution) -> SpatialReference {
        var copy = self
        copy.resolution = new
        return copy
    }

    /// Safe to execute an action against? Requires a single confident match under the
    /// CURRENT surface arrangement.
    public func actionable(underEpoch epoch: Int, minConfidence: Double = 0.5) -> Bool {
        let checked = resolution.staleness(againstEpoch: epoch)
        return checked.state.actionable && checked.confidence >= minConfidence
    }
}

// ═══════════════════ window matching (pure) ═══════════════════
//
// The matching rules live here, with no CoreGraphics window API in sight, so they can
// be tested against a hand-built list instead of against whatever happens to be open.
// The adapter that actually calls CGWindowList is OverlayWindows.swift.

/// One window as the resolver sees it. Deliberately just facts, no handles.
public struct WindowDescriptor: Codable, Equatable, Sendable {
    public var pid: Int
    public var owner: String        // application name, e.g. "Safari"
    public var title: String
    public var number: Int          // CGWindowID — a runtime hint, never identity
    public var frame: CGRect        // TOP-LEFT space, as CGWindowList reports it
    public var layer: Int

    public init(pid: Int, owner: String, title: String, number: Int,
                frame: CGRect, layer: Int = 0) {
        self.pid = pid; self.owner = owner; self.title = title
        self.number = number; self.frame = frame; self.layer = layer
    }
}

/// Where a mark sits inside a window, and how to find that window again.
public struct WindowBinding: Codable, Equatable, Sendable {
    public var anchor: SpatialAnchor
    /// 0…1 within the window's frame. This is what survives a move or a resize.
    public var rel: NormRect

    public init(anchor: SpatialAnchor, rel: NormRect) {
        self.anchor = anchor; self.rel = rel
    }
}

public enum WindowMatcher {

    /// Windows a human could plausibly have meant: normal layer, real size.
    /// Filters out the menu bar, the Dock, wallpaper and our own overlay panels,
    /// which are on screen but are not things anyone points at.
    public static func addressable(_ windows: [WindowDescriptor],
                                   excludingOwner: String? = nil) -> [WindowDescriptor] {
        windows.filter { w in
            w.layer == 0
                && w.frame.width >= 80 && w.frame.height >= 60
                && w.owner != (excludingOwner ?? "\u{0}")
        }
    }

    /// Everything matching an anchor, strongest selector first.
    ///
    /// Returns ALL matches on purpose. The caller grades the count — one is resolved,
    /// several is ambiguous — because "pick the closest" is exactly the behaviour that
    /// makes a stale annotation quietly point at the wrong thing.
    public static func candidates(for anchor: SpatialAnchor,
                                  among windows: [WindowDescriptor])
        -> (matches: [WindowDescriptor], method: AnchorSelectorKind, weight: Double) {
        // A broader selector is a REACQUISITION aid, not a general fallback. It is
        // accepted only when it names exactly one window.
        //
        // Measured on a real desktop: minimising a window removes it from
        // CGWindowList (179 windows -> 178). The specific app+title selector then
        // finds nothing and, with a naive fallback, the app-only selector matched
        // all ten open Finder windows — reporting "ambiguous among 10" when the
        // truthful answer is "the window you meant is gone". Both are non-actionable,
        // but only one of them is useful to read.
        // The title the anchor was created against, if it had one. A broad selector
        // may only reacquire a window that still agrees with it — otherwise "the one
        // remaining Safari window" gets silently adopted as the one you meant, which
        // is the sibling-rebinding the acceptance criteria forbid outright.
        let recordedTitle = anchor.selectors
            .compactMap { $0.windowTitle }
            .first { !$0.isEmpty }

        for selector in anchor.selectors {
            let hits = windows.filter { matches(selector, $0) }
            guard hits.count == 1, let only = hits.first else { continue }

            let isBroad = (selector.windowTitle ?? "").isEmpty
            if isBroad, let recorded = recordedTitle,
               only.title.caseInsensitiveCompare(recorded) != .orderedSame {
                // One window of the right app, wrong title. Two very different things
                // look like this, and the window number tells them apart:
                //
                //   the SAME window, retitled (a browser navigated) — same number,
                //   so adopt it; the anchor is still pointing at the right thing.
                //
                //   a DIFFERENT window of the same app — different number, so refuse.
                //   Adopting it is the silent sibling-rebinding that makes a stale
                //   annotation quietly describe the wrong thing.
                //
                // The number is corroboration here, never identity: it is only ever
                // consulted to CONFIRM a match the selectors already found, and it is
                // meaningless after a restart, when the title check carries the case.
                let recordedNumber = anchor.selectors.compactMap { $0.windowNumber }.first
                guard let number = recordedNumber, number == only.number else { continue }
            }
            return (hits, selector.kind, selector.weight)
        }

        let best = anchor.best
        // Several matches on the MOST SPECIFIC selector is genuine ambiguity; several
        // only on a broad one, after the specific one found nothing, is absence.
        if let best = best, windows.filter({ matches(best, $0) }).count > 1 {
            let hits = windows.filter { matches(best, $0) }
            return (hits, best.kind, best.weight)
        }
        return ([], best?.kind ?? .windowFingerprint, best?.weight ?? 0)
    }

    /// Case-insensitive, and title is matched only when the selector carries one —
    /// a browser retitles itself constantly, so app-only is often the honest anchor.
    public static func matches(_ selector: AnchorSelector, _ w: WindowDescriptor) -> Bool {
        switch selector.kind {
        case .windowFingerprint, .accessibility:
            guard let app = selector.application else { return false }
            guard w.owner.caseInsensitiveCompare(app) == .orderedSame
                    || w.owner.lowercased().contains(app.lowercased()) else { return false }
            if let title = selector.windowTitle, !title.isEmpty {
                return w.title.caseInsensitiveCompare(title) == .orderedSame
            }
            return true
        case .text:
            guard let exact = selector.exact, !exact.isEmpty else { return false }
            return w.title.lowercased().contains(exact.lowercased())
        case .windowNormalizedRect, .surfaceNormalizedRect:
            return false        // geometry alone never identifies a window
        }
    }

    /// Build an anchor from a window the user just pointed at.
    ///
    /// Records app AND title as separate selectors rather than one compound key, so a
    /// retitled window still matches on the app, degrading instead of vanishing.
    public static func anchor(for w: WindowDescriptor) -> SpatialAnchor {
        var selectors = [AnchorSelector(kind: .windowFingerprint, application: w.owner,
                                  windowTitle: w.title, windowNumber: w.number, pid: w.pid)]
        if !w.title.isEmpty {
            selectors.append(AnchorSelector(kind: .text, exact: w.title, context: w.owner))
        }
        selectors.append(AnchorSelector(kind: .windowFingerprint, application: w.owner))
        return SpatialAnchor(selectors: selectors)
    }

    /// Absolute rect → 0…1 inside a window. The stored form.
    public static func bind(_ rect: CGRect, to window: CGRect) -> NormRect {
        Geometry.normalize(rect, in: window)
    }

    /// 0…1 inside a window → absolute rect. The resolved form.
    public static func place(_ rel: NormRect, in window: CGRect) -> CGRect {
        Geometry.denormalize(rel, in: window)
    }
}

// ═══════════════════ authority ═══════════════════
//
// The inbox accepted any JSON any local process wrote. Fine for a prototype, not an
// acceptable boundary once an agent can propose actions — so the envelope separates
// the four things that must never collapse into each other:
//
//     annotate  ·  propose an action  ·  approve  ·  execute
//
// Overlay captures and displays approval. It does NOT own authority, and it must not
// become its own shadow governance system: execution lives elsewhere, and this file
// deliberately contains no way to perform one.

public enum Capability: String, Codable, Sendable, CaseIterable {
    case observe          = "spatial.observe"
    case annotate         = "spatial.annotation.create"
    case dismiss          = "spatial.annotation.dismiss"
    case referenceCreate  = "spatial.reference.create"
    case referenceResolve = "spatial.reference.resolve"
    case actionPropose    = "spatial.action.propose"
    case approvalRequest  = "spatial.approval.request"

    /// Nothing here can execute anything. Stated as code so the boundary is not just
    /// a comment: an annotation capability can never widen into an execution one.
    public var permitsExecution: Bool { false }
}

public struct Scope: Codable, Equatable, Sendable {
    public var surface: String            // "local-display/*"
    public var kinds: [String]            // object kinds this actor may create
    public var maxLifetime: Lifetime

    public init(surface: String = "local-display/*",
                kinds: [String] = ObjectKind.allCases.map(\.rawValue),
                maxLifetime: Lifetime = .session) {
        self.surface = surface; self.kinds = kinds; self.maxLifetime = maxLifetime
    }

    public func allows(surface s: String) -> Bool {
        if surface.hasSuffix("/*") { return s.hasPrefix(String(surface.dropLast(1))) }
        return surface == s
    }
    public func allows(kind: ObjectKind) -> Bool { kinds.contains(kind.rawValue) }

    /// Lifetimes ordered by how long they litter the screen for.
    private static let rank: [Lifetime: Int] = [
        .ephemeral: 0, .window: 1, .session: 2, .space: 3, .persistent: 4]
    public func allows(lifetime: Lifetime) -> Bool {
        (Self.rank[lifetime] ?? 9) <= (Self.rank[maxLifetime] ?? 0)
    }
}

/// What an agent must wrap a request in.
public struct Envelope: Decodable, Sendable {
    public var actor: String
    public var capability: Capability
    public var scope: Scope?
    /// Unix seconds. An envelope with no expiry is refused — an unbounded grant is
    /// not a grant, it is an oversight.
    public var expiry: Double?
    public var request: [PostRequest]?

    public enum Denial: Error, CustomStringConvertible, Equatable {
        case noActor
        case expired(Double)
        case noExpiry
        case capabilityForbids(Capability, ObjectKind)
        case kindOutOfScope(ObjectKind)
        case lifetimeOutOfScope(Lifetime, Lifetime)
        case surfaceOutOfScope(String)
        case nothingRequested

        public var description: String {
            switch self {
            case .noActor:  return "envelope has no actor — every mark must be attributable"
            case .expired(let t): return "envelope expired at \(Int(t))"
            case .noExpiry: return "envelope has no expiry — an unbounded grant is refused"
            case .capabilityForbids(let c, let k):
                return "capability '\(c.rawValue)' does not permit creating a '\(k.rawValue)'"
            case .kindOutOfScope(let k): return "kind '\(k.rawValue)' is outside this scope"
            case .lifetimeOutOfScope(let want, let max):
                return "lifetime '\(want.rawValue)' exceeds the granted maximum "
                     + "'\(max.rawValue)'"
            case .surfaceOutOfScope(let s): return "surface '\(s)' is outside this scope"
            case .nothingRequested: return "envelope carries no request"
            }
        }
    }

    /// Check the envelope itself, then every object it wants to create.
    ///
    /// Returns the requests it is allowed to make. Anything refused is refused by
    /// name, because an agent that gets a silent no cannot correct itself.
    public func authorised(now: Double, surface: String = "local-display/main")
        throws -> [PostRequest] {
        guard !actor.isEmpty else { throw Denial.noActor }
        guard let expiry = expiry else { throw Denial.noExpiry }
        guard expiry > now else { throw Denial.expired(expiry) }

        let scope = self.scope ?? Scope()
        guard scope.allows(surface: surface) else { throw Denial.surfaceOutOfScope(surface) }

        guard let requests = request, !requests.isEmpty else { throw Denial.nothingRequested }
        guard capability == .annotate || capability == .actionPropose
                || capability == .referenceCreate else {
            throw Denial.capabilityForbids(capability, .ink)
        }

        for r in requests {
            let kind = ObjectKind(rawValue: r.kind ?? "box") ?? .box
            guard scope.allows(kind: kind) else { throw Denial.kindOutOfScope(kind) }
            let lifetime = Lifetime(rawValue: r.ttl ?? "") ?? .session
            guard scope.allows(lifetime: lifetime) else {
                throw Denial.lifetimeOutOfScope(lifetime, scope.maxLifetime)
            }
        }
        return requests
    }
}

// ═══════════════════ ActionIntent ═══════════════════
//
// The Envoy-specific experiment: approval bound to a RESOLVED TARGET rather than to a
// sentence. "Allow clicking Delete?" cannot express which Delete — the ambiguity was
// never in the verb.

public enum ProposedAction: String, Codable, Sendable {
    case click, type, drag, open, delete, submit, copy
}

public enum IntentState: String, Codable, Sendable {
    case proposed, approved, rejected, invalidated, executed, failed
}

public struct ActionIntent: Codable, Equatable, Sendable {
    public var id: String
    public var actor: String
    public var action: ProposedAction
    /// The thing itself, not a description of it.
    public var target: SpatialReference
    public var reason: String
    public var state: IntentState
    public var createdAt: Double

    /// Recorded at the moment of approval, and compared before execution. This is
    /// the whole mechanism: what the human actually saw and said yes to.
    public var approvedResolution: Resolution?
    public var approvedObservationDigest: String?
    public var approvedAt: Double?

    public init(id: String = UUID().uuidString, actor: String, action: ProposedAction,
                target: SpatialReference, reason: String,
                state: IntentState = .proposed, createdAt: Double) {
        self.id = id; self.actor = actor; self.action = action; self.target = target
        self.reason = reason; self.state = state; self.createdAt = createdAt
    }

    /// A human approves the thing they were shown, and what they were shown is pinned.
    public func approved(at t: Double) -> ActionIntent {
        var copy = self
        copy.state = .approved
        copy.approvedResolution = target.resolution
        copy.approvedObservationDigest = target.observation.cropDigest
        copy.approvedAt = t
        return copy
    }

    public func rejected() -> ActionIntent {
        var copy = self; copy.state = .rejected; return copy
    }

    /// May this execute, given how the target resolves RIGHT NOW?
    ///
    /// Fails closed on every count: not approved, not currently resolvable, the
    /// surface rearranged, the target moved somewhere else, or the picture the human
    /// approved is no longer the picture. A stale approval is not an approval.
    public func executable(against current: Resolution, epoch: Int,
                           currentDigest: String? = nil)
        -> (ok: Bool, reason: String) {
        guard state == .approved else { return (false, "not approved (\(state.rawValue))") }
        guard let approved = approvedResolution else { return (false, "no approved resolution") }
        guard current.state.actionable else {
            return (false, "target is \(current.state.rawValue), not resolved")
        }
        guard current.surfaceEpoch == epoch else {
            return (false, "the display arrangement changed since approval")
        }
        guard approved.surfaceEpoch == current.surfaceEpoch else {
            return (false, "approved under a different surface arrangement")
        }
        // Equivalence is about the REFERENT, not the pixels.
        //
        // The first version refused whenever the rectangle changed, which is wrong in
        // the most ordinary case there is: the same button moves because its window
        // moved. That is obviously still the same button, and invalidating on it
        // would make approval useless — every window drag would revoke consent.
        //
        // What must match is what the thing IS, not where it is:
        //   · it still resolves to the same target
        //   · by a selector at least as trustworthy as the one approved under
        //   · and the picture the human was shown has not materially changed
        //
        // Geometry is deliberately absent from this list. A window-relative rect is
        // already invariant under a move, and a screen-relative one is not evidence
        // of identity either way.
        if let approvedTarget = approved.targetID, let nowTarget = current.targetID,
           approvedTarget != nowTarget {
            return (false, "it resolves to a different thing now (\(approvedTarget) "
                         + "→ \(nowTarget)) — re-approve")
        }
        if current.confidence < approved.confidence - 0.2 {
            return (false, "the match is weaker than the one approved "
                         + "(\(approved.confidence) → \(current.confidence))")
        }
        if let approvedDigest = approvedObservationDigest, let now = currentDigest,
           approvedDigest != now {
            return (false, "what is there now is not what was approved")
        }
        return (true, "same referent, still confidently resolved")
    }

    /// Same place, within a tolerance that allows for sub-pixel jitter but not for
    /// the control having moved.
    static func same(_ a: NormRect, _ b: NormRect, tolerance: Double = 0.01) -> Bool {
        abs(a.x - b.x) < tolerance && abs(a.y - b.y) < tolerance
            && abs(a.w - b.w) < tolerance && abs(a.h - b.h) < tolerance
    }
}
