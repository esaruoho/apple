// iPhoneLatest — its own 📱 menu-bar icon (NOT AppleToolbox). Click = grab the
// newest photo off the USB-cabled iPhone (bin/iphone-latest → JPEG → clipboard)
// and show a draggable thumbnail. Right-click = Help / Quit.
// FEATURE-CARD >> features/iphone-latest.feature
import Cocoa
import SwiftUI

let SCRIPT = NSString(string: "~/work/apple/bin/iphone-latest").expandingTildeInPath

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

final class App: NSObject, NSApplicationDelegate {
    var item: NSStatusItem!
    var pop = NSPopover()
    var busy = false

    func applicationDidFinishLaunching(_ n: Notification) {
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "📱"
        item.button?.toolTip = "Newest iPhone photo (USB) — click"
        item.button?.target = self
        item.button?.action = #selector(click(_:))
        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        pop.behavior = .transient
    }

    @objc func click(_ b: NSStatusBarButton) {
        if NSApp.currentEvent?.type == .rightMouseUp { return showMenu() }
        if pop.isShown { pop.performClose(nil); return }
        grab()
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
            usage: [(icon: "📱", text: "Click the icon: newest photo → JPEG → clipboard."),
                    (icon: "🖱️", text: "Drag the thumbnail into Terminal / Claude / Mail."),
                    (icon: "⌨️", text: "Or just ⌘V / Ctrl-V — it's already on the clipboard.")])
        let vc = NSHostingController(rootView: v)
        pop.contentViewController = vc
        if let b = item.button { pop.show(relativeTo: b.bounds, of: b, preferredEdge: .minY) }
    }

    func grab() {
        guard !busy else { return }
        busy = true; item.button?.title = "⏳"
        DispatchQueue.global().async {
            let p = Process(); let pipe = Pipe()
            p.executableURL = URL(fileURLWithPath: SCRIPT)
            p.standardOutput = pipe; p.standardError = FileHandle.nullDevice
            try? p.run(); p.waitUntilExit()
            let out = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines).split(separator: "\n").last.map(String.init) ?? ""
            DispatchQueue.main.async {
                self.busy = false; self.item.button?.title = "📱"
                self.showThumb(out)
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
        iv.fileURL = URL(fileURLWithPath: path)
        let l = NSTextField(labelWithString: "Drag into chat · or ⌘V (on clipboard)")
        l.font = .systemFont(ofSize: 10); l.alignment = .center
        l.frame = NSRect(x: 0, y: 5, width: w, height: 16)
        root.addSubview(iv); root.addSubview(l)
        vc.view = root; pop.contentViewController = vc
        if let b = item.button { pop.show(relativeTo: b.bounds, of: b, preferredEdge: .minY) }
    }
}

let app = NSApplication.shared
let d = App(); app.delegate = d
app.setActivationPolicy(.accessory)
app.run()
