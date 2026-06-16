// Filee — the bottom rung of the convey ladder.
//
// "Filee" (Finnish): both a fish FILLET and, said aloud, "lots of files" (file-ee).
// A folder's files, rendered as boxes you can fillet, navigate, and convey.
//
// Esa's waterdrop: "they should be boxes on a screen. you boot up, you're in a folder,
// you see the files, the files are boxes next to each other." We're re-inventing the
// GUI — but where WE define what a box is and what can be done to it. The moment we own
// "render a file as a box," we own everything downstream: automate-what-happens-to-it,
// attach meaning, link local↔online, convey it.
//
// THE LADDER (same primitive, bigger nouns each rung — see Filee.feature):
//   file → folder → repo (commits/gates) → skills+memory → MLX-reader view → fleet (peers)
// Fleet.app already renders the TOP rung (peers-as-boxes). Filee renders the BOTTOM
// rung (files-as-boxes). Identical idiom on purpose. BoxItem.kind makes file/folder/
// repo/skill/machine the same thing — a box. A "filee" is what sits in a box at rung 1.
//
// Apple-native: SwiftUI + AppKit, compiled with `xcrun swiftc`, no Homebrew, no Xcode.
// FEATURE-CARD >> ~/work/apple/filee/Filee.feature

import SwiftUI
import AppKit
import Foundation

// ───────────────────────────── Model ─────────────────────────────

/// A box is a box is a box. Files are the FIRST kind; the ladder adds the rest.
enum BoxKind: String {
    case folder, file, repo, skill, machine
    var sfSymbol: String {
        switch self {
        case .folder:  return "folder"
        case .file:    return "doc"
        case .repo:    return "shippingbox"
        case .skill:   return "wand.and.stars"
        case .machine: return "desktopcomputer"
        }
    }
}

/// A typed bond read from a file's co-located `<name>.molecule.json` sidecar (convey's
/// molecule format). A processing RESULT is a bond: research.pdf --produces--> research.txt.
/// This is the bet made visible — the metadata that travelled WITH the file, now seen.
struct Bond: Decodable, Hashable {
    let to: String
    let kind: String            // part_of | produces | derived_from | associated_with | references
    let targetPath: String
    let note: String?
    enum CodingKeys: String, CodingKey { case to, kind, note; case targetPath = "target_path" }

    /// An ONLINE edge: target is a URL, not a filesystem path (kind "references").
    var isURL: Bool { targetPath.hasPrefix("http://") || targetPath.hasPrefix("https://") }

    /// Direction glyph: → produces, ← derived_from, ⊂ part_of, ↔ associated_with, ↗ references(url).
    var arrow: String {
        switch kind {
        case "produces":        return "→"
        case "derived_from":    return "←"
        case "part_of":         return "⊂"
        case "associated_with": return "↔"
        case "references":      return "↗"
        default:                return "·"
        }
    }
    /// Menu label tail: a file's basename, or a URL's host (so an online edge reads cleanly).
    var targetName: String {
        if isURL { return URL(string: targetPath)?.host ?? targetPath }
        return (targetPath as NSString).lastPathComponent
    }
    /// A URL edge is always "live" (we can't filestat it); a file edge must exist on disk.
    var exists: Bool { isURL || FileManager.default.fileExists(atPath: targetPath) }
}

/// The shape of a `<name>.molecule.json` sidecar — we only need its bonds.
private struct MoleculeSidecar: Decodable { let bonds: [Bond] }

private let _imageExts: Set<String> = ["png", "jpg", "jpeg", "gif", "heic", "heif", "tiff", "tif", "bmp", "webp"]

/// A downscaled thumbnail of an image file, so an image box SHOWS the image (a
/// wordcloud.png box is the wordcloud). nil for non-images → caller uses the Finder icon.
private func imageThumb(_ url: URL) -> NSImage? {
    guard _imageExts.contains(url.pathExtension.lowercased()),
          let img = NSImage(contentsOf: url), img.size.width > 0, img.size.height > 0 else { return nil }
    let maxDim: CGFloat = 128                       // keep a folder of big images light
    let s = img.size
    let scale = min(maxDim / s.width, maxDim / s.height, 1)
    let t = NSSize(width: s.width * scale, height: s.height * scale)
    let thumb = NSImage(size: t)
    thumb.lockFocus()
    img.draw(in: NSRect(origin: .zero, size: t))
    thumb.unlockFocus()
    return thumb
}

