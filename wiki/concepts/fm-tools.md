# FM tools — giving the on-device LLM hands (FoundationModels tool-calling)

`bin/fm` / `fm-chat` today is a closed-book chatbot: it answers from the ~3B model's own
weights, nothing else. FoundationModels ships a **`Tool` protocol** — the model can call
Swift functions mid-generation and fold the results back into its answer. That turns the
chat from "what the model remembers" into "what the model can *go find out*" — grounded,
current, and specific to this fleet.

## How it fits our architecture (the elegant part)

Tools register on the `LanguageModelSession` **on the Mini, in-process**. So when the laptop
sends one prompt over Syncthing, the Mini's FM session can call local tools (read a file,
run an embedding search, read the climate JSON) *during that single generation* and return
the finished, grounded answer. **Tool calls do not bounce back to the laptop** — it's still
one Syncthing round-trip, no matter how many tools fire. The transport cost we measured
(~4–11s) doesn't multiply.

Implementation: extend `bin/fm.swift` to register a set of `Tool` conformers and pass them
to `LanguageModelSession(tools:instructions:)`. `fm-worker` stays unchanged (or gains a
`--tools` flag). Each tool's `call()` is a tiny Swift wrapper that either reads a file or
shells out to one of the `apple-*` CLIs already in `bin/`. Exact API surface gets verified at
build time on the Mini (FM is macOS-26-only; can't compile-test on the laptop).

## The security boundary (unchanged)

The worker's existing rule holds: **a job never carries a shell command, and FM never gets
an arbitrary-shell tool.** Tools are an *allowlist* of named, fixed-purpose Swift functions —
exactly like `panel-worker`'s registered-action allowlist. "Search this folder" is a tool;
"run this bash" is never a tool. Read-only tools first; any write/side-effect tool (send mail,
create reminder) gets added deliberately, one at a time.

## The catalog — grouped by what they reach

### A. On-device ML (already built as CLIs — these become tools almost for free)
| Tool | Wraps | "Chat can now…" |
|---|---|---|
| `semantic_search(query, folder)` | `apple-semantic-match` / `vault-grep` (NLEmbedding) | **RAG** — "find my notes about X" → grounds the answer in real files |
| `ocr(file)` | `vision-ocr` (Vision `VNRecognizeText`) | "what does this PDF/screenshot say?" |
| `image_similar(image, folder)` | `apple-image-similar` (Vision FeaturePrint) | "find the screenshot like this one / dupes" |
| `entities(text)` / `keywords(text)` | `apple-ner` / `apple-keywords` (NLTagger) | "who/what is named in this?" |
| `translate(text, lang)` | `apple-translate` (Translation framework) | "say that in Finnish" |
| `sentiment(text)` | `apple-sentiment` | tone/triage scoring |

All of these are on-device, no network, no cost — the same pedigree as FM itself.

### B. Fleet + system state (read a file or run a tiny query)
| Tool | Source | "Chat can now…" |
|---|---|---|
| `now()` | system clock | the model doesn't know the date/time — this fixes it (cheapest, highest-value first tool) |
| `home_climate()` | `~/work/comms/queue/homepod-climate/` JSON | "what's the temperature at home?" |
| `fleet_status()` | the `*-heartbeat.json` files | "is the Mini busy? is OCR running?" |
| `whisp_search(query)` | the whisp-transcripts corpus | "find where I talked about X on YouTube" |
| `mail_search(query)` | Mail SQLite (mail-flag pipeline infra) | "find emails from X" (read-only) |

### C. Apple system frameworks (Apple-native, read-only to start)
| Tool | Framework | "Chat can now…" |
|---|---|---|
| `calendar(range)` | EventKit | "what's on my calendar this week?" |
| `reminders()` | EventKit | "what's due?" |
| `contacts(name)` | Contacts | look up a person |

(These need TCC grants on the Mini; EventKit/Contacts prompts once, like the topbar grants.)

### Complement: structured output (`@Generable`)
Not a "tool" but the other half — annotate a Swift struct with `@Generable`/`@Guide` and FM
returns a **validated typed value** (constrained decoding, not parse-and-pray). This is what
makes FM a reliable *extractor* for the trigger→worker chassis: "pull the action items / the
invoice fields / the routing decision" → a struct, every time. Pairs naturally with tools
(a tool fetches text, structured output shapes the result).

## Recommended first batch (proves the three tool shapes)
1. **`now()`** — pure-compute tool, trivial, immediately useful (fixes "what day is it").
2. **`home_climate()`** — file-read tool against existing fleet data.
3. **`semantic_search(query, folder)`** — the flagship: on-device RAG via NLEmbedding, the
   one that makes the chat genuinely more than its weights.

If those three round-trip cleanly, the rest of the catalog is the same pattern repeated.

## Is FM the engine for the apple skill itself? (the real destination)

Yes — this is literally the apple skill's stated identity: *"the LLM-driven Automator."*
Until now the "LLM" driving it has been Claude (cloud). FM tool-calling means the apple
skill's own curated actions could be driven by an **on-device, Apple-native, zero-cost,
zero-network** model instead. You chat in plain language; FM picks the action and fills the
arguments; the action runs. That's the Automator brain, on-device. Three honest boundaries:

**1. Which tools — not all `bin/` scripts are equal.**
- ✅ **Read-only / compute / headless-batch** (OCR a folder, embed+search a vault, NER,
  translate, image-dedup, transcribe, mirror, summarize, classify) — perfect fit. These are
  what the apple skill calls "the LLM-driven Automator: any folder-batch transform." FM
  routes them beautifully.
- ⚠️ **Side-effecting UI automation** (Finder moves, app activation, window tiling, System
  Events keystrokes, sending Mail) — gated, one at a time, read-only-first. And the hard ban
  stands: **never give an LLM a System-Events-keystroke tool that fires on the machine
  someone is actively using** (see `feedback_never_ui_hijack_active_session`). Side effects go
  through side-channel pipelines (inbox files, the panel allowlist), not simulated keystrokes.

**2. Where it runs — FM is on the Mini, so it drives the *server-side* fleet.**
FM tools execute on the Mini, in-process. So FM-as-Automator-brain naturally drives the
**headless fleet** (OCR/embeddings/transcribe/mirror/translate) — not "activate an app on
the laptop I'm typing on," because that has to happen where the user is. The laptop can't
host its own FM node yet (macOS 15.6.1; FM needs 26). When the laptop is on 26, a local
fm-worker makes the same brain drive *local* actions too.

**3. It's an allowlist, not "run any script."**
FM never gets a "exec any bin/ tool" tool — that reintroduces the arbitrary-shell hole and
the UI-hijack risk. It gets a **curated set of named actions**, each a Swift `Tool` wrapper.
This is the *same allowlist* the **Apple Panel** (`apple-panel`) and **panel-worker** already
expose as cards-with-Run-buttons. So the clean unification is:

> **FM tool-calling = the natural-language front door to the Apple Panel action registry.**
> The Panel gives each capability a card + a Run button; FM lets you say it in words, picks
> the card, and fills the arg. Same curated, safe action set — two front doors.

**The capability ceiling (be honest):** a 3B model is a good *router over a defined action
set* and a good *summarize/classify/extract* engine — not a heavy multi-step reasoner. So the
realistic design is **tiered**: FM handles the fast/free/private/on-device common cases ("OCR
these, translate that, search my vault, which card fits this request"); Claude/cloud stays the
heavy reasoner for novel multi-step orchestration. FM doesn't replace Claude here — it makes
the *frequent, well-defined* automations free and local.

## See also
- [on-device-ml.md](on-device-ml.md) — the framework family + the fm-worker fleet plumbing
- [machine-card-protocol.md](machine-card-protocol.md) — where `fleet_status()` reads from
- [apple-panel](../../commands/apple-panel.md) / `bin/panel-worker` — the same curated action
  allowlist FM would route over in natural language
