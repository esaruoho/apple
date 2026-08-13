// AnchorProbe — measure whether anchoring actually works, rather than asserting it.
//
// The SDD asks for numbers and is right to: "do not claim semantic persistence
// without numbers." This answers its questions 1, 2, 3, 5 and 7 directly.
//
//   overlay-anchor-probe windows                 what the resolver can see, raw
//   overlay-anchor-probe stability <app> [secs]  does one fingerprint stay single?
//   overlay-anchor-probe ax <app>                what the AX tree offers as selectors
//   overlay-anchor-probe reacquire <app>         resolve, wait, resolve again
//
// Built as a separate executable from the same core, so measuring never depends on
// the overlay being up.

import Cocoa
import ApplicationServices

func out(_ s: String) { print(s) }

/// Swift's String(format:) %s wants a C string; padding by hand is clearer anyway.
func pad(_ s: String, _ n: Int) -> String {
    let t = String(s.prefix(n))
    return t + String(repeating: " ", count: max(0, n - t.count))
}
func padNum(_ v: Int, _ n: Int) -> String {
    let t = String(v)
    return String(repeating: " ", count: max(0, n - t.count)) + t
}

// ───────────────────────── windows ─────────────────────────

func dumpWindows() {
    let all = WindowList.onScreen()
    let usable = WindowMatcher.addressable(all, excludingOwner: "Overlay")
    out("\(all.count) on-screen, \(usable.count) addressable\n")
    out(pad("OWNER", 22) + pad("TITLE", 34) + pad("NUM", 8) + pad("LYR", 5) + "FRAME(top-left)")
    for w in all.sorted(by: { $0.layer == $1.layer ? $0.owner < $1.owner : $0.layer < $1.layer }) {
        let mark = usable.contains(w) ? " " : "·"       // · = filtered out
        let frame = "\(Int(w.frame.minX)),\(Int(w.frame.minY)) "
                  + "\(Int(w.frame.width))x\(Int(w.frame.height))"
        out(mark + pad(w.owner, 21) + pad(w.title, 34)
            + padNum(w.number, 8) + padNum(w.layer, 5) + "  " + frame)
    }
}

/// Q1: how stable is a window fingerprint during one process lifetime?
/// Q7: what happens when the target is minimised?
func stability(app: String, seconds: Int) {
    guard let first = WindowList.addressable().first(where: {
        $0.owner.lowercased().contains(app.lowercased()) }) else {
        out("no addressable window for '\(app)'"); return
    }
    let anchor = WindowMatcher.anchor(for: first)
    out("anchor for \(first.owner) — \"\(first.title)\"")
    for s in anchor.selectors {
        out("   " + pad(s.kind.rawValue, 24)
            + "weight " + String(format: "%.2f", s.weight)
            + "  restart-safe " + (s.survivesRestart ? "yes" : "no"))
    }
    out("\nsampling \(seconds)s at 4 Hz\n")

    var counts: [Int: Int] = [:]          // candidate count → how often
    var frames = Set<String>()
    var samples = 0
    let deadline = Date().addingTimeInterval(Double(seconds))
    while Date() < deadline {
        let pool = WindowList.addressable()
        let found = WindowMatcher.candidates(for: anchor, among: pool)
        counts[found.matches.count, default: 0] += 1
        if let m = found.matches.first {
            frames.insert("\(Int(m.frame.minX)),\(Int(m.frame.minY)) "
                          + "\(Int(m.frame.width))x\(Int(m.frame.height))")
        }
        samples += 1
        Thread.sleep(forTimeInterval: 0.25)
    }

    out("samples            \(samples)")
    for (n, hits) in counts.sorted(by: { $0.key < $1.key }) {
        let label = n == 0 ? "unavailable" : (n == 1 ? "resolved" : "AMBIGUOUS")
        let pct = String(format: "%5.1f", 100.0 * Double(hits) / Double(max(samples, 1)))
        out("  \(n) candidate(s)  " + padNum(hits, 4) + "  \(pct)%  → " + label)
    }
    out("distinct frames    \(frames.count)")
    let single = counts[1] ?? 0
    let stable = String(format: "%.1f", 100.0 * Double(single) / Double(max(samples, 1)))
    out("\nSTABILITY          \(stable)% of samples resolved to exactly one window")
}