/// One box on the screen. Generic on purpose — a filee, a repo, a skill and a peer are
/// all just (icon, title, subtitle, kind, action, links). Today we fill it from the
/// filesystem; tomorrow from git, from skills/, from the fleet.
struct BoxItem: Identifiable {
    let id: String          // stable id (the path, for files)
    let url: URL?           // the thing on disk, if any
    let title: String       // shown big
    let subtitle: String    // shown small under the title
    let kind: BoxKind
    let icon: NSImage?      // real Finder icon for files; nil → SF Symbol fallback
    var bonds: [Bond] = []  // typed edges from <name>.molecule.json — the bet, made visible
    var links: [URL] = []   // local↔online edges — derived from bonds' target paths
}

/// Boots into a folder, lists it as boxes, lets you walk in/up, and tracks a keyboard
/// selection so arrow keys move a highlight across the grid. That's rung one.
final class FolderModel: ObservableObject {
    @Published var dir: URL
    @Published var items: [BoxItem] = []
    @Published var showHidden = false
    @Published var selection: String? = nil   // id of the selected box (arrow-key nav)

    // Running a convey verb ON a file from the box's widget — the folder becomes a place
    // where you DO something to files with convey, not just look at them.
    @Published var conveyOutput: String? = nil   // non-nil → the output sheet is shown
    @Published var conveyRunning = false
    @Published var conveyTitle = ""

    init() {
        // Keep the App-level @StateObject initializer trivial; defer listing to boot().
        self.dir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    }

    /// Called from the view's .onAppear — does the first listing off the init path.
    func boot() {
        let fm = FileManager.default
        let args = CommandLine.arguments
        var start: URL
        if args.count > 1, fm.fileExists(atPath: args[1]) {
            start = URL(fileURLWithPath: args[1])
        } else if let env = ProcessInfo.processInfo.environment["FILEE_DIR"], fm.fileExists(atPath: env) {
            start = URL(fileURLWithPath: env)
        } else {
            start = URL(fileURLWithPath: fm.currentDirectoryPath)
        }
        var isDir: ObjCBool = false
        if fm.fileExists(atPath: start.path, isDirectory: &isDir), !isDir.boolValue {
            start.deleteLastPathComponent()
        }
        dir = start
        load()
    }

