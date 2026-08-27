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

// MARK: - rebalance: make the VOICE audible against the app audio
//
// Normalisation (above) moves the whole mix up together. It cannot fix the failure that
// actually ruins a screencast: the microphone is a metre from your face and the app audio
// was mastered to full scale, so the two arrive ~25 dB apart and one constant gain moves
// BOTH of them, preserving the imbalance exactly.
//
// Measured on Esa's 2026-08-27 Renoise walkthrough:
//     system audio   -9.2 LUFS   true peak +0.5 dBTP (already clipped)
//     microphone    -35.3 LUFS   true peak -10.6 dBTP
// The narration was 26 dB under the wavetable demo. The delivered file was correctly
// normalised and the voice was still inaudible.
//
// So before the sum, the two tracks are treated as what they are — a VOICE and a BED:
//
//   mic : high-pass (kill desk rumble, it only eats headroom)
//         → one measured gain
//         → soft-knee compressor that touches ONLY the transients, so the boost doesn't
//           have to be limited away and nothing buzzes
//   sys : ducked by the mic — pulled down a fixed, known depth WHILE you are speaking and
//         returned to full level in the gaps, so the demo audio keeps its impact
//
// Every number is measured from this recording, not typed in: the mic gain is whatever it
// takes to land the voice `voiceLead` dB above the ducked bed, and the "is he speaking"
// threshold is derived from the mic's own gated loudness. Nothing here is tuned to one file.

struct BalanceParams {
    var voiceLeadDb = 1.5          // how far the voice sits ABOVE the ducked app audio
    var duckDepthDb = 7.0          // how far the app audio drops while you're talking
    var micHighPassHz = 75.0
    var micCompThresholdDb = -14.0 // only the transients — the body of the voice is untouched
    var micCompRatio = 4.0
    var micCompKneeDb = 6.0
    var micCompAttackMs = 10.0
    var micCompReleaseMs = 250.0
    var duckAttackMs = 20.0        // duck fast enough to catch the first word
    var duckReleaseMs = 400.0      // come back slowly, so it doesn't chatter between words
    var micCeilingDb = -3.0        // fast soft ceiling on the boosted voice, so a plosive or a
                                   // keyboard click can't arrive at the sum 10 dB over full scale
    var speechGateBelowGatedDb = 6.0   // "speaking" = mic envelope within 6 dB of its own gated
                                   // loudness. Not lower: in a tracker walkthrough the mic also
                                   // hears the KEYBOARD, and a gate loose enough to count typing
                                   // as speech leaves the app audio ducked for the whole video —
                                   // measured 99% at -12 dB, which is a static cut wearing a
                                   // ducker's clothes.
    var maxMicBoostDb = 30.0       // never lift pure hiss out of a dead microphone
}

/// Direct-form-I biquad. Used for one thing here: a 75 Hz high-pass on the mic.
struct Biquad {
    var b0 = 1.0, b1 = 0.0, b2 = 0.0, a1 = 0.0, a2 = 0.0
    var x1 = 0.0, x2 = 0.0, y1 = 0.0, y2 = 0.0
    static func highPass(_ f: Double, _ sr: Double, q: Double = 0.70710678) -> Biquad {
        let w = 2 * Double.pi * f / sr, cw = cos(w), alpha = sin(w) / (2 * q)
        let a0 = 1 + alpha
        var b = Biquad()
        b.b0 = ((1 + cw) / 2) / a0; b.b1 = (-(1 + cw)) / a0; b.b2 = ((1 + cw) / 2) / a0
        b.a1 = (-2 * cw) / a0;      b.a2 = (1 - alpha) / a0
        return b
    }
    mutating func process(_ x: Double) -> Double {
        let y = b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
        x2 = x1; x1 = x; y2 = y1; y1 = y
        return y
    }
}

/// Asymmetric one-pole follower: rises at `attack`, falls at `release`.
struct Follower {
    private let att: Double, rel: Double
    var v = 0.0
    init(attackMs: Double, releaseMs: Double, sr: Double) {
        att = exp(-1.0 / max(1e-6, attackMs / 1000 * sr))
        rel = exp(-1.0 / max(1e-6, releaseMs / 1000 * sr))
    }
    mutating func process(_ a: Double) -> Double {
        let c = a > v ? att : rel
        v = c * v + (1 - c) * a
        return v
    }
}

