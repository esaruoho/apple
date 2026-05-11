# MTC 2019 Endnote — Creating the Ultimate Set of Control Panels

**Speakers:** Neal Wright (host intro) + Sal Soghoian (main)
**Length:** 490-line transcript, ~50KB. Conference endnote talk at MacTech Conference 2019.
**Context:** Sal demos a hidden Apple feature — the **Panel Editor** in `/System/Library/Input Methods/AssistiveControl.app` — combined with Luna Display + iPad Pro + AppleScript libraries to build per-app custom touch control panels. This is a **completely undocumented Apple capability** that Sal explicitly says Apple itself may not know about.
**Audit attestation:** every quoted phrase below verified verbatim by direct read of transcript.txt by Esa's auditor on 2026-05-11.

## The historical position

Three years after the elimination, Sal is back at MacTech Conference as "automation researcher" doing contract work for both Apple and Omni (line 7). This talk is the **single most consequential Loupedeck/Stream Deck ancestor in Sal's corpus** — a system where the iPad becomes a programmable per-app touch control surface, with every button bound to AppleScript handlers in user-authored libraries.

> *"I had this thing that nobody's seen that I think is pretty darn interesting but I've never shown it before and nobody's ever actually seen this thing in action and I don't think Apple knows that it's possible."* (lines 14-17)

The "Apple doesn't know" line is the WWSD signature here: a Sal-class researcher poking at his former employer's own OS finds capabilities the shipping team forgot about. Mojave shipped this. Catalina shipped this. Apple never marketed it.

## Sal's framing — research mode

> *"I'm fascinated by all things automation and I have a vision that automation should be easy on the computer. Unfortunately that vision is always met with difficulties because people aren't aware of automation as they are other factors on the computer and sometimes it gets missed or overlooked."* (lines 19-22)

WWSD #1 (democratization) restated in 2019: not as a slogan, as a *complaint*. The vision still hasn't won inside Apple.

## The architecture — Panel Editor + Luna Display + AppleScript Libraries

### The hidden app

**`/System/Library/Input Methods/AssistiveControl.app`** with its **Panel Editor**. Buried in System Library where no normal user looks. Enable via: System Preferences → Accessibility → check "Enable Assistive Control" (lines 41-42).

> *"This man said well let's take a look at what that does and it turns out that using this app you can create your own custom assistive keyboards but they don't have to be keyboards in the normal sense of keyboards they can be something else they can be full control panels."* (lines 36-40)

The Panel Editor lets you create UI buttons of arbitrary size with custom images, then assign actions. Action types include:
- Open specific panel (line 107)
- Show/hide toolbar (line 109)
- Insert text (line 117)
- Press keys / key combinations (line 118-120)
- Open an application (line 121)
- Trigger system event (volume, brightness, eject, playback) (lines 123-127)
- Typing suggestions (line 128)
- **Run an AppleScript script** (line 134) ← the headline action

### The Luna Display trick

Luna Display = the little red dongle that turns iPad Pro into a touch-capable second display.

> *"The sidecar, you can use a pen, but you can't use your finger. You can use two fingers as a swipe, but you can't use one finger. So I said, hmm, it turns out that the Luna doesn't have that prejudice."* (lines 62-64)

**Sidecar is touch-disabled by Apple policy. Luna Display isn't.** Sal weaponizes this: Panel Editor panels via AssistiveControl, displayed on iPad via Luna, become touch-driven control surfaces for the Mac.

### The "library + one-line scripts" pattern (echoes WWDC 2013 #416)

> *"You can create an AppleScript library... it's nothing more than a regular script file that has functions... your library can have a thousand functions in it if you want to."* (lines 159-163)

> *"I can have a simple little one-line script here that basically says tell script the name of the library keynote dash library and then the name of the function that I'm calling and I'm passing in a couple initial parameters right so make a new gradient presentation 1920 by 1080."* (lines 169-172)

This is **WWSD #36 (cleaning and waxing in one motion) + WWSD #43 (one verb per action) + WWDC 2013 #416 (AppleScript Libraries)** all converging. Library holds handlers. Panel button references library handler. One tap = one verb.

