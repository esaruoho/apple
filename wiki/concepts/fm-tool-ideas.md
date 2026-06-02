---
description: Tool-calling roadmap for FoundationModels — what's built, what's next, and the three surfaces (fm CLI / apple-do / FoundationModelsChat GUI) that expose the tools. A small on-device LLM gets POWERFUL once it can call Apple-native tools.
---

# FM tool-calling — what's built, and what else to give the model

**The premise.** FoundationModels is a ~3B on-device model. On its own it's a decent
writer with no memory of *now*, no access to *your* data, and a tiny context window.
**Tools fix all three.** A `Tool` (name + description + `@Generable` Arguments +
`call()` returning a `String`/`ToolOutput`) lets the model reach out, get grounded
facts, and answer from them. The model stays small; the *tools* make it capable.

Two facts that shape everything:
1. **Tools run where the model runs.** For Esa that's the **Mini** (macOS 26). A tool
   can touch the Mini's disk, the merlib archive, the apple `bin/` toolset, the fleet
   queue, and the network — none of which the laptop (macOS 15) could do, because the
   laptop can't host FoundationModels at all.
2. **Reliability scales with simplicity.** A 3B model calls a tool well when the tool
   has a clear name, a one-line description, and 1–3 obvious args. Keep tools small and
   read-only first; add write/destructive tools only behind confirmation.

---

## The three surfaces (same tools, different front doors)

| Surface | What it is | Who picks the tool | Where it runs |
|---|---|---|---|
| **`fm` / `fm-chat`** (`bin/fm.swift`) | the CLI engine + Syncthing-bridge clients | the **LLM**, from natural language | model on the Mini; reachable from any Mac |
| **`apple-do`** (`bin/apple-do`) | scriptable, **no-LLM** runner, Tab-cycles capabilities | **you** | wherever you run it (Mini-only caps route via ssh) |
| **`FoundationModelsChat`** (GUI `.app`) | native AppKit window, streaming, drag-PDF, MathML | the **LLM**, in a window | in-process, **Mini only** (macOS 26) |

A tool is registered **where the model runs**: in `fm.swift` for the bridge, and
separately in `FoundationModelsChat/main.swift` for the GUI (same Tool code, two
registration sites). `apple-do` doesn't use the model at all — it shells straight to
the backend and prints the answer.

---

## Status — what's built (2026-06-02)

**`fm` CLI: 16 tools live.** **GUI: only WebReader (needs the other 15 ported).**
**`apple-do`: 6 capabilities wired.**

| Tool | fm CLI | GUI | apple-do | Backend |
|---|:---:|:---:|:---:|---|
| `currentDateTime` | ✅ | ⬜ | `now` ✅ | `Date()`+`DateFormatter` (pure Swift) |
| `calculator` | ✅ | ⬜ | — | recursive-descent parser (pure Swift) |
| `unitConvert` | ✅ | ⬜ | — | `Measurement`/`Dimension` (pure Swift) |
| `systemState` | ✅ | ⬜ | — | battery/disk/thermal |
| `webReader` | ✅ | ✅ | — | `URLSession` + HTML→text |
| `semantic_search` | ✅ | ⬜ | `search` ✅ | **`vault-rag` → CoreML MiniLM (ANE)** |
| `readFile` | ✅ | ⬜ | — | file→text |
| `ocr` | ✅ | ⬜ | `ocr` ✅ | `vision-ocr` (Vision `VNRecognizeText`) |
| `entities` | ✅ | ⬜ | — | `apple-ner` (NLTagger) |
| `keywords` | ✅ | ⬜ | — | `apple-keywords` |
| `translate` | ✅ | ⬜ | — | `apple-translate` (Translation) |
| `sentiment` | ✅ | ⬜ | — | `apple-sentiment` |
| `imageSimilar` | ✅ | ⬜ | — | `apple-image-similar` (Vision FeaturePrint) |
| `spotlight` | ✅ | ⬜ | `spotlight` ✅ | `mdfind` |
| `fleetStatus` | ✅ | ⬜ | `fleet` ✅ | reads `*-heartbeat.json` |
| `homeClimate` | ✅ | ⬜ | `home` ✅ | `homepod-now` (HomePod sensor log) |

**The headline gap:** the GUI is at 1/16. Porting the proven 15 into
`FoundationModelsChat/main.swift` is the biggest single win and is low-risk (the code
already works in `fm.swift`).

---

## 1. Ground the model in reality — DONE ✅ (cheap, high-value, safe)

The model literally doesn't know the date or do reliable arithmetic. All four shipped
in the `fm` CLI; trivial to port to the GUI.

