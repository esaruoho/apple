// iPhoneLatest — its own 📱 menu-bar icon (NOT AppleToolbox). Click = grab the
// newest photo off the USB-cabled iPhone (bin/iphone-latest → JPEG → clipboard)
// and show a draggable thumbnail. Right-click = Help / Quit.
// FEATURE-CARD >> features/iphone-latest.feature
import Cocoa
import SwiftUI
import ImageCaptureCore
import UserNotifications

let SCRIPT = NSString(string: "~/work/apple/bin/iphone-latest").expandingTildeInPath
let OUTDIR = NSString(string: "~/Pictures/iPhone-Latest").expandingTildeInPath

func L(_ m: String) {
    let line = "\(Date()) \(m)\n"
    let path = NSString(string: "~/Library/Logs/iphone-latest-app.log").expandingTildeInPath
    if let h = FileHandle(forWritingAtPath: path) { h.seekToEndOfFile(); h.write(line.data(using: .utf8)!); h.closeFile() }
    else { try? line.write(toFile: path, atomically: true, encoding: .utf8) }
}

final class DragView: NSImageView, NSDraggingSource {
    var fileURL: URL?
    var onDoubleClick: (() -> Void)?
    func draggingSession(_ s: NSDraggingSession, sourceOperationMaskFor c: NSDraggingContext) -> NSDragOperation { .copy }
    override func mouseDown(with e: NSEvent) {
        if e.clickCount == 2 { onDoubleClick?(); return }
        guard let u = fileURL, let img = image else { return }
        let it = NSDraggingItem(pasteboardWriter: u as NSURL)
        it.setDraggingFrame(bounds, contents: img)
        beginDraggingSession(with: [it], event: e, source: self)
    }
}