/// Same shape, but for a GAIN: moving DOWN is the attack (duck fast), moving UP the release.
struct GainSmoother {
    private let down: Double, up: Double
    var v = 1.0
    init(attackMs: Double, releaseMs: Double, sr: Double) {
        down = exp(-1.0 / max(1e-6, attackMs / 1000 * sr))
        up   = exp(-1.0 / max(1e-6, releaseMs / 1000 * sr))
    }
    mutating func process(_ target: Double) -> Double {
        let c = target < v ? down : up
        v = c * v + (1 - c) * target
        return v
    }
}

/// Soft-knee static compressor curve: returns the gain change in dB (≤ 0) for an input level.
func compressorGainDb(_ envDb: Double, threshold: Double, ratio: Double, knee: Double) -> Double {
    let over = envDb - threshold
    let outDb: Double
    if over < -knee / 2 { outDb = envDb }
    else if over <= knee / 2 { outDb = envDb + (1 / ratio - 1) * pow(over + knee / 2, 2) / (2 * knee) }
    else { outDb = threshold + over / ratio }
    return outDb - envDb
}

/// Pulls one audio track out of a reader as an ABSOLUTE-TIMELINE stream of frames.
///
/// This is the part that is easy to get wrong. The two tracks in a `rec` capture do NOT
/// start at the same instant — on the 2026-08-27 recording the system track starts at
/// 0.119 s and the mic at 0.2996 s, because ScreenCaptureKit and the mic tap begin
/// independently. Anything that just concatenates decoded packets puts the voice ~180 ms
/// out of place. So every sample buffer's PTS is converted to an absolute frame index and
/// the gaps are filled with silence: frame 0 of this reader is frame 0 of the video.
final class TimelineTrackReader {
    private let out: AVAssetReaderTrackOutput
    private var pending: [Int16] = []   // interleaved stereo, from `pendingStart`
    private var head = 0                // consumed frames at the front of `pending`
    private var pendingStart = 0        // absolute frame index of pending[head]
    private var started = false
    private var done = false
    private let sr: Double

    init(track: AVAssetTrack, reader: AVAssetReader, sampleRate: Double = 48_000) {
        out = AVAssetReaderTrackOutput(track: track, outputSettings: pcmSettings)
        out.alwaysCopiesSampleData = false
        sr = sampleRate
        guard reader.canAdd(out) else { die("cannot add track output") }
        reader.add(out)
    }

    private func pull() {
        guard !done else { return }
        guard let sb = out.copyNextSampleBuffer() else { done = true; return }
        let pts = CMSampleBufferGetPresentationTimeStamp(sb)
        let absFrame = Int((CMTimeGetSeconds(pts) * sr).rounded())
        guard let bb = CMSampleBufferGetDataBuffer(sb) else { return }
        var length = 0
        var ptr: UnsafeMutablePointer<Int8>?
        guard CMBlockBufferGetDataPointer(bb, atOffset: 0, lengthAtOffsetOut: nil,
                                          totalLengthOut: &length, dataPointerOut: &ptr) == kCMBlockBufferNoErr,
              let raw = ptr, length > 1 else { return }
        if !started { pendingStart = absFrame; started = true }
        // Silence-fill any gap between where we are and where this buffer says it belongs.
        let writeAt = pendingStart + (pending.count - head) / 2
        if absFrame > writeAt { pending.append(contentsOf: [Int16](repeating: 0, count: (absFrame - writeAt) * 2)) }
        raw.withMemoryRebound(to: Int16.self, capacity: length / 2) { p in
            pending.append(contentsOf: UnsafeBufferPointer(start: p, count: length / 2))
        }
    }

    /// Frames [pos, pos+frames) as interleaved doubles in -1…1. Anything before this track
    /// starts, after it ends, or missing in the middle reads as silence.
    func read(pos: Int, frames: Int, into dest: inout [Double]) {
        while !done && (!started || pendingStart + (pending.count - head) / 2 < pos + frames) { pull() }
        // Drop everything before `pos` (the caller only ever moves forward).
        if started && pos > pendingStart {
            let drop = min((pending.count - head) / 2, pos - pendingStart)
            head += drop * 2
            pendingStart += drop
            if head > 1 << 20 { pending.removeFirst(head); head = 0 }
        }
        let lead = started ? max(0, pendingStart - pos) : frames   // silence before the track begins
        for i in 0..<(frames * 2) { dest[i] = 0 }
        guard started, lead < frames else { return }
        let avail = min(frames - lead, (pending.count - head) / 2)
        guard avail > 0 else { return }
        for f in 0..<avail {
            let s = head + f * 2
            dest[(lead + f) * 2]     = Double(pending[s])     / 32768.0
            dest[(lead + f) * 2 + 1] = Double(pending[s + 1]) / 32768.0
        }
    }
}

