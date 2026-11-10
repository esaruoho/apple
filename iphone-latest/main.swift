// iPhoneLatest — 📱 menu-bar icon. Click → the iPhone camera opens (Continuity
// Camera) → take the photo, tap Use Photo → thumbnail appears → drag it into chat.
// That's all. No USB, no watchers, no notifications (see FINDINGS.md for why).
// Photos are saved to ~/Pictures/iPhone-Latest/Continuity-<timestamp>.jpg.
// FEATURE-CARD >> features/iphone-latest.feature
import Cocoa
import SwiftUI
import ServiceManagement

let OUTDIR = NSString(string: "~/Pictures/iPhone-Latest").expandingTildeInPath

func L(_ m: String) {
    let line = "\(Date()) \(m)\n"
    let path = NSString(string: "~/Library/Logs/iphone-latest-app.log").expandingTildeInPath
    if let h = FileHandle(forWritingAtPath: path) { h.seekToEndOfFile(); h.write(line.data(using: .utf8)!); h.closeFile() }
    else { try? line.write(toFile: path, atomically: true, encoding: .utf8) }
}

/// The thumbnail. Drag only — a drag starts after the mouse moves >4pt, so plain
/// clicks never flash a drag image.
final class DragView: NSImageView, NSDraggingSource {
    var fileURL: URL?
    var downAt: NSPoint?
    func draggingSession(_ s: NSDraggingSession, sourceOperationMaskFor c: NSDraggingContext) -> NSDragOperation { .copy }
    override func mouseDown(with e: NSEvent) { downAt = e.locationInWindow }
    override func mouseUp(with e: NSEvent) { downAt = nil }
    override func mouseDragged(with e: NSEvent) {
        guard let d = downAt, let u = fileURL, let img = image else { return }
        let p = e.locationInWindow
        guard hypot(p.x - d.x, p.y - d.y) > 4 else { return }
        downAt = nil
        let it = NSDraggingItem(pasteboardWriter: u as NSURL)
        it.setDraggingFrame(bounds, contents: img)
        beginDraggingSession(with: [it], event: e, source: self)
    }
}

/// Receives the photo the iPhone sends back after "Take Photo" and saves it as JPEG.
func savePhoto(from pb: NSPasteboard) -> String? {
    guard let img = NSImage(pasteboard: pb), let tiff = img.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let jpg = rep.representation(using: .jpeg, properties: [.compressionFactor: 0.88]) else {
        L("no image on pasteboard"); return nil
    }
    let f = DateFormatter(); f.dateFormat = "yyyyMMdd-HHmmss"
    try? FileManager.default.createDirectory(atPath: OUTDIR, withIntermediateDirectories: true)
    let path = OUTDIR + "/Continuity-" + f.string(from: Date()) + ".jpg"
    do { try jpg.write(to: URL(fileURLWithPath: path)) } catch { L("write failed: \(error)"); return nil }
    L("got \(rep.pixelsWide)x\(rep.pixelsHigh) → \(path)")
    return path
}

final class CaptureView: NSView, NSServicesMenuRequestor {
    var onImage: ((String) -> Void)?
    override var acceptsFirstResponder: Bool { true }
    override func validRequestor(forSendType s: NSPasteboard.PasteboardType?, returnType r: NSPasteboard.PasteboardType?) -> Any? {
        if s == nil, let r = r, NSImage.imageTypes.contains(r.rawValue) { return self }
        return super.validRequestor(forSendType: s, returnType: r)
    }
    func readSelection(from pb: NSPasteboard) -> Bool {
        guard let p = savePhoto(from: pb) else { return false }
        DispatchQueue.main.async { self.onImage?(p) }
        return true
    }
}

final class App: NSObject, NSApplicationDelegate, NSPopoverDelegate, NSServicesMenuRequestor {
    var item: NSStatusItem!
    let pop = NSPopover()
    var thumb: DragView?
    var caption: NSTextField?
    var captureView: CaptureView?
    var capturing = false
    var closedAt = Date.distantPast

