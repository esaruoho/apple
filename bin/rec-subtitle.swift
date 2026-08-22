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

/// mm:ss (or h:mm:ss) for reporting lengths / elapsed times.
func clock(_ secs: Double) -> String {
    guard secs.isFinite, secs > 0 else { return "0:00" }
    let t = Int(secs.rounded()); let h = t / 3600, m = (t % 3600) / 60, s = t % 60
    return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
}

/// Length of a media file in seconds (0 if it can't be read) — used to tell the user how
/// much audio Whisper has to chew through, so its streaming [mm:ss] timestamps read as progress.
func mediaSeconds(_ path: String) -> Double {
    let asset = AVURLAsset(url: URL(fileURLWithPath: path))
    let d = sync { try await asset.load(.duration) }
    let s = CMTimeGetSeconds(d)
    return s.isFinite ? s : 0
}

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

// MARK: - vocabulary (proper-noun alignment)

/// The words a transcript keeps getting wrong. Whisper guesses proper nouns phonetically
/// ("Paketti" → "Pucketty" / "Pocketty", "Renoise" → "Reno", "Lackluster" → "Lacklustre"),
/// so the fix is applied at BOTH ends of the transcription:
///
///   1. BIAS   — the canonical terms are fed to Whisper as `--initial_prompt`, which makes it
///               far more likely to spell them right in the first place.
///   2. REPAIR — the finished .srt is swept for the known mishearings and for sound-alikes,
///               and rewritten to the canonical spelling.
///
/// Bias alone is probabilistic (it nudges, it does not guarantee); the sweep is what makes
/// "Paketti" come out as Paketti every single time. Both read the same vocabulary file.
struct Vocabulary {
    var terms: [String] = []                    // canonical spellings → --initial_prompt
    var corrections: [String: [String]] = [:]   // canonical → literal mishearings to rewrite
    var prompt: String? = nil                   // explicit initial_prompt (overrides `terms`)
    var fuzzy: Bool = true                      // also sweep UNLISTED sound-alikes (Soundex)
    var source: String = "(built-in)"
    var isEmpty: Bool { terms.isEmpty && corrections.isEmpty && (prompt?.isEmpty ?? true) }
}

/// Where a vocabulary comes from, first hit wins: an explicit --vocab, $RECBURN_VOCAB, a
/// per-project file in the recording's own folder, the user's config, then the copy shipped
/// beside this binary (also inside RecBurn.app/Contents/MacOS).
func vocabularyPaths(explicit: String?, near dir: String?) -> [String] {
    var p: [String] = []
    if let e = explicit { p.append((e as NSString).expandingTildeInPath) }
    if let e = ProcessInfo.processInfo.environment["RECBURN_VOCAB"], !e.isEmpty {
        p.append((e as NSString).expandingTildeInPath)
    }
    if let d = dir, !d.isEmpty { p.append((d as NSString).appendingPathComponent(".recburn-vocabulary.json")) }
    p.append(FileManager.default.currentDirectoryPath + "/.recburn-vocabulary.json")
    p.append(("~/.config/recburn/vocabulary.json" as NSString).expandingTildeInPath)
    let selfDir = (CommandLine.arguments[0] as NSString).resolvingSymlinksInPath as NSString
    p.append((selfDir.deletingLastPathComponent as NSString).appendingPathComponent("recburn-vocabulary.json"))
    return p
}

func loadVocabulary(explicit: String?, near dir: String? = nil) -> Vocabulary {
    for path in vocabularyPaths(explicit: explicit, near: dir) {
        guard FileManager.default.fileExists(atPath: path),
              let data = FileManager.default.contents(atPath: path),
              let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { continue }
        var v = Vocabulary()
        v.source = path
        v.terms = (obj["terms"] as? [String]) ?? []
        v.prompt = obj["prompt"] as? String
        v.fuzzy = (obj["fuzzy"] as? Bool) ?? true
        if let c = obj["corrections"] as? [String: [String]] { v.corrections = c }
        // Every canonical is also a term (so the bias covers everything the sweep repairs).
        for k in v.corrections.keys where !v.terms.contains(k) { v.terms.append(k) }
        return v
    }
    if let e = explicit { die("vocabulary file not found: \(e)") }
    return Vocabulary()   // nothing configured: no bias, no sweep
}

