---
description: Build plan for Overlay.app — a shared spatial blackboard over the macOS desktop where humans and agents point, annotate, chat, and reply in the same coordinate space. Apple-native, no Electron.
---

# Spatial Overlay — build plan (Apple-native)

**Source thought:** `~/work/convey-packs/chatgpt/6a785108-e47c-83ed-a844-e5bfaca19635/conversation.md`
(2026-08-08, gpt-5-6-thinking). That thread landed on the right abstraction — *a shared
spatial blackboard between humans and machine agents* — and then concluded with
"prototype it in Electron." **We reject that conclusion.** Every primitive it wanted is
already PUBLIC Apple API, and most of it is already built in this repo. Electron would be
a second rendering engine, a second update path, and a Homebrew dependency, to reach a
place `swiftc` reaches in an afternoon.

Status: **plan only, nothing built yet** (2026-08-11).

---

## 1. What it is

Three things in one surface, all sharing one coordinate space:

| | |
|---|---|
| **Annotation** | ink, arrows, highlights, boxes, spotlights, stickers — drawn by a human OR posted by an agent |
| **Chat** | a speech bubble *anchored to a thing on screen* is an editable text field; typing in it and hitting ⌘↩ sends |
| **Responses** | the reply comes back as another anchored object on the same anchor — the thread lives at the thing, not in a sidebar |

The point is **deixis**: stop saying "the second button under Account Settings," just point
at it. Bidirectional — agent→human (here is what I am about to click) and human→agent
(circle a region, ask "what's wrong here?").

## 2. Core rule (inherited from the source thread, and correct)

> **Do not encode NSWindows or raw screen pixels into the core abstraction.**

The core knows: `surface · region · element · object · anchor · actor · lifetime · provenance`.
An AppKit adapter resolves those into pixels. This keeps the same protocol usable later for
a Fleet peer's screen, a captured stream, or a phone — without rewriting the semantics.

The wire object, which is also the on-disk store record and the agent API:

```json
{ "kind": "callout",
  "anchor": { "type": "element", "app": "com.apple.Safari",
              "window": "Settings", "role": "AXButton", "title": "Export Data" },
  "content": { "text": "Use this one", "glyph": "arrow" },
  "actor": "agent:fm", "ttl": "session", "confidence": 0.8 }
```

Anchor types, resolved by a chain that degrades gracefully:
`screen` → `display` → `space` (implicit) → `window` → `element` (AX) → `region` (Vision).

## 3. Reuse before re-rolling — what already exists here

Per `feedback_reuse_before_rerolling`. This is the DRY audit; nothing on this list gets rewritten.

| Need | Already in repo |
|---|---|
| Transparent floating panel, Spaces-aware | `LiveEnvelopePanel/main.swift:61-78` — `NSPanel`, `.floating`, `[.canJoinAllSpaces, .fullScreenAuxiliary]`. **The chassis exists.** |
| Arrow rendering | `bin/live-envelope-arrows.swift` (350 lines) |
| Window geometry without any TCC prompt | `bin/window-frame` — CGWindowList → JSON (pid, owner, title, x/y/w/h, screen) |
| Global hotkey (⌥⌘D) | AppleToolbox Carbon `RegisterEventHotKey` — see `feedback_carbon_hotkey_gotchas` |
| Menu-bar host + status | `topbar/AppleToolbox.swift` |
| On-device LLM (the responder) | `bin/fm` local · `bin/fm-submit` → Mini · `FoundationModelsChat/` |
| Text under a region | `bin/vision-ocr` (Vision, Neural Engine) |
| Screenshot / crop | `bin/snap`, `bin/screen-frame-minus-toolbox`, `sensor-snapshot/` |
| Semantic dedup / "is this the same annotation" | `bin/apple-embed` (NLEmbedding, 512-dim) |
| Agent ingress chassis | trigger→worker file-drop (Finder tag · Voice Memo · Stickies · Mail flag) — **this is the 5th instance** |
| Help + donate panel | `shared/SupportHelp.swift` (mandatory, per project ground rule) |

