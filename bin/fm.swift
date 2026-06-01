// fm — talk to Apple's on-device LLM via the FoundationModels framework.
//
// The same model behind Apple Intelligence, running locally on the Neural
// Engine — Apple-native, no Ollama, no pip, no network. macOS 26 (Tahoe) only,
// and only when Apple Intelligence is enabled + the model is downloaded.
//
// Usage:
//   fm "your prompt"            generate a reply (prompt from args)
//   echo "text" | fm            prompt from stdin (e.g. summarize piped text)
//   fm --check                  report model availability, then exit
//   fm --system "..." "prompt"  set system instructions

import Foundation
import FoundationModels

var args = Array(CommandLine.arguments.dropFirst())
func popValue(_ flag: String) -> String? {
    guard let i = args.firstIndex(of: flag), i + 1 < args.count else { return nil }
    let v = args[i + 1]; args.removeSubrange(i...(i + 1)); return v
}
let checkOnly = args.contains("--check"); args.removeAll { $0 == "--check" }
let system = popValue("--system")

// ── availability ──
let model = SystemLanguageModel.default
switch model.availability {
case .available:
    if checkOnly { print("available"); exit(0) }
case .unavailable(let reason):
    FileHandle.standardError.write(Data("FoundationModels unavailable: \(reason)\n".utf8))
    exit(3)
@unknown default:
    FileHandle.standardError.write(Data("FoundationModels unavailable (unknown state)\n".utf8))
    exit(3)
}

// ── prompt (args, else stdin) ──
var prompt = args.filter { !$0.hasPrefix("--") }.joined(separator: " ")
if prompt.isEmpty {
    let data = FileHandle.standardInput.readDataToEndOfFile()
    prompt = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
}
guard !prompt.isEmpty else {
    FileHandle.standardError.write(Data("usage: fm \"prompt\"   (or pipe text on stdin)   ·   fm --check\n".utf8))
    exit(2)
}

// ── generate (async bridged to the CLI via a semaphore) ──
let sema = DispatchSemaphore(value: 0)
var output = ""
var failure: String?
Task {
    do {
        let session = system.map { LanguageModelSession(instructions: $0) } ?? LanguageModelSession()
        let result = try await session.respond(to: prompt)
        output = result.content
    } catch {
        failure = "\(error)"
    }
    sema.signal()
}
sema.wait()

if let f = failure {
    FileHandle.standardError.write(Data("fm error: \(f)\n".utf8))
    exit(1)
}
print(output)
