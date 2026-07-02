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

// MARK: - flatten: mix all audio tracks into one, keep video (passthrough)

func flatten(_ inPath: String, _ outArg: String?) {
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
    let pcm: [String: Any] = [
        AVFormatIDKey: kAudioFormatLinearPCM,
        AVSampleRateKey: 48_000,
        AVNumberOfChannelsKey: 2,
        AVLinearPCMBitDepthKey: 16,
        AVLinearPCMIsFloatKey: false,
        AVLinearPCMIsBigEndianKey: false,
        AVLinearPCMIsNonInterleaved: false,
    ]
    let audioOut = AVAssetReaderAudioMixOutput(audioTracks: audioTracks, audioSettings: pcm)
    // Attenuate each source a touch when there's more than one, so a loud moment on both
    // (voice + app sound at once) doesn't clip the summed track.
    if audioTracks.count > 1 {
        let mix = AVMutableAudioMix()
        mix.inputParameters = audioTracks.map { t in
            let p = AVMutableAudioMixInputParameters(track: t)
            p.setVolume(0.8, at: .zero)
            return p
        }
        audioOut.audioMix = mix
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
            if let sb = audioOut.copyNextSampleBuffer() { aIn.append(sb) }
            else { aIn.markAsFinished(); group.leave(); break }
        }
    }
    group.wait()

    if reader.status == .failed { die("read failed: \(reader.error?.localizedDescription ?? "unknown")") }
    let sem = DispatchSemaphore(value: 0)
    writer.finishWriting { sem.signal() }
    sem.wait()
    if writer.status != .completed { die("write failed: \(writer.error?.localizedDescription ?? "unknown")") }
    print("✓ \(outPath)")
}

// MARK: - main

let args = Array(CommandLine.arguments.dropFirst())
guard let mode = args.first else {
    die("""
    usage:
      rec-audio split   <recording.mov>            → <stem>-system.m4a + <stem>-mic.m4a
      rec-audio flatten <recording.mov> [-o out]   → <stem>-flat.mov (video + one mixed track)
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
    flatten(args[1], outArg)
default:
    die("unknown mode \"\(mode)\" — use split or flatten")
}
