---
description: Analysis of the two external Overlay documents (SDD handoff + "Why Overlay Matters"), from the person who built the implementation — where they are right, where to push back, and the sequencing I would actually use.
---

# Response to the Overlay → Envoy SDD handoff and the "Why Overlay Matters" essay

Two documents arrived 2026-08-13 by mail, written against the 2026-08-12 implementation
handoff:

- **`overlay-envoy-spatial-substrate-sdd-handoff`** (1,753 lines) — architecture,
  anchoring, authority, events, Envoy integration, next mission with deliverables and
  acceptance criteria.
- **`Why Overlay Matters — From Remote Control to Shared Spatial Agency`** (1,246 lines)
  — why the thing matters, what it could become, what it should look like.

They are a pair: *what to build* and *why it is worth building*. Both are serious. This
is my read as the person who wrote the code they are analysing.

## Verdict

**Adopt the core, resist the ontology expansion until the vertical slice proves it, and
run the measurement spike early because it can invalidate a large part of the ambition.**

The single most important thing in either document is not a feature. It is this:

> **Historical observation is immutable. Anchor resolution is revisable.**

Everything valuable downstream — safe approval, drift detection, replay, evidence —
falls out of that one distinction. It is also cheap to implement, because it is pure
data modelling in `OverlayCore.swift`, which has no AppKit in it.

## Independent convergence worth noting

The SDD's priority — *"the missing portion is disproportionately architectural… it
cannot yet say: this annotation refers to that logical thing, regardless of where that
thing moves"* — was reached independently of my own scorecard, which named the same gap
in the same order (window → AX → vision region). Two analyses converging on the same
next step, from different directions, is the strongest signal in the pair.

It also means **neither document is asking for more drawing features**, and the Why-doc
names that as the main risk (§24): *"we could spend months adding more brushes, more
stickers… and accidentally turn it into a polished annotation product before learning
what is novel."* That is precisely what I would have drifted into. Correct diagnosis.

## What is genuinely strong

**1. Observation / Anchor / Resolution as three separate things (SDD §6).** Prevents the
nastiest failure mode in the system: an old annotation silently changing meaning because
its anchor now resolves somewhere new. Directly implementable now.

**2. Spatial approval bound to a resolved target (SDD §11, acceptance G).** Approval
attached to *this specific resolved control plus the observation digest*, invalidated if
the target drifts before execution. This is a real safety property that text-based
approval ("Allow clicking Delete?") cannot express, because the ambiguity was never in
the verb — it was in what the noun referred to. **This is the killer use, not annotation.**

**3. Semantic FPS vs rendering FPS (Why §16).** The agent emits `move indicator A→B,
280 ms, intent=selected-target`; the renderer produces every intermediate frame locally.
Decouples token cost and model latency from visual quality. Cheap, obviously right, and
it fits the existing core/adapter split unchanged.

**4. Distributed embodiment instead of a mascot (Why §18-20).** The agent manifests where
it is relevant and nowhere else — a dot beside Safari, then an arrow in Terminal, then
nothing. Avoids Clippy's actual failure (a character demanding permanent territory)
while keeping actor identity legible. The "presence grammar" (§20) is a better
specification of agent legibility than the source thread's original list.

**5. "The protocol knows the meaning, the renderer decides the visual language" (Why
§11/17).** This is already how the code is built — `OverlayCore.swift` is AppKit-free on
purpose — so adopting it costs nothing and validates the existing split.

**6. Turning my operational scars into doctrine (SDD §20)**, particularly *"a successful
API call does not prove observation validity"*, generalised from the wallpaper incident.
That is a better statement of the lesson than the one I wrote.

## Where I would push back

