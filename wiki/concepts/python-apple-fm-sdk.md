# python-apple-fm-sdk — what it brings to our FoundationModels stack

**Repo:** `github.com/apple/python-apple-fm-sdk` (Apple, Apache-2.0, alpha v0.2.0)
**Local:** `~/work/python-apple-fm-sdk` (laptop clone) · `/Users/esaruoho/work/python-apple-fm-sdk` on **cloudcity** (built + installed in `.venv`, `256 passed / 15 skipped`, 2026-06-10).
**What it is:** native Python bindings to the on-device FoundationModels model, via a Swift→C shim (`foundation-models-c/`, a `.dylib`) with `ctypesgen`-generated ctypes. Requires macOS 26.0+ and **full Xcode 26** to build. No skills folder (unlike `foundation-models-utilities`).

## The one-line thesis

Today **every FM call in our stack crosses a process boundary.** Convey (Python), converse, roundtable, transclude, DreamGraph — all reach the model only by `subprocess`-spawning a Swift CLI (`fm-submit` / `fm-converse` / `fm.swift`) *per call*. `apple-fm-sdk` collapses that boundary: on the Mini (where the model lives) Python holds the model **in-process** as a live `LanguageModelSession` object instead of re-exec'ing `fm.swift` every turn.

## Current architecture (the boundary it removes)

- **Convey → FM** is 100% subprocess. `mechanism.py:_run_ai()` → `subprocess.run([fm-converse, "--timeout", ..., prompt])`. Roundtable → `subprocess.Popen([fm-submit, "--id", job, "--system", ..., prompt])`, **N personas × M turns = N×M spawns**. Transclude `judge_groups()` → `votes×` spawns.
- **Stateless server, stateful client.** The Mini worker never remembers across jobs; state is re-replayed. `fm-converse build_replay()` and roundtable's in-memory `transcript` string re-serialize the **entire** history every turn, under hard char caps (`REPLAY_BUDGET=6000`, `MAX_INPUT_CHARS=9000`).
- **No streaming.** `subprocess.run(capture_output=True)` blocks until the full reply lands (5–12 s on the Syncthing bridge); the wall/karaoke shows nothing until done.
- **Overflow handled by string-grep.** `if "exceededContextWindowSize" in stderr` → shrink budget, restart.
- **Structured output by prose-parsing.** DreamGraph asks FM 3× and majority-votes parsed text (the model "flip-flops").

## What apple-fm-sdk fixes (point by point)

1. **Persistent sessions kill transcript replay.** One `LanguageModelSession` object owns its transcript; follow-ups don't re-send history, KV cache stays warm. Roundtable's N personas become **N persistent session objects**, not N×M spawns.
2. **Streaming → the wall/karaoke goes live.** The SDK streams tokens; Converse principles 0024 (live wall) and 0039 (karaoke display) get word-by-word rendering instead of a blocking spinner.
3. **Typed structured output natively in Python.** `@fm.generable` + `fm.guide(...)` returns a validated typed struct by constrained decoding — verified on the Mini: `Cat(name='Whiskers', age=3)`. DreamGraph's `judge_groups()` verdict becomes a typed struct instead of parsed prose.
4. **Typed exceptions, not stderr greps.** `ExceededContextWindowSizeError`, `RateLimitedError`, `GuardrailViolationError`, `RefusalError` as real `except` targets.
5. **Native transcript load/save.** Session-from-saved-transcript + transcript-JSON dump → principle 0033 ("every ask/answer saved, dated, pruneable") gets first-class serialization instead of the ad-hoc `~/.cache/fm-converse/<session>.json` buffer.
6. **No per-call process spawn.** Removes Swift startup + session init + model load/unload on every turn.
7. **Tools in Python.** The SDK has a `Tool` type; tool *bodies* (the 16 grounding tools) get defined once in Python instead of copy-maintained across `fm.swift` + `FoundationModelsChat`.

## The boundary that does NOT move

- **The laptop still can't run FM.** MacBook is macOS 15 (Sequoia); FoundationModels needs 26+. The Syncthing bridge (laptop → Mini `fm-worker`) **stays** for laptop-originated work. The SDK helps on the **Mini side**.
- **Xcode-26 build dependency** = Mini-only. Fits the existing "FM lives on the Mini" topology.
- **The 16 grounding tools are still ours to port.** The SDK gives the session + `Tool` protocol, not the tool implementations (calculator, `semantic_search`→vault-rag, webReader, ocr, …). Migration = keep the tool bodies, swap the harness Swift-CLI → Python-SDK.
- **FoundationModelsChat (native GUI) stays Swift** — already in-process; the SDK is for the Python orchestration layer, not the app.

## Highest-leverage move

Turn the Mini's `fm-worker` into an `apple-fm-sdk` Python **service**:
- one persistent `LanguageModelSession` per conversation key (converse session; each roundtable persona),
- streaming replies back over the bridge (or direct when convey runs on the Mini — which `roundtable-as-fleet-entity.md` already wants),
- `@generable` verdicts for DreamGraph,
- typed-exception overflow/guardrail handling,
- native transcript → KB.

This converts the stateless-spawn FM layer into a **stateful, streaming, typed, in-process** one, on the machine that already hosts the model — without touching the laptop bridge or the native GUI.
