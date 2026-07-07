// Fleet — a single-window Mac app that shows THIS computer's Machine Card
// side-by-side with every peer Mac running the same app on the same network.
//
// Two transports, merged into one fleet view:
//   • Bonjour / Network.framework — each app advertises _machinecard._tcp on the
//     LAN, auto-discovers peers, and exchanges public Machine Cards live over a
//     socket. Green dot = connected right now. No SSH, no Syncthing needed.
//   • Syncthing queue — peers that publish machine-card-<host>.json into
//     ~/work/comms/queue/ (the Mini) are read straight off the synced folder,
//     so off-LAN / not-currently-running machines still appear.
//
// Each card's `skills` face is interactive: a skill backed by an inbox port
// (ocr, voicebox, whisp, pakettibot) is a button — clicking it picks a file and
// routes it to that machine by dropping it into the Syncthing-mirrored inbox.
//
// Data comes from `bin/machine-card` (zero-token Python). This app renders it.
// Apple-native: SwiftUI + AppKit + Network. Built with xcrun swiftc, no Xcode.

import SwiftUI
import AppKit
import Network
import Foundation

// ───────────────────────────── Model ─────────────────────────────

struct Card: Codable, Identifiable {
    let id: String
    var ts: Int?
    var identity: Identity?
    var shape: Shape?
    var ports: Ports?
    var skills: [Skill]?
    var panel_actions: [PanelAction]?
    var activity: [Activity]?
    var running: Running?

    // Transport metadata — not part of the JSON; set after decode.
    var origin: Origin = .local
    var lastSeen: Date = Date()

    enum CodingKeys: String, CodingKey { case id, ts, identity, shape, ports, skills, panel_actions, activity, running }

    enum Origin: String { case local, bonjour, syncthing }
}

struct Identity: Codable {
    var hostname: String?
    var computer_name: String?
    var user: String?
}

struct AIInfo: Codable {
    var neural_engine_tops: Double?
    var memory_bandwidth_gbs: Double?
    var max_model_b_q4: Double?
    var max_model_b_q8: Double?
    var tokens_per_sec: [String: Double]?
}

struct Display: Codable { var name: String?; var pixels: String?; var resolution: String? }

struct Shape: Codable {
    var chip: String?
    var model_name: String?
    var model_identifier: String?
    var cores_total: Int?
    var cores_perf: Int?
    var cores_efficiency: Int?
    var ram_gb: Int?
    var gpu_name: String?
    var gpu_cores: String?
    var ssd_gb: Int?
    var displays: [Display]?
    var macos_version: String?
    var macos_build: String?
    var ai: AIInfo?
}

struct Channel: Codable, Identifiable {
    var id: String { name }
    var name: String
    var kind: String?
    var target: String?
    var available: Bool?
}
struct Ports: Codable { var channels: [Channel]? }

struct Skill: Codable, Identifiable {
    var id: String { name }
    var name: String
    var source: String?
    var warm: Bool?
    var inbox: String?
    var verb: String?
}

/// One runnable Apple-Panel action a machine advertises. The unification with
/// the panel: Fleet renders these per machine and dispatches a run.
struct PanelAction: Codable, Identifiable {
    var id: String
    var group: String
    var kind: String        // "safe" = read-only · "action" = makes a change
    var label: String
    var desc: String?
    var arg: String?        // placeholder if it needs an input value, else nil
}

/// A curated read-only Apple-Event probe (third transport): sent to a peer's real
/// app over eppc. Machine-agnostic — the same probes work against any peer.
struct EppcProbe: Codable, Identifiable {
    var id: String
    var app: String
    var label: String
    var desc: String?
}

/// Live per-service job state — what a machine is DOING right now, drawn from
/// its service heartbeats. Only services the machine actually hosts appear.
struct Progress: Codable { var cur: Int?; var total: Int? }
struct Activity: Codable, Identifiable {
    var id: String { service }
    var service: String
    var warm: Bool?
    var age_s: Int?
    var status: String?
    var current_job: String?
    var progress: Progress?
    var eta_s: Int?
    var elapsed_s: Int?
    var queue: [String: Int]?
    var ready: Bool?
    var agents: Int?
}

struct TopProc: Codable { var cpu: Double?; var cmd: String? }
struct Running: Codable {
    var load_pct: Int?
    var load_avg: [Double]?
    var mem_used_gb: Double?
    var battery_pct: Int?
    var power_source: String?
    var cpu_speed_limit_pct: Int?
    var uptime: String?
    var top: [TopProc]?
    var queues: [String: [String: Int]]?
    var thermal: Thermal?
}

// Sensor temperatures (°C) + thermal pressure, published by each machine via
// bin/machine-card (which reads bin/mac-temps). This is how Fleet answers
// "how hot is the Mini?" for a peer it can't touch directly.
struct Thermal: Codable {
    var headline_c: Double?
    var max_c: Double?
    var avg_c: Double?
    var cpu_c: Double?
    var gpu_c: Double?
    var pressure: String?
    var sensor_count: Int?
    var top_sensors: [TempSensor]?
}

struct TempSensor: Codable {
    var name: String?
    var c: Double?
}

// ─────────────────────── Config (whitelabel) ───────────────────────
//
// Fleet ships with no host, path, or service baked in. Where the helper
// binaries live and where the Syncthing queue is come from a JSON config so a
// stranger can run Fleet against their own layout. Resolution order, first hit
// wins, falling back to the historical defaults so an unconfigured install (or
// Esa's) behaves exactly as before:
//   1. env override   FLEET_BIN_DIR / FLEET_QUEUE_DIR  (handy for testing)
//   2. config file     $FLEET_CONFIG, else ~/.config/fleet/config.json
//   3. default         ~/work/apple/bin  and  ~/work/comms/queue
// machine-card reads the SAME file (queue_dir + services), so the renderer and
// the emitter never disagree about where the queue is. See fleet/config.example.json.

