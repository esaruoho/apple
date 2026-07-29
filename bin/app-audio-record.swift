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
import CoreAudio
import AppKit

// MARK: - Who is actually making sound right now?
//
// SCShareableContent lists every running app; it does NOT know which of them are
// producing audio. CoreAudio does: macOS 14.4+ exposes an audio-process object list,
// and each process object reports whether it is currently running OUTPUT. That is the
// difference between "here are 60 apps, guess" and "Schism Tracker ● is playing".
// Used by --list-audio, which is what the `wav` picker renders.

struct AudioProc {
    var pid: pid_t
    var bundleID: String
    var name: String
    var playing: Bool
    var isApp: Bool     // .regular activation policy — a real app with a Dock tile / UI,
                        // as opposed to audiomxd / assistantd / avconferenced plumbing.
}

func audioProcesses() -> [AudioProc] {
    guard #available(macOS 14.4, *) else { return [] }
    var addr = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyProcessObjectList,
                                          mScope: kAudioObjectPropertyScopeGlobal,
                                          mElement: kAudioObjectPropertyElementMain)
    var size: UInt32 = 0
    guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size) == noErr,
          size > 0 else { return [] }
    let count = Int(size) / MemoryLayout<AudioObjectID>.size
    var ids = [AudioObjectID](repeating: 0, count: count)
    guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size, &ids) == noErr
    else { return [] }

    // POD properties only (pid_t, UInt32). CFString properties must NOT go through this —
    // taking a raw pointer to a variable holding an object reference is not well-defined.
    func prop<T>(_ obj: AudioObjectID, _ selector: AudioObjectPropertySelector, _ initial: T) -> T? {
        var a = AudioObjectPropertyAddress(mSelector: selector,
                                           mScope: kAudioObjectPropertyScopeGlobal,
                                           mElement: kAudioObjectPropertyElementMain)
        var v = initial
        var sz = UInt32(MemoryLayout<T>.size)
        let status = withUnsafeMutablePointer(to: &v) {
            AudioObjectGetPropertyData(obj, &a, 0, nil, &sz, UnsafeMutableRawPointer($0))
        }
        guard status == noErr else { return nil }
        return v
    }

    /// CFString-valued property. CoreAudio hands back a +1 reference, hence takeRetainedValue.
    func stringProp(_ obj: AudioObjectID, _ selector: AudioObjectPropertySelector) -> String? {
        var a = AudioObjectPropertyAddress(mSelector: selector,
                                           mScope: kAudioObjectPropertyScopeGlobal,
                                           mElement: kAudioObjectPropertyElementMain)
        var cf: Unmanaged<CFString>?
        var sz = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        let status = withUnsafeMutablePointer(to: &cf) {
            AudioObjectGetPropertyData(obj, &a, 0, nil, &sz, $0)
        }
        guard status == noErr, let cf else { return nil }
        return cf.takeRetainedValue() as String
    }

    var out: [AudioProc] = []
    for id in ids {
        guard let pid: pid_t = prop(id, kAudioProcessPropertyPID, pid_t(0)) else { continue }
        let playing = (prop(id, kAudioProcessPropertyIsRunningOutput, UInt32(0)) ?? 0) != 0
        let bundleID = stringProp(id, kAudioProcessPropertyBundleID) ?? ""
        let running = NSRunningApplication(processIdentifier: pid)
        let name = running?.localizedName ?? bundleID
        if bundleID.isEmpty && running == nil { continue }   // faceless daemon, nothing to pick
        out.append(AudioProc(pid: pid,
                             bundleID: bundleID.isEmpty ? (running?.bundleIdentifier ?? "") : bundleID,
                             name: name.isEmpty ? "pid \(pid)" : name,
                             playing: playing,
                             isApp: running?.activationPolicy == .regular))
    }
    // Playing first, then alphabetical — the thing you want is always at the top.
    return out.sorted { ($0.playing ? 0 : 1, $0.name.lowercased()) < ($1.playing ? 0 : 1, $1.name.lowercased()) }
}

