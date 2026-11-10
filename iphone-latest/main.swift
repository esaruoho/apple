// iPhoneLatest — its own 📱 menu-bar icon (NOT AppleToolbox). Click = grab the
// newest photo off the USB-cabled iPhone (bin/iphone-latest → JPEG → clipboard)
// and show a draggable thumbnail. Right-click = Help / Quit.
// FEATURE-CARD >> features/iphone-latest.feature
import Cocoa
import SwiftUI

let SCRIPT = NSString(string: "~/work/apple/bin/iphone-latest").expandingTildeInPath
let OUTDIR = NSString(string: "~/Pictures/iPhone-Latest").expandingTildeInPath

final class DragView: NSImageView, NSDraggingSource {
    var fileURL: URL?
    func draggingSession(_ s: NSDraggingSession, sourceOperationMaskFor c: NSDraggingContext) -> NSDragOperation { .copy }
    override func mouseDown(with e: NSEvent) {
        guard let u = fileURL, let img = image else { return }
        let it = NSDraggingItem(pasteboardWriter: u as NSURL)
        it.setDraggingFrame(bounds, contents: img)
        beginDraggingSession(with: [it], event: e, source: self)
    }
}

final class App: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    var item: NSStatusItem!
    var thumb: DragView?
    var caption: NSTextField?
    var watcher: Process?
    var pollTimer: Timer?
    var shownPath: String?
    var pop = NSPopover()
    var busy = false

    func applicationDidFinishLaunching(_ n: Notification) {
        // kill watchers orphaned by a previous instance (two ICC sessions = stale catalog)
        let k = Process(); k.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
        k.arguments = ["-f", "iphone-latest --watch"]; try? k.run(); k.waitUntilExit()
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "📱"
        item.button?.toolTip = "Newest iPhone photo (USB) — click"
        item.button?.target = self
        item.button?.action = #selector(click(_:))
        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        pop.behavior = .transient
        pop.delegate = self
    }

    @objc func click(_ b: NSStatusBarButton) {
        if NSApp.currentEvent?.type == .rightMouseUp { return showMenu() }
        grab()   // every click = fresh fetch from the phone
    }

    func showMenu() {
        let m = NSMenu()
        m.addItem(withTitle: "Help / Support Esa…", action: #selector(help), keyEquivalent: "").target = self
        m.addItem(withTitle: "Open folder", action: #selector(openFolder), keyEquivalent: "").target = self
        m.addItem(.separator())
        m.addItem(withTitle: "Quit", action: #selector(NSApp.terminate(_:)), keyEquivalent: "q")
        item.menu = m; item.button?.performClick(nil); item.menu = nil
    }

    @objc func openFolder() {
        NSWorkspace.shared.open(URL(fileURLWithPath: NSString(string: "~/Pictures/iPhone-Latest").expandingTildeInPath))
    }

    @objc func help() {
        let v = AppHelpView(appName: "iPhoneLatest",
            tagline: "Newest iPhone photo, over the cable, into any chat.",
            usage: [(icon: "📱", text: "Click the icon: newest photo → JPEG thumbnail (clipboard untouched)."),
                    (icon: "🖱️", text: "Drag the thumbnail into Terminal / Claude / Mail."),
                    ])
        let vc = NSHostingController(rootView: v)
        pop.contentViewController = vc
        if let b = item.button { pop.show(relativeTo: b.bounds, of: b, preferredEdge: .minY) }
    }

    func newestJPG() -> String? {
        let fm = FileManager.default
        guard let names = try? fm.contentsOfDirectory(atPath: OUTDIR) else { return nil }
        return names.filter { $0.lowercased().hasSuffix(".jpg") }
            .map { OUTDIR + "/" + $0 }
            .max { (mtime($0)) < (mtime($1)) }
    }
    func mtime(_ p: String) -> Date {
        ((try? FileManager.default.attributesOfItem(atPath: p))?[.modificationDate] as? Date) ?? .distantPast
    }

    func grab() {
        // Show the last-known image instantly, then fetch the phone's true newest
        // with a FRESH session (bin/iphone-latest --no-clip) and swap it in.
        if !pop.isShown { showThumb(newestJPG() ?? "") }
        guard !busy else { return }
        busy = true; item.button?.title = "⏳"
        caption?.stringValue = "⏳ fetching newest from iPhone…"
        DispatchQueue.global().async {
            let p = Process(); let pipe = Pipe()
            p.executableURL = URL(fileURLWithPath: SCRIPT)
            p.arguments = ["--no-clip"]
            p.standardOutput = pipe; p.standardError = FileHandle.nullDevice
            try? p.run(); p.waitUntilExit()
            let out = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
                .split(separator: "\n").last.map(String.init) ?? ""
            DispatchQueue.main.async {
                self.busy = false; self.item.button?.title = "📱"
                if out.hasSuffix(".jpg") { self.updateThumb(out) }
                else { self.caption?.stringValue = "⚠️ iPhone cabled + unlocked? Click 📱 to retry" }
            }
        }
    }

    func showThumb(_ path: String) {
        let vc = NSViewController()
        guard path.hasSuffix(".jpg"), let img = NSImage(contentsOfFile: path) else {
            let l = NSTextField(labelWithString: "  No photo — iPhone cabled + unlocked?  ")
            l.frame = NSRect(x: 0, y: 0, width: 260, height: 40)
            vc.view = l; pop.contentViewController = vc
            if let b = item.button { pop.show(relativeTo: b.bounds, of: b, preferredEdge: .minY) }
                return
        }
        let w: CGFloat = 240, h = max(80, min(340, w * img.size.height / max(1, img.size.width)))
        let root = NSView(frame: NSRect(x: 0, y: 0, width: w, height: h + 26))
        let iv = DragView(frame: NSRect(x: 0, y: 26, width: w, height: h))
        iv.image = img; iv.imageScaling = .scaleProportionallyUpOrDown
        iv.fileURL = URL(fileURLWithPath: path); shownPath = path
        let l = NSTextField(labelWithString: "Drag into chat")
        l.font = .systemFont(ofSize: 10); l.alignment = .center
        l.frame = NSRect(x: 0, y: 5, width: w, height: 16)
        root.addSubview(iv); root.addSubview(l)
        thumb = iv; caption = l
        vc.view = root; pop.contentViewController = vc
        if let b = item.button { pop.show(relativeTo: b.bounds, of: b, preferredEdge: .minY) }
    }

    // Live refresh: while the thumbnail is open, `iphone-latest --watch` prints a
    // jpg path per NEW photo; swap it into the same view (+ it's on the clipboard).
    func startWatcher() {
        guard watcher?.isRunning != true else { return }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: SCRIPT)
        p.arguments = ["--watch", "--no-clip"]
        p.standardOutput = FileHandle.nullDevice; p.standardError = FileHandle.nullDevice
        try? p.run(); watcher = p
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.poll() }
    }

    func poll() {
        guard thumb != nil, let n = newestJPG(), n != shownPath else { return }
        updateThumb(n)
    }

    func stopWatcher() {
        pollTimer?.invalidate(); pollTimer = nil
        guard let p = watcher else { return }
        if p.isRunning {
            // kill the child iphone-import too (it's in the script's process group)
            p.terminate()
            let k = Process(); k.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
            k.arguments = ["-P", String(p.processIdentifier)]; try? k.run()
        }
        watcher = nil
    }

    func updateThumb(_ path: String) {
        guard let iv = thumb, let img = NSImage(contentsOfFile: path) else { return }
        iv.image = img; iv.fileURL = URL(fileURLWithPath: path); shownPath = path
        caption?.stringValue = "🆕 " + (path as NSString).lastPathComponent + " · drag into chat · click 📱 to refresh"
    }

    func applicationWillTerminate(_ n: Notification) { stopWatcher() }

    func popoverDidClose(_ n: Notification) {
        stopWatcher(); thumb = nil; caption = nil
    }
}

let app = NSApplication.shared
let d = App(); app.delegate = d
app.setActivationPolicy(.accessory)
app.run()