/// The `--initial_prompt` handed to Whisper: a plain glossary sentence. Whisper conditions its
/// first window on this text, which biases the decoder toward these spellings.
func vocabularyPrompt(_ v: Vocabulary) -> String? {
    if let p = v.prompt, !p.isEmpty { return p }
    guard !v.terms.isEmpty else { return nil }
    return v.terms.joined(separator: ", ") + "."
}

// MARK: vocabulary — the repair sweep

/// American Soundex. Two words with the same code sound alike to a first approximation, which
/// is exactly the failure mode here: Whisper heard the sounds right and spelled them wrong.
/// "Pucketty" / "Pocketty" / "Paketti" all code P230; "Lacklustre" / "Lackluster" both L242.
func soundex(_ word: String) -> String {
    let letters = word.lowercased().unicodeScalars.filter { CharacterSet.letters.contains($0) }
    guard let first = letters.first else { return "" }
    func code(_ c: Unicode.Scalar) -> Character? {
        switch c {
        case "b", "f", "p", "v": return "1"
        case "c", "g", "j", "k", "q", "s", "x", "z": return "2"
        case "d", "t": return "3"
        case "l": return "4"
        case "m", "n": return "5"
        case "r": return "6"
        default: return nil          // vowels + h,w,y — separators, no code
        }
    }
    var out = String(Character(first)).uppercased()
    var prev = code(first)
    for c in letters.dropFirst() {
        let k = code(c)
        if let k = k, k != prev { out.append(k) }
        // h and w are transparent: they do NOT reset the "same code" rule; vowels do.
        if c != "h" && c != "w" { prev = k }
        if out.count == 4 { break }
    }
    return out.padding(toLength: 4, withPad: "0", startingAt: 0)
}

/// The system word list, used as a veto: if Whisper produced a REAL English word, leave it
/// alone no matter what it rhymes with. Only nonsense-looking tokens get sound-alike repair.
let englishWords: Set<String> = {
    for p in ["/usr/share/dict/words", "/usr/share/dict/web2"] {
        if let s = try? String(contentsOfFile: p, encoding: .utf8) {
            return Set(s.split(separator: "\n").map { $0.lowercased() })
        }
    }
    return []
}()

func regexEscape(_ s: String) -> String { NSRegularExpression.escapedPattern(for: s) }

/// Rewrite one line of transcript text. Returns the corrected line plus a canonical→count
/// tally, so the run can report exactly what it fixed rather than silently editing speech.
func correctText(_ text: String, _ v: Vocabulary) -> (String, [String: Int]) {
    var out = text
    var hits: [String: Int] = [:]

    // 1. Listed mishearings. Longest first so "pucketty bot" wins over "pucketty".
    let listed = v.corrections.flatMap { canon, aliases in aliases.map { (canon, $0) } }
        .sorted { $0.1.count > $1.1.count }
    for (canon, alias) in listed {
        // \b…\b, but the alias may contain spaces/hyphens, so allow either between its words.
        let body = alias.split(whereSeparator: { $0 == " " || $0 == "-" })
            .map { regexEscape(String($0)) }.joined(separator: "[ -]+")
        guard let re = try? NSRegularExpression(pattern: "\\b" + body + "\\b", options: [.caseInsensitive]) else { continue }
        let ms = re.matches(in: out, range: NSRange(out.startIndex..., in: out))
        guard !ms.isEmpty else { continue }
        hits[canon, default: 0] += ms.count
        out = re.stringByReplacingMatches(in: out, range: NSRange(out.startIndex..., in: out),
                                          withTemplate: NSRegularExpression.escapedTemplate(for: canon))
    }

    // 1b. The canonical terms themselves, in the wrong case. Whisper hears the name fine but
    //     writes "renoise" / "lackluster" lowercase mid-sentence; the spelling we ship is the
    //     one that goes on screen.
    for term in v.terms {
        let body = term.split(separator: " ").map { regexEscape(String($0)) }.joined(separator: "\\s+")
        guard let re = try? NSRegularExpression(pattern: "\\b" + body + "\\b", options: [.caseInsensitive]) else { continue }
        for m in re.matches(in: out, range: NSRange(out.startIndex..., in: out)).reversed() {
            guard let r = Range(m.range, in: out), String(out[r]) != term else { continue }
            hits[term, default: 0] += 1
            out.replaceSubrange(r, with: term)
        }
    }

    // 2. Sound-alikes nobody listed yet — the whole point being that you should not have to
    //    enumerate every way Whisper can mangle a name before it gets spelled right.
    guard v.fuzzy else { return (out, hits) }
    let singles = v.terms.filter { !$0.contains(" ") && $0.count >= 5 }
    guard !singles.isEmpty,
          let tok = try? NSRegularExpression(pattern: "[A-Za-z][A-Za-z'’-]*") else { return (out, hits) }
    let codes = singles.map { (term: $0, code: soundex($0)) }
    var result = out
    for m in tok.matches(in: out, range: NSRange(out.startIndex..., in: out)).reversed() {
        guard let r = Range(m.range, in: out) else { continue }
        var word = String(out[r])
        var suffix = ""
        for poss in ["'s", "’s"] where word.lowercased().hasSuffix(poss) {
            suffix = String(word.suffix(2)); word = String(word.dropLast(2))
        }
        guard word.count >= 5 else { continue }
        let lower = word.lowercased()
        if englishWords.contains(lower) { continue }                       // real word — hands off
        if singles.contains(where: { $0.lowercased() == lower }) { continue } // already correct
        let code = soundex(word)
        guard let hit = codes.first(where: { $0.code == code }) else { continue }
        guard abs(hit.term.count - word.count) <= 3 else { continue }      // same sound, wildly different length
        hits[hit.term, default: 0] += 1
        result.replaceSubrange(r, with: hit.term + suffix)
    }
    return (result, hits)
}