enum FleetConfig {
    static let binDir   = resolve(env: "FLEET_BIN_DIR",   key: "bin_dir",   default: "\(NSHomeDirectory())/work/apple/bin")
    static let queueDir = resolve(env: "FLEET_QUEUE_DIR", key: "queue_dir", default: "\(NSHomeDirectory())/work/comms/queue")

    /// Parsed config JSON (empty on absence / parse error — defaults then win).
    private static let json: [String: Any] = {
        let env = ProcessInfo.processInfo.environment
        let path = env["FLEET_CONFIG"] ?? "\(NSHomeDirectory())/.config/fleet/config.json"
        guard let data = FileManager.default.contents(atPath: path),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return [:] }
        return obj
    }()

    private static func resolve(env: String, key: String, default def: String) -> String {
        if let v = ProcessInfo.processInfo.environment[env], !v.isEmpty { return expand(v) }
        if let v = json[key] as? String, !v.isEmpty { return expand(v) }
        return def
    }

    /// Expand a leading `~` or `$HOME` so config files can stay portable.
    private static func expand(_ p: String) -> String {
        if p == "~" || p.hasPrefix("~/") { return NSHomeDirectory() + p.dropFirst(1) }
        if p.hasPrefix("$HOME") { return NSHomeDirectory() + p.dropFirst(5) }
        return p
    }
}

// ─────────────────────── Machine-card data source ───────────────────────

enum CardSource {
    static let bin = "\(FleetConfig.binDir)/machine-card"
    static let panelBin = "\(FleetConfig.binDir)/apple-panel"
    static let nudgeBin = "\(FleetConfig.binDir)/syncthing-nudge"
    static let eppcBin = "\(FleetConfig.binDir)/eppc-probe"
    static let fleetFilesBin = "\(FleetConfig.binDir)/fleet-files"
    static let queue = FleetConfig.queueDir

    /// The curated eppc probe registry (machine-agnostic), loaded once.
    static func loadEppcProbes() -> [EppcProbe] {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        p.arguments = ["python3", eppcBin, "--list-json"]
        let pipe = Pipe(); p.standardOutput = pipe; p.standardError = Pipe()
        do { try p.run() } catch { return [] }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        return (try? JSONDecoder().decode([EppcProbe].self, from: data)) ?? []
    }

    /// Run one curated probe against a peer over eppc. Blocking — call off-main.
    static func runEppc(host: String, user: String, probeID: String) -> (out: String, ok: Bool) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        var a = ["python3", eppcBin, host, probeID]
        if !user.isEmpty { a += ["--user", user] }
        p.arguments = a
        let outPipe = Pipe(), errPipe = Pipe()
        p.standardOutput = outPipe; p.standardError = errPipe
        do { try p.run() } catch { return ("Couldn’t launch eppc-probe: \(error.localizedDescription)", false) }
        let o = String(data: outPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let e = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        p.waitUntilExit()
        let ok = p.terminationStatus == 0
        let text = ok ? (o.isEmpty ? "(no output)" : o) : (e.isEmpty ? "eppc failed" : e)
        return (text, ok)
    }

