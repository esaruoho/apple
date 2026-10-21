# The Apple Harness

> A zero-token-first local ingestion engine, the way Apple would make it:
> native frameworks do the work, the LLM is a surgical pen, and there are no
> third-party dependencies — Python stdlib + Apple-shipped frameworks only.
> No Homebrew, no pip, no cloud, no API key.

This is the **whitelabeled scaffold** (Layer 1). It ships with `~/work/apple`
and runs on a single Mac out of the box. A private instance (Layer 2 — e.g.
`harken`) overrides the bindings to wire it to a fleet, without editing a line
of engine code. See [`../wiki/concepts/apple-harness.md`](../wiki/concepts/apple-harness.md)
for the full doctrine.

## What it does

Point it at a folder. For every asset it:

1. **Scans** → one ledger row per file, `status: needs_analysis` (zero tokens).
2. **Extracts** text with a native organ — Vision OCR for images/PDF, Whisper
   for audio/video, direct read for text (zero tokens).
3. **Structures** — Apple `NaturalLanguage` NER for entities, Apple
   `NLEmbedding` for a 512-dim vector, writes an Obsidian Asset Note (zero tokens).
4. **Decides** — and only here spends tokens: hands the LLM the *entities + a
   tiny snippet* (never the raw bytes), N times, takes the **majority vote**.
5. **Resumes** — crash-only. The ledger row's `status` is the recovery point.

## Install / run

```sh
# from anywhere; the tool finds its own lib
apple-harness capabilities               # SHOW where each capability resolves now
apple-harness init                       # writes ./harness.plist to edit
apple-harness ingest --pool ~/SomeFolder --recursive
apple-harness status --pool ~/SomeFolder
apple-harness resume --pool ~/SomeFolder # re-pick interrupted/errored rows
apple-harness oracle --pool ~/SomeFolder # project analyzed assets into per-entity spaces
```

With no `--config`, the engine runs on its built-in **local Apple-native**
defaults. On a bare machine those local providers that need something not
present (whisp's model, macOS 26 for `fm`) resolve to **UNAVAILABLE** — the
engine refuses to auto-download. Bind a fleet belt (see harken) to route that
heavy work elsewhere.

## Capabilities, not commands — the no-download guarantee

The engine does not hardcode "run whisp". It resolves a **capability**
(`ocr` / `transcribe` / `ner` / `embed` / `reason`) to a **provider**:

- **local** — used only if its `local_preflight` (a cheap, read-only check)
  proves it is *already installed*. whisp's preflight checks the model is
  already in cache; `fm`'s checks `macOS ≥ 26`. If proving availability would
  require a download, the preflight fails and local is skipped.
- **fleet** — a belt on another machine (e.g. a Mini's whisp / fm workers),
  used only if its `fleet_heartbeat` says the belt is alive.
- neither available → **error**, never a silent install.

`apple-harness capabilities` prints the live resolution table. This is the
mechanism that stops "just run it locally" from pulling a multi-GB model onto a
workstation that was never meant to host it.

## Configuration (`config.example.plist`)

A property list — the Apple-native, stdlib-parseable format. Keys:

| key | meaning | local default |
|---|---|---|
| `vault` | where Asset Notes are written | `~/AppleHarnessVault` |
| `embeds` | the semantic-memory vector store (JSONL) | `~/.apple-harness-embeds.jsonl` |
| `bin_dir` | prefix for organ commands (`""` = use `PATH`) | `""` |
| `scan_ignore` | filename suffixes that are harness artifacts, never re-scanned | `.transcript.txt`, `.speakers.txt` |
| `modalities` | extension → modality map | image/pdf/audio/video/text |
| `modality_capability` | modality → capability | image/pdf→ocr, audio/video→transcribe, text→read |
| `capabilities.<cap>` | provider spec: `local_cmd` + `local_preflight`, `fleet_cmd` + `fleet_heartbeat` + `fleet_collect`, `prefer`, `on_unavailable` | see below |
| `reasoning.votes` / `.timeout` / `.prompt` / `.enabled` | how to majority-vote (provider comes from capability `reason`) | 3 / 120 / … / true |

Each `capabilities.<cap>` entry: `local_cmd` (template, `{path}`),
`local_preflight` (shell check, exit 0 = installed-without-download),
`fleet_cmd` + `fleet_heartbeat` + `fleet_collect` (`{stem}` → a file the belt
writes), `prefer` (`local`|`fleet`), `on_unavailable` (`error`).

## The ledger

`.harness-ledger.jsonl` at the root of the target pool. Append-only, fsync'd,
latest-row-per-path wins on load, tolerates a torn final line from a crash.
It is the episodic memory; delete it to re-ingest from scratch.

## Layout

```
harness/
├── config.example.plist      # the whitelabeled local-Apple config
├── README.md
└── lib/harness/
    ├── config.py             # plist loading + defaults + bindings
    ├── ledger.py             # durable status ledger (the source of truth)
    ├── organs.py             # zero-token extraction + NER + embed dispatch
    ├── reasoning.py          # the reasoning binding + majority vote-to-judge
    └── loop.py               # Think→Act→Observe→Stop, per asset
bin/apple-harness             # the CLI chassis
bin/fmremote                  # remote Apple FM binding (wraps fm-submit → Mini)
```

## What this scaffold deliberately does NOT contain

- No CloudcityMacMini, no Syncthing paths, no `convey`, no `~/work/cc/vault`,
  no 5TB assumption. Those are **harken** (the private instance), not the engine.
- No daemon / no `nohup`. A long supervised run belongs under Cloudcity-Boot.app
  + `systems.yaml` — again, harken's concern.