/// Sweep a finished .srt in place. Only the text lines are touched — indices and timecodes are
/// passed through byte-for-byte, so the file stays a valid .srt and the burn-in still lines up.
@discardableResult
func correctSRT(_ path: String, _ v: Vocabulary, quiet: Bool = false) -> [String: Int] {
    guard !v.isEmpty, let raw = try? String(contentsOfFile: path, encoding: .utf8) else { return [:] }
    var hits: [String: Int] = [:]
    let fixed = raw.components(separatedBy: "\n").map { line -> String in
        let t = line.trimmingCharacters(in: .whitespaces)
        if t.isEmpty || t.contains("-->") || Int(t) != nil { return line }   // index / timecode / blank
        let (s, h) = correctText(line, v)
        for (k, n) in h { hits[k, default: 0] += n }
        return s
    }.joined(separator: "\n")
    if !hits.isEmpty {
        try? fixed.write(toFile: path, atomically: true, encoding: .utf8)
        if !quiet {
            let summary = hits.sorted { $0.value > $1.value }.map { "\($0.key) ×\($0.value)" }.joined(separator: ", ")
            let total = hits.values.reduce(0, +)
            note("✓ vocabulary: corrected \(total) word\(total == 1 ? "" : "s") — \(summary)")
        }
    } else if !quiet {
        note("✓ vocabulary: nothing to correct (\((v.source as NSString).lastPathComponent))")
    }
    return hits
}

/// Headless assertions for the vocabulary layer — no audio, no video, no Whisper. `build.sh`
/// runs this, so a regression in the correction rules fails the build instead of a recording.
func vocabularySelfTest() -> Never {
    var v = Vocabulary()
    v.terms = ["Renoise", "Paketti", "Lackluster", "Redux"]
    v.corrections = ["Paketti": ["pucketty", "pocketty"], "Renoise": ["reno"],
                     "Lackluster": ["lacklustre", "lack luster"]]
    var failed = 0
    func check(_ input: String, _ want: String, _ why: String) {
        let got = correctText(input, v).0
        if got == want { print("  ok   \(why)") }
        else { failed += 1; print("  FAIL \(why)\n       input: \(input)\n       want:  \(want)\n       got:   \(got)") }
    }
    print("rec-subtitle vocabulary self-test")
    check("So I opened Pucketty in Reno.", "So I opened Paketti in Renoise.", "listed mishearings")
    check("pocketty is a Renoise tool", "Paketti is a Renoise tool", "listed, sentence-initial + already-correct term untouched")
    check("my Lacklustre album", "my Lackluster album", "British spelling")
    check("the lack luster record", "the Lackluster record", "two-word mishearing")
    check("Packetti and Paketi both", "Paketti and Paketti both", "UNLISTED sound-alikes (Soundex)")
    check("Pucketty's tools", "Paketti's tools", "possessive preserved")
    check("Paketti in Renoise", "Paketti in Renoise", "idempotent — correct text unchanged")
    check("a lackluster performance today", "a Lackluster performance today", "canonical casing applied")
    check("I put the packet in the tracker", "I put the packet in the tracker", "real English words are never rewritten")
    check("rendered a nice noise floor", "rendered a nice noise floor", "ordinary speech untouched")
    print(failed == 0 ? "✓ vocabulary self-test passed" : "✗ \(failed) failure(s)")
    exit(failed == 0 ? 0 : 1)
}

