// screen-audio-record — Apple-native screen + system-audio recorder (ScreenCaptureKit)
//
// Records the screen AND audio straight off the system audio engine — NO microphone,
// NO loopback driver (BlackHole/Loopback), NO virtual cable. Scope the audio to a single
// application so you capture only that app's sound (e.g. Renoise), or grab all system audio.
//
// Build:  swiftc -O -o bin/screen-audio-record bin/screen-audio-record.swift \
//               -framework ScreenCaptureKit -framework AVFoundation -framework CoreMedia \
//               -framework CoreGraphics -framework AppKit
// Usage:  screen-audio-record --list
//         screen-audio-record --app Renoise --out ~/rec.mov        # screen + ONLY that app's audio
//         screen-audio-record --system-audio --out ~/rec.mov       # screen + ALL system audio
//         screen-audio-record --app Renoise --also-mic --out ~/rec.mov
//
// FEATURE-CARD >> features/screen-audio-record.feature

import Foundation
import ScreenCaptureKit
import AVFoundation
import CoreMedia
import CoreGraphics
import CoreImage
import AppKit

// MARK: - Options

struct Options {
    var appName: String?
    var displayIndex = 0
    var systemAudio = false
    var alsoMic = false
    var fps = 60
    var outPath = ""
    var list = false
    var reveal = false
    var autoFlatten = false   // after stop, if the mic was used, also emit a YouTube-ready -flat.mov
    var pip = false           // bake the webcam into a corner of the screen (picture-in-picture)
    var pipCorner = "br"      // br|bl|tr|tl
    var pipScale = 0.16       // webcam size as a fraction of the screen width (circle diameter)
    var pipShape = "circle"   // circle (default) | square
    var pipCamera: String?    // camera name substring (default: front/built-in)
    var burn = false          // after stop, transcribe + burn subtitles (one-command pipeline)
    var burnMini = false      // OPT-IN: route transcription to the Mini (default is local + reliable)
    var burnLang = "en"       // subtitle language (default English; "auto" to auto-detect)
    var burnModel: String?    // whisper model (default: rec-subtitle picks small.en / small)
    var burnPrompt: String?   // vocabulary bias → rec-subtitle --prompt → whisper --initial_prompt
    var clicks = false        // burn a live "CLICKS: n" counter into the video
    var clicksCorner = "tl"   // tl|tr|bl|br
    var clicksSeed = 0        // start the counter at n (demo / headless verification)
    var clicksLabel = "CLICKS"
}

// MARK: - Click counting without an event tap
//
// The obvious way to count clicks is a CGEventTap or an NSEvent global monitor — both of
// which need Accessibility permission and hand us every event just to increment a number.
// macOS already keeps the tally: CGEventSource.counterForEventType reports how many events
// of a type the session has seen. No tap, no TCC prompt, no event stream. We take a
// baseline when recording starts and the counter is simply the delta since.
final class ClickCounter {
    private let baseline: Int
    private let seed: Int

    init(seed: Int = 0) {
        self.seed = seed
        self.baseline = ClickCounter.sessionTotal()
    }

    static func sessionTotal() -> Int {
        let state = CGEventSourceStateID.combinedSessionState
        return [CGEventType.leftMouseDown, .rightMouseDown, .otherMouseDown]
            .reduce(0) { $0 + Int(CGEventSource.counterForEventType(state, eventType: $1)) }
    }

    /// Clicks since the recording began (left + right + middle/other).
    var count: Int { seed + max(0, ClickCounter.sessionTotal() - baseline) }
}

// MARK: - Typed handoff manifest
//
// The recorder is the pipeline's orchestrator: it alone knows every artifact it produced
// (base capture, flattened YouTube version, .srt, subtitled video) and which one is final.
// Instead of downstream consumers (RecBurn.app, a Shortcut, a Service) scraping the human
// "✓ …" prose off stdout — brittle the day the wording changes — the recorder emits a typed
// manifest: a sidecar `<base-stem>.recburn.json` AND a single sentinel stdout line
// `RECBURN-MANIFEST: <path>`. Structured data flows between actions; nobody greps prose.
struct RecBurnManifest: Codable {
    var schema = "recburn/1"
    var base: String          // the raw ScreenCaptureKit capture (always present)
    var flat: String?         // YouTube-ready single-track mix (only if --auto-flatten + mic used)
    var subtitled: String?    // hard-burned-subtitle video (only if --burn succeeded)
    var srt: String?          // soft caption sidecar (only if --burn produced one)
    var final: String         // the artifact to reveal / hand off (subtitled ?? flat ?? base)
    var lengthSeconds: Double
    var micRecorded: Bool
}

