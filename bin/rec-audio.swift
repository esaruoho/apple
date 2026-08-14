// rec-audio — post-process a screen recording's audio for editing (Apple-native AVFoundation)
//
// A `rec` recording is one .mov with video + a system-audio track (+ a mic track if used).
// iMovie can't pull individual audio tracks OUT of a single file — but it CAN import
// separate audio files as independent timeline tracks. So:
//
//   rec-audio split   <in.mov>            → <stem>-system.m4a  +  <stem>-mic.m4a
//                                           (drop these into iMovie as independent tracks —
//                                            balance voice vs app sound, mute either, etc.)
//   rec-audio flatten <in.mov> [-o out]   → <stem>-flat.mov: video (passthrough, no re-encode)
//                                           + ONE mixed audio track (system+mic summed).
//                                           Plays both everywhere (iMovie / QuickTime / YouTube).
//
// Build:  swiftc -O -o bin/rec-audio bin/rec-audio.swift -framework AVFoundation -framework CoreMedia

import Foundation
import AVFoundation
import CoreMedia

func die(_ s: String) -> Never { FileHandle.standardError.write((s + "\n").data(using: .utf8)!); exit(1) }

/// Run an async operation synchronously (CLI has no async main).
func sync<T>(_ op: @escaping () async throws -> T) -> T {
    let sem = DispatchSemaphore(value: 0)
    var out: Result<T, Error>!
    Task { do { out = .success(try await op()) } catch { out = .failure(error) }; sem.signal() }
    sem.wait()
    switch out! { case .success(let v): return v; case .failure(let e): die("error: \(e.localizedDescription)") }
}

// MARK: - split: each audio track → its own .m4a

func split(_ inPath: String) {
    let asset = AVURLAsset(url: URL(fileURLWithPath: inPath))
    let audioTracks = sync { try await asset.loadTracks(withMediaType: .audio) }
    guard !audioTracks.isEmpty else { die("no audio tracks in \(inPath)") }
    let duration = sync { try await asset.load(.duration) }
    let stem = (inPath as NSString).deletingPathExtension
    // The recorder writes system audio first, mic second (see screen-audio-record setupWriter).
    let labels = ["system", "mic"]
    for (i, track) in audioTracks.enumerated() {
        let label = i < labels.count ? labels[i] : "audio\(i + 1)"
        let outPath = "\(stem)-\(label).m4a"
        exportOneTrack(track, duration: duration, to: outPath)
        print("✓ \(outPath)")
    }
    if audioTracks.count == 1 {
        FileHandle.standardError.write("note: only one audio track (no mic was recorded) — just \(stem)-system.m4a\n".data(using: .utf8)!)
    }
}

func exportOneTrack(_ track: AVAssetTrack, duration: CMTime, to outPath: String) {
    let comp = AVMutableComposition()
    guard let ct = comp.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else { die("composition track") }
    do { try ct.insertTimeRange(CMTimeRange(start: .zero, duration: duration), of: track, at: .zero) }
    catch { die("insert audio: \(error.localizedDescription)") }
    let out = URL(fileURLWithPath: outPath)
    try? FileManager.default.removeItem(at: out)
    guard let export = AVAssetExportSession(asset: comp, presetName: AVAssetExportPresetAppleM4A) else { die("export session") }

    // Version-safe export. The modern export(to:as:) is macOS 15+ only; the
    // outputURL/exportAsynchronously/status path is deprecated on 15 but is the only
    // option on macOS 13–14 (Ventura/Sonoma) and still works. #available picks at runtime;
    // compiling with MACOSX_DEPLOYMENT_TARGET=13.0 lets the binary RUN on Ventura+ and also
    // silences the deprecation warning (the API isn't deprecated at that deployment target).
    if #available(macOS 15.0, *) {
        sync { try await export.export(to: out, as: .m4a) }
    } else {
        export.outputURL = out
        export.outputFileType = .m4a
        let sem = DispatchSemaphore(value: 0)
        export.exportAsynchronously { sem.signal() }
        sem.wait()
        if export.status != .completed { die("export failed: \(export.error?.localizedDescription ?? "unknown")") }
    }
}

