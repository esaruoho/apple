---
description: The Apple Harness doctrine — the zero-token local ingestion loop that composes the apple/convey/vault organs into one Think→Act→Observe→Stop nervous system with a durable status ledger. Maps the generic "AI harness" architecture to tools that already exist; names the one real gap.
---

# The Apple Harness

> *AI Agent = AI Model + Harness.* A raw LLM is a brain in a jar. The harness is the operating system around it — tools, memory, execution loop, guardrails — that turns reasoning into action. On Apple Silicon the harness's whole job is to keep expensive tokens **out** of the extraction work: Apple Vision, `NLEmbedding`, Whisper/SFSpeech and `NLTagger` run on the Neural Engine for **zero LLM tokens**, and the frontier/on-device LLM is used only as a surgical pen on tiny curated snippets.

## The honest finding

The generic harness architecture (five layers: execution loop, tool integration, context/memory, guardrails, observability) describes a thing that **already exists in pieces across this ecosystem**. The organs are built. What is missing is the *nervous system* — one driver that runs the loop over them with a durable status ledger so a large ingest can crash and resume.

That driver is the Apple Harness. Everything else below already ships.

## Organ map — generic harness box → tool that already exists

| Harness layer (the doc's claim) | Zero-token Apple path | Tool(s) here | Status |
|---|---|---|---|
| Visual indexing (OCR, scene tags) | `VNRecognizeTextRequest` on the ANE | `bin/vision-ocr`, `ocr-pdf-rebuild`, `ocr-triage`, CCOCR via `convey ocr` | **built** |
| Audio/video → text | Whisper CoreML / `SFSpeechRecognizer` | `whisp` (local), whisp-worker (YouTube queue) | **built** |
| Semantic embeddings | `NLEmbedding.sentenceEmbedding` → 512-dim | `bin/apple-embed`, `apple-semantic-match`, `apple-cluster-docs`, `embed` | **built** |
| Semantic memory (vector store) | cosine over cached matrix | `~/.vault-embeds/` (`_matrix_manifest.json` + `_matrix_rows.npz`) | **built** |
| Retrieval (RAG — inject only the hit) | embed-to-narrow | `vault-grep`, `vault-rag`, `vault-ask`, `vault-consilience`, `vault-distill` | **built** |
| Reasoning engine (local LLM) | Apple FoundationModels (macOS 26) / MLX | `bin/fm` → refuses off-Tahoe; `fm-submit` → Mini via Syncthing `fm-inbox`/`fm-outbox`; `fm-mlx` | **built** |
| LLM-as-judge (stable only in aggregate) | majority-vote N samples | `convey graph judge` (FoundationModels, 3 votes, flags flip-flops) | **built** |
| Relational memory (knowledge graph) | entity/concept/person nodes + edges | **convey DreamGraph** (`convey graph dedup` / `judge`) | **built** |
| Human-readable shared memory | Obsidian vault, YAML frontmatter, `[[links]]` | `~/work/cc/vault/` (179 conversation folders) + `vault` skill | **built** |
| Episodic memory / audit log | resume-after-crash step log | report-card triad; `systems.yaml` panes on the Mini | **partial** |
| **Execution loop + status ledger** | **Think→Act→Observe→Stop over a `needs_analysis→analyzed` ledger** | **— none —** | **THE GAP** |

## The one gap: the loop + the ledger

Every row above is an organ. The harness is the single process that:

1. **Scans** a target pool (zero tokens) and writes one ledger row per asset with `status: needs_analysis` — hash, path, size, mtime, mime, detected modality.
2. **Extracts** per modality by dispatching to the organ (`vision-ocr` for images/PDF, `whisp` for audio/video, raw text otherwise) — still zero tokens. Lands the extract as a vault Asset Note.
3. **Structures** — `NLTagger` NER for people/place/org, `apple-embed` for the vector, append to `~/.vault-embeds/` and spawn/attach DreamGraph entity nodes. Zero tokens.
4. **Decides** — and only here spend tokens: hand the LLM the *graph + filenames + entity lists*, not the bytes; it emits an ACTION (`cross_reference_nodes(a,b)`); the harness opens the ledger, extracts only the overlapping paragraphs, feeds back those snippets; `fm`/judge votes; flips the row `needs_analysis → analyzed`.
5. **Resumes** — on crash, re-read the ledger, skip `analyzed`, continue. The ledger *is* the episodic memory.

**Division of labour (the whole point):** `NLEmbedding` = the scalpel that *selects* (cheap, deterministic, instant); FoundationModels = the pen that *decides* (language, stable only in aggregate → always majority-vote). **Embed-to-narrow, vote-to-judge.**

### Ledger schema (proposed — not yet built)

One JSONL row per asset, the single source of truth the loop reads to resume:

```jsonl
{"id":"asset_20261021_001","hash":"…","path":"/Volumes/5TB/…","size":...,"mtime":"…",
 "modality":"image|audio|video|pdf|text","status":"needs_analysis|extracting|extracted|analyzed|error",
 "extract":"vault/System/Assets/asset_20261021_001.md","entities":["Tesla","reactive power"],
 "vector_row":1234,"errors":[],"touched":"2026-10-21T…"}
```

Mirrors convey's existing `convey-ocr-manifest.jsonl` / `convey-to-be-analyzed.jsonl` shape on purpose — the harness ledger should be a superset, not a competitor. **Only convey writes the OCR manifest** (project rule); the harness must route OCR *through* `convey ocr`, never raw `cp` into `ocr-inbox/`, or results orphan.

### Loop contract (proposed)

- **Idempotent** — re-running on a pool with existing rows is a no-op for `analyzed` assets.
- **Crash-only** — no graceful-shutdown assumption; the ledger row's `status` is the recovery point.
- **No-nohup** — a long-running Mini ingest runs under Cloudcity-Boot.app + `systems.yaml`, never `nohup`/daemon (project ground rule).
- **Durable outputs home in mediabank/vault, never in a Syncthing git tree that `git clean` can wipe** (OCR-outputs-durable rule).
- **Token budget is a guardrail, not a hope** — the loop asserts a per-asset token ceiling; breaching it is an `error` row, not a silent overspend.

## Where it lives — the two-layer whitelabel split

This follows the **companion-mac pattern**: public mechanism ships whitelabeled, private instance is separate and gitignored. Two layers, never conflated:

### Layer 1 — the whitelabeled scaffold (ships with `~/work/apple`)

The generic engine. **No** hardcoded CloudcityMacMini, **no** Esa paths, **no** Syncthing-inbox specifics, **no** 5TB-pool assumption. A stranger clones apple and gets a working harness skeleton. It defines the *interface*, not the bindings:

- The **loop** (scan → extract → structure → decide → resume) as a driver that reads only its config.
- The **ledger schema** (the JSONL contract above) and a reference JSONL store.
- An **organ-dispatch table** as an interface: each modality (`image|audio|video|pdf|text`) maps to an organ command that must accept `(asset_path) → extract_text` and `(asset_path) → entities,vector`. The scaffold ships *reference organs* that use only Apple-shipped tools (`vision-ocr`/`VNRecognizeTextRequest`, `apple-embed`/`NLEmbedding`, `NLTagger`) and a **local** `fm` call — so it runs on any single Mac with no fleet.
- A **`config.example.yaml`**: pool glob, ledger path, vault path, per-modality organ binding, reasoning-backend binding (default `local`), token ceiling.

Likely form: `~/work/apple/harness/` (scaffold + `config.example.yaml`) with a thin `bin/apple-harness` entrypoint (`init` · `ingest <pool>` · `status` · `resume`). Public by the same `.gitignore` split the repo already uses.

### Layer 2 — the private instance: **harken** (`~/work/harken`)

Naming is deliberate: **harness** = the generic whitelabeled scaffold (Layer 1, ships with apple); **harken** = Esa's private bound instance (Layer 2, never ships). Keeping the two words distinct removes the "which harness?" ambiguity.

Just **config + overrides** that bind the scaffold to the real world: reasoning → `fmremote` → Mini (not local), and — the load-bearing rule — **every HEAVY extraction organ routes to CloudcityMacMini, never the laptop.** Audio/video → `convey transcript` (Mini whisp belt, large-v3); scanned/image-only PDF → `convey ocr` (manifest, no orphans). Only LIGHT Apple-ANE organs run locally: `vision-ocr` on crisp images, `apple-ner`, `apple-embed`. Then vault, graph = convey DreamGraph, pool = the 5TB drive, execution = Cloudcity-Boot.app + `systems.yaml` (never nohup). Supplies bindings only; re-rolls no engine code. **convey is a *consumer* the private instance points at, not the harness's home.** See [[feedback_harness_heavy_extraction_routes_to_mini]].

> Built 2026-10-21 at `~/work/harken/`: `harken.plist` + `harken` wrapper + `bin/transcribe-remote` (the Mini-transcription adapter). The local-whisp misstep that prompted this rule is recorded in that memory.

This keeps DRY: the apple `bin/` organs are the leaf tools both layers dispatch to; the private layer adds no second extractor, only a binding table.

## Reconciliation with the `convey-harness` blueprint

A separate blueprint (`apple_harness_scaffolding_plan.md`) was drafted against the *pre-split* design (home = convey). Its structure is adopted; its couplings are rejected:

- **Adopt:** the module tree (`lib/harness/{ledger,loop,organs}.py` + a thin `bin/` entrypoint), the ledger schema, the atomic append-only ledger with path-dedup on load, the three verification stages.
- **Relocate:** engine lives in `~/work/apple/harness/lib/` with `bin/apple-harness` (not `~/work/convey` / `convey harness`). Every `convey` / `cc/vault` / `/Volumes/5TB` / `convey graph judge` string becomes injected config supplied by **harken**, never engine code.
- **Correct (verified 2026-10-21):**
  - OCR organ is **async + PDF-oriented**, not a blocking stdout call. Real contract: `convey ocr <path> --run` submits to the Mini and homes results over Syncthing; the loop needs a `submitted → awaiting → extracted` sub-state, not `return res.stdout`.
  - Audio organ: `~/work/whisp/whisp <file>` (no `bin/whisp`, no `--local` flag).
  - NER organ already exists as **`bin/apple-ner`** — the blueprint's `bin/apple-tagger-ner` is an invented name; reuse `apple-ner` (DRY).
  - `os.path.splitext(p)[1].lower()` (blueprint's `.lower()` on the tuple crashes); keep `pdf` and `video` as distinct modalities.
  - Python here is **3.14** → `datetime.now(timezone.utc)`, never `datetime.utcnow()`.

## The reasoning binding: `fm` (abstract) → `fmremote` (our default)

The scaffold ships the abstract **`fm`** reasoning interface — prompt in (argv or stdin) → model text out — with a `local` reference binding for a stranger on macOS 26. **On this fleet local FM is impossible (15.6.1), so harken's default binding is `fmremote` → CloudcityMacMini.**

`fmremote` (to build) is the keystone remote binding. Contract:

- **Same CLI shape as `fm`** so the scaffold is backend-agnostic: `fmremote "<prompt>"` or `echo prompt | fmremote` → answer on stdout; non-zero exit on timeout/unreachable.
- **Wraps the existing bridge** — it is a thin adapter over `fm-submit` (Syncthing `fm-inbox` → Mini FoundationModels → `fm-outbox`), **not** a new transport. Reuse-before-rerolling.
- **Vote-to-judge** is the scaffold's generic majority-vote wrapper calling the bound reasoning cmd N times (default 3), reporting `k/N` and flagging flip-flops — the same discipline `convey graph judge` already encodes, but without requiring convey. harken MAY additionally bind judge → `convey graph judge` when the graph is the target.
- **No-nohup:** a long harken ingest on the Mini runs under Cloudcity-Boot.app + `systems.yaml`; `fmremote` itself bounds each call with `asyncio.wait_for`, never a backgrounded killer loop.

Config surface is an Apple-native **property list** (`harness/config.example.plist`), parsed by stdlib `plistlib` — zero third-party deps, "like Apple would make it." The reasoning binding:

```
reasoning.cmd     = fm       (local macOS 26) ; harken overrides → fmremote
reasoning.votes   = 3        (majority-vote — the model flip-flops)
reasoning.enabled = true
```

## Capability-aware provider resolution (the no-download rule)

Devices differ: some have local FoundationModels (macOS 26), some have the whisp
model cached, most have neither. The harness must route to wherever a capability
*actually lives* — and must **never** download a heavy model to "run it locally".

So an organ is not a command; it is a **capability** (`ocr`, `transcribe`,
`ner`, `embed`, `reason`) that resolves to a **provider** at run time
(`harness/lib/harness/capabilities.py`):

- **local** — used only if its `local_preflight` (a cheap, read-only shell
  check) proves it is *already installed*. whisp → "is the large-v3 model in
  cache?"; `fm` → "is this macOS ≥ 26?". **If proving availability would require
  a download, the preflight fails and local is skipped.** This is the exact gate
  that stops the 1.2 GB pull.
- **fleet** — a belt on another machine, used only if its `fleet_heartbeat` says
  the belt is alive (fm-worker / whisp-worker heartbeats — the Fleet is the
  source of truth for where capabilities live). A fleet result may arrive in a
  file beside the source (`fleet_collect`, e.g. `convey transcript` →
  `<stem>.transcript.txt`) rather than on stdout.
- neither available → **error** (recoverable on `resume`), never a silent install.

`apple-harness capabilities` / `harken capabilities` prints the live table.
The whitelabel defaults are honest for a stranger: on a non-Tahoe Mac with no
model, `transcribe` and `reason` read **UNAVAILABLE** rather than downloading.
harken binds the fleet providers (transcribe → Mini whisp, reason → `fmremote`)
so the same engine routes heavy work to the Mini automatically. Verified
2026-10-21: a full image+pdf+audio pool ran with ocr/ner/embed local,
transcribe+reason on the Mini, and **zero model downloads**; a transient
fm-heartbeat blip during heavy Mini load errored one asset, and `resume`
completed it. See [[feedback_harness_heavy_extraction_routes_to_mini]].

## Build status (2026-10-21)

- **Layer 1 (scaffold) is built and runtime-verified.** `bin/apple-harness` + `harness/lib/harness/` + `bin/fmremote` + `harness/config.example.plist`. The zero-token path (extract → NER → NLEmbedding → Asset Note → ledger → resume), the `fmremote` round-trip to the Mini, and 3-vote majority reasoning were all run live. Report card: [`../../features/apple-harness.feature`](../../features/apple-harness.feature).
- **Honestly ungraded:** image/PDF/audio *through the loop* end-to-end, the `init` verb, and torn-ledger crash recovery are `@runtime-untested` — wired and code-verified, not yet exercised.
- **Layer 2 (harken) v0 is built** at `~/work/harken/` (harken.plist + wrapper + `bin/transcribe-remote`), binding reasoning → `fmremote` and audio/video → the Mini whisp belt. Still a design: the event-driven listener trigger layer, async-OCR substate, and Cloudcity-Boot supervision. No completion-framing.

## Comparison with the prior `~/work/harness` (the shell meta-harness)

A separate harness already exists at `~/work/harness` (built 2026-10-20). It is a **sibling, not a rival** — different philosophy, complementary strengths. (Note it already uses the name *harken* for its listener daemon, `listeners/harken.py` — a naming overlap to resolve, since our private instance claims `~/work/harken`.)

| Axis | Prior `~/work/harness` (shell meta-harness) | Apple Harness (`~/work/apple/harness`) |
|---|---|---|
| **Language** | bash atoms + a few python listeners | Python stdlib engine + native Apple leaf organs |
| **Trigger** | event-driven: listeners watch drop folders + Syncthing queues (push) | on-demand scan of a pool (pull) |
| **Memory** | append-only `RESULT-LOG.md` (human prose) + `.card.md` sidecars | machine-readable JSONL ledger keyed by asset, atomic+fsync, resumable; Obsidian Asset Notes; embeds JSONL |
| **Organs** | shell wrappers that shell out to `convey`, `mlx_brain`, `scp_deploy` | config-bound, defaulting to local Apple-native tools |
| **Reasoning** | `mlx_brain` atom (single pass) | bound `fm`/`fmremote`, **majority-voted** (k/N, flip-flop flag) |
| **Dependencies** | convey, the fleet, esaruoho.org deploy — personal, cross-repo | none — stdlib + Apple frameworks only |
| **Whitelabeled** | no (hardcoded to Esa's infra) | **yes** (that is the point) |
| **Crash/resume** | prose audit, not a resumable per-asset state machine | first-class: ledger status is the recovery point |
| **Scope** | broad orchestration + deploy across repos | focused, shippable ingestion engine |

**The synthesis:** they compose. The prior harness is good at *"watch my drop folders, run my existing pipelines, deploy to my site."* The Apple Harness is good at *"point at a pool, get a resumable, token-frugal, Obsidian-landed knowledge base anyone can run."* When **harken** (Layer 2) is built, it should **absorb the prior harness's listener pattern as its event-driven trigger** — listeners sense a drop, then hand the file to the Apple Harness engine for ledgered, majority-voted ingestion. Push (prior) feeds pull (new).

## Reconciliation with the plain-text Oracle handover

A third external handover (`ai_harness_handover.md`) describes the same paradigm
and mostly **validates** this build: move control out of the LLM into rigid
local scripts; aggressive de-tokenization (premium APIs as specialists); a
Mac-Mini local inference worker; plain-text Markdown/YAML memory; a
`needs_analysis` ledger; three decoupled layers (Harness / Memory / Prompt). We
already do all of this (engine / vault+ledger / `reasoning.prompt`).

Where it diverges it conflicts with Esa's OWN rules or repeats the mistake we
just fixed — reject those:

- **Local `docling`/`marker` for scanned PDFs + formulas** (its Phase 2) is the
  *exact* local-whisp trap: heavy ML parsers that download models and pin the
  workstation. Route heavy/scanned OCR to the Mini (`convey ocr`); the capability
  model already forbids the local download. Formula → LaTeX has no Mini belt yet
  → a genuine future belt, not a local install. See [[feedback_harness_heavy_extraction_routes_to_mini]].
- **SSH transport** → use Syncthing belts (fm-submit / convey transcript /
  whisp-inbox). Syncthing-default is doctrine; SSH is brittle.
- **`pyyaml` dependency + YAML ledgers** → we use stdlib `plistlib` + JSONL to
  stay zero-dep ("no Homebrew, no pip").
- **A separate Qwen-2.5-MLX-over-SSH worker** → that is just another `reason`
  fleet provider in our capability model (pluggable), not a parallel pipeline.
  Today `reason` binds to `fmremote` (Apple FoundationModels on the Mini).

**One genuinely new idea to adopt:** per-entity **oracle spaces** —
`oracle_spaces/<entity>/namespace.yaml` + that entity's documents, a
human-readable projection grouping Asset Notes by NER entity. **Built
2026-10-21** as `apple-harness oracle` (`harness/lib/harness/oracle.py`): a
post-pass over the ledger writing `oracle_spaces/<slug>/namespace.yaml` (identity
+ focus areas from aggregated tags + connections from co-occurring entities) and
an Obsidian-navigable `index.md`. Idempotent, dependency-free (YAML hand-emitted).

## What this doctrine deliberately does NOT claim

- It does **not** claim harken exists. Layer 1 is built and runtime-verified; Layer 2 (harken, the private fleet instance) is a design. No completion-framing.
- `NLEmbedding` is a *light* model — weak on very short strings. The loop must **partition first, then embedding-cluster within the partition, leader clustering** so single-linkage can't chain everything into one blob.
- FoundationModels is **non-deterministic and rationalises both ways**; a single call is never a judge. Always vote.

## Related

- [`asobjc.md`](asobjc.md) — ASObjC is the default surface for any new Apple-native organ the loop needs.
- [`../../skill.md`](../../skill.md) — "Apple NLEmbedding & FoundationModels" section: the scalpel/pen division in the skill index.
- convey skill + `~/work/convey/AGENTS.md` — DreamGraph, the OCR manifest doctrine, the Mini fabric.
- `vault` skill — the Obsidian shared-memory layer the harness writes into.
- [`finder-tag-pipeline.md`](finder-tag-pipeline.md), [`mail-flag-pipeline.md`](mail-flag-pipeline.md) — the trigger→worker chassis the harness loop generalises to arbitrary pools.
