// app-audio-record — capture ONE app's audio straight to a .wav (ScreenCaptureKit, no loopback)
//
// The Apple-native answer to "route another app's sound into my recorder". There is NO
// AudioUnit plugin that can do this — an AU runs inside its host process and cannot reach
// another app's audio. ScreenCaptureKit can: an SCContentFilter scoped to an application
// yields that application's audio taps only, with nothing rerouted and no virtual device
// (BlackHole / Loopback / Soundflower) installed. The source app keeps playing to the
// speakers exactly as before; we get a parallel tap.
//
// This is the audio-only sibling of screen-audio-record: no video track, no .mov,
// no re-encode — 48 kHz / 16-bit / stereo LinearPCM straight into a WAV.
//
// Build:  swiftc -O -o bin/app-audio-record bin/app-audio-record.swift \
//               -framework ScreenCaptureKit -framework AVFoundation -framework CoreMedia -framework AppKit
//
// Usage:  app-audio-record --list                             # what can I tap?
//         app-audio-record --app Music --seconds 10           # 10s of Music.app → ./<stamp>-Music.wav
//         app-audio-record --app Renoise --out ~/take.wav     # Ctrl-C to stop
//         app-audio-record --all --seconds 5                  # all system audio
//
// FEATURE-CARD >> features/app-audio-record.feature

import Foundation
import ScreenCaptureKit
import AVFoundation
import CoreMedia
import AppKit

struct Options {
    var appName: String?
    var all = false
    var outPath = ""
    var seconds: Double = 0     // 0 = record until Ctrl-C
    var list = false
    var reveal = false
}

func err(_ s: String) -> Never {
    FileHandle.standardError.write(("error: " + s + "\n").data(using: .utf8)!)
    exit(1)
}

func printUsage() {
    print("""
    app-audio-record — capture one app's audio to a .wav (ScreenCaptureKit, no loopback driver)

      --list              list displays + tappable apps
      --app <name>        capture ONLY this app's audio (name or bundle id, substring ok)
      --all               capture all system audio
      --seconds <n>       stop automatically after n seconds (default: run until Ctrl-C)
      --out <path>        a .wav FILE, or a FOLDER to drop <timestamp>-<app>.wav into
                          (folder is created if missing; default: the current folder)
      --reveal            reveal the finished file in Finder

    The source app keeps playing normally — this is a parallel tap, not a reroute.
    Needs Screen Recording permission (System Settings ▸ Privacy & Security).
    """)
}

func parseArgs() -> Options {
    var o = Options()
    var i = 1
    let a = CommandLine.arguments
    while i < a.count {
        switch a[i] {
        case "--list", "-l": o.list = true
        case "--all", "--system-audio": o.all = true
        case "--reveal": o.reveal = true
        case "--app": i += 1; o.appName = i < a.count ? a[i] : nil
        case "--out", "-o": i += 1; o.outPath = i < a.count ? a[i] : ""
        case "--seconds", "-t": i += 1; o.seconds = i < a.count ? (Double(a[i]) ?? 0) : 0
        case "--help", "-h": printUsage(); exit(0)
        default: err("unknown argument \(a[i]) — try --help")
        }
        i += 1
    }
    return o
}

final class AudioRecorder: NSObject, SCStreamOutput, SCStreamDelegate {
    var opts: Options
    init(_ o: Options) { opts = o }

    let sampleQueue = DispatchQueue(label: "app-audio-record.samples")
    var stream: SCStream?
    var writer: AVAssetWriter!
    var audioInput: AVAssetWriterInput!
    var started = false
    var finished = false
    var frames = 0

