# `xcrun agent skills export` — status & what we know (2026-07-03)

## What it is (from the source, NOT verified by running it)
Source: a Threads post by @eshumarneedi —
> "TIL Apple has some new agent skills for iOS/macOS app development. Run `xcrun agent skills export` with Xcode 27 installed. They're extremely thorough and well-conceived."

So: **Xcode 27** ships a new `agent` developer tool (invoked via `xcrun agent …`) whose `skills export` subcommand emits a catalogue of the "agent skills" — the structured, machine-readable capabilities Apple's on-device intelligence (FoundationModels-backed) exposes for app development/automation. That is the *claim*; the exact subcommands, flags, and output format are **not yet confirmed**.

## Verified status — NOT runnable on any machine we have
Checked 2026-07-03:
- **Laptop:** Xcode **26.3** → `xcrun --find agent` → *"unable to find utility 'agent'"*.
- **Mac Mini (cloudcity):** only **Command Line Tools** (`/Library/Developer/CommandLineTools`), no full Xcode → same error; `xcodebuild` unavailable.

`xcrun agent` is a **full-Xcode-27** tool. Neither machine has Xcode 27 (full), so the command **cannot be run yet** — and its real flags/output are therefore **unknown**. We deliberately did NOT invent them (anti-fabrication).

## How to actually get the real data (do this once Xcode 27 is installed)
1. Install the **Xcode 27 beta** (full Xcode.app, not Command Line Tools) and point the toolchain at it:
   `sudo xcode-select -s /Applications/Xcode-beta.app/Contents/Developer`
2. Discover the real interface (do NOT assume flags):
   ```
   xcrun --find agent
   xcrun agent --help
   xcrun agent skills --help
   xcrun agent skills export --help
   xcrun agent skills export        # the actual catalogue
   ```
3. Capture the output and replace the "what it is" section above with the CONFIRMED behaviour + flags.

## TODO
- [ ] Re-run the discovery block above once Xcode 27 (full) is on the laptop or Mini.
- [ ] If genuinely useful, add a convey/apple-skill wrapper that exports + parses the skill catalogue.
