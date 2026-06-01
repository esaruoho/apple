#!/usr/bin/env swift
// apple-ner — Apple-native named-entity recognition pipe.
//
// Reads UTF-8 text on stdin and emits one JSON object per recognised entity:
//   {"text": "Walter Russell", "type": "PersonalName", "line": 42, "char": 12}
//
// Uses NaturalLanguage.NLTagger with the .nameType scheme. On-device, ANE-
// accelerated (10.15+), zero third-party deps. Three entity types:
//   - PersonalName       (Tesla, Russell, Bearden, Esa Ruoho)
//   - PlaceName          (Colorado Springs, Aalto-University)
//   - OrganizationName   (NASA, Apple, MERLib)
//
// For archive cross-decade tracing: pipe a quote ledger or a deep-read file
// in, extract every person/place/org mentioned, build the graph that says
// "who co-occurs with whom" across the corpus.
//
// Usage:
//   cat sources/hilarion/HILARION-COOKE-QUOTE-LEDGER.md | apple-ner
//   apple-ner < file.md
//   apple-ner --json < file.md     # default — one JSON line per entity
//   apple-ner --table < file.md    # 'TYPE  text  (line:char)' columns

import Foundation
import NaturalLanguage

let args = CommandLine.arguments.dropFirst().map { String($0) }
let mode: String = args.first(where: { $0 == "--table" || $0 == "--json" }) ?? "--json"

// Read all stdin into a single string
let stdin = FileHandle.standardInput
let data  = stdin.readDataToEndOfFile()
guard let fullText = String(data: data, encoding: .utf8), !fullText.isEmpty else {
    FileHandle.standardError.write("apple-ner: empty stdin\n".data(using: .utf8)!)
    exit(1)
}

let tagger = NLTagger(tagSchemes: [.nameType])
tagger.string = fullText

// Build a line-number index so we can map character offset → line:char
var lineStarts: [String.Index] = [fullText.startIndex]
var idx = fullText.startIndex
while idx < fullText.endIndex {
    if fullText[idx] == "\n" {
        lineStarts.append(fullText.index(after: idx))
    }
    idx = fullText.index(after: idx)
}

func lineCharFor(_ pos: String.Index) -> (line: Int, char: Int) {
    // binary search
    var lo = 0, hi = lineStarts.count - 1, ans = 0
    while lo <= hi {
        let mid = (lo + hi) / 2
        if lineStarts[mid] <= pos { ans = mid; lo = mid + 1 }
        else { hi = mid - 1 }
    }
    let line = ans + 1
    let char = fullText.distance(from: lineStarts[ans], to: pos) + 1
    return (line, char)
}

let opts: NLTagger.Options = [.omitWhitespace, .omitPunctuation, .joinNames]
let scheme: NLTagScheme = .nameType
let wanted: Set<String> = ["PersonalName", "PlaceName", "OrganizationName"]

var hits: [(text: String, type: String, line: Int, char: Int)] = []
tagger.enumerateTags(in: fullText.startIndex..<fullText.endIndex,
                       unit: .word, scheme: scheme, options: opts) { tag, range in
    if let tag = tag, wanted.contains(tag.rawValue) {
        let text = String(fullText[range])
        let (l, c) = lineCharFor(range.lowerBound)
        hits.append((text: text, type: tag.rawValue, line: l, char: c))
    }
    return true
}

// Deduplicate identical entities at the same position
var seen = Set<String>()
hits = hits.filter {
    let key = "\($0.line):\($0.char):\($0.text)"
    if seen.contains(key) { return false }
    seen.insert(key); return true
}

if mode == "--table" {
    let maxTextLen = hits.map { $0.text.count }.max() ?? 30
    for h in hits {
        let padded = h.text.padding(toLength: min(maxTextLen, 40), withPad: " ", startingAt: 0)
        print("\(h.type.padding(toLength: 18, withPad: " ", startingAt: 0))  \(padded)  (line \(h.line):\(h.char))")
    }
} else {
    for h in hits {
        let obj: [String: Any] = ["text": h.text, "type": h.type,
                                    "line": h.line, "char": h.char]
        if let data = try? JSONSerialization.data(withJSONObject: obj,
                                                   options: [.sortedKeys]),
           let s = String(data: data, encoding: .utf8) {
            print(s)
        }
    }
}

FileHandle.standardError.write(
    "  \(hits.count) entities (\(hits.filter{$0.type=="PersonalName"}.count) persons, "
    + "\(hits.filter{$0.type=="PlaceName"}.count) places, "
    + "\(hits.filter{$0.type=="OrganizationName"}.count) orgs)\n"
    , using: .utf8)

// Wee helper because FileHandle.write doesn't accept a String + encoding directly.
extension FileHandle {
    func write(_ s: String, using encoding: String.Encoding) {
        if let d = s.data(using: encoding) { write(d) }
    }
}