// MARK: - transcription via whisp

func shquote(_ args: [String]) -> String {
    args.map { "'\($0.replacingOccurrences(of: "'", with: "'\\''"))'" }.joined(separator: " ")
}

func which(_ name: String) -> String? {
    let p = Process(); p.launchPath = "/usr/bin/which"; p.arguments = [name]
    let pipe = Pipe(); p.standardOutput = pipe; p.standardError = Pipe()
    do { try p.run() } catch { return nil }
    p.waitUntilExit()
    guard p.terminationStatus == 0 else { return nil }
    let s = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
        .trimmingCharacters(in: .whitespacesAndNewlines)
    return (s?.isEmpty == false) ? s : nil
}

/// Transcribe with the openai-whisper `whisper` CLI directly (clean + predictable, no wrapper
/// side-effects). Models cache ONCE, globally, in ~/.cache/whisper — never per-directory, so
/// running this from ~/Downloads or anywhere reuses the same cached model. Returns the
/// <inputstem>.srt path in outStem's directory.
func transcribe(_ audioOrVideo: String, model: String?, lang: String, outStem: String, prompt: String? = nil) -> String {
    let outDir = (outStem as NSString).deletingLastPathComponent
    let inStem = ((audioOrVideo as NSString).lastPathComponent as NSString).deletingPathExtension
    guard let w = which("whisper") else {
        die("`whisper` not found — `pip install openai-whisper` (or run install-deps.sh) to enable subtitles")
    }
    // Proper default model: small.en for English (accurate + fast), multilingual small otherwise.
    // NOT tiny — that was only for speed-tests. Bump to medium.en / large-v3 via --model.
    let chosen = model ?? (lang.lowercased() == "en" ? "small.en" : "small")
    // Force the language (default en) — Whisper's auto-detect misfires on short/accented clips
    // (e.g. calling English "Finnish"). Pass lang "auto" to let it detect.
    let langArgs = (lang.lowercased() == "auto") ? [] : ["--language", lang]
    let total = mediaSeconds(audioOrVideo)
    let ofLen = total > 0 ? " of \(clock(total)) audio" : ""
    note("⧉ transcribing \((audioOrVideo as NSString).lastPathComponent)\(ofLen) — whisper model=\(chosen), lang=\(lang)")
    note("   (Whisper prints each line as it decodes; its [mm:ss] timestamps show how far it is)")
    // --verbose True streams every decoded segment to the terminal → live progress.
    // --initial_prompt biases Whisper toward domain vocabulary (proper nouns it would otherwise
    // guess phonetically, e.g. "Renoise", "Paketti", "Esa Ruoho"). Only added when provided.
    let promptArgs = (prompt?.isEmpty == false) ? ["--initial_prompt", prompt!] : []
    let args = [w, audioOrVideo, "--model", chosen, "--verbose", "True",
                "--output_format", "srt", "--output_dir", outDir, "--fp16", "False"] + langArgs + promptArgs
    let t0 = Date()
    let p = Process(); p.launchPath = "/bin/bash"; p.arguments = ["-lc", shquote(args)]
    do { try p.run() } catch { die("failed to launch whisper: \(error.localizedDescription)") }
    p.waitUntilExit()
    if p.terminationStatus != 0 { die("whisper exited \(p.terminationStatus)") }
    let srt = (outDir as NSString).appendingPathComponent(inStem + ".srt")
    guard FileManager.default.fileExists(atPath: srt) else { die("no .srt produced at \(srt)") }
    let elapsed = Date().timeIntervalSince(t0)
    let n = parseSRT(srt).count
    note("✓ transcribed \(n) subtitle line\(n == 1 ? "" : "s") in \(clock(elapsed))")
    return srt
}

/// Is the Mac Mini whisp pipeline present on this host? (whisp-submit + the Syncthing inbox.)
func miniAvailable() -> Bool {
    let submit = ("~/work/whisp-transcripts/whisp-submit" as NSString).expandingTildeInPath
    var isDir: ObjCBool = false
    let inbox = ("~/work/comms/queue/whisp-inbox" as NSString).expandingTildeInPath
    return FileManager.default.fileExists(atPath: submit)
        && FileManager.default.fileExists(atPath: inbox, isDirectory: &isDir) && isDir.boolValue
}

