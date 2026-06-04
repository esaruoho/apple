// audio-snippets — capture N short clips from every audio INPUT device (or every
// individual channel), the audio twin of the camera snapshot. Apple-native:
// AVCaptureSession + AVCaptureAudioFileOutput, with an AVAudioFile channel
// splitter for --per-channel mode. No third-party deps.
//
//   audio-snippets <outdir> [--per-channel] [--device <substr>]
//                  [--count 5] [--len 3] [--gap 3.75] [--list]
//
// Default: 5 clips × 3s, ~3.75s apart (≈30s window) from each input device,
// written as LinearPCM .caf so high channel counts (e.g. the 7ch Aggregate) and
// per-channel splitting both work. Needs Microphone TCC (carried by the bundle).

import Foundation
import AVFoundation

var args = Array(CommandLine.arguments.dropFirst())
func popFlag(_ n: String) -> String? {
    guard let i = args.firstIndex(of: n), i + 1 < args.count else { return nil }
    let v = args[i + 1]; args.removeSubrange(i...(i+1)); return v
}
func err(_ s: String) { FileHandle.standardError.write((s + "\n").data(using: .utf8)!) }

let listOnly = args.contains("--list"); args.removeAll { $0 == "--list" }
let perChannel = args.contains("--per-channel"); args.removeAll { $0 == "--per-channel" }
let count = Int(popFlag("--count") ?? "5") ?? 5
let len = Double(popFlag("--len") ?? "3") ?? 3
let gap = Double(popFlag("--gap") ?? "3.75") ?? 3.75
let deviceMatch = popFlag("--device")
let outArg = args.first

let discovery = AVCaptureDevice.DiscoverySession(
    deviceTypes: [.microphone, .external], mediaType: .audio, position: .unspecified)
var devices = discovery.devices
if let m = deviceMatch {
    devices = devices.filter { $0.localizedName.range(of: m, options: .caseInsensitive) != nil }
}

if listOnly {
    print("audio input devices (\(devices.count)):")
    for d in devices { print("  • \(d.localizedName) | id=\(d.uniqueID)") }
    exit(0)
}
guard let outArg = outArg else {
    err("usage: audio-snippets <outdir> [--per-channel] [--count N] [--len S] [--gap S] [--list]"); exit(1)
}
let outURL = URL(fileURLWithPath: outArg, isDirectory: true)
func sanitize(_ s: String) -> String {
    String(s.map { $0.isLetter || $0.isNumber ? $0 : "-" })
}

// AVCaptureFileOutputRecordingDelegate's didFinishRecordingTo relies on KVO that
// a swiftc binary can't synthesize (same landmine as AVCapturePhotoOutput), so
// it never fires here. We don't depend on it — after stopRecording we POLL the
// output file until it opens as a valid, non-empty audio file.
final class RecDelegate: NSObject, AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo url: URL,
                    from connections: [AVCaptureConnection], error: Error?) {}
}
let recDelegate = RecDelegate()

func fileIsReady(_ url: URL) -> Bool {
    guard let f = try? AVAudioFile(forReading: url) else { return false }
    return f.length > 0
}

func recordSnippet(_ device: AVCaptureDevice, to url: URL, seconds: Double) -> Bool {
    let session = AVCaptureSession()
    guard let input = try? AVCaptureDeviceInput(device: device), session.canAddInput(input) else {
        err("  cannot open input for \(device.localizedName)"); return false
    }
    session.addInput(input)
    let out = AVCaptureAudioFileOutput()
    out.audioSettings = [
        AVFormatIDKey: kAudioFormatLinearPCM,
        AVLinearPCMBitDepthKey: 32,
        AVLinearPCMIsFloatKey: true,
        AVLinearPCMIsNonInterleaved: false,
        AVLinearPCMIsBigEndianKey: false,
    ]
    guard session.canAddOutput(out) else { err("  cannot add audio output"); return false }
    session.addOutput(out)
    session.startRunning()
    Thread.sleep(forTimeInterval: 0.3)  // let the input spin up
    let fileType: AVFileType = AVCaptureAudioFileOutput.availableOutputFileTypes().contains(.caf) ? .caf : .m4a
    out.startRecording(to: url, outputFileType: fileType, recordingDelegate: recDelegate)
    Thread.sleep(forTimeInterval: seconds)
    out.stopRecording()
    // poll for finalization (delegate won't fire — see note above)
    var ready = false
    for _ in 0..<40 { if fileIsReady(url) { ready = true; break }; Thread.sleep(forTimeInterval: 0.15) }
    session.stopRunning()
    if !ready { err("  recording did not finalize"); return false }
    return true
}

// Split a multichannel recording into one mono .caf per channel.
func splitChannels(_ src: URL, into dir: URL, base: String) -> Int {
    guard let f = try? AVAudioFile(forReading: src) else { return 0 }
    let fmt = f.processingFormat
    let frames = AVAudioFrameCount(f.length)
    guard frames > 0, let buf = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: frames),
          (try? f.read(into: buf)) != nil, let data = buf.floatChannelData else { return 0 }
    let ch = Int(fmt.channelCount)
    if ch <= 1 { return 0 }  // already mono, nothing to split
    var written = 0
    for c in 0..<ch {
        guard let monoFmt = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                          sampleRate: fmt.sampleRate, channels: 1, interleaved: false),
              let mono = AVAudioPCMBuffer(pcmFormat: monoFmt, frameCapacity: buf.frameLength) else { continue }
        mono.frameLength = buf.frameLength
        memcpy(mono.floatChannelData![0], data[c], Int(buf.frameLength) * MemoryLayout<Float>.size)
        let url = dir.appendingPathComponent("\(base)-ch\(c + 1).caf")
        guard let wf = try? AVAudioFile(forWriting: url, settings: monoFmt.settings,
                                        commonFormat: .pcmFormatFloat32, interleaved: false) else { continue }
        if (try? wf.write(from: mono)) != nil { written += 1 }
    }
    return written
}

try? FileManager.default.createDirectory(at: outURL, withIntermediateDirectories: true)
err("[audio-snippets] \(devices.count) device(s), \(count)×\(len)s, gap \(gap)s, perChannel=\(perChannel)")
var produced = 0
for device in devices {
    let ddir = outURL.appendingPathComponent(sanitize(device.localizedName))
    try? FileManager.default.createDirectory(at: ddir, withIntermediateDirectories: true)
    err("· \(device.localizedName)")
    for i in 1...count {
        let snip = ddir.appendingPathComponent("snippet-\(i).caf")
        if recordSnippet(device, to: snip, seconds: len) {
            produced += 1
            print(snip.path)
            if perChannel {
                let n = splitChannels(snip, into: ddir, base: "snippet-\(i)")
                if n > 0 { err("    split into \(n) channel file(s)") }
            }
        }
        if i < count { Thread.sleep(forTimeInterval: gap) }
    }
}
err("[audio-snippets] done — \(produced) snippet(s)")
exit(produced > 0 ? 0 : 2)