struct RebalancePlan {
    var sysGatedDb: Double
    var micGatedDb: Double
    var micGainDb: Double
    var speechThreshold: Double   // linear, against the POST-gain mic envelope
    var params: BalanceParams

    var describe: String {
        String(format: "app %.1f dBFS · mic %.1f dBFS (%.1f dB apart) → mic %+.1f dB, app ducks %.0f dB while you speak",
               sysGatedDb, micGatedDb, sysGatedDb - micGatedDb, micGainDb, params.duckDepthDb)
    }
}

/// The whole balance decision, as arithmetic on two measured numbers — kept separate from
/// the decoding so `--self-test` can assert it.
///
/// Land the voice `voiceLead` dB above where the bed will BE once it has ducked. Never
/// attenuate the mic (if the voice is already on top, leave the take alone) and never boost
/// past `maxMicBoost` (a dead microphone is hiss, and hiss lifted 40 dB is still hiss).
func micGainDb(sysGatedDb: Double, micGatedDb: Double, _ p: BalanceParams) -> Double {
    let want = (sysGatedDb - p.duckDepthDb + p.voiceLeadDb) - micGatedDb
    guard want.isFinite else { return 0 }
    return max(0.0, min(p.maxMicBoostDb, want))
}

func planRebalance(_ asset: AVURLAsset, system: AVAssetTrack, mic: AVAssetTrack, _ p: BalanceParams) -> RebalancePlan {
    let sys = measureLevels(asset, [system], nil)
    let m   = measureLevels(asset, [mic], nil)
    let gainDb = micGainDb(sysGatedDb: sys.gatedDb, micGatedDb: m.gatedDb, p)
    let thr = pow(10.0, (m.gatedDb + gainDb - p.speechGateBelowGatedDb) / 20.0)
    return RebalancePlan(sysGatedDb: sys.gatedDb, micGatedDb: m.gatedDb,
                         micGainDb: gainDb, speechThreshold: thr, params: p)
}

/// The two-track mix, pulled a chunk at a time so the caller can either MEASURE it or WRITE it.
/// Both passes must run the identical chain, or the normaliser's gain is computed against
/// audio that isn't what gets written.
final class RebalancedMixer {
    private let reader: AVAssetReader
    private let sysR: TimelineTrackReader
    private let micR: TimelineTrackReader
    private var sysBuf: [Double], micBuf: [Double]
    private var pos = 0
    private let total: Int
    private let plan: RebalancePlan
    private let p: BalanceParams
    private let micGain: Double
    private let duckFloor: Double
    private let micCeiling: Double
    private let micKnee: Double
    private var hpL: Biquad, hpR: Biquad
    private var micEnv: Follower
    private var compEnv: Follower
    private var duckKey: Follower
    private var duckGain: GainSmoother
    /// Reported afterwards, because "I boosted the mic 21 dB" and "the app audio spent 40% of
    /// the video ducked" are both things you want to know without listening to the whole thing.
    private(set) var duckedFrames = 0
    private(set) var duckGainSum = 0.0
    private(set) var frames = 0
    /// Mean duck depth in dB over the whole recording — the honest summary of what the
    /// ducker DID, as opposed to how often it was nominally engaged.
    var meanDuckDb: Double { frames > 0 ? 20 * log10(duckGainSum / Double(frames)) : 0 }

    static let chunk = 4800   // 100 ms

    init(asset: AVURLAsset, system: AVAssetTrack, mic: AVAssetTrack, plan: RebalancePlan, totalFrames: Int) {
        guard let r = try? AVAssetReader(asset: asset) else { die("rebalance reader") }
        reader = r
        sysR = TimelineTrackReader(track: system, reader: r)
        micR = TimelineTrackReader(track: mic, reader: r)
        self.plan = plan
        self.p = plan.params
        total = totalFrames
        micGain = pow(10.0, plan.micGainDb / 20.0)
        duckFloor = pow(10.0, -p.duckDepthDb / 20.0)
        micCeiling = pow(10.0, p.micCeilingDb / 20.0)
        micKnee = pow(10.0, (p.micCeilingDb - 5.0) / 20.0)
        let sr = 48_000.0
        hpL = Biquad.highPass(p.micHighPassHz, sr); hpR = hpL
        micEnv = Follower(attackMs: 1, releaseMs: 50, sr: sr)
        compEnv = Follower(attackMs: p.micCompAttackMs, releaseMs: p.micCompReleaseMs, sr: sr)
        duckKey = Follower(attackMs: 5, releaseMs: 120, sr: sr)
        duckGain = GainSmoother(attackMs: p.duckAttackMs, releaseMs: p.duckReleaseMs, sr: sr)
        sysBuf = [Double](repeating: 0, count: RebalancedMixer.chunk * 2)
        micBuf = [Double](repeating: 0, count: RebalancedMixer.chunk * 2)
        guard reader.startReading() else { die("rebalance read: \(reader.error?.localizedDescription ?? "unknown")") }
    }

