import Foundation
import ApplicationServices
import Cocoa

// Helper to get string attribute
func getAttr(_ elem: AXUIElement, _ attr: String) -> String {
    var val: CFTypeRef?
    if AXUIElementCopyAttributeValue(elem, attr as CFString, &val) == .success {
        return (val as? String) ?? ""
    }
    return ""
}

// Find element matching predicate recursively
func findAXElement(_ root: AXUIElement, match: (AXUIElement) -> Bool) -> AXUIElement? {
    if match(root) {
        return root
    }
    var childrenRef: CFTypeRef?
    if AXUIElementCopyAttributeValue(root, kAXChildrenAttribute as CFString, &childrenRef) == .success,
       let children = childrenRef as? [AXUIElement] {
        for child in children {
            if let found = findAXElement(child, match: match) {
                return found
            }
        }
    }
    return nil
}

func main() {
    let args = CommandLine.arguments
    let mode = args.count > 1 ? args[1].lowercased() : "toggle"

    // 1. Read current defaults state
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
    task.arguments = ["read", "com.apple.universalaccess", "stereoAsMono"]
    let pipe = Pipe()
    task.standardOutput = pipe
    try? task.run()
    task.waitUntilExit()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let defaultsStr = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "0"
    let curState = (defaultsStr == "1" || defaultsStr == "true") ? 1 : 0

    if mode == "status" || mode == "-s" || mode == "--status" {
        print(curState == 1 ? "mono" : "stereo")
        exit(0)
    }

    var targetState = 1
    if mode == "mono" || mode == "1" || mode == "true" || mode == "on" {
        targetState = 1
    } else if mode == "stereo" || mode == "0" || mode == "false" || mode == "off" {
        targetState = 0
    } else if mode == "toggle" {
        targetState = curState == 1 ? 0 : 1
    }

    if curState == targetState {
        if targetState == 1 {
            print("Audio is already set to mono mode.")
        } else {
            print("Audio is already set to stereo mode.")
        }
        exit(0)
    }

    // 2. Check if System Settings was running previously
    let preApps = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.systempreferences")
    let wasRunning = !preApps.isEmpty

    // 3. Open Accessibility Settings Extension
    let openTask = Process()
    openTask.executableURL = URL(fileURLWithPath: "/usr/bin/open")
    openTask.arguments = ["x-apple.systempreferences:com.apple.Accessibility-Settings.extension"]
    try? openTask.run()
    openTask.waitUntilExit()

    var sysApp: NSRunningApplication? = nil
    for _ in 0..<30 {
        let apps = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.systempreferences")
        if let a = apps.first {
            sysApp = a
            break
        }
        Thread.sleep(forTimeInterval: 0.1)
    }

    guard let app = sysApp else {
        print("Failed to launch System Settings.")
        exit(1)
    }

    let axApp = AXUIElementCreateApplication(app.processIdentifier)

    var toggled = false

    // Loop up to 5 seconds searching for Audio button or Play stereo audio as mono checkbox
    for _ in 0..<50 {
        // Check if "Play stereo audio as mono" checkbox/switch is present
        if let cb = findAXElement(axApp, match: { elem in
            let desc = getAttr(elem, kAXDescriptionAttribute)
            let title = getAttr(elem, kAXTitleAttribute)
            let role = getAttr(elem, kAXRoleAttribute)
            return (role == (kAXCheckBoxRole as String) || role == (kAXValueIndicatorRole as String) || role == (kAXButtonRole as String)) &&
                   (desc == "Play stereo audio as mono" || title == "Play stereo audio as mono")
        }) {
            // Check value
            var valRef: CFTypeRef?
            AXUIElementCopyAttributeValue(cb, kAXValueAttribute as CFString, &valRef)
            let valInt = (valRef as? Int) ?? 0
            if valInt != targetState {
                AXUIElementPerformAction(cb, kAXPressAction as CFString)
            }
            toggled = true
            break
        }

        // If checkbox not visible yet, look for "Audio" button via AXDescription or AXIdentifier
        if let audioBtn = findAXElement(axApp, match: { elem in
            let desc = getAttr(elem, kAXDescriptionAttribute)
            let id = getAttr(elem, "AXIdentifier")
            return (desc == "Audio" || id == "AX_FEATURE_AUDIO")
        }) {
            AXUIElementPerformAction(audioBtn, kAXPressAction as CFString)
            Thread.sleep(forTimeInterval: 0.1)
        }

        Thread.sleep(forTimeInterval: 0.1)
    }

    // 4. Update defaults
    let defWrite = Process()
    defWrite.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
    defWrite.arguments = ["write", "com.apple.universalaccess", "stereoAsMono", "-bool", targetState == 1 ? "true" : "false"]
    try? defWrite.run()
    defWrite.waitUntilExit()

    // 5. Clean up System Settings if we launched it fresh
    if !wasRunning {
        app.terminate()
    }

    if toggled {
        if targetState == 1 {
            print("Audio switched to mono mode.")
        } else {
            print("Audio switched to stereo mode.")
        }
    } else {
        print("Could not locate 'Play stereo audio as mono' setting in System Settings.")
        exit(1)
    }
}

main()