New code is roughly: the object store, the anchor resolver, the renderer for semantic
objects, and the chat bubble. Everything else is wiring.

## 4. API verification (hard rule: probe before naming)

`bin/cocoa-class-probe`, run 2026-08-11:

```
NSPanel PUBLIC · NSVisualEffectView PUBLIC · NSBezierPath PUBLIC · NSTrackingArea PUBLIC
CAShapeLayer PUBLIC · SCShareableContent PUBLIC · NLEmbedding PUBLIC · NSTextView PUBLIC
PKCanvasView PUBLIC ← PencilKit is on macOS; free ink engine, don't hand-roll strokes
AXObserver ABSENT   ← expected: it's a CF type, not an ObjC class
```

`AXObserver` verified by header instead — `AXObserverCreate`, `AXObserverCreateWithInfoCallback`,
`AXUIElementCopyAttributeValue`, `kAXWindowMovedNotification`, `kAXWindowResizedNotification`,
`kAXUIElementDestroyedNotification`, `kAXFocusedWindowChangedNotification` all present in
`ApplicationServices/HIServices/AXUIElement.h` + `AXNotificationConstants.h`.

**No private API anywhere in this plan.** In particular: no CGS/SkyLight Space enumeration.

## 5. Tier justification

The skill's default order is ASObjC → Python stdlib → Swift → shell. This is a **tier-3
Swift** job and it earns it: custom `NSPanel` subclass, `NSView` drawing, `AXObserver`
callbacks, Carbon hotkeys. Precedent in-repo: LiveEnvelopePanel, AppleToolbox, Fleet.
The *agent-facing* side stays tier-2 Python stdlib (`bin/overlay`), so anything can post
an object with no compile step.

## 6. Architecture

```
   agents (Claude / fm / Fleet peer / any script)
                    │  JSON objects
                    ▼
        ~/.overlay/inbox/*.json          ← file-drop, Syncthing-able
                    │
        ┌───────────┴────────────┐
        │  Overlay.app (Swift)   │
        │  ├ ObjectStore         │  ~/.overlay/store/  JSON, TTL-GC'd
        │  ├ AnchorResolver      │  CGWindowList → AXObserver → Vision
        │  ├ Renderer            │  PKCanvasView ink + CAShapeLayer semantics
        │  ├ ChatBubble          │  NSTextView, ⌘↩ submits
        │  └ Responder           │  fm | fm-submit | claude-relay
        └───────────┬────────────┘
                    ▼
   two panel classes, deliberately:
     managed panel   collectionBehavior []                 → lives in ONE Space
     HUD panel       [.canJoinAllSpaces,.fullScreenAuxiliary] → everywhere
```

**Spaces, solved without private API.** A screen-anchored annotation is drawn into a
*managed* panel created while you are in that Space. Swipe away and macOS slides it out
with the Space, exactly as asked — because it is an ordinary window. Global HUD gets the
`canJoinAllSpaces` panel. Nobody ever needs to know `spaceID=847`.

**Input, solved.** Panel is `ignoresMouseEvents = true` by default: the overlay is
invisible to the pointer, the Mac stays usable. ⌥⌘D flips it false (draw mode); `Esc`
flips it back. One bit of state.

**Window tracking, two tiers.** Tier A: CGWindowList fingerprint (pid + owner + title +
geometry), polled ~10 Hz *only while an attached annotation is visible* — zero TCC prompts,
works day one. Tier B: `AXObserver` on moved/resized/destroyed — event-driven, no polling,
costs one Accessibility grant. Ship A, upgrade to B; the anchor record is identical.

**Strokes stored window-relative** (`0.12, 0.33`), never desktop pixels — so they survive
window moves, resizes, resolution changes, and display swaps.

## 7. Chat + responses — the part the source thread never designed

A `chat` object is just another anchored object whose content is a conversation:

1. ⌥⌘D, drag a region or click a UI element → an anchored bubble appears, focused.
2. Type. ⌘↩ submits. What actually gets sent is not just the text:

```
{ text, anchor, app+window+AX element under it,
  ScreenCaptureKit crop of the anchor rect,
  vision-ocr of that crop, timestamp, actor:"human:esa" }
```

   That is the "structured reference" — the agent gets the *pixels and the semantics* of
   the thing you pointed at, not a paragraph of prose describing it.

3. The responder answers; the reply is written back as a new object with the **same
   anchor** and `actor:"agent:fm"`. It renders as a reply bubble at the thing.

Responder backends, in order of cost:
- **`bin/fm`** — FoundationModels on-device, zero token, zero network, instant. **Default.**
  Non-deterministic → majority-vote when it is judging rather than chatting.
- **`bin/fm-submit`** — same model on the Mini, for when this Mac is busy.
- **claude-relay** — file-drop to a Claude Code session for anything heavyweight.

Actor identity is metadata, not gaudy colour: a small label + provenance on each object.
TTLs (`ephemeral 5s · session · space · window · persistent`) get GC'd by the store so
agents cannot litter the screen forever.

## 8. Phases

| Phase | Deliverable | Proves |
|---|---|---|
| **P0** | Fork LiveEnvelopePanel → `overlay/Overlay.app`: transparent panel, ⌥⌘D click-through toggle, PencilKit ink, screen-anchored, per-Space | the interaction feels right |
| **P1** | Object protocol + `~/.overlay/inbox` + `bin/overlay post/list/clear` + semantic objects (arrow/box/highlight/spotlight/label/sticker) | **an agent can point at something** |
| **P2** | Window anchoring: tier A CGWindowList, then tier B AXObserver; window-relative geometry | ink follows Safari when Safari moves |
| **P3** | Chat bubble + context capture (SCK crop + vision-ocr + AX dump) + fm responder | the bidirectional loop closes |
| **P4** | Element + Vision region anchors, multi-actor provenance, TTL GC, Fleet peer posting, Envoy/Convey ingress | it becomes infrastructure |

P0 is an afternoon because the panel already exists. P1 is the one that matters — after
P1 this stops being a drawing app.

## 9. Known limits — stated up front, not discovered later

- **Space identity is not durable across logout/reboot.** Public API gives no Space IDs.
  Within a login session the behaviour is exactly as wanted. Persistent-across-reboot
  annotations must anchor to a *window* or *display*, not a Space. No CGS workaround will
  be added.
- **Fullscreen games / DRM video** may composite over or reject the overlay.
  `.fullScreenAuxiliary` covers normal AppKit fullscreen; the rest needs testing.
- **TCC.** Accessibility (tier B) and Screen Recording (context capture). If a helper
  binary does the ScreenCaptureKit work it must be bundled in `Contents/Helpers` and
  co-signed with the app identity or the grant re-prompts forever —
  `feedback_tcc_bundle_sck_helper_same_identity`.
- **Never UI-hijack.** The overlay must not synthesise keystrokes into the frontmost app —
  `feedback_never_ui_hijack_active_session`. Agent "point at this" is legal; agent
  "click it for you" is a separate, opt-in, out-of-scope decision.
- `lsregister -f` after every .app bundle change — `feedback_lsregister_after_app_bundle_changes`.

## 10. Definition of done for each phase

Report-card triad is mandatory and born with the code, not after:
`overlay/overlay.feature` (graded claims) + `overlay/overlay.session.md` (this conversation,
with the clickable resume block) + RESULT block (commits/files). Pure-logic parts — the
anchor resolver's coordinate maths, the TTL GC — get a headless assertion test that
`build.sh` gates on, per `feedback_test_renderers_headlessly`. Shared Help panel wired via
`AppHelpCommand(appName: "Overlay")`, per the repo ground rule.

## See also

- `wiki/concepts/global-keyboard-shortcuts.md` — the ⌥⌘D path
- `wiki/concepts/finder-tag-pipeline.md` — the trigger→worker chassis this is the 5th instance of
- `wiki/concepts/sensor-snapshot.md` — capture side
- `LiveEnvelopePanel/main.swift` — the panel chassis being forked