/// Route transcription to the always-on Mac Mini via the Syncthing whisp pipeline
/// (whisp-submit drops the file into ~/work/comms/queue/whisp-inbox; the Mini worker
/// transcribes and the .srt returns via git/Syncthing). Keeps heavy Whisper off THIS mac.
/// @built — the round-trip depends on the Mini worker; poll locations are best-effort.
/// Best-effort Mini routing (--mini). Submits, polls briefly, and FALLS BACK to local
/// transcription if the transcript doesn't return in time — never hangs then dies. The Mini
/// worker names outputs by title (not the input stem) and can be queued behind other jobs, so
/// this is genuinely best-effort; local is the reliable path.
func transcribeOnMini(_ audio: String, model: String?, lang: String, stem: String, prompt: String? = nil) -> String {
    let submit = ("~/work/whisp-transcripts/whisp-submit" as NSString).expandingTildeInPath
    guard FileManager.default.fileExists(atPath: submit) else {
        note("Mini whisp-submit not found — transcribing locally"); return transcribe(audio, model: model, lang: lang, outStem: stem + ".srt", prompt: prompt)
    }
    let inStem = ((audio as NSString).lastPathComponent as NSString).deletingPathExtension
    note("⧉ submitting to the Mini (whisp-submit)…")
    let p = Process(); p.launchPath = submit; p.arguments = [audio]
    do { try p.run(); p.waitUntilExit() } catch {}
    let dirs = [("~/work/whisp-transcripts/transcripts" as NSString).expandingTildeInPath,
                ("~/work/comms/queue/whisp-results" as NSString).expandingTildeInPath]
    note("   waiting up to 3 min for the Mini transcript, then falling back to local…")
    let deadline = Date(timeIntervalSinceNow: 180)   // short — never hang the user
    while Date() < deadline {
        for dir in dirs {
            if let hit = findSRT(named: inStem, under: dir) {
                let dst = stem + ".srt"
                try? FileManager.default.removeItem(atPath: dst)
                try? FileManager.default.copyItem(atPath: hit, toPath: dst)
                note("   ✓ transcript returned from the Mini"); return dst
            }
        }
        Thread.sleep(forTimeInterval: 5)
    }
    note("   Mini didn't return in time — transcribing locally instead")
    return transcribe(audio, model: model, lang: lang, outStem: stem + ".srt", prompt: prompt)
}

func findSRT(named stem: String, under dir: String) -> String? {
    guard let en = FileManager.default.enumerator(atPath: dir) else { return nil }
    for case let f as String in en where f.hasSuffix(".srt") && (f as NSString).lastPathComponent.hasPrefix(stem) {
        return (dir as NSString).appendingPathComponent(f)
    }
    return nil
}

// MARK: - burn-in (Core Animation)

/// Subtitle glyphs in one solid colour, NO stroke. The readability outline is built
/// separately (see renderTextImage) by offset-compositing — a centered `.strokeWidth`
/// stroke is what closed up the counters (the enclosed holes) of a/e/o/g and made them mud.
func subtitleAttr(_ s: String, fontSize: CGFloat, color: NSColor) -> NSAttributedString {
    let style = NSMutableParagraphStyle()
    style.alignment = .center
    style.lineBreakMode = .byWordWrapping
    return NSAttributedString(string: s, attributes: [
        .font: NSFont.systemFont(ofSize: fontSize, weight: .semibold),
        .foregroundColor: color,
        .paragraphStyle: style,
    ])
}