func parseArgs() -> Options {
    var o = Options()
    var it = CommandLine.arguments.dropFirst().makeIterator()
    while let a = it.next() {
        switch a {
        case "--app":          o.appName = it.next()
        case "--display":      o.displayIndex = Int(it.next() ?? "0") ?? 0
        case "--system-audio": o.systemAudio = true
        case "--clicks", "--click-counter": o.clicks = true
        case "--clicks-corner": o.clicksCorner = it.next() ?? "tl"
        case "--clicks-label":  o.clicksLabel = it.next() ?? "CLICKS"
        case "--clicks-seed":   o.clicksSeed = Int(it.next() ?? "0") ?? 0
        case "--also-mic", "--mic": o.alsoMic = true
        case "--fps":          o.fps = Int(it.next() ?? "60") ?? 60
        case "--out", "-o":    o.outPath = (it.next() as NSString?)?.expandingTildeInPath ?? ""
        case "--reveal":       o.reveal = true
        case "--auto-flatten": o.autoFlatten = true
        case "--pip", "--camera": o.pip = true
        case "--pip-corner":   o.pipCorner = it.next() ?? "br"
        case "--pip-scale":    o.pipScale = Double(it.next() ?? "0.16") ?? 0.16
        case "--pip-shape":    o.pipShape = it.next() ?? "circle"
        case "--pip-square":   o.pipShape = "square"
        case "--pip-camera":   o.pipCamera = it.next()
        case "--burn", "--burn-local": o.burn = true            // transcribe LOCALLY + burn (default)
        case "--burn-mini":    o.burn = true; o.burnMini = true // opt-in: route to the Mini
        case "--burn-lang":    o.burnLang = it.next() ?? "en"   // subtitle language (default en)
        case "--burn-model":   o.burnModel = it.next()          // whisper model (default small.en)
        case "--burn-prompt":  o.burnPrompt = it.next()         // vocabulary bias (proper nouns)
        case "--list", "-l":   o.list = true
        case "--help", "-h":   printUsage(); exit(0)
        default: FileHandle.standardError.write("unknown arg: \(a)\n".data(using: .utf8)!); exit(2)
        }
    }
    return o
}

func printUsage() {
    print("""
    screen-audio-record — screen + system-audio recorder (ScreenCaptureKit, no loopback driver)

      --list                 list displays and audible running apps, then exit
      --app <name>           capture only this app's screen windows AND its audio
      --system-audio         capture the whole display + all system audio
      --display <n>          display index from --list (default 0 = main)
      --clicks               burn a live "CLICKS: n" counter into the video (counts every
                             left/right/middle mouse-down from the moment recording starts)
      --clicks-corner <c>    tl (default) | tr | bl | br
      --clicks-label <s>     label before the number (default "CLICKS")
      --also-mic, --mic      start with your microphone recording (2nd audio track)
      --fps <n>              frame rate (default 60)
      --out, -o <path>       output .mov (default: ./yyyy-MM-dd-HH-mm-ss.mov in the current folder)
      --reveal               after finalizing, reveal the file in Finder (open -R)
      --auto-flatten         if the mic was used, also emit a YouTube-ready <name>-flat.mov
                             (one track with system + mic mixed — YouTube plays only track 1)
      --pip, --camera        bake the webcam into a corner of the recording (speaking head)
      --pip-corner <c>       br | bl | tr | tl  (default br = bottom-right)
      --pip-shape <s>        circle (default) | square       --pip-square = square
      --pip-scale <f>        webcam size as a fraction of screen width (default 0.16)
      --pip-camera <name>    camera name substring (default: built-in / front camera)
      --burn                 on stop: transcribe LOCALLY + burn subtitles → -subtitled.mov
      --burn-mini            opt-in: route transcription to the Mini (falls back to local)
      --burn-lang <code>     subtitle language (default en; "auto" to auto-detect)
      --burn-model <name>    whisper model (default small.en; e.g. medium.en, large-v3)

    Press Ctrl-C (or type q + Enter) to stop and finalize the file.
    On stop it prints the final recording length and whether the mic was recorded.
    Live mic toggle: send SIGUSR1 to this process — `kill -USR1 <pid>` — to turn the
    microphone on/off mid-recording (the mic goes to its own track, so muting just
    stops writing mic samples). The AppleToolbox ⌃⌥⌘M shortcut does this for you.
    """)
}

func err(_ s: String) -> Never {
    FileHandle.standardError.write((s + "\n").data(using: .utf8)!)
    exit(1)
}

