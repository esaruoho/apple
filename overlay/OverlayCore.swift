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

/// P0 ships exactly one object kind — ink. P1 adds arrow / box / highlight /
/// spotlight / label / sticker / callout, which is why this is an enum from day one
/// rather than an implicit assumption that every object is a stroke.
public enum ObjectKind: String, Codable, Sendable {
    case ink
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

    public init(id: String = UUID().uuidString,
                kind: ObjectKind = .ink,
                points: [CGPoint],
                colorHex: String = Hex.palette[0],
                width: Double = 3,
                actor: String = "human:esa",
                lifetime: Lifetime = .persistent,
                created: Double = Date().timeIntervalSince1970,
                anchor: OverlayAnchor = .screen) {
        self.id = id; self.kind = kind; self.points = points
        self.colorHex = colorHex; self.width = width; self.actor = actor
        self.lifetime = lifetime; self.created = created; self.anchor = anchor
    }

    public var bounds: CGRect { Geometry.bounds(points) }

    /// The rect an agent should be shown for this object: the ink's box plus enough
    /// margin that whatever was circled is actually inside the crop.
    public func cropRect(in surface: CGRect, pad: CGFloat = 24) -> CGRect {
        Geometry.padded(bounds, by: pad, clampedTo: surface)
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

    /// Drop objects whose lifetime has run out. `.ephemeral` is the only TTL P0 can
    /// evaluate from time alone; the anchor-dependent ones land in P2/P4.
    public func expire(now: Double, ephemeralSeconds: Double = 5) {
        objects.removeAll { $0.lifetime == .ephemeral && now - $0.created > ephemeralSeconds }
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
    public static var session: URL { store.appendingPathComponent("session.json") }
}