    /// Next chunk of the finished mix (interleaved stereo, -1…1), or nil at the end.
    /// `startFrame` is the absolute frame index of the first frame returned.
    func next() -> (pcm: [Double], startFrame: Int, frames: Int)? {
        guard pos < total else { return nil }
        let n = min(RebalancedMixer.chunk, total - pos)
        sysR.read(pos: pos, frames: n, into: &sysBuf)
        micR.read(pos: pos, frames: n, into: &micBuf)
        var out = [Double](repeating: 0, count: n * 2)
        for f in 0..<n {
            // --- microphone: high-pass → measured gain → transient-only compression
            var l = hpL.process(micBuf[f * 2])     * micGain
            var r = hpR.process(micBuf[f * 2 + 1]) * micGain
            let a = max(abs(l), abs(r))
            let e = compEnv.process(a)
            if e > 0 {
                let gdb = compressorGainDb(20 * log10(e), threshold: p.micCompThresholdDb,
                                           ratio: p.micCompRatio, knee: p.micCompKneeDb)
                if gdb < 0 { let g = pow(10.0, gdb / 20.0); l *= g; r *= g }
            }
            // A stateless soft ceiling, not a lookahead limiter: the compressor's 10 ms attack
            // deliberately lets transients through (that is what keeps speech sounding like
            // speech), and this stops those transients reaching the sum at +10 dBFS.
            l = softLimit(l, ceiling: micCeiling, knee: micKnee)
            r = softLimit(r, ceiling: micCeiling, knee: micKnee)
            // --- app audio: ducked while the voice is present
            let key = duckKey.process(max(abs(l), abs(r)))
            let target = key > plan.speechThreshold ? duckFloor : 1.0
            let dg = duckGain.process(target)
            if dg < 0.999 { duckedFrames += 1 }
            duckGainSum += dg
            // 0.8 on each source is headroom for the moment BOTH are loud; the normaliser
            // hands it straight back, so it costs nothing in delivered loudness.
            out[f * 2]     = l * 0.8 + sysBuf[f * 2]     * dg * 0.8
            out[f * 2 + 1] = r * 0.8 + sysBuf[f * 2 + 1] * dg * 0.8
            _ = micEnv
        }
        let start = pos
        pos += n
        frames += n
        return (out, start, n)
    }
}

/// Accumulate `Levels` from the doubles the mixer produces (same statistics as measureLevels).
final class LevelAccumulator {
    private var peak = 0.0, sumSq = 0.0, n = 0
    private let bins = 4096
    private var hist: [Int]
    private var blocks: [Double] = []
    private var blockSumSq = 0.0, blockN = 0
    private let blockSamples = 48_000 * 2 * 4 / 10
    init() { hist = [Int](repeating: 0, count: bins) }
    func add(_ buf: [Double], count: Int) {
        for i in 0..<count {
            let v = buf[i], a = abs(v)
            if a > peak { peak = a }
            sumSq += v * v; n += 1
            hist[min(bins - 1, Int(a * Double(bins)))] += 1
            blockSumSq += v * v; blockN += 1
            if blockN >= blockSamples { blocks.append((blockSumSq / Double(blockN)).squareRoot()); blockSumSq = 0; blockN = 0 }
        }
    }
    func finish() -> Levels {
        if blockN > 0 { blocks.append((blockSumSq / Double(blockN)).squareRoot()) }
        return Levels(peak: peak, rms: n > 0 ? (sumSq / Double(n)).squareRoot() : 0, samples: n, hist: hist, blocks: blocks)
    }
}

