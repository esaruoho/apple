// OverlayInbox — the agent ingress.
//
// The fifth instance of this repo's trigger→worker chassis (Finder tag, Voice Memo
// #process, Stickies, Mail flag, now this): drop a file in a folder, something
// happens. Chosen over a socket or an HTTP server because it needs no port, no
// permission, no protocol version, and because ~/.overlay/inbox can be a Syncthing
// folder — at which point a Fleet peer annotates this Mac's screen for free.
//
// Concurrency: one serial queue owns every scan. The Stickies watcher taught us that
// a timer AND an event source both firing will double-dispatch
// (feedback_stickies_watcher_must_lock); here the file itself is the lock — it is
// consumed on success, so a second scan finds nothing to do.
//
// Energy: the event source does the real work; the safety poll is 30s, never faster
// (feedback_stickies_watcher_energy_hog).
//
// FEATURE-CARD >> overlay/overlay.feature

import Foundation

final class InboxWatcher {

    /// Called on the main queue with the parsed requests from one file.
    /// Returns nil on success, or a human-readable reason the file was rejected.
    typealias Handler = ([PostRequest]) -> String?

    private let directory: URL
    private let handler: Handler
    private let queue = DispatchQueue(label: "com.esaruoho.overlay.inbox")
    private var source: DispatchSourceFileSystemObject?
    private var descriptor: Int32 = -1
    private var poll: DispatchSourceTimer?

    init(directory: URL = OverlayPaths.inbox, handler: @escaping Handler) {
        self.directory = directory
        self.handler = handler
    }

    func start() {
        do {
            try FileManager.default.createDirectory(at: directory,
                                                    withIntermediateDirectories: true)
        } catch {
            NSLog("Overlay: cannot create inbox \(directory.path): \(error)")
            return
        }

        descriptor = open(directory.path, O_EVTONLY)
        guard descriptor >= 0 else {
            NSLog("Overlay: cannot watch inbox \(directory.path)")
            return
        }

        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor, eventMask: [.write], queue: queue)
        src.setEventHandler { [weak self] in self?.scanDebounced() }
        src.setCancelHandler { [weak self] in
            if let fd = self?.descriptor, fd >= 0 { close(fd) }
        }
        src.resume()
        source = src

        // Safety net for the cases an fd event can miss (an atomic rename into the
        // directory from another volume, a Syncthing write while we were launching).
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + 30, repeating: 30, leeway: .seconds(10))
        timer.setEventHandler { [weak self] in self?.scan() }
        timer.resume()
        poll = timer

        // Anything that arrived while the app was not running.
        queue.async { [weak self] in self?.scan() }
        NSLog("Overlay: watching inbox \(directory.path)")
    }

    func stop() {
        source?.cancel(); source = nil
        poll?.cancel(); poll = nil
    }

    /// A single agent write can generate several fd events. Coalesce them so a
    /// multi-file drop is handled once, and so we never read a half-written file.
    private var pending = false
    private func scanDebounced() {
        guard !pending else { return }
        pending = true
        queue.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.pending = false
            self?.scan()
        }
    }

    private func scan() {
        let fm = FileManager.default
        guard let names = try? fm.contentsOfDirectory(atPath: directory.path) else { return }

        for name in names.sorted() where name.hasSuffix(".json") {
            let url = directory.appendingPathComponent(name)
            guard let data = try? Data(contentsOf: url) else { continue }
            // A zero-byte file is a write still in flight; leave it for the next pass.
            guard !data.isEmpty else { continue }

            var failure: String?
            do {
                let requests = try PostRequest.decodeBatch(data)
                // The handler touches AppKit, so it must run on the main queue — but
                // this scan owns the file, so wait for the verdict before deciding
                // whether to consume or quarantine it.
                DispatchQueue.main.sync { failure = self.handler(requests) }
            } catch let e as PostRequest.PostError {
                failure = e.description
            } catch {
                failure = "not valid JSON: \(error.localizedDescription)"
            }

            if let failure = failure {
                quarantine(url, reason: failure)
            } else {
                try? fm.removeItem(at: url)
            }
        }
    }

    /// A rejected file is renamed rather than deleted, with the reason written beside
    /// it — an agent that posted nonsense can read back exactly what was wrong instead
    /// of watching its request vanish.
    private func quarantine(_ url: URL, reason: String) {
        let fm = FileManager.default
        let bad = url.appendingPathExtension("bad")
        // Order matters: the reason is written BEFORE the request disappears. A
        // caller watching for its file to vanish would otherwise see the rename
        // land first and read that as success — which is exactly what happened
        // the first time this was tested.
        try? Data(reason.utf8).write(to: url.appendingPathExtension("error.txt"),
                                     options: .atomic)
        try? fm.removeItem(at: bad)
        try? fm.moveItem(at: url, to: bad)
        NSLog("Overlay: rejected \(url.lastPathComponent): \(reason)")
    }
}

// ─────────────────────────── control channel ───────────────────────────

/// Verbs that act on the overlay rather than adding to it (clear, toggle draw mode).
///
/// These travel as distributed notifications rather than inbox files: they are
/// instantaneous, they carry no payload worth persisting, and a control verb that
/// arrives while the app is down should evaporate rather than fire at next launch.
/// `DistributedNotificationCenter` is public API and needs no entitlement, and
/// AppleScript-ObjC can post to it in one line — so the CLI stays dependency-free.
enum OverlayControl {
    static let clear  = Notification.Name("com.esaruoho.overlay.clear")
    static let draw   = Notification.Name("com.esaruoho.overlay.draw")
    static let ask    = Notification.Name("com.esaruoho.overlay.ask")
    static let probe  = Notification.Name("com.esaruoho.overlay.probe")
    static let imagine = Notification.Name("com.esaruoho.overlay.imagine")
    static let all: [Notification.Name] = [clear, draw, ask]
}
