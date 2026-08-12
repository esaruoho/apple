---
description: Overlay vs Converse — a spatial layer over where you already are, versus a durable time-ordered conversation document. What each owns, and the seam where they should join.
---

# Overlay vs Converse

Both are Apple-native Swift apps, both talk to FoundationModels, both have something
that looks like a chat. They are answering different questions.

## The one-line difference

- **Converse** — *"what was said, in order, and keep it."* A place you go.
- **Overlay** — *"what about THIS thing, here."* A layer over where you already are.

Converse is organised by **time**. Overlay is organised by **space**.

## Converse (`~/work/converse`)

A fullscreen live-transcribing text editor. Speak, and text appears (`mlx-whisper`
locally, ~11× realtime); edit anywhere while it keeps transcribing; the audio is saved
beside the transcript. TTS reads back, and a roundtable of voices can take turns.

Its doctrine (`DOCTRINE.md`, adopted 2026-05-27) is the important part:

> **The transcript is a view. The event log is the document.**

A session is a portable directory — `manifest.json`, an append-only `provenance.jsonl`
as the source of truth, a derived `transcript.md`, artifacts, exports, audio. Copy the
directory to another machine and the conversation still makes sense. It is
ENVOY-adapter-compatible by design.

**So Converse owns: durability, ordering, provenance, voice, and the document.**

## Overlay (`~/work/apple/overlay`)

A transparent click-through canvas above every window, one per display per Space. Ten
object kinds with anchors, actors and TTLs. Circle a region and ask about it (Vision OCR
→ FoundationModels, ~5s). Sketch something and have it rendered (Image Playground takes
the drawing itself as input). Any process can post objects as JSON into
`~/.overlay/inbox/`.

**So Overlay owns: position, pointing, other apps' content, and the live screen.**

Its conversation is deliberately thin — one exchange at a time, cleared with Esc,
nothing restored on relaunch. It has no document.

## Side by side

| | Converse | Overlay |
|---|---|---|
| Organising axis | time | screen position |
| Where it lives | its own fullscreen window | on top of everything else |
| Primary input | your voice | your pointer, and a typed question |
| Subject | what you say | what is already on your screen |
| Lifetime | permanent, portable session directory | session; Esc clears it |
| Source of truth | append-only provenance log | an in-memory object store, mirrored write-only |
| Model use | transcription, TTS, roundtable | OCR + one-shot Q&A, image generation |
| Multi-turn | yes, that is the point | one exchange, no memory |

## The seam

The gap in Overlay is exactly what Converse already solved. An overlay exchange —
*region, crop, OCR, question, answer, actor, timestamp* — is precisely the shape of a
provenance event. Appending it to a Converse session would give the spatial side the
durability and threading it lacks, without inventing a second storage doctrine:

```
overlay: circle a thing, ask            →  event: {anchor, crop, question, answer, actor, t}
                                        →  appended to a Converse session's provenance.jsonl
                                        →  transcript.md renders the exchange
                                        →  the thread survives a relaunch, and is portable
```

The rule that keeps this honest is Converse's, and it applies to Overlay too: the marks
on screen are a *view*; the event log should be the document. Overlay currently has only
the view.

## When to reach for which

- Talking, thinking out loud, wanting a record → **Converse**.
- Pointing at something on screen and asking about it, or sketching → **Overlay**.
- Wanting the pointing to be remembered → that is the unbuilt bridge above.

## See also

- `~/work/converse/DOCTRINE.md` — the event-log doctrine
- `wiki/operations/spatial-overlay-plan.md` — Overlay's phases
- `wiki/operations/spatial-overlay-scorecard.md` — what of the vision exists
