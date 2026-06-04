# Session — Folding "Hey Sal" into AppleBar (voice as a second door to one router)

Faithful, not flattering. Audit trail for `hey-sal-fold.feature`.

## How to get back

- Transcript: `file:///Users/esaruoho/.claude/projects/-Users-esaruoho-work-apple/e08dfd73-b702-44ad-9f8b-e58f14614d0f.jsonl`
- Session ID: `e08dfd73-b702-44ad-9f8b-e58f14614d0f`
- Resume: `claude --resume e08dfd73-b702-44ad-9f8b-e58f14614d0f`
- When: Thursday, 4 June 2026, ~14:00–15:20 EEST

## The thread that led here

This session started with me-location (deduce Directions origin from device presence).
Esa then asked the DRY question: *"is the DRY principle unwavering. this was triggered
from Hey Sal, what about Apple Bar? does Directions understand the same thing there, too?"*

I traced it and was honest about a real gap: AppleBar's Directions DOES inherit the
me-location fix (AppleBar → apple-intent → apple-do directions → maps-directions, one
shared file). But the **spoken** "Hey Sal" went through `bin/sal-siri-match.py` → DC-XXX
AppleScript handlers — a *separate routing brain* that never touches maps-directions.
So DRY held inside AppleBar but was broken across the voice surface.

Esa's call: *"Hey Sal is a Vocal Shortcut in Shortcuts, that initializes a situation.
but if we can somehow fold Hey Sal, as an idea, to the Apple Bar, then we have an even
better situation."*

## The realization (why this was small)

AppleBar **already** had the hard parts:
- `OnDeviceDictation` (shared/Dictation.swift) — the mic + on-device recognizer.
- A 🎙 mic button; ↩ already "stops the mic, then runs what was heard" via apple-intent.

So speaking *into* AppleBar already routed through the one pipeline. The ONLY missing
piece was a **hands-free wake** the Vocal Shortcut could fire — something that opens
AppleBar, starts the mic, and auto-runs when you stop talking. That's the whole fold.

## What I built

1. **URL scheme** `applebar://` (build.sh → CFBundleURLTypes) + a `kAEGetURL` handler.
   `applebar://listen` → wake + mic; `applebar://open` → wake (keyboard) for symmetry.
2. **listenMode + silence auto-submit**: each partial transcription bumps a 1.6s timer;
   when you go quiet, it calls the existing `runQuery` → `apple-intent` → `apple-do`.
   ↩ still submits immediately (override). Reuses the exact chain typing uses.
3. **No-speech give-up (9s)** + ESC-aborts-listen — so a fired-but-unspoken listen never
   leaves the mic open (honors the global no-energy-hog / runaway-mic rule).

Crucially I changed **nothing** in Dictation.swift, apple-intent, apple-do, maps-directions
or me-location. The fold's value is that voice now lands on those unchanged — DRY intact.

## Verification (what I actually checked, and what I did not)

- **URL routing — verified** via unified log: `handleGetURL 'applebar://open' host='open'`
  and `'applebar://listen' host='listen'`.
- **listen engages the recognizer — verified** via log: firing listen brought up `tccd`
  (permission) + `TextInputUI`/`CursorUIViewService` XPC = Speech/mic subsystem starting.
  I killed the app right after to release the mic — I did NOT record Esa.
- **Routing parity — verified earlier**: `apple-intent --dry-run "directions"` →
  `match: directions (1.00)` → `would run: apple-do directions`. And `grep "maps://"`
  returns only `bin/maps-directions` (single source of truth).
- **NOT verified end-to-end**: the full spoken round-trip (speak "directions home" →
  silence → Maps opens from Workspace). That needs a real utterance and is Esa's to drive.
  Graded `@built`, not `@verified`. I will not claim a voice round-trip I didn't hear.

### Build-vs-editor note
swiftc builds clean (AppleBar.swift + shared/Dictation.swift compiled together). The
editor's SourceKit flags "Cannot find OnDeviceDictation" etc. — false positives from
analyzing AppleBar.swift alone; the build is the source of truth (same pattern the
@main comment in the file already documents).

## The one thing left for Esa (not auto-done, on purpose)

Re-point the "Hey Sal" Vocal Shortcut body to a single action: **Open URLs →
`applebar://listen`**. I did NOT edit it — it's a Shortcuts.app object, and the global
rule is to not UI-hijack / not simulate the Shortcuts editor. Steps handed over in chat.
`sal-siri-match.py` stays on disk; it's just no longer the voice/directions brain.

## Possible next turns
- Make the panel survive `hidesOnDeactivate` during an active listen (minor UX).
- Tune `silenceSeconds` (1.6s) if it clips mid-sentence pauses.
- A spoken wake-word ("Hey Sal") without the Shortcut would need always-on listening —
  out of scope; the Vocal Shortcut IS the wake-word, which is the Apple-native way.
