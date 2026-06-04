// mic-record — capture the default microphone to a WAV.
// Apple-native only: AVFoundation (AVAudioRecorder) + the macOS mic TCC grant.
// Sibling of speech-transcribe (which is file-only): mic-record produces the
// file, speech-transcribe reads it. Together they are "talk → text".
//
// Two modes:
//   mic-record <out.wav> [--seconds N]     fixed window (default 5s)
//   mic-record <out.wav> --until-silence   listen until you stop speaking
//       [--silence S]   trailing silence that ends the take   (default 1.5s)
//       [--max M]       hard cap so it can't run forever       (default 30s)
//       [--threshold D] dBFS below which counts as silence     (default -35)
//       [--onset T]     max wait for you to START speaking     (default 10s)
//
// Linear PCM 16 kHz mono — the shape Apple's Speech recogniser reads happily.

import Foundation
import AVFoundation

let args = Array(CommandLine.arguments.dropFirst())
guard let outPath = args.first, !outPath.hasPrefix("--") else {
    FileHandle.standardError.write("usage: mic-record <output.wav> [--seconds N | --until-silence]\n".data(using: .utf8)!)
    exit(1)
}

func doubleArg(_ name: String, _ fallback: Double) -> Double {
    if let i = args.firstIndex(of: name), i + 1 < args.count, let v = Double(args[i + 1]) { return v }
    return fallback
}

let untilSilence = args.contains("--until-silence")
var seconds = max(1.0, doubleArg("--seconds", 5.0))
let silenceNeeded = max(0.3, doubleArg("--silence", 1.5))
let maxDur = max(1.0, doubleArg("--max", 30.0))
let onsetWait = max(1.0, doubleArg("--onset", 10.0))
let threshold = doubleArg("--threshold", -35.0)   // dBFS; speech is typically > -30
let url = URL(fileURLWithPath: outPath)

// macOS mic permission is AVCaptureDevice audio TCC (AVAudioSession is iOS-only).
let authSema = DispatchSemaphore(value: 0)
var granted = false
AVCaptureDevice.requestAccess(for: .audio) { ok in granted = ok; authSema.signal() }
authSema.wait()
guard granted else {
    FileHandle.standardError.write("microphone access denied (grant Microphone TCC to this terminal/app)\n".data(using: .utf8)!)
    exit(2)
}

let settings: [String: Any] = [
    AVFormatIDKey: Int(kAudioFormatLinearPCM),
    AVSampleRateKey: 16000.0,
    AVNumberOfChannelsKey: 1,
    AVLinearPCMBitDepthKey: 16,
    AVLinearPCMIsFloatKey: false,
    AVLinearPCMIsBigEndianKey: false,
]

do {
    let recorder = try AVAudioRecorder(url: url, settings: settings)
    recorder.isMeteringEnabled = untilSilence
    guard recorder.record() else {
        FileHandle.standardError.write("could not start recording\n".data(using: .utf8)!)
        exit(3)
    }

    if untilSilence {
        FileHandle.standardError.write("listening… (speak; stops after \(silenceNeeded)s of silence, max \(maxDur)s)\n".data(using: .utf8)!)
        let poll = 0.05                 // 20 Hz level polling
        var elapsed = 0.0
        var silenceRun = 0.0
        var heardSpeech = false
        while elapsed < maxDur {
            Thread.sleep(forTimeInterval: poll)
            elapsed += poll
            recorder.updateMeters()
            let power = Double(recorder.averagePower(forChannel: 0))   // dBFS, ~-160…0
            if power > threshold {
                heardSpeech = true
                silenceRun = 0.0
            } else if heardSpeech {
                silenceRun += poll
                if silenceRun >= silenceNeeded { break }   // they stopped speaking
            } else if elapsed >= onsetWait {
                // never started speaking within the onset window — give up gracefully
                FileHandle.standardError.write("no speech detected\n".data(using: .utf8)!)
                break
            }
        }
    } else {
        FileHandle.standardError.write("recording \(seconds)s…\n".data(using: .utf8)!)
        Thread.sleep(forTimeInterval: seconds)
    }
    recorder.stop()
} catch {
    FileHandle.standardError.write("recorder failed: \(error)\n".data(using: .utf8)!)
    exit(4)
}

print(url.path)