    func load() {
        let fm = FileManager.default
        let keys: [URLResourceKey] = [.isDirectoryKey, .fileSizeKey, .contentTypeKey, .localizedTypeDescriptionKey]
        guard let urls = try? fm.contentsOfDirectory(at: dir,
                                                     includingPropertiesForKeys: keys,
                                                     options: showHidden ? [] : [.skipsHiddenFiles]) else {
            items = []; selection = nil; return
        }
        let ws = NSWorkspace.shared
        let mapped: [BoxItem] = urls.map { url in
            let vals = try? url.resourceValues(forKeys: Set(keys))
            let isDir = vals?.isDirectory ?? false
            let kind: BoxKind = isDir
                ? (fm.fileExists(atPath: url.appendingPathComponent(".git").path) ? .repo : .folder)
                : .file
            let sub: String
            if isDir {
                let n = (try? fm.contentsOfDirectory(atPath: url.path).count) ?? 0
                sub = kind == .repo ? "git repo · \(n) items" : "\(n) items"
            } else if let bytes = vals?.fileSize {
                sub = ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
            } else {
                sub = vals?.localizedTypeDescription ?? "file"
            }
            // The bet: read the molecule sidecar sitting BESIDE this box. `convey molecule`
            // wrote `<name>.molecule.json` next to the file; we just look down and see it.
            var bonds: [Bond] = []
            let sidecar = URL(fileURLWithPath: url.path + ".molecule.json")
            if let data = try? Data(contentsOf: sidecar),
               let mol = try? JSONDecoder().decode(MoleculeSidecar.self, from: data) {
                bonds = mol.bonds
            }
            // An IMAGE box shows the image itself (a wordcloud.png box IS the wordcloud),
            // not a generic file-type icon. Falls back to the Finder icon otherwise.
            return BoxItem(id: url.path, url: url, title: url.lastPathComponent,
                           subtitle: sub, kind: kind,
                           icon: imageThumb(url) ?? ws.icon(forFile: url.path),
                           bonds: bonds,
                           links: bonds.map { URL(fileURLWithPath: $0.targetPath) })
        }
        items = mapped.sorted {
            if ($0.kind == .file) != ($1.kind == .file) { return $0.kind != .file }
            return $0.title.localizedStandardCompare($1.title) == .orderedAscending
        }
        // Keep the current selection if it's still here (so a live reload doesn't jump);
        // else select the first box so the keyboard highlight has a starting point.
        if let k = selection, items.contains(where: { $0.id == k }) { /* keep */ }
        else { selection = items.first?.id }

        // auto-convey: armed folder → CHEAP molecule for files that just ARRIVED. We only
        // fire on a reload of the SAME folder (knownIdsDir == dir.path), so opening a
        // populated armed folder seeds quietly without molecule-ing everything at once.
        autoConvey = fm.fileExists(atPath: dir.appendingPathComponent(autoMarkerName).path)
        if autoConvey && knownIdsDir == dir.path {
            for box in items where !knownIds.contains(box.id)
                && box.kind == .file
                && box.bonds.isEmpty
                && !box.title.hasSuffix(".molecule.json")
                && !conveyingIds.contains(box.id) {
                quietConvey(box.id)
            }
        }
        knownIds = Set(items.map { $0.id })
        knownIdsDir = dir.path

        watchDir()   // (re)arm the live watcher on the folder now shown
    }

    // ── live folder watch: when the belt drops a .txt / .analysis.md / _ocr.pdf beside
    //    a file, those boxes APPEAR here as they land — you watch the change happen.
    private var dirWatch: DispatchSourceFileSystemObject?
    private var watchedPath = ""
    private var reloadPending = false

