// rec-subtitle — transcribe a recording to .srt (via whisp/Whisper) and optionally BURN the
// subtitles into the video (Apple-native AVFoundation Core Animation). Two modes:
//
//   rec-subtitle <video> [--mic <voice.m4a>] [--model NAME]
//        → <video-stem>.srt  (soft sidecar — upload to YouTube as a caption track)
//   rec-subtitle <video> --burn [--srt FILE] [--mic <voice.m4a>] [--model NAME]
//        → <video-stem>-subtitled.mov  (subtitles hard-burned into the picture)
//
// Transcription shells out to ~/work/whisp/whisp (OpenAI Whisper, --output_format all).
// Feed the voice-only track (--mic <name>-mic.m4a from `rec-audio split`) for the cleanest
// transcript; otherwise the video's own audio is used.
//
// Build: swiftc -O -target <arch>-apple-macos13.0 -o rec-subtitle rec-subtitle.swift \
//          -framework AVFoundation -framework CoreMedia -framework QuartzCore -framework AppKit

import Foundation
import AVFoundation
import CoreMedia
import QuartzCore
import AppKit

func die(_ s: String) -> Never { FileHandle.standardError.write((s + "\n").data(using: .utf8)!); exit(1) }
func note(_ s: String) { FileHandle.standardError.write((s + "\n").data(using: .utf8)!) }

func sync<T>(_ op: @escaping () async throws -> T) -> T {
    let sem = DispatchSemaphore(value: 0); var out: Result<T, Error>!
    Task { do { out = .success(try await op()) } catch { out = .failure(error) }; sem.signal() }
    sem.wait()
    switch out! { case .success(let v): return v; case .failure(let e): die("error: \(e.localizedDescription)") }
}

// MARK: - SRT

struct Cue { let start: Double; let end: Double; let text: String }

func parseSRTTime(_ s: String) -> Double? {
    // HH:MM:SS,mmm
    let parts = s.replacingOccurrences(of: ",", with: ".").split(separator: ":")
    guard parts.count == 3, let h = Double(parts[0]), let m = Double(parts[1]), let sec = Double(parts[2]) else { return nil }
    return h * 3600 + m * 60 + sec
}

func parseSRT(_ path: String) -> [Cue] {
    guard let raw = try? String(contentsOfFile: path, encoding: .utf8) else { die("cannot read \(path)") }
    var cues: [Cue] = []
    for block in raw.replacingOccurrences(of: "\r", with: "").components(separatedBy: "\n\n") {
        let lines = block.split(separator: "\n", omittingEmptySubsequences: true).map(String.init)
        guard let tIdx = lines.firstIndex(where: { $0.contains("-->") }) else { continue }
        let tc = lines[tIdx].components(separatedBy: "-->")
        guard tc.count == 2, let a = parseSRTTime(tc[0].trimmingCharacters(in: .whitespaces)),
              let b = parseSRTTime(tc[1].trimmingCharacters(in: .whitespaces)) else { continue }
        let text = lines[(tIdx + 1)...].joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty { cues.append(Cue(start: a, end: b, text: text)) }
    }
    return cues
}

// MARK: - transcription via whisp

func transcribe(_ audioOrVideo: String, model: String?, outStem: String) -> String {
    let whisp = ("~/work/whisp/whisp" as NSString).expandingTildeInPath
    guard FileManager.default.fileExists(atPath: whisp) else { die("whisp not found at \(whisp)") }
    let outDir = (outStem as NSString).deletingLastPathComponent
    note("⧉ transcribing \((audioOrVideo as NSString).lastPathComponent) via whisp (Whisper)…")
    let p = Process()
    p.launchPath = "/bin/bash"
    var args = [whisp, "--output-dir", outDir]
    if let model { args += ["--model", model] }
    args.append(audioOrVideo)
    p.arguments = ["-lc", args.map { "'\($0.replacingOccurrences(of: "'", with: "'\\''"))'" }.joined(separator: " ")]
    do { try p.run() } catch { die("failed to launch whisp: \(error.localizedDescription)") }
    p.waitUntilExit()
    if p.terminationStatus != 0 { die("whisp exited \(p.terminationStatus)") }
    // whisp writes <inputstem>.srt into outDir
    let inStem = ((audioOrVideo as NSString).lastPathComponent as NSString).deletingPathExtension
    let srt = (outDir as NSString).appendingPathComponent(inStem + ".srt")
    guard FileManager.default.fileExists(atPath: srt) else { die("whisp produced no .srt at \(srt)") }
    return srt
}

