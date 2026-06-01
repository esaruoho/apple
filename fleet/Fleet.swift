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
    var running: Running?

    // Transport metadata — not part of the JSON; set after decode.
    var origin: Origin = .local
    var lastSeen: Date = Date()

    enum CodingKeys: String, CodingKey { case id, ts, identity, shape, ports, skills, running }

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
}

// ─────────────────────── Machine-card data source ───────────────────────

enum CardSource {
    static let bin = "\(NSHomeDirectory())/work/apple/bin/machine-card"
    static let queue = "\(NSHomeDirectory())/work/comms/queue"

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

    /// Raw public-card JSON bytes to hand to a peer over the wire.
    static func localPublicJSON() -> Data? {
        guard let card = local(publicOnly: true) else { return nil }
        return try? JSONEncoder().encode(card)
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
        guard let payload = CardSource.localPublicJSON() else { return }
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

final class FleetModel: ObservableObject {
    @Published var local: Card?
    @Published var peers: [String: Card] = [:]   // id → card
    @Published var toast: String?

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
            DispatchQueue.main.async {
                for c in found {
                    // Don't let a stale syncthing card clobber a live bonjour one.
                    if let existing = self.peers[c.id], existing.origin == .bonjour { continue }
                    self.peers[c.id] = c
                }
            }
        }
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
    }
}

struct FleetView: View {
    @EnvironmentObject var model: FleetModel
    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView(.horizontal, showsIndicators: true) {
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
        }
        .padding(.horizontal, 14).padding(.vertical, 9)
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
            }
            Divider()
            face("SHAPE", icon: "cpu") { shapeFace }
            face("PORTS", icon: "cable.connector") { portsFace }
            face("RUNNING", icon: "waveform.path.ecg") { runningFace }
            face("SKILLS", icon: "wrench.and.screwdriver") { skillsFace }
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
