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
}

func parseArgs() -> Options {
    var o = Options()
    var it = CommandLine.arguments.dropFirst().makeIterator()
    while let a = it.next() {
        switch a {
        case "--app":          o.appName = it.next()
        case "--display":      o.displayIndex = Int(it.next() ?? "0") ?? 0
        case "--system-audio": o.systemAudio = true
        case "--also-mic":     o.alsoMic = true
        case "--fps":          o.fps = Int(it.next() ?? "60") ?? 60
        case "--out", "-o":    o.outPath = (it.next() as NSString?)?.expandingTildeInPath ?? ""
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
      --also-mic             add your microphone as a second audio track
      --fps <n>              frame rate (default 60)
      --out, -o <path>       output .mov (required unless --list)

    Press Ctrl-C to stop and finalize the file.
    """)
}

func err(_ s: String) -> Never {
    FileHandle.standardError.write((s + "\n").data(using: .utf8)!)
    exit(1)
}

// MARK: - Recorder

final class Recorder: NSObject, SCStreamOutput, SCStreamDelegate {
    let opts: Options
    var stream: SCStream?
    var writer: AVAssetWriter!
    var videoInput: AVAssetWriterInput!
    var sysAudioInput: AVAssetWriterInput!
    var micInput: AVAssetWriterInput?
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
        guard !opts.outPath.isEmpty else { err("--out <path> required (or use --list)") }
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
        if opts.alsoMic {
            cfg.captureMicrophone = true   // macOS 15+ native mic capture, no AVCaptureSession
        }

        setupWriter(width: cfg.width, height: cfg.height, mic: opts.alsoMic)

        let s = SCStream(filter: filter, configuration: cfg, delegate: self)
        do {
            try s.addStreamOutput(self, type: .screen, sampleHandlerQueue: sampleQueue)
            try s.addStreamOutput(self, type: .audio, sampleHandlerQueue: sampleQueue)
            if opts.alsoMic {
                try s.addStreamOutput(self, type: .microphone, sampleHandlerQueue: sampleQueue)
            }
        } catch { err("addStreamOutput: \(error.localizedDescription)") }
        self.stream = s

        s.startCapture { [weak self] error in
            if let error { err("startCapture: \(error.localizedDescription)") }
            let scope = self?.opts.appName.map { "app \"\($0)\"" } ?? "whole display + all system audio"
            let mic = (self?.opts.alsoMic ?? false) ? " + mic" : ""
            FileHandle.standardError.write("● recording \(scope)\(mic) → \(self?.opts.outPath ?? "")\n  press Ctrl-C to stop\n".data(using: .utf8)!)
        }

        installSignalHandler()
    }

    func setupWriter(width: Int, height: Int, mic: Bool) {
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

        if mic {
            let m = AVAssetWriterInput(mediaType: .audio, outputSettings: aSettings)
            m.expectsMediaDataInRealTime = true
            writer.add(m)
            micInput = m
        }

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
            if let mic = micInput, mic.isReadyForMoreMediaData { mic.append(sampleBuffer) }
        @unknown default:
            break
        }
    }

    func stream(_ stream: SCStream, didStopWithError error: Error) {
        FileHandle.standardError.write("stream stopped: \(error.localizedDescription)\n".data(using: .utf8)!)
        finish()
    }

    // Ctrl-C → clean stop + finalize.
    func installSignalHandler() {
        signal(SIGINT, SIG_IGN)
        let src = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        src.setEventHandler { [weak self] in self?.finish() }
        src.resume()
        // Retain the source for the life of the process.
        objc_setAssociatedObject(self, "sigsrc", src, .OBJC_ASSOCIATION_RETAIN)
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
                    if self.writer.status == .completed {
                        print("✓ saved \(self.opts.outPath)")
                    } else {
                        FileHandle.standardError.write("write failed: \(self.writer.error?.localizedDescription ?? "unknown")\n".data(using: .utf8)!)
                    }
                    exit(self.writer.status == .completed ? 0 : 1)
                }
            }
        }
    }
}

// MARK: - main

let opts = parseArgs()
let recorder = Recorder(opts)   // global — must outlive the async SCK callbacks
recorder.run()