    /// Best-effort: make Syncthing scan + announce a just-written path now, so a
    /// peer pulls it in a second or two instead of after the watcher delay.
    static func nudgeSyncthing(_ path: String) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        p.arguments = ["python3", nudgeBin, path]
        p.standardOutput = FileHandle.nullDevice
        p.standardError = FileHandle.nullDevice
        try? p.run()
        p.waitUntilExit()
    }

    /// Run one curated panel action on THIS machine and capture its output.
    /// (Local arm of the runner; remote goes via the Syncthing panel-inbox.)
    static func runLocal(actionID: String, arg: String) -> (out: String, ok: Bool) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        var a = ["python3", "-u", panelBin, "--run", actionID]
        if !arg.isEmpty { a += ["--arg", arg] }
        p.arguments = a
        let outPipe = Pipe(); let errPipe = Pipe()
        p.standardOutput = outPipe; p.standardError = errPipe
        do { try p.run() } catch { return ("Couldn’t launch: \(error.localizedDescription)", false) }

        // Read both pipes concurrently (a full stderr buffer can't deadlock
        // stdout) and bound it with a hard timeout so the sheet never hangs.
        final class Box { var data = Data() }
        let outBox = Box(), errBox = Box()
        let g = DispatchGroup()
        let q = DispatchQueue(label: "panel.run.read", attributes: .concurrent)
        g.enter(); q.async { outBox.data = outPipe.fileHandleForReading.readDataToEndOfFile(); g.leave() }
        g.enter(); q.async { errBox.data = errPipe.fileHandleForReading.readDataToEndOfFile(); g.leave() }
        if g.wait(timeout: .now() + 90) == .timedOut {
            p.terminate()
            return ("Timed out after 90 s — terminated. (The command kept running with no output.)", false)
        }
        p.waitUntilExit()
        let o = String(data: outBox.data, encoding: .utf8) ?? ""
        let e = String(data: errBox.data, encoding: .utf8) ?? ""
        let combined = o + (e.isEmpty ? "" : "\n— stderr —\n\(e)")
        return (combined.isEmpty ? "(no output)" : combined, p.terminationStatus == 0)
    }

    /// Run a curated action on a REMOTE machine via the Syncthing panel-inbox:
    /// drop a job, the target's panel-worker validates it against its own
    /// registry and writes panel-results/<job>.json, Syncthing mirrors it back.
    /// No network-exposed exec; the registry is the allowlist. Blocking — call
    /// off the main thread.
    static func runRemote(actionID: String, arg: String, target: String) -> (out: String, ok: Bool) {
        let fm = FileManager.default
        let inbox = "\(queue)/panel-inbox"
        let results = "\(queue)/panel-results"
        try? fm.createDirectory(atPath: inbox, withIntermediateDirectories: true)
        let jobID = UUID().uuidString
        let job: [String: Any] = [
            "job_id": jobID, "target": target, "id": actionID, "arg": arg,
            "from": ProcessInfo.processInfo.hostName.components(separatedBy: ".").first ?? "",
            "ts": Int(Date().timeIntervalSince1970)]
        let jobPath = "\(inbox)/\(jobID).json"
        guard let data = try? JSONSerialization.data(withJSONObject: job),
              fm.createFile(atPath: jobPath, contents: data) else {
            return ("Couldn’t write the job into panel-inbox.", false)
        }
        nudgeSyncthing(jobPath)   // push it to the target now, not after the watcher delay
        let resultPath = "\(results)/\(jobID).json"
        let deadline = Date().addingTimeInterval(120)   // Syncthing round-trip + run
        while Date() < deadline {
            if let d = fm.contents(atPath: resultPath),
               let obj = try? JSONSerialization.jsonObject(with: d) as? [String: Any] {
                let out = (obj["out"] as? String) ?? ""
                let err = (obj["err"] as? String) ?? ""
                let ok = (obj["ok"] as? Bool) ?? false
                try? fm.removeItem(atPath: resultPath)   // consume it
                let combined = out + (err.isEmpty ? "" : "\n— stderr —\n\(err)")
                return (combined.isEmpty ? "(no output)" : combined, ok)
            }
            Thread.sleep(forTimeInterval: 1.0)
        }
        return ("No response from \(target) within 120 s.\n"
            + "Is its panel-worker running and Syncthing connected?", false)
    }

    /// Run `machine-card` and decode. `public` = the publishable subset we send
    /// to peers; full (local) is what we display for ourselves.
    static func local(publicOnly: Bool) -> Card? {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        p.arguments = publicOnly ? [bin, "--public"] : [bin]
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = Pipe()
        do {
            try p.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            p.waitUntilExit()
            var card = try JSONDecoder().decode(Card.self, from: data)
            card.origin = .local
            return card
        } catch { return nil }
    }

    /// Raw card JSON bytes to hand to a peer over the live socket.
    /// Auto-trust same-LAN: peers reachable over Bonjour are on your trusted
    /// LAN, so they get the FULL card (serial, exact load, everything) — not
    /// the stripped subset. The --public strip is only for the persisted
    /// Syncthing file (readable on disk), not for a point-to-point LAN link.
    static func localFullJSON() -> Data? {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        p.arguments = [bin]                 // full card, no --public
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = Pipe()
        do {
            try p.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            p.waitUntilExit()
            return data.isEmpty ? nil : data
        } catch { return nil }
    }

    /// Peers published into the Syncthing queue as machine-card-<host>.json.
    static func syncthingPeers(excluding selfID: String) -> [Card] {
        let fm = FileManager.default
        guard let names = try? fm.contentsOfDirectory(atPath: queue) else { return [] }
        var out: [Card] = []
        for n in names where n.hasPrefix("machine-card-") && n.hasSuffix(".json") {
            let path = "\(queue)/\(n)"
            guard let data = fm.contents(atPath: path),
                  var card = try? JSONDecoder().decode(Card.self, from: data),
                  card.id.lowercased() != selfID.lowercased() else { continue }
            card.origin = .syncthing
            if let ts = card.ts { card.lastSeen = Date(timeIntervalSince1970: TimeInterval(ts)) }
            out.append(card)
        }
        return out
    }

    /// Route a file to a peer's inbox by dropping it into the Syncthing-mirrored
    /// queue. The peer's worker (Mini) picks it up; Syncthing is the transport.
    static func route(file: URL, toInbox inbox: String) -> Result<String, Error> {
        let dir = "\(queue)/\(inbox)"
        let fm = FileManager.default
        do {
            if !fm.fileExists(atPath: dir) {
                try fm.createDirectory(atPath: dir, withIntermediateDirectories: true)
            }
            let dest = URL(fileURLWithPath: dir).appendingPathComponent(file.lastPathComponent)
            if fm.fileExists(atPath: dest.path) { try? fm.removeItem(at: dest) }
            try fm.copyItem(at: file, to: dest)
            return .success(dest.path)
        } catch { return .failure(error) }
    }
}

// ─────────────────────── Bonjour peer exchange ───────────────────────
//
// Length-prefixed (UInt32 big-endian) JSON. On every connection — whether we
// dialed out (browser) or accepted in (listener) — both sides immediately send
// their public card, then read the peer's. Self is skipped by service name.

final class FleetNet: ObservableObject {
    static let serviceType = "_machinecard._tcp"

    private var listener: NWListener?
    private var browser: NWBrowser?
    private let queue = DispatchQueue(label: "fleet.net")
    private let selfName = (Host.current().localizedName ?? ProcessInfo.processInfo.hostName)
        .components(separatedBy: ".").first ?? "Mac"
    // The id machine-card emits is socket.gethostname() — match it so we can
    // drop our own broadcast even before the async local card has loaded.
    private let selfHostname = ProcessInfo.processInfo.hostName
        .components(separatedBy: ".").first ?? ""

    /// Called on the main thread when a peer card arrives.
    var onPeer: ((Card) -> Void)?
    /// Bonjour up/down for the header indicator.
    @Published var advertising = false

    func start() {
        startListener()
        startBrowser()
    }

