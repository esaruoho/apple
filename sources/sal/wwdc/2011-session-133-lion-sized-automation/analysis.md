# WWDC 2011 Session 133 — Lion-Sized Automation (Analysis)

**Speakers:** Sal Soghoian (overview + AppleScript + Automator + Services) + Chris Page ("the Terminator Page" — Terminal lead, AppleScript team)
**Year:** 2011 (Mac OS X 10.7 Lion)
**Source:** https://nonstrict.eu/wwdcindex/wwdc2011/133/

## The historical position

The **Lion launch automation overview** with two structural shifts:

1. **AppleScript-ObjC moves to the desktop.** In Snow Leopard, ASOC was Xcode-only. In Lion, ASOC arrives in plain `.applescript` applets opened in Script Editor — no Xcode required.
2. **Terminal joins the automation family.** Formerly outside the AppleScript/Automator/Services trinity, in Lion it becomes **the fourth pillar of automation on macOS**. Chris Page does the demo half.

The structure: AppleScript + Automator + Services + Terminal = the **four-pillar model** that holds through 2014. **This is the WWDC where Sal formally inducts the command line into his canon.**

## Sal's framing — the "shoved into the OS" opener

> *"We made sure that you had the ability to convert from one type of workflow into another… Did I say shoved? Okay. We, you know, thought about it very clearly, made decisions and followed procedures and processes always. Always got management approval."*

Sal's signature lightly-subversive insider voice — he speaks AS the automation community, not as the marketing layer.

## What Sal + Chris cover (the substance)

### 1. Automator + Services housekeeping
- **Duplicate To** — convert any workflow type to another (workflow → service → applet → folder action)
- **Double-click-to-install** — drop a `.action` or `.workflow`, double-click, system prompts to install
- **Versions support** — workflows ride Lion's Time Machine-style versions

### 2. The encoding actions

> *"You stand on one leg and hop like a chicken. It's a nightmare."*

Pre-Lion: how do I encode this file? Open QuickTime, no take it to iTunes, no use iMovie. Lion ships **`Encode Selected Audio Files`** and **`Encode Selected Video Files`** as contextual-menu services. **Apple-curated presets** — *"we locked the QuickTime engineers in a room for 10 hours. We would not feed them, let them out, until they gave us the appropriate settings."*

### 3. The website pop-up action — a HUD-shaped browser-as-action

Input: any URL. Output: floating HUD window with that page's content, selectable **user-agent (iPhone / iPad / Safari)** and display size. Wired into a service called *Look up in Wikipedia*: select "flounder" in Mail, right-click, HUD pops up with the Wikipedia page, pick text, click OK, selection replaces. **The great-great-grandfather of every modern "AI summary at the cursor" interaction.** In 2011. Built on WebKit. Already user-pluggable.

### 4. The EPUB Action — book-from-files

The 2010 Alice EPUB action is now first-class shipping. Select files in Finder → "Build EPUB Publication With Selected Files" → fill cover image + placement defaults → click Continue. EPUB lands on desktop, transfer to iPad. RTF formatting honored if input is RTF.

### 5. AppleScript voice + phrase matching (`listen for`)

- 35 international high-quality voices
- New `Add to iTunes as Spoken Track` service — TTS-to-podcast pipeline
- **`listen for` command** — script asks question, takes list of possible matching phrases, returns whichever the user said

Sal demos a Sinatra branching dialog: *"play some music. Which artist? Frank Sinatra. His early years or later years? Capitol recordings. Birth of the Blues."* **Voice as an AppleScript primitive, not a hosted service.** The 2011 ancestor of Vocal Shortcuts. **Offline. Local. No cloud round-trip.** WWSD #2 (local-over-cloud) embodied in a 2011 voice API.

### 6. Script templates (the New From Template menu)

`~/Library/Application Support/Script Editor/Templates/` — Lion ships:
- **Aperture import action** — runs when Aperture imports images
- **Recursive file-processing droplet** — solves the "process files in folder after folder" problem
- **iChat responder** — auto-conversation ("they got down to all the computers were talking to each other and there was no humans involved")
- **Mail rule** — fires on incoming-message conditions

### 7. The headline: Cocoa AppleScript Applets (ASOC on the desktop)

