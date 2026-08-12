// image-create — generate an image with Apple's on-device Image Playground.
//
// Apple-native, no Homebrew / pip / Node. Uses the ImagePlayground framework's
// programmatic ImageCreator API (macOS 15.4+). At RUNTIME it needs an Apple
// Silicon Mac with Apple Intelligence enabled and the Image Playground model
// downloaded (Settings ▸ Apple Intelligence & Siri). It is the local-laptop
// counterpart to `fm` (FoundationModels prose): prose can live on the Mini,
// pictures can render right here.
//
// Usage:
//   image-create "a tiger" -o tiger.png            generate one image
//   image-create "a tiger" --style illustration    pick a style
//   image-create --check                            report availability + styles
//   image-create "a tiger" -o out.png --limit 1     how many to try (keeps best)
//
// Styles: animation (default), illustration, sketch — whatever this Mac reports
// as available. `--check` prints the real list for this machine.
//
// FEATURE-CARD >> features/image-playground.feature

import Foundation
import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

#if canImport(ImagePlayground)
import ImagePlayground
#endif

// Image Playground refuses to render when its host process is "hidden or
// running in the background." A plain CLI has activation policy .prohibited and
// no window, so generation fails even with .regular + activate. The API needs a
// genuinely foregrounded app with a visible window. We give it exactly that: a
// tiny on-screen window, a full NSApp run loop, generate in didFinishLaunching,
// then terminate. The window flashes briefly — the cost of Apple's foreground
// requirement for a CLI. (Inside Converse there's already a window, so this
// dance isn't needed there.)
final class GenDelegate: NSObject, NSApplicationDelegate {
    let body: (@escaping () -> Void) -> Void   // (done) -> begin async work
    var window: NSWindow?
    init(_ body: @escaping (@escaping () -> Void) -> Void) { self.body = body }

    func applicationDidFinishLaunching(_ n: Notification) {
        // The window has to EXIST and be on screen for ImageCreator to run, but
        // nothing says it has to be seen. A titled 240x80 panel flashed up in the
        // middle of the display on every generation, which is intolerable when the
        // overlay is meant to render a sketch in place. So: 1x1, borderless, almost
        // transparent, parked in a corner. Not zero alpha — a fully transparent
        // window can read as not-visible and the API refuses again.
        let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1, height: 1),
                         styleMask: [.borderless], backing: .buffered, defer: false)
        w.alphaValue = 0.02
        w.level = .normal
        w.ignoresMouseEvents = true
        w.setFrameOrigin(NSPoint(x: 0, y: 0))
        w.makeKeyAndOrderFront(nil)
        window = w
        NSApp.activate(ignoringOtherApps: true)
        body { DispatchQueue.main.async { NSApp.terminate(nil) } }
    }
}

// ── arg parsing (stdlib only) ────────────────────────────────────────────────
var args = Array(CommandLine.arguments.dropFirst())
func popValue(_ flags: [String]) -> String? {
    for f in flags {
        if let i = args.firstIndex(of: f), i + 1 < args.count {
            let v = args[i + 1]; args.removeSubrange(i...(i + 1)); return v
        }
    }
    return nil
}
// When driven by the `image-create` CLI through `open` (which detaches stdio),
// the app can't talk back on stdout/stderr. So the wrapper passes a result file
// and we redirect both streams into it; the wrapper reads it afterwards.
if let rf = popValue(["--result-file"]) {
    let p = (rf as NSString).expandingTildeInPath
    freopen(p, "w", stdout)
    freopen(p, "w", stderr)
    setbuf(stdout, nil); setbuf(stderr, nil)
}
let checkOnly = args.contains("--check"); args.removeAll { $0 == "--check" }
let styleName = popValue(["--style", "-s"])
let outPath   = popValue(["--output", "-o"])
// A sketch to build from: the drawing IS the subject, not a description
// of it. ImagePlaygroundConcept.image(CGImage) is the documented route.
let fromImagePath = popValue(["--from-image"])
let limitStr  = popValue(["--limit", "-n"])
let limit     = max(1, Int(limitStr ?? "1") ?? 1)
// The on-device generator intermittently throws a vague "The image creation
// failed." for the SAME prompt — it's transient, not (always) a content block.
// Retry a few times before giving up. Override with --retries N.
let retries   = max(1, Int(popValue(["--retries"]) ?? "8") ?? 8)
let prompt = args.filter { !$0.hasPrefix("-") }.joined(separator: " ")
    .trimmingCharacters(in: .whitespacesAndNewlines)

func die(_ msg: String, _ code: Int32 = 1) -> Never {
    FileHandle.standardError.write(Data((msg + "\n").utf8)); exit(code)
}

