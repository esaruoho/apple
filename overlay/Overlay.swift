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

/// Borderless + non-activating, but still able to take the keyboard.
///
/// A borderless window refuses key status unless you override this; without it Esc
/// and ⌘Z would never arrive and draw mode would be a one-way door.
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

    var colorHex = Hex.palette[0]
    var strokeWidth: Double = 3
    var displayName = ""

    var mode: OverlayMode = .passthrough {
        didSet {
            guard mode != oldValue else { return }
            // Dropping the live stroke on a mode flip prevents a half-drawn line
            // being stranded on screen when you hit Esc mid-drag.
            live = []
            needsDisplay = true
            window?.invalidateCursorRects(for: self)
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

        for object in store.objects {
            // Only paint what intersects the invalidated rect. Without this, every
            // mouse-drag sample would re-stroke the entire canvas.
            let box = object.bounds.insetBy(dx: -CGFloat(object.width) - 2,
                                            dy: -CGFloat(object.width) - 2)
            guard box.isNull || box.intersects(dirtyRect) else { continue }
            stroke(points: object.points, hex: object.colorHex, width: object.width)
        }

        if !live.isEmpty {
            stroke(points: live, hex: colorHex, width: strokeWidth)
        }

        if mode == .draw { drawModeChrome() }
    }

    private func stroke(points: [CGPoint], hex: String, width: Double) {
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
        color(hex).setStroke()
        path.stroke()
    }

    private func color(_ hex: String) -> NSColor {
        guard let c = Hex.parse(hex) else { return .systemRed }
        return NSColor(srgbRed: c.r, green: c.g, blue: c.b, alpha: c.a)
    }

    /// Draw mode has to be unmistakable — an overlay that silently eats your clicks
    /// is indistinguishable from a frozen Mac.
    private func drawModeChrome() {
        let border = NSBezierPath(rect: bounds.insetBy(dx: 1.5, dy: 1.5))
        border.lineWidth = 3
        color(colorHex).withAlphaComponent(0.85).setStroke()
        border.stroke()

        let text = "DRAW  ·  esc exit  ·  ⌘Z undo  ·  1-6 colour  ·  [ ] size  ·  ⌘⌫ clear"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .medium),
            .foregroundColor: NSColor.white,
        ]
        let size = (text as NSString).size(withAttributes: attrs)
        let chip = CGRect(x: bounds.midX - size.width / 2 - 10, y: 18,
                          width: size.width + 20, height: size.height + 10)
        NSColor.black.withAlphaComponent(0.72).setFill()
        NSBezierPath(roundedRect: chip, xRadius: 7, yRadius: 7).fill()
        (text as NSString).draw(at: CGPoint(x: chip.minX + 10, y: chip.minY + 5),
                                withAttributes: attrs)

        // The live colour and width, shown as an actual swatch rather than a number.
        let swatch = CGRect(x: chip.maxX + 8, y: chip.midY - CGFloat(strokeWidth) / 2,
                            width: 34, height: max(2, CGFloat(strokeWidth)))
        color(colorHex).setFill()
        NSBezierPath(roundedRect: swatch,
                     xRadius: CGFloat(strokeWidth) / 2,
                     yRadius: CGFloat(strokeWidth) / 2).fill()
    }

    override func resetCursorRects() {
        // Only claim the cursor in draw mode; in passthrough the pointer belongs to
        // whatever app is underneath.
        if mode == .draw { addCursorRect(bounds, cursor: .crosshair) }
    }

    // ── pointer ──

    override func mouseDown(with event: NSEvent) {
        guard mode == .draw else { return }
        live = [convert(event.locationInWindow, from: nil)]
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard mode == .draw, !live.isEmpty else { return }
        let p = convert(event.locationInWindow, from: nil)
        let previous = live[live.count - 1]
        live.append(p)
        // Invalidate just the segment that appeared, padded for line width and caps.
        let pad = CGFloat(strokeWidth) + 4
        setNeedsDisplay(Geometry.bounds([previous, p]).insetBy(dx: -pad, dy: -pad))
    }

    override func mouseUp(with event: NSEvent) {
        guard mode == .draw, !live.isEmpty else { return }
        let points = Geometry.decimate(live, minDistance: 1.5)
        live = []
        store.add(OverlayObject(points: points,
                                colorHex: colorHex,
                                width: strokeWidth,
                                actor: "human:esa",
                                lifetime: .persistent,
                                anchor: OverlayAnchor(type: .screen, display: displayName)))
        needsDisplay = true
        manager?.persist()
    }

    // ── keyboard ──

    override func keyDown(with event: NSEvent) {
        let cmd = event.modifierFlags.contains(.command)
        let shift = event.modifierFlags.contains(.shift)

        switch Int(event.keyCode) {
        case kVK_Escape:
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

        panel = OverlayPanel(contentRect: screen.frame,
                             styleMask: [.borderless, .nonactivatingPanel],
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
    private func ensureCanvasesHere() {
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
            // An .accessory app must actually activate for keystrokes to reach the
            // panel; .nonactivatingPanel keeps the visual disruption to a minimum.
            if activatesOnDraw { NSApp.activate(ignoringOtherApps: true) }
            if let target = canvasUnderPointer() ?? here.first {
                target.panel.makeKeyAndOrderFront(nil)
                target.panel.makeFirstResponder(target.view)
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

    func clearHere() {
        for canvas in here { canvas.view.store.clear(); canvas.view.needsDisplay = true }
        persist()
    }

    func clearAll() {
        for canvas in canvases { canvas.view.store.clear(); canvas.view.needsDisplay = true }
        persist()
    }

    var markCount: Int { canvases.reduce(0) { $0 + $1.view.store.objects.count } }

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
    private var helpWindow: NSWindow?

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
        manager.onModeChange = { [weak self] _ in self?.refreshStatusItem() }
        refreshStatusItem()

        NotificationCenter.default.addObserver(
            forName: .showAppHelp, object: nil, queue: .main) { [weak self] _ in
                self?.showHelp(nil)
            }

        NSLog("Overlay: ready — ⌃⌥⌘D toggles draw mode")
    }

    // ── menu bar ──

    private func buildStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        let menu = NSMenu()
        let draw = NSMenuItem(title: "Draw Mode", action: #selector(toggleDraw), keyEquivalent: "")
        draw.target = self
        menu.addItem(draw)
        menu.addItem(.separator())

        for (title, selector, key) in [
            ("Undo Last Mark", #selector(undoHere), "z"),
            ("Clear This Canvas", #selector(clearHere), ""),
            ("Clear All Canvases", #selector(clearAll), ""),
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
            DispatchQueue.main.async { if id.id == 1 { me.toggleDraw() } }
            return noErr
        }, 1, &spec, selfPtr, nil)

        let mods = UInt32(controlKey | optionKey | cmdKey)
        let id = EventHotKeyID(signature: OSType(0x4F564C44), id: 1)   // 'OVLD'
        let status = RegisterEventHotKey(UInt32(kVK_ANSI_D), mods, id,
                                         GetApplicationEventTarget(), 0, &hotKeyRef)
        if status != noErr {
            NSLog("Overlay: ⌃⌥⌘D registration failed with OSStatus \(status)")
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