// MARK: - loudness: measure, then normalise
//
// A screencast is mixed from two very different sources: app audio that was already
// mastered, and a microphone a metre from your face. The result is usually far too quiet —
// you deliver a video the viewer has to reach for the volume knob for. So before the
// flattened .mov is handed on (and therefore before subtitles are burned into it), measure
// the mixed track and apply one gain to the whole thing.
//
// Deliberately ONE constant gain for the entire recording, not compression or per-moment
// AGC: constant gain cannot pump, cannot breathe, and cannot change the balance between
// your voice and the app — it only moves the whole thing up. The quiet-to-loud dynamics of
// the take survive exactly as recorded.

struct Levels {
    var peak: Double      // 0…1, absolute maximum sample
    var rms: Double       // 0…1, root-mean-square over the whole recording
    var samples: Int
    // Amplitude histogram, so we can ask "how loud is all but the top 0.1%?". The absolute
    // peak is a single sample and a terrible basis for a decision: one click, one pop, one
    // genuinely clipped moment pins it at 0 dBFS and then peak-normalisation refuses to
    // raise a recording that is inaudibly quiet everywhere else.
    var hist: [Int] = []  // 4096 bins over |sample| 0…1
    var blocks: [Double] = []   // RMS of each ~400ms block, for GATED loudness

    /// Gated loudness, in the spirit of EBU R128: the level of the material that is
    /// actually PLAYING, with silence and near-silence excluded.
    ///
    /// This matters more than any other number here. A screencast is mostly pauses — this
    /// file's median sample sits at -51.8 dBFS — so plain whole-file RMS mostly measures
    /// the silence between sentences and reports "very quiet" for a recording whose speech
    /// is fine. Gate the quiet blocks out and you get the loudness a listener perceives.
    var gated: Double {
        let loud = blocks.filter { $0 > 0.001 }            // absolute gate ≈ -60 dBFS
        guard !loud.isEmpty else { return rms }
        let mean1 = (loud.map { $0 * $0 }.reduce(0, +) / Double(loud.count)).squareRoot()
        let rel = mean1 * pow(10.0, -10.0 / 20.0)          // relative gate: -10 dB below that
        let kept = loud.filter { $0 >= rel }
        guard !kept.isEmpty else { return mean1 }
        return (kept.map { $0 * $0 }.reduce(0, +) / Double(kept.count)).squareRoot()
    }

    /// Amplitude below which `q` of all samples fall (0…1).
    func percentile(_ q: Double) -> Double {
        guard !hist.isEmpty, samples > 0 else { return peak }
        let want = Int(Double(samples) * q)
        var seen = 0
        for (i, c) in hist.enumerated() {
            seen += c
            if seen >= want { return (Double(i) + 0.5) / Double(hist.count) }
        }
        return peak
    }

    func db(_ a: Double) -> Double { a > 0 ? 20 * log10(a) : -.infinity }
    var peakDb: Double { peak > 0 ? 20 * log10(peak) : -.infinity }
    var rmsDb: Double { rms > 0 ? 20 * log10(rms) : -.infinity }

    var gatedDb: Double { gated > 0 ? 20 * log10(gated) : -.infinity }

    var describe: String {
        func f(_ d: Double) -> String { d.isFinite ? String(format: "%.1f dBFS", d) : "silence" }
        return "loudness \(f(gatedDb)) (gated) · peak \(f(peakDb)) · RMS \(f(rmsDb)) (whole file)"
    }
}

/// Targets. -1 dBFS of peak headroom is the usual "loud but never clipping" ceiling, and
/// -18 dBFS RMS is a comfortable spoken-word level. Whichever target is reached FIRST wins,
/// so a recording with one loud spike is lifted only as far as that spike allows.
let targetPeakDb = -1.0
let targetLoudnessDb = -18.0
let maxBoostDb = 30.0     // refuse to lift hiss out of an essentially silent recording