/// Print an anchor for the named window, as JSON, so a driver script can keep it
/// across an application quitting and relaunching.
func emitAnchor(app: String, title: String) {
    guard let w = WindowList.addressable().first(where: {
        $0.owner.lowercased().contains(app.lowercased())
            && $0.title.caseInsensitiveCompare(title) == .orderedSame }) else {
        out("{\"error\":\"no window\"}"); return
    }
    let anchor = WindowMatcher.anchor(for: w)
    let payload: [String: Any] = [
        "expect": "\(w.owner)|\(w.title)",
        "selectors": anchor.selectors.map { sel -> [String: Any] in
            var d: [String: Any] = ["kind": sel.kind.rawValue, "weight": sel.weight]
            if let a = sel.application { d["application"] = a }
            if let t = sel.windowTitle { d["windowTitle"] = t }
            if let n = sel.windowNumber { d["windowNumber"] = n }
            if let e = sel.exact { d["exact"] = e }
            return d
        },
        "frame": [w.frame.minX, w.frame.minY, w.frame.width, w.frame.height],
    ]
    if let d = try? JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]),
       let str = String(data: d, encoding: .utf8) { out(str) }
}

/// Resolve a previously emitted anchor and score it: exact / ambiguous / missing /
/// wrong. `wrong` is the only outcome that matters — a confident match on the
/// wrong thing.
func resolveAnchor(json: String) {
    guard let data = json.data(using: .utf8),
          let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let raw = payload["selectors"] as? [[String: Any]] else {
        out("missing\tunparseable anchor"); return
    }
    let expect = payload["expect"] as? String

    let selectors = raw.compactMap { d -> AnchorSelector? in
        guard let kindRaw = d["kind"] as? String,
              let kind = AnchorSelectorKind(rawValue: kindRaw) else { return nil }
        return AnchorSelector(kind: kind,
                              application: d["application"] as? String,
                              windowTitle: d["windowTitle"] as? String,
                              windowNumber: d["windowNumber"] as? Int,
                              exact: d["exact"] as? String)
    }
    let anchor = SpatialAnchor(selectors: selectors)
    let pool = WindowList.addressable()
    let found = WindowMatcher.candidates(for: anchor, among: pool)
    let target = found.matches.first.map { "\($0.owner)|\($0.title)" }
    let resolution = Resolution.grade(candidates: found.matches.count,
                                      method: found.method, confidence: found.weight,
                                      rect: nil, surfaceEpoch: 0,
                                      t: Date().timeIntervalSince1970,
                                      targetID: target)
    let outcome = resolution.outcome(expecting: expect)
    let detail = "\(found.matches.count) candidate(s) via \(found.method.rawValue)"
              + (target.map { ", got \($0)" } ?? "")
              + (expect.map { ", expected \($0)" } ?? "")
    out("\(outcome.rawValue)\t\(detail)")
}

// ───────────────────────── accessibility ─────────────────────────

func axString(_ element: AXUIElement, _ attribute: String) -> String? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success
    else { return nil }
    return value as? String
}

func axChildren(_ element: AXUIElement) -> [AXUIElement] {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString,
                                        &value) == .success,
          let kids = value as? [AXUIElement] else { return [] }
    return kids
}

