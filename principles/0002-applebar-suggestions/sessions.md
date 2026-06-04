# Stage 2 — Sessions (imported from features/spotlight-suggestions.session.md)

# Session — AppleBar Spotlight-style suggestions (spawning conversation)

Faithful, not flattering. Audit trail for `spotlight-suggestions.feature`.

## How to get back

- **Same session** as the other AppleBar cards:
  `file:///Users/esaruoho/.claude/projects/-Users-esaruoho-work-apple/fde596bb-669f-493a-8a43-04a4e33cd964.jsonl`
- **Bundled transcript (local-only, gitignored):** `features/dictation-button.transcript.jsonl` / `.md`
- **Session ID:** `fde596bb-669f-493a-8a43-04a4e33cd964` · **Resume:** `claude --resume fde596bb-669f-493a-8a43-04a4e33cd964`
- **Card authored:** 2026-06-03 (EEST).

## How this unit was spawned

Esa: *"what else apple can it do, that it is able to recognize. can we not make it
like Spotlight, with suggestions you can cursor up and down with."*

## Decisions

- **DRY over a 2nd catalog.** The bar needs the same intents apple-intent routes over.
  Rather than duplicate them in Swift, the catalog moved to ONE `shared/intents.json`
  both read (the reuse-before-rerolling rule). Adding an intent updates both.
- **In-process ranking, not subprocess-per-keystroke.** apple-intent is a swift script
  (~1 s compile per run) — far too slow to call on every keystroke. AppleBar embeds the
  examples once at launch with NLEmbedding and cosine-ranks the query in-process (~ms),
  so suggestions update live and smooth.
- **Pick runs exactly that action.** Arrowing to a suggestion and pressing Return runs
  `apple-intent --action <name>` (force-run, skips embedding) so the highlighted choice
  is honoured rather than re-routed. Keeps templating/learning/speak in one place.
- **"What else can it do" → +4 capabilities:** battery, wifi, clipboard, lock — easy,
  Apple-native, no/low permission, good demonstrations in the suggestion list.

## Honest status

- Routing + the pick path are `@verified` (shared/test-intent-routing.sh, 17 cases).
- The live list rendering / ↑↓ navigation is `@built` — compiles + runs (PID confirmed);
  visual behaviour verified by eye in the GUI, not headlessly (AppKit interaction).