func writePNG(_ cg: CGImage, to path: String) throws {
    let url = URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
    guard let dest = CGImageDestinationCreateWithURL(
        url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        throw NSError(domain: "image-create", code: 10,
                      userInfo: [NSLocalizedDescriptionKey: "cannot create PNG at \(path)"])
    }
    CGImageDestinationAddImage(dest, cg, nil)
    guard CGImageDestinationFinalize(dest) else {
        throw NSError(domain: "image-create", code: 11,
                      userInfo: [NSLocalizedDescriptionKey: "failed to write PNG"])
    }
}

#if canImport(ImagePlayground)
@available(macOS 15.4, *)
func styleFor(_ name: String?, available: [ImagePlaygroundStyle]) -> ImagePlaygroundStyle {
    guard let name = name?.lowercased() else { return available.first ?? .animation }
    // Match on the style's id/description; fall back to first available.
    if let hit = available.first(where: {
        "\($0)".lowercased().contains(name) || "\($0.id)".lowercased().contains(name)
    }) { return hit }
    FileHandle.standardError.write(Data(
        "image-create: style '\(name)' not available; using \(available.first.map { "\($0)" } ?? "default")\n".utf8))
    return available.first ?? .animation
}

@available(macOS 15.4, *)
func run() async {
    let creator: ImageCreator
    do {
        creator = try await ImageCreator()
    } catch {
        die("image-create: Image Playground unavailable — \(error.localizedDescription)\n" +
            "Enable Apple Intelligence and download the Image Playground model " +
            "(Settings ▸ Apple Intelligence & Siri), then retry.", 3)
    }
    let available = creator.availableStyles

    if checkOnly {
        print("available")
        print("styles: " + available.map { "\($0)" }.joined(separator: ", "))
        exit(0)
    }
    guard !prompt.isEmpty || fromImagePath != nil else {
        die("usage: image-create \"a tiger\" -o tiger.png   ·   " +
            "image-create --from-image sketch.png -o out.png   ·   image-create --check", 2)
    }

    let style = styleFor(styleName, available: available)
    let out = outPath ?? "image-create-output.png"

    var lastError: Error?
    for attempt in 1...retries {
        do {
            // Concepts, in the order Image Playground should weigh them. A sketch
            // supplied with --from-image is THE subject: the user drew a cube and
            // wants a cube, not a picture of the words "a cube".
            var concepts: [ImagePlaygroundConcept] = []
            if let sketch = fromImagePath {
                guard let src = CGImageSourceCreateWithURL(
                        URL(fileURLWithPath: sketch) as CFURL, nil),
                      let cg = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
                    die("image-create: cannot read --from-image \(sketch)", 2)
                }
                concepts.append(.image(cg))
            }
            if !prompt.isEmpty { concepts.append(.text(prompt)) }
            let stream = creator.images(for: concepts, style: style, limit: limit)
            var saved = 0
            for try await created in stream {
                let path = saved == 0 ? out : numbered(out, saved)
                try writePNG(created.cgImage, to: path)
                print(path)
                saved += 1
            }
            if saved > 0 { return }       // success
            lastError = nil
        } catch {
            let s = "\(error) \(error.localizedDescription)".lowercased()
            // A foreground/availability error won't fix itself on retry — fail fast.
            if s.contains("background") || s.contains("hidden") {
                die("image-create: bring the app to the front — Image Playground won't render in the background.", 1)
            }
            lastError = error
            if attempt < retries {
                FileHandle.standardError.write(Data(
                    "image-create: attempt \(attempt)/\(retries) failed — retrying…\n".utf8))
                // brief backoff; the generator often succeeds on the next try
                try? await Task.sleep(nanoseconds: UInt64(attempt) * 600_000_000)
            }
        }
    }
    // All attempts exhausted. The message is identical for a transient hiccup and
    // a content-policy block, so we can't tell them apart — say both, honestly.
    let raw = lastError?.localizedDescription ?? "no image was produced"
    die("image-create: failed after \(retries) attempts — \(raw)\n" +
        "  This is usually a transient on-device hiccup (just run it again). If it\n" +
        "  fails every time, Apple's content filter may be blocking a word — rephrase.", 1)
}

func numbered(_ path: String, _ i: Int) -> String {
    let ns = path as NSString
    let ext = ns.pathExtension
    let base = ns.deletingPathExtension
    return ext.isEmpty ? "\(base)-\(i)" : "\(base)-\(i).\(ext)"
}
#endif

// ── entry ────────────────────────────────────────────────────────────────────
#if canImport(ImagePlayground)
if #available(macOS 15.4, *) {
    if checkOnly {
        // Availability/styles need no window — run inline.
        let sem = DispatchSemaphore(value: 0)
        Task { await run(); sem.signal() }
        sem.wait()
    } else {
        // Generation needs a foreground app + window. Drive it from the run loop.
        let app = NSApplication.shared
        let delegate = GenDelegate { done in
            Task { await run(); done() }
        }
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        app.run()
    }
} else {
    die("image-create: requires macOS 15.4+ (Image Playground / ImageCreator API)", 3)
}
#else
die("image-create: this SDK has no ImagePlayground framework — build on macOS 15.4+", 3)
#endif
