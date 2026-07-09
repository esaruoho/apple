---
title: What Would Sal Add to the RecBurn Molecule
date: 2026-07-09
type: sal-voice-synthesis
subject: recburn multimedia recording pipeline — automation surfaces + typed handoff
status: forward-looking
related:
  - features/recburn-automation-surfaces.feature
  - "esaruoho/apple-rec"
---

# What Would Sal Add to the RecBurn Molecule

Styled impersonation grounded in Sal Soghoian's documented voice signatures (WWSD file +
`sources/sal/`). Not fabricated verbatim quotes — his register, applied forward.

## Where the molecule stands
It now has a **typed exit** (the `recburn.json` manifest — structured data leaves the pipeline
instead of prose) and **typed entrances** (one `recburn://` seam behind Shortcuts, Services, Siri,
and hardware). Good bones. Sal's response would be: *you built the plumbing — now let the water flow
THROUGH to the next room.*

## Sal's additions, in his register

### 1. Make it CHAIN — return the artifact, don't just fire and forget
> "Chain, don't monolith."

The App Intents today return `.result()` — nothing. That's a dead end. A recording that finishes
should HAND ITS OUTPUT to the next action: the final `.mov`, the `.srt`, the length, the mic flag —
all of it as typed Shortcuts values, straight off the manifest we already write. Then a civilian
builds *"Record my screen → upload the .mov to YouTube → post the .srt to the blog → text me the
link"* without a line of code. Right now the manifest is a private note the app reads to itself;
Sal would make it the **return value of the verb** so the pipeline becomes a link, not a terminus.
Concretely: `IntentResult & ReturnsValue<IntentFile>` on Stop/Toggle, plus manifest fields as
output properties a workflow can branch on ("if it has subtitles, then…").

### 2. Add the verbs that ACT ON a file, not just the ones that TRIGGER
> "The rest of us."

Our Services are no-input triggers (toggle/start/stop). Sal's whole donut-and-Bob world is about
**doing something to the thing in front of you**. The thin verbs already exist — `rec-subtitle`,
`rec-audio flatten`. Expose them as **file-input** Services / Quick Actions: select a `.mov` in
Finder → "Burn Subtitles" / "Flatten for YouTube". That's `NSSendTypes` = file URLs, not the empty
no-input we shipped. Now RecBurn earns its place in the right-click menu of every recording anyone
ever made — not only the ones it recorded. That is the difference between a recorder and a *service*.

### 3. Name the phrases like speech
> "Name things like speech, not labels." · "If you can speak it, you can script it."

Audit the Siri phrases. "Toggle RecBurn Recording" is a label. "Record my screen", "Start a
screencast", "Subtitle this video" are speech. The verb should fall out of the mouth.

### 4. Make it scriptable + attachable, not only URL-able
> "Scriptable, recordable, attachable."

The `recburn://` seam is great glue, but Sal's trilogy wants a tiny `.sdef` too, so
`tell application "RecBurn" to start recording` works — and a **droplet / Folder Action**: drop a
`.mov` on it (or into a watched folder) and it burns subtitles unattended. Attachability is the leg
we haven't grown yet.

### 5. Ship the Shortcut PRE-BUILT — pass the Bob test
> "Bob and the donut."

Don't make Bob assemble a Run-Shell-Script shortcut. Ship an importable/downloadable "Record with
RecBurn" Shortcut in the repo so it's one tap to install. The App Intents metadata gap (SwiftPM vs
Xcode) is exactly the kind of plumbing Bob should never see or think about.

## The one-line Sal verdict
> "It's plumbing — and you finally exposed the pipes. Now put a fitting on the end so the next
> pipe can screw on. Return the file, act on the file, name it like speech, and hand Bob the
> Shortcut already built."

The single highest-leverage next move: **#1 — make the intents return the finished artifact +
manifest metadata as typed Shortcuts values.** That one change turns RecBurn from a trigger into a
composable link, which is the entire point of everything Sal ever argued for.