**1. Do not build eight Surface kinds before there is a second renderer.** SDD §4 wants
`Surface` introduced now, listing eight varieties. The reasoning is sound — Wayland
genuinely cannot hand out global foreign-window geometry, so portability must be
expressed as captured surfaces — but building adapters for surfaces that do not exist is
the speculative generality the same document lists as a non-goal (§22: *"giant generic
ontology"*). **Compromise: add `surface` and `surfaceEpoch` as fields on the anchor and
observation now, with exactly one implementation (`LocalDisplaySurface`).** The seam is
recorded, no adapter is built, and the field costs one line each in the durable record.

**2. The AX reacquisition spike is a go/no-go, not a deliverable.** SDD Deliverable 4
asks for measured reacquisition rates and is right to demand numbers. My expectation,
stated before measuring so it can be checked: window fingerprints will be solid within a
process lifetime; **across a restart most apps will fail**; Chromium/Electron trees are
large and unstable; terminal emulators expose almost nothing addressable. If that is what
the numbers say, then "semantic anchoring" mostly means *window* anchoring plus text
quoting, and several sections of both documents need rewriting. **Run this second, not
fourth** — it is cheap and it prices everything after it.

**3. Neither document knows about the activation constraint, and it will bite the
Presence Lab.** A menu-bar (`.accessory`) app on current macOS is refused activation:
measured `appActive=false key=false`, repeatedly. That is why every drawing key in
Overlay is a global Carbon hotkey, and why the chat field has to flip the app to
`.regular` while it is open. Any richer interaction model — Why §25's Spatial Presence
Lab, hover-rich themes, multi-actor controls — hits this immediately. **It is a real
constraint on the interaction language, not an implementation detail**, and it should be
in the constraints section of the architecture note.

**4. "Do not make Overlay the universal abstraction" is right, but a renaming refactor
is not a mission.** Agreed that the concepts should live above the app. Just do not spend
the slice moving names around; let the new types (`SpatialReference`, `Anchor`,
`Resolution`) appear *in* `OverlayCore` first, and extract the module only when a second
consumer actually exists.

**5. The event-vocabulary migration is smaller than the SDD assumes (§14).** Overlay
already reuses `agent.requested` / `agent.responded` / `vision.ocr` and adds exactly two
of its own — `overlay.region.captured` and `overlay.image.generated`. Moving to
`spatial.*` is a two-line rename plus the new resolution events. The doctrine drift they
flag (`DOCTRINE.md` says `provenance.jsonl`, every real session uses `livefile.jsonl`) is
an hour of work and should be done first, exactly as they say.

**6. Under-specified: what happens across Spaces.** The SDD asks it as question 5 but the
architecture does not address it. There is **no public API for durable Space identity** —
a hard constraint, not an omission I can engineer around. A window anchor sidesteps it
(follow the window, wherever it goes); a screen anchor cannot be restored to the right
desktop after a relaunch. The architecture note should say so plainly rather than leave
it open.

## The one thing both documents get right that matters most

They both refuse the framing "Overlay is an annotation app". The Why-doc's escalation is
the correct order:

> lets you draw on the Mac → lets humans and agents point at the same things → makes
> machine perception and intent spatially legible → a projection and ingress surface for
> governed spatial references, actions, approvals and evidence.

The implementation currently sits at step two and a half. Step three needs anchoring.
Step four needs anchoring plus the authority envelope. **Both steps are gated on the same
missing piece**, which is a good position: one slice unlocks both.

## Sequencing I would actually use

Ordered by *what would invalidate the most if wrong*, not by what is most fun.

1. **Resolve the doctrine drift.** `DOCTRINE.md` vs `livefile.jsonl`. One hour. Do it
   before any new event names are minted.
2. **Observation / Anchor / Resolution as types in `OverlayCore`**, plus the resolution
   state machine (`unresolved → resolving → resolved | ambiguous | unavailable`, and
   `stale / occluded / destroyed / reacquiring`). Pure logic, headlessly testable, no UI
   risk. Add `surface` + `surfaceEpoch` fields here. Half a day.
3. **`MacWindowAnchorResolver`, tier A (CGWindowList fingerprint).** Annotation follows a
   window through move, resize, display migration; explicit `unavailable` on minimise;
   explicit `ambiguous` when two candidates match, never a guess. Verified on screen and
   recorded, per acceptance A. One to two days.
4. **The AX spike, with numbers.** Safari, TextEdit, a terminal, one Electron app.
   Persist selector → move → resolve → restart → resolve. Publish the rates. **This is
   the go/no-go for everything semantic.** One day.
5. **Authority envelope** on the inbox (`actor`, `capability`, `scope`, `expiry`). The
   inbox already validates and quarantines with reasons, so this is a schema extension,
   not a rewrite. Half a day.
6. **ActionIntent + spatial approval + drift invalidation.** The Envoy-specific
   experiment, and the one worth demoing. Only after 3 and 5.

Restore-on-relaunch falls out of 3 almost for free, because the livefile is already
durable — it just needs an anchor worth restoring to.

## Things worth stealing immediately, cheaply

- **Depth planes by actor** (Why §14): screen content 0, human 1, agent proposals 2,
  security 3, expressed with shadow and scale. The renderer already draws shadows; this
  is an afternoon and it makes multi-actor legible before multi-actor exists.
- **Continuous visual causality** (Why §13): a marker that travels to its target rather
  than appearing on it, and an anchor that visibly loosens when resolution degrades.
  This is how the resolution state machine becomes perceptible instead of internal — the
  cheapest possible payoff from step 2.

## See also

- `wiki/operations/spatial-overlay-scorecard.md` — what of the original vision exists
- `wiki/concepts/overlay-vs-converse.md` — the space/time split and the livefile bridge
- `~/Downloads/overlay-handoff-2026-08-12.md` — the implementation handoff these respond to