    func watchDir() {
        if watchedPath == dir.path && dirWatch != nil { return }
        dirWatch?.cancel(); dirWatch = nil
        let fd = open(dir.path, O_EVTONLY)
        guard fd >= 0 else { watchedPath = ""; return }
        watchedPath = dir.path
        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd, eventMask: [.write, .extend, .rename, .delete], queue: .main)
        src.setEventHandler { [weak self] in self?.scheduleReload() }
        src.setCancelHandler { close(fd) }
        src.resume()
        dirWatch = src
    }

    private func scheduleReload() {           // debounce a burst of FS events into one reload
        if reloadPending { return }
        reloadPending = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.reloadPending = false
            self?.load()
        }
    }

    func enter(_ box: BoxItem) {
        guard let url = box.url else { return }
        if box.kind == .folder || box.kind == .repo {
            dir = url; load()
        } else {
            NSWorkspace.shared.open(url)   // a filee opens in its default app
        }
    }

    /// Follow a molecule bond to its target: walk INTO a bonded folder, or REVEAL a bonded
    /// file in Finder. Dead targets (the source got moved/deleted) are no-ops — the widget
    /// greys them out, so this only fires on live edges.
    func goToBond(_ bond: Bond) {
        if bond.isURL {                                                   // ONLINE edge → open in browser
            if let u = URL(string: bond.targetPath) { NSWorkspace.shared.open(u) }
            return
        }
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: bond.targetPath, isDirectory: &isDir) else { return }
        let url = URL(fileURLWithPath: bond.targetPath)
        if isDir.boolValue { dir = url; load() }                          // enter the bonded folder
        else { NSWorkspace.shared.activateFileViewerSelecting([url]) }     // reveal the bonded file
    }

    /// Open whatever the keyboard selection points at (Return key).
    func openSelected() {
        if let id = selection, let box = items.first(where: { $0.id == id }) { enter(box) }
    }

    /// Move the highlight with the arrow keys. `columns` = boxes per row (from layout).
    func move(_ dir: MoveCommandDirection, columns: Int) {
        guard !items.isEmpty else { return }
        let cols = max(1, columns)
        let idx = items.firstIndex { $0.id == selection } ?? -1
        var n: Int
        switch dir {
        case .left:  n = idx <= 0 ? 0 : idx - 1
        case .right: n = idx < 0 ? 0 : min(idx + 1, items.count - 1)
        case .up:    n = idx < 0 ? 0 : max(idx - cols, 0)
        case .down:  n = idx < 0 ? 0 : min(idx + cols, items.count - 1)
        @unknown default: n = max(idx, 0)
        }
        selection = items[max(0, min(n, items.count - 1))].id
    }

    func up() {
        let parent = dir.deletingLastPathComponent()
        if parent.path != dir.path { dir = parent; load() }
    }

    func pick() {
        let p = NSOpenPanel()
        p.canChooseDirectories = true
        p.canChooseFiles = false
        p.allowsMultipleSelection = false
        p.directoryURL = dir
        if p.runModal() == .OK, let url = p.url { dir = url; load() }
    }

    func toggleHidden() { showHidden.toggle(); load() }

    // Arrow-key + Return navigation via an AppKit local key monitor. This is robust:
    // SwiftUI's .focusable()/.onMoveCommand()/@FocusState machinery suppressed the
    // window on this macOS build, so we capture keys at the AppKit layer instead.
    private var keyMonitor: Any?
    func installKeyMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            let width = NSApp.keyWindow?.contentView?.bounds.width
                ?? NSApp.mainWindow?.frame.width ?? 820
            let cols = max(1, Int((width - 40) / 148))   // must match the grid's cell stride
            switch event.keyCode {
            case 123: self.move(.left,  columns: cols); return nil   // ←
            case 124: self.move(.right, columns: cols); return nil   // →
            case 125: self.move(.down,  columns: cols); return nil   // ↓
            case 126: self.move(.up,    columns: cols); return nil   // ↑
            case 36, 76: self.openSelected();           return nil   // Return / keypad Enter
            default: return event
            }
        }
    }

    // ── do something with a box, using convey + friends ─────────────────────────
    // The box's widget runs a verb and shows the output in a sheet.
    private let conveyBin = "/Users/esaruoho/work/apple/bin/convey"
    private let conveyCwd = "/Users/esaruoho/work/convey"   // so `belt --spec media.filerule` resolves
    private let folderMemoryBin = "/Users/esaruoho/work/apple/bin/folder-memory"

    /// Run any executable, capture stdout+stderr into the sheet, then reload (a verb may
    /// have produced files — OCR .txt, .molecule.json, .memory.md — show them now).
    func runProcess(_ exec: String, _ args: [String], cwd: String, title: String) {
        conveyTitle = title
        conveyOutput = ""          // non-nil → sheet appears immediately
        conveyRunning = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let p = Process()
            p.executableURL = URL(fileURLWithPath: exec)
            p.arguments = args
            p.currentDirectoryURL = URL(fileURLWithPath: cwd)
            let pipe = Pipe()
            p.standardOutput = pipe; p.standardError = pipe
            var text = ""
            do {
                try p.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                p.waitUntilExit()
                text = String(data: data, encoding: .utf8) ?? ""
            } catch {
                text = "couldn't run \((exec as NSString).lastPathComponent): \(error.localizedDescription)"
            }
            DispatchQueue.main.async {
                self.conveyOutput = text.isEmpty ? "(no output)" : text
                self.conveyRunning = false
                self.load()
            }
        }
    }

    func runConvey(_ args: [String], title: String) {
        runProcess(conveyBin, args, cwd: conveyCwd, title: title)
    }

    /// Prompt for a URL, then `convey molecule <file> --from-url <url>` — the ONLINE half of
    /// the local↔online edge (a transcript ← its YouTube video). The resulting bond's target
    /// IS the URL, so its Bonds-menu row opens in the browser.
    func linkURL(_ box: BoxItem) {
        guard let url = box.url else { return }
        let alert = NSAlert()
        alert.messageText = "Link \(box.title) to an online source"
        alert.informativeText = "A URL this file references (e.g. the video it came from):"
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 360, height: 24))
        field.placeholderString = "https://…"
        alert.accessoryView = field
        alert.addButton(withTitle: "Link"); alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn, !field.stringValue.isEmpty {
            runConvey(["molecule", url.path, "--from-url", field.stringValue],
                      title: "molecule --from-url · \(box.title)")
        }
    }

    // ── folder memory: give a folder a voice (folder-memory triad) ───────────────
    func buildFolderMemory(_ box: BoxItem) {
        guard let url = box.url else { return }
        runProcess(folderMemoryBin, [url.path], cwd: conveyCwd, title: "folder-memory · \(box.title)")
    }
    func showFolderMemory(_ box: BoxItem) {
        guard let url = box.url else { return }
        let mem = url.appendingPathComponent(".memory.md")
        if FileManager.default.fileExists(atPath: mem.path) { NSWorkspace.shared.open(mem) }
        else { buildFolderMemory(box) }   // none yet → build it
    }
    /// Open Terminal in the folder running `mlx-here` — standing in the folder arms its
    /// governing skill; this is the interactive "talk to it" the capture-sheet can't host.
    func talkToFolder(_ box: BoxItem) {
        guard let url = box.url else { return }
        let src = "tell application \"Terminal\"\ndo script \"cd \\\"\(url.path)\\\" && mlx-here\"\nactivate\nend tell"
        NSAppleScript(source: src)?.executeAndReturnError(nil)
    }

    // ── rung 3: open a repo box into its commits ─────────────────────────────────
    func showCommits(_ box: BoxItem) {
        guard let url = box.url else { return }
        runProcess("/usr/bin/git", ["-C", url.path, "log", "--oneline", "--decorate", "-40"],
                   cwd: url.path, title: "git log · \(box.title)")
    }

    // ── auto-convey: a folder armed to molecule new files as they LAND ───────────
    // SAFE by design: auto-runs only the CHEAP `convey molecule --json` (writes a sidecar,
    // no OCR, no CPU burn). The heavy belt --run stays manual. Marker: `.filee-autoconvey`.
    @Published var autoConvey = false
    private var knownIds: Set<String> = []
    private var knownIdsDir = ""
    private var conveyingIds: Set<String> = []
    private let autoMarkerName = ".filee-autoconvey"

    func toggleAutoConvey() {
        let marker = dir.appendingPathComponent(autoMarkerName)
        if autoConvey { try? FileManager.default.removeItem(at: marker) }
        else {
            FileManager.default.createFile(atPath: marker.path,
                contents: Data("filee auto-convey: new files here get `convey molecule --json` (cheap; no OCR).\n".utf8))
        }
        load()
    }

    /// Background `convey molecule --json` with NO sheet — used by auto-convey. Loop-free:
    /// it gives the file a sidecar, after which the file has bonds and is no longer "fresh".
    private func quietConvey(_ id: String) {
        conveyingIds.insert(id)
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            let p = Process()
            p.executableURL = URL(fileURLWithPath: self.conveyBin)
            p.arguments = ["molecule", id, "--json"]
            p.currentDirectoryURL = URL(fileURLWithPath: self.conveyCwd)
            p.standardOutput = Pipe(); p.standardError = Pipe()
            try? p.run(); p.waitUntilExit()
            DispatchQueue.main.async { self.conveyingIds.remove(id); self.load() }
        }
    }

    /// Prompt for a question, then `convey ask <file> "<q>"` — the file's molecule is the
    /// context; convey prints the answer (and speaks it Apple-natively).
    func askConvey(_ box: BoxItem) {
        guard let url = box.url else { return }
        let alert = NSAlert()
        alert.messageText = "Ask convey about \(box.title)"
        alert.informativeText = "Your question — the file's molecule (its bonds) is the context:"
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 340, height: 24))
        field.placeholderString = "What is this and how does it relate to the files around it?"
        alert.accessoryView = field
        alert.addButton(withTitle: "Ask")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            let q = field.stringValue.isEmpty
                ? "What is this file and how does it relate to the files around it?"
                : field.stringValue
            runConvey(["ask", url.path, q], title: "convey ask · \(box.title)")
        }
    }
}

