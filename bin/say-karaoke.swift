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

final class Reader: NSObject, AVSpeechSynthesizerDelegate {
    let text: String
    init(_ t: String) { self.text = t }
    func speechSynthesizer(_ s: AVSpeechSynthesizer, willSpeakRangeOfSpeechString r: NSRange, utterance: AVSpeechUtterance) {
        let word = (text as NSString).substring(with: r)
        let esc = word.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        FileHandle.standardOutput.write("{\"loc\":\(r.location),\"len\":\(r.length),\"word\":\"\(esc)\"}\n".data(using: .utf8)!)
    }
    func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) { exit(0) }
    func speechSynthesizer(_ s: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) { exit(0) }
}

let reader = Reader(text)
synth.delegate = reader
let u = AVSpeechUtterance(string: text)
let want = voiceName ?? "Zoe (Premium)"
if let v = AVSpeechSynthesisVoice.speechVoices().first(where: { $0.name == want })
        ?? AVSpeechSynthesisVoice.speechVoices().first(where: { $0.name.contains("Zoe") && $0.quality == .premium }) {
    u.voice = v
}
synth.speak(u)
RunLoop.main.run()
