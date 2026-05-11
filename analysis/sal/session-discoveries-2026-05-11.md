---
title: Hey Sal × Paketti — session discoveries
date: 2026-05-11
status: Captured. Adds to (does not replace) hey-sal-paketti-stack-state.md.
purpose: Save the five findings that were ephemeral — facts learned during the live build that aren't in the code or the handoff narrative. Future sessions can read this without re-walking the debugging path.
---

# What this file is

The `hey-sal-paketti-stack-state.md` handoff captures *what was built*. This file captures *what I learned while building it* — facts about Apple's behaviour, decision records, and gotchas that would otherwise be lost when the chat that produced them ends.

Five items. Short.

---

## 1. AppleScript-keystroke path won. MCP path is parked.

Both paths got built today. The decision wasn't theoretical — both were tried.

**MCP path** (`PakettiMCP/tools/paketti.lua` + `pmcp` CLI):
- Pros: typed JSON, structured returns, queries state two-way, no key-chord mapping needed
- Cons: requires the MCP server to be running inside Renoise. Server has to be started manually (Tools → Paketti → !Preferences → MCP Server Start) every Renoise session. If it's down, the verb fails.

**AppleScript path** (`bin/renoise/<verb>` wrappers + `_send`):
- Pros: works as long as Renoise is open. No daemon, no port, no manual start. Faithful to the chord the user already bound — same as pressing the key by hand.
- Cons: limited to verbs that have a key chord assigned. Can't query state (output-only). Each verb maps to exactly one chord.

**Decision:** AppleScript path is the daily driver for *firing* verbs. MCP stays available for *reading* state (e.g. "what's the current BPM?"). The two cover different jobs — they aren't competitors.

**What this means for next time:** if someone asks "can voice ask Renoise a question?", the answer is MCP. If "can voice make Renoise do something?", AppleScript. Don't relitigate.

---

## 2. `osacompile`-made apps have no bundle identifier

The Hey Sal.app at `~/Applications/Hey Sal.app` was compiled with `osacompile`. Its `Info.plist` has **no `CFBundleIdentifier`** key.

Two consequences:

1. **TCC lists it by display name "Hey Sal"**, not by reverse-DNS bundle ID. So in System Settings → Privacy & Security → Accessibility (and Automation), the entry appears as just `Hey Sal`. No `com.esaruoho.hey-sal` to look for.
2. **`tccutil reset Accessibility <bundle-id>` cannot target it.** Reset only works on bundle IDs. The only way to reset this app's grants is to remove it from the list manually in System Settings.

**If we ever need to script TCC for this app**, the fix is to add `CFBundleIdentifier` to the Info.plist after `osacompile` runs:

```bash
osacompile -o "$HOME/Applications/Hey Sal.app" hey-sal-type.applescript
plutil -insert CFBundleIdentifier -string "com.esaruoho.heysal" "$HOME/Applications/Hey Sal.app/Contents/Info.plist"
```

Doing that now would invalidate the existing TCC grants (macOS treats it as a different app), so we left it alone. Future sessions: do it from day one if scriptable TCC matters.

---

## 3. Voice still routes through `sal-siri-match.py`, not `hey-sal`

The Vocal Shortcut "Hey Sal" → Shortcut "Hey Sal" → Run Shell Script → `sal-siri-match.py` (the 588-intent Sal matcher).

`sal-siri-match.py` **does not know about Paketti**. Only `bin/hey-sal` knows the 343 Paketti verbs.

So today:
- **Typed path** ("Hey Sal" .app via Spotlight, or `bin/hey-sal` direct) → knows Paketti ✓
- **Voice path** (saying "Hey Sal" via Vocal Shortcut) → only knows Sal's original 588 intents, returns "I did not understand" for Paketti verbs ✗

**Two fixes possible:**

A. **Patch `sal-siri-match.py` to fall through to `hey-sal`** when no Sal intent matches. About 10 lines at the end of `sal-siri-match.py`'s `main()`. Cleanest because it preserves the voice Shortcut's existing routing.

B. **Rebuild the voice Shortcut** (`build-hey-sal-shortcut.py`) to route through `hey-sal` instead of `sal-siri-match.py`. Then `hey-sal` is the single router; `sal-siri-match` becomes a library it can call. Architecturally cleaner.