// ───────────────────────────── Views ─────────────────────────────

@main
struct FileeApp: App {
    @StateObject private var model = FolderModel()
    var body: some Scene {
        WindowGroup("Filee") {
            FileeView().environmentObject(model).onAppear { model.boot() }
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 820, height: 600)
    }
}

struct FileeView: View {
    @EnvironmentObject var model: FolderModel

    // Adaptive grid; cell footprint ~148 (width 130 + padding 8·2 + spacing). The key
    // monitor uses the same 148 stride to compute columns for up/down navigation.
    private let columns = [GridItem(.adaptive(minimum: 120, maximum: 160), spacing: 18)]

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(model.items) { box in
                        BoxView(box: box, selected: model.selection == box.id)
                            .onTapGesture(count: 2) { model.selection = box.id; model.enter(box) }
                            .onTapGesture(count: 1) { model.selection = box.id }
                            .contextMenu { widget(for: box) }   // right-click = "the whole widget"
                    }
                }
                .padding(20)
            }
            footer
        }
        .frame(minWidth: 480, minHeight: 360)
        .onAppear { model.installKeyMonitor() }   // arrow keys + Return, via AppKit
        .sheet(isPresented: Binding(
            get: { model.conveyOutput != nil },
            set: { if !$0 { model.conveyOutput = nil } })) {
            ConveyOutputView().environmentObject(model)
        }
    }

    // The breadcrumb / boot-into-a-folder bar.
    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "fish").foregroundColor(.accentColor)
            Button { model.up() } label: { Image(systemName: "chevron.up") }
                .buttonStyle(.borderless).help("Up one folder")
            Text(model.dir.path)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(1).truncationMode(.head)
            Spacer()
            Button { model.toggleAutoConvey() } label: {
                Image(systemName: model.autoConvey ? "bolt.fill" : "bolt.slash")
                    .foregroundColor(model.autoConvey ? .accentColor : .secondary)
            }.buttonStyle(.borderless)
             .help(model.autoConvey
                ? "Auto-convey ON: new files here auto-get `convey molecule --json` (cheap, no OCR). Click to disarm."
                : "Auto-convey OFF: arm this folder so new files auto-grow their molecule.")
            Button { model.toggleHidden() } label: {
                Image(systemName: model.showHidden ? "eye" : "eye.slash")
            }.buttonStyle(.borderless).help("Show hidden files")
            Button { model.pick() } label: { Image(systemName: "folder.badge.plus") }
                .buttonStyle(.borderless).help("Open another folder…")
        }
        .padding(.horizontal, 14).padding(.vertical, 9)
    }

    // The connected-data thesis, stated honestly — boxes today, edges next.
    private var footer: some View {
        HStack {
            Text("\(model.items.count) filee\(model.items.count == 1 ? "" : "s")")
            Spacer()
            Text("file → repo → skill → machine · same box, bigger noun")
                .foregroundColor(.secondary)
        }
        .font(.caption2)
        .padding(.horizontal, 14).padding(.vertical, 6)
        .background(Color(NSColor.windowBackgroundColor))
    }

    @ViewBuilder
    private func widget(for box: BoxItem) -> some View {
        if box.kind == .folder || box.kind == .repo {
            Button("Enter") { model.enter(box) }
        } else {
            Button("Open") { if let u = box.url { NSWorkspace.shared.open(u) } }
        }
        Button("Reveal in Finder") {
            if let u = box.url { NSWorkspace.shared.activateFileViewerSelecting([u]) }
        }
        Button("Copy Path") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(box.url?.path ?? box.id, forType: .string)
        }
        // The connected-data thesis, no longer @designed: this file's molecule bonds, each a
        // row you can follow. → produces, ← derived_from, ⊂ part_of, ↔ associated_with.
        if !box.bonds.isEmpty {
            Divider()
            Menu("⋈ Bonds (\(box.bonds.count))") {
                ForEach(box.bonds, id: \.self) { bond in
                    Button("\(bond.arrow) \(bond.kind) · \(bond.targetName)") {
                        model.goToBond(bond)
                    }
                    .disabled(!bond.exists)   // grey out edges whose target is gone
                }
            }
        }
        Divider()
        // Do something with this box.
        if box.kind == .folder || box.kind == .repo {
            if box.kind == .repo {                                  // rung 3: the repo's interior
                Button("Show commits (git log)") { model.showCommits(box) }
            }
            Menu("Folder memory") {                                 // give the folder a voice
                Button("Build / refresh (.memory.md)") { model.buildFolderMemory(box) }
                Button("Show .memory.md") { model.showFolderMemory(box) }
                Button("Talk to this folder (Terminal)") { model.talkToFolder(box) }
            }
            Button("convey changed") {
                model.runConvey(["changed", box.url?.path ?? "", "--no-html"],
                                title: "convey changed · \(box.title)")
            }
        } else {
            Button("convey molecule") {
                model.runConvey(["molecule", box.url?.path ?? box.id],
                                title: "convey molecule · \(box.title)")
            }
            Button("Link to URL… (online edge)") { model.linkURL(box) }
            Button("convey ask…") { model.askConvey(box) }
            Button("convey belt (plan)") {
                model.runConvey(["belt", box.url?.path ?? box.id],
                                title: "convey belt · \(box.title)")
            }
            Button("convey belt — RUN ▶  (OCR a PDF, etc.)") {
                model.runConvey(["belt", box.url?.path ?? box.id, "--run"],
                                title: "convey belt --run · \(box.title)")
            }
        }
    }
}