- **`currentDateTime`** ✅ — now (date/time/weekday/timezone). The model stops guessing "today."
- **`calculator`** ✅ — safe recursive-descent arithmetic (no `NSExpression`/eval; can't crash).
- **`unitConvert`** ✅ — length/mass/temp/volume/duration via `Measurement`.
- **`systemState`** ✅ — battery, disk free, thermal, uptime → "is the Mini OK?".

## 2. The killer category — the user's OWN knowledge (local RAG) — DONE + UPGRADED ✅

This is the one that matters, and it's now genuinely good.

- **`semantic_search`** ✅ — chunks notes into header-aware **sections**, embeds each via
  **`all-MiniLM-L6-v2` as a CoreML model on the Neural Engine** (`bin/vault-rag`), ranks
  chunks, returns quotable passages. **The upgrade was decisive:** with the old
  `NLEmbedding`, "AppleScriptObjC" couldn't surface `asobjc.md` even in the top 30; with
  MiniLM it's **#2**, and the chat gives a correct grounded answer. Retrieval is local +
  zero-token; the LLM only reasons over the few passages pulled. RAG, entirely on-device.
- **`readFile`** ✅ — given a path, file→text (txt/pdf/rtf/image-OCR) so the model can quote
  the full passage.
- **`spotlight`** ✅ — `mdfind` for files by name/content/tag across the Mac.
- **`entities`** ✅ / **`keywords`** ✅ — `apple-ner` / `apple-keywords` over a file/folder.
- **Still ideas:** **`searchArchive`** over the full 600k-line merlib corpus (point
  `vault-rag --root` at the archive, warm its cache once); **`paperLookup`** (DOI →
  `scihub` → text → summarize); **`consilience`** (`vault-consilience` cross-source).

The strategic point: **FM (reason) × MiniLM embeddings (retrieve) × the archive (truth)
= a private research assistant.** The MiniLM swap was the retrieval half finally working.

## 3. Apple personal data (EventKit / Contacts / Notes / Music / Mail) — IDEAS ⬜

All first-party, all on-device. Most need a one-time TCC grant (prompt once, like the
AppleToolbox grants).

- **`calendar`** — read events / "am I free Thursday?" (EventKit). Add-event behind confirmation.
- **`reminders`** — list/create reminders (EventKit). "Remind me to ramp the flag."
- **`contacts`** — look up a person's email/phone (Contacts).
- **`notesSearch`** — query Apple Notes (the Notes exporter already exists).
- **`nowPlaying` / `playMusic`** — read or control Music.app (ScriptingBridge).
- **`mailSearch`** — query the local Mail SQLite/.emlx (the mail-flag pipeline already reads
  it) — "what did Sal say about Automator?" from the actual mailbox. Read-only; **never**
  poll Mail via osascript (see `mail-app-internal-behaviors.md`).

## 4. The fleet & Cloudcity (Esa-specific, the most *fun*) — PARTLY DONE

FM-on-Mini already lives in the fleet. Let it act on the fleet.

- **`fleetStatus`** ✅ — reads the published heartbeats. "Is whisp backed up? Is the Mini hot?"
- **`homeClimate`** ✅ — HomePod temp/humidity from the watcher log (`homepod-now`).
- **`submitOCR` / `submitTranscription`** ⬜ — drop a file into the Syncthing inbox (the
  existing trigger→worker chassis). "OCR this PDF" → it just happens.
- **`speak`** ⬜ — TTS the answer via `voicebox-submit` → the Mini's Voicebox. A GUI app you
  live in is the natural place for "read it to me."
- **`notifyPhone`** ⬜ — `imessage`/`notify-iphone` to banner the iPhone. "Tell me when the
  build's done." (write — behind confirmation.)
- **`stashSearch`** ⬜ — query the 4TB CLOUDCITY archive (`!pk stash`).
- **`runShell`** ⬜ — a **whitelisted, read-only** command via the file-bridge. Strictly
  allow-listed (`ls`, `git status`, `df`) — **never a blank shell.** The dangerous one; gate hard.

## 5. Web & world (network — opt-in by nature) — PARTLY DONE

- **`webReader`** ✅ — fetch a URL → readable text (in BOTH the CLI and the GUI already).
- **`webSearch`** ⬜ — a query → top results (beyond a single-URL fetch). No clean Apple-native
  search API; would need a provider — weigh against the no-third-party pedigree.
- **`weather`** ⬜ — WeatherKit, "coat tomorrow?" (outdoor, vs `homeClimate` = indoor).
- **`travelTime`** ⬜ — MapKit ETA between two places.

## 6. Domain tools (where Esa actually works) — IDEAS ⬜

- **`renoise` / `paketti`** — drive Renoise via the existing **ReMCP/OSC** bridge:
  "make an 8-step bassline," "render the song." The model as a tracker assistant.
- **`corum`** — the Tesla Extra-Coil 9-step calculator (the skill exists). "What voltage from
  a 24-inch coil at 150 kHz?" → real numbers, not a guess.
- **`rbiAnalyze`** — run the Rhythmic Balanced Interchange lens over text.
- **`gumroad` / `financing`** — "how much did I make this month?" from real data (the `gumroad`
  CLI exists).

## 7. Vision / media — PARTLY DONE

- **`ocr`** ✅ — Vision OCR on a file/image (`vision-ocr`). Also covered by the GUI's drag-drop.
- **`imageSimilar`** ✅ — `apple-image-similar` → find dupes / "the screenshot like this one."
- **`transcribe`** ⬜ — Speech / whisp on an audio file → text the model can use.

---

## Build infrastructure & gotchas (learned the hard way, 2026-06-02)

- **`@Generable` needs FULL XCODE on the build machine.** The macro plugin
  (`FoundationModelsMacros`) ships only with Xcode, NOT CommandLineTools — without it
  `swiftc` fails with *"external macro implementation type … could not be found."* `-sdk`
  doesn't help (a plugin isn't an SDK). Install Xcode 26, then once: `sudo xcode-select -s
  /Applications/Xcode.app && sudo xcodebuild -license accept && sudo xcodebuild -runFirstLaunch`.