    static func stamped(_ label: String) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        let safe = label.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: " ", with: "-")
        return "\(f.string(from: Date()))-\(safe).wav"
    }

    /// `--out` takes a FILE or a FOLDER. A folder (existing directory, or any path ending
    /// in "/") gets a timestamped `<stamp>-<App>.wav` dropped inside it — "record a wavefile
    /// to a specific folder" without inventing a filename every time. Empty = current folder.
    static func resolveOutPath(_ given: String, label: String) -> String {
        let name = stamped(label)
        if given.isEmpty { return FileManager.default.currentDirectoryPath + "/" + name }
        let expanded = (given as NSString).expandingTildeInPath
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: expanded, isDirectory: &isDir)
        if given.hasSuffix("/") || (exists && isDir.boolValue) {
            let dir = (expanded as NSString).standardizingPath
            if !exists {
                try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
            }
            return dir + "/" + name
        }
        return expanded
    }

    func run() {
        SCShareableContent.getExcludingDesktopWindows(false, onScreenWindowsOnly: false) { content, error in
            if let error { err("ScreenCaptureKit: \(error.localizedDescription)\n(grant Screen Recording in System Settings ▸ Privacy & Security)") }
            guard let content else { err("no shareable content") }
            if self.opts.list { self.listContent(content); exit(0) }
            self.start(content)
        }
        dispatchMain()
    }

    func listContent(_ c: SCShareableContent) {
        print("TAPPABLE APPS (use --app <name>):")
        var seen = Set<String>()
        for a in c.applications
            .filter({ !$0.applicationName.isEmpty })
            .sorted(by: { $0.applicationName.lowercased() < $1.applicationName.lowercased() })
            where seen.insert(a.applicationName).inserted {
            print("  \(a.applicationName)  (\(a.bundleIdentifier))")
        }
    }

    func start(_ content: SCShareableContent) {
        guard let display = content.displays.first else { err("no display available") }

        let filter: SCContentFilter
        var label = "system"
        if let name = opts.appName {
            let matches = content.applications.filter {
                $0.applicationName.caseInsensitiveCompare(name) == .orderedSame ||
                $0.bundleIdentifier.caseInsensitiveCompare(name) == .orderedSame ||
                $0.applicationName.range(of: name, options: .caseInsensitive) != nil ||
                $0.bundleIdentifier.range(of: name, options: .caseInsensitive) != nil
            }
            guard !matches.isEmpty else { err("no running app matches \"\(name)\" — try --list") }
            label = matches[0].applicationName
            filter = SCContentFilter(display: display, including: matches, exceptingWindows: [])
        } else if opts.all {
            filter = SCContentFilter(display: display, excludingWindows: [])
        } else {
            err("choose --app <name> or --all — try --help")
        }
        opts.outPath = AudioRecorder.resolveOutPath(opts.outPath, label: label)

        // Audio-only: SCStream still wants a video configuration, so ask for the smallest
        // possible frame at the slowest possible rate and never attach a .screen output.
        // Nothing is encoded, nothing is written — the video path is inert.
        let cfg = SCStreamConfiguration()
        cfg.width = 2
        cfg.height = 2
        cfg.minimumFrameInterval = CMTime(value: 1, timescale: 1)
        cfg.showsCursor = false
        cfg.queueDepth = 6
        cfg.capturesAudio = true
        cfg.sampleRate = 48_000
        cfg.channelCount = 2
        cfg.excludesCurrentProcessAudio = true

        setupWriter()

        let s = SCStream(filter: filter, configuration: cfg, delegate: self)
        do { try s.addStreamOutput(self, type: .audio, sampleHandlerQueue: sampleQueue) }
        catch { err("addStreamOutput: \(error.localizedDescription)") }
        stream = s

        s.startCapture { [weak self] error in
            if let error { err("startCapture: \(error.localizedDescription)") }
            guard let self else { return }
            let scope = self.opts.appName == nil ? "all system audio" : "app \"\(label)\""
            print("🎧 tapping \(scope) → \(self.opts.outPath)")
            print(self.opts.seconds > 0 ? "   stopping after \(self.opts.seconds)s…" : "   press Ctrl-C to stop.")
            if self.opts.seconds > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + self.opts.seconds) { self.finish() }
            }
        }
        installSignalHandler()
    }

    func setupWriter() {
        let url = URL(fileURLWithPath: opts.outPath)
        try? FileManager.default.removeItem(at: url)
        guard let w = try? AVAssetWriter(outputURL: url, fileType: .wav) else { err("cannot create \(opts.outPath)") }
        writer = w
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 48_000,
            AVNumberOfChannelsKey: 2,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false,
        ]
        audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: settings)
        audioInput.expectsMediaDataInRealTime = true
        writer.add(audioInput)
    }

    // MARK: SCStreamOutput

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .audio, !finished, CMSampleBufferDataIsReady(sampleBuffer) else { return }
        if !started {
            writer.startWriting()
            writer.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
            started = true
        }
        if audioInput.isReadyForMoreMediaData {
            audioInput.append(sampleBuffer)
            frames += 1
        }
    }

    func stream(_ stream: SCStream, didStopWithError error: Error) {
        // Our own stopCapture() trips this delegate on the way out — that is teardown,
        // not a fault. Only report a stop we did not ask for.
        guard !finished else { return }
        FileHandle.standardError.write("stream stopped: \(error.localizedDescription)\n".data(using: .utf8)!)
        finish()
    }

    func installSignalHandler() {
        signal(SIGINT, SIG_IGN)
        let src = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        src.setEventHandler { [weak self] in self?.finish() }
        src.resume()
        Self.sigSrc = src
    }
    static var sigSrc: DispatchSourceSignal?

    func finish() {
        guard !finished else { return }
        finished = true
        stream?.stopCapture { _ in
            self.sampleQueue.async {
                guard self.started else {
                    FileHandle.standardError.write("no audio was captured — was the app actually making sound?\n".data(using: .utf8)!)
                    exit(2)
                }
                self.audioInput.markAsFinished()
                self.writer.finishWriting {
                    if self.writer.status == .completed {
                        let bytes = (try? FileManager.default.attributesOfItem(atPath: self.opts.outPath)[.size] as? Int) ?? 0
                        print("✓ \(self.opts.outPath)  (\(bytes) bytes, \(self.frames) buffers)")
                        if self.opts.reveal {
                            NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: self.opts.outPath)])
                        }
                        exit(0)
                    } else {
                        FileHandle.standardError.write("writer failed: \(self.writer.error?.localizedDescription ?? "unknown")\n".data(using: .utf8)!)
                        exit(1)
                    }
                }
            }
        }
    }
}

let opts = parseArgs()
if CommandLine.arguments.count == 1 { printUsage(); exit(0) }
AudioRecorder(opts).run()