/// The result of running a convey verb on a filee — shown right in the folder window.
struct ConveyOutputView: View {
    @EnvironmentObject var model: FolderModel
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "fish").foregroundColor(.accentColor)
                Text(model.conveyTitle).font(.headline).lineLimit(1)
                if model.conveyRunning {
                    ProgressView().scaleEffect(0.6)
                    Text("running…").font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Button("Done") { model.conveyOutput = nil }.keyboardShortcut(.defaultAction)
            }
            ScrollView {
                Text(model.conveyOutput ?? "")
                    .font(.system(.callout, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(NSColor.textBackgroundColor))
        }
        .padding(16)
        .frame(width: 660, height: 460)
    }
}

/// One box: real Finder icon (or SF Symbol fallback), title, subtitle. A repo gets a
/// tiny badge; the keyboard selection gets an accent ring. Renders every rung's noun.
struct BoxView: View {
    let box: BoxItem
    var selected: Bool = false

    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .bottomTrailing) {
                if let icon = box.icon {
                    Image(nsImage: icon)
                        .resizable().scaledToFit()
                        .frame(width: 60, height: 60)
                } else {
                    Image(systemName: box.kind.sfSymbol)
                        .resizable().scaledToFit()
                        .frame(width: 48, height: 48)
                        .foregroundColor(.accentColor)
                }
                if box.kind == .repo {
                    Image(systemName: "point.3.connected.trianglepath.dotted")
                        .font(.system(size: 14))
                        .foregroundColor(.accentColor)
                        .background(Circle().fill(Color(NSColor.windowBackgroundColor)).frame(width: 18, height: 18))
                }
            }
            .frame(height: 64)
            Text(box.title)
                .font(.system(size: 12))
                .lineLimit(2).multilineTextAlignment(.center)
            Text(box.subtitle)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(width: 130, height: 120)
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 10)
            .fill(selected ? Color.accentColor.opacity(0.22) : Color(NSColor.controlBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 10)
            .stroke(selected ? Color.accentColor : Color(NSColor.separatorColor),
                    lineWidth: selected ? 2 : 0.5))
        // The bet, seen: a box that carries molecule bonds wears a ⋈ count chip.
        .overlay(alignment: .topTrailing) {
            if !box.bonds.isEmpty {
                Text("⋈ \(box.bonds.count)")
                    .font(.system(size: 9, weight: .semibold))
                    .padding(.horizontal, 5).padding(.vertical, 2)
                    .background(Capsule().fill(Color.accentColor.opacity(0.85)))
                    .foregroundColor(.white)
                    .padding(5)
            }
        }
        .help(box.url?.path ?? box.title)
    }
}
