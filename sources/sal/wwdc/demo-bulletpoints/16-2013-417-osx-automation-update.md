# WWDC 2013 #417 — OS X Automation Update (Mavericks)

**Speakers:** Chris Nebel + Sal Soghoian · **54:02** · Track: Tools (OS X)
**nonstrict:** https://nonstrict.eu/wwdcindex/wwdc2013/417/

## The pitch — Mavericks state-of-automation

The companion session to #416 (AppleScript Libraries). #416 is the architectural deep-dive. #417 is the tour of everything else Mavericks ships for automation.

## Five features in the tour

### 1. iCloud Documents for Script Editor

Open/save scripts directly to iCloud Drive. Sync your script library across Macs without manually copying. **Note for 2026:** still works in Sequoia.

### 2. One-click code-signing in the Export sheet

> *"The signing dance from 2012 #206 just got a single checkbox."*

Mavericks adds a **"Sign" popup in Script Editor's Export sheet**. Pick your Developer ID identity, click Save, you have a signed applet. The Mountain Lion three-step (set bundle ID, chmod a-w, codesign CLI) collapses to one UI choice.

### 3. AppleScript Libraries (the headline) — see #416 for the deep-dive

Recap here: `~/Library/Script Libraries/`, `script "<name>"` reference, `use` clause, .sdef terminology, script-bundle ASOC.

### 4. Notification Center support

```applescript
display notification "Build finished" with title "Xcode" subtitle "Project: MyApp" sound name "Submarine"
```

AppleScript can now post Notification Center alerts. Useful for long-running scripts that need to ping the user without stealing focus.

Plus: the `Display Notification` Automator action ships, with template fields for app icon, title, subtitle, body, sound.

### 5. Speakable Workflows (★ underrated)

**The filename of an Automator workflow becomes its trigger phrase under Speakable Items.** Save a workflow as `"open my email"` → invoke Speakable Items → say "open my email" → workflow runs.

**This is the 2013 ancestor of every modern voice-routing trick** — including Hey Sal v1's matcher pattern (memory: `vocal_shortcuts_trigger_position.md`). Apple shipping it on a stage 11 years before voice-as-trigger surface re-emerges as Vocal Shortcuts.

## Closing — 20th-anniversary toast

Chris Nebel closes with **four explicit thank-yous to the community**: developers, scripters, customers, engineers. Same four constituencies Sal lists in #416 — the **community model** is consistent across both Mavericks sessions.

This is two sessions, on the same day, both ending with the same gratitude speech. **Apple was celebrating AppleScript's 20th birthday on the WWDC stage in 2013.**

## Power features delivered

- **iCloud Drive for `.scpt` / `.applescript`** — multi-Mac script sync
- **One-click code-signing** in Script Editor Export sheet
- **`display notification` AppleScript command** — Notification Center from scripts
- **`Display Notification` Automator action** with full template fields
- **Speakable Workflows** — filename-as-trigger-phrase voice routing
- **20th-anniversary community recognition** — developers + scripters + customers + engineers

## Sal's voice quotes (from #416/#417 together)

> *"You're going to like Libraries, they're going to be useful for you."*

> *"It's just an XML file."* (on .sdef)

> *"On the 20th anniversary, we want to thank developers + scripters + customers + engineers."*

## Marketing copy version

**Headline:** Mavericks polishes the whole automation surface. One-click signing. Notification Center from scripts. **Voice-trigger workflows by filename** (the trick Hey Sal still uses in 2026). And the architectural headline of #416 — AppleScript Libraries — turns the language extensible.

**Audience takeaway:** Mavericks is a maturity release. Every paper cut from 2003-2012 gets a polish pass. The big feature is AppleScript Libraries (#416); the underrated one is Speakable Workflows (voice via filename). Watch both 416 and 417 — they're a pair.
