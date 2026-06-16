---
description: The missing SPINE for Paketti — a single Feature Catalog (source of truth) parsed from the authoritative CHANGESLOG, linked to keybindings + code, from which every view (manual, README, Gumroad, FAQ, Discord bot) is generated. Stops the MLX bot from hallucinating descriptions.
---

# The Paketti Spine (source of truth → all views)

## The problem (Esa, 2026-06-16)

> "We have a README, a CHANGESLOG, a manual, the mlx-here fooling around… nothing is combined, nothing is explained, nothing works. The manual doesn't know about the changelog, the changelog doesn't know about the manual, the README is barely coherent, the Gumroad listing is un-updated random stuff. We're dropping knowledge left & right and not utilizing it. The QUESTIONS the FAQ makes are useful; the ANSWERS are total junk, because they are unhinged from reality."

Six disconnected sources, none referencing the others: `README.md`, `CHANGESLOG.md` (~14k lines), `manual/`, the Gumroad listing, the keybinding manifests, the `.lua` code. The MLX bot grabs scraps from whichever it can reach and **confabulates the glue.**

## The proof

Asked "what does HyperEdit do," the bot read function *names* from `PakettiHyperEdit.lua` and **invented** their meaning — including a "Drift" mode that does not exist. Meanwhile the **correct, detailed description was already written by Esa in CHANGESLOG.md** (2026-06-13): the Cirklon Sculpt toolbar; modes Regular / Sculpt ABS / Sculpt REL / Random ABS / Random REL; the hold mechanics; Effect-parameter vs Stepper. The authoritative truth existed and was never read.

**Diagnosis:** today MLX *generates* descriptions (hallucinates). The fix is to make it *retrieve* the author's real description and present it.

## A FEATURE IS AN ENTITY WITH A HISTORY — not a changelog line

The first cut of this doc was wrong in the exact way the bot is wrong: it treated
**one changelog entry as "the feature."** It isn't. The changelog is a *timeline of
increments*; a feature is the *thing those increments happen to.*

Proof — HyperEdit's real history in CHANGESLOG.md:

- **Foundation (2025-09-27, first `Feature:` entry):** "Paketti HyperEdit — create
  Looping Automation Sequences, each row 1 to 256 steps long, the rest of the
  pattern filled with the Canvas content."
- **Code header agrees:** "8-Row Interchangeable Stepsequencer with individual
  device/parameter selection."
- **~11 increments over 9 months:** Groovebox integration (09-29), auto-assign
  automation params (10-07), external-editor hide (10-30), live MIDI write (06-08),
  Open/Close MIDI map + Stepper mode (06-09), All Rows (06-10), Cirklon Sculpt/Random
  (06-13), Gang (06-14), …

The bot grabbed the newest entry (Sculpt) and called it "what HyperEdit is." Sculpt
is **1 of 11 parts** bolted onto an 8-row automation step-sequencer. Wildly wrong.

## The spine = a Feature ENTITY catalog (aggregate, anchor, layer)

Build by **entity resolution**, not entry parsing:

1. **Resolve entities** — group every `### DATE - <Type>: <…>` entry by the feature
   it's about (all "HyperEdit …" entries → entity **HyperEdit**).
2. **Anchor on the foundation** — the *earliest* `Feature:` entry + the matching
   `PakettiX.lua` header comment = "what it fundamentally is."
3. **Layer the increments chronologically** — every later Feature/Improvement/Fix is
   a part/mode/refinement of the entity.

One record per ENTITY:

```
feature:       HyperEdit
foundation:    8-row interchangeable stepsequencer for looping automation
               sequences; rows 1–256 steps; each row its own device/param canvas
               (2025-09-27 + PakettiHyperEdit.lua header)
parts:         [Stepper mode (06-09), live MIDI write (06-08), All Rows (06-10),
                Cirklon Sculpt/Random (06-13), Gang (06-14), Groovebox 8120 (09-29),
                auto-assign automation params (10-07), …]   ← each with its date + prose
keybindings:   [...]    ← linked to autocomplete_shortcuts.txt
midi:          [...]
code:          PakettiHyperEdit.lua (+ functions)
manual:        manual/<section> (if any)
status:        verified | needs-verify
```

The canonical description = **foundation + all parts**, in Esa's words — never one
entry. It links the ground-truth sources that today ignore each other:
**changelog (what it does, over time) ↔ keybindings (how you trigger it) ↔ code
(where it lives) ↔ manual (long-form).**

## The role reversal (this is what kills the junk)

- **Today:** MLX GENERATES the description → hallucinates ("Drift").
- **With the spine:** MLX RETRIEVES the catalog's real description (your changelog words) and presents/rephrases it. It generates *phrasing*, never *facts*. When a feature has **no** catalog entry, it says "undocumented" — honest, not invented.

So `paketti-ask "what does HyperEdit do"` returns your actual 2026-06-13 changelog text, not a fantasy.

## Every view is generated FROM the spine

Once the catalog exists, the drifting/contradicting documents become **generated views** of it — so they can't drift again:

- **manual** index ← catalog (grouped by area)
- **README** feature list ← catalog (recent + headline features)
- **Gumroad** listing ← catalog (curated subset)
- **FAQ vault** ← catalog (question → matching feature record)
- **Discord bot** ← catalog (retrieve + present, never invent)

*The transcript is a view; the event log is the document* (convey doctrine) — here the **catalog is the document; manual/README/Gumroad/FAQ are views.**

## Build order (first vertebra is deterministic — cannot hallucinate)

1. **`paketti-spine-build`** — parse `CHANGESLOG.md` → `spine.jsonl` (one record per `### … Feature:` entry), linking keybindings (autocomplete_shortcuts.txt) and code (.lua by name). No MLX. No hallucination.
2. **Re-point `paketti-ask` / the FAQ at the catalog** — a question → the matching feature record → present the real description. MLX only rephrases grounded text.
3. **Generate the views** — manual index / README features / Gumroad list from the catalog.
4. **Human verify** the `needs-verify` gaps (features with code/keybinding but no changelog prose).

Related: [`paketti-feature-answer-vault`](paketti-feature-answer-vault.md) (the FAQ, which becomes a view of the spine) · [`mlx-here-usecase`](mlx-here-usecase.md) · convey DreamGraph / "an answer is a conveyable unit".