> *"In Snow Leopard, we introduced ASOC… But it was only in Xcode. Now it's moved to the desktop."*

The idiom:

```applescript
property NSString : class "NSString"
set cocoaString to NSString's stringWithString:appleScriptText
set upper to cocoaString's uppercaseString
```

**No Xcode. No project file. No build step.** A `.applescript` saved as an applet. From now on, AppleScripts can call any Cocoa class/instance method, sort lists via NSArray selectors, build custom UI (Sal demos a progress window with Stop button on its own thread, defined in a sister script inside the applet bundle).

Applet bundle gains a script-bundle inner structure: main script + auxiliary scripts in `Contents/Resources/` defining Cocoa classes. **Classes-as-script-objects** — the Smalltalk-shaped programming model AppleScript always wanted.

> *"Only took me 14 years. Your tax dollars at work."*

### 8. Chris Page on Terminal (the new family member)

> *"You're probably thinking to yourself right now, what kind of crazy stuff did they do to my terminal? Lots."*

~35 changes. Highlights:
- **Working-directory tracking** — Terminal knows shell's CWD via escape sequence, displays in title-bar proxy icon, drag to Finder / other tab / other window. New tabs inherit CWD. **Drag a Finder folder onto Terminal → new window CD'd there.**
- **Display** — full-screen Terminal (option-Cmd-F), 256-color, background-color-erase, blur backgrounds, folder-of-images rotation, randomized solid colors per tab
- **Status indicators** — busy spinner per tab, unread-text ellipsis, bell badges, live process name in Dock icon
- **System services** — `cd to Finder folder`, `Open man page for selection`

**Terminal is now an automation surface**, addressable from contextual menus and Finder drag-targets.

## Verbatim Sal-voice signatures

- *"I better watch what I say because this is going to be caught on video. So none of my normal acerbic wit will be used today."*
- *"Applause for the new guy. Yeah, yeah, make him feel the love."* (welcoming Terminal)
- *"Now you are very dangerous people. You have AppleScript, Apple Events, you have the command line, and you have Cocoa. Dude, tear it up."*
- *"Only took me 14 years."* (placing Cocoa AppleScript Applets on the 1997 timeline)

## WWSD-relevant takeaways

- **Four-pillar canon (AppleScript + Automator + Services + Terminal)** formally established. Load-bearing structure for probing future Apple OS versions.
- **WWSD #1 operationalized via templates.** New-From-Template menu = lower the floor, raise the ceiling.
- **WWSD #2 (local-over-cloud) confirmed by `listen for`.** Sal's 2011 voice API is offline, local, latency-free — the trigger surface Vocal Shortcuts reclaims in 2024. **2011 → 2024 lineage unbroken.**
- **WWSD #38 (droplet-with-preferences) generalized to templates.** Same shape at Script Editor's new-document layer.
- **Candidate WWSD #42 — Lower the cost of "I want my own UI".** Cocoa AppleScript Applets remove Xcode from the equation. Sal's 14-year wait for this feature is itself a biographical anchor.

## Reusable for the apple repo

- **`bin/listen-for-replacement.sh`** — Sal's 2011 `listen for` is already-shipping local voice-trigger infrastructure that predates Vocal Shortcuts by 13 years. Probe: does it still work on Sequoia 2026? Second offline-local-voice-trigger surface beside Vocal Shortcuts.
- **Cocoa AppleScript Applet template recovery** — Lion shipped a working `.applescript` template for Cocoa applets with the progress-window pattern. Still in `~/Library/Application Support/Script Editor/Templates/`? If retired, recover from Wayback / macosxautomation.com.
- **`bin/apple-website-popup-action`** — port the 2011 HUD as a 2026 service. WebKit alive, user-agent spoofing available via WKWebView. Wire to LLM endpoints, not just Wikipedia.
- **`bin/probe-encoding-defaults.py`** — extract the Apple-curated encoding presets likely still shipping inside `/System/Library/Automator/Encode Media.action/`.
- **Four-pillar audit doc** — `analysis/sal/four-pillar-canon-state-2026.md` grading each pillar 1-5 in Sequoia.
- **iChat responder template ↔ pakettibot lineage** — 2011 iChat auto-responder is the direct ancestor of pakettibot's cloudcity agent. Worth a paragraph in `CLAUDE.md` linking the lineage.