/// Render a subtitle line to a CGImage. CATextLayer text does NOT draw inside the offline
/// AVVideoCompositionCoreAnimationTool render, so we rasterize the text ourselves and hand a
/// plain CALayer the image — that composites reliably.
///
/// The outline is drawn by compositing the black glyphs at N points around a small circle,
/// then painting the white glyphs on top. Unlike a centered `.strokeWidth` stroke (which grows
/// INWARD and swallows letter counters), this only adds ink OUTSIDE the glyph, so the holes in
/// a/e/o/g stay open and crisp.
func renderTextImage(_ text: String, width: CGFloat, height: CGFloat, fontSize: CGFloat) -> CGImage? {
    let scale: CGFloat = 2
    let w = max(1, Int(width * scale)), h = max(1, Int(height * scale))
    guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                              space: CGColorSpaceCreateDeviceRGB(),
                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
    ctx.setShouldAntialias(true); ctx.setShouldSmoothFonts(true)
    // Bottom-up context (flipped:false) so the resulting CGImage displays right-side-up when
    // set as a CALayer's contents (CGContext bitmaps are bottom-origin).
    let ns = NSGraphicsContext(cgContext: ctx, flipped: false)
    NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = ns

    let fs = fontSize * scale
    let inset = 14.0 * scale
    let maxW = CGFloat(w) - inset * 2
    let opts: NSString.DrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
    let white = subtitleAttr(text, fontSize: fs, color: .white)
    let black = subtitleAttr(text, fontSize: fs, color: .black)
    let bounds = white.boundingRect(with: NSSize(width: maxW, height: CGFloat(h)), options: opts)
    let ty = max(inset, (CGFloat(h) - bounds.height) / 2)
    let rect = NSRect(x: inset, y: ty, width: maxW, height: bounds.height)

    // Outline: thin enough (≈4.5% of glyph size) to leave counters open, dense enough (16 points)
    // to read as a smooth ring rather than a star. This is the anti-mud fix.
    let ow = max(1.5, fs * 0.045)
    let n = 16
    for i in 0..<n {
        let a = CGFloat(i) / CGFloat(n) * 2 * .pi
        black.draw(with: rect.offsetBy(dx: cos(a) * ow, dy: sin(a) * ow), options: opts)
    }
    white.draw(with: rect, options: opts)

    NSGraphicsContext.restoreGraphicsState()
    return ctx.makeImage()
}

func burn(video: String, srtPath: String, outPath: String) {
    let cues = parseSRT(srtPath)
    guard !cues.isEmpty else {
        note("no subtitle cues (silent/short audio?) — kept the .srt, skipped burn")
        return
    }
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
    note("⧉ burning \(cues.count) subtitles into \((outPath as NSString).lastPathComponent) (\(clock(CMTimeGetSeconds(dur))) video)…")
    let t0 = Date()
    if #available(macOS 15.0, *) {
        sync { try await export.export(to: out, as: .mov) }
    } else {
        export.outputURL = out; export.outputFileType = .mov
        let sem = DispatchSemaphore(value: 0)
        export.exportAsynchronously { sem.signal() }
        sem.wait()
        if export.status != .completed { die("burn export failed: \(export.error?.localizedDescription ?? "unknown")") }
    }
    print("✓ \(outPath)  ·  burned in \(clock(Date().timeIntervalSince(t0)))")
}

// MARK: - main

