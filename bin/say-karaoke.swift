// say-karaoke — speak text aloud AND emit each word's character range as it is
// spoken, so a UI can highlight along (karaoke). Apple-native: AVSpeechSynthesizer's
// willSpeakRangeOfSpeechString delegate is the word-by-word hook `say` does not expose.
//
// Usage:  say-karaoke "text"      (or pipe text on stdin)
//         say-karaoke --voice "Zoe (Premium)" "text"
// Emits one JSON line per word to STDOUT: {"loc":N,"len":M,"word":"..."}  (consume to
// highlight); speaks via the chosen voice (default Zoe (Premium) if installed).

import AVFoundation
import Foundation

var argv = Array(CommandLine.arguments.dropFirst())
var voiceName: String? = nil
if let i = argv.firstIndex(of: "--voice"), i + 1 < argv.count {
    voiceName = argv[i + 1]; argv.removeSubrange(i...(i + 1))
}
var text = argv.joined(separator: " ")
if text.isEmpty {
    text = String(data: FileHandle.standardInput.readDataToEndOfFile(), encoding: .utf8) ?? ""
}
text = text.trimmingCharacters(in: .whitespacesAndNewlines)
guard !text.isEmpty else {
    FileHandle.standardError.write("usage: say-karaoke [--voice NAME] \"text\"\n".data(using: .utf8)!)
    exit(1)
}

let synth = AVSpeechSynthesizer()

// Playback control. We write our PID to a well-known file so external commands
// (voicebox-stop / speech-toggle, driven by the global ⌃⌥⌘. and pause hotkeys)
// can reach the live synthesizer:
//   • SIGTERM / SIGINT → stop immediately and exit (interrupt).
//   • SIGUSR1          → toggle pause ⇄ resume at a word boundary ("continue later").
let pidPath = "/tmp/say-karaoke.pid"
func cleanup() { try? FileManager.default.removeItem(atPath: pidPath) }

final class Reader: NSObject, AVSpeechSynthesizerDelegate {
    let text: String
    init(_ t: String) { self.text = t }
    func speechSynthesizer(_ s: AVSpeechSynthesizer, willSpeakRangeOfSpeechString r: NSRange, utterance: AVSpeechUtterance) {
        let word = (text as NSString).substring(with: r)
        let esc = word.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        FileHandle.standardOutput.write("{\"loc\":\(r.location),\"len\":\(r.length),\"word\":\"\(esc)\"}\n".data(using: .utf8)!)
    }
    func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) { cleanup(); exit(0) }
    func speechSynthesizer(_ s: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) { cleanup(); exit(0) }
}

let reader = Reader(text)
synth.delegate = reader
let u = AVSpeechUtterance(string: text)
let want = voiceName ?? "Zoe (Premium)"
if let v = AVSpeechSynthesisVoice.speechVoices().first(where: { $0.name == want })
        ?? AVSpeechSynthesisVoice.speechVoices().first(where: { $0.name.contains("Zoe") && $0.quality == .premium }) {
    u.voice = v
}

// Register the PID + signal handlers BEFORE speaking, so a fast ⌃⌥⌘. lands.
try? "\(getpid())".write(toFile: pidPath, atomically: true, encoding: .utf8)

// NB: DispatchSource signal sources must be retained for the program's lifetime —
// a source that goes out of scope is cancelled and the (SIG_IGN'd) signal is then
// silently ignored. So these are top-level `let`s, not loop locals.
signal(SIGUSR1, SIG_IGN)
let pauseSrc = DispatchSource.makeSignalSource(signal: SIGUSR1, queue: .main)
pauseSrc.setEventHandler {
    if synth.isPaused {
        synth.continueSpeaking()
    } else if synth.isSpeaking {
        synth.pauseSpeaking(at: .word)        // pause at the next word boundary
    }
}
pauseSrc.resume()

signal(SIGTERM, SIG_IGN)
let termSrc = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
termSrc.setEventHandler { synth.stopSpeaking(at: .immediate); cleanup(); exit(0) }
termSrc.resume()

signal(SIGINT, SIG_IGN)
let intSrc = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
intSrc.setEventHandler { synth.stopSpeaking(at: .immediate); cleanup(); exit(0) }
intSrc.resume()

synth.speak(u)
RunLoop.main.run()
