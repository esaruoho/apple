# Overlay — report card

**One sentence:** a transparent sheet of glass over your whole screen that you and AI
agents can both draw on, ask questions through, and generate pictures into — and
everything you do on it is written to a durable, portable document.

**Where it is:** `~/work/apple/overlay/` (the app) · `~/work/apple/bin/overlay*` (the
command line) · `~/.overlay/` (its files) · `~/work/converse/sessions/*-overlay/` (its
history).

**How much:** ~7,800 lines. **291 tests, all passing** — 224 pure-logic, 67 against a
real live screen. 24 commits, all pushed.

**Grades:** ✅ works, verified · ⚠️ works with a caveat · ❌ not built.

---

## What you can actually do

| | How | |
|---|---|---|
| Draw on top of everything | **⌃⌥⌘D**, then draw | ✅ |
| Keep using your Mac with it up | it's invisible to the mouse until you ask | ✅ |
| Select a region of the screen | `r`, then drag a box | ✅ |
| **Ask about what's in that region** | **⌃⌥⌘T**, type, ⏎ — answer appears at the thing | ✅ ~5s |
| **Turn your sketch into a picture** | draw, then **Render drawing ⌥⏎** | ✅ 60–90s |
| **Type a description, get a picture** | **⌃⌥⌘I** | ✅ 60–90s |
| Read text off the screen | box a region → **Read text here ⌘⏎** | ✅ |
| **Pin a mark to a window so it follows** | **⌘A** in draw mode, or `overlay attach` | ✅ new today |
| Get rid of everything | **⌃⌥⌘C** — works from any state | ✅ |
| Get rid of one thing | click its **✕** | ✅ |
| Let an agent draw on your screen | drop JSON in `~/.overlay/inbox/` | ✅ |
| See the whole history | `overlay session --transcript` | ✅ |

**The four keys that matter:** ⌃⌥⌘D draw · ⌃⌥⌘T ask · ⌃⌥⌘I make a picture ·
**⌃⌥⌘C wipe everything**.

---

## The three things it's actually for

**1. Point instead of describing.** Circle something on screen and ask about it. The
model gets the picture, the text in it, and where it is — not your paragraph trying to
describe it. ✅

**2. Your drawing is the prompt.** Draw a cube, get a rendered cube. No words involved
at any point — Image Playground takes the sketch itself as the input. ✅

**3. Agents can point back.** Any script can put an arrow, a highlight, a warning or a
spotlight on your screen, tagged with who did it and how long it lives. ✅ Nothing has
actually used this yet besides me. ⚠️

---

## Under the hood, in plain terms

| | |
|---|---|
| **Depth** | your marks sit low, agent marks above them, warnings highest — read as shadow and overlap, not colour codes ✅ |
| **Motion** | marks arrive and settle rather than appearing; temporary ones fade rather than blinking out ✅ |
| **Provenance** | every mark records who made it ✅ |
| **Lifetimes** | 5-second, session, permanent — an agent that forgets to say gets "session", so it can't litter ✅ |
| **Authority** | an agent must present actor + capability + scope + expiry; no expiry is refused; **nothing can grant execution** ✅ |
| **Approval** | approval binds to *the resolved target and the picture you were shown* — if it moves or changes, execution is refused ✅ logic done, ❌ no demo yet |
| **History** | every exchange appended to a Converse session; the log is the document, the transcript is a view ✅ |

---

## What's honestly not there

| | |
|---|---|
| Marks following a window **after the app restarts** | ⚠️ untested — the one number still missing |
| Pinning to a *button* rather than a window | ❌ the AX numbers say it's viable (67–95% of controls are uniquely addressable); not built |
| Marks coming back after Overlay relaunches | ❌ possible now the history is durable |
| A conversation with memory | ❌ each question stands alone |
| An agent showing what it's about to click | ❌ the vocabulary exists, nothing drives it |
| Overlay on anything but this Mac's screen | ❌ |

---

## Measured, not claimed

- Window fingerprint stability: **100%** (23 samples).
- A minimised window leaves the window list: **179 → 178**.
- Buttons uniquely addressable by name: **Calendar 95% · Finder 89% · Safari 67%**.
  *(I predicted this would be bad. It isn't. Recorded because I wrote the prediction
  down first.)*
- Ask round trip: **~5s**. Idle cost: **0% CPU**.
- Moving a window: mark followed **exactly** (+250 across, −80 down).

---

## The nine traps that cost real time today

1. **No Screen Recording permission ⇒ macOS hands over your WALLPAPER**, silently. Every
   answer described your desktop picture for a whole morning.
2. **Rebuilding the app voids that permission** while Settings still shows it enabled.
3. A menu-bar app **can never take the keyboard** — hence global hotkeys everywhere.
4. Which meant **the text field ate its own letters**; typing "free" lost the f and r.
5. A GUI app's child process gets a **stripped PATH**, so OCR silently returned nothing.
6. The **Syncthing queue is the wrong pipe for a question** — 50s vs 4s over SSH.
7. Telling a model "don't mention tools" **makes it emit tool calls**.
8. Never let a model **invent an image subject** — "not against my own plan" became a truck.
9. **A data dump is not a screenshot.** Most of today's UI defects were found by you
   photographing your screen while I read an object store that was always "correct".

---

## If you only remember three things

1. **⌃⌥⌘C** gets your screen back from any state.
2. **⌃⌥⌘D** → draw → **⌥⏎** turns your sketch into a picture.
3. **⌃⌥⌘T** asks a question about whatever you last boxed.

Full detail: `~/Downloads/overlay-handoff-2026-08-12.md` ·
`~/work/apple/wiki/operations/overlay-anchor-measurements.md` ·
`~/work/apple/overlay/overlay.feature`
