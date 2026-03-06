# NOTES-001: Recording Audio Should Be One Action

**App:** Notes.app
**Intent:** Record a voice memo immediately — an idea strikes, capture it NOW
**Severity:** UX friction — defeats the purpose of voice recording
**Status:** Open
**Filed:** 2026-03-06

---

## The Click Count

| Step | Action | Recording? |
|------|--------|:----------:|
| 1 | Open Notes.app | No |
| 2 | Create a New Note | No |
| 3 | Click "Record Audio" in the topbar | No |
| 4 | Watch the sidebar open with "New Recording" | No |
| 5 | Press the big red button | **Yes, finally** |
| 6 | Navigate to "Done" and click it | Stopped |

**5 clicks to start recording. 6 to finish.**

The idea you wanted to capture? Half-gone by click 3.

---

## What Sal Would Say

> "The power of the computer should reside in the hands of the one using it."

This is the opposite. The computer is in charge. It decides when you're ready. It makes you navigate a sidebar. It makes you find a red button. It makes you confirm you meant what you already said you meant.

Sal's Principle #2: **Solve a real problem.** The real problem is: "I have an idea and I need to record it before it disappears." The solution is one action. Not a wizard. Not a sidebar. Not a confirmation step.

Sal's Principle #7: **Think in workflows.** The workflow here is: intent → capture. Two nodes. Apple inserted four nodes in between.

---

## What It Should Be

**1 action → recording.**

Any of these would work:

```bash
# Shortcut triggered from keyboard, Loupedeck, menu bar, Siri
shortcuts run "Record Voice Memo"

# AppleScript (if Notes exposed it)
tell application "Notes"
    set newNote to make new note in folder "Notes"
    start recording audio in newNote
end tell

# What Siri should do
"Hey Siri, record a note" → immediately recording, no UI, no clicks
```

The recording should start the moment you express the intent. Everything else — the note, the sidebar, the "Done" button — should happen automatically or afterward.

---

## The Automation Surface (from our probe)

Notes has **318 Siri phrases** and **50 Shortcuts actions** — it's the most intent-rich app on macOS. And yet "start recording audio in a note" is not one of them.

From `dictionaries/notes/notes-probe.yaml`: Notes has 2 AppleScript commands (`show`, `save`) and 4 classes (`account`, `folder`, `note`, `attachment`). No `recording` class. No `start recording` command. The scripting dictionary has no concept of audio.

Notes is Tier 1 in the Automation Atlas — "fully automatable." But the audio recording feature lives outside its automation surface entirely. It's a GUI-only feature with no scripting, no Intents, no URL scheme, no keyboard shortcut.

---

## Fix Paths

1. **Apple (ideal):** Add an App Intent: "Record Audio in Notes" — starts recording immediately into a new note. One action. Add a `recording` class to the scripting dictionary.
2. **Shortcuts (workaround):** Chain Voice Memos → Notes. Record in Voice Memos (which DOES have Intents for recording), then attach to a note. Two apps to do one app's job.
3. **System Events (hack):** UI-script the 5 clicks. Fragile, breaks on UI changes, but works today.
4. **Keyboard shortcut:** Apple could add a global hotkey for "Record Audio in Notes" — like Screenshot has Cmd+Shift+5.

---

---

*Part of the [Apple Automation Atlas](../README.md). Tagged for the attention of anyone at Apple who still believes the power of the computer should reside in the hands of the one using it.*

**Filed by [@esaruoho](https://github.com/esaruoho)** — software tester, UI enthusiast, amateur scripter, automation/workflow obsessive, and user experience evaluator. Reporting the missing bits and pieces one at a time.
