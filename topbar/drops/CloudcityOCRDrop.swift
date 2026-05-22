// CloudcityOCRDrop — Finder-toolbar drop target for the Cloudcity Syncthing
// OCR pipeline. Drag a PDF onto this app in the Finder toolbar; it shells
// out to ~/.claude/skills/bbs/bin/bbs-ocr-submit.sh which drops the file
// into ~/work/comms/queue/ocr-inbox/, which Syncthing mirrors to the remote
// OCR worker. Results return to ~/work/comms/queue/ocr-results/.
//
// No local OCR ever runs from this wrapper — that's a hard rule (see global
// CLAUDE.md). Local tesseract/ocrmypdf wear the laptop hardware; this app
// is the zero-touch route to the remote pipeline.
//
// Apple-native: Cocoa only, no third-party deps.

import Cocoa

class OCRDropDelegate: NSObject, NSApplicationDelegate {
    var handledFiles = false

    func application(_ sender: NSApplication, open urls: [URL]) {
        handledFiles = true
        let home = NSHomeDirectory()
        let script = "\(home)/.claude/skills/bbs/bin/bbs-ocr-submit.sh"
        var submitted: [String] = []
        var failed: [String] = []

        for url in urls {
            let p = Process()
            p.launchPath = "/bin/bash"
            p.arguments = [script, url.path]
            let pipe = Pipe()
            p.standardError = pipe
            p.standardOutput = pipe
            do {
                try p.run()
                p.waitUntilExit()
                if p.terminationStatus == 0 {
                    submitted.append(url.lastPathComponent)
                } else {
                    failed.append(url.lastPathComponent)
                }
            } catch {
                failed.append(url.lastPathComponent)
            }
        }

        // Show one Notification Center toast summarising the submission.
        // osascript is the simplest Apple-native path that works in an
        // unsigned-or-ad-hoc wrapper without the UserNotifications-framework
        // registration dance.
        let msg: String
        if failed.isEmpty {
            msg = "Submitted \(submitted.count) PDF\(submitted.count == 1 ? "" : "s") to Cloudcity OCR via Syncthing."
        } else if submitted.isEmpty {
            msg = "OCR submit FAILED for \(failed.count) file\(failed.count == 1 ? "" : "s")."
        } else {
            msg = "Submitted \(submitted.count); FAILED \(failed.count)."
        }
        let osa = Process()
        osa.launchPath = "/usr/bin/osascript"
        osa.arguments = ["-e",
            "display notification \"\(msg)\" with title \"Cloudcity OCR Drop\""]
        try? osa.run()
        osa.waitUntilExit()

        NSApp.terminate(nil)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            if self?.handledFiles != true {
                NSApp.terminate(nil)
            }
        }
    }
}

let app = NSApplication.shared
let delegate = OCRDropDelegate()
app.delegate = delegate
app.run()
