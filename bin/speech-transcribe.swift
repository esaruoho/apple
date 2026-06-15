// speech-transcribe — on-device speech-to-text via Apple's Speech framework.
//
// Apple-native transcription (SFSpeechRecognizer, requiresOnDeviceRecognition),
// no Whisper, no pip, no network. For benchmarking against Whisper and as a
// fast local option for short clips. macOS 13+.
//
// Usage:
//   speech-transcribe <audio-file> [--locale en-US]
//   speech-transcribe --auth          request Speech authorization, print status
//
// Note: Speech recognition is TCC-gated. The host process (Terminal/iTerm, or
// an .app) must be granted "Speech Recognition" in Privacy & Security.

import Foundation
import Speech
import AVFoundation

var args = Array(CommandLine.arguments.dropFirst())
func popValue(_ flag: String) -> String? {
    guard let i = args.firstIndex(of: flag), i + 1 < args.count else { return nil }
    let v = args[i + 1]; args.removeSubrange(i...(i + 1)); return v
}
let authOnly = args.contains("--auth"); args.removeAll { $0 == "--auth" }
let locale = popValue("--locale") ?? "en-US"

func err(_ s: String) { FileHandle.standardError.write(Data((s + "\n").utf8)) }

// ── authorization (TCC) ──
let authSema = DispatchSemaphore(value: 0)
var status: SFSpeechRecognizerAuthorizationStatus = .notDetermined
SFSpeechRecognizer.requestAuthorization { s in status = s; authSema.signal() }
authSema.wait()
if authOnly {
    let names: [SFSpeechRecognizerAuthorizationStatus: String] =
        [.authorized: "authorized", .denied: "denied", .restricted: "restricted", .notDetermined: "notDetermined"]
    print(names[status] ?? "unknown")
    exit(status == .authorized ? 0 : 3)
}
guard status == .authorized else {
    err("speech-transcribe: not authorized (\(status.rawValue)). Grant 'Speech Recognition' to this terminal in Privacy & Security.")
    exit(3)
}

guard let path = args.first else {
    err("usage: speech-transcribe <audio-file> [--locale en-US]   ·   speech-transcribe --auth")
    exit(2)
}
guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: locale)) else {
    err("speech-transcribe: no recognizer for locale \(locale)"); exit(1)
}
if !recognizer.supportsOnDeviceRecognition {
    err("speech-transcribe: on-device recognition not supported for \(locale) (would need network — refusing)."); exit(1)
}

let timeout = Double(popValue("--timeout") ?? "120") ?? 120
let maxAttempts = Int(popValue("--retries") ?? "3") ?? 3

// COLD-START RETRY (the real fix). Apple's on-device speech model returns an
// empty result — or error 1110 "No speech detected" — on the FIRST recognition
// call after it's been idle, then works once warm. A single attempt therefore
// looks like "no text captured" on clean, loud speech. So we retry on an
// empty/no-speech outcome (with a short delay to let the model load) before
// giving up. SFSpeechRecognizer delivers callbacks to the MAIN run loop, so we
// spin it and exit from inside the handler; a main-queue timer bounds the wait.
var latest = ""
var attempt = 0
var currentTask: SFSpeechRecognitionTask?

func retryOrFail(_ what: String) {
    if attempt < maxAttempts {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { startAttempt() }
    } else {
        if !latest.isEmpty { print(latest); exit(0) }
        err("speech-transcribe: recognized no words after \(attempt) attempt(s) " +
            "(\(what), locale \(locale)). The speech may be unclear, or the on-device " +
            "model for \(locale) is cold/missing.")
        exit(4)
    }
}

func startAttempt() {
    attempt += 1
    let req = SFSpeechURLRecognitionRequest(url: URL(fileURLWithPath: path))
    req.requiresOnDeviceRecognition = true
    req.shouldReportPartialResults = false
    currentTask = recognizer.recognitionTask(with: req) { result, error in
        if let r = result, r.isFinal {
            let text = r.bestTranscription.formattedString
            if !text.isEmpty { print(text); exit(0) }
            retryOrFail("empty result")           // cold-start empty → retry
            return
        }
        if let e = error {
            retryOrFail((e as NSError).localizedDescription)   // e.g. 1110 No speech detected
            return
        }
        if let r = result { latest = r.bestTranscription.formattedString }
    }
}

DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
    currentTask?.cancel()
    if !latest.isEmpty { print(latest); exit(0) }
    err("speech-transcribe: timed out after \(Int(timeout))s with no result.")
    exit(2)
}
startAttempt()
RunLoop.main.run()
