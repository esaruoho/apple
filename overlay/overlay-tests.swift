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

        // ═══════════════ P1: object kinds ═══════════════

        do {
            check(ObjectKind.box.isRectangular && ObjectKind.highlight.isRectangular
                  && ObjectKind.spotlight.isRectangular, "the three rect kinds agree")
            check(!ObjectKind.arrow.isRectangular, "an arrow is not a rectangle")
            check(ObjectKind.label.needsText && ObjectKind.callout.needsText
                  && ObjectKind.sticker.needsText, "text kinds demand text")
            check(!ObjectKind.ink.needsText, "ink needs no text")
            check(ObjectKind.arrow.minimumPoints == 2, "an arrow needs a tail and a head")
            check(ObjectKind.label.minimumPoints == 1, "a label needs one point")

            // Corners in any order describe the same rectangle — an agent should not
            // have to normalise before posting.
            let forward = OverlayObject(kind: .box, points: [CGPoint(x: 10, y: 10),
                                                             CGPoint(x: 110, y: 60)])
            let reversed = OverlayObject(kind: .box, points: [CGPoint(x: 110, y: 60),
                                                              CGPoint(x: 10, y: 10)])
            check(forward.rect == reversed.rect, "reversed corners give the same rect")
            check(near(forward.rect.width, 100) && near(forward.rect.height, 50),
                  "rect has a positive size either way")

            check(OverlayObject(kind: .callout, points: [.zero], text: "hi").isRenderable == false,
                  "a callout with one point is rejected")
            check(OverlayObject(kind: .label, points: [.zero], text: "").isRenderable == false,
                  "a label with empty text is rejected")
            check(OverlayObject(kind: .label, points: [.zero], text: "ok").isRenderable,
                  "a label with a point and text is fine")
        }

        // ═══════════════ P1: shape recognition ═══════════════

        do {
            /// Trace a closed rectangle with `per` samples along each edge.
            func square(_ r: CGRect, per: Int = 12) -> [CGPoint] {
                let cs = [CGPoint(x: r.minX, y: r.minY), CGPoint(x: r.maxX, y: r.minY),
                          CGPoint(x: r.maxX, y: r.maxY), CGPoint(x: r.minX, y: r.maxY),
                          CGPoint(x: r.minX, y: r.minY)]
                var out: [CGPoint] = []
                for i in 1..<cs.count {
                    for s in 0..<per {
                        let t = CGFloat(s) / CGFloat(per)
                        out.append(CGPoint(x: cs[i-1].x + (cs[i].x - cs[i-1].x) * t,
                                           y: cs[i-1].y + (cs[i].y - cs[i-1].y) * t))
                    }
                }
                out.append(cs[0])
                return out
            }
            func circle(_ c: CGPoint, _ radius: CGFloat, steps: Int = 48) -> [CGPoint] {
                (0...steps).map { i in
                    let a = 2 * CGFloat.pi * CGFloat(i) / CGFloat(steps)
                    return CGPoint(x: c.x + cos(a) * radius, y: c.y + sin(a) * radius)
                }
            }

            // THE headline case: Esa draws a square around part of a whiteboard.
            let drawn = ShapeDetect.classify(square(CGRect(x: 100, y: 100,
                                                           width: 300, height: 200)))
            check(drawn.shape == .rectangle, "a traced square is recognised as a rectangle")
            check(drawn.confidence > 0.8, "…with high confidence")
            check(near(drawn.rect.width, 300) && near(drawn.rect.height, 200),
                  "…and the rect it reports is the region to crop")

            let round = ShapeDetect.classify(circle(CGPoint(x: 200, y: 200), 80))
            check(round.shape == .ellipse, "a traced circle is recognised as an ellipse")
            check(near(round.rect.width, 160, 1), "the ellipse's rect is its bounding box")

            let straight = ShapeDetect.classify((0..<30).map { CGPoint(x: CGFloat($0) * 10, y: 5) })
            check(straight.shape == .line, "a straight drag is a line")
            check(straight.confidence > 0.9, "…with high confidence")

            // A genuine scribble must NOT be silently straightened into a shape.
            let scribble = (0..<40).map { i -> CGPoint in
                CGPoint(x: CGFloat(i) * 7, y: CGFloat((i % 5) * 40 - 80))
            }
            check(ShapeDetect.classify(scribble).shape == .freehand,
                  "a zigzag scribble stays freehand — we never rewrite what was drawn")

            check(ShapeDetect.classify([]).shape == .freehand, "no points → freehand")
            check(ShapeDetect.classify([CGPoint(x: 1, y: 1), CGPoint(x: 2, y: 2)]).shape
                  == .freehand, "too few points → freehand, not a lucky guess")

            // A hand-drawn square is never perfect; jitter must not break recognition.
            var wobbly = square(CGRect(x: 0, y: 0, width: 240, height: 240))
            for i in stride(from: 0, to: wobbly.count, by: 3) {
                wobbly[i].x += (i % 2 == 0 ? 4 : -4)
                wobbly[i].y += (i % 3 == 0 ? -3 : 3)
            }
            check(ShapeDetect.classify(wobbly).shape == .rectangle,
                  "a wobbly hand-drawn square is still a rectangle")

            check(near(ShapeDetect.pathLength([CGPoint(x: 0, y: 0), CGPoint(x: 3, y: 4)]), 5),
                  "pathLength measures the polyline")
        }

        // ═══════════════ P1: the agent post protocol ═══════════════

        do {
            let screen = CGRect(x: 0, y: 0, width: 1000, height: 800)

            func post(_ json: String) throws -> OverlayObject {
                let reqs = try PostRequest.decodeBatch(Data(json.utf8))
                return try reqs[0].resolve(in: screen, now: 1_700_000_000)
            }

            // The canonical agent call from the plan.
            let box = try! post("""
            {"kind":"box","rel":{"x":0.1,"y":0.2,"w":0.3,"h":0.1},
             "color":"#FF3B30","actor":"agent:fm","ttl":"ephemeral"}
            """)
            check(box.kind == .box, "kind decodes")
            check(near(box.rect.minX, 100) && near(box.rect.minY, 160),
                  "rel is resolved against the surface")
            check(near(box.rect.width, 300) && near(box.rect.height, 80),
                  "…including its size")
            check(box.actor == "agent:fm" && box.lifetime == .ephemeral,
                  "provenance and TTL come through")

            // An agent that omits the TTL gets .session, never .persistent — it must
            // not be able to litter the desktop permanently by forgetting a field.
            let defaulted = try! post("""
            {"kind":"highlight","rel":{"x":0,"y":0,"w":0.5,"h":0.5}}
            """)
            check(defaulted.lifetime == .session, "a posted object defaults to .session")
            check(defaulted.actor == "agent:unknown", "…and to an explicit unknown actor")
            check(defaulted.colorHex == Hex.palette[3],
                  "agent default colour is blue, distinct from human red")

            // Absolute pixels also work, for an agent that already knows the geometry.
            let abs = try! post("""
            {"kind":"arrow","points":[[10,20],[300,400]],"actor":"agent:claude"}
            """)
            check(abs.points.count == 2 && near(abs.points[1].y, 400),
                  "explicit points are taken verbatim")

            let label = try! post("""
            {"kind":"label","at":[500,500],"text":"click this"}
            """)
            check(label.points.count == 1 && label.text == "click this", "label at a point")

            // A rect given for a single-point kind collapses to its centre, so the same
            // `rel` works whether the agent asks for a box or a label.
            let centred = try! post("""
            {"kind":"sticker","rel":{"x":0.4,"y":0.4,"w":0.2,"h":0.2},"text":"⚠️"}
            """)
            check(near(centred.points[0].x, 500) && near(centred.points[0].y, 400),
                  "a rel rect for a sticker resolves to its centre")

            let callout = try! post("""
            {"kind":"callout","rel":{"x":0.1,"y":0.1,"w":0.2,"h":0.1},"text":"here"}
            """)
            check(callout.points.count == 2, "a callout gets a target and a chip position")
            check(callout.points[1].y > callout.points[0].y, "the chip floats above the target")

            // ── rejection: every one of these must fail loudly, not paint nothing ──
            func fails(_ json: String, _ expect: PostRequest.PostError, _ msg: String) {
                do { _ = try post(json); check(false, msg + " (accepted!)") }
                catch let e as PostRequest.PostError { check(e == expect, msg) }
                catch { check(false, msg + " (wrong error type)") }
            }
            fails(#"{"kind":"hilight","rel":{"x":0,"y":0,"w":1,"h":1}}"#,
                  .unknownKind("hilight"), "a misspelled kind is rejected by name")
            fails(#"{"kind":"box"}"#, .noGeometry, "no geometry is rejected")
            fails(#"{"kind":"label","at":[1,2]}"#, .missingText(.label),
                  "a label without text is rejected")
            fails(#"{"kind":"box","rel":{"x":0,"y":0,"w":1,"h":1},"color":"nope"}"#,
                  .badColor("nope"), "a bad colour is rejected")
            fails(#"{"kind":"box","rel":{"x":0,"y":0,"w":1,"h":1},"ttl":"forever"}"#,
                  .badTTL("forever"), "a bad ttl is rejected")
            fails(#"{"kind":"arrow","points":[[1,2]]}"#, .notRenderable(.arrow),
                  "an arrow with one point is rejected")

            // A batch drops in atomically.
            let batch = try! PostRequest.decodeBatch(Data("""
            [{"kind":"box","rel":{"x":0,"y":0,"w":0.5,"h":0.5}},
             {"kind":"label","at":[5,5],"text":"two"}]
            """.utf8))
            check(batch.count == 2, "an array of requests decodes as a batch")
            check((try? batch[1].resolve(in: screen))?.text == "two", "…and each resolves")

            var threw = false
            do { _ = try PostRequest.decodeBatch(Data("nonsense".utf8)) } catch { threw = true }
            check(threw, "a malformed inbox file throws")
        }

        // ═══════════════ the Converse bridge ═══════════════

        do {
            check(Livefile.eventID(1) == "evt_000001", "event ids are 6-digit padded")
            check(Livefile.eventID(12181) == "evt_012181", "…and keep working past 10k")

            // Must match Converse byte-for-byte or the two writers sort differently.
            let when = Date(timeIntervalSince1970: 1_753_001_537.813)
            let t = Livefile.stamp(when)
            check(t.hasSuffix("Z") && t.contains("T"), "timestamps are RFC3339 Z")
            check(t.count == 24, "…with milliseconds, exactly like Converse (\(t))")

            let stampFmt = Livefile.sessionStamp(when)
            check(stampFmt.count == 17 && stampFmt.filter { $0 == "-" }.count == 3,
                  "session stamp is YYYY-MM-DD-HHMMSS (\(stampFmt))")

            let line = Livefile.encode(
                LivefileEvent(type: "agent.requested", body: "what is this",
                              extra: ["instruction": "what is this", "agent": "fm",
                                      "source": "overlay"]),
                id: "evt_000007", at: when)
            check(line != nil, "an event encodes")
            let parsed = try! JSONSerialization.jsonObject(
                with: line!.data(using: .utf8)!) as! [String: Any]
            check(parsed["id"] as? String == "evt_000007", "id survives")
            check(parsed["type"] as? String == "agent.requested",
                  "type is one Converse already knows")
            check(parsed["actor"] as? String == "local-user", "actor defaults as Converse does")
            check(parsed["instruction"] as? String == "what is this", "extra fields survive")
            check(!line!.contains("\n"), "one event is exactly one line")

            // Untrusted content must not be able to break the log format.
            let nasty = Livefile.encode(
                LivefileEvent(type: "vision.ocr", body: "line one\nline two \"quoted\""),
                id: "evt_000008", at: when)
            check(nasty != nil && !nasty!.contains("\n"),
                  "a body with newlines and quotes stays on one line")

            let rendered = Livefile.transcript(from: [
                ["type": "session.created", "t": "2026-08-12T10:00:00.000Z", "body": "s"],
                ["type": "overlay.region.captured", "t": "x", "rect": "10,20 300x100"],
                ["type": "vision.ocr", "t": "x", "body": "some text on screen"],
                ["type": "agent.requested", "t": "x", "instruction": "what is this"],
                ["type": "agent.responded", "t": "x", "body": "It is a table.",
                 "agent": "fm", "latency_ms": 4200],
                ["type": "overlay.image.generated", "t": "x", "prompt": "a red truck",
                 "file": "gen-1.png"],
            ], sessionID: "test")
            check(rendered.contains("Do not treat this file alone as the source of truth"),
                  "the transcript declares it is derived")
            check(rendered.contains("**you:** what is this"), "the question renders")
            check(rendered.contains("**fm:** It is a table."), "the answer renders")
            check(rendered.contains("4200 ms"), "latency is kept")
            check(rendered.contains("![generated](gen-1.png)"), "a generated image is linked")
            check(rendered.contains("`10,20 300x100`"), "the region is recorded")

            check(LivefileWriter.sessionsRoot.path.hasSuffix("work/converse/sessions"),
                  "sessions land beside Converse's own")
            check(LivefileWriter(now: when).sessionID.hasSuffix("-overlay"),
                  "an overlay session is named as one")
        }

        // ═══════════════ depth planes ═══════════════

        do {
            check(DepthPlane.of(actor: "human:esa") == .human, "the human's marks sit low")
            check(DepthPlane.of(actor: "agent:fm") == .agent, "agent marks sit above them")
            check(DepthPlane.of(actor: "agent:security-steward") == .alert,
                  "a security actor is raised to the alert plane")
            check(DepthPlane.of(actor: "agent:ask", colorHex: "#FF9F0A") == .alert,
                  "the warning colour raises the plane too")
            check(DepthPlane.human < DepthPlane.agent, "planes are ordered")
            check(DepthPlane.agent < DepthPlane.alert, "…all the way up")

            // Depth must be conveyed by height cues, not by shouting.
            check(DepthPlane.alert.shadow.radius > DepthPlane.agent.shadow.radius,
                  "a higher plane casts a longer shadow")
            check(DepthPlane.agent.shadow.radius > DepthPlane.human.shadow.radius,
                  "…monotonically")
            check(DepthPlane.alert.shadow.offsetY < DepthPlane.human.shadow.offsetY,
                  "and it falls further")
            check(DepthPlane.human.scale == 1.0 && DepthPlane.alert.scale < 1.05,
                  "scale is a hint, not a zoom")
        }

        // ═══════════════ motion ═══════════════

        do {
            check(Motion.easeOut(0) == 0 && Motion.easeOut(1) == 1, "easeOut spans 0…1")
            check(Motion.easeOut(0.5) > 0.5, "easeOut decelerates — most distance covered early")
            check(Motion.easeOut(-3) == 0 && Motion.easeOut(9) == 1, "easing clamps")

            // Overshoot is the point: arrival should look physical.
            check(Motion.easeOutBack(0.75) > 1.0, "easeOutBack overshoots before settling")
            check(near(Motion.easeOutBack(1), 1.0, 1e-9), "…and lands exactly on target")

            let t0 = 1_000_000.0
            check(Motion.arrival(created: t0, now: t0) == 0, "arrival starts at 0")
            check(Motion.arrival(created: t0, now: t0 + 0.14) > 0.49, "…is half way at half time")
            check(Motion.arrival(created: t0, now: t0 + 5) == 1, "…and completes")
            check(Motion.arrival(created: t0, now: t0, duration: 0) == 1,
                  "a zero duration is instant, not a divide by zero")

            let mid = Motion.lerp(CGPoint(x: 0, y: 0), CGPoint(x: 100, y: 50), 0.5)
            check(near(mid.x, 50) && near(mid.y, 25), "lerp travels a marker to its target")

            // A TTL object should visibly be running out, not blink away.
            check(Motion.fadeOut(created: t0, now: t0 + 1, lifetime: 5) == 1,
                  "an ephemeral mark is fully opaque in mid-life")
            let dying = Motion.fadeOut(created: t0, now: t0 + 4.6, lifetime: 5)
            check(dying > 0 && dying < 1, "…fades over its last stretch")
            check(Motion.fadeOut(created: t0, now: t0 + 6, lifetime: 5) == 0,
                  "…and is gone when its time is up")
        }

        // ═══════════════ attachment grammar ═══════════════

        do {
            check(Attachment.firm.opacity == 1.0, "a firm anchor is fully drawn")
            check(Attachment.loosening.opacity < Attachment.firm.opacity,
                  "a degrading anchor visibly weakens")
            check(Attachment.lost.opacity < Attachment.loosening.opacity,
                  "a lost one weakens further")
            check(!Attachment.firm.isDashed, "firm is solid")
            check(Attachment.ambiguous.isDashed && Attachment.lost.isDashed,
                  "anything not firm is dashed — uncertainty is never drawn as certainty")
        }

        // ═══════════ Observation / Anchor / Resolution ═══════════

        do {
            let surface = SurfaceRef(kind: .localDisplay, id: "Built-in Retina Display",
                                     epoch: 3)
            let obs = Observation(surface: surface, t: 1000,
                                  rect: NormRect(x: 0.1, y: 0.2, w: 0.3, h: 0.1),
                                  cropPath: "/tmp/a.png", cropDigest: "sha:abc",
                                  ocr: "Export Data")

            // Selectors: semantics beat geometry, and the strongest sorts first.
            let anchor = SpatialAnchor(selectors: [
                AnchorSelector(kind: .surfaceNormalizedRect,
                         rect: NormRect(x: 0.1, y: 0.2, w: 0.3, h: 0.1)),
                AnchorSelector(kind: .accessibility, application: "com.apple.Safari",
                         windowTitle: "Settings", role: "AXButton", name: "Export Data"),
                AnchorSelector(kind: .text, exact: "Export Data", context: "Privacy"),
            ])
            check(anchor.best?.kind == .accessibility,
                  "the most semantic selector sorts first")
            check(anchor.selectors.map(\.kind) ==
                  [.accessibility, .text, .surfaceNormalizedRect],
                  "…and the rest follow by weight")

            check(anchor.survivesRestart, "an app+role+name anchor survives a restart")
            check(!AnchorSelector(kind: .windowNormalizedRect,
                            rect: NormRect(x: 0, y: 0, w: 1, h: 1)).survivesRestart,
                  "a window-relative rect does not — it has no window after a restart")
            check(!AnchorSelector(kind: .windowFingerprint, windowNumber: 42).survivesRestart,
                  "a bare window NUMBER is not a durable identity")
            check(AnchorSelector(kind: .windowFingerprint,
                           application: "com.apple.Safari").survivesRestart,
                  "…but the application is")

            // The rule that keeps the whole system honest.
            let none = Resolution.grade(candidates: 0, method: .accessibility,
                                        rect: nil, surfaceEpoch: 3, t: 1001)
            check(none.state == .unavailable, "no candidates → unavailable")
            check(!none.state.actionable, "…and not actionable")

            // Confidence comes from the selector that actually matched, so callers
            // pass its weight; the kind alone cannot know how specific it was.
            let semantic = anchor.best!
            let one = Resolution.grade(candidates: 1, method: semantic.kind,
                                       confidence: semantic.weight,
                                       rect: obs.rect, surfaceEpoch: 3, t: 1001)
            check(one.state == .resolved && one.state.actionable, "one candidate → resolved")
            check(one.confidence > 0.9, "…with high confidence for a role+name match")
            check(AnchorSelector(kind: .accessibility, application: "x", role: "AXButton").weight
                    < semantic.weight,
                  "a role with no name is a much weaker address than role+name")

            let many = Resolution.grade(candidates: 4, method: .windowFingerprint,
                                        rect: obs.rect, surfaceEpoch: 3, t: 1001)
            check(many.state == .ambiguous, "several candidates → AMBIGUOUS")
            check(!many.state.actionable,
                  "…and never actionable — the system must not pick the closest")
            check(many.candidates == 4, "…recording how many, for the human to see")

            let weak = Resolution.grade(candidates: 1, method: .surfaceNormalizedRect,
                                        confidence: 0.1,
                                        rect: obs.rect, surfaceEpoch: 3, t: 1001)
            check(weak.confidence < 0.2,
                  "a bare geometry match resolves, but with almost no confidence")

            // Epoch: geometry recorded under a different display arrangement is not
            // comparable, whatever it said at the time.
            check(one.staleness(againstEpoch: 3).state == .resolved,
                  "same epoch → still resolved")
            check(one.staleness(againstEpoch: 4).state == .stale,
                  "the display arrangement changed → stale, not silently reused")

            // The doctrine, made mechanical.
            let ref = SpatialReference(surface: surface, observation: obs, anchor: anchor,
                                       resolution: one, actor: "human:esa", createdAt: 1000)
            let later = ref.resolved(Resolution.grade(candidates: 0, method: .accessibility,
                                                      rect: nil, surfaceEpoch: 3, t: 2000))
            check(later.observation == ref.observation,
                  "re-resolving NEVER alters the observation — evidence is immutable")
            check(later.resolution.state == .unavailable,
                  "…only the resolution changes")

            check(ref.actionable(underEpoch: 3), "a confident current match is actionable")
            check(!ref.actionable(underEpoch: 9),
                  "…and stops being actionable when the surface changed underneath")
            check(!ref.resolved(many).actionable(underEpoch: 3),
                  "an ambiguous reference is never actionable")
            check(!ref.resolved(weak).actionable(underEpoch: 3, minConfidence: 0.5),
                  "a low-confidence match is refused for action")

            // The epistemic state drives the visual grammar built earlier.
            check(ResolutionState.resolved.attachment == .firm, "resolved draws firm")
            check(ResolutionState.stale.attachment == .loosening, "stale visibly loosens")
            check(ResolutionState.ambiguous.attachment == .ambiguous, "ambiguity is dashed")
            check(ResolutionState.destroyed.attachment == .lost, "a destroyed target is lost")

            // It has to survive the wire, since agents and missions will hold these.
            let data = try! JSONEncoder().encode(ref)
            let back = try! JSONDecoder().decode(SpatialReference.self, from: data)
            check(back == ref, "a SpatialReference roundtrips through JSON")
            check(back.anchor.selectors.count == 3, "…with all its selectors")
        }

        // ═══════════ window matching ═══════════

        do {
            func w(_ owner: String, _ title: String, _ n: Int,
                   _ r: CGRect, layer: Int = 0) -> WindowDescriptor {
                WindowDescriptor(pid: 100 + n, owner: owner, title: title, number: n,
                                 frame: r, layer: layer)
            }
            let safari  = w("Safari", "Settings", 1, CGRect(x: 100, y: 100, width: 800, height: 600))
            let safari2 = w("Safari", "Apple",    2, CGRect(x: 200, y: 150, width: 700, height: 500))
            let term    = w("iTerm2", "bash",     3, CGRect(x: 0, y: 0, width: 600, height: 400))
            let menubar = w("Window Server", "Menubar", 4,
                            CGRect(x: 0, y: 0, width: 1512, height: 24), layer: 24)
            let tiny    = w("Dock", "", 5, CGRect(x: 0, y: 0, width: 40, height: 40))
            let mine    = w("Overlay", "", 6, CGRect(x: 0, y: 0, width: 1512, height: 982))
            let all = [safari, safari2, term, menubar, tiny, mine]

            let usable = WindowMatcher.addressable(all, excludingOwner: "Overlay")
            check(usable.count == 3, "menu bar, Dock and our own panel are not targets")
            check(!usable.contains(where: { $0.owner == "Overlay" }),
                  "the overlay never anchors to itself")

            // app + title → exactly one
            let precise = WindowMatcher.anchor(for: safari)
            let hit = WindowMatcher.candidates(for: precise, among: usable)
            check(hit.matches.count == 1 && hit.matches[0].number == 1,
                  "app + title finds exactly the intended window")
            check(hit.method == .windowFingerprint, "…by fingerprint")
            check(hit.weight > 0.8, "…and the app+title fingerprint is a specific match")
            check(AnchorSelector(kind: .windowFingerprint, application: "Safari").weight <
                  AnchorSelector(kind: .windowFingerprint, application: "Safari",
                           windowTitle: "Settings").weight,
                  "app-only ranks BELOW app+title — specificity, not category")

            // app alone across two Safari windows → AMBIGUOUS, never a guess
            let loose = SpatialAnchor(selectors: [
                AnchorSelector(kind: .windowFingerprint, application: "Safari")])
            let both = WindowMatcher.candidates(for: loose, among: usable)
            check(both.matches.count == 2, "app alone matches both Safari windows")
            let graded = Resolution.grade(candidates: both.matches.count,
                                          method: both.method, confidence: both.weight,
                                          rect: nil, surfaceEpoch: 0, t: 0)
            check(graded.state == .ambiguous && !graded.state.actionable,
                  "two candidates is ambiguity, and ambiguity is not actionable")

            // A vanished window must read as GONE, not as "ambiguous among its
            // siblings" — the anchor carries a broad app-only selector for
            // reacquisition, and that must not turn absence into ambiguity.
            let withBroadFallback = SpatialAnchor(selectors: [
                AnchorSelector(kind: .windowFingerprint, application: "Safari",
                               windowTitle: "Settings"),
                AnchorSelector(kind: .windowFingerprint, application: "Safari"),
            ])
            let vanished = WindowMatcher.candidates(for: withBroadFallback,
                                                    among: [safari2, term])
            check(vanished.matches.isEmpty,
                  "the exact window is gone → unavailable, not ambiguous among siblings")
            check(Resolution.grade(candidates: 0, method: vanished.method,
                                   confidence: vanished.weight, rect: nil,
                                   surfaceEpoch: 0, t: 0).state == .unavailable,
                  "…and grades as unavailable")

            // Reacquisition after a restart: the app is back with the SAME title, so
            // the broad selector is allowed to adopt it even though the window number
            // is new. That is the case reacquisition exists for.
            let restarted = w("Safari", "Settings", 999,
                              CGRect(x: 100, y: 100, width: 800, height: 600))
            let back = WindowMatcher.candidates(for: withBroadFallback, among: [restarted])
            check(back.matches.count == 1 && back.matches[0].number == 999,
                  "after a restart the same app+title reacquires, with a new window id")

            // A single window of the right app but a DIFFERENT title is not adopted.
            let sibling = WindowMatcher.candidates(for: withBroadFallback, among: [safari2])
            check(sibling.matches.isEmpty,
                  "one window of the right app but the wrong title is NOT adopted")

            // closed window → unavailable, and NOT rebound to the other Safari
            let gone = WindowMatcher.candidates(for: precise, among: [term])
            check(gone.matches.isEmpty, "a closed window finds nothing")
            check(Resolution.grade(candidates: 0, method: gone.method, confidence: gone.weight,
                                   rect: nil, surfaceEpoch: 0, t: 0).state == .unavailable,
                  "…and resolves unavailable rather than to the nearest window")

            // a retitled window still matches on the app — degrade, don't vanish
            let renamed = w("Safari", "Something Else Entirely", 1,
                            CGRect(x: 100, y: 100, width: 800, height: 600))
            let after = WindowMatcher.candidates(for: precise, among: [renamed])
            check(after.matches.count == 1,
                  "the SAME window, retitled, is still found — same window number")

            // …but a different window of the same app, with a different title, is not
            // adopted just because it is the only one left.
            let impostor = w("Safari", "Something Else Entirely", 77,
                             CGRect(x: 100, y: 100, width: 800, height: 600))
            check(WindowMatcher.candidates(for: precise, among: [impostor]).matches.isEmpty,
                  "a different window of the same app is NOT adopted in its place")

            // the geometry that makes an annotation follow
            let mark = CGRect(x: 300, y: 250, width: 200, height: 100)
            let rel = WindowMatcher.bind(mark, to: safari.frame)
            check(near(rel.x, 0.25) && near(rel.y, 0.25), "a mark binds window-relative")

            let moved = CGRect(x: 500, y: 400, width: 800, height: 600)
            let followed = WindowMatcher.place(rel, in: moved)
            check(near(followed.minX, 700) && near(followed.minY, 550),
                  "…and follows the window when it moves")
            check(near(followed.width, 200), "…keeping its size when the window only moves")

            let resized = CGRect(x: 100, y: 100, width: 400, height: 300)
            let shrunk = WindowMatcher.place(rel, in: resized)
            check(near(shrunk.width, 100) && near(shrunk.height, 50),
                  "…and scales proportionally when the window is resized")
            check(near(shrunk.minX, 200), "…staying at the same relative position")

            check(!WindowMatcher.matches(
                    AnchorSelector(kind: .surfaceNormalizedRect,
                             rect: NormRect(x: 0, y: 0, w: 1, h: 1)), safari),
                  "geometry alone never identifies a window")
        }

        // ═══════════ authority envelope ═══════════

        do {
            let now = 1_000_000.0
            func envelope(_ json: String) throws -> [PostRequest] {
                let e = try JSONDecoder().decode(Envelope.self, from: Data(json.utf8))
                return try e.authorised(now: now)
            }
            func denied(_ json: String, _ expect: Envelope.Denial, _ msg: String) {
                do { _ = try envelope(json); check(false, msg + " (allowed!)") }
                catch let d as Envelope.Denial { check(d == expect, msg) }
                catch { check(false, msg + " (wrong error: \(error))") }
            }

            let good = try! envelope("""
            {"actor":"agent:francois","capability":"spatial.annotation.create",
             "expiry":1000060,
             "scope":{"surface":"local-display/*","kinds":["box","label"],
                      "maxLifetime":"session"},
             "request":[{"kind":"box","rel":{"x":0,"y":0,"w":0.2,"h":0.2},"ttl":"session"}]}
            """)
            check(good.count == 1, "a well-formed envelope is authorised")

            denied("""
            {"actor":"","capability":"spatial.annotation.create","expiry":1000060,
             "request":[{"kind":"box","rel":{"x":0,"y":0,"w":1,"h":1}}]}
            """, .noActor, "an unattributable request is refused")

            denied("""
            {"actor":"agent:x","capability":"spatial.annotation.create",
             "request":[{"kind":"box","rel":{"x":0,"y":0,"w":1,"h":1}}]}
            """, .noExpiry, "an envelope with no expiry is refused — a grant must end")

            denied("""
            {"actor":"agent:x","capability":"spatial.annotation.create","expiry":999000,
             "request":[{"kind":"box","rel":{"x":0,"y":0,"w":1,"h":1}}]}
            """, .expired(999000), "an expired envelope is refused")

            denied("""
            {"actor":"agent:x","capability":"spatial.annotation.create","expiry":1000060,
             "scope":{"surface":"local-display/*","kinds":["label"],"maxLifetime":"session"},
             "request":[{"kind":"spotlight","rel":{"x":0,"y":0,"w":1,"h":1}}]}
            """, .kindOutOfScope(.spotlight),
                   "an actor scoped to labels cannot dim the whole screen")

            denied("""
            {"actor":"agent:x","capability":"spatial.annotation.create","expiry":1000060,
             "scope":{"surface":"local-display/*","kinds":["box"],"maxLifetime":"ephemeral"},
             "request":[{"kind":"box","rel":{"x":0,"y":0,"w":1,"h":1},"ttl":"persistent"}]}
            """, .lifetimeOutOfScope(.persistent, .ephemeral),
                   "an ephemeral-only actor cannot leave a permanent mark")

            // The boundary that matters most.
            check(Capability.allCases.allSatisfy { !$0.permitsExecution },
                  "NO capability here permits execution — annotating never becomes acting")
        }

        // ═══════════ ActionIntent: approval bound to a resolved target ═══════════

        do {
            let surface = SurfaceRef(id: "display-1", epoch: 5)
            let rect = NormRect(x: 0.7, y: 0.8, w: 0.1, h: 0.05)
            let obs = Observation(surface: surface, t: 100, rect: rect,
                                  cropDigest: "sha:the-delete-button")
            let anchor = SpatialAnchor(selectors: [
                AnchorSelector(kind: .accessibility, application: "com.apple.Safari",
                               role: "AXButton", name: "Delete repository")])
            let resolved = Resolution(state: .resolved, method: .accessibility,
                                      confidence: 1.0, rect: rect, surfaceEpoch: 5, t: 100)
            let target = SpatialReference(surface: surface, observation: obs,
                                          anchor: anchor, resolution: resolved,
                                          actor: "agent:francois", createdAt: 100)

            let intent = ActionIntent(actor: "agent:francois", action: .click,
                                      target: target,
                                      reason: "remove the abandoned fork", createdAt: 100)
            check(intent.state == .proposed, "an intent starts merely proposed")
            check(!intent.executable(against: resolved, epoch: 5).ok,
                  "…and a proposal alone can never execute")

            let approved = intent.approved(at: 200)
            check(approved.state == .approved, "the human approves")
            check(approved.approvedObservationDigest == "sha:the-delete-button",
                  "…and what they were SHOWN is pinned to the approval")

            let fine = approved.executable(against: resolved, epoch: 5,
                                           currentDigest: "sha:the-delete-button")
            check(fine.ok, "unchanged target → executes: \(fine.reason)")

            // Target drift — the acceptance test the whole design exists for.
            let moved = Resolution(state: .resolved, method: .accessibility,
                                   confidence: 1.0,
                                   rect: NormRect(x: 0.2, y: 0.3, w: 0.1, h: 0.05),
                                   surfaceEpoch: 5, t: 300)
            let drifted = approved.executable(against: moved, epoch: 5)
            check(!drifted.ok, "the target MOVED after approval → refused")
            check(drifted.reason.contains("moved"), "…and says so: \(drifted.reason)")

            let swapped = approved.executable(against: resolved, epoch: 5,
                                              currentDigest: "sha:something-else")
            check(!swapped.ok,
                  "the pixels changed under the same coordinates → refused: \(swapped.reason)")

            let rearranged = approved.executable(against: resolved, epoch: 6)
            check(!rearranged.ok, "the display arrangement changed → refused")

            let ambiguousNow = Resolution(state: .ambiguous, surfaceEpoch: 5, t: 300)
            check(!approved.executable(against: ambiguousNow, epoch: 5).ok,
                  "the target became ambiguous → refused, never a guess")

            let gone = Resolution(state: .unavailable, surfaceEpoch: 5, t: 300)
            check(!approved.executable(against: gone, epoch: 5).ok,
                  "the target vanished → refused")

            check(!intent.rejected().executable(against: resolved, epoch: 5).ok,
                  "a rejected intent never executes")

            let wire = try! JSONEncoder().encode(approved)
            let back = try! JSONDecoder().decode(ActionIntent.self, from: wire)
            check(back == approved, "an intent and its approval survive the wire intact")
        }

        print("\n\(passed) passed, \(failed) failed")
        exit(failed == 0 ? 0 : 1)
    }
}
