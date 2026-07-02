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
}

func parseArgs() -> Options {
    var o = Options()
    var it = CommandLine.arguments.dropFirst().makeIterator()
    while let a = it.next() {
        switch a {
        case "--app":          o.appName = it.next()
        case "--display":      o.displayIndex = Int(it.next() ?? "0") ?? 0
        case "--system-audio": o.systemAudio = true
        case "--also-mic", "--mic": o.alsoMic = true
        case "--fps":          o.fps = Int(it.next() ?? "60") ?? 60
        case "--out", "-o":    o.outPath = (it.next() as NSString?)?.expandingTildeInPath ?? ""
        case "--reveal":       o.reveal = true
        case "--auto-flatten": o.autoFlatten = true
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
      --also-mic, --mic      start with your microphone recording (2nd audio track)
      --fps <n>              frame rate (default 60)
      --out, -o <path>       output .mov (default: ./yyyy-MM-dd-HH-mm-ss.mov in the current folder)
      --reveal               after finalizing, reveal the file in Finder (open -R)
      --auto-flatten         if the mic was used, also emit a YouTube-ready <name>-flat.mov
                             (one track with system + mic mixed — YouTube plays only track 1)

    Press Ctrl-C to stop and finalize the file.
    Live mic toggle: send SIGUSR1 to this process — `kill -USR1 <pid>` — to turn the
    microphone on/off mid-recording (the mic goes to its own track, so muting just
    stops writing mic samples). The AppleToolbox ⌃⌥⌘M shortcut does this for you.
    """)
}

func err(_ s: String) -> Never {
    FileHandle.standardError.write((s + "\n").data(using: .utf8)!)
    exit(1)
}

// MARK: - Recorder

final class Recorder: NSObject, SCStreamOutput, SCStreamDelegate {
    var opts: Options

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
        setupWriter(width: cfg.width, height: cfg.height)

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
            let mic = self.micOn ? " + mic ON" : " (mic off)"
            FileHandle.standardError.write("● recording \(scope)\(mic) → \(self.opts.outPath)\n  Ctrl-C to stop · SIGUSR1 (kill -USR1 \(ProcessInfo.processInfo.processIdentifier)) toggles mic\n".data(using: .utf8)!)
        }

        installSignalHandler()
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

        lock.lock()
        if !sessionStarted {
            writer.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
            sessionStarted = true
        }
        lock.unlock()

        switch type {
        case .screen:
            if videoInput.isReadyForMoreMediaData { videoInput.append(sampleBuffer) }
        case .audio:
            if sysAudioInput.isReadyForMoreMediaData { sysAudioInput.append(sampleBuffer) }
        case .microphone:
            // Only write mic samples while the mic is toggled ON.
            if micOn, let mic = micInput, mic.isReadyForMoreMediaData { mic.append(sampleBuffer) }
        @unknown default:
            break
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

    var finishing = false
    func finish() {
        lock.lock(); if finishing { lock.unlock(); return }; finishing = true; lock.unlock()
        FileHandle.standardError.write("\n■ stopping…\n".data(using: .utf8)!)
        stream?.stopCapture { [weak self] _ in
            guard let self else { return }
            self.sampleQueue.async {
                self.videoInput.markAsFinished()
                self.sysAudioInput.markAsFinished()
                self.micInput?.markAsFinished()
                self.writer.finishWriting {
                    let ok = self.writer.status == .completed
                    if ok {
                        print("✓ saved \(self.opts.outPath)")
                        // If asked, and the mic was actually used, also produce a YouTube-ready
                        // single-mixed-track copy (YouTube/QuickTime play only the FIRST audio
                        // track, so a 2-track file would lose the voice). Reveal that one.
                        var revealTarget = self.opts.outPath
                        if self.opts.autoFlatten && self.micEverOn,
                           let flat = self.makeYouTubeVersion(self.opts.outPath) {
                            revealTarget = flat
                        }
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