    private func startListener() {
        do {
            let l = try NWListener(using: .tcp)
            l.service = NWListener.Service(name: selfName, type: Self.serviceType)
            l.stateUpdateHandler = { [weak self] state in
                if case .ready = state { DispatchQueue.main.async { self?.advertising = true } }
            }
            l.newConnectionHandler = { [weak self] conn in self?.handle(conn) }
            l.start(queue: queue)
            listener = l
        } catch { NSLog("Fleet listener failed: \(error)") }
    }

    private func startBrowser() {
        let params = NWParameters.tcp
        let b = NWBrowser(for: .bonjour(type: Self.serviceType, domain: nil), using: params)
        b.browseResultsChangedHandler = { [weak self] results, _ in
            guard let self else { return }
            for r in results {
                if case let .service(name, _, _, _) = r.endpoint {
                    if name == self.selfName { continue }   // skip ourselves
                    let conn = NWConnection(to: r.endpoint, using: .tcp)
                    self.handle(conn)
                }
            }
        }
        b.start(queue: queue)
        browser = b
    }

    /// Drive one connection: send our card, read the peer's.
    private func handle(_ conn: NWConnection) {
        conn.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.sendCard(on: conn)
                self?.readCard(on: conn)
            case .failed, .cancelled:
                conn.cancel()
            default: break
            }
        }
        conn.start(queue: queue)
    }

    private func sendCard(on conn: NWConnection) {
        guard let payload = CardSource.localFullJSON() else { return }
        var len = UInt32(payload.count).bigEndian
        var frame = Data(bytes: &len, count: 4)
        frame.append(payload)
        conn.send(content: frame, completion: .contentProcessed { _ in })
    }

    private func readCard(on conn: NWConnection) {
        conn.receive(minimumIncompleteLength: 4, maximumLength: 4) { [weak self] header, _, _, err in
            guard let self, let header, header.count == 4, err == nil else { conn.cancel(); return }
            let n = header.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
            if n == 0 || n > 4_000_000 { conn.cancel(); return }
            self.readBody(on: conn, remaining: Int(n), buffer: Data())
        }
    }

    private func readBody(on conn: NWConnection, remaining: Int, buffer: Data) {
        conn.receive(minimumIncompleteLength: 1, maximumLength: remaining) { [weak self] chunk, _, _, err in
            guard let self, err == nil, let chunk else { conn.cancel(); return }
            var buf = buffer; buf.append(chunk)
            let left = remaining - chunk.count
            if left > 0 {
                self.readBody(on: conn, remaining: left, buffer: buf)
            } else {
                if var card = try? JSONDecoder().decode(Card.self, from: buf),
                   card.id.lowercased() != self.selfHostname.lowercased() {
                    card.origin = .bonjour
                    card.lastSeen = Date()
                    DispatchQueue.main.async { self.onPeer?(card) }
                }
                conn.cancel()
            }
        }
    }
}

// ───────────────────────────── ViewModel ─────────────────────────────

/// The output of running one action on one machine — shown in a sheet, updated
/// in place (same id) so a running→done transition refreshes without flicker.
struct RunResult: Identifiable {
    let id = UUID()
    let title: String
    let target: String
    var running: Bool
    var output: String
    var ok: Bool = true
}

final class FleetModel: ObservableObject {
    @Published var local: Card?
    @Published var peers: [String: Card] = [:]   // id → card
    @Published var toast: String?
    @Published var runResult: RunResult?
    @Published var eppcProbes: [EppcProbe] = []   // third transport (Remote Apple Events)

    // Our own hostname — matches the `id` machine-card emits (socket.gethostname).
    // Known synchronously so we exclude our own published card from peers even
    // before the async local-card load finishes.
    let selfID = ProcessInfo.processInfo.hostName.components(separatedBy: ".").first ?? ""

    let net = FleetNet()
    private var timer: Timer?

    var cards: [Card] {
        var all: [Card] = []
        if let l = local { all.append(l) }
        all.append(contentsOf: peers.values.sorted { $0.id < $1.id })
        return all
    }