// Persistent ImageCaptureCore session — the Image Capture.app trick. icdd only keeps
// the iPhone's catalog live while a client HOLDS a session open; short sessions get a
// stale cached catalog (stuck at an old IMG_). So: open once at launch, never close.
final class PhoneLink: NSObject, ICDeviceBrowserDelegate, ICCameraDeviceDelegate, ICCameraDeviceDownloadDelegate {
    let browser = ICDeviceBrowser()
    var cam: ICCameraDevice?
    var open = false
    var onNew: (() -> Void)?
    var reopening = false
    var beats = 0
    var downloading: Bool { pendingDone != nil }
    var afterReady: [() -> Void] = []
    func refresh(_ then: @escaping () -> Void) {
        guard let c = cam else { then(); return }
        let first = afterReady.isEmpty
        afterReady.append(then)
        guard first else { return }            // a reopen is already in flight — just wait for it
        if open { reopening = true; c.requestCloseSession() } else { c.requestOpenSession() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak self] in   // never hang
            guard let self = self, !self.afterReady.isEmpty else { return }
            L("refresh timeout"); let cbs = self.afterReady; self.afterReady = []; cbs.forEach { $0() }
        }
    }
    var pendingDone: ((String?) -> Void)?
    let tmp = NSTemporaryDirectory() + "iphone-latest-app"

    func start() {
        try? FileManager.default.createDirectory(atPath: tmp, withIntermediateDirectories: true)
        browser.delegate = self
        browser.browsedDeviceTypeMask = ICDeviceTypeMask(rawValue:
            ICDeviceTypeMask.camera.rawValue | ICDeviceLocationTypeMask.local.rawValue)!
        browser.start()
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            guard let self = self, let c = self.cam, !self.open else { return }
            c.requestOpenSession()   // retry while locked / after drop
        }
        // heartbeat: log real session state every 15s; reopen if ICC silently dropped it
        Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let c = self.cam
            L("hb: cam=\(c != nil) open=\(self.open) hasOpen=\(c?.hasOpenSession ?? false) items=\(c?.mediaFiles?.count ?? -1) newest=\(self.newest()?.name ?? "-")")
            if let c = c, self.open, !c.hasOpenSession { self.open = false; c.requestOpenSession() }
            // Sessions go silently stale (hw 2026-11-10: IMG_5736 only appeared after an
            // app restart). Every 2nd beat (~30s), idle → close+reopen for a fresh catalog;
            // the ready → onNew → prefetch path then notifies about anything new.
            self.beats += 1
            if self.beats % 2 == 0, let c = c, self.open, self.afterReady.isEmpty, !self.downloading {
                self.reopening = true; c.requestCloseSession()
            }
        }
    }
    func newest() -> ICCameraFile? {
        func num(_ f: ICCameraFile) -> Int {
            let n = f.name ?? ""; guard n.hasPrefix("IMG_") else { return -1 }
            return Int(n.dropFirst(4).prefix { $0.isNumber }) ?? -1
        }
        let files = (cam?.mediaFiles ?? []).compactMap { $0 as? ICCameraFile }
        // date first (fresh items have none yet = newest); IMG number breaks ties.
        // (number alone fails: iPhone counters wrap — an old IMG_9728 beat IMG_5721.)
        return files.max { ($0.creationDate ?? .distantFuture, num($0)) < ($1.creationDate ?? .distantFuture, num($1)) }
    }
    /// Download newest → JPEG in ~/Pictures/iPhone-Latest; returns jpg path (or nil).
    func fetchNewest(_ done: @escaping (String?) -> Void) {
        L("fetch: open=\(open) cam=\(cam != nil) items=\(cam?.mediaFiles?.count ?? -1) newest=\(newest()?.name ?? "-")")
        guard open, let c = cam, let f = newest() else { done(nil); return }
        let jpg = OUTDIR + "/" + ((f.name ?? "photo") as NSString).deletingPathExtension + ".jpg"
        if FileManager.default.fileExists(atPath: jpg) { done(jpg); return }
        pendingDone = done
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) { [weak self] in
            if let cb = self?.pendingDone { self?.pendingDone = nil; L("fetch timeout"); cb(nil) }
        }
        c.requestDownloadFile(f, options: [.downloadsDirectoryURL: URL(fileURLWithPath: tmp), .overwrite: true],
            downloadDelegate: self, didDownloadSelector: #selector(didDownloadFile(_:error:options:contextInfo:)), contextInfo: nil)
    }
    var tries = 0
    @objc func didDownloadFile(_ file: ICCameraFile, error: Error?, options: [String: Any] = [:], contextInfo: UnsafeMutableRawPointer?) {
        if error != nil, tries < 15, let c = cam {     // -9934: iOS still writing it
            tries += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                c.requestDownloadFile(file, options: [.downloadsDirectoryURL: URL(fileURLWithPath: self.tmp), .overwrite: true],
                    downloadDelegate: self, didDownloadSelector: #selector(self.didDownloadFile(_:error:options:contextInfo:)), contextInfo: nil)
            }
            return
        }
        tries = 0
        let cb = pendingDone; pendingDone = nil
        L("downloaded \(file.name ?? "?") err=\(String(describing: error))")
        guard error == nil else { cb?(nil); return }
        let name = (options[ICDownloadOption.savedFilename.rawValue] as? String) ?? file.name ?? "photo"
        let src = tmp + "/" + name
        let jpg = OUTDIR + "/" + (name as NSString).deletingPathExtension + ".jpg"
        DispatchQueue.global().async {
            try? FileManager.default.createDirectory(atPath: OUTDIR, withIntermediateDirectories: true)
            let p = Process(); p.executableURL = URL(fileURLWithPath: "/usr/bin/sips")
            p.arguments = ["-s", "format", "jpeg", "-s", "formatOptions", "85", src, "--out", jpg]
            p.standardOutput = FileHandle.nullDevice; p.standardError = FileHandle.nullDevice
            try? p.run(); p.waitUntilExit(); try? FileManager.default.removeItem(atPath: src)
            DispatchQueue.main.async { cb?(FileManager.default.fileExists(atPath: jpg) ? jpg : nil) }
        }
    }

    func deviceBrowser(_ b: ICDeviceBrowser, didAdd d: ICDevice, moreComing: Bool) {
        guard cam == nil, let c = d as? ICCameraDevice else { return }
        L("found \(c.name ?? "?")"); cam = c; c.delegate = self; c.requestOpenSession()
    }
    func deviceBrowser(_ b: ICDeviceBrowser, didRemove d: ICDevice, moreGoing: Bool) {
        if d === cam { cam = nil; open = false }
    }
    func device(_ d: ICDevice, didOpenSessionWithError e: Error?) { open = (e == nil); L("open: \(e.map { "\(($0 as NSError).code)" } ?? "OK")") }
    func device(_ d: ICDevice, didCloseSessionWithError e: Error?) {
        open = false; L("closed")
        if reopening { reopening = false; cam?.requestOpenSession() }
    }
    func didRemove(_ d: ICDevice) { if d === cam { cam = nil; open = false } }
    func cameraDevice(_ c: ICCameraDevice, didAdd items: [ICCameraItem]) {
        guard items.count < 20 else { return }          // initial catalog flood, not new shots
        L("didAdd \(items.compactMap { $0.name })")
        onNew?()
    }
    func cameraDevice(_ c: ICCameraDevice, didRemove items: [ICCameraItem]) {}
    func cameraDevice(_ c: ICCameraDevice, didRenameItems items: [ICCameraItem]) {}
    func cameraDevice(_ c: ICCameraDevice, didReceivePTPEvent e: Data) {}
    func cameraDeviceDidChangeCapability(_ c: ICCameraDevice) {}
    func cameraDeviceDidRemoveAccessRestriction(_ d: ICDevice) {
        L("unlocked")
        if !open { cam?.requestOpenSession() }
    }
    func cameraDeviceDidEnableAccessRestriction(_ d: ICDevice) { L("locked") }
    func deviceDidBecomeReady(withCompleteContentCatalog d: ICCameraDevice) {
        L("ready \(d.mediaFiles?.count ?? 0) newest \(newest()?.name ?? "-") open=\(open)")
        guard open else { return }   // cached catalog from a failed (locked) open — ignore
        // Plugged in while LOCKED → session opens with an EMPTY catalog (hw log: "ready 0").
        // Keep reopening every 3s until the phone is unlocked and items show up.
        if (d.mediaFiles?.count ?? 0) == 0 {
            L("empty catalog (phone locked at plug-in?) — reopen in 3s")
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                guard let self = self, self.open, let c = self.cam else { return }
                self.reopening = true; c.requestCloseSession()
            }
            return
        }
        if !afterReady.isEmpty {
            let cbs = afterReady; afterReady = []
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { cbs.forEach { $0() } }   // let late items stream in
        } else { onNew?() }
    }
    func cameraDevice(_ c: ICCameraDevice, didReceiveThumbnail t: CGImage?, for i: ICCameraItem, error: Error?) {}
    func cameraDevice(_ c: ICCameraDevice, didReceiveMetadata m: [AnyHashable: Any]?, for i: ICCameraItem, error: Error?) {}
}

