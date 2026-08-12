---
description: Honest scorecard of Overlay.app against the original spatial-overlay vision — what shipped 2026-08-12, what is partial, and what was never built.
---

# Spatial overlay — vision vs. what exists

Source of the vision: `~/work/convey-packs/chatgpt/6a785108-e47c-83ed-a844-e5bfaca19635/conversation.md`
(2026-08-08). Built: 2026-08-12, one session. Code: `overlay/`, `bin/overlay*`.

Grading is against what the thread actually asked for, not against the plan I wrote.
`✅` works and was verified on screen · `🟡` partial · `❌` not built.

## The core idea

> *"A shared spatial blackboard between humans and machine agents."*

✅ **Exists.** A transparent click-through canvas over every window, one per display per
Space, that both a human and any script can draw on. It is the thing the thread
described, minus the anchoring depth (below).

## Interaction model

| Vision | State |
|---|---|
| Transparent overlay above everything | ✅ borderless `NSPanel` at `.floating` |
| Invisible to input until asked | ✅ `ignoresMouseEvents`; verified the Mac stays usable |
| Modal draw mode, hotkey in / Esc out | ✅ ⌃⌥⌘D / Esc (⌥⌘D was swallowed; ⌃⌥⌘ family used) |
| Lives in one Space, slides away with it | ✅ ordinary managed window, **zero private API** |
| Works over fullscreen | 🟡 `.fullScreenAuxiliary` set, untested — Esa dropped it from scope |

## The primitive set

The thread listed 12 semantic objects. Ten exist and render:

✅ `arrow` `highlight` `box` `label` `sticker` `freehand stroke` `spotlight`
`speech bubble` (as `callout`) · plus `line` and `image`, which the thread did not ask
for — `image` is the generated-picture object.

❌ `pointer` · `underline` · `progress/status badge` · `mask/dim region` as distinct
from spotlight.

## Anchors — the biggest gap

The thread was explicit that the last two matter most.

| Anchor | State |
|---|---|
| `screen` | ✅ the only one implemented |
| `display` | 🟡 recorded on every object, never resolved |
| `space` | ✅ implicitly, by being an ordinary window |
| `window` | ❌ **not built.** Marks do not follow Safari when it moves |
| `accessibility_element` | ❌ not built |
| `vision_region` | ❌ not built |

> *"Instead of `draw arrow at x=1427 y=593`, an agent should be able to say: application
> Safari, window Settings, element AXButton 'Export Data'."*

Not possible today. Everything is screen coordinates. `AXObserver` was verified present
in the SDK on day one and never used. **This is the single largest piece of the vision
that is missing.**

## Bidirectional

**Agent → human** ✅ An agent points, highlights, labels, warns, leaves marks, via
`~/.overlay/inbox/*.json` or `overlay post`. Provenance and TTL on every object.

**Human → agent** ✅ Circle a region → it becomes a crop → Vision OCR → FoundationModels
→ answer anchored back at the thing. This is the deictic loop the thread wanted, and it
works: ~5s end to end over a direct call to the Mini.

🟡 The "structured reference" is thinner than described: the agent receives the crop,
its OCR, classifier labels and the region — **not** the app, window or AX element under
it, because those anchors do not exist.

## Chat

> *"a highlighted region and 'what's going on here?'"*

✅ Type a question into a field anchored at the region, ⏎ sends, the answer lands as a
callout on the same anchor, your question stays above it as `you: …`.
✅ Every exchange is now durable — appended to a Converse session, see below.
🟡 The UI still shows one exchange at a time; the model gets no memory of the last answer.

## Durability — added after this scorecard was first written

✅ Overlay writes into a Converse session directory in `envoy-livefile-v1` shape:
`livefile.jsonl` is the document, `transcript.md` a regenerated view, the folder is
portable. Reuses Converse's `agent.requested` / `agent.responded` / `vision.ocr` types.
See `wiki/concepts/overlay-vs-converse.md`. **This closes the "marks are a view with no
document" gap.**

## Lifecycle, provenance, multiple agents

✅ All five TTLs from the thread exist (`ephemeral` 5s · `session` · `space` · `window` ·
`persistent`); `ephemeral` is collected on a timer that only runs while something
ephemeral is on screen. An omitted TTL defaults to `session` so an agent cannot litter.
✅ Every object carries an actor (`human:esa`, `agent:fm`, `agent:ask`, `agent:imagine`)
rendered as a small tag — identity by provenance, not by gaudy colour, exactly as asked.
🟡 Several agents *can* annotate at once; nothing has actually done so yet.
❌ `window` and `space` TTLs are recorded but never enforced (they need window anchors).

## Agent legibility

> *"thin outline = agent sees this · highlight = relevant · arrow = intended action ·
> checkmark = completed · warning sticker = uncertainty"*

❌ **Not built.** The vocabulary can express it, but nothing drives it — no agent
publishes what it is looking at or about to click.

## Architecture

✅ The declarative JSON object API the thread sketched, near-verbatim, including `kind`,
`anchor`, `text`, `actor`, `ttl`. Bad input is rejected by name with the reason written
beside the request.
✅ Object store with lifecycle. ✅ Provenance. ❌ Permissions — any local process can post.
✅ Portable core: `OverlayCore.swift` has no AppKit, so a second backend stays possible.
❌ Envoy ingress not wired.

## Beyond the vision

Two things the thread did not ask for and that exist:

- **Draw → picture.** A sketch is fed to Image Playground as the actual input
  (`ImagePlaygroundConcept.image`), so a drawn cube returns a rendered cube. No prompt.
- **Region → text.** On-device Vision OCR of any screen region, answered by
  FoundationModels.

And the thread's own conclusion — *"prototype it in Electron"* — was rejected. All of
this is AppKit, Vision, FoundationModels and Image Playground, no dependencies.

## Honest summary

**Roughly 70% of the vision** (60% before the Converse bridge and chat landed). The blackboard, the primitives, the lifecycle, the agent
channel, the deictic human→agent loop and the chat all work. The **anchoring model —
window, AX element, vision region — is the bulk of the missing 30%**, and it is the part the source
thread called the most important. Until it exists, every mark is pinned to screen
coordinates and nothing follows the thing it is about.

Next, in order of value: **window anchoring (CGWindowList first, then `AXObserver`)** ·
restore on relaunch (now possible — the livefile is durable) · a threaded UI over the
stored exchanges · agent legibility.

A handoff written for a fresh reader lives at
`~/Downloads/overlay-handoff-2026-08-12.md`.