// MARK: - burn-in (Core Animation)

func attributed(_ s: String, fontSize: CGFloat) -> NSAttributedString {
    let style = NSMutableParagraphStyle(); style.alignment = .center
    return NSAttributedString(string: s, attributes: [
        .font: NSFont.systemFont(ofSize: fontSize, weight: .semibold),
        .foregroundColor: NSColor.white,
        .strokeColor: NSColor.black,
        .strokeWidth: -4.0,               // negative = stroke AND fill (outline for readability)
        .paragraphStyle: style,
    ])
}

/// Render a subtitle line to a CGImage. CATextLayer text does NOT draw inside the offline
/// AVVideoCompositionCoreAnimationTool render, so we rasterize the text ourselves and hand a
/// plain CALayer the image — that composites reliably.
func renderTextImage(_ text: String, width: CGFloat, height: CGFloat, fontSize: CGFloat) -> CGImage? {
    let scale: CGFloat = 2
    let w = max(1, Int(width * scale)), h = max(1, Int(height * scale))
    guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                              space: CGColorSpaceCreateDeviceRGB(),
                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
    // Bottom-up context (flipped:false) so the resulting CGImage displays right-side-up when
    // set as a CALayer's contents (CGContext bitmaps are bottom-origin).
    let ns = NSGraphicsContext(cgContext: ctx, flipped: false)
    NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = ns
    let attr = attributed(text, fontSize: fontSize * scale)
    let inset = 12 * scale
    let bounds = attr.boundingRect(with: NSSize(width: CGFloat(w) - inset * 2, height: CGFloat(h)),
                                   options: [.usesLineFragmentOrigin, .usesFontLeading])
    let ty = max(inset, (CGFloat(h) - bounds.height) / 2)
    attr.draw(with: NSRect(x: inset, y: ty, width: CGFloat(w) - inset * 2, height: bounds.height),
              options: [.usesLineFragmentOrigin, .usesFontLeading])
    NSGraphicsContext.restoreGraphicsState()
    return ctx.makeImage()
}

