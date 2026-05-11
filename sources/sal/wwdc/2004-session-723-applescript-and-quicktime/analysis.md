# WWDC 2004 Session 723 — A Powerful Combination: AppleScript and QuickTime (Analysis)

**Speakers:** Sal Soghoian (AppleScript product manager, lead), Ryan Lynch (QuickTime team, Broadcaster + Publisher demos), guest "Tonna" referenced in metadata but not audibly distinguished in the Whisper transcript
**Year:** 2004 (Tiger preview / Panther shipping)
**Source:** https://nonstrict.eu/wwdcindex/wwdc2004/723/
**Note:** Whisper machine transcript; proper-noun homophones ("Sal Segoyna", "applescript.com" for `apple.com/applescript`).

## Sal's framing — automation as inevitability

> *"The meeting of AppleScript and QuickTime has always been an incredibly fertile ground for creating very productive tools… the last thing you should have to do is some repetitive thing over and over again, like setting annotations to movies. It should always be an easy process. And now, with the introduction of Automator, it's going to be even easier."*

This is the **sequel** to 2003 Session 718. One year on, the QuickTime sdef has continued to "grow and grow and grow" (Sal's words), and the headline is no longer just a richer dictionary — it's that **Automator is about to land**, and the same QuickTime verbs Sal demoed via Script Editor in 2003 are about to become drag-and-drop tiles for non-coders. The session is structured as a bridge: half walks the existing QuickTime AppleScript collection (Panther era, ~150 scripts), and the second half is the **Automator preview** — Sal openly admits "we've been skating on the thin ice of a preview release."

## What Sal covers (the substance)

### 1. The QuickTime scripts collection — same as 2003, with Tiger additions

Same `apple.com/applescript` → Applications → QuickTime Player page, same three categories (applets, droplets, script-menu scripts, ~150 total). Sal walks:

- **Limited annotations droplet** — annotations stored in the droplet's **Finder comment field** (one annotation per line, `name: value`). The 2003 droplet-with-preferences pattern (WWSD #38), re-demoed verbatim.
- **Playback property droplets** — `autoplay`, `auto-close when done`, `auto-quit when done`, `auto-present`. Sal's pitch: *"Did you know that a movie can automatically close when it's done? Or it can automatically quit the QuickTime player? Or it can automatically self-present full screen? You can set these properties yourself, but nowhere in the UI of the application currently can you do that."* **Scripting exposes operations the GUI hides.**
- **Help Center example** — embed a movie in a help page, set its URL to `selfpresent.move` with auto-present + auto-close, user clicks the link and gets a full-screen demo that cleans up after itself. *"All of that can be set with AppleScript in QuickTime. Here's a very simple example of how it can be useful in the real world."*
- **Media Skin droplet** — drag a movie onto the droplet, droplet writes XML, composites movie + skin background, saves as self-contained, cleans up. Sal narrates each step on purpose: *"I've left this droplet showing you each step of what it's going to do, so you can see how long and involved the process is. If you take out these dialogues, it happens very quickly."* Same teaching trick as 2003 — the droplet *is the documentation*.
- **Typewriter Text Movie** — frame-level construction of a movie from scratch via AppleScript. *"AppleScript talking to a frame in a movie file live. It's interacting with the player. It's not a pre-done movie."* Total granularity: per-frame default font, color, anti-aliasing, justification.

### 2. The Tiger preview: System Events QuickTime File Suite

The "tip" buried at the end of the existing-tools walkthrough: Tiger adds a **QuickTime File Suite to System Events**, plus a new **XML suite**. The point:

> *"This particular suite will allow you to access information about QuickTime media files without having to use the QuickTime player. You can just ask the question or get the properties of it… without having to rely on the player in the future."*

This is the architectural delta. In 2003 you needed QuickTime Player running to script a `.mov`. In Tiger, System Events can interrogate the file *as data*, headless — no Player launch, no UI. Same shift the 2007-era Image Events / Database Events suites would generalize.

### 3. The Automator preview (the headline)

Sal launches Automator (Tiger preview) and gives the canonical first explanation of the UI: **category buttons** on the left, **actions list** below them, **description pane** at the bottom, **workflow area** on the right. *"It's real easy just to link these things together and create an entire workflow, and then just run the workflow when you're done."*

He builds four workflows live:

1. **Set movie playback properties** — drag a folder of movies in, drop "Set Movie Playback Properties" after, configure autoplay + auto-close + auto-present, run. Same QuickTime sdef verbs from the 2003 droplets, now as tiles.
2. **Set annotations + browse movies** — chains annotation-setting with a "browse movies" action that opens a web-style review interface.
3. **Remote broadcast via QuickTime Broadcaster** (with Ryan Lynch) — workflow creates a settings file → writes it to text → then Ryan switches to "Initiate Remote Broadcast", which uses **Remote Apple Events over wireless** to send broadcast settings to Sal's machine, launch Broadcaster there, and start streaming. Prerequisites called out: *"under the sharing preferences, there is an option for remote Apple events, and I have enabled that, and we have him on my machine as a user."* This is **the live demo of program linking** — Apple Events over the network with user-level authentication.
4. **QuickTime Streaming Server Publisher** — upload files, create playlists, start broadcasting. Sal pulls tracks from an iTunes playlist into the workflow, and Automator silently **converts iTunes track references into file references** for the upload action: *"Automator will handle it for you. It automatically figures out that what I require is a file or a folder, converts the output of the last action into what I need for this action. Ooh, invisible conversion. Didn't know it was there, did you?"* This is the **type-coercion-between-actions** feature that survives into Shortcuts 2018.

### 4. The Sal pitch for Automator

> *"Isn't the whole idea behind automation the fact that you should just be working with what you want to do and not have to deal with the intricacies of how to do that? And that's the beauty of what Automator can do… now this takes it to the next level to where you're just saying, I want to do this task, then that task, then this task, and go do it for me."*

This is the **canonical Automator framing** — "say what you want done, don't write how to do it." WWSD #1 (democratization) operationalized for the post-Studio audience: AppleScript demanded a syntax, Automator demands only an arrangement of tiles. The phrase *"I want to do this task, then that task, then this task"* is the verbal user-model Sal will repeat across every Automator session for the next decade.

### 5. The forward-compat reassurance

> *"If the person who created that workflow enables you to do that, yes. You can open them back up into Automator and change whatever parameters you want."*

Q&A early in the session — Sal confirms workflows are **inspectable and modifiable** unless the author locks them. WWSD-grade: the user owns the recipe, the recipe is readable, and the author can choose to ship it open or sealed. (The same principle re-stated as a security feature in 2012.)

## WWSD-relevant takeaways

- **#33 four whys (consistency/accuracy/speed/scale)** — implicit throughout, but *"the last thing you should have to do is some repetitive thing over and over again"* is the speed/scale pair restated.
- **#34 vision-stability since 1992** — *"the dictionary within QuickTime has grown and grown and grown"* is an explicit appeal to incremental, decade-long API enrichment as the model.
- **#35 GUI scripting last resort** — playback properties *"nowhere in the UI of the application currently can you do that"* is the inverse pitch: when sdef *does* expose the property, **GUI scripting is unnecessary**. The dictionary is always the first surface.
- **#38 droplet-with-preferences** — same Finder-comment pattern as 2003, re-demoed unchanged. The pattern was an architectural fixed-point one year after introduction.
- **#1 democratization** + **#31 peer to Aqua** — Automator's pitch reframes AppleScript's "peer to Aqua" claim as **peer to the user's everyday tasks**. The actions tile is to the workflow what the Aqua button is to the app.
- **Candidate operational principle: type coercion as a Sal pattern** — Automator's invisible action-to-action type conversion (iTunes track → file ref → upload) is the same WWSD-grade move as "the OS does the work, the user expresses the intent." Worth noting alongside #33 as an *operational* WWSD pattern: **the user composes by meaning; the OS composes by type**.

## Reusable for the apple repo

- **Headless QuickTime file inspection** — the 2004 System Events QuickTime File Suite is the ancestor of today's `mdls`, `mdimport`, and `AVAsset` headless reading. `bin/voice-memos-exporter` and `bin/image-capture-exporter` already do this pattern; a `bin/movie-metadata-probe.py` (no QuickTime Player launch) would be the direct port.
- **Remote Apple Events recipe** — Sharing prefs → Remote Apple Events on + add target-machine user. Apple still ships this surface in Sequoia. `bin/sal-grand-export` could grow a `--remote <host>` mode for batch-exporting against a CloudcityMacMini-style always-on Mac.
- **The droplet-narrates-its-own-steps trick** — *"I've left this droplet showing you each step of what it's going to do."* Every `bin/` script that does multi-stage work should have a `--narrate` flag that prints "now opening… now writing XML… now applying playback settings… now cleaning up." Same teaching pattern as Sal's media-skin droplet.
- **Type coercion between Automator actions** ≈ Shortcuts' magic-variable type ladder ≈ Loupedeck's "any input goes to any handler" model. Worth a `painpoints/` write-up on which 2026 Apple surfaces preserve this and which lost it (Shortcuts: yes; Quick Actions: partial; Services menu: strings/files only).
- **Sal as Automator pitchman** — the *"you should just be working with what you want to do and not have to deal with the intricacies of how to do that"* line is verbatim quotable for any Loupedeck / Hey Sal user-facing documentation. It belongs on the README.
