// Headless tests for OverlayCore — no GUI, no window server, no permissions.
// Compiled + run by overlay/build.sh, which refuses to build the app if any fail.
// Per feedback_test_renderers_headlessly: every pure-logic path gets an assertion
// BEFORE the thing is claimed to work, and every bug found later adds a case here.

import Foundation
import CoreGraphics

var failed = 0, passed = 0
func check(_ cond: Bool, _ msg: String) {
    if cond { passed += 1; print("ok   - \(msg)") }
    else    { failed += 1; print("FAIL - \(msg)") }
}
func near(_ a: Double, _ b: Double, _ eps: Double = 1e-9) -> Bool { abs(a - b) < eps }
func near(_ a: CGFloat, _ b: CGFloat, _ eps: CGFloat = 1e-6) -> Bool { abs(a - b) < eps }

@main
enum OverlayCoreTests {
    static func main() {

        // ───────────── geometry: bounds ─────────────
        do {
            let b = Geometry.bounds([CGPoint(x: 10, y: 20), CGPoint(x: 30, y: 5),
                                     CGPoint(x: 15, y: 40)])
            check(near(b.minX, 10) && near(b.minY, 5), "bounds finds min corner")
            check(near(b.width, 20) && near(b.height, 35), "bounds finds extent")

            check(Geometry.bounds([]).isNull, "bounds of no points is .null, not .zero")

            let single = Geometry.bounds([CGPoint(x: 7, y: 9)])
            check(!single.isNull && near(single.width, 0) && near(single.minX, 7),
                  "bounds of one point is a zero-size rect at that point")

            // Negative coordinates happen for real: a second display placed left of
            // the primary one has negative global x.
            let neg = Geometry.bounds([CGPoint(x: -100, y: -50), CGPoint(x: -20, y: -10)])
            check(near(neg.minX, -100) && near(neg.width, 80), "bounds handles negatives")
        }

        // ───────────── geometry: normalize / denormalize ─────────────
        do {
            let parent = CGRect(x: 100, y: 200, width: 400, height: 800)
            let p = CGPoint(x: 300, y: 600)
            let n = Geometry.normalize(p, in: parent)
            check(near(n.x, 0.5) && near(n.y, 0.5), "normalize centre → (0.5, 0.5)")

            let back = Geometry.denormalize(n, in: parent)
            check(near(back.x, p.x) && near(back.y, p.y), "denormalize is the inverse")

            // The property that matters for P2: the same normalized stroke re-projected
            // into a MOVED and RESIZED parent lands proportionally in the same place.
            let moved = CGRect(x: 900, y: 0, width: 200, height: 400)
            let re = Geometry.denormalize(n, in: moved)
            check(near(re.x, 1000) && near(re.y, 200),
                  "normalized point re-projects into a moved+resized parent")

            // A degenerate parent must not produce NaN and poison the store.
            let flat = CGRect(x: 0, y: 0, width: 0, height: 0)
            let fn = Geometry.normalize(CGPoint(x: 5, y: 5), in: flat)
            check(fn.x == 0 && fn.y == 0 && !fn.x.isNaN, "zero-size parent yields 0, not NaN")

            let nr = Geometry.normalize(CGRect(x: 200, y: 400, width: 100, height: 200),
                                        in: parent)
            check(near(nr.x, 0.25) && near(nr.y, 0.25) && near(nr.w, 0.25) && near(nr.h, 0.25),
                  "rect normalizes on all four fields")
            let rback = Geometry.denormalize(nr, in: parent)
            check(near(rback.minX, 200) && near(rback.height, 200), "rect roundtrips")
        }

        // ───────────── geometry: crop padding (the P1 seam) ─────────────
        do {
            let surface = CGRect(x: 0, y: 0, width: 1000, height: 1000)
            let ink = CGRect(x: 500, y: 500, width: 100, height: 100)
            let crop = Geometry.padded(ink, by: 20, clampedTo: surface)
            check(near(crop.minX, 480) && near(crop.width, 140), "crop pads on both sides")

            // Ink drawn against the screen edge must clamp, never go negative — an
            // out-of-bounds crop rect would crash ScreenCaptureKit later.
            let edge = CGRect(x: 0, y: 0, width: 50, height: 50)
            let clamped = Geometry.padded(edge, by: 30, clampedTo: surface)
            check(clamped.minX >= 0 && clamped.minY >= 0, "crop at the screen edge clamps to 0")
            check(surface.contains(clamped), "crop never escapes the surface")

            check(Geometry.padded(.null, by: 10, clampedTo: surface).isNull,
                  "padding a null rect stays null")
        }

        // ───────────── geometry: decimate ─────────────
        do {
            // 100 samples one pixel apart, threshold 5 → keeps roughly every 5th.
            let dense = (0..<100).map { CGPoint(x: CGFloat($0), y: 0) }
            let thin = Geometry.decimate(dense, minDistance: 5)
            check(thin.count < dense.count, "decimate drops samples")
            check(thin.count >= 20 && thin.count <= 21, "decimate keeps ~every 5th sample")
            check(thin.first == dense.first, "decimate keeps the first point")
            check(thin.last == dense.last, "decimate keeps the last point (short flicks)")

            check(Geometry.decimate([], minDistance: 5).isEmpty, "decimate of empty is empty")
            let one = [CGPoint(x: 1, y: 1)]
            check(Geometry.decimate(one, minDistance: 5) == one, "decimate of one point is itself")
            check(Geometry.decimate(dense, minDistance: 0).count == 100,
                  "threshold 0 disables decimation")

            // A tiny two-point flick inside the threshold must not collapse to a
            // single point — a zero-length stroke renders as nothing at all.
            let flick = [CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 0)]
            check(Geometry.decimate(flick, minDistance: 5).count == 2, "2-point flick survives")
        }