    func boot() {
        refreshLocal()
        DispatchQueue.global(qos: .utility).async {
            let probes = CardSource.loadEppcProbes()
            DispatchQueue.main.async { self.eppcProbes = probes }
        }
        net.onPeer = { [weak self] card in
            guard let self else { return }
            // Bonjour advertises on every interface, so the browser also finds
            // our own service. Never store our own broadcast as a peer.
            if card.id.lowercased() == self.selfID.lowercased()
                || card.id.lowercased() == (self.local?.id.lowercased() ?? "") { return }
            self.peers[card.id] = card
        }
        net.start()
        refreshSyncthing()
        // Periodic refresh: local running stats + syncthing card freshness.
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.refreshLocal()
            self?.refreshSyncthing()
        }
    }

    func refreshLocal() {
        DispatchQueue.global(qos: .utility).async {
            let card = CardSource.local(publicOnly: false)
            DispatchQueue.main.async { if let c = card { self.local = c } }
        }
    }

    func refreshSyncthing() {
        let selfID = self.selfID
        DispatchQueue.global(qos: .utility).async {
            let found = CardSource.syncthingPeers(excluding: selfID)
            let foundIDs = Set(found.map { $0.id })
            DispatchQueue.main.async {
                // Reconcile DELETIONS: a Syncthing-sourced peer whose card file
                // has vanished from the queue (e.g. a machine renamed, so its old
                // machine-card-<oldname>.json was removed) must be evicted, not
                // kept forever. Without this, refresh only ever adds/updates and
                // a deleted card lingers in the view (the "MacPro stays after
                // Refresh" bug). Only prune .syncthing peers — Bonjour/LAN peers
                // are reconciled by the NWBrowser's own found/lost events.
                for (id, peer) in self.peers where peer.origin == .syncthing && !foundIDs.contains(id) {
                    self.peers.removeValue(forKey: id)
                }
                for c in found {
                    // Keep whichever card carries the newer data — compare by the
                    // card's own `ts` (when machine-card generated it), NOT by which
                    // transport delivered it. A bonjour card is a one-shot snapshot
                    // taken when the peer last dialed in; NWBrowser only redials when
                    // the advertised service set changes, so while the peer stays up
                    // that snapshot freezes and never refreshes over the LAN. The
                    // Syncthing card, by contrast, is republished continuously. The
                    // old "never let syncthing clobber bonjour" rule pinned the stale
                    // LAN number forever (Fleet stuck at OCR 127/717 while the fresh
                    // Syncthing card already said 394/717). Newest ts wins.
                    if let existing = self.peers[c.id],
                       (existing.ts ?? 0) >= (c.ts ?? 0) { continue }
                    self.peers[c.id] = c
                }
            }
        }
    }

    /// VIEW — open a Screen Sharing session to a peer. Fire-and-forget so the
    /// UI never blocks (fleet-files may Wake-on-LAN the peer, up to ~90s):
    /// fleet-files sets up the ssh -L hop through the Mini for LAN-only Macs,
    /// or opens vnc://<host> directly for Tailscale-reachable ones.
    func screenShare(on card: Card) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        p.arguments = ["python3", CardSource.fleetFilesBin, "screen", card.id]
        p.standardOutput = FileHandle.nullDevice
        p.standardError = FileHandle.nullDevice
        do { try p.run() } catch {
            flash("⚠️ VIEW failed: \(error.localizedDescription)"); return
        }
        flash("🖥 Opening Screen Sharing → \(card.identity?.computer_name ?? card.id)…")
    }

    func route(skill: Skill, on card: Card) {
        guard let inbox = skill.inbox else { return }
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Route to \(card.id)"
        panel.message = "Pick a file to send to \(card.id)’s \(skill.name) (\(skill.verb ?? inbox))"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        switch CardSource.route(file: url, toInbox: inbox) {
        case .success:
            flash("→ Routed \(url.lastPathComponent) to \(card.id) · \(skill.name)")
        case .failure(let e):
            flash("⚠️ Route failed: \(e.localizedDescription)")
        }
    }

    private func flash(_ msg: String) {
        toast = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            if self.toast == msg { self.toast = nil }
        }
    }

    // ── run an action on a machine (the Fleet × Panel unification) ──
    func run(action: PanelAction, on card: Card) {
        var arg = ""
        if let placeholder = action.arg {          // action needs an input value
            guard let entered = promptForArg(action: action, placeholder: placeholder),
                  !entered.isEmpty else { return }
            arg = entered
        }
        let title = action.label, target = card.id, isLocal = (card.origin == .local)
        runResult = RunResult(title: title, target: target, running: true, output: "")
        DispatchQueue.global(qos: .userInitiated).async {
            let out: String, ok: Bool
            if isLocal {
                let r = CardSource.runLocal(actionID: action.id, arg: arg)
                (out, ok) = (r.out, r.ok)
            } else {
                let r = CardSource.runRemote(actionID: action.id, arg: arg, target: target)
                (out, ok) = (r.out, r.ok)
            }
            DispatchQueue.main.async {
                // Reassign the whole struct (not a nested-field mutation) so the
                // sheet reliably re-renders. The sheet is keyed on isPresented,
                // not on id, so a fresh id is fine and won't dismiss it.
                guard self.runResult != nil else { return }   // user closed it
                self.runResult = RunResult(title: title, target: target,
                                           running: false, output: out, ok: ok)
            }
        }
    }

    // ── third transport: drive a peer's real apps over eppc ──
    func runEppc(probe: EppcProbe, on card: Card) {
        let host = card.identity?.hostname ?? card.id
        let user = card.identity?.user ?? ""
        let title = "\(probe.label) · \(probe.app)", target = card.id
        runResult = RunResult(title: "\(title)  (eppc)", target: target, running: true, output: "")
        DispatchQueue.global(qos: .userInitiated).async {
            let r = CardSource.runEppc(host: host, user: user, probeID: probe.id)
            DispatchQueue.main.async {
                guard self.runResult != nil else { return }
                self.runResult = RunResult(title: "\(title)  (eppc)", target: target,
                                           running: false, output: r.out, ok: r.ok)
            }
        }
    }

    private func promptForArg(action: PanelAction, placeholder: String) -> String? {
        let alert = NSAlert()
        alert.messageText = action.label
        alert.informativeText = action.desc ?? "Enter a value:"
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 280, height: 24))
        field.placeholderString = placeholder
        alert.accessoryView = field
        alert.addButton(withTitle: "Run")
        alert.addButton(withTitle: "Cancel")
        return alert.runModal() == .alertFirstButtonReturn ? field.stringValue : nil
    }
}

// ───────────────────────────── Views ─────────────────────────────

@main
struct FleetApp: App {
    @StateObject private var model = FleetModel()
    var body: some Scene {
        WindowGroup("Fleet") {
            FleetView().environmentObject(model).onAppear { model.boot() }
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 760, height: 620)
        .commands {
            AppHelpCommand(appName: "Fleet")   // shared Help + donate (see shared/SupportHelp.swift)
        }
    }
}

