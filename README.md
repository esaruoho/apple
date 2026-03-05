# apple

### macOS automation arsenal by [Esa Ruoho](https://github.com/esaruoho) @ [Ray Browser](https://raybrowser.com). One button. One action. Zero wasted time.

[![macOS](https://img.shields.io/badge/macOS-Sequoia-000000?style=flat-square&logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![AppleScript](https://img.shields.io/badge/AppleScript-Automation-blue?style=flat-square)](https://developer.apple.com/library/archive/documentation/AppleScript/Conceptual/AppleScriptLangGuide/introduction/ASLR_intro.html)
[![Loupedeck Live](https://img.shields.io/badge/Loupedeck_Live-Optimized-orange?style=flat-square)](https://loupedeck.com/)
[![Built with Claude Code](https://img.shields.io/badge/Built_with-Claude_Code-blueviolet?style=flat-square)](https://claude.ai/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

---

## What is this?

A growing collection of **battle-tested AppleScripts** for macOS automation, built specifically for one-press execution from a **Loupedeck Live** hardware controller.

Every script in this repo is:
- **Fast** -- no unnecessary delays, no spinners, no waiting
- **Reliable** -- handles edge cases like apps not running
- **Single-purpose** -- one button, one job, done

This is how I work. I press a physical button on my Loupedeck Live and something happens *instantly*. No hunting through the Dock. No Cmd-Tab cycling. No friction.

If you've seen what I did with **[Paketti](https://github.com/esaruoho/paketti)** -- a 3,022-feature workflow suite for Renoise built in Lua -- you know I don't stop optimizing until every wasted second is gone. This repo is that same obsession applied to macOS itself.

## Script Catalog

### App Launchers (64 scripts)

Every Apple app and utility, ready for one-button activation from Loupedeck Live.

<details>
<summary><b>System Apps (40 scripts)</b></summary>

| App | File |
|-----|------|
| App Store | [`scripts/launchers/activate-app-store.applescript`](scripts/launchers/activate-app-store.applescript) |
| Automator | [`scripts/launchers/activate-automator.applescript`](scripts/launchers/activate-automator.applescript) |
| Books | [`scripts/launchers/activate-books.applescript`](scripts/launchers/activate-books.applescript) |
| Calculator | [`scripts/launchers/activate-calculator.applescript`](scripts/launchers/activate-calculator.applescript) |
| Calendar | [`scripts/launchers/activate-calendar.applescript`](scripts/launchers/activate-calendar.applescript) |
| Chess | [`scripts/launchers/activate-chess.applescript`](scripts/launchers/activate-chess.applescript) |
| Clock | [`scripts/launchers/activate-clock.applescript`](scripts/launchers/activate-clock.applescript) |
| Contacts | [`scripts/launchers/activate-contacts.applescript`](scripts/launchers/activate-contacts.applescript) |
| Dictionary | [`scripts/launchers/activate-dictionary.applescript`](scripts/launchers/activate-dictionary.applescript) |
| FaceTime | [`scripts/launchers/activate-facetime.applescript`](scripts/launchers/activate-facetime.applescript) |
| Find My | [`scripts/launchers/activate-find-my.applescript`](scripts/launchers/activate-find-my.applescript) |
| Font Book | [`scripts/launchers/activate-font-book.applescript`](scripts/launchers/activate-font-book.applescript) |
| Freeform | [`scripts/launchers/activate-freeform.applescript`](scripts/launchers/activate-freeform.applescript) |
| Home | [`scripts/launchers/activate-home.applescript`](scripts/launchers/activate-home.applescript) |
| Image Capture | [`scripts/launchers/activate-image-capture.applescript`](scripts/launchers/activate-image-capture.applescript) |
| Launchpad | [`scripts/launchers/activate-launchpad.applescript`](scripts/launchers/activate-launchpad.applescript) |
| Mail | [`scripts/launchers/activate-mail.applescript`](scripts/launchers/activate-mail.applescript) |
| Maps | [`scripts/launchers/activate-maps.applescript`](scripts/launchers/activate-maps.applescript) |
| Messages | [`scripts/launchers/activate-messages.applescript`](scripts/launchers/activate-messages.applescript) |
| Mission Control | [`scripts/launchers/activate-mission-control.applescript`](scripts/launchers/activate-mission-control.applescript) |
| Music | [`scripts/launchers/activate-music.applescript`](scripts/launchers/activate-music.applescript) |
| News | [`scripts/launchers/activate-news.applescript`](scripts/launchers/activate-news.applescript) |
| Notes | [`scripts/launchers/activate-notes.applescript`](scripts/launchers/activate-notes.applescript) |
| Passwords | [`scripts/launchers/activate-passwords.applescript`](scripts/launchers/activate-passwords.applescript) |
| Photo Booth | [`scripts/launchers/activate-photo-booth.applescript`](scripts/launchers/activate-photo-booth.applescript) |
| Photos | [`scripts/launchers/activate-photos.applescript`](scripts/launchers/activate-photos.applescript) |
| Podcasts | [`scripts/launchers/activate-podcasts.applescript`](scripts/launchers/activate-podcasts.applescript) |
| Preview | [`scripts/launchers/activate-preview.applescript`](scripts/launchers/activate-preview.applescript) |
| QuickTime Player | [`scripts/launchers/activate-quicktime-player.applescript`](scripts/launchers/activate-quicktime-player.applescript) |
| Reminders | [`scripts/launchers/activate-reminders.applescript`](scripts/launchers/activate-reminders.applescript) |
| Shortcuts | [`scripts/launchers/activate-shortcuts.applescript`](scripts/launchers/activate-shortcuts.applescript) |
| Stickies | [`scripts/launchers/activate-stickies.applescript`](scripts/launchers/activate-stickies.applescript) |
| Stocks | [`scripts/launchers/activate-stocks.applescript`](scripts/launchers/activate-stocks.applescript) |
| System Settings | [`scripts/launchers/activate-system-settings.applescript`](scripts/launchers/activate-system-settings.applescript) |
| TextEdit | [`scripts/launchers/activate-textedit.applescript`](scripts/launchers/activate-textedit.applescript) |
| Time Machine | [`scripts/launchers/activate-time-machine.applescript`](scripts/launchers/activate-time-machine.applescript) |
| Tips | [`scripts/launchers/activate-tips.applescript`](scripts/launchers/activate-tips.applescript) |
| TV | [`scripts/launchers/activate-tv.applescript`](scripts/launchers/activate-tv.applescript) |
| Voice Memos | [`scripts/launchers/activate-voice-memos.applescript`](scripts/launchers/activate-voice-memos.applescript) |
| Weather | [`scripts/launchers/activate-weather.applescript`](scripts/launchers/activate-weather.applescript) |

</details>

<details>
<summary><b>Utilities (16 scripts)</b></summary>

| App | File |
|-----|------|
| Activity Monitor | [`scripts/launchers/activate-activity-monitor.applescript`](scripts/launchers/activate-activity-monitor.applescript) |
| AirPort Utility | [`scripts/launchers/activate-airport-utility.applescript`](scripts/launchers/activate-airport-utility.applescript) |
| Audio MIDI Setup | [`scripts/launchers/activate-audio-midi-setup.applescript`](scripts/launchers/activate-audio-midi-setup.applescript) |
| Bluetooth File Exchange | [`scripts/launchers/activate-bluetooth-file-exchange.applescript`](scripts/launchers/activate-bluetooth-file-exchange.applescript) |
| ColorSync Utility | [`scripts/launchers/activate-colorsync-utility.applescript`](scripts/launchers/activate-colorsync-utility.applescript) |
| Console | [`scripts/launchers/activate-console.applescript`](scripts/launchers/activate-console.applescript) |
| Digital Color Meter | [`scripts/launchers/activate-digital-color-meter.applescript`](scripts/launchers/activate-digital-color-meter.applescript) |
| Disk Utility | [`scripts/launchers/activate-disk-utility.applescript`](scripts/launchers/activate-disk-utility.applescript) |
| Grapher | [`scripts/launchers/activate-grapher.applescript`](scripts/launchers/activate-grapher.applescript) |
| Migration Assistant | [`scripts/launchers/activate-migration-assistant.applescript`](scripts/launchers/activate-migration-assistant.applescript) |
| Screen Sharing | [`scripts/launchers/activate-screen-sharing.applescript`](scripts/launchers/activate-screen-sharing.applescript) |
| Screenshot | [`scripts/launchers/activate-screenshot.applescript`](scripts/launchers/activate-screenshot.applescript) |
| Script Editor | [`scripts/launchers/activate-script-editor.applescript`](scripts/launchers/activate-script-editor.applescript) |
| System Information | [`scripts/launchers/activate-system-information.applescript`](scripts/launchers/activate-system-information.applescript) |
| Terminal | [`scripts/launchers/activate-terminal.applescript`](scripts/launchers/activate-terminal.applescript) |
| VoiceOver Utility | [`scripts/launchers/activate-voiceover-utility.applescript`](scripts/launchers/activate-voiceover-utility.applescript) |

</details>

<details>
<summary><b>Apple Pro Apps + Core (8 scripts)</b></summary>

| App | File |
|-----|------|
| Finder | [`scripts/launchers/activate-finder.applescript`](scripts/launchers/activate-finder.applescript) |
| Safari | [`scripts/launchers/activate-safari.applescript`](scripts/launchers/activate-safari.applescript) |
| Keynote | [`scripts/launchers/activate-keynote.applescript`](scripts/launchers/activate-keynote.applescript) |
| Numbers | [`scripts/launchers/activate-numbers.applescript`](scripts/launchers/activate-numbers.applescript) |
| Pages | [`scripts/launchers/activate-pages.applescript`](scripts/launchers/activate-pages.applescript) |
| Final Cut Pro | [`scripts/launchers/activate-final-cut-pro.applescript`](scripts/launchers/activate-final-cut-pro.applescript) |
| Logic Pro | [`scripts/launchers/activate-logic-pro.applescript`](scripts/launchers/activate-logic-pro.applescript) |
| iMovie | [`scripts/launchers/activate-imovie.applescript`](scripts/launchers/activate-imovie.applescript) |

</details>

### App Automation Probe (13 Layers)

`bin/app-probe.py` extracts **13 layers of automation intelligence** from every Apple app:

| Layer | What It Reveals |
|-------|-----------------|
| 1. Scripting Dictionary (sdef) | AppleScript commands, classes, properties |
| 2. URL Schemes | URLs the app responds to (`mailto://`, `music://`) |
| 3. Document Types | File types the app can open |
| 4. **App Intents / Siri Phrases** | Shortcuts actions + Siri voice commands |
| 5. NSServices | Services menu entries |
| 6. User Activity Types | Handoff/Spotlight activities |
| 7. Entitlements | What the app is *allowed* to do |
| 8. Linked Frameworks | Which Apple frameworks the app uses |
| 9. Spotlight Metadata | Bundle ID, version, category |
| 10. LaunchServices | LS database registration (opt-in) |
| 11. Plugin Extensions | `.appex` plugins inside the app |
| 12. Notification Actions | Actionable notification buttons |
| 13. CLI Tools | macOS command-line automation tools |

```bash
python3 bin/app-probe.py                    # All 66 apps, all layers
python3 bin/app-probe.py Mail               # Single app
python3 bin/app-probe.py --layer intents    # Only App Intents
python3 bin/app-probe.py --cli              # Include CLI tools
python3 bin/app-probe.py --list             # Show available apps
```

**66 apps probed, 378 layer hits, 20 apps with App Intents, 35 with URL schemes.**

Output per app: `dictionaries/<app>/<app>-probe.yaml` + `<app>-probe.md`
Cross-app index: `dictionaries/_probe-index.yaml` (URL scheme registry, App Intents summary, framework matrix)

### Workflow Scripts

| Script | What it does | File |
|--------|-------------|------|
| **Activate Finder** | Brings Finder to the foreground | [`scripts/activate-finder.applescript`](scripts/activate-finder.applescript) |

*More workflow scripts incoming. The launchers are the foundation -- the workflow scripts build on top.*

## How to Use

### Quick start

```bash
# Clone the repo
git clone https://github.com/esaruoho/apple.git
cd apple

# Run any script
osascript scripts/activate-finder.applescript
```

That's it. No dependencies. No build step. No package manager. Just `osascript` and the script path.

### Loupedeck Live setup

1. Open the **Loupedeck** software
2. Drag a **Custom Action** (or **Run Command**) onto a button
3. Set the command to:
   ```
   osascript /path/to/apple/scripts/activate-finder.applescript
   ```
4. Press the button. The action fires immediately.

Each script is designed to execute in a fraction of a second -- exactly what you need from a hardware controller button.

### Inline usage

You can also run AppleScripts inline without files:

```bash
osascript -e 'tell application "Finder" to activate'
```

The scripts in this repo are standalone files because Loupedeck Live works best with file paths, and because files are easier to version, share, and iterate on.

## About the Author

**Esa Ruoho** (Lackluster) -- user automation expert, software developer, author, tester, musician, and user experience evaluator.

I've been making electronic music since 1997, with 30+ album releases and 203 live gigs across 20 countries. I come from the **demoscene** (Distance) where you learn to squeeze maximum output from minimal resources. That mindset never left. I develop my own music automation tools and port workflow optimizations across applications.

By day, I work at **Ray Browser** as a workflow/UX specialist and software tester. By night (and every other waking hour), I build tools that eliminate friction. I believe user automation is a fundamental right -- not a luxury feature.

My biggest open-source project is **[Paketti](https://github.com/esaruoho/paketti)** -- a massive quality-of-life workflow suite for Renoise with 3,022 features, all written in Lua. It started because I got tired of clicking through menus. This repo exists for the same reason, just aimed at macOS itself.

### Philosophy

Inspired by **Sal Soghoian** -- Apple's Product Manager of Automation Technologies (1997-2016), co-inventor of Automator (US Patent 7,428,535), and champion of the idea that *"the power of the computer should reside in the hands of the one using it."*

This repo is built with the help of **Claude Code** and its custom Apple skill -- an AI-assisted workflow where I describe what I need and the scripts get written, tested, and cataloged automatically.

## Links

- **Paketti** (3,022-feature Renoise workflow suite): [github.com/esaruoho/paketti](https://github.com/esaruoho/paketti)
- **Paketti Manual**: [esaruoho.github.io/paketti](https://esaruoho.github.io/paketti)
- **Patreon** (support the work): [patreon.com/esaruoho](http://patreon.com/esaruoho)

---

*One button. One action. No wasted time.*