func gainFor(_ l: Levels) -> Double {
    guard l.peak > 0, l.gated > 0 else { return 1.0 }
    // Aim at the loudness target…
    let byLoudness = pow(10.0, (targetLoudnessDb - l.gatedDb) / 20.0)
    // …but don't ask the limiter to do more than polish the very top: cap the gain so the
    // 99.9th-percentile sample still lands at or under the ceiling. Everything above that
    // — 0.1% of samples, the transients and the stray click — is what gets limited.
    let p999 = l.percentile(0.999)
    let byHeadroom = p999 > 0 ? pow(10.0, (targetPeakDb - 20 * log10(p999)) / 20.0) : .infinity
    let g = min(byLoudness, byHeadroom)
    return min(g, pow(10.0, maxBoostDb / 20.0))
}

/// Soft-knee limiter. Above the KNEE, amplitude is compressed smoothly into the space
/// between the knee and the CEILING instead of being clipped flat — the difference between
/// "loud" and "buzzy". Sample-wise and stateless on purpose: no attack/release means
/// nothing pumps or breathes.
///
/// The knee and the ceiling are different numbers, and conflating them was a real bug here:
/// mapping overs with tanh into [knee, 1.0] let the output reach 0.0 dBFS while the tool
/// printed "ceiling -1 dBFS". Caught by measuring the tool's OWN output — the claim was
/// false, and true-peak overshoot after AAC encoding is exactly how a "normalised" file
/// ends up clipping in someone's player.
@inline(__always)
func softLimit(_ x: Double, ceiling: Double, knee: Double) -> Double {
    let a = abs(x)
    if a <= knee { return x }
    let head = ceiling - knee
    guard head > 0 else { return x < 0 ? -ceiling : ceiling }
    let shaped = knee + head * tanh((a - knee) / head)   // → ceiling asymptotically, never past
    return x < 0 ? -shaped : shaped
}

func dbString(_ gain: Double) -> String {
    let db = 20 * log10(gain)
    return String(format: "%+.1f dB", db)
}

/// Read the mixed audio once and report its levels. Audio-only decode — no video is touched.
func measureLevels(_ asset: AVURLAsset, _ audioTracks: [AVAssetTrack], _ mix: AVAudioMix?) -> Levels {
    guard let reader = try? AVAssetReader(asset: asset) else { die("level reader") }
    let out = AVAssetReaderAudioMixOutput(audioTracks: audioTracks, audioSettings: pcmSettings)
    out.audioMix = mix
    guard reader.canAdd(out) else { die("cannot add level output") }
    reader.add(out)
    guard reader.startReading() else { die("level read: \(reader.error?.localizedDescription ?? "unknown")") }

    var peak = 0.0, sumSq = 0.0
    var n = 0
    let bins = 4096
    var hist = [Int](repeating: 0, count: bins)
    // ~400ms blocks at 48kHz stereo, the EBU R128 block size.
    let blockSamples = 48_000 * 2 * 4 / 10
    var blocks: [Double] = []
    var blockSumSq = 0.0, blockN = 0
    while let sb = out.copyNextSampleBuffer() {
        guard let bb = CMSampleBufferGetDataBuffer(sb) else { continue }
        var length = 0
        var ptr: UnsafeMutablePointer<Int8>?
        guard CMBlockBufferGetDataPointer(bb, atOffset: 0, lengthAtOffsetOut: nil,
                                          totalLengthOut: &length, dataPointerOut: &ptr) == kCMBlockBufferNoErr,
              let raw = ptr, length > 1 else { continue }
        raw.withMemoryRebound(to: Int16.self, capacity: length / 2) { p in
            for i in 0..<(length / 2) {
                let v = Double(p[i]) / 32768.0
                let a = abs(v)
                if a > peak { peak = a }
                sumSq += v * v
                n += 1
                let b = min(bins - 1, Int(a * Double(bins)))
                hist[b] += 1
                blockSumSq += v * v
                blockN += 1
                if blockN >= blockSamples {
                    blocks.append((blockSumSq / Double(blockN)).squareRoot())
                    blockSumSq = 0; blockN = 0
                }
            }
        }
    }
    if reader.status == .failed { die("level read failed: \(reader.error?.localizedDescription ?? "unknown")") }
    if blockN > 0 { blocks.append((blockSumSq / Double(blockN)).squareRoot()) }
    return Levels(peak: peak, rms: n > 0 ? (sumSq / Double(n)).squareRoot() : 0, samples: n,
                  hist: hist, blocks: blocks)
}