/// Wrap finished PCM in a CMSampleBuffer stamped at an exact frame position.
/// Building these by hand (instead of reusing a decoded buffer as a carrier) is what makes
/// the output start at frame 0 with the two tracks in their true relative places.
func makeAudioSampleBuffer(_ pcm: [Int16], frames: Int, startFrame: Int, format: CMAudioFormatDescription) -> CMSampleBuffer? {
    let bytes = frames * 2 * MemoryLayout<Int16>.size
    guard let mem = malloc(bytes) else { return nil }
    pcm.withUnsafeBytes { _ = memcpy(mem, $0.baseAddress!, bytes) }
    var bb: CMBlockBuffer?
    guard CMBlockBufferCreateWithMemoryBlock(allocator: kCFAllocatorDefault, memoryBlock: mem,
                                             blockLength: bytes, blockAllocator: kCFAllocatorMalloc,
                                             customBlockSource: nil, offsetToData: 0, dataLength: bytes,
                                             flags: 0, blockBufferOut: &bb) == kCMBlockBufferNoErr,
          let block = bb else { free(mem); return nil }
    var sb: CMSampleBuffer?
    var timing = CMSampleTimingInfo(duration: CMTime(value: 1, timescale: 48_000),
                                    presentationTimeStamp: CMTime(value: CMTimeValue(startFrame), timescale: 48_000),
                                    decodeTimeStamp: .invalid)
    guard CMSampleBufferCreate(allocator: kCFAllocatorDefault, dataBuffer: block, dataReady: true,
                               makeDataReadyCallback: nil, refcon: nil, formatDescription: format,
                               sampleCount: frames, sampleTimingEntryCount: 1, sampleTimingArray: &timing,
                               sampleSizeEntryCount: 1, sampleSizeArray: [4], sampleBufferOut: &sb) == noErr else { return nil }
    return sb
}

func pcmFormatDescription() -> CMAudioFormatDescription {
    var asbd = AudioStreamBasicDescription(mSampleRate: 48_000, mFormatID: kAudioFormatLinearPCM,
                                           mFormatFlags: kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked,
                                           mBytesPerPacket: 4, mFramesPerPacket: 1, mBytesPerFrame: 4,
                                           mChannelsPerFrame: 2, mBitsPerChannel: 16, mReserved: 0)
    var fmt: CMAudioFormatDescription?
    guard CMAudioFormatDescriptionCreate(allocator: kCFAllocatorDefault, asbd: &asbd, layoutSize: 0, layout: nil,
                                         magicCookieSize: 0, magicCookie: nil, extensions: nil,
                                         formatDescriptionOut: &fmt) == noErr, let f = fmt else { die("audio format") }
    return f
}

/// Apply the normalisation gain + soft limiter to the mixer's doubles and pack to 16-bit.
/// Same ceiling and knee as `applyGain`, so both paths deliver the same guarantee.
func packGained(_ pcm: [Double], count: Int, gain: Double) -> [Int16] {
    let ceiling = pow(10.0, targetPeakDb / 20.0)
    let knee = pow(10.0, (targetPeakDb - 5.0) / 20.0)
    var out = [Int16](repeating: 0, count: count)
    for i in 0..<count {
        let v = pcm[i] * gain
        if abs(v) > knee { limitStats.limited += 1 }
        let y = softLimit(v, ceiling: ceiling, knee: knee)
        out[i] = Int16(max(-32768.0, min(32767.0, (y * 32768.0).rounded())))
    }
    limitStats.total += count
    return out
}

// MARK: - flatten: mix all audio tracks into one, keep video (passthrough)