func printAudioProcessesJSON() {
    let rows = audioProcesses().map { p -> [String: Any] in
        ["pid": Int(p.pid), "bundleID": p.bundleID, "name": p.name,
         "playing": p.playing, "isApp": p.isApp]
    }
    let data = try! JSONSerialization.data(withJSONObject: rows, options: [.prettyPrinted])
    FileHandle.standardOutput.write(data)
    FileHandle.standardOutput.write("\n".data(using: .utf8)!)
}

struct Options {
    var appName: String?
    var all = false
    var front = false           // tap whatever app is frontmost when capture begins
    var outPath = ""
    var seconds: Double = 0     // 0 = record until Ctrl-C
    var after: Double = 0       // countdown before the tap opens (go hit play in the tracker)
    var list = false
    var reveal = false
    var quiet = false           // suppress the live level meter
    var manifest = ""           // typed handoff: write {path, peak, bytes, silent} here
}

func err(_ s: String) -> Never {
    FileHandle.standardError.write(("error: " + s + "\n").data(using: .utf8)!)
    exit(1)
}

func printUsage() {
    print("""
    app-audio-record — capture one app's audio to a .wav (ScreenCaptureKit, no loopback driver)

      --list              list tappable apps
      --app <name>        capture ONLY this app's audio (name or bundle id, substring ok)
      --front             capture whatever app is FRONTMOST when the tap opens
      --all               capture all system audio
      --after <n>         wait n seconds before the tap opens — switch to the app and
                          hit play; with --front the frontmost app is resolved AFTER the wait
      --seconds <n>       stop automatically after n seconds (default: run until Ctrl-C)
      --out <path>        a .wav FILE, or a FOLDER to drop <timestamp>-<app>.wav into
                          (folder is created if missing; default: the current folder)
      --quiet             no live level meter (and no countdown)
      --manifest <path>   write {path, peak_dbfs, bytes, silent} JSON there when done
                          (typed handoff for a "then" step — no scraping our prose)
      --reveal            reveal the finished file in Finder

    While capturing it prints a live level meter WITH a countdown, so you can see both
    whether the app is making sound and how long is left. Stop early any time with
    Enter, Esc, q or Ctrl-C. If the whole capture was digital silence it says so and
    exits 3 — a silent .wav is never reported as a success.

    The source app keeps playing normally — this is a parallel tap, not a reroute.
    Needs Screen Recording permission (System Settings ▸ Privacy & Security).

    Tracker workflow:
      app-audio-record --front --after 4 --seconds 30 --out ~/Music/grabs
      (run it, switch to Schism/Renoise, hit play — the grab lands in the folder)
    """)
}

