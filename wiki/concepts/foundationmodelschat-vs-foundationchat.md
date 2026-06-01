---
description: Your FoundationModelsChat (single-file AppKit Mac app) vs Dimillian/FoundationChat (the 338-star SwiftUI reference app) — what each is, where they diverge.
---

# FoundationModelsChat vs FoundationChat

Two chat apps over Apple's on-device FoundationModels LLM. One is yours
(`~/work/apple/FoundationModelsChat/`), one is the community reference
(`~/work/FoundationChat/`, cloned from
[Dimillian/FoundationChat](https://github.com/Dimillian/FoundationChat),
338 stars — surfaced in the 2026-06-02 last30days run as the top GitHub project).

## What FoundationChat (Dimillian) is

Thomas Ricouard's (@Dimillian, the IceCubes/Medium dev) **demonstration project**
showcasing the framework's idiomatic surface. It is the canonical "this is how you
use Foundation Models the Apple way" repo.

- **Xcode project**, 15 Swift files, ~569 LOC, MVVM-ish SwiftUI.
- **Multiplatform**: iOS / iPadOS / macOS / visionOS 26.
- **SwiftData** persistence — multiple `Conversation`s, each with `Message`s, swipe-to-delete.
- **Structured streaming**: `@Generable MessageGenerable` streamed via
  `session.streamResponse(generating:)` — the response itself is a typed struct, not text.
- **Tool calling**: `WebAnalyserTool` extracts title/thumbnail/description from a URL.
- **Auto-summarization** of each conversation.
- Ships an **EXAMPLES/ folder** (Basic, Structured Output, Streaming, Tool Calling,
  Performance & Safety, Complete Chat App + a QUICK_REFERENCE and FOUNDATION_MODELS_RULES)
  — genuinely the best free tutorial corpus for the framework. Worth reading regardless.

It is a teaching app: clean, idiomatic, SDK-forward. Not whitelabeled (named author),
needs Xcode to build, optimized to show off the framework's features.

## What FoundationModelsChat (yours) is

A **single-file AppKit Mac app** — `main.swift`, 764 lines, built by `build.sh` with
`xcrun swiftc`, no Xcode project, no Homebrew/pip/npm. Apple-native imports only:
AppKit, WebKit, FoundationModels, PDFKit, Vision, ImageIO, UniformTypeIdentifiers.

- **Mac-only**, in-process, one stateful `LanguageModelSession`.
- **Whitelabeled** — nothing names a person, host, or service (your house style).
- **Document ingestion**: drag a PDF/.txt/.md/.rtf/image onto the window → PDFKit text
  layer or on-device **Vision OCR** for scans → sent to the model. FoundationChat has
  no local-file ingestion (its "attachment" is web-URL metadata).
- **MathML rendering**: model is asked to emit MathML, WebKit renders it with the system
  math font, plus a built-in LaTeX→MathML fallback for `$…$`. FoundationChat renders plain text.
- **ENVOY-style persistence**: every turn written immediately to
  `~/Documents/FoundationModelsChat/<ts>/chat-<ts>.md` + `events.jsonl` (append-only event
  log + human-readable view — matches your `envoy_livefile_doctrine`). FoundationChat
  uses a SwiftData store (DB, not a portable folder).

## Head-to-head

| | FoundationModelsChat (yours) | FoundationChat (Dimillian) |
|---|---|---|
| Build | `build.sh` + swiftc, no Xcode | Xcode project required |
| UI | AppKit + WebKit, single window | SwiftUI, multiplatform |
| LOC / files | 764 / 1 file | 569 / 15 files |
| Platforms | macOS 26 only | iOS/iPadOS/macOS/visionOS 26 |
| Sessions | one stateful session | many SwiftData conversations |
| Output | text → Markdown/MathML in WebKit | `@Generable` typed struct, streamed |
| Tools | none (yet) | WebAnalyserTool (URL → metadata) |
| Local files | PDF/text/image drag-in + Vision OCR | none |
| Persistence | append-only `.md` + `events.jsonl` | SwiftData DB |
| Identity | whitelabeled | named author, demo repo |
| Purpose | a tool you actually use | a reference to learn from |

## What got borrowed (2026-06-02)

Four of his patterns grafted onto `main.swift`, all Apple-native, compile-verified
against the macOS 26.2 SDK:

1. **Streaming** — `session.streamResponse(to:)`; each cumulative `Snapshot.content`
   updates only the last chat bubble via `evaluateJavaScript` (no full WKWebView
   reload, so no flicker / scroll reset).
2. **`prewarm()`** at launch — warms the model so the first reply isn't slow.
3. **Context-window recovery** — catch `LanguageModelSession.GenerationError.exceededContextWindowSize`,
   summarize the prior turns, rebuild a fresh tool-enabled session seeded with that
   summary, retry once. Directly addresses the 4096-token limit (the #1 complaint in
   the last30days research).
4. **Native `WebReaderTool`** — his `WebAnalyserTool` uses SwiftSoup (banned). Mine
   fetches with `URLSession` and converts HTML→text with `NSAttributedString`'s
   importer. `Tool.call` returns `String` (which is `PromptRepresentable`) — the real
   SDK has no `ToolOutput` wrapper despite what the older EXAMPLES show.

**Deliberately NOT borrowed:** his `@Generable MessageGenerable` wrapping the *chat
reply*. Your reply is plain text feeding the Markdown→MathML renderer, and stream
snapshots are `String` anyway — `@Generable` belongs on tool `Arguments`, where it's
used. Forcing it on the reply would fight the math pipeline.

What yours still has that his doesn't: real document/OCR ingestion, MathML, single-file
swiftc build, whitelabeling, the portable append-only event log, and the remote-Mac
bridge fallback. Different goals — his is a tutorial, yours is daily-driver
infrastructure. The EXAMPLES/ folder in his repo is the best reason to keep the clone.

Related: [[on-device-ml]], [[envoy-foundry-compatibility]],
`~/.claude/projects/.../memory/fm_worker_fleet_llm.md`.