func flatten(_ inPath: String, _ outArg: String?, normalize: Bool = true, rebalance: Bool = true) {
    let asset = AVURLAsset(url: URL(fileURLWithPath: inPath))
    let videoTracks = sync { try await asset.loadTracks(withMediaType: .video) }
    let audioTracks = sync { try await asset.loadTracks(withMediaType: .audio) }
    guard let vTrack = videoTracks.first else { die("no video track in \(inPath)") }
    guard !audioTracks.isEmpty else { die("no audio tracks in \(inPath)") }

    let outPath = outArg ?? "\((inPath as NSString).deletingPathExtension)-flat.mov"
    let out = URL(fileURLWithPath: outPath)
    try? FileManager.default.removeItem(at: out)

    // Two tracks + a mic that was actually used = the case worth rebalancing: the voice is a
    // voice, the app audio is a bed, and summing them raw preserves whatever distance the room
    // put between them. One track (or --no-rebalance) takes the plain summing path.
    let doRebalance = rebalance && audioTracks.count >= 2
    var plan: RebalancePlan?
    let totalFrames = Int((CMTimeGetSeconds(sync { try await asset.load(.duration) }) * 48_000).rounded())

    guard let reader = try? AVAssetReader(asset: asset) else { die("reader") }
    // AVAssetReaderAudioMixOutput SUMS multiple audio tracks into one PCM stream.
    let audioOut = AVAssetReaderAudioMixOutput(audioTracks: audioTracks, audioSettings: pcmSettings)
    // Attenuate each source a touch when there's more than one, so a loud moment on both
    // (voice + app sound at once) doesn't clip the summed track. Normalisation afterwards
    // gives this headroom straight back, so it costs nothing in the delivered loudness.
    var mix: AVAudioMix?
    if audioTracks.count > 1 && !doRebalance {
        let m = AVMutableAudioMix()
        m.inputParameters = audioTracks.map { t in
            let p = AVMutableAudioMixInputParameters(track: t)
            p.setVolume(0.8, at: .zero)
            return p
        }
        mix = m
        audioOut.audioMix = m
    }

    if doRebalance {
        FileHandle.standardError.write("⧗ measuring voice vs app audio…\n".data(using: .utf8)!)
        // The recorder writes system audio first, mic second (screen-audio-record setupWriter).
        let pl = planRebalance(asset, system: audioTracks[0], mic: audioTracks[1], BalanceParams())
        plan = pl
        print("🎙 balance  : \(pl.describe)")
        if pl.micGainDb <= 0.01 {
            print("🎙 balance  : the mic is already at or above the app audio — left alone")
        }
    }

    // Measure BEFORE writing anything: the gain has to be known for the first sample.
    // When rebalancing, this measures the REBALANCED mix, because that is what gets written.
    var gain = 1.0
    if normalize {
        FileHandle.standardError.write("⧗ measuring loudness…\n".data(using: .utf8)!)
        let lv: Levels
        if let pl = plan {
            let acc = LevelAccumulator()
            let m = RebalancedMixer(asset: asset, system: audioTracks[0], mic: audioTracks[1], plan: pl, totalFrames: totalFrames)
            while let c = m.next() { acc.add(c.pcm, count: c.frames * 2) }
            lv = acc.finish()
        } else {
            lv = measureLevels(asset, audioTracks, mix)
        }
        gain = gainFor(lv)
        print("🔊 audio in : \(lv.describe)")
        if abs(20 * log10(gain)) < 0.1 {
            print("🔊 audio out: already at target — no gain applied")
        } else {
            print("🔊 gain     : \(dbString(gain))  (target loudness \(Int(targetLoudnessDb)) dBFS, ceiling \(Int(targetPeakDb)) dBFS)")
            print(String(format: "🔊 expected : loudness %.1f dBFS after gain", lv.gatedDb + 20 * log10(gain)))
        }
    }
    if plan == nil {
        guard reader.canAdd(audioOut) else { die("cannot add audio mix output") }
        reader.add(audioOut)
    }

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
    var writeMixer: RebalancedMixer?
    if let pl = plan {
        // Second pass through the two tracks, running the identical chain that was measured.
        let mixer = RebalancedMixer(asset: asset, system: audioTracks[0], mic: audioTracks[1], plan: pl, totalFrames: totalFrames)
        writeMixer = mixer
        let fmt = pcmFormatDescription()
        aIn.requestMediaDataWhenReady(on: DispatchQueue(label: "flatten.a")) {
            while aIn.isReadyForMoreMediaData {
                if let c = mixer.next() {
                    let packed = packGained(c.pcm, count: c.frames * 2, gain: gain)
                    if let sb = makeAudioSampleBuffer(packed, frames: c.frames, startFrame: c.startFrame, format: fmt) {
                        aIn.append(sb)
                    }
                } else { aIn.markAsFinished(); group.leave(); break }
            }
        }
    } else {
        aIn.requestMediaDataWhenReady(on: DispatchQueue(label: "flatten.a")) {
            while aIn.isReadyForMoreMediaData {
                if let sb = audioOut.copyNextSampleBuffer() {
                    applyGain(sb, gain)
                    aIn.append(sb)
                }
                else { aIn.markAsFinished(); group.leave(); break }
            }
        }
    }
    group.wait()

    if reader.status == .failed { die("read failed: \(reader.error?.localizedDescription ?? "unknown")") }
    let sem = DispatchSemaphore(value: 0)
    writer.finishWriting { sem.signal() }
    sem.wait()
    if writer.status != .completed { die("write failed: \(writer.error?.localizedDescription ?? "unknown")") }
    if let m = writeMixer, m.frames > 0, let pl = plan, pl.micGainDb > 0.01 {
        let pct = 100.0 * Double(m.duckedFrames) / Double(m.frames)
        print(String(format: "🎙 ducking  : app audio under the voice %.0f%% of the recording, %.1f dB deep on average",
                     pct, -m.meanDuckDb))
    }
    if normalize && limitStats.total > 0 && limitStats.limited > 0 {
        let pct = 100.0 * Double(limitStats.limited) / Double(limitStats.total)
        print(String(format: "🔊 limiter  : shaped %.3f%% of samples (the transients above the ceiling)", pct))
    }
    print("✓ \(outPath)")
}