/// Q3: which AX attributes are stable enough to be selectors?
/// Q4: how different are the trees across app kinds?
func axSurvey(app: String, limit: Int = 4000) {
    guard AXIsProcessTrusted() else {
        out("NOT TRUSTED for Accessibility — grant it to whatever is running this, "
            + "then re-run. (System Settings ▸ Privacy & Security ▸ Accessibility)")
        return
    }
    // Exact name first. A substring match picked "CalendarWidgetExtension" over
    // "Calendar" and reported a one-element tree as if it were the app's — a
    // measurement artefact that would have quietly become a finding.
    let candidates = NSWorkspace.shared.runningApplications.filter {
        ($0.localizedName ?? "").lowercased().contains(app.lowercased())
    }
    guard let running = candidates.first(where: {
              ($0.localizedName ?? "").caseInsensitiveCompare(app) == .orderedSame })
            ?? candidates.first(where: { $0.activationPolicy == .regular })
            ?? candidates.first else {
        out("no running app matching '\(app)'"); return
    }
    if candidates.count > 1 {
        out("(\(candidates.count) processes matched '\(app)'; measuring "
            + "\(running.localizedName ?? "?"))")
    }
    out("\(running.localizedName ?? app)  pid \(running.processIdentifier)")

    let axApp = AXUIElementCreateApplication(running.processIdentifier)
    var visited = 0
    var byRole: [String: Int] = [:]
    var named = 0, unnamed = 0
    var addressable: [(role: String, name: String)] = []

    func walk(_ element: AXUIElement, depth: Int) {
        guard visited < limit else { return }
        visited += 1
        let role = axString(element, kAXRoleAttribute as String) ?? "?"
        byRole[role, default: 0] += 1
        let name = axString(element, kAXTitleAttribute as String)
            ?? axString(element, kAXDescriptionAttribute as String)
            ?? axString(element, kAXValueAttribute as String)
        if let name = name, !name.isEmpty {
            named += 1
            // A selector is only useful on something a person would point at.
            if ["AXButton", "AXCheckBox", "AXRadioButton", "AXMenuItem", "AXLink",
                "AXTextField", "AXPopUpButton"].contains(role) {
                addressable.append((role, name))
            }
        } else { unnamed += 1 }
        for child in axChildren(element) { walk(child, depth: depth + 1) }
    }
    walk(axApp, depth: 0)

    out("elements visited   \(visited)\(visited >= limit ? "  (hit the cap)" : "")")
    let namedPct = String(format: "%.0f", 100.0 * Double(named) / Double(max(visited, 1)))
    out("named / unnamed    \(named) / \(unnamed)  (\(namedPct)% carry a name)")
    out("distinct roles     \(byRole.count)")
    out("\ntop roles:")
    for (role, n) in byRole.sorted(by: { $0.value > $1.value }).prefix(8) {
        out("   " + pad(role, 26) + padNum(n, 5))
    }

    // Uniqueness is what actually decides whether a selector can address anything.
    var seen: [String: Int] = [:]
    for a in addressable { seen["\(a.role)|\(a.name)", default: 0] += 1 }
    let unique = seen.values.filter { $0 == 1 }.count
    out("\naddressable controls \(addressable.count)")
    let uniquePct = String(format: "%.0f", 100.0 * Double(unique) / Double(max(addressable.count, 1)))
    out("uniquely named       \(unique)  (\(uniquePct)% — the rest collide on role+name)")
    out("\nexamples:")
    for a in addressable.prefix(6) { out("   \(a.role)  \"\(a.name)\"") }
}

// ───────────────────────── entry ─────────────────────────

@main
enum AnchorProbeMain {
    static func main() {
        let args = Array(CommandLine.arguments.dropFirst())
        switch args.first {
        case "windows":
            dumpWindows()
        case "stability":
            stability(app: args.count > 1 ? args[1] : "Finder",
                      seconds: args.count > 2 ? Int(args[2]) ?? 10 : 10)
        case "ax":
            axSurvey(app: args.count > 1 ? args[1] : "Finder")
        case "anchor":
            emitAnchor(app: args.count > 1 ? args[1] : "Finder",
                       title: args.count > 2 ? args[2] : "")
        case "resolve":
            resolveAnchor(json: args.count > 1 ? args[1] : "")
        default:
            out("""
            overlay-anchor-probe — measure whether anchoring works

              windows                    every window the resolver sees, and which are filtered
              stability <app> [seconds]  does one fingerprint keep resolving to one window?
              ax <app>                   what the accessibility tree offers as selectors
              anchor <app> <title>       emit an anchor as JSON, to keep across a restart
              resolve <anchor-json>      re-resolve it and score exact/ambiguous/missing/wrong
            """)
        }
    }
}