## The Panel Design principles — "muscle memory"

> *"Each panel has the same set in the same location so that I can sit there and I instantly have muscle memory on how to get between the different apps."* (lines 241-243)

The structural design rule: **every panel has the same chrome in the same place.** Top row = app switcher icons. Bottom row = system-preference shortcuts. Center = app-specific verbs.

This is a candidate new WWSD principle (see #46 below) — *muscle memory as a first-class design constraint for control surfaces*.

## The Keynote panel — what Sal actually built

App-specific verb categories (rows 267-289):
- **Document controls** (top 2 rows): make new presentation, save, close, close all, show file info
- **Slide masters** (next): tap to change master slide
- **Slide editing** (left): insert blank, append blank, move to end, delete, skip/unskip, edit title/body, undo/redo, overlay titles, **magic duplicate**, replace images
- **Transitions**: reset, auto transition, panoramic sequence, magic move, dissolve, object zoom, swap
- **Durations**: instantaneous transition duration setters
- **Playback** (left): controls for live presentation
- **Image controls** (right): open back in Photos, etc.

### The signature verb: **Magic Duplicate**

> *"A magic duplicate takes a slide, duplicates it, and applies a magic move to the first one so that you can animation by just tapping magic duplicate and changing the shape of the items on the second slide."* (lines 277-279)

**One tap = duplicate-slide + apply-magic-move-transition.** Compound verb. The user just changes the shapes on the new slide; Keynote animates the transition. Sal's example of compound-verb design.

## Security pain — the "no plus button" wall

> *"You set up all the security to allow that app to do what it's going to need to do... You have to go in and add, but the problem is, is that once you've had to do this for all of these different apps, just to enable the computer to do what you used to be able to do right out of the box, then you come across some that don't have plus buttons. They're supposed to automatically sense this for you, but they don't because nobody thought about that there might be an automation running. So sometimes you just hit a brick wall."* (lines 206-215)

**The WWSD #35 (GUI scripting last resort) prescription returns:** when the System Preference doesn't even have the UI to grant the permission, the user is stuck. Apple's security team didn't think about automation users.

To even register AssistiveControl.app in Full Disk Access, Sal had to type a `cd` command in Terminal to navigate to `/System/Library/Input Methods/` and drag the app from there. Most users can't do this. Apple hid the capability behind a UI cliff (lines 204-208).

## Panel portability — XML bundle export

> *"You can save them and put them on other computers because you can export your panel as an XML file bundle there's a control there for saving off your panel and then you can open it up on another machine."* (lines 467-470)

**Panels are XML bundles.** Portable, version-controllable, shareable. **This is the missing distribution model for Loupedeck-style configs** — Loupedeck's own profile format isn't open; Stream Deck's is proprietary; Apple's panel export is XML.

## Sal's apology for incomplete work

> *"I've just figured this out a couple of weeks ago and although I want to sit down and write 500 controls I haven't had the time."* (lines 388-389)

Sal anticipates a 500-command panel. The audience is seeing the prototype.

## Sal's PC vs Mac throwback — the security parody

Sal plays the 2007-era "I'm a Mac / I'm a PC" Vista cancel-or-allow ad on screen (lines 179-193) to satirize macOS's evolution into Vista-tier permission-prompting hell:

> *"Enough said so while I appreciate the need for security in a modern world you know I'm still the same guy sitting in my den working on my computer who are you protecting me from by making me jump through incredible amount of hoops?"* (lines 194-196)

**Sal explicitly using a 12-year-old Apple ad against Apple in 2019.** WWSD #2 (local-over-cloud) gets a security-doctrine sub-principle: *protect the user from external threats, not from themselves*.

## Verbatim Sal-voice signatures

- *"I don't think Apple knows that it's possible"* (line 16) — the talk's signature line
- *"I'm an automation researcher, so I look at security differently"* (line 177)
- *"Hello, I'm a Mac. Mac has issued a salutation, cancel or allow?"* (line 179)
- *"It's important for researchers to share. Right, Ed?"* (lines 228-230) — shouts out Ed (Wilco, fellow MTC presenter)
- *"How long would that take you to do by hand? Isn't that a nice thing to have at a button?"* (lines 438-439)
- *"Thank you for letting me be part of your experience here and part of your life"* (line 477) — closing line. Echoes the 2015 #306 valedictory *"thank you so much for being part of this experience for me"* — same emotional register.

## WWSD-relevant takeaways

- **WWSD #1 (democratization)** restated in 2019 as still-not-won inside Apple.
- **WWSD #2 (local-over-cloud)** extended to anti-permission-prompt-fatigue stance.
- **WWSD #35 (GUI scripting last resort)** generalizes: when Apple's UI doesn't expose the right control, the user falls off a cliff.
- **WWSD #36 (cleaning and waxing) + #43 (one verb per action) + WWDC 2013 #416 (AppleScript Libraries)** converge in the library-per-app + button-calls-library pattern.
- **WWSD #38 (droplet-with-prefs) extended:** panels-as-XML-bundles are the 2019 distribution model. Drag a bundle, install a control panel. Like droplets but for touch surfaces.

## CANDIDATE WWSD #46 — Surface what Apple shipped but hid

**Source quote (verbatim, line 16):** *"I don't think Apple knows that it's possible."*

**Rationale:** Sal's research model is to dig into `/System/Library/`, find capabilities the shipping team forgot or never marketed, and weaponize them in user-author tooling. The Panel Editor + Luna pattern is one instance; the dictation-commands library is another; the Keynote `sdef` deeper-than-documented verbs are a third. The Mac contains more automation capability than even Apple knows.

**How to apply:** When a user-facing UI seems weak, probe `/System/Library/`, `/usr/libexec/`, and the per-app `Contents/Resources/` for shipped-but-hidden tools. Apple's marketing surface ≠ Apple's actual ship surface.

## CANDIDATE WWSD #47 — Same set, same location, every panel

**Source quote (verbatim, lines 241-243):** *"Each panel has the same set in the same location so that I can sit there and I instantly have muscle memory on how to get between the different apps."*

**Rationale:** When designing per-context control surfaces (panels, Loupedeck pages, Stream Deck profiles, Vocal Shortcut grids), the chrome should be **invariant across contexts**. Context-specific verbs fill the center; navigation + system + app-switcher always-the-same edges. Muscle memory transfers; cognitive load doesn't.

**How to apply:** Audit any multi-page Loupedeck/Stream Deck config or Hey Sal grid against this rule. Are app-switchers in the same row everywhere? Are system controls in the same row everywhere? If not, every context-switch costs muscle-memory load.

## CANDIDATE WWSD #48 — The compound verb (Magic Duplicate)

**Source quote (verbatim, lines 277-279):** *"A magic duplicate takes a slide, duplicates it, and applies a magic move to the first one so that you can animation by just tapping magic duplicate and changing the shape of the items on the second slide."*

**Rationale:** Atomic verbs are good (#43), but for repeated multi-step workflows the right design is the **compound verb** — one user-facing button that performs N atomic actions deterministically. Sal's Magic Duplicate compresses duplicate+transition-apply into one tap. WWSD #43 says "decompose composite UIs"; #48 says "compose deterministic workflows into single verbs". Both rules; not contradictory.

**How to apply:** When you find yourself doing the same 2-4 action sequence repeatedly, that's a candidate compound verb. Bake the sequence into one Loupedeck button / one Hey Sal verb / one Panel button. The user composes by re-using; you compose by automating.

## Reusable for the apple repo

- **`bin/install-assistive-panels.py`** — install user-authored Panel Editor XML bundles into `~/Library/Application Support/com.apple.AssistiveControl/`. Document the magic folder + the security-gating dance (Full Disk Access for AssistiveControl.app via Terminal-dragged registration).
- **Per-app AppleScript library template generator.** `bin/library-gen.py --for keynote` scaffolds a `~/Library/Script Libraries/keynote-library.scptd` with named verbs + an `.sdef` (per WWDC 2013 #416 walk-through) ready to be called from Panel buttons.
- **Loupedeck profile porter.** Sal's XML panel bundles are 1:1 translatable to Loupedeck profile JSON. Worth a `bin/panel-to-loupedeck.py` converter — port Sal's keynote panel layout to the user's Loupedeck Live.
- **Magic Duplicate as a Hey Sal verb.** *"Hey Sal, magic duplicate"* → Keynote AppleScript handler: get front slide → duplicate → set transition of original to Magic Move → wait 50ms → save state. Add to `applets/hey-sal.scpt` matcher table.
- **The "no plus button" wall as a `painpoints/` entry.** Apple's permission system doesn't accommodate apps installed outside `/Applications/`. `painpoints/SECURITY-001.md` candidate.
- **Sal's Panel Editor video** referenced in the talk (line 473 — *"I post a video about how to set it up"*) — search Sal's YouTube + macosxautomation.com for the demo recording.

## Audit footer — verbatim quote verification

All quotes verified by direct character match against transcript.txt:

| Quote excerpt | Line(s) | Verdict |
|---|---|---|
| *"I don't think Apple knows that it's possible"* | 16 | ✓ exact |
| *"I had this thing that nobody's seen..."* | 14-15 | ✓ exact |
| *"I'm fascinated by all things automation..."* | 19-22 | ✓ exact |
| *"You can create your own custom assistive keyboards but they don't have to be keyboards in the normal sense"* | 37-39 | ✓ exact |
| *"The sidecar, you can use a pen, but you can't use your finger"* | 62 | ✓ exact |
| *"You can create an AppleScript library"* + 1000 functions claim | 159-163 | ✓ exact |
| *"tell script the name of the library keynote dash library"* | 169-170 | ✓ exact |
| *"Each panel has the same set in the same location... muscle memory"* | 241-243 | ✓ exact |
| *"A magic duplicate takes a slide, duplicates it, and applies a magic move"* | 277-279 | ✓ exact |
| *"You set up all the security to allow that app... no plus buttons"* | 206-215 | ✓ exact |
| *"You can export your panel as an XML file bundle"* | 467-470 | ✓ exact |
| *"I'm a Mac. Mac has issued a salutation, cancel or allow?"* | 179 | ✓ exact (Sal playing recorded Apple ad) |
| *"I'm still the same guy sitting in my den working on my computer"* | 195-196 | ✓ exact |
| *"Thank you for letting me be part of your experience here and part of your life"* | 477 | ✓ exact |
| *"I'm an automation researcher"* | 12 + 177 | ✓ exact |
| *"I've just figured this out a couple of weeks ago and although I want to sit down and write 500 controls I haven't had the time"* | 388-389 | ✓ exact |

**No paraphrasing in quote marks. All quotes from direct read of transcript.txt.**

## Whisper proper-noun confidence flags

- *"Sal Seguin"* (line 8) — Whisper mishearing of **Sal Soghoian**. Neil Ticktin (MTC host) introduces him. Wright/Ticktin is the actual host; Whisper labels him as Neil.
- *"saul"* / *"Saul"* (line 1) — Steve Jobs nickname, correct rendering preserved (Sal himself uses this spelling).
- *"Pope's summer palace in Arleigh"* (line 442) — Avignon (city in France, *Palais des Papes*). Whisper rendered "Arleigh" — likely *"in Arles"*. Cosmetic only.
- *"Pontegarde"* (line 433) — actually **Pont du Gard**, Roman aqueduct near Nîmes. Whisper-corrupted but recognizable.
- *"Wilco"* (line 230) — likely *"Ed Wilcox"* or another Ed; Sal addresses an "Ed" who presented earlier at MTC.
- *"Neal"* / *"Neil"* — host name (Neil Ticktin); both spellings appear (line 9 "Neil", line 478 "Neal").
- *"Apple Foundation Models Framework"* — not mentioned in this 2019 transcript; the AFM-via-Omni-Automation reference is from the 2025 podcast #815, not here.