**Recommendation:** A first (5 minutes, no Shortcut rebuild, no re-import). B if we ever do a bigger router refactor.

---

## 4. Empty `input:` in HeySal.log means dictation captured nothing

Hard-won diagnostic pattern. Worth knowing.

`~/Library/Logs/HeySal.log` lines look like:

```
--- Sunday 10. May 2026 at 20.12.55 ---
input:
```

When you see `input:` followed by blank, it means:

1. The Vocal Shortcut fired (otherwise no log entry at all)
2. The Shortcut started (otherwise the AppleScript router wouldn't have logged)
3. The **Dictate Text** action ran but captured no speech

Three causes, ordered by likelihood:

| Cause | How to confirm |
|---|---|
| User said the trigger phrase, but didn't speak after the dictation popup | If a dictation listener visibly appeared on screen |
| Microphone permission for the Shortcuts daemon got revoked | System Settings → Privacy & Security → Microphone → check Shortcuts |
| `Dictate Text` action timed out (Stop Listening = "After Short Pause" is jumpy) | Try editing the Shortcut → set Stop Listening to "On Tap" so dictation only ends when you press a button |

**If we see this pattern persist**, the fix is to swap the Shortcut's Dictate Text action for "Speak" with longer timeout, OR add an "Ask for Input" fallback when dictation returns empty.

---

## 5. The debug trail (so future me doesn't re-walk it)

When the user said *"Hey Sal does nothing"* today, the wrong-first-guesses I made and the right path that worked:

| Step | What I tried | Outcome |
|---|---|---|
| 1 | Checked legacy CitrusPeel plist: `~/Library/Application Support/com.apple.speech.SpeechRecognitionCore/CustomCommands.plist` | Doesn't exist. Concluded (wrongly) "no Vocal Shortcut registered." |
| 2 | User screenshot proved Vocal Shortcut IS registered | I was wrong. Apologised. |
| 3 | Found `analysis/sal/vocal-shortcuts-storage-format.md` in the existing skill — documents the *actual* storage at `~/Library/Preferences/com.apple.Accessibility.plist` → `AVSPreferenceKey` | The skill already knew. I should have read it first. |
| 4 | Ran `bin/list-vocal-shortcuts.py` | Confirmed "Hey Sal" → Shortcut UUID `A2496D32-...` registered. |
| 5 | Read HeySal.log | Saw recent fires succeed (Sal demo) but most recent entry had empty `input:` — i.e. listener works, dictation step is where it sometimes fails. |
| 6 | Built typed entry path (`Hey Sal.app` via Spotlight) to bypass dictation failure mode entirely | Worked end-to-end. |
| 7 | User typed "groovebox" → got "I don't know how to do that yet" | `hey-sal` regex required "paketti" prefix. Wrong. |
| 8 | Added bare-verb fallback to `hey-sal classify()` | "groovebox" alone now dispatches. Verified. |
| 9 | User typed "groovebox" again → got `osascript is not allowed to send keystrokes (1002)` | Accessibility permission missing on `Hey Sal.app`. User added it. |
| 10 | Fired again → ERROR: Renoise is not running. Started Renoise. Verb fired. | Chain proven end-to-end. |

**The pattern:** when the user says something doesn't work, the failure is usually **one specific layer down**, not the whole chain. Each error message names that layer. Read the error. Don't theorise.

**The skill-docs lesson:** before guessing about Apple internals, grep `~/.claude/skills/apple/analysis/` and `~/work/apple/analysis/`. The user's own prior research lives there. If the skill has a doc named after the thing I'm guessing about, read it.

---

## Cross-references

- Stack state and three trigger surfaces: `hey-sal-paketti-stack-state.md` (this folder)
- Vocal Shortcuts storage: `vocal-shortcuts-storage-format.md` (this folder)
- Sequoia dictation runtime removal: `macos-sequoia-dictation-runtime-removal.md` (this folder)
- Bootstrap that installs the stack: `~/work/apple/bin/bootstrap-hey-sal.sh`
- Communication rules for future sessions: `~/.claude/projects/<paketti-project>/memory/feedback_no_jargon_no_deflection.md`
