// LiveEnvelopePanel — a small always-on-top, non-activating panel of buttons that
// drive live-envelope. Every button just shells out to the same binary the
// Keyboard Maestro macros use, so behaviour is identical either way.
//
// Panel buttons, top to bottom:
//   Transpose:  -12 | 0 | +12        (relative nudge / absolute reset via AbletonOSC)
//   Envelope:   Gain | Transpose | Sample Offset   (direct select, no toggling)
// A status line along the bottom shows the last result or error.

import Cocoa

let BIN = "/Users/esaruoho/work/apple/bin/live-envelope"
let PANEL_WIDTH: CGFloat = 460

func runLiveEnvelope(_ args: [String], completion: @escaping (String, Bool) -> Void) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: BIN)
    process.arguments = args
    let outPipe = Pipe(), errPipe = Pipe()
    process.standardOutput = outPipe
    process.standardError = errPipe
    process.terminationHandler = { proc in
        let out = String(data: outPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let err = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let ok = proc.terminationStatus == 0
        let text = ok ? out.trimmingCharacters(in: .whitespacesAndNewlines)
                      : err.trimmingCharacters(in: .whitespacesAndNewlines)
        DispatchQueue.main.async { completion(text, ok) }
    }
    do {
        try process.run()
    } catch {
        DispatchQueue.main.async { completion("failed to launch live-envelope: \(error)", false) }
    }
}

let DEFAULT_TITLE = "Live Clip Envelopes"

final class PanelController: NSObject {
    let panel: NSPanel
    //--------------------------------------------------------------------------------
    // Bumped on every press; a delayed revert-to-default only applies if it's still
    // the most recent press, so a rapid second click isn't stomped by the first
    // click's timer reverting the title out from under it.
    //--------------------------------------------------------------------------------
    var generation = 0

    override init() {
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: PANEL_WIDTH, height: 100),
            styleMask: [.nonactivatingPanel, .titled, .closable, .utilityWindow],
            backing: .buffered,
            defer: false)

        super.init()

        //--------------------------------------------------------------------------------
        // The app's name lives in the title bar, not as a row of button-area text, so it
        // costs no vertical space. The title also doubles as the result/error readout.
        //--------------------------------------------------------------------------------
        panel.title = DEFAULT_TITLE
        panel.titleVisibility = .visible
        panel.titlebarAppearsTransparent = false
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.isReleasedWhenClosed = false

        let root = NSStackView()
        root.orientation = .vertical
        root.spacing = 6
        root.edgeInsets = NSEdgeInsets(top: 8, left: 10, bottom: 6, right: 10)
        root.translatesAutoresizingMaskIntoConstraints = false

        //--------------------------------------------------------------------------------
        // No section labels: the button captions ("Gain", "+12", ...) already say what
        // each one does, so a header above them would only repeat that and cost a row.
        //--------------------------------------------------------------------------------
        root.addArrangedSubview(row([
            smallButton("-48", "transpose-set-neg48"),
            smallButton("-36", "transpose-set-neg36"),
            smallButton("-24", "transpose-set-neg24"),
            smallButton("-12", "transpose-down-12"),
            smallButton("0", "transpose-set-0"),
            smallButton("+12", "transpose-up-12"),
            smallButton("+24", "transpose-set-24"),
            smallButton("+36", "transpose-set-36"),
            smallButton("+48", "transpose-set-48"),
        ]))

        root.addArrangedSubview(row([
            button("Gain", "exact Gain"),
            button("Transpose", "exact Transposition"),
            button("Sample Offset", "exact Sample Offset"),
        ]))

        panel.contentView = NSView(frame: panel.contentRect(forFrameRect: panel.frame))
        panel.contentView!.addSubview(root)
        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: panel.contentView!.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: panel.contentView!.trailingAnchor),
            root.topAnchor.constraint(equalTo: panel.contentView!.topAnchor),
            root.bottomAnchor.constraint(equalTo: panel.contentView!.bottomAnchor),
        ])

        //--------------------------------------------------------------------------------
        // Fixed width, always. Nothing inside — including a long error message in the
        // status field — is allowed to grow the window; only its height can adapt.
        //--------------------------------------------------------------------------------
        panel.minSize = NSSize(width: PANEL_WIDTH, height: 0)
        panel.maxSize = NSSize(width: PANEL_WIDTH, height: .greatestFiniteMagnitude)

        //--------------------------------------------------------------------------------
        // Size to exactly what the two button rows need, rather than a guessed constant
        // — this is what keeps the window free of dead space.
        //--------------------------------------------------------------------------------
        root.layoutSubtreeIfNeeded()
        panel.setContentSize(NSSize(width: PANEL_WIDTH, height: root.fittingSize.height))

        panel.center()
        panel.makeKeyAndOrderFront(nil)
    }

    func row(_ views: [NSView]) -> NSStackView {
        let stack = NSStackView(views: views)
        stack.orientation = .horizontal
        stack.spacing = 6
        stack.distribution = .fillEqually
        return stack
    }

    func button(_ title: String, _ args: String) -> NSButton {
        let button = NSButton(title: title, target: self, action: #selector(pressed(_:)))
        button.bezelStyle = .rounded
        button.tag = commandTable.count
        commandTable.append(args)
        return button
    }

    /// A row of nine needs a smaller font to stay legible at the panel's fixed width.
    func smallButton(_ title: String, _ args: String) -> NSButton {
        let button = self.button(title, args)
        button.font = .systemFont(ofSize: 10)
        return button
    }

    var commandTable: [String] = []

    @objc func pressed(_ sender: NSButton) {
        generation += 1
        let thisPress = generation
        let args = commandTable[sender.tag].split(separator: " ").map(String.init)

        runLiveEnvelope(args) { [weak self] text, ok in
            guard let self = self else { return }
            self.panel.title = ok ? text : "⚠ \(text)"
            //--------------------------------------------------------------------------------
            // An error stays up longer than a success, since it's the one worth reading.
            //--------------------------------------------------------------------------------
            let holdSeconds = ok ? 1.5 : 5.0
            DispatchQueue.main.asyncAfter(deadline: .now() + holdSeconds) {
                if self.generation == thisPress { self.panel.title = DEFAULT_TITLE }
            }
        }
    }
}

let app = NSApplication.shared
//--------------------------------------------------------------------------------
// Regular, not accessory: this needs a Dock icon so it can be launched from the
// Dock like any other app, at the cost of taking a normal spot in Cmd-Tab.
//--------------------------------------------------------------------------------
app.setActivationPolicy(.regular)
let mainMenu = NSMenu()
let appMenuItem = NSMenuItem()
mainMenu.addItem(appMenuItem)
let appMenu = NSMenu()
appMenu.addItem(withTitle: "Quit Live Envelopes", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
appMenuItem.submenu = appMenu
app.mainMenu = mainMenu

let delegate = AppDelegate()
app.delegate = delegate
app.run()

final class AppDelegate: NSObject, NSApplicationDelegate {
    var controller: PanelController?
    func applicationDidFinishLaunching(_ notification: Notification) {
        controller = PanelController()
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
// rebuild-test-1786225286
