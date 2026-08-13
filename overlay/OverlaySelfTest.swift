// OverlaySelfTest — the AppKit half of the test suite.
//
// overlay-tests.swift covers the pure core. This covers what only a real window
// server can answer: is the panel actually transparent, actually floating, actually
// click-through, actually confined to one Space, and does a real drag on a real view
// actually produce a stored OverlayObject.
//
// Run:  Overlay.app/Contents/MacOS/Overlay --selftest
//
// Events are constructed with NSEvent.mouseEvent / .keyEvent and handed DIRECTLY to
// the view. Nothing is posted to the event system and no System Events keystrokes are
// synthesized, so this cannot hijack whatever app is frontmost
// (feedback_never_ui_hijack_active_session).

import Cocoa
import Carbon.HIToolbox   // kVK_* virtual key codes

enum OverlaySelfTest {

    private static var passed = 0
    private static var failed = 0

    private static func check(_ cond: Bool, _ msg: String) {
        if cond { passed += 1; print("ok   - \(msg)") }
        else    { failed += 1; print("FAIL - \(msg)") }
    }

    // ── synthetic events, delivered straight to the view ──

    private static func mouse(_ type: NSEvent.EventType, _ p: CGPoint,
                              in panel: NSPanel) -> NSEvent {
        NSEvent.mouseEvent(with: type,
                           location: p,                    // window coordinates
                           modifierFlags: [],
                           timestamp: ProcessInfo.processInfo.systemUptime,
                           windowNumber: panel.windowNumber,
                           context: nil,
                           eventNumber: 0,
                           clickCount: 1,
                           pressure: 1)!
    }

    private static func key(_ code: Int, _ chars: String,
                            _ flags: NSEvent.ModifierFlags = [],
                            in panel: NSPanel) -> NSEvent {
        NSEvent.keyEvent(with: .keyDown,
                         location: .zero,
                         modifierFlags: flags,
                         timestamp: ProcessInfo.processInfo.systemUptime,
                         windowNumber: panel.windowNumber,
                         context: nil,
                         characters: chars,
                         charactersIgnoringModifiers: chars,
                         isARepeat: false,
                         keyCode: UInt16(code))!
    }

    /// Drag a closed square, the way Esa will: down, several drags, up.
    private static func drawSquare(in canvas: Canvas, at origin: CGPoint, side: CGFloat) {
        let v = canvas.view, p = canvas.panel
        let corners = [origin,
                       CGPoint(x: origin.x + side, y: origin.y),
                       CGPoint(x: origin.x + side, y: origin.y + side),
                       CGPoint(x: origin.x, y: origin.y + side),
                       origin]
        v.mouseDown(with: mouse(.leftMouseDown, corners[0], in: p))
        for c in corners.dropFirst() {
            // Several samples per edge, so decimation has something to chew on.
            for t in stride(from: 0.25, through: 1.0, by: 0.25) {
                let prev = corners[max(0, corners.firstIndex(of: c)! - 1)]
                let pt = CGPoint(x: prev.x + (c.x - prev.x) * t,
                                 y: prev.y + (c.y - prev.y) * t)
                v.mouseDragged(with: mouse(.leftMouseDragged, pt, in: p))
            }
        }
        v.mouseUp(with: mouse(.leftMouseUp, corners.last!, in: p))
    }

    // ── the suite ──