struct FleetView: View {
    @EnvironmentObject var model: FleetModel
    @State private var showHelp = false
    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            // Scroll both ways: a card with many RUN actions can be taller than
            // the screen, and several cards can be wider than it.
            ScrollView([.vertical, .horizontal], showsIndicators: true) {
                HStack(alignment: .top, spacing: 16) {
                    ForEach(model.cards) { card in
                        CardView(card: card)
                    }
                }
                .padding(16)
            }
            if let toast = model.toast {
                Text(toast)
                    .font(.callout).padding(8)
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor.opacity(0.15))
            }
        }
        .frame(minWidth: 420, minHeight: 460)
        .sheet(isPresented: Binding(
            get: { model.runResult != nil },
            set: { if !$0 { model.runResult = nil } })) {
            RunOutputView().environmentObject(model)
        }
        .onReceive(NotificationCenter.default.publisher(for: .showAppHelp)) { _ in
            showHelp = true
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "rectangle.connected.to.line.below")
                .foregroundColor(.accentColor)
            Text("Fleet").font(.headline)
            Circle().fill(model.net.advertising ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
            Text(model.net.advertising ? "advertising on LAN" : "starting…")
                .font(.caption).foregroundColor(.secondary)
            Spacer()
            Text("\(model.cards.count) machine\(model.cards.count == 1 ? "" : "s")")
                .font(.caption).foregroundColor(.secondary)
            Button { model.refreshLocal(); model.refreshSyncthing() } label: {
                Image(systemName: "arrow.clockwise")
            }.buttonStyle(.borderless)
            Button { showHelp.toggle() } label: { Image(systemName: "questionmark.circle") }
                .buttonStyle(.borderless)
                .help("What is Fleet?")
                .popover(isPresented: $showHelp, arrowEdge: .bottom) {
                    AppHelpView(
                        appName: "Fleet",
                        tagline: "This Mac and every peer Mac on your network, side by side — each machine’s card, live status, and one-click routing.",
                        usage: [
                            ("display", "Click VIEW on a peer to open Screen Sharing (wakes it first if asleep)."),
                            ("paperplane.fill", "Click a skill chip (ocr, whisp, voicebox…) to route a file to that machine."),
                            ("arrow.clockwise", "↻ refreshes local status + Syncthing peers."),
                        ])
                }
        }
        .padding(.horizontal, 14).padding(.vertical, 9)
    }
}

// Output of a run — reads model.runResult so a running→done update refreshes live.
struct RunOutputView: View {
    @EnvironmentObject var model: FleetModel
    var body: some View {
        let r = model.runResult
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(r?.title ?? "Run").font(.headline)
                    Text("on \(r?.target ?? "")").font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                if r?.running == true { ProgressView().scaleEffect(0.7) }
            }
            Divider()
            ScrollView {
                Text(r.map { $0.output.isEmpty ? "Running…" : $0.output } ?? "")
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            HStack {
                if r?.running == false {
                    Image(systemName: (r?.ok ?? false) ? "checkmark.circle.fill" : "xmark.octagon.fill")
                        .foregroundColor((r?.ok ?? false) ? .green : .red)
                    Text((r?.ok ?? false) ? "Done" : "Failed").font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Button("Close") { model.runResult = nil }.keyboardShortcut(.defaultAction)
            }
        }
        .padding(16)
        .frame(width: 640, height: 480)
    }
}

struct CardView: View {
    @EnvironmentObject var model: FleetModel
    let card: Card