/// How many samples the limiter actually had to touch — reported at the end, because
/// "I boosted this a lot" and "I squashed 4% of your audio" are different facts.
final class LimitCount { var limited = 0; var total = 0 }
let limitStats = LimitCount()

/// Scale 16-bit PCM in place, soft-limiting anything that would exceed the ceiling.
func applyGain(_ sb: CMSampleBuffer, _ gain: Double) {
    guard gain != 1.0, let bb = CMSampleBufferGetDataBuffer(sb) else { return }
    guard CMBlockBufferAssureBlockMemory(bb) == kCMBlockBufferNoErr else { return }
    var length = 0
    var ptr: UnsafeMutablePointer<Int8>?
    guard CMBlockBufferGetDataPointer(bb, atOffset: 0, lengthAtOffsetOut: nil,
                                      totalLengthOut: &length, dataPointerOut: &ptr) == kCMBlockBufferNoErr,
          let raw = ptr, length > 1 else { return }
    let g = gain
    let ceiling = pow(10.0, targetPeakDb / 20.0)
    let knee = pow(10.0, (targetPeakDb - 5.0) / 20.0)     // start shaping 5 dB below the ceiling
    raw.withMemoryRebound(to: Int16.self, capacity: length / 2) { p in
        for i in 0..<(length / 2) {
            let v = (Double(p[i]) / 32768.0) * g
            if abs(v) > knee { limitStats.limited += 1 }
            let y = softLimit(v, ceiling: ceiling, knee: knee)
            p[i] = Int16(max(-32768.0, min(32767.0, (y * 32768.0).rounded())))
        }
        limitStats.total += length / 2
    }
}

let pcmSettings: [String: Any] = [
    AVFormatIDKey: kAudioFormatLinearPCM,
    AVSampleRateKey: 48_000,
    AVNumberOfChannelsKey: 2,
    AVLinearPCMBitDepthKey: 16,
    AVLinearPCMIsFloatKey: false,
    AVLinearPCMIsBigEndianKey: false,
    AVLinearPCMIsNonInterleaved: false,
]

// MARK: - flatten: mix all audio tracks into one, keep video (passthrough)