final class App: NSObject, NSApplicationDelegate, NSPopoverDelegate, UNUserNotificationCenterDelegate {
    var item: NSStatusItem!
    var thumb: DragView?
    var caption: NSTextField?
    var watcher: Process?
    var pollTimer: Timer?
    var shownPath: String?
    var pop = NSPopover()
    var busy = false
    let phone = PhoneLink()
    var debounce: DispatchWorkItem?
    var lastNotified: String?

    func notifyArrived(_ jpg: String) {
        let c = UNMutableNotificationContent()
        c.title = "📱 New iPhone photo"
        c.body = (jpg as NSString).lastPathComponent + " — click to open & drag"
        c.sound = .default
        // attachment needs a copy (the system moves the file)
        let att = NSTemporaryDirectory() + "notif-" + (jpg as NSString).lastPathComponent
        try? FileManager.default.removeItem(atPath: att)
        if (try? FileManager.default.copyItem(atPath: jpg, toPath: att)) != nil,
           let a = try? UNNotificationAttachment(identifier: "img", url: URL(fileURLWithPath: att)) { c.attachments = [a] }
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: jpg, content: c, trigger: nil)) { e in
            L("notify \((jpg as NSString).lastPathComponent): \(e.map { "\($0)" } ?? "ok")")
        }
    }
    func userNotificationCenter(_ c: UNUserNotificationCenter, willPresent n: UNNotification,
                                withCompletionHandler h: @escaping (UNNotificationPresentationOptions) -> Void) { h([.banner, .sound]) }
    func userNotificationCenter(_ c: UNUserNotificationCenter, didReceive r: UNNotificationResponse,
                                withCompletionHandler h: @escaping () -> Void) {
        DispatchQueue.main.async { if !self.pop.isShown { self.grab() } }; h()
    }

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
        // A session opened while the phone is LOCKED is access-restricted: stale
        // catalog, no new-photo pushes even after unlock (hw log 2026-11-10). So every
        // click and every unlock reopens the session, then reads the live catalog.
        phone.start()
        let nc = UNUserNotificationCenter.current(); nc.delegate = self
        nc.requestAuthorization(options: [.alert, .sound]) { ok, e in L("notif auth: \(ok) \(String(describing: e))") }
        // Live: when new items stream in and the thumbnail is open, fetch the newest.
        phone.onNew = { [weak self] in
            guard let self = self else { return }
            self.debounce?.cancel()
            let w = DispatchWorkItem { self.prefetch() }
            self.debounce = w
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: w)
        }
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
        L("click: open=\(phone.open) shown=\(pop.isShown) busy=\(busy)")
        // Click never reopens the session (that raced iOS: -9943 + stale cache → "fetch failed").
        // Show the newest photo already here; new ones arrive via didAdd → prefetch().
        if item.button?.title == "📸" { item.button?.title = "📱" }
        if !pop.isShown { showThumb(newestJPG() ?? "") }
        if phone.cam == nil { caption?.stringValue = "⚠️ No iPhone on the cable"; return }
        if !phone.open { caption?.stringValue = "🔒 Unlock the iPhone…"; return }
        caption?.stringValue = "Drag · double-click = refresh"
        prefetch()
    }

    /// Double-click: reopen the iPhone session (fresh catalog) and fetch the newest.
    func hardRefresh() {
        L("double-click refresh")
        caption?.stringValue = "⏳ refreshing from iPhone…"
        busy = true; item.button?.title = "⏳"
        phone.refresh { [weak self] in
            guard let self = self else { return }
            self.busy = false; self.item.button?.title = "📱"
            self.caption?.stringValue = "Drag · double-click = refresh"
            self.prefetch()
        }
    }

    /// New photo streamed in → download it now; swap into the thumbnail if it's open.
    func prefetch() {
        guard !busy, phone.open else { return }
        busy = true; item.button?.title = "⏳"
        phone.fetchNewest { [weak self] jpg in
            guard let self = self else { return }
            self.busy = false; self.item.button?.title = "📱"
            L("prefetch done: \(jpg ?? "nil") lastNotified=\(self.lastNotified ?? "-") shown=\(self.shownPath ?? "-")")
            guard let j = jpg else { return }
            // more streamed in while we were busy? go again
            if let n = self.phone.newest()?.name, !j.hasSuffix(((n as NSString).deletingPathExtension) + ".jpg") {
                DispatchQueue.main.async { self.prefetch() }
            }
            if self.pop.isShown { self.updateThumb(j) }
            if j != self.lastNotified, j != self.shownPath {
                self.lastNotified = j
                if !self.pop.isShown { self.item.button?.title = "📸" }   // unseen photo marker
                self.notifyArrived(j)
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
        let l = NSTextField(labelWithString: "Drag · double-click = refresh")
        l.font = .systemFont(ofSize: 10); l.alignment = .center
        l.frame = NSRect(x: 0, y: 5, width: w, height: 16)
        root.addSubview(iv); root.addSubview(l)
        thumb = iv; caption = l
        iv.onDoubleClick = { [weak self] in self?.hardRefresh() }
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
        caption?.stringValue = "🆕 " + (path as NSString).lastPathComponent + "  ·  drag · double-click = refresh"
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