func burn(video: String, srtPath: String, outPath: String) {
    let cues = parseSRT(srtPath)
    guard !cues.isEmpty else { die("no cues in \(srtPath)") }
    let asset = AVURLAsset(url: URL(fileURLWithPath: video))
    guard let vTrack = sync({ try await asset.loadTracks(withMediaType: .video) }).first else { die("no video track") }
    let natural = sync { try await vTrack.load(.naturalSize) }
    let transform = sync { try await vTrack.load(.preferredTransform) }
    let dur = sync { try await asset.load(.duration) }
    let disp = natural.applying(transform)
    let W = abs(disp.width), H = abs(disp.height)

    let comp = AVMutableComposition()
    guard let cV = comp.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else { die("comp v") }
    try? cV.insertTimeRange(CMTimeRange(start: .zero, duration: dur), of: vTrack, at: .zero)
    cV.preferredTransform = transform
    if let aTrack = sync({ try await asset.loadTracks(withMediaType: .audio) }).first {
        if let cA = comp.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
            try? cA.insertTimeRange(CMTimeRange(start: .zero, duration: dur), of: aTrack, at: .zero)
        }
    }

    // CA layer tree: parent → videoLayer (the picture) + one text layer per cue.
    let parent = CALayer(); parent.frame = CGRect(x: 0, y: 0, width: W, height: H)
    let videoLayer = CALayer(); videoLayer.frame = parent.frame
    parent.addSublayer(videoLayer)
    let fontSize = H * 0.045
    let totalSec = max(CMTimeGetSeconds(dur), 0.001)
    let boxW = W * 0.84, boxH = H * 0.22
    for cue in cues {
        let t = CALayer()
        t.frame = CGRect(x: W * 0.08, y: H * 0.05, width: boxW, height: boxH)
        t.contents = renderTextImage(cue.text, width: boxW, height: boxH, fontSize: fontSize)
        t.contentsGravity = .resizeAspect
        t.opacity = 0
        // Single DISCRETE keyframe over the whole timeline: opacity 0 until start, 1 during
        // [start,end], 0 after. This is the reliable pattern for the offline CA tool (multiple
        // begin-time-offset animations on one layer don't accumulate here).
        let s = min(max(cue.start / totalSec, 0.0001), 0.9997)
        let e = min(max(cue.end / totalSec, s + 0.0001), 0.9998)
        let anim = CAKeyframeAnimation(keyPath: "opacity")
        anim.duration = totalSec
        anim.beginTime = AVCoreAnimationBeginTimeAtZero
        anim.calculationMode = .discrete
        anim.keyTimes = [0, s, e, 1].map { NSNumber(value: $0) }
        anim.values = [0, 1, 0, 0]
        anim.isRemovedOnCompletion = false
        anim.fillMode = .both
        t.add(anim, forKey: "vis")
        parent.addSublayer(t)
    }

    let vc = AVMutableVideoComposition()
    vc.renderSize = CGSize(width: W, height: H)
    vc.frameDuration = CMTime(value: 1, timescale: 30)
    let instr = AVMutableVideoCompositionInstruction()
    instr.timeRange = CMTimeRange(start: .zero, duration: dur)
    let li = AVMutableVideoCompositionLayerInstruction(assetTrack: cV)
    li.setTransform(transform, at: .zero)
    instr.layerInstructions = [li]
    vc.instructions = [instr]
    vc.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parent)

    let out = URL(fileURLWithPath: outPath)
    try? FileManager.default.removeItem(at: out)
    guard let export = AVAssetExportSession(asset: comp, presetName: AVAssetExportPresetHighestQuality) else { die("export session") }
    export.videoComposition = vc
    note("⧉ burning \(cues.count) subtitles into \((outPath as NSString).lastPathComponent) …")
    if #available(macOS 15.0, *) {
        sync { try await export.export(to: out, as: .mov) }
    } else {
        export.outputURL = out; export.outputFileType = .mov
        let sem = DispatchSemaphore(value: 0)
        export.exportAsynchronously { sem.signal() }
        sem.wait()
        if export.status != .completed { die("burn export failed: \(export.error?.localizedDescription ?? "unknown")") }
    }
    print("✓ \(outPath)")
}

// MARK: - main

var args = Array(CommandLine.arguments.dropFirst())
guard let video = args.first, !video.hasPrefix("-") else {
    die("""
    usage:
      rec-subtitle <video> [--mic voice.m4a] [--model NAME]           → <stem>.srt sidecar
      rec-subtitle <video> --burn [--srt FILE] [--mic voice.m4a]      → <stem>-subtitled.mov
    """)
}
let videoPath = (video as NSString).expandingTildeInPath
args.removeFirst()
func opt(_ name: String) -> String? { if let i = args.firstIndex(of: name), i + 1 < args.count { return (args[i+1] as NSString).expandingTildeInPath }; return nil }
let doBurn = args.contains("--burn")
let model = opt("--model")
let micAudio = opt("--mic")
let stem = (videoPath as NSString).deletingPathExtension

// Get the .srt: use --srt if given, else an existing sidecar, else transcribe.
var srt = opt("--srt") ?? (stem + ".srt")
if !FileManager.default.fileExists(atPath: srt) {
    let source = micAudio ?? videoPath
    let produced = transcribe(source, model: model, outStem: stem + ".srt")
    // whisp names by the SOURCE stem; normalize to <video-stem>.srt for predictability.
    if produced != stem + ".srt" { try? FileManager.default.removeItem(atPath: stem + ".srt"); try? FileManager.default.copyItem(atPath: produced, toPath: stem + ".srt") }
    srt = stem + ".srt"
}
print("✓ \(srt)")

if doBurn {
    burn(video: videoPath, srtPath: srt, outPath: stem + "-subtitled.mov")
}
