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
public enum ObjectKind: String, Codable, Sendable, CaseIterable {
    case ink, line, arrow, box, highlight, spotlight, label, callout, sticker

    /// Kinds whose rectangle is defined by two opposite corners.
    public var isRectangular: Bool {
        self == .box || self == .highlight || self == .spotlight
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
        case .box, .highlight, .spotlight:          return 2
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

    public init(id: String = UUID().uuidString,
                kind: ObjectKind = .ink,
                points: [CGPoint],
                colorHex: String = Hex.palette[0],
                width: Double = 3,
                actor: String = "human:esa",
                lifetime: Lifetime = .persistent,
                created: Double = Date().timeIntervalSince1970,
                anchor: OverlayAnchor = .screen,
                text: String? = nil) {
        self.id = id; self.kind = kind; self.points = points
        self.colorHex = colorHex; self.width = width; self.actor = actor
        self.lifetime = lifetime; self.created = created; self.anchor = anchor
        self.text = text
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
            text: text)

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