        // ───────────── hex ─────────────
        do {
            let red = Hex.parse("#FF0000")
            check(red != nil && near(red!.r, 1) && near(red!.g, 0) && near(red!.a, 1),
                  "#RRGGBB parses opaque")
            check(Hex.parse("00FF00") != nil, "hex without the # parses")
            let half = Hex.parse("#00000080")
            check(half != nil && half!.a > 0.49 && half!.a < 0.51, "#RRGGBBAA parses alpha")
            check(Hex.parse("#GG0000") == nil, "non-hex digits rejected")
            check(Hex.parse("#FFF") == nil, "3-digit shorthand rejected (not supported)")
            check(Hex.parse("") == nil, "empty string rejected")
            check(Hex.palette.allSatisfy { Hex.parse($0) != nil }, "every palette entry parses")
        }

        // ───────────── store: undo / redo / clear ─────────────
        do {
            let s = OverlayStore()
            func ink(_ x: CGFloat) -> OverlayObject {
                OverlayObject(points: [CGPoint(x: x, y: 0), CGPoint(x: x + 1, y: 1)])
            }
            s.add(ink(1)); s.add(ink(2)); s.add(ink(3))
            check(s.objects.count == 3, "three strokes added")

            check(s.undo() && s.objects.count == 2, "undo removes the last stroke")
            check(s.redo() && s.objects.count == 3, "redo puts it back")

            // The classic editor invariant: drawing after an undo kills the redo branch.
            s.undo(); s.add(ink(9))
            check(!s.redo(), "a new stroke invalidates the redo branch")
            check(s.objects.count == 3, "…and the store holds the new stroke")

            let empty = OverlayStore()
            check(!empty.undo(), "undo on an empty store is a no-op, not a crash")
            check(!empty.redo(), "redo on an empty store is a no-op")

            s.clear()
            check(s.objects.isEmpty, "clear empties the canvas")
            check(s.redo() && s.objects.count == 1, "clear is undoable one stroke at a time")

            let byID = OverlayStore()
            let target = ink(5)
            byID.add(ink(4)); byID.add(target)
            byID.remove(id: target.id)
            check(byID.objects.count == 1 && byID.objects[0].id != target.id,
                  "remove(id:) removes exactly the named object")
        }