/// Human-readable length, e.g. 5s → "0:05", 95s → "1:35", 3725s → "1:02:05".
func formatDuration(_ secs: Double) -> String {
    guard secs.isFinite, secs > 0 else { return "0:00" }
    let t = Int(secs.rounded())
    let h = t / 3600, m = (t % 3600) / 60, s = t % 60
    return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
}

// MARK: - Recorder

final class Recorder: NSObject, SCStreamOutput, SCStreamDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    var opts: Options

    // Picture-in-picture webcam compositing (--pip)
    var captureSession: AVCaptureSession?
    let cameraQueue = DispatchQueue(label: "sar.camera")
    let cameraLock = NSLock()
    var latestCameraBuffer: CVPixelBuffer?     // holding it retains the frame past the capture pool
    var ciContext: CIContext?
    var videoAdaptor: AVAssetWriterInputPixelBufferAdaptor?

    /// Default output: <current working directory>/yyyy-MM-dd-HH-mm-ss.mov —
    /// the file lands in whatever folder you ran the command from.
    static func defaultOutPath() -> String {
        let dir = FileManager.default.currentDirectoryPath
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        return (dir as NSString).appendingPathComponent(f.string(from: Date()) + ".mov")
    }
    var stream: SCStream?
    var cfg: SCStreamConfiguration!   // kept mutable so SIGUSR1 can flip captureMicrophone live
    var writer: AVAssetWriter!
    var videoInput: AVAssetWriterInput!
    var sysAudioInput: AVAssetWriterInput!
    var micInput: AVAssetWriterInput?
    var micOn = false                 // whether mic samples are currently being written
    var micEverOn = false             // did the mic capture ANY audio this session? (gates auto-flatten)
    var sessionStarted = false
    var firstPTS: CMTime?             // first & last video timestamps → final recording length
    var lastPTS: CMTime = .zero
    let lock = NSLock()
    let sampleQueue = DispatchQueue(label: "sar.samples")

    init(_ o: Options) { self.opts = o }

    func run() {
        SCShareableContent.getExcludingDesktopWindows(false, onScreenWindowsOnly: false) { [weak self] content, error in
            guard let self else { return }
            if let error { err("shareable content: \(error.localizedDescription)") }
            guard let content else { err("no shareable content") }
            if self.opts.list { self.listContent(content); exit(0) }
            self.start(content)
        }
        // Deliver SCK callbacks + keep process alive until Ctrl-C.
        dispatchMain()
    }

    func listContent(_ c: SCShareableContent) {
        print("DISPLAYS:")
        for (i, d) in c.displays.enumerated() {
            print("  [\(i)] \(d.width)x\(d.height)  id=\(d.displayID)")
        }
        print("\nAUDIBLE / RUNNING APPS (use --app <name>):")
        let apps = c.applications
            .filter { !$0.applicationName.isEmpty }
            .sorted { $0.applicationName.lowercased() < $1.applicationName.lowercased() }
        var seen = Set<String>()
        for a in apps where seen.insert(a.applicationName).inserted {
            print("  \(a.applicationName)  (\(a.bundleIdentifier))")
        }
    }

    func start(_ content: SCShareableContent) {
        if opts.outPath.isEmpty { opts.outPath = Recorder.defaultOutPath() }
        guard opts.displayIndex < content.displays.count else { err("no display at index \(opts.displayIndex)") }
        let display = content.displays[opts.displayIndex]

        // Build the content filter — app-scoped (screen + that app's audio) or whole-display.
        let filter: SCContentFilter
        if let name = opts.appName {
            let matches = content.applications.filter {
                $0.applicationName.caseInsensitiveCompare(name) == .orderedSame ||
                $0.bundleIdentifier.caseInsensitiveCompare(name) == .orderedSame ||
                $0.applicationName.range(of: name, options: .caseInsensitive) != nil
            }
            guard !matches.isEmpty else { err("no running app matches \"\(name)\" — try --list") }
            filter = SCContentFilter(display: display, including: matches, exceptingWindows: [])
        } else if opts.systemAudio {
            filter = SCContentFilter(display: display, excludingWindows: [])
        } else {
            err("choose --app <name> (single-app audio) or --system-audio (all audio)")
        }

        // Resolution: use the display's pixel dimensions for a crisp capture.
        let scale = NSScreen.screens.first { $0.deviceDescription[.init("NSScreenNumber")] as? CGDirectDisplayID == display.displayID }?.backingScaleFactor ?? 2.0
        let px = { (pts: Int) in Int(Double(pts) * Double(scale)) }

        let cfg = SCStreamConfiguration()
        cfg.width = px(display.width)
        cfg.height = px(display.height)
        cfg.minimumFrameInterval = CMTime(value: 1, timescale: CMTimeScale(opts.fps))
        cfg.showsCursor = true
        cfg.queueDepth = 6
        cfg.capturesAudio = true
        cfg.sampleRate = 48_000
        cfg.channelCount = 2
        cfg.excludesCurrentProcessAudio = true
        // macOS 15+ native mic capture (no AVCaptureSession). Start on/off per --mic;
        // SIGUSR1 flips it live via updateConfiguration().
        micOn = opts.alsoMic
        micEverOn = opts.alsoMic
        cfg.captureMicrophone = micOn
        self.cfg = cfg

        // The mic ALWAYS gets its own track + stream output, even if it starts muted,
        // so a live SIGUSR1 toggle can turn it on later without rebuilding the writer.
        if opts.clicks { clickCounter = ClickCounter(seed: opts.clicksSeed) }
        setupWriter(width: cfg.width, height: cfg.height)
        if opts.pip { _ = setupCamera() }

        let s = SCStream(filter: filter, configuration: cfg, delegate: self)
        do {
            try s.addStreamOutput(self, type: .screen, sampleHandlerQueue: sampleQueue)
            try s.addStreamOutput(self, type: .audio, sampleHandlerQueue: sampleQueue)
            try s.addStreamOutput(self, type: .microphone, sampleHandlerQueue: sampleQueue)
        } catch { err("addStreamOutput: \(error.localizedDescription)") }
        self.stream = s

        s.startCapture { [weak self] error in
            if let error { err("startCapture: \(error.localizedDescription)") }
            guard let self else { return }
            let scope = self.opts.appName.map { "app \"\($0)\"" } ?? "whole display + all system audio"
            let pid = ProcessInfo.processInfo.processIdentifier
            let micLine = self.micOn
                ? "🎤 microphone: ON — your voice IS being recorded (own track)"
                : "🎤 microphone: off — system audio only (kill -USR1 \(pid) to turn on)"
            FileHandle.standardError.write("""
            ● recording \(scope) → \(self.opts.outPath)
            \(micLine)
              stop & finalize: Ctrl-C  (or type q + Enter)   ·   toggle mic: kill -USR1 \(pid)

            """.data(using: .utf8)!)
        }

        installSignalHandler()
        installQuitWatcher()
    }

    func setupWriter(width: Int, height: Int) {
        let url = URL(fileURLWithPath: opts.outPath)
        try? FileManager.default.removeItem(at: url)
        do { writer = try AVAssetWriter(outputURL: url, fileType: .mov) }
        catch { err("AVAssetWriter: \(error.localizedDescription)") }

        let vSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
        ]
        videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: vSettings)
        videoInput.expectsMediaDataInRealTime = true
        writer.add(videoInput)

        // Any compositing — the webcam corner, the click counter, or both — means we
        // build each output frame ourselves and feed the video input through a
        // pixel-buffer adaptor instead of passing raw screen sample buffers straight in.
        if opts.pip || opts.clicks {
            let attrs: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
                kCVPixelBufferWidthKey as String: width,
                kCVPixelBufferHeightKey as String: height,
            ]
            videoAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput,
                                                                sourcePixelBufferAttributes: attrs)
            ciContext = CIContext(options: [.cacheIntermediates: false])
        }

        let aSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey: 2,
            AVSampleRateKey: 48_000,
            AVEncoderBitRateKey: 128_000,
        ]
        sysAudioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: aSettings)
        sysAudioInput.expectsMediaDataInRealTime = true
        writer.add(sysAudioInput)

        // Mic track always exists so live-enabling the mic mid-recording has somewhere
        // to write. If the mic is never turned on, this track simply receives no samples.
        let m = AVAssetWriterInput(mediaType: .audio, outputSettings: aSettings)
        m.expectsMediaDataInRealTime = true
        writer.add(m)
        micInput = m

        guard writer.startWriting() else {
            err("startWriting failed: \(writer.error?.localizedDescription ?? "unknown")")
        }
    }

    // SCStreamOutput
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard CMSampleBufferDataIsReady(sampleBuffer) else { return }

        if type == .screen {
            guard let attach = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false) as? [[SCStreamFrameInfo: Any]],
                  let raw = attach.first?[.status] as? Int,
                  let status = SCFrameStatus(rawValue: raw), status == .complete else { return }
        }

        let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        lock.lock()
        if !sessionStarted {
            writer.startSession(atSourceTime: pts)
            sessionStarted = true
        }
        lock.unlock()

        // Track the video timeline so we can report the final recording length on stop.
        if type == .screen {
            if firstPTS == nil { firstPTS = pts }
            lastPTS = pts
        }

        switch type {
        case .screen:
            if opts.pip || opts.clicks, let px = CMSampleBufferGetImageBuffer(sampleBuffer) {
                compositeFrame(screen: px, pts: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
            } else if videoInput.isReadyForMoreMediaData {
                videoInput.append(sampleBuffer)
            }
        case .audio:
            if sysAudioInput.isReadyForMoreMediaData { sysAudioInput.append(sampleBuffer) }
        case .microphone:
            // Only write mic samples while the mic is toggled ON.
            if micOn, let mic = micInput, mic.isReadyForMoreMediaData { mic.append(sampleBuffer) }
        @unknown default:
            break
        }
    }

    // AVCaptureVideoDataOutputSampleBufferDelegate — keep the latest webcam frame.
    // Holding the CVPixelBuffer retains it past the capture pool's recycling.
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let px = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        cameraLock.lock(); latestCameraBuffer = px; cameraLock.unlock()
    }

    // Re-rendering the text every frame would be wasteful and would shimmer; the badge
    // only changes when the number does, so cache it by (count, width).
    var clickCounter: ClickCounter?
    private var badgeCache: (n: Int, w: CGFloat, img: CIImage)?

    /// "CLICKS: 12" as a rounded dark plate with white monospaced-digit text. Monospaced
    /// digits matter: proportional ones make the badge jitter as the number changes.
    func clickBadge(_ n: Int, baseW: CGFloat) -> CIImage? {
        if let c = badgeCache, c.n == n, c.w == baseW { return c.img }
        let fontSize = max(18, baseW * 0.022)
        let text = "\(opts.clicksLabel): \(n)"
        let font = NSFont.monospacedDigitSystemFont(ofSize: fontSize, weight: .bold)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.white]
        let str = NSAttributedString(string: text, attributes: attrs)
        let tSize = str.size()
        let padX = fontSize * 0.62, padY = fontSize * 0.34
        let w = Int(ceil(tSize.width + padX * 2)), h = Int(ceil(tSize.height + padY * 2))
        guard w > 0, h > 0,
              let cg = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                                 space: CGColorSpaceCreateDeviceRGB(),
                                 bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }
        let nsCtx = NSGraphicsContext(cgContext: cg, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = nsCtx
        let plate = NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: CGFloat(w), height: CGFloat(h)),
                                 xRadius: fontSize * 0.35, yRadius: fontSize * 0.35)
        NSColor(calibratedWhite: 0, alpha: 0.66).setFill()
        plate.fill()
        str.draw(at: NSPoint(x: padX, y: padY))
        NSGraphicsContext.restoreGraphicsState()
        guard let img = cg.makeImage() else { return nil }
        let ci = CIImage(cgImage: img)
        badgeCache = (n, baseW, ci)
        return ci
    }

    /// Build one output frame: the screen, plus the webcam corner (--pip) and/or the live
    /// click counter (--clicks), and append it. If an overlay can't be produced the screen
    /// frame is appended unchanged — a recording is never lost to a decoration.
    func compositeFrame(screen: CVPixelBuffer, pts: CMTime) {
        guard let adaptor = videoAdaptor, let ctx = ciContext,
              adaptor.assetWriterInput.isReadyForMoreMediaData else { return }
        guard let pool = adaptor.pixelBufferPool else {
            if videoInput.isReadyForMoreMediaData { adaptor.append(screen, withPresentationTime: pts) }
            return
        }
        var outBuf: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(nil, pool, &outBuf)
        guard let dst = outBuf else { adaptor.append(screen, withPresentationTime: pts); return }

        var image = CIImage(cvPixelBuffer: screen)
        let baseW = CGFloat(CVPixelBufferGetWidth(screen))
        let baseH = CGFloat(CVPixelBufferGetHeight(screen))

        cameraLock.lock(); let cam = latestCameraBuffer; cameraLock.unlock()
        if let cam = cam {
            let camImg = CIImage(cvPixelBuffer: cam)
            let ext = camImg.extent
            if ext.width > 0 && ext.height > 0 {
                let margin = baseW * 0.025
                let overlay: CIImage, ow: CGFloat, oh: CGFloat
                if opts.pipShape == "square" {
                    let targetW = baseW * CGFloat(opts.pipScale)
                    let s = targetW / ext.width
                    overlay = camImg.transformed(by: CGAffineTransform(scaleX: s, y: s))
                        .transformed(by: CGAffineTransform(translationX: -ext.origin.x * s, y: -ext.origin.y * s))
                    ow = targetW; oh = ext.height * s
                } else {
                    // Circle (default): center-crop the camera to a square, scale to the target
                    // diameter, then mask to a circle so it takes far less space than a rectangle.
                    let side = min(ext.width, ext.height)
                    let d = baseW * CGFloat(opts.pipScale)
                    let s = d / side
                    let sq = camImg
                        .cropped(to: CGRect(x: ext.midX - side / 2, y: ext.midY - side / 2, width: side, height: side))
                        .transformed(by: CGAffineTransform(translationX: -(ext.midX - side / 2), y: -(ext.midY - side / 2)))
                        .transformed(by: CGAffineTransform(scaleX: s, y: s))
                    let mask = CIFilter(name: "CIRadialGradient", parameters: [
                        "inputCenter": CIVector(x: d / 2, y: d / 2),
                        "inputRadius0": d / 2 - 2, "inputRadius1": d / 2,
                        "inputColor0": CIColor(red: 1, green: 1, blue: 1, alpha: 1),
                        "inputColor1": CIColor(red: 0, green: 0, blue: 0, alpha: 0),
                    ])?.outputImage?.cropped(to: CGRect(x: 0, y: 0, width: d, height: d)) ?? CIImage.empty()
                    overlay = sq.applyingFilter("CIBlendWithMask", parameters: [
                        kCIInputBackgroundImageKey: CIImage.empty(),
                        kCIInputMaskImageKey: mask,
                    ])
                    ow = d; oh = d
                }
                let x: CGFloat, y: CGFloat   // CIImage origin is bottom-left
                switch opts.pipCorner {
                case "bl": x = margin;              y = margin
                case "tl": x = margin;              y = baseH - oh - margin
                case "tr": x = baseW - ow - margin; y = baseH - oh - margin
                default:   x = baseW - ow - margin; y = margin   // br
                }
                image = overlay.transformed(by: CGAffineTransform(translationX: x, y: y)).composited(over: image)
            }
        }

        // "CLICKS: 12" burned into the frame, so the count is IN the video rather than
        // something the viewer has to be told afterwards.
        if let counter = clickCounter, let badge = clickBadge(counter.count, baseW: baseW) {
            let margin = baseW * 0.025
            let bw = badge.extent.width, bh = badge.extent.height
            let x: CGFloat, y: CGFloat   // CIImage origin is bottom-left
            switch opts.clicksCorner {
            case "bl": x = margin;              y = margin
            case "br": x = baseW - bw - margin; y = margin
            case "tr": x = baseW - bw - margin; y = baseH - bh - margin
            default:   x = margin;              y = baseH - bh - margin   // tl
            }
            image = badge.transformed(by: CGAffineTransform(translationX: x, y: y)).composited(over: image)
        }

        ctx.render(image, to: dst)
        adaptor.append(dst, withPresentationTime: pts)
    }

    /// Start webcam capture for PiP. Returns false (and records screen-only) if no camera
    /// or access is denied — never aborts the recording.
    func setupCamera() -> Bool {
        // Ask for camera access up front (blocks briefly on first run for the TCC prompt).
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .notDetermined {
            let sem = DispatchSemaphore(value: 0)
            AVCaptureDevice.requestAccess(for: .video) { _ in sem.signal() }
            sem.wait()
        }
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
            FileHandle.standardError.write("PiP: camera access not granted — recording without webcam\n".data(using: .utf8)!)
            return false
        }
        let device: AVCaptureDevice?
        if let name = opts.pipCamera {
            let types: [AVCaptureDevice.DeviceType] = [.builtInWideAngleCamera, .external, .continuityCamera]
            device = AVCaptureDevice.DiscoverySession(deviceTypes: types, mediaType: .video, position: .unspecified)
                .devices.first { $0.localizedName.range(of: name, options: .caseInsensitive) != nil }
        } else {
            device = AVCaptureDevice.default(for: .video)
        }
        guard let device else {
            FileHandle.standardError.write("PiP: no camera found — recording without webcam\n".data(using: .utf8)!)
            return false
        }
        let session = AVCaptureSession()
        session.sessionPreset = .high
        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else { return false }
            session.addInput(input)
            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
            output.alwaysDiscardsLateVideoFrames = true
            output.setSampleBufferDelegate(self, queue: cameraQueue)
            guard session.canAddOutput(output) else { return false }
            session.addOutput(output)
            session.startRunning()
            captureSession = session
            FileHandle.standardError.write("🎥 webcam PiP: \(device.localizedName) (\(opts.pipCorner))\n".data(using: .utf8)!)
            return true
        } catch {
            FileHandle.standardError.write("PiP: camera error \(error.localizedDescription) — recording without webcam\n".data(using: .utf8)!)
            return false
        }
    }

    func stream(_ stream: SCStream, didStopWithError error: Error) {
        FileHandle.standardError.write("stream stopped: \(error.localizedDescription)\n".data(using: .utf8)!)
        finish()
    }

    // Ctrl-C → clean stop + finalize.  SIGUSR1 → toggle mic on/off live.
    func installSignalHandler() {
        signal(SIGINT, SIG_IGN)
        let intSrc = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        intSrc.setEventHandler { [weak self] in self?.finish() }
        intSrc.resume()
        objc_setAssociatedObject(self, "sigint", intSrc, .OBJC_ASSOCIATION_RETAIN)

        signal(SIGUSR1, SIG_IGN)
        let micSrc = DispatchSource.makeSignalSource(signal: SIGUSR1, queue: .main)
        micSrc.setEventHandler { [weak self] in self?.toggleMic() }
        micSrc.resume()
        objc_setAssociatedObject(self, "sigusr1", micSrc, .OBJC_ASSOCIATION_RETAIN)
    }

    /// Allow `q` + Enter as a friendly alternative to Ctrl-C. Reads stdin on a background
    /// thread; on EOF (stdin not a TTY, e.g. launched by AppleToolbox) it simply exits the
    /// loop and leaves Ctrl-C / SIGUSR1 as the controls.
    func installQuitWatcher() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            while let line = readLine(strippingNewline: true) {
                let c = line.trimmingCharacters(in: .whitespaces).lowercased()
                if c == "q" || c == "quit" || c == "stop" {
                    DispatchQueue.main.async { self?.finish() }
                    return
                }
            }
        }
    }

    /// Flip the mic between ON and OFF mid-recording. The append gate (micOn) is the
    /// source of truth for what lands in the file; updateConfiguration() also starts/stops
    /// the actual mic hardware capture so "off" means the mic is truly not listening.
    func toggleMic() {
        micOn.toggle()
        if micOn { micEverOn = true }
        cfg.captureMicrophone = micOn
        let now = micOn
        if let s = stream {
            Task {
                do { try await s.updateConfiguration(cfg) }
                catch { NSLog("updateConfiguration(mic=\(now)) failed: \(error.localizedDescription)") }
            }
        }
        FileHandle.standardError.write("🎤 mic \(micOn ? "ON" : "OFF")\n".data(using: .utf8)!)
    }

    /// Run `rec-audio flatten` (found alongside this binary) to mix system+mic into one
    /// track → <stem>-flat.mov. Blocks until done (we're on the way to exit anyway).
    /// Returns the flattened path on success, nil otherwise.
    func makeYouTubeVersion(_ inPath: String) -> String? {
        guard let exeDir = Bundle.main.executableURL?.deletingLastPathComponent() else { return nil }
        let recAudio = exeDir.appendingPathComponent("rec-audio").path
        guard FileManager.default.fileExists(atPath: recAudio) else {
            FileHandle.standardError.write("auto-flatten: rec-audio not found next to the recorder — skipping YouTube version\n".data(using: .utf8)!)
            return nil
        }
        let flatPath = (inPath as NSString).deletingPathExtension + "-flat.mov"
        FileHandle.standardError.write("⧉ making YouTube version (system + mic mixed) → \((flatPath as NSString).lastPathComponent) …\n".data(using: .utf8)!)
        let p = Process()
        p.launchPath = recAudio
        p.arguments = ["flatten", inPath, "-o", flatPath]
        do { try p.run() } catch {
            FileHandle.standardError.write("auto-flatten failed to launch: \(error.localizedDescription)\n".data(using: .utf8)!)
            return nil
        }
        p.waitUntilExit()
        if p.terminationStatus == 0 {
            print("✓ YouTube version: \(flatPath)")
            return flatPath
        }
        FileHandle.standardError.write("auto-flatten: rec-audio exited \(p.terminationStatus)\n".data(using: .utf8)!)
        return nil
    }

    /// Run `rec-subtitle --burn` (found alongside this binary) on the finished video to
    /// transcribe + hard-burn subtitles. Transcription routes to the Mini unless --burn-local.
    /// Blocks (transcription can take minutes). Returns the -subtitled.mov path on success.
    func makeSubtitledVersion(_ inPath: String) -> String? {
        guard let exeDir = Bundle.main.executableURL?.deletingLastPathComponent() else { return nil }
        let tool = exeDir.appendingPathComponent("rec-subtitle").path
        guard FileManager.default.fileExists(atPath: tool) else {
            FileHandle.standardError.write("--burn: rec-subtitle not found next to the recorder — skipping\n".data(using: .utf8)!)
            return nil
        }
        FileHandle.standardError.write("⧉ transcribing + burning subtitles (\(opts.burnMini ? "via the Mini" : "locally")) — this can take a minute…\n".data(using: .utf8)!)
        let p = Process()
        p.launchPath = tool
        var a = [inPath, "--burn", "--lang", opts.burnLang]
        if let m = opts.burnModel { a += ["--model", m] }
        if let pr = opts.burnPrompt { a += ["--prompt", pr] }
        if opts.burnMini { a.append("--mini") }
        p.arguments = a
        do { try p.run() } catch {
            FileHandle.standardError.write("--burn failed to launch rec-subtitle: \(error.localizedDescription)\n".data(using: .utf8)!)
            return nil
        }
        p.waitUntilExit()
        let subbed = (inPath as NSString).deletingPathExtension + "-subtitled.mov"
        if p.terminationStatus == 0 && FileManager.default.fileExists(atPath: subbed) {
            print("✓ subtitled: \(subbed)")
            return subbed
        }
        FileHandle.standardError.write("--burn: rec-subtitle exited \(p.terminationStatus)\n".data(using: .utf8)!)
        return nil
    }

    /// Write the typed handoff: a `<base-stem>.recburn.json` sidecar (durable, re-readable by
    /// any consumer — the app, a Shortcut, a Service) plus one sentinel stdout line pointing at
    /// it. This replaces stdout-prose scraping as the machine-readable result of the pipeline.
    func writeManifest(_ m: RecBurnManifest) {
        let path = (m.base as NSString).deletingPathExtension + ".recburn.json"
        let enc = JSONEncoder(); enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? enc.encode(m) else { return }
        do {
            try data.write(to: URL(fileURLWithPath: path))
            print("RECBURN-MANIFEST: \(path)")
        } catch {
            FileHandle.standardError.write("manifest: could not write \(path): \(error.localizedDescription)\n".data(using: .utf8)!)
        }
    }

    var finishing = false
    func finish() {
        lock.lock(); if finishing { lock.unlock(); return }; finishing = true; lock.unlock()
        FileHandle.standardError.write("\n■ stopping…\n".data(using: .utf8)!)
        captureSession?.stopRunning()
        stream?.stopCapture { [weak self] _ in
            guard let self else { return }
            self.sampleQueue.async {
                self.videoInput.markAsFinished()
                self.sysAudioInput.markAsFinished()
                self.micInput?.markAsFinished()
                self.writer.finishWriting {
                    let ok = self.writer.status == .completed
                    if ok {
                        let secs = self.firstPTS != nil ? CMTimeGetSeconds(self.lastPTS - self.firstPTS!) : 0
                        let micNote = self.micEverOn ? " · mic recorded" : ""
                        print("✓ saved \(self.opts.outPath)  ·  length \(formatDuration(secs))\(micNote)")
                        // If asked, and the mic was actually used, also produce a YouTube-ready
                        // single-mixed-track copy (YouTube/QuickTime play only the FIRST audio
                        // track, so a 2-track file would lose the voice). Reveal that one.
                        var revealTarget = self.opts.outPath
                        var flatOut: String?, subOut: String?, srtOut: String?
                        if self.opts.autoFlatten && self.micEverOn,
                           let flat = self.makeYouTubeVersion(self.opts.outPath) {
                            revealTarget = flat; flatOut = flat
                        }
                        if self.opts.burn {
                            let subInput = revealTarget   // rec-subtitle names the .srt off THIS stem
                            if let subbed = self.makeSubtitledVersion(subInput) {
                                subOut = subbed; revealTarget = subbed
                                let srt = (subInput as NSString).deletingPathExtension + ".srt"
                                if FileManager.default.fileExists(atPath: srt) { srtOut = srt }
                            }
                        }
                        // Emit the typed handoff so consumers never parse the prose above.
                        self.writeManifest(RecBurnManifest(
                            base: self.opts.outPath, flat: flatOut, subtitled: subOut, srt: srtOut,
                            final: revealTarget, lengthSeconds: secs, micRecorded: self.micEverOn))
                        if self.opts.reveal {
                            let p = Process()
                            p.launchPath = "/usr/bin/open"
                            p.arguments = ["-R", revealTarget]
                            try? p.run()
                            p.waitUntilExit()
                        }
                    } else {
                        FileHandle.standardError.write("write failed: \(self.writer.error?.localizedDescription ?? "unknown")\n".data(using: .utf8)!)
                    }
                    exit(ok ? 0 : 1)
                }
            }
        }
    }
}

// MARK: - main

let opts = parseArgs()
let recorder = Recorder(opts)   // global — must outlive the async SCK callbacks
recorder.run()