    private var live: Bool {
        switch card.origin {
        case .local, .bonjour: return true
        case .syncthing: return Date().timeIntervalSince(card.lastSeen) < 120
        }
    }
    private var originLabel: String {
        switch card.origin {
        case .local: return "this Mac"
        case .bonjour: return "LAN · live"
        case .syncthing: return live ? "Syncthing · fresh" : "Syncthing · stale"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            HStack(spacing: 7) {
                Circle().fill(live ? Color.green : Color.gray)
                    .frame(width: 9, height: 9)
                VStack(alignment: .leading, spacing: 1) {
                    Text(card.identity?.computer_name ?? card.id)
                        .font(.title3).bold()
                    Text(originLabel).font(.caption2).foregroundColor(.secondary)
                }
                // VIEW — one-click Screen Sharing to this peer (not to self).
                // screenShare() → fleet-files screen → cmd_tunnel already
                // Wake-on-LANs an asleep peer through the Mini before connecting.
                // When the card is stale (machine not open), say so honestly:
                // the click wakes it FIRST, then views — so label it WAKE & VIEW.
                if card.origin != .local {
                    Spacer()
                    let peerName = card.identity?.computer_name ?? card.id
                    Button { model.screenShare(on: card) } label: {
                        Label(live ? "VIEW" : "WAKE & VIEW",
                              systemImage: live ? "display" : "powersleep")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .help(live
                        ? "Open Screen Sharing to \(peerName)"
                        : "Wake \(peerName) over the LAN (via the Mini), then open Screen Sharing. Laptops on battery / lid-closed may not wake.")
                }
            }
            Divider()
            face("SHAPE", icon: "cpu") { shapeFace }
            face("PORTS", icon: "cable.connector") { portsFace }
            face("RUNNING", icon: "waveform.path.ecg") { runningFace }
            if let acts = card.activity, !acts.isEmpty {
                face("ACTIVITY", icon: "bolt.horizontal.fill") { activityFace(acts) }
            }
            face("SKILLS", icon: "wrench.and.screwdriver") { skillsFace }
            if let acts = card.panel_actions, !acts.isEmpty {
                face("RUN", icon: "play.circle") { runFace(acts) }
            }
            // APPS · eppc — drive a peer's real apps over Remote Application
            // Scripting. Peer cards only (you don't eppc to yourself), needs an
            // identity to address and reachability at click time.
            if card.origin != .local, card.identity?.hostname != nil, !model.eppcProbes.isEmpty {
                face("APPS · eppc", icon: "macwindow.on.rectangle") { eppcFace }
            }
        }
        .padding(14)
        .frame(width: 340, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(NSColor.controlBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke(card.origin == .local ? Color.accentColor.opacity(0.5) : Color.gray.opacity(0.25), lineWidth: 1))
    }

    @ViewBuilder private func face<C: View>(_ title: String, icon: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.caption2).foregroundColor(.secondary)
                Text(title).font(.caption2).bold().foregroundColor(.secondary)
                    .tracking(1)
            }
            content()
        }
    }

    // SHAPE
    @ViewBuilder private var shapeFace: some View {
        let s = card.shape
        VStack(alignment: .leading, spacing: 2) {
            row(s?.chip ?? "—", bold: true)
            row("\(s?.model_name ?? "Mac")  ·  \(s?.model_identifier ?? "")")
            kv("Cores", coresText(s))
            kv("Memory", s?.ram_gb.map { "\($0) GB" } ?? "—")
            kv("GPU", "\(s?.gpu_cores ?? "?")-core")
            kv("SSD", s?.ssd_gb.map { "\($0) GB" } ?? "—")
            kv("macOS", "\(s?.macos_version ?? "—") (\(s?.macos_build ?? "—"))")
            if let ai = s?.ai, let q4 = ai.max_model_b_q4 {
                kv("AI", String(format: "≤%.0fB q4 · %.0f TOPS", q4, ai.neural_engine_tops ?? 0))
            }
        }
    }
    private func coresText(_ s: Shape?) -> String {
        guard let t = s?.cores_total else { return "—" }
        if let p = s?.cores_perf, let e = s?.cores_efficiency { return "\(t) (\(p)P+\(e)E)" }
        return "\(t)"
    }

    // PORTS
    @ViewBuilder private var portsFace: some View {
        let chans = card.ports?.channels ?? []
        if chans.isEmpty { row("—") }
        else {
            FlowChips(chans.map { ch in
                Chip(text: ch.name, on: ch.available ?? false, kind: .channel)
            })
        }
    }

    // RUNNING
    @ViewBuilder private var runningFace: some View {
        let r = card.running
        VStack(alignment: .leading, spacing: 2) {
            if let lp = r?.load_pct { kv("Load", "\(lp)%") }
            if let m = r?.mem_used_gb { kv("Mem used", String(format: "%.1f GB", m)) }
            if let b = r?.battery_pct {
                kv("Battery", "\(b)%\(r?.power_source.map { " · \($0)" } ?? "")")
            } else if let ps = r?.power_source { kv("Power", ps) }
            if let lim = r?.cpu_speed_limit_pct, lim < 100 { kv("Thermal", "CPU @ \(lim)%") }
            if let th = r?.thermal, let h = th.headline_c {
                let press = th.pressure.map { " · \($0.prefix(1).uppercased() + $0.dropFirst())" } ?? ""
                kv("Temp", String(format: "%.0f°C%@", h, press))
                if let s = th.top_sensors?.first, let n = s.name, let c = s.c {
                    kv("Hottest", String(format: "%@ %.0f°C", n, c))
                }
            }
            if let top = r?.top, let first = top.first, let cmd = first.cmd {
                kv("Top", String(format: "%@ %.0f%%", cmd, first.cpu ?? 0))
            }
            if let q = r?.queues, !q.isEmpty {
                ForEach(q.keys.sorted(), id: \.self) { k in
                    if let pend = q[k]?["pending"] { kv("\(k) queue", "\(pend) pending") }
                }
            }
        }
    }

    // ACTIVITY — live per-service job state: what this machine is doing NOW.
    // Capability (SKILLS) says "I can OCR"; this says "I'm on page 3/12, ETA 4m".
    @ViewBuilder private func activityFace(_ acts: [Activity]) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            ForEach(acts) { a in
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Circle().fill((a.warm ?? false) ? Color.green : Color.gray.opacity(0.4))
                            .frame(width: 7, height: 7)
                        Text(a.service).font(.caption).bold()
                        if let s = a.status, !s.isEmpty { statusPill(s) }
                        Spacer(minLength: 0)
                    }
                    if let pr = a.progress, let cur = pr.cur, let tot = pr.total, tot > 0 {
                        ProgressView(value: Double(min(cur, tot)), total: Double(tot))
                            .progressViewStyle(.linear).tint(.accentColor)
                        HStack(spacing: 4) {
                            Text("\(cur)/\(tot)")
                            if let eta = a.eta_s { Text("· ETA \(fmtDur(eta))") }
                            Spacer(minLength: 0)
                        }.font(.system(size: 9)).foregroundColor(.secondary)
                    }
                    if let job = a.current_job {
                        Text(prettyJob(job)).font(.system(size: 9))
                            .foregroundColor(.secondary).lineLimit(1).truncationMode(.middle)
                    }
                    if a.progress == nil, let line = queueLine(a) {
                        Text(line).font(.system(size: 9)).foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder private func statusPill(_ s: String) -> some View {
        Text(s).font(.system(size: 9)).foregroundColor(.secondary)
            .padding(.horizontal, 5).padding(.vertical, 1)
            .background(Capsule().fill(Color.secondary.opacity(0.15)))
    }
    private func fmtDur(_ s: Int) -> String {
        s < 60 ? "\(s)s" : "\(s / 60)m\(String(format: "%02d", s % 60))s"
    }
    private func prettyJob(_ raw: String) -> String {
        var f = (raw as NSString).lastPathComponent
        if let r = f.range(of: "^[0-9]{8}-[0-9]{6}-", options: .regularExpression) {
            f.removeSubrange(r)  // strip the inbox's "YYYYMMDD-HHMMSS-" stamp
        }
        return f
    }
    private func queueLine(_ a: Activity) -> String? {
        var parts: [String] = []
        if let q = a.queue {
            if let p = q["pending"] { parts.append("\(p) pending") }
            if let d = q["done"] { parts.append("\(d) done") }
            if let fl = q["failed"], fl > 0 { parts.append("\(fl) failed") }
        }
        if let ag = a.agents { parts.append("\(ag) agent\(ag == 1 ? "" : "s")") }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    // SKILLS — service skills with an inbox become route buttons.
    @ViewBuilder private var skillsFace: some View {
        let skills = card.skills ?? []
        let warm = skills.filter { ($0.warm ?? false) }
        let routable = skills.filter { $0.inbox != nil }
        let others = skills.filter { !($0.warm ?? false) && $0.inbox == nil }

        VStack(alignment: .leading, spacing: 6) {
            if !routable.isEmpty {
                FlowChips(routable.map { sk in
                    Chip(text: sk.name, on: sk.warm ?? false, kind: .route) {
                        if card.origin != .local { model.route(skill: sk, on: card) }
                    }
                })
            }
            if !warm.filter({ $0.inbox == nil }).isEmpty {
                FlowChips(warm.filter { $0.inbox == nil }.map { sk in
                    Chip(text: sk.name, on: true, kind: .service)
                })
            }
            Text("\(others.count) installed skill\(others.count == 1 ? "" : "s")")
                .font(.caption2).foregroundColor(.secondary)
        }
    }

    // RUN — every Apple-Panel action this machine advertises, as a button.
    // Click → runs locally (this Mac) or dispatches over Syncthing (a peer).
    @ViewBuilder private func runFace(_ acts: [PanelAction]) -> some View {
        let groups = Dictionary(grouping: acts, by: { $0.group })
        VStack(alignment: .leading, spacing: 7) {
            ForEach(groups.keys.sorted(), id: \.self) { g in
                Text(g).font(.caption2).foregroundColor(.secondary).tracking(0.5)
                ForEach(groups[g] ?? []) { act in
                    Button { model.run(action: act, on: card) } label: {
                        HStack(spacing: 6) {
                            Image(systemName: act.kind == "safe" ? "play.circle" : "exclamationmark.triangle.fill")
                                .font(.caption2)
                                .foregroundColor(act.kind == "safe" ? .accentColor : .orange)
                            Text(act.label).font(.caption).lineLimit(1).truncationMode(.tail)
                            if act.arg != nil {
                                Image(systemName: "character.cursor.ibeam")
                                    .font(.system(size: 8)).foregroundColor(.secondary)
                            }
                            Spacer(minLength: 0)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help(act.desc ?? "")
                }
            }
        }
    }

    // APPS · eppc — read-only probes that drive the peer's real apps live over
    // Remote Application Scripting. Click → osascript over eppc → result sheet.
    @ViewBuilder private var eppcFace: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(model.eppcProbes) { probe in
                Button { model.runEppc(probe: probe, on: card) } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "macwindow").font(.caption2).foregroundColor(.accentColor)
                        Text(probe.label).font(.caption).lineLimit(1).truncationMode(.tail)
                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(probe.desc ?? "")
            }
            Text("Each connection asks for a password (macOS won't cache eppc) — "
                + "use Snapshot for one prompt. Needs Remote Application Scripting on + peer reachable.")
                .font(.system(size: 9)).foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // small helpers
    private func row(_ t: String, bold: Bool = false) -> some View {
        Text(t).font(bold ? .callout.bold() : .callout).fixedSize(horizontal: false, vertical: true)
    }
    private func kv(_ k: String, _ v: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(k).font(.caption).foregroundColor(.secondary).frame(width: 78, alignment: .leading)
            Text(v).font(.caption).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

// ───────────────────────────── Chips ─────────────────────────────

struct Chip: Identifiable {
    let id = UUID()
    let text: String
    let on: Bool
    let kind: Kind
    var action: (() -> Void)? = nil
    enum Kind { case channel, service, route }
}

/// A simple wrapping row of chips (SwiftUI has no native flow layout pre-16,
/// so we lay out greedily into lines).
struct FlowChips: View {
    let chips: [Chip]
    init(_ chips: [Chip]) { self.chips = chips }
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(lines().enumerated()), id: \.offset) { _, line in
                HStack(spacing: 5) {
                    ForEach(line) { chip in ChipView(chip: chip) }
                }
            }
        }
    }
    // Greedy wrap by character budget (cards are fixed-width).
    private func lines() -> [[Chip]] {
        var out: [[Chip]] = [[]]; var budget = 0
        for c in chips {
            let w = c.text.count + 4
            if budget + w > 40 && !out[out.count - 1].isEmpty { out.append([]); budget = 0 }
            out[out.count - 1].append(c); budget += w
        }
        return out
    }
}

struct ChipView: View {
    let chip: Chip
    var body: some View {
        let base = HStack(spacing: 4) {
            Circle().fill(chip.on ? Color.green : Color.gray.opacity(0.5))
                .frame(width: 6, height: 6)
            Text(chip.text).font(.caption2)
            if chip.kind == .route { Image(systemName: "paperplane.fill").font(.system(size: 8)) }
        }
        .padding(.horizontal, 7).padding(.vertical, 3)
        .background(Capsule().fill(color.opacity(0.16)))
        .overlay(Capsule().stroke(color.opacity(0.35), lineWidth: 0.5))

        if chip.kind == .route, let action = chip.action {
            Button(action: action) { base }.buttonStyle(.plain).help("Route a file here")
        } else {
            base
        }
    }
    private var color: Color {
        switch chip.kind {
        case .channel: return .blue
        case .service: return .green
        case .route: return chip.on ? .accentColor : .gray
        }
    }
}