- **The MiniLM CoreML model** is built by `bin/build-minilm.sh` → `bin/minilm-convert.py`
  (python3.12 venv). **Pin `transformers==4.44.2` `torch==2.5.1` `numpy<2`** — numpy 2 breaks
  coremltools' int-cast (*"only 0-dimensional arrays can be converted to Python scalars"*),
  and coremltools dropped ONNX input, so `torch.jit.trace` + numpy<2 is the path. The
  `.mlpackage`+`vocab.txt` live in `models/minilm/` (gitignored); the compiled `.mlmodelc` is
  cached at `~/.cache/apple/`.
- **Two registration sites.** A tool exists for the model only where it's registered: the
  Mini's `fm.swift` `groundingTools` array (bridge/CLI) AND the GUI's
  `LanguageModelSession(tools:)` in `FoundationModelsChat/main.swift`. Porting a tool to the
  GUI = copy its `Tool` struct into `main.swift` and add it to that array.
- **`apple-do` is the no-model twin.** Same capabilities, no FoundationModels — `bin/apple-do`
  shells straight to the backend (or routes Mini-only ones like `search` over ssh).
  `bin/apple-do-completion.sh` gives bash+zsh **Tab-cycling** of the capability names.
- **Deploy busts the RAG cache.** `git reset --hard` (the Mini deploy step) bumps file mtimes,
  so `vault-rag`'s mtime-keyed cache cold-re-embeds the corpus on the next query (~64 s,
  one-time per deploy). Fix later by keying the cache on content hash, not mtime.

## How to roll the rest out

1. **Port the 15 proven tools into the GUI** — the biggest single win; the GUI becomes as
   capable as the CLI, with streaming + drag-PDF + MathML on top.
2. **Personal/fleet second wave** — `calendar`, `mailSearch`, `speak`, `submitOCR`, `weather`.
3. **Write/destructive tools** (`runShell`, add-event, submit-jobs, `notifyPhone`) **only
   behind explicit confirmation + a tight allow-list.** A 3B model *will* occasionally call
   the wrong tool — never let "wrong" mean "destructive."

## The honest caveats

- **3B reliability**: it'll sometimes not call a tool it should, or pass odd args. Clear names
  + minimal args + good descriptions matter more than cleverness.
- **Latency over the bridge**: each tool call is model-side on the Mini; the Syncthing
  round-trip already costs ~4–11 s, and a tool call adds the tool's own time. Fine for
  research, not rapid-fire chat. (The GUI, in-process, has no bridge hop.)
- **Aggressive guardrails**: Apple's on-device safety layer refuses readily (even benign
  personal-info recall). Rephrasing usually clears it; it's an FM property, not a bug.

## See also
- [on-device-ml.md](on-device-ml.md) — the framework family + the MiniLM retrieval engine
- [fm-tools.md](fm-tools.md) — the tool-calling design + the apple-skill-as-Automator framing
- [foundationmodelschat-vs-foundationchat.md](foundationmodelschat-vs-foundationchat.md) — the GUI app's lineage
- `bin/fm.swift` (16 tools) · `FoundationModelsChat/main.swift` (GUI) · `bin/apple-do` (no-LLM twin)
