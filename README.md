# apple

### macOS automation arsenal. One button. One action. Zero wasted time.

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

| Script | What it does | File |
|--------|-------------|------|
| **Activate Finder** | Brings Finder to the foreground instantly | [`scripts/activate-finder.applescript`](scripts/activate-finder.applescript) |

*More scripts incoming. This repo grows every time I automate another action.*

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

**Esa Ruoho** (Lackluster) -- electronic musician, workflow optimizer, Apple aficionado.

I've been making electronic music since 1997, with 30+ album releases and 203 live gigs across 20 countries. I come from the **demoscene** (Distance) where you learn to squeeze maximum output from minimal resources. That mindset never left.

By day, I work at **Ray Browser** as a workflow/UX specialist and software tester. By night (and every other waking hour), I build tools that eliminate friction.

My biggest open-source project is **[Paketti](https://github.com/esaruoho/paketti)** -- a massive quality-of-life workflow suite for Renoise with 3,022 features, all written in Lua. It started because I got tired of clicking through menus. This repo exists for the same reason, just aimed at macOS instead of a DAW.

This repo is built with the help of **Claude Code** and its custom Apple skill -- an AI-assisted workflow where I describe what I need and the scripts get written, tested, and cataloged automatically.

## Links

- **Paketti** (3,022-feature Renoise workflow suite): [github.com/esaruoho/paketti](https://github.com/esaruoho/paketti)
- **Paketti Manual**: [esaruoho.github.io/paketti](https://esaruoho.github.io/paketti)
- **Patreon** (support the work): [patreon.com/esaruoho](http://patreon.com/esaruoho)

---

*One button. One action. No wasted time.*