    static func run(manager: OverlayManager) -> Int {
        print("── Overlay AppKit self-test ──\n")

        // 1. activation policy
        check(NSApp.activationPolicy() == .accessory,
              "app is .accessory — no Dock tile, no Cmd-Tab slot")

        // 2. cold state
        check(manager.mode == .passthrough, "starts in passthrough, not draw")
        check(manager.canvases.isEmpty, "no canvas is created until one is needed")

        // 3. entering draw mode materialises a canvas per display
        manager.setMode(.draw)
        check(manager.mode == .draw, "mode flipped to draw")
        check(manager.canvases.count == NSScreen.screens.count,
              "one canvas per display (\(NSScreen.screens.count) screen(s))")
        guard let canvas = manager.here.first else {
            print("FAIL - no canvas on the active Space; cannot continue")
            return 1
        }
        check(manager.here.count == manager.canvases.count,
              "every canvas is on the Space it was created in")

        let panel = canvas.panel

        // 4. the panel is genuinely an overlay
        check(!panel.isOpaque, "panel is not opaque")
        check(panel.backgroundColor.alphaComponent == 0, "panel background is fully clear")
        check(!panel.hasShadow, "panel casts no shadow")
        check(panel.level == .floating, "panel sits at .floating, above ordinary windows")
        check(panel.isVisible, "panel is on screen")
        check(panel.styleMask.contains(.borderless), "panel is borderless")
        check(!panel.styleMask.contains(.nonactivatingPanel),
              "panel is NOT non-activating — that flag makes NSApp.activate a no-op on "
            + "an .accessory app, which cost Esc, undo and the crosshair")
        check(panel.canBecomeKey, "panel can take the keyboard (Esc / ⌘Z depend on it)")
        check(!panel.canBecomeMain, "panel never becomes the main window")

        // 5. Spaces semantics — the whole reason this is a managed window
        check(!panel.collectionBehavior.contains(.canJoinAllSpaces),
              "panel does NOT join all Spaces — screen ink belongs to one desktop")
        check(panel.collectionBehavior.contains(.fullScreenAuxiliary),
              "panel may appear over a fullscreen app's Space")
        check(panel.isOnActiveSpace, "panel reports itself on the active Space")

        // 6. geometry matches its display exactly
        if let screen = NSScreen.screens.first(where: { canvas.matches(screen: $0) }) {
            check(panel.frame == screen.frame,
                  "panel frame == screen frame (\(Int(screen.frame.width))×\(Int(screen.frame.height)))")
            check(canvas.view.bounds.size == screen.frame.size, "view fills the panel")
        } else {
            check(false, "canvas maps back to a live NSScreen")
        }
        check(canvas.displayName.isEmpty == false, "canvas knows its display name")

        // 7. click-through is the state that decides whether the Mac is usable
        check(panel.ignoresMouseEvents == false, "draw mode: panel accepts the mouse")
        manager.setMode(.passthrough)
        check(panel.ignoresMouseEvents == true,
              "passthrough: panel ignores the mouse — clicks reach the app underneath")
        check(canvas.view.mode == .passthrough, "the view was told about the mode change")
        check(panel.isVisible, "the ink stays on screen in passthrough (only input changes)")

        // 8. a real drag produces a real stored object
        manager.setMode(.draw)
        let before = canvas.view.store.objects.count
        drawSquare(in: canvas, at: CGPoint(x: 300, y: 300), side: 200)
        let objects = canvas.view.store.objects
        check(objects.count == before + 1, "one drag → exactly one stored object")
        guard let square = objects.last else { return finish() }
        check(square.kind == .ink, "it is an ink object")
        check(square.actor == "human:esa", "provenance is recorded as human:esa")
        check(square.lifetime == .persistent, "human ink is persistent, not TTL'd")
        check(square.points.count > 4, "the drag kept its samples")
        check(square.points.count < 17, "…but decimation dropped the redundant ones")
        check(square.anchor.type == .screen, "anchored to the screen")
        check(square.anchor.display == canvas.displayName, "anchor names the display it was drawn on")

        // 9. the bounding box is the crop rect P1 hands to a model — the thing Esa
        //    actually wants: draw a square, get exactly that region.
        let b = square.bounds
        check(abs(b.minX - 300) < 2 && abs(b.minY - 300) < 2,
              "bounding box origin matches where the square was drawn")
        check(abs(b.width - 200) < 2 && abs(b.height - 200) < 2,
              "bounding box size matches the square (200×200)")
        let crop = square.cropRect(in: canvas.view.bounds, pad: 24)
        check(canvas.view.bounds.contains(crop), "the crop rect stays inside the screen")
        check(abs(crop.width - 248) < 2, "the crop rect is the square plus padding")

        // 10. keyboard, delivered straight to the view
        canvas.view.keyDown(with: key(kVK_ANSI_2, "2", [], in: panel))
        check(canvas.view.colorHex == Hex.palette[1], "key '2' picks the second colour")
        let w0 = canvas.view.strokeWidth
        canvas.view.keyDown(with: key(kVK_ANSI_RightBracket, "]", [], in: panel))
        check(canvas.view.strokeWidth == w0 + 1, "']' widens the stroke")
        canvas.view.keyDown(with: key(kVK_ANSI_LeftBracket, "[", [], in: panel))
        check(canvas.view.strokeWidth == w0, "'[' narrows it back")

        canvas.view.keyDown(with: key(kVK_ANSI_Z, "z", [.command], in: panel))
        check(canvas.view.store.objects.count == before, "⌘Z undid the square")
        canvas.view.keyDown(with: key(kVK_ANSI_Z, "z", [.command, .shift], in: panel))
        check(canvas.view.store.objects.count == before + 1, "⇧⌘Z redid it")

        // 12. persistence — checked BEFORE Esc, because Esc now clears the canvas as
        //     well as leaving draw mode. That is deliberate (Esa could not get rid of
        //     anything otherwise) and this ordering keeps the test honest about it.
        manager.persist()
        let session = OverlayPaths.session
        check(FileManager.default.fileExists(atPath: session.path),
              "persist() wrote \(session.path)")
        if let store = try? OverlayStore.load(from: session) {
            check(store.objects.count == manager.markCount,
                  "the file holds every mark across every canvas")
            check(store.objects.contains { $0.id == square.id },
                  "the square survived the roundtrip to disk")
        } else {
            check(false, "the persisted file parses back")
        }

        // 11. Esc leaves draw mode AND clears — one key to get your screen back.
        canvas.view.keyDown(with: key(kVK_Escape, "\u{1b}", [], in: panel))
        check(manager.mode == .passthrough, "Esc leaves draw mode")
        check(panel.ignoresMouseEvents, "…and the panel goes click-through again")
        check(manager.markCount == 0, "…and Esc clears the canvas, so nothing is stranded")

        // 13. clearing
        manager.clearHere()
        check(canvas.view.store.objects.isEmpty, "Clear This Canvas empties it")
        check(manager.markCount == 0, "…and the total mark count goes to zero")

        // ═══════════════ P1: agents ═══════════════

        // 14. an agent posts, and it lands — without disturbing the input mode
        manager.setMode(.passthrough)
        let failure = manager.post([
            decode(#"{"kind":"box","rel":{"x":0.1,"y":0.2,"w":0.3,"h":0.1},"actor":"agent:fm"}"#)
        ])
        check(failure == nil, "a valid post is accepted")
        check(manager.markCount == 1, "…and appears on a canvas")
        check(manager.mode == .passthrough,
              "posting NEVER enters draw mode — Esa keeps typing while an agent draws")
        check(panel.ignoresMouseEvents,
              "…and the overlay stays click-through while agent marks are up")
        if let posted = canvas.view.store.objects.last {
            check(posted.actor == "agent:fm", "the actor is recorded")
            check(posted.lifetime == .session, "an omitted ttl defaults to session")
            check(abs(posted.rect.width - canvas.view.bounds.width * 0.3) < 1,
                  "rel geometry resolved against this display's real size")
        }

        // 15. a bad post is refused with a reason, and nothing lands
        let refused = manager.post([decode(#"{"kind":"label","at":[10,10]}"#)])
        check(refused != nil, "a label with no text is refused")
        check(refused?.contains("requires text") == true, "…with a reason worth reading")
        check(manager.markCount == 1, "…and nothing was added")

        // 16. every kind actually renders — a smoke test through the real draw path
        manager.clear(actor: nil)
        let mid = CGPoint(x: canvas.view.bounds.midX, y: canvas.view.bounds.midY)
        for kind in ObjectKind.allCases {
            let points: [CGPoint] = kind.minimumPoints >= 2
                ? [CGPoint(x: mid.x - 120, y: mid.y - 80), CGPoint(x: mid.x + 120, y: mid.y + 80)]
                : [mid]
            canvas.view.store.add(OverlayObject(kind: kind, points: points,
                                                actor: "agent:selftest",
                                                lifetime: .session,
                                                text: kind.needsText ? "test \(kind.rawValue)" : nil))
        }
        check(canvas.view.store.objects.count == ObjectKind.allCases.count,
              "one object of every kind (\(ObjectKind.allCases.count)) is on the canvas")
        // display() runs the real draw(_:) — a crash or a bad path shows up here.
        canvas.view.display()
        check(true, "all \(ObjectKind.allCases.count) kinds render without crashing")

        // 17. clear by actor leaves human ink alone
        canvas.view.store.add(OverlayObject(points: [mid, CGPoint(x: mid.x + 10, y: mid.y)],
                                            actor: "human:esa"))
        let total = manager.markCount
        manager.clear(actor: "agent:selftest")
        check(manager.markCount == 1, "clearing one actor removed only its marks")
        check(canvas.view.store.objects.first?.actor == "human:esa",
              "…and the human's ink survived (was \(total) marks)")

        // 18. the TTL collector only exists while something ephemeral does
        manager.clear(actor: nil)
        manager.syncTTLCollector()
        check(manager.hasTTLCollector == false,
              "no ephemeral marks → no timer running (nothing ticks at idle)")
        _ = manager.post([decode(
            #"{"kind":"box","rel":{"x":0,"y":0,"w":0.2,"h":0.2},"ttl":"ephemeral"}"#)])
        check(manager.hasTTLCollector, "an ephemeral mark starts the collector")
        manager.clear(actor: nil)
        check(manager.hasTTLCollector == false, "…and removing it stops the collector again")

        return finish()
    }

    /// Test-local convenience: a PostRequest from a literal, or a fatal error — a
    /// malformed literal in the test file is a bug in the test, not a finding.
    private static func decode(_ json: String) -> PostRequest {
        guard let r = try? PostRequest.decodeBatch(Data(json.utf8)).first, let one = Optional(r)
        else { fatalError("self-test literal is not a valid PostRequest: \(json)") }
        return one
    }

    private static func finish() -> Int {
        print("\n\(passed) passed, \(failed) failed")
        return failed == 0 ? 0 : 1
    }
}