func flatten(_ inPath: String, _ outArg: String?, normalize: Bool = true) {
    let asset = AVURLAsset(url: URL(fileURLWithPath: inPath))
    let videoTracks = sync { try await asset.loadTracks(withMediaType: .video) }
    let audioTracks = sync { try await asset.loadTracks(withMediaType: .audio) }
    guard let vTrack = videoTracks.first else { die("no video track in \(inPath)") }
    guard !audioTracks.isEmpty else { die("no audio tracks in \(inPath)") }

    let outPath = outArg ?? "\((inPath as NSString).deletingPathExtension)-flat.mov"
    let out = URL(fileURLWithPath: outPath)
    try? FileManager.default.removeItem(at: out)

    guard let reader = try? AVAssetReader(asset: asset) else { die("reader") }
    // AVAssetReaderAudioMixOutput SUMS multiple audio tracks into one PCM stream.
    let audioOut = AVAssetReaderAudioMixOutput(audioTracks: audioTracks, audioSettings: pcmSettings)
    // Attenuate each source a touch when there's more than one, so a loud moment on both
    // (voice + app sound at once) doesn't clip the summed track. Normalisation afterwards
    // gives this headroom straight back, so it costs nothing in the delivered loudness.
    var mix: AVAudioMix?
    if audioTracks.count > 1 {
        let m = AVMutableAudioMix()
        m.inputParameters = audioTracks.map { t in
            let p = AVMutableAudioMixInputParameters(track: t)
            p.setVolume(0.8, at: .zero)
            return p
        }
        mix = m
        audioOut.audioMix = m
    }

    // Measure BEFORE writing anything: the gain has to be known for the first sample.
    var gain = 1.0
    if normalize {
        FileHandle.standardError.write("⧗ measuring loudness…\n".data(using: .utf8)!)
        let lv = measureLevels(asset, audioTracks, mix)
        gain = gainFor(lv)
        print("🔊 audio in : \(lv.describe)")
        if abs(20 * log10(gain)) < 0.1 {
            print("🔊 audio out: already at target — no gain applied")
        } else {
            print("🔊 gain     : \(dbString(gain))  (target loudness \(Int(targetLoudnessDb)) dBFS, ceiling \(Int(targetPeakDb)) dBFS)")
            print(String(format: "🔊 expected : loudness %.1f dBFS after gain", lv.gatedDb + 20 * log10(gain)))
        }
    }
    guard reader.canAdd(audioOut) else { die("cannot add audio mix output") }
    reader.add(audioOut)

    let videoOut = AVAssetReaderTrackOutput(track: vTrack, outputSettings: nil)  // nil = passthrough (no re-decode)
    videoOut.alwaysCopiesSampleData = false
    guard reader.canAdd(videoOut) else { die("cannot add video output") }
    reader.add(videoOut)

    guard let writer = try? AVAssetWriter(outputURL: out, fileType: .mov) else { die("writer") }
    let vFmt = sync { try await vTrack.load(.formatDescriptions) }.first
    let vIn = AVAssetWriterInput(mediaType: .video, outputSettings: nil, sourceFormatHint: vFmt)  // passthrough
    vIn.expectsMediaDataInRealTime = false
    vIn.transform = sync { try await vTrack.load(.preferredTransform) }
    guard writer.canAdd(vIn) else { die("cannot add video input") }
    writer.add(vIn)

    let aSettings: [String: Any] = [
        AVFormatIDKey: kAudioFormatMPEG4AAC,
        AVNumberOfChannelsKey: 2,
        AVSampleRateKey: 48_000,
        AVEncoderBitRateKey: 192_000,
    ]
    let aIn = AVAssetWriterInput(mediaType: .audio, outputSettings: aSettings)
    aIn.expectsMediaDataInRealTime = false
    guard writer.canAdd(aIn) else { die("cannot add audio input") }
    writer.add(aIn)

    guard writer.startWriting() else { die("startWriting: \(writer.error?.localizedDescription ?? "unknown")") }
    guard reader.startReading() else { die("startReading: \(reader.error?.localizedDescription ?? "unknown")") }
    writer.startSession(atSourceTime: .zero)

    let group = DispatchGroup()
    group.enter()
    vIn.requestMediaDataWhenReady(on: DispatchQueue(label: "flatten.v")) {
        while vIn.isReadyForMoreMediaData {
            if let sb = videoOut.copyNextSampleBuffer() { vIn.append(sb) }
            else { vIn.markAsFinished(); group.leave(); break }
        }
    }
    group.enter()
    aIn.requestMediaDataWhenReady(on: DispatchQueue(label: "flatten.a")) {
        while aIn.isReadyForMoreMediaData {
            if let sb = audioOut.copyNextSampleBuffer() {
                applyGain(sb, gain)
                aIn.append(sb)
            }
            else { aIn.markAsFinished(); group.leave(); break }
        }
    }
    group.wait()

    if reader.status == .failed { die("read failed: \(reader.error?.localizedDescription ?? "unknown")") }
    let sem = DispatchSemaphore(value: 0)
    writer.finishWriting { sem.signal() }
    sem.wait()
    if writer.status != .completed { die("write failed: \(writer.error?.localizedDescription ?? "unknown")") }
    if normalize && limitStats.total > 0 && limitStats.limited > 0 {
        let pct = 100.0 * Double(limitStats.limited) / Double(limitStats.total)
        print(String(format: "🔊 limiter  : shaped %.3f%% of samples (the transients above the ceiling)", pct))
    }
    print("✓ \(outPath)")
}