    // AppKit only activates the Continuity "Import from iPhone" item when it lives in
    // the MAIN menu (probe-verified; pop-up menus stay grey).
    lazy var importMenu: NSMenu = {
        let main = NSMenu(); let fileItem = NSMenuItem(); let file = NSMenu(title: "File")
        let imp = NSMenuItem(title: "Import from iPhone", action: nil, keyEquivalent: "")
        imp.identifier = NSMenuItem.importFromDeviceIdentifier
        file.addItem(imp); fileItem.submenu = file; main.addItem(fileItem)
        NSApp.mainMenu = main
        return file
    }()

    func applicationDidFinishLaunching(_ n: Notification) {
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "📱"
        item.button?.toolTip = "Take a photo with the iPhone"
        item.button?.target = self
        item.button?.action = #selector(click(_:))
        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        pop.behavior = .transient
        pop.delegate = self
        _ = importMenu
        // First launch: turn Open at Login on (toggle lives in the right-click menu).
        if !UserDefaults.standard.bool(forKey: "loginItemInitialized") {
            UserDefaults.standard.set(true, forKey: "loginItemInitialized")
            setOpenAtLogin(true)
        }
    }

    // MARK: Open at Login (SMAppService — Apple's login-item API, macOS 13+)

    var opensAtLogin: Bool { SMAppService.mainApp.status == .enabled }
    func setOpenAtLogin(_ on: Bool) {
        do { if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() } }
        catch { L("login item \(on ? "register" : "unregister") failed: \(error)") }
        L("open at login: \(opensAtLogin)")
    }
    @objc func toggleLogin() { setOpenAtLogin(!opensAtLogin) }

    @objc func click(_ b: NSStatusBarButton) {
        if NSApp.currentEvent?.type == .rightMouseUp { return showMenu() }
        // Icon click while the thumbnail is open = dismiss. (The transient popover closes
        // itself on that same click before we get here, so check how recently it closed.)
        if pop.isShown || Date().timeIntervalSince(closedAt) < 0.5 {
            pop.performClose(nil); L("click: dismiss"); return
        }
        L("click: take photo")
        showThumb(newestJPG())
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { self.takePhoto() }
    }

    // MARK: Continuity Camera

    func findTakePhoto(_ m: NSMenu) -> (NSMenu, Int)? {
        for (i, it) in m.items.enumerated() {
            if it.title.localizedCaseInsensitiveContains("Take Photo"), it.action != nil { return (m, i) }
            if let sub = it.submenu, let r = findTakePhoto(sub) { return r }
        }
        return nil
    }

    func takePhoto() {
        guard let root = captureView else { return }
        if capturing { L("already waiting for a photo"); return }
        NSApp.activate(ignoringOtherApps: true)
        root.window?.makeKeyAndOrderFront(nil)
        root.window?.makeFirstResponder(root)
        importMenu.update()
        if findTakePhoto(importMenu) == nil {
            // AppKit fills the submenu only once the menu has been opened: open it and
            // cancel it 0.4s later, then fire Take Photo ourselves.
            L("priming menu")
            let t = Timer(timeInterval: 0.4, repeats: false) { [weak self] _ in self?.importMenu.cancelTracking() }
            RunLoop.main.add(t, forMode: .common)
            importMenu.popUp(positioning: nil, at: NSPoint(x: 10, y: 30), in: root)
            importMenu.update()
        }
        guard let (m, i) = findTakePhoto(importMenu) else {
            L("Take Photo unavailable")
            caption?.stringValue = "⚠️ iPhone camera unavailable (Wi-Fi + Bluetooth, same Apple ID?)"
            return
        }
        capturing = true
        caption?.stringValue = "📷 Take the photo on your iPhone…"
        L("firing \(m.items[i].title)")
        m.performActionForItem(at: i)
    }

    func gotPhoto(_ path: String) {
        capturing = false
        if pop.isShown, thumb != nil { updateThumb(path) } else { showThumb(path) }
    }

    // End-of-chain requestor (NSApplication asks its delegate) — same handling.
    @objc func validRequestor(forSendType s: NSPasteboard.PasteboardType?, returnType r: NSPasteboard.PasteboardType?) -> Any? {
        if s == nil, let r = r, NSImage.imageTypes.contains(r.rawValue) { return self }
        return nil
    }
    @objc func readSelection(from pb: NSPasteboard) -> Bool {
        guard let p = savePhoto(from: pb) else { return false }
        DispatchQueue.main.async { self.gotPhoto(p) }
        return true
    }

    // MARK: Thumbnail

    func newestJPG() -> String? {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: OUTDIR)) ?? []
        return names.filter { $0.hasPrefix("Continuity-") && $0.hasSuffix(".jpg") }.sorted().last.map { OUTDIR + "/" + $0 }
    }

    func showThumb(_ path: String?) {
        let img = path.flatMap { NSImage(contentsOfFile: $0) }
        let w: CGFloat = 240
        let h: CGFloat = img.map { max(80, min(340, w * $0.size.height / max(1, $0.size.width))) } ?? 80
        let root = CaptureView(frame: NSRect(x: 0, y: 0, width: w, height: h + 46))
        root.onImage = { [weak self] p in self?.gotPhoto(p) }
        let iv = DragView(frame: NSRect(x: 0, y: 46, width: w, height: h))
        iv.imageScaling = .scaleProportionallyUpOrDown
        if let img = img, let p = path { iv.image = img; iv.fileURL = URL(fileURLWithPath: p) }
        let l = NSTextField(labelWithString: img == nil ? "No photo yet" : "Drag into chat · click 📱 for another")
        l.font = .systemFont(ofSize: 10); l.alignment = .center
        l.frame = NSRect(x: 0, y: 26, width: w, height: 16)
        // clickable row → open the folder with every photo taken
        let folder = NSButton(title: "📂 Open iPhone-Latest folder", target: self, action: #selector(openFolder))
        folder.isBordered = false; folder.font = .systemFont(ofSize: 11)
        folder.contentTintColor = .linkColor
        folder.frame = NSRect(x: 0, y: 4, width: w, height: 18)
        root.addSubview(iv); root.addSubview(l); root.addSubview(folder)
        thumb = iv; caption = l; captureView = root
        let vc = NSViewController(); vc.view = root
        pop.contentViewController = vc
        if let b = item.button { pop.show(relativeTo: b.bounds, of: b, preferredEdge: .minY) }
    }

    func updateThumb(_ path: String) {
        guard let iv = thumb, let img = NSImage(contentsOfFile: path) else { return }
        iv.image = img; iv.fileURL = URL(fileURLWithPath: path)
        caption?.stringValue = "Drag into chat · click 📱 for another"
    }

    func popoverDidClose(_ n: Notification) { capturing = false; thumb = nil; caption = nil; closedAt = Date() }

    // MARK: Right-click menu

    func showMenu() {
        let m = NSMenu()
        m.addItem(withTitle: "Help / Support Esa…", action: #selector(help), keyEquivalent: "").target = self
        m.addItem(withTitle: "Open folder", action: #selector(openFolder), keyEquivalent: "").target = self
        let login = NSMenuItem(title: "Open at Login", action: #selector(toggleLogin), keyEquivalent: "")
        login.target = self; login.state = opensAtLogin ? .on : .off
        m.addItem(login)
        m.addItem(.separator())
        m.addItem(withTitle: "Quit", action: #selector(NSApp.terminate(_:)), keyEquivalent: "q")
        item.menu = m; item.button?.performClick(nil); item.menu = nil
    }
    @objc func openFolder() {
        pop.performClose(nil)
        try? FileManager.default.createDirectory(atPath: OUTDIR, withIntermediateDirectories: true)
        NSWorkspace.shared.open(URL(fileURLWithPath: OUTDIR))
    }
    @objc func help() {
        let v = AppHelpView(appName: "iPhoneLatest",
            tagline: "Take a photo with your iPhone, drag it into any chat.",
            usage: [(icon: "📱", text: "Click the icon: the iPhone camera opens."),
                    (icon: "📷", text: "Take the photo, tap Use Photo — the thumbnail updates."),
                    (icon: "🖱️", text: "Drag the thumbnail into Terminal / Claude / Mail.")])
        pop.contentViewController = NSHostingController(rootView: v)
        if let b = item.button { pop.show(relativeTo: b.bounds, of: b, preferredEdge: .minY) }
    }
}

let app = NSApplication.shared
let d = App(); app.delegate = d
app.setActivationPolicy(.accessory)
app.run()