// Hidden dev tool: render one subtitle line onto a mid-grey backdrop → PNG, so the glyph
// rendering (counters of a/e, outline weight) can be eyeballed headlessly without a full burn.
//   rec-subtitle --render-sample "some text with a and e" out.png
if CommandLine.arguments.dropFirst().first == "--render-sample" {
    let a = Array(CommandLine.arguments.dropFirst())
    let text = a.count > 1 ? a[1] : "already like that. As you can see — a, e, o, g, 8."
    let outPng = (a.count > 2 ? a[2] : "sample.png") as NSString
    let bw = 1500, bh = 220
    guard let bg = CGContext(data: nil, width: bw, height: bh, bitsPerComponent: 8, bytesPerRow: 0,
                             space: CGColorSpaceCreateDeviceRGB(),
                             bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { die("ctx") }
    bg.setFillColor(CGColor(red: 0.30, green: 0.36, blue: 0.46, alpha: 1))
    bg.fill(CGRect(x: 0, y: 0, width: bw, height: bh))
    if let img = renderTextImage(text, width: CGFloat(bw), height: CGFloat(bh), fontSize: CGFloat(bh) * 0.42) {
        bg.draw(img, in: CGRect(x: 0, y: 0, width: bw, height: bh))
    }
    guard let out = bg.makeImage() else { die("makeImage") }
    let rep = NSBitmapImageRep(cgImage: out)
    guard let data = rep.representation(using: .png, properties: [:]) else { die("png encode") }
    try? data.write(to: URL(fileURLWithPath: outPng.expandingTildeInPath))
    note("wrote \(outPng.expandingTildeInPath)")
    exit(0)
}

var args = Array(CommandLine.arguments.dropFirst())

// Headless check of the vocabulary rules — no media, no Whisper. Run by build.sh.
if args.contains("--self-test") { vocabularySelfTest() }

// Repair an EXISTING transcript in place (a take you already burned, a .srt from anywhere).
if let i = args.firstIndex(of: "--fix-srt") {
    guard i + 1 < args.count else { die("--fix-srt needs a .srt path") }
    let path = (args[i+1] as NSString).expandingTildeInPath
    guard FileManager.default.fileExists(atPath: path) else { die("no such .srt: \(path)") }
    let vopt: String? = { if let j = args.firstIndex(of: "--vocab"), j + 1 < args.count { return args[j+1] }; return nil }()
    let v = loadVocabulary(explicit: vopt, near: (path as NSString).deletingLastPathComponent)
    if v.isEmpty { die("no vocabulary found — ship bin/recburn-vocabulary.json or write ~/.config/recburn/vocabulary.json") }
    note("⧉ vocabulary: \(v.source)")
    correctSRT(path, v)
    print("✓ \(path)")
    exit(0)
}

guard let video = args.first, !video.hasPrefix("-") else {
    die("""
    usage:
      rec-subtitle <video> [--mic voice.m4a] [--model NAME]           → <stem>.srt sidecar
      rec-subtitle <video> --burn [--srt FILE] [--mic voice.m4a]      → <stem>-subtitled.mov
      rec-subtitle --fix-srt <file.srt> [--vocab FILE]                → align proper nouns in place
      rec-subtitle --self-test                                        → check the vocabulary rules

    vocabulary (proper nouns Whisper mishears — Paketti, Renoise, Lackluster):
      --vocab FILE   use this vocabulary  ·  --no-vocab   disable bias + correction
      Default search: ./.recburn-vocabulary.json, ~/.config/recburn/vocabulary.json,
      then recburn-vocabulary.json beside this binary. Terms are fed to Whisper as
      --initial_prompt AND the finished .srt is swept for known/sound-alike mishearings.
    """)
}
let videoPath = (video as NSString).expandingTildeInPath
args.removeFirst()
func opt(_ name: String) -> String? { if let i = args.firstIndex(of: name), i + 1 < args.count { return (args[i+1] as NSString).expandingTildeInPath }; return nil }
let doBurn = args.contains("--burn")
// Default is LOCAL (reliable). --mini is an explicit opt-in that itself falls back to local.
let useMini = args.contains("--mini")
let model = opt("--model")
// Vocabulary: the proper nouns this recording is going to contain. Feeds BOTH the Whisper
// bias (--initial_prompt) and the correction sweep over the finished .srt.
let noVocab = args.contains("--no-vocab")
let vocab = noVocab ? Vocabulary()
                    : loadVocabulary(explicit: opt("--vocab"), near: (videoPath as NSString).deletingLastPathComponent)
if !vocab.isEmpty { note("⧉ vocabulary: \(vocab.source) — \(vocab.terms.count) term(s)") }
// An explicit --prompt still wins; otherwise the vocabulary becomes the bias.
let prompt = opt("--prompt") ?? vocabularyPrompt(vocab)   // → whisper --initial_prompt
let lang = opt("--lang") ?? "en"   // default English; pass --lang auto to auto-detect
let micAudio = opt("--mic")
let stem = (videoPath as NSString).deletingPathExtension

// Get the .srt: use --srt if given, else an existing sidecar, else transcribe.
var srt = opt("--srt") ?? (stem + ".srt")
if !FileManager.default.fileExists(atPath: srt) {
    let source = micAudio ?? videoPath
    if useMini {
        srt = transcribeOnMini(source, model: model, lang: lang, stem: stem, prompt: prompt)
    } else {
        let produced = transcribe(source, model: model, lang: lang, outStem: stem + ".srt", prompt: prompt)
        // whisp/whisper name by the SOURCE stem; normalize to <video-stem>.srt for predictability.
        if produced != stem + ".srt" { try? FileManager.default.removeItem(atPath: stem + ".srt"); try? FileManager.default.copyItem(atPath: produced, toPath: stem + ".srt") }
        srt = stem + ".srt"
    }
}

// The repair half of the vocabulary: Whisper's bias is a nudge, not a guarantee, so the
// finished transcript is swept before anything is burned into the picture. Idempotent — a
// transcript that is already right is left byte-for-byte alone.
if !noVocab { correctSRT(srt, vocab) }

print("✓ \(srt)")

if doBurn {
    burn(video: videoPath, srtPath: srt, outPath: stem + "-subtitled.mov")
}
