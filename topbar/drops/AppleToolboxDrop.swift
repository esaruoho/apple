// AppleToolboxDrop — drop-target wrapper for AppleToolbox.
//
// Why this exists: AppleToolbox.app sets LSUIElement=true (menu-bar agent,
// no Dock icon). macOS LaunchServices refuses to treat LSUIElement apps as
// Finder-toolbar drop targets — drag a file onto one and you get the (X)
// no-drop cursor, regardless of CFBundleDocumentTypes.
//
// This wrapper is a regular app (no LSUIElement). Its only job: accept the
// dropped file via application(_:open:), forward the path to AppleToolbox
// via `open -a AppleToolbox <path>` (which dispatches an Apple Event to the
// already-running instance, triggering ITS application(_:open:) handler),
// then quit. The user drags THIS .app to the Finder toolbar.
//
// Apple-native: Cocoa only, no third-party deps.

import Cocoa

class DropDelegate: NSObject, NSApplicationDelegate {
    let targetApp = "/Applications/Apple-Workflows/AppleToolbox.app"
    var handledFiles = false

    func application(_ sender: NSApplication, open urls: [URL]) {
        handledFiles = true
        for url in urls {
            let p = Process()
            p.launchPath = "/usr/bin/open"
            p.arguments = ["-a", targetApp, url.path]
            try? p.run()
            p.waitUntilExit()
        }
        NSApp.terminate(nil)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // If launched without files (e.g. someone double-clicked the wrapper
        // by mistake), give the open event a brief window to arrive then
        // self-terminate so we never linger in the Dock.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            if self?.handledFiles != true {
                NSApp.terminate(nil)
            }
        }
    }
}

let app = NSApplication.shared
let delegate = DropDelegate()
app.delegate = delegate
app.run()
