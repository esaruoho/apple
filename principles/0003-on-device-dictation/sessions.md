# Stage 2 — Sessions (imported from features/dictation-button.session.md)

# Session — Dictation button (the spawning conversation)

Faithful, not flattering. This is the audit trail for the grades in
`dictation-button.feature`.

## How to get back

- **Transcript (origin):** `file:///Users/esaruoho/.claude/projects/-Users-esaruoho-work-apple/fde596bb-669f-493a-8a43-04a4e33cd964.jsonl`
- **Bundled beside this card (local-only, gitignored — repo is public):**
  `dictation-button.transcript.jsonl` (lossless) + `dictation-button.transcript.md` (readable, `fm-converse`-ingestible)
- **Session ID:** `fde596bb-669f-493a-8a43-04a4e33cd964`
- **Resume:** `claude --resume fde596bb-669f-493a-8a43-04a4e33cd964`
- **Window:** 2026-06-01T20:33:54Z → 2026-06-03T08:42:33Z UTC
  (2026-06-01 23:33 → 2026-06-03 11:42 EEST). Card authored 2026-06-03.
- **Converse it:** `fm-converse features/dictation-button.transcript.md`

## How this unit was spawned

1. Earlier in the session I added a 🎙 mic button to AppleBar with **inline**
   `SFSpeechRecognizer` code (commit `369d9b0`). It compiled and shipped.
2. Esa, on clicking it: *"we already have this exact same thing in apple-toolbox
   and in converse and.. why are we having this DRY principle issue with simply
   conveying a simple, report-cardable change, of adding a button… fully tested +
   gherkin written, so that the button's knowledge for recreating it is stored in
   the reportcard, and so that a LLM Wiki karpathy style can fully get this from now
   on. we are turning gherkin tests 'given when then' - into actual programming
   language."*
3. **The correction I own:** I re-rolled dictation a third time instead of reusing
   what existed. That is the DRY violation this card exists to close.

## What the investigation found (so the card matches reality)

- **AppleToolbox** already has the canonical, most-evolved version:
  `SpeechDictationController` (topbar/AppleToolbox.swift ~8170–8536) — cursor-aware
  tentative-range rendering, audio-file capture, pause/resume when the user grabs
  the keyboard. It targets a custom `ChatInputTextView`.
- **Converse** uses **Whisper** (AVAudioEngine → whisper worker), NOT
  SFSpeechRecognizer — a genuinely different engine. So it is out of scope, not a
  consumer. (Recorded as an `@note` scenario, not a missed DRY target.)
- Therefore the honest DRY move is: extract the **target-agnostic core** both
  SFSpeechRecognizer users share (authorize → mic + on-device recogniser → emit
  transcription strings → stop) as `shared/Dictation.swift` `OnDeviceDictation`,
  have AppleBar consume it now, and mark AppleToolbox's controller to wrap it as a
  follow-up (`@todo`) — rewriting that battle-tested 8.5k-line file mid-turn would
  be reckless.

## "Gherkin → actual programming language"

The mic-free behaviours of the engine became an executable test,
`shared/test-dictation.sh` (compiles `Dictation.swift` + `dictation-tests.swift`,
runs headlessly, no mic, no TCC): fresh engine idle, on-device preferred, and
`stop()`-while-idle is a safe no-op (the crash class that matters). These scenarios
are graded `@verified`. The mic-path scenarios (authorize → listen → stream) can't
run headlessly and are graded `@built @untested` — a human checklist, honestly
labelled rather than graded up.

## Decisions / open items

- `@todo`: refactor AppleToolbox's `SpeechDictationController` to sit on
  `OnDeviceDictation` (its core), keeping the tentative-range + audio-capture as a
  layer on `onText`.
- Possible follow-up Esa flagged earlier: auto-run the moment dictation stops
  (instead of waiting for ↩). Not done; left as a one-line change if wanted.