        // ───────────── store: JSON roundtrip (the agent wire format) ─────────────
        do {
            let o = OverlayObject(points: [CGPoint(x: 1.5, y: 2.5), CGPoint(x: 3, y: 4)],
                                  colorHex: "#0A84FF", width: 4.5,
                                  actor: "agent:fm", lifetime: .ephemeral,
                                  created: 1_700_000_000,
                                  anchor: OverlayAnchor(type: .window, app: "com.apple.Safari",
                                                 windowTitle: "Settings", windowNumber: 42,
                                                 rel: NormRect(x: 0.1, y: 0.2, w: 0.3, h: 0.4)))
            let s = OverlayStore(objects: [o])
            let data = try! s.encoded()
            let back = try! OverlayStore.decode(data)
            check(back.count == 1, "one object survives the roundtrip")
            check(back[0] == o, "the object is byte-for-byte equal after roundtrip")
            check(back[0].points.count == 2 && near(back[0].points[0].x, 1.5),
                  "CGPoint really is Codable (float precision kept)")
            check(back[0].anchor.rel?.w == 0.3, "the nested normalized rect survives")
            check(back[0].actor == "agent:fm" && back[0].lifetime == .ephemeral,
                  "provenance and lifetime survive")

            let json = String(data: data, encoding: .utf8) ?? ""
            check(json.contains("\"actor\""), "the wire format is readable JSON")

            // Agent-supplied JSON is untrusted input: a malformed body must throw, not
            // take down the app.
            var threw = false
            do { _ = try OverlayStore.decode(Data("{ not json".utf8)) } catch { threw = true }
            check(threw, "malformed JSON throws rather than crashing")
        }

        // ───────────── store: disk ─────────────
        do {
            let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent("overlay-test-\(getpid())")
                .appendingPathComponent("nested")     // exercises directory creation
                .appendingPathComponent("session.json")
            let s = OverlayStore(objects: [OverlayObject(points: [CGPoint(x: 0, y: 0)])])
            try! s.save(to: tmp)
            check(FileManager.default.fileExists(atPath: tmp.path),
                  "save creates intermediate directories")
            let loaded = try! OverlayStore.load(from: tmp)
            check(loaded.objects.count == 1, "load reads it back")
            try? FileManager.default.removeItem(at: tmp.deletingLastPathComponent())
        }

        // ───────────── store: TTL expiry ─────────────
        do {
            let now = 1_000_000.0
            let s = OverlayStore(objects: [
                OverlayObject(points: [.zero], actor: "agent:fm",
                              lifetime: .ephemeral, created: now - 60),   // stale
                OverlayObject(points: [.zero], actor: "agent:fm",
                              lifetime: .ephemeral, created: now - 1),    // fresh
                OverlayObject(points: [.zero], lifetime: .persistent, created: now - 9999),
            ])
            s.expire(now: now, ephemeralSeconds: 5)
            check(s.objects.count == 2, "stale ephemeral objects are collected")
            check(s.objects.contains { $0.lifetime == .persistent },
                  "persistent human ink is never collected by TTL")
            check(s.objects.contains { $0.lifetime == .ephemeral },
                  "a fresh ephemeral object is kept")
        }

        // ───────────── object: crop rect ─────────────
        do {
            let surface = CGRect(x: 0, y: 0, width: 1440, height: 900)
            let square = OverlayObject(points: [CGPoint(x: 400, y: 300),
                                                CGPoint(x: 700, y: 300),
                                                CGPoint(x: 700, y: 500),
                                                CGPoint(x: 400, y: 500),
                                                CGPoint(x: 400, y: 300)])
            let crop = square.cropRect(in: surface, pad: 24)
            check(near(crop.minX, 376) && near(crop.width, 348),
                  "a drawn square yields a padded crop rect around it")
            check(surface.contains(crop), "the crop stays on screen")
        }

        // ───────────── mode machine ─────────────
        do {
            let m = OverlayMode.passthrough
            check(m.ignoresMouseEvents, "passthrough ignores the mouse — the Mac stays usable")
            check(!m.toggled.ignoresMouseEvents, "draw mode captures the mouse")
            check(m.toggled.toggled == m, "toggling twice returns to passthrough")
            check(OverlayMode(rawValue: "draw") == .draw, "mode is round-trippable by name")
        }

        // ───────────── paths ─────────────
        do {
            check(OverlayPaths.root.path.hasSuffix("/.overlay"), "root is ~/.overlay")
            check(OverlayPaths.inbox.lastPathComponent == "inbox", "inbox path")
            check(OverlayPaths.session.path.contains("/store/"), "session lives under store/")
        }

        print("\n\(passed) passed, \(failed) failed")
        exit(failed == 0 ? 0 : 1)
    }
}
