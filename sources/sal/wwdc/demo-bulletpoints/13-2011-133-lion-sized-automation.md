# WWDC 2011 #133 — Lion-Sized Automation

**Speakers:** Sal Soghoian + Chris Page · **48:22** · Track: App Frameworks (OS X)
**nonstrict:** https://nonstrict.eu/wwdcindex/wwdc2011/133/

## The pitch — four pillars now

This is the WWDC where Sal formally inducts **Terminal** into his canon. From now on: **AppleScript + Automator + Services + Terminal = the four-pillar automation model** that holds through 2014.

> *"Did I say shoved? Okay. We, you know, thought about it very clearly, made decisions and followed procedures and processes always. Always got management approval."*

Sal's signature lightly-subversive insider voice. He shipped more than the comms team wanted to announce, and he tells the audience.

## The headline — Cocoa AppleScript Applets (ASOC on the desktop)

Pre-Lion: AppleScript-ObjC was Xcode-only. **In Lion: ASOC works in `.applescript` files opened in Script Editor.** No Xcode. No build step.

```applescript
property NSString : class "NSString"
set cocoaString to NSString's stringWithString:appleScriptText
set upper to cocoaString's uppercaseString
```

**Sal had been waiting 14 years for this feature.** *"Only took me 14 years. Your tax dollars at work."*

What it unlocks:
- AppleScript can call any Cocoa class/instance method
- Build custom UI (progress windows with cancel buttons, list pickers, error dialogs)
- Define new Cocoa classes inside the applet bundle as sister script files
- Threading — run code on a separate thread for non-blocking progress UI

The applet bundle gains a **script bundle** inner structure: `main.scpt` + auxiliary scripts in `Contents/Resources/` defining Cocoa classes. **Classes-as-script-objects** — the Smalltalk-shaped model AppleScript always wanted.

## The encoding actions (Apple-curated presets)

`Encode Selected Audio Files` + `Encode Selected Video Files` ship as contextual-menu services.

> *"We locked the QuickTime engineers in a room for 10 hours. We would not feed them, let them out, until they gave us the appropriate settings."*

**Apple-curated presets** baked into shipped actions. Consistency + accuracy operationalized.

## The website pop-up action (★ the prescient one)

A **microbrowser as an Automator action.** Input: any URL. Output: floating HUD window with the page, selectable user-agent (iPhone/iPad/Safari) and display size.

Wired into a service called *Look up in Wikipedia*: select "flounder" in Mail → right-click → HUD pops with Wikipedia → pick text → click OK → selection replaces.

**The great-great-grandfather of every modern "AI summary at the cursor" interaction.** In 2011. Built on WebKit. Already user-pluggable.

## AppleScript voice: `listen for`

```applescript
listen for {"Frank Sinatra", "Cole Porter", "Ella Fitzgerald"} ¬
    with prompt "Which artist?"
```

Returns whichever phrase the user said. **Voice as an AppleScript primitive, not a hosted service.** Offline. Local. No cloud. The 2011 ancestor of Vocal Shortcuts (2024). 13-year lineage unbroken.

Plus: 35 international voices, speaking rate/modulation commands, `Add to iTunes as Spoken Track` service for TTS-to-podcast.

## Script templates (New From Template menu)

`~/Library/Application Support/Script Editor/Templates/` — Lion ships:
- **Aperture import action**
- **Recursive file-processing droplet**
- **iChat responder** (*"all the computers were talking to each other and there was no humans involved"*)
- **Mail rule handler**

## Automator + Services housekeeping

- **Duplicate To** — convert any workflow type to any other (workflow → service → applet → folder action)
- **Double-click-to-install** — drop a `.action` or `.workflow`, double-click, system prompts to install
- **Versions support** — workflows ride Lion's Time Machine versioning

## Chris Page on Terminal (the new family member)

~35 changes. Highlights:
- **Working-directory tracking** via escape sequence → title-bar proxy icon → drag to Finder / other tab / other window. New tabs inherit CWD. **Drag a Finder folder onto Terminal → window CD'd there.**
- **Full-screen** (option-Cmd-F), 256-color, blur backgrounds, folder-of-images rotation, randomized solid colors per tab
- **Busy spinner per tab**, bell badges, live process name in Dock
- System services: `cd to Finder folder`, `Open man page for selection`

## Sal voice

> *"Now you are very dangerous people. You have AppleScript, Apple Events, you have the command line, and you have Cocoa. Dude, tear it up."*

## Power features delivered

- **Cocoa AppleScript Applets** — ASOC without Xcode (★ the killer)
- **`listen for`** — offline local voice primitive
- **Encoding actions with Apple-curated presets**
- **Microbrowser-as-action** with user-agent spoofing
- **Script Editor templates** — Aperture, recursive droplet, iChat, Mail
- **Workflow Duplicate-To** — convert types without rebuilding
- **Double-click install** for actions and services
- **Terminal as the fourth automation pillar**

## Marketing copy version

**Headline:** Lion finally lets AppleScript reach into the entire Cocoa runtime — without Xcode. Build apps with custom UI in Script Editor. Plus: voice triggers, microbrowsers-as-actions, Terminal in the family. The four-pillar automation model arrives.

**Audience takeaway:** if you're a longtime AppleScripter, this is the moment your scripts grow up. You can now build production-quality UI, call any framework, ship single-file Cocoa apps — without leaving Script Editor. The 14-year wait pays off.