// MARK: - level: just report, change nothing

func level(_ inPath: String, rebalance: Bool = true) {
    let asset = AVURLAsset(url: URL(fileURLWithPath: inPath))
    let audioTracks = sync { try await asset.loadTracks(withMediaType: .audio) }
    guard !audioTracks.isEmpty else { die("no audio tracks in \(inPath)") }
    // With two tracks the single most useful number is not the mix's loudness — it is how far
    // APART the voice and the app audio are. That is the thing a single gain cannot fix.
    var plan: RebalancePlan?
    if audioTracks.count >= 2 && rebalance {
        plan = planRebalance(asset, system: audioTracks[0], mic: audioTracks[1], BalanceParams())
    }
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
    print("  tracks : \(audioTracks.count)\(plan != nil ? " (system + mic)" : "")")
    if let pl = plan { print("  balance: \(pl.describe)") }
    print("  levels : \(lv.describe)\(plan != nil ? "  [of the raw sum, before rebalance]" : "")")
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

// MARK: - self-test
//
// The balance decision and every filter in the chain are pure arithmetic, so they get
// asserted HERE — at build time, in a second — rather than by discovering three minutes into
// a screencast that the voice came out ducking itself. Same reason rec-subtitle has one.
// Every case below is a bug that was possible, and several are bugs that happened.

func selfTest() -> Never {
    var failures = 0
    func check(_ name: String, _ ok: Bool, _ detail: @autoclosure () -> String = "") {
        if ok { print("  ✓ \(name)") }
        else { failures += 1; print("  ✗ \(name)  \(detail())") }
    }
    func near(_ a: Double, _ b: Double, _ tol: Double = 0.05) -> Bool { abs(a - b) <= tol }

    let p = BalanceParams()
    print("balance decision")
    // The 2026-08-27 Renoise walkthrough, the recording this feature exists because of.
    let g = micGainDb(sysGatedDb: -11.4, micGatedDb: -38.0, p)
    check("Esa's Renoise take: 26.6 dB apart → +21.0 dB of mic", near(g, 21.0, 0.15), "got \(g)")
    // A voice already on top must be left completely alone — never attenuated.
    check("voice already louder than the app → no change",
          micGainDb(sysGatedDb: -30.0, micGatedDb: -12.0, p) == 0)
    // A mic that captured nothing is hiss. Lifting hiss 60 dB delivers loud hiss.
    check("dead microphone is capped at maxMicBoost",
          micGainDb(sysGatedDb: -10.0, micGatedDb: -90.0, p) == p.maxMicBoostDb)
    check("silent track (−inf dBFS) does not produce NaN gain",
          micGainDb(sysGatedDb: -12.0, micGatedDb: -.infinity, p) == 0)
    // The post-gain voice must land exactly voiceLead above the ducked bed. This is the
    // whole point of the formula, so it is asserted directly rather than assumed.
    let sysDb = -11.4, micDb = -38.0
    let voiceAfter = micDb + micGainDb(sysGatedDb: sysDb, micGatedDb: micDb, p)
    let bedAfter = sysDb - p.duckDepthDb
    check("voice lands voiceLead dB above the ducked bed", near(voiceAfter - bedAfter, p.voiceLeadDb))

    print("compressor curve")
    check("below the knee it is transparent",
          compressorGainDb(-40, threshold: -14, ratio: 4, knee: 6) == 0)
    // 10 dB over at 4:1 must come out 7.5 dB down, not 10 and not 2.5.
    check("well above the knee it obeys the ratio",
          near(compressorGainDb(-4, threshold: -14, ratio: 4, knee: 6), -7.5, 0.01),
          "got \(compressorGainDb(-4, threshold: -14, ratio: 4, knee: 6))")
    check("the knee is continuous at its lower edge",
          near(compressorGainDb(-17.01, threshold: -14, ratio: 4, knee: 6), 0, 0.01))
    check("the knee is continuous at its upper edge",
          near(compressorGainDb(-11.0, threshold: -14, ratio: 4, knee: 6),
               compressorGainDb(-10.99, threshold: -14, ratio: 4, knee: 6), 0.01))
    check("gain reduction never goes positive (a compressor cannot make things louder)",
          (-60...0).allSatisfy { compressorGainDb(Double($0), threshold: -14, ratio: 4, knee: 6) <= 0 })

    print("soft limiter")
    let ceil = pow(10.0, -1.0 / 20.0), knee = pow(10.0, -6.0 / 20.0)
    check("below the knee it is identity", softLimit(0.1, ceiling: ceil, knee: knee) == 0.1)
    // The bug this file already shipped once: knee and ceiling conflated, output reached
    // 0 dBFS while the tool printed "ceiling -1 dBFS".
    check("nothing, at any input, exceeds the ceiling",
          stride(from: 0.0, through: 40.0, by: 0.05).allSatisfy { abs(softLimit($0, ceiling: ceil, knee: knee)) <= ceil + 1e-9 })
    check("it is odd-symmetric", near(softLimit(-3.0, ceiling: ceil, knee: knee), -softLimit(3.0, ceiling: ceil, knee: knee), 1e-12))

    print("high-pass")
    var hp = Biquad.highPass(75, 48_000)
    var dc = 0.0
    for _ in 0..<20_000 { dc = hp.process(1.0) }
    check("DC is rejected (desk rumble does not eat the headroom)", abs(dc) < 1e-3, "settled at \(dc)")
    var hp2 = Biquad.highPass(75, 48_000)
    var peak = 0.0
    for i in 0..<48_000 { let y = hp2.process(sin(2 * Double.pi * 1000 * Double(i) / 48_000)); if i > 4800 { peak = max(peak, abs(y)) } }
    check("1 kHz passes at unity (the voice is not being filtered)", near(peak, 1.0, 0.02), "peak \(peak)")

    print("followers")
    var f = Follower(attackMs: 10, releaseMs: 250, sr: 48_000)
    for _ in 0..<480 { _ = f.process(1.0) }             // 10 ms of full scale
    check("attack reaches ~63% of the target in one time constant", f.v > 0.6 && f.v < 0.68, "\(f.v)")
    let afterAttack = f.v
    for _ in 0..<480 { _ = f.process(0.0) }             // 10 ms of silence
    check("release is much slower than attack", f.v > afterAttack * 0.9, "\(f.v)")
    var gs = GainSmoother(attackMs: 20, releaseMs: 400, sr: 48_000)
    for _ in 0..<960 { _ = gs.process(0.5) }            // 20 ms of "duck!"
    let ducked = gs.v
    check("the ducker moves DOWN on its attack, not its release", ducked < 0.72, "\(ducked)")
    for _ in 0..<960 { _ = gs.process(1.0) }            // 20 ms of "let go"
    check("…and comes back up slowly, so it cannot chatter between words",
          gs.v < ducked + 0.1, "\(gs.v)")

    print(failures == 0 ? "\nall checks passed" : "\n\(failures) FAILED")
    exit(failures == 0 ? 0 : 1)
}

// MARK: - main

let args = Array(CommandLine.arguments.dropFirst())
if args.first == "--self-test" { selfTest() }
guard let mode = args.first else {
    die("""
    usage:
      rec-audio split   <recording.mov>            → <stem>-system.m4a + <stem>-mic.m4a
      rec-audio flatten <recording.mov> [-o out]   → <stem>-flat.mov (video + one mixed track:
                                                      voice rebalanced against the app audio,
                                                      then loudness-normalised.
                                                      --no-rebalance / --no-normalize opt out)
      rec-audio level   <video.mov>                → report peak/RMS and the gain it would apply
      rec-audio normalize <video.mov> [-o out]     → <stem>-loud.mov: SAME video (passthrough,
                                                      no re-encode), audio normalised
      rec-audio --self-test                        → assert the balance + filter arithmetic
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
    flatten(args[1], outArg,
            normalize: !(args.contains("--no-normalize") || args.contains("--no-normalise")),
            rebalance: !args.contains("--no-rebalance"))
case "level":
    guard args.count >= 2 else { die("rec-audio level <video.mov>") }
    level(args[1], rebalance: !args.contains("--no-rebalance"))
case "normalize", "normalise":
    // Same machinery as flatten — a single already-mixed track is just the one-track case.
    guard args.count >= 2 else { die("rec-audio normalize <video.mov> [-o out.mov]") }
    var outArg: String? = nil
    if let i = args.firstIndex(of: "-o"), i + 1 < args.count { outArg = (args[i + 1] as NSString).expandingTildeInPath }
    flatten(args[1], outArg ?? "\((args[1] as NSString).deletingPathExtension)-loud.mov",
            normalize: true, rebalance: !args.contains("--no-rebalance"))
default:
    die("unknown mode \"\(mode)\" — use split, flatten, level or normalize")
}