// MARK: - level: just report, change nothing

func level(_ inPath: String) {
    let asset = AVURLAsset(url: URL(fileURLWithPath: inPath))
    let audioTracks = sync { try await asset.loadTracks(withMediaType: .audio) }
    guard !audioTracks.isEmpty else { die("no audio tracks in \(inPath)") }
    var mix: AVAudioMix?
    if audioTracks.count > 1 {
        let m = AVMutableAudioMix()
        m.inputParameters = audioTracks.map { t in
            let p = AVMutableAudioMixInputParameters(track: t)
            p.setVolume(0.8, at: .zero)
            return p
        }
        mix = m
    }
    let lv = measureLevels(asset, audioTracks, mix)
    let g = gainFor(lv)
    print("\((inPath as NSString).lastPathComponent)")
    print("  tracks : \(audioTracks.count)")
    print("  levels : \(lv.describe)")
    let pcts = [0.5, 0.9, 0.99, 0.999, 0.9999]
    let parts = pcts.map { q -> String in
        String(format: "p%@ %.1f", q == 0.5 ? "50" : (q == 0.9 ? "90" : (q == 0.99 ? "99" : (q == 0.999 ? "99.9" : "99.99"))),
               lv.db(lv.percentile(q)))
    }
    print("  spread : " + parts.joined(separator: " · ") + " dBFS")
    let overs = 1.0 - Double(lv.hist.prefix(max(0, Int(pow(10.0, targetPeakDb / 20.0) * Double(lv.hist.count) / g))).reduce(0, +)) / Double(max(1, lv.samples))
    print("  normalise: \(dbString(g)) → loudness \(String(format: "%.1f", lv.gatedDb + 20 * log10(g))) dBFS "
          + String(format: "(limiter would shape ~%.3f%% of samples)", max(0, overs) * 100))
}

// MARK: - main

let args = Array(CommandLine.arguments.dropFirst())
guard let mode = args.first else {
    die("""
    usage:
      rec-audio split   <recording.mov>            → <stem>-system.m4a + <stem>-mic.m4a
      rec-audio flatten <recording.mov> [-o out]   → <stem>-flat.mov (video + one mixed track,
                                                      loudness-normalised; --no-normalize opts out)
      rec-audio level   <video.mov>                → report peak/RMS and the gain it would apply
      rec-audio normalize <video.mov> [-o out]     → <stem>-loud.mov: SAME video (passthrough,
                                                      no re-encode), audio normalised
    """)
}
switch mode {
case "split":
    guard args.count >= 2 else { die("rec-audio split <recording.mov>") }
    split(args[1])
case "flatten":
    guard args.count >= 2 else { die("rec-audio flatten <recording.mov> [-o out.mov]") }
    var outArg: String? = nil
    if let i = args.firstIndex(of: "-o"), i + 1 < args.count { outArg = (args[i + 1] as NSString).expandingTildeInPath }
    flatten(args[1], outArg, normalize: !args.contains("--no-normalize"))
case "level":
    guard args.count >= 2 else { die("rec-audio level <video.mov>") }
    level(args[1])
case "normalize", "normalise":
    // Same machinery as flatten — a single already-mixed track is just the one-track case.
    guard args.count >= 2 else { die("rec-audio normalize <video.mov> [-o out.mov]") }
    var outArg: String? = nil
    if let i = args.firstIndex(of: "-o"), i + 1 < args.count { outArg = (args[i + 1] as NSString).expandingTildeInPath }
    flatten(args[1], outArg ?? "\((args[1] as NSString).deletingPathExtension)-loud.mov", normalize: true)
default:
    die("unknown mode \"\(mode)\" — use split, flatten, level or normalize")
}