func parseArgs() -> Options {
    var o = Options()
    var i = 1
    let a = CommandLine.arguments
    while i < a.count {
        switch a[i] {
        case "--list", "-l": o.list = true
        case "--list-audio": printAudioProcessesJSON(); exit(0)
        case "--all", "--system-audio": o.all = true
        case "--front", "--frontmost": o.front = true
        case "--reveal": o.reveal = true
        case "--quiet", "-q": o.quiet = true
        case "--app": i += 1; o.appName = i < a.count ? a[i] : nil
        case "--out", "-o": i += 1; o.outPath = i < a.count ? a[i] : ""
        case "--seconds", "-t": i += 1; o.seconds = i < a.count ? (Double(a[i]) ?? 0) : 0
        case "--after", "--delay": i += 1; o.after = i < a.count ? (Double(a[i]) ?? 0) : 0
        case "--manifest": i += 1; o.manifest = i < a.count ? a[i] : ""
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

    /// `--out` takes a FILE or a FOLDER, and the rule is the one people actually expect:
    /// **it is a file only if it ends in .wav** — otherwise it is a folder, created if
    /// missing, and a timestamped `<stamp>-<App>.wav` is dropped inside.
    ///
    /// The earlier rule ("folder only if it already exists or ends in /") looked reasonable
    /// and was wrong in the exact case that matters: `--out ~/Music/grabs` on the FIRST run,
    /// before the folder exists, silently produced a extension-less *file* named `grabs`.
    /// Caught by the picker's end-to-end test, which passed a not-yet-created folder.
    static func resolveOutPath(_ given: String, label: String) -> String {
        let name = stamped(label)
        if given.isEmpty { return FileManager.default.currentDirectoryPath + "/" + name }
        let expanded = ((given as NSString).expandingTildeInPath as NSString).standardizingPath
        if expanded.lowercased().hasSuffix(".wav") {
            // A file. Make sure its parent exists so `--out ~/new/dir/take.wav` works too.
            let parent = (expanded as NSString).deletingLastPathComponent
            if !parent.isEmpty {
                try? FileManager.default.createDirectory(atPath: parent, withIntermediateDirectories: true)
            }
            return expanded
        }
        try? FileManager.default.createDirectory(atPath: expanded, withIntermediateDirectories: true)
        return expanded + "/" + name
    }

    func run() {
        // The countdown happens BEFORE anything is resolved, so --front picks the app you
        // switched to during the wait, not the terminal you launched from.
        if opts.after > 0 {
            var left = Int(opts.after.rounded())
            print("⏱  starting in \(left)s — switch to the app and hit play…")
            while left > 0 {
                FileHandle.standardError.write("   \(left)…\r".data(using: .utf8)!)
                Thread.sleep(forTimeInterval: 1)
                left -= 1
            }
            FileHandle.standardError.write("        \r".data(using: .utf8)!)
        }
        if opts.front {
            guard let app = NSWorkspace.shared.frontmostApplication,
                  let bid = app.bundleIdentifier else { err("cannot determine the frontmost app") }
            opts.appName = bid
            print("🎯 frontmost app: \(app.localizedName ?? bid)  (\(bid))")
        }
        SCShareableContent.getExcludingDesktopWindows(false, onScreenWindowsOnly: false) { content, error in
            if let error { err("ScreenCaptureKit: \(error.localizedDescription)\n(grant Screen Recording in System Settings ▸ Privacy & Security)") }
            guard let content else { err("no shareable content") }
            if self.opts.list { self.listContent(content); exit(0) }
            self.start(content)
        }
        dispatchMain()
    }

    // MARK: - Level metering
    //
    // The whole point: a capture that produced silence must LOOK different from one that
    // worked, while it is still running. SCK hands us Float32 PCM; peak-scan each buffer,
    // keep the session maximum, and redraw a meter line ~10x/sec.

    var sessionPeak: Float = 0
    var lastMeterDraw = Date.distantPast
    var meterEnabled = false
    var captureStart: Date?
    var meterTimer: DispatchSourceTimer?

    func peakOf(_ sb: CMSampleBuffer) -> Float? {
        guard let fmt = sb.formatDescription,
              let asbd = fmt.audioStreamBasicDescription,
              asbd.mFormatFlags & kAudioFormatFlagIsFloat != 0 else { return nil }
        var maxAbs: Float = 0
        try? sb.withAudioBufferList { abl, _ in
            for buf in abl {
                guard let data = buf.mData else { continue }
                let n = Int(buf.mDataByteSize) / MemoryLayout<Float>.size
                let p = data.bindMemory(to: Float.self, capacity: n)
                for i in 0..<n {
                    let a = abs(p[i])
                    if a > maxAbs { maxAbs = a }
                }
            }
        }
        return maxAbs
    }

    /// The meter line is also the clock. A capture that says "stopping after 16.0s" once
    /// and then sits there tells you nothing about how long is left — so the remaining
    /// time counts down in the same line that shows the level.
    ///
    /// Driven by BOTH the audio callbacks and a 0.1s timer, so the clock keeps ticking
    /// even if buffers stall — a frozen countdown would be its own kind of lie.
    var lastPeak: Float = 0

    func drawMeter() {
        guard meterEnabled, Date().timeIntervalSince(lastMeterDraw) > 0.08 else { return }
        lastMeterDraw = Date()
        let peak = lastPeak
        let db = peak > 0 ? 20 * log10(Double(peak)) : -Double.infinity
        // -60 dBFS .. 0 dBFS across 30 cells
        let filled = peak > 0 ? max(0, min(30, Int((db + 60) / 2))) : 0
        let bar = String(repeating: "█", count: filled) + String(repeating: "·", count: 30 - filled)
        let label = peak > 0 ? String(format: "%6.1f dBFS", db) : "  silence"

        var clock = ""
        if let started = captureStart {
            let elapsed = Date().timeIntervalSince(started)
            if opts.seconds > 0 {
                let left = max(0, opts.seconds - elapsed)
                clock = String(format: "  %4.1fs left", left)
            } else {
                clock = String(format: "  %d:%02d", Int(elapsed) / 60, Int(elapsed) % 60)
            }
        }
        FileHandle.standardError.write("   [\(bar)] \(label)\(clock)  \r".data(using: .utf8)!)
    }

    func startMeterClock() {
        guard meterEnabled else { return }
        let t = DispatchSource.makeTimerSource(queue: sampleQueue)
        t.schedule(deadline: .now() + 0.1, repeating: 0.1)
        t.setEventHandler { [weak self] in self?.drawMeter() }
        t.resume()
        meterTimer = t
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
            // Say out loud WHICH app the string resolved to, so nobody has to type a bundle
            // id defensively just to be sure the match landed where they meant.
            let names = matches.map { "\($0.applicationName) (\($0.bundleIdentifier))" }
            if names.count == 1 {
                print("🎯 matched: \(names[0])")
            } else {
                print("🎯 \"\(name)\" matched \(names.count) apps — tapping all of them:")
                for n in names { print("     • \(n)") }
            }
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
        meterEnabled = !opts.quiet && isatty(STDERR_FILENO) == 1

        let s = SCStream(filter: filter, configuration: cfg, delegate: self)
        do { try s.addStreamOutput(self, type: .audio, sampleHandlerQueue: sampleQueue) }
        catch { err("addStreamOutput: \(error.localizedDescription)") }
        stream = s

        s.startCapture { [weak self] error in
            if let error { err("startCapture: \(error.localizedDescription)") }
            guard let self else { return }
            let scope = self.opts.appName == nil ? "all system audio" : "app \"\(label)\""
            print("🎧 tapping \(scope) → \(self.opts.outPath)")
            let stopKeys = isatty(STDIN_FILENO) == 1 ? "Enter / Esc / q / Ctrl-C" : "Ctrl-C"
            print(self.opts.seconds > 0
                  ? "   stopping after \(String(format: "%g", self.opts.seconds))s — or \(stopKeys) to stop early."
                  : "   press \(stopKeys) to stop.")
            self.captureStart = Date()
            self.startMeterClock()
            if self.opts.seconds > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + self.opts.seconds) { self.finish() }
            }
        }
        installSignalHandler()
        installKeyWatcher()
    }

    /// Typed handoff, same doctrine as screen-audio-record's RECBURN-MANIFEST: whatever
    /// runs AFTER this recording (open in Live, reveal in Finder, a Shortcut) must read
    /// structured data, never grep the human "✓ …" line whose wording will change.
    /// Written on BOTH outcomes, so a "then" step can decline to open a silent grab.
    func writeManifest(bytes: Int, silent: Bool) {
        guard !opts.manifest.isEmpty else { return }
        let db = sessionPeak > 0 ? 20 * log10(Double(sessionPeak)) : -Double.infinity
        let obj: [String: Any] = [
            "schema": "app-audio-record/1",
            "path": opts.outPath,
            "bytes": bytes,
            "peak_dbfs": db.isFinite ? db : -999,
            "silent": silent,
            "app": opts.appName ?? "",
        ]
        if let d = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted]) {
            try? d.write(to: URL(fileURLWithPath: opts.manifest))
        }
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
        if let p = peakOf(sampleBuffer) {
            if p > sessionPeak { sessionPeak = p }
            lastPeak = p
            drawMeter()
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

    // MARK: - Stop on a keypress
    //
    // Ctrl-C works, but "press a key to stop" is what a recorder should feel like — and
    // after `wav` raises the app, Ctrl-C is a two-handed thing while Esc/Enter is one.
    // ICANON+ECHO are cleared so single keys arrive immediately with nothing echoed;
    // ISIG is deliberately LEFT ON so Ctrl-C still raises SIGINT as before.

    static var savedTermios: termios?
    var stdinSrc: DispatchSourceRead?

    func installKeyWatcher() {
        guard isatty(STDIN_FILENO) == 1 else { return }   // piped/backgrounded: nothing to read
        var raw = termios()
        guard tcgetattr(STDIN_FILENO, &raw) == 0 else { return }
        Self.savedTermios = raw
        raw.c_lflag &= ~(UInt(ICANON) | UInt(ECHO))       // NOT ISIG — keep Ctrl-C alive
        withUnsafeMutablePointer(to: &raw.c_cc) {
            $0.withMemoryRebound(to: cc_t.self, capacity: Int(NCCS)) { cc in
                cc[Int(VMIN)] = 1
                cc[Int(VTIME)] = 0
            }
        }
        tcsetattr(STDIN_FILENO, TCSANOW, &raw)
        atexit { AudioRecorder.restoreTerminal() }        // never leave a wrecked terminal

        let src = DispatchSource.makeReadSource(fileDescriptor: STDIN_FILENO, queue: .main)
        src.setEventHandler { [weak self] in
            var byte: UInt8 = 0
            guard read(STDIN_FILENO, &byte, 1) == 1 else { return }
            // Enter, Esc or q — Esc arrives as 0x1B alone (no arrow-key escape sequences
            // are expected here, this is not a full-screen UI).
            if byte == 0x0A || byte == 0x0D || byte == 0x1B || byte == UInt8(ascii: "q") {
                self?.finish()
            }
        }
        src.resume()
        stdinSrc = src
    }

    static func restoreTerminal() {
        guard var t = savedTermios else { return }
        tcsetattr(STDIN_FILENO, TCSANOW, &t)
        savedTermios = nil
    }

    func finish() {
        guard !finished else { return }
        finished = true
        meterTimer?.cancel(); meterTimer = nil
        AudioRecorder.restoreTerminal()
        stream?.stopCapture { _ in
            self.sampleQueue.async {
                guard self.started else {
                    FileHandle.standardError.write("no audio was captured — was the app actually making sound?\n".data(using: .utf8)!)
                    exit(2)
                }
                self.audioInput.markAsFinished()
                self.writer.finishWriting {
                    if self.meterEnabled {
                        FileHandle.standardError.write(String(repeating: " ", count: 56).data(using: .utf8)! + "\r".data(using: .utf8)!)
                    }
                    if self.writer.status == .completed {
                        let bytes = (try? FileManager.default.attributesOfItem(atPath: self.opts.outPath)[.size] as? Int) ?? 0
                        // A silent .wav is a FAILED grab, not a successful one. Say so, keep
                        // the file (so it can be inspected), and exit non-zero so any
                        // automation chaining off this doesn't treat silence as a capture.
                        if self.sessionPeak <= 0 {
                            self.writeManifest(bytes: bytes, silent: true)
                            let who = self.opts.appName ?? "the selected source"
                            FileHandle.standardError.write("""
                            ⚠️  SILENT — every sample is zero. \(self.opts.outPath) is \
                            \(String(format: "%.1f", Double(bytes) / 192_000.0))s of digital silence.
                                \(who) produced no audio during the capture. Check that it was
                                actually PLAYING, and that its output goes to a normal output
                                device (a tap can only hear what the app renders).
                                Use --after <n> to give yourself time to switch over and hit play.

                            """.data(using: .utf8)!)
                            exit(3)
                        }
                        self.writeManifest(bytes: bytes, silent: false)
                        let db = 20 * log10(Double(self.sessionPeak))
                        print(String(format: "✓ %@  (%d bytes, %d buffers, peak %.1f dBFS)",
                                     self.opts.outPath, bytes, self.frames, db))
                        // Not zero, but nothing you could ever hear: an app can hold an
                        // open output stream (so CoreAudio calls it "playing") while
                        // rendering only denormal noise. Say so — otherwise a -99 dBFS
                        // grab reads as a clean success and disappoints later.
                        if db < -60 {
                            let warn = "⚠️  effectively silent — peak is \(String(format: "%.1f", db)) dBFS, far below audible. "
                                     + "The app held an audio stream open but rendered (near-)nothing. Was it really playing?\n"
                            FileHandle.standardError.write(warn.data(using: .utf8)!)
                        }
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
