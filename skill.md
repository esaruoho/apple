---
name: apple
description: Product Manager of Automation Technologies — the role Apple eliminated, continued as open-source
domain: global
version: 3.5.0
generated: 2026-04-02T00:00:00Z
tags: [applescript, macos, automation, hardware-controllers, finder, system-events, workflow, sdef, scripting-dictionary, sal-soghoian, data-type-chaining, app-intents, shortcuts, url-schemes, painpoints, thought-multiplier, bbs, ray-browser]
triggers:
  keywords:
    primary: [applescript, apple script, osascript, apple]
    secondary: [loupedeck, streamdeck, contour shuttle, macos automation, finder, system events, activate app, bring to front, sal, what would sal do, wwsd, shortcuts, app intents, siri phrases, painpoint]
---

# Apple Skill

> Product Manager of Automation Technologies — the role Apple eliminated in November 2016, continued as open-source. 66 apps probed across 13 layers, 1,254 Siri phrases, 246 Shortcuts actions, 111 URL schemes, 31 scripting dictionaries. The credo lives on: *"The power of the computer should reside in the hands of the one using it."*

## User Context

- **User**: Esa Juhani Ruoho ([@esaruoho](https://github.com/esaruoho)) — software tester, UI enthusiast, amateur scripter, automation/workflow obsessive, and user experience evaluator
- **OS**: macOS Sequoia (Darwin)
- **Hardware controllers**: Loupedeck Live, Contour Shuttle Pro, Stream Deck, and any programmable controller that can trigger shell commands
- **Use case**: Hardware buttons, keyboard shortcuts, Siri, and CLI all trigger AppleScripts via osascript to launch/activate apps, automate workflows, and optimize the workday

## Default tool order (updated 2026-05-22 after Sal's ASObjC pointer)

When a task needs code, pick in this order:

1. **AppleScript + AppleScriptObjective-C (ASObjC)** — `use framework "Foundation"` gives every public Cocoa class from a plain `.applescript` file. No Swift, no compile, runs in `osascript`. This is the default. See [`wiki/concepts/asobjc.md`](wiki/concepts/asobjc.md) for the tier doc; [`wiki/concepts/wwsd-decision-tree.md`](wiki/concepts/wwsd-decision-tree.md) for branching.
2. **Python stdlib** — when no public Cocoa class exists for the domain (verify with `bin/cocoa-class-probe ClassName`), or when stdlib is genuinely cleaner (e.g. plain plist read/write — `NSSavedSearch` doesn't exist as a public class, so `plistlib` wins for Smart Folders).
3. **Swift compile** — only when AS+ASObjC genuinely can't reach (e.g. KVO subclassing for AVFoundation, custom NSWindow subclasses, Carbon hotkeys via menu-bar apps).
4. **Shell** — for orchestration and Apple-shipped CLIs (`mdfind`, `defaults`, `xattr`, etc.). NEVER for third-party CLIs.

**Hard rule:** Before naming any Cocoa class in a proposal, run `bin/cocoa-class-probe NSXxxx`. PUBLIC verdict required. ABSENT means the name is wrong. See project memory `feedback_probe_before_naming_cocoa_classes.md`.

## Apple NLEmbedding & FoundationModels — the on-device intelligence layer (zero-token, zero-cloud)

Two Apple-native models ship in the OS — no download, no key, no network, no token:

- **`NLEmbedding.sentenceEmbedding(for:)`** (macOS 10.15+) → a **512-dim Neural-Engine vector** per string. High cosine ≈ similar meaning. This is how a Mac does "semantic" with no LLM. **Clustering is not a model — it's arithmetic on the vectors** (cosine + leader clustering; no sklearn, no third-party anything). Tools: [`bin/apple-embed`](bin/apple-embed) (stdin lines → `{"t","v":[512]}`), [`bin/apple-semantic-match`](bin/apple-semantic-match), [`bin/apple-cluster-docs`](bin/apple-cluster-docs), [`bin/embed`](bin/embed) (warm the shared `~/.vault-embeds/` cache). Cosine guide: >0.8 strong · 0.6–0.8 maybe · <0.6 noise. It's a *light* model: weak on very short strings → **partition first, then embedding-cluster within the partition; use leader clustering** so single-linkage can't chain everything into one blob.
- **FoundationModels** (the on-device Apple-Intelligence LLM, macOS 26 / Tahoe only) → [`bin/fm`](bin/fm) locally, or [`bin/fm-submit`](bin/fm-submit) to run it on the **Mini** via Syncthing (`fm-inbox`/`fm-outbox`) from any machine. **It is NON-DETERMINISTIC and rationalises both ways** — a single call is not a judge. **Always majority-vote** (N samples, take the majority, report `5/5` vs `3/5`, flag ties).

**The division of labour:** NLEmbedding = the *scalpel that selects* (cheap, deterministic, instant); FoundationModels = the *pen that decides* (language understanding, stable only in aggregate). Embed-to-narrow, vote-to-judge. Convey's DreamGraph uses exactly this to dedup 11k Renoise-forum requests and judge them against Paketti (`convey graph dedup` / `judge`).

## Boot Protocol

This skill is a thin index. Section bodies live in `wiki/` and are loaded only when relevant.

**Sal-archive refresh** runs only when the user's message mentions Sal, WWSD, archive, transcript, recovery, dashboard, status, or asks "what's left" / "continue" / "boot up Apple skill":

```bash
python3 bin/sal-archive-status.py --write analysis/sal/current-status.md
```

Then read `analysis/sal/current-status.md` and report. **Do not run the refresh for unrelated AppleScript / Loupedeck / image-batch / Finder / Spotlight questions** — it's the wrong dashboard for those.

For everything else, treat this file as a routing table: identify the topic, grep the matching wiki page, answer.

**Tag pipeline + Dock manager (added 2026-05-21):** Two Apple-native control surfaces wired into the skill. When the user says "tag this", "needs-ocr", "send to OCR", "ocr-failed", "Smart Folder", "talkback" → see [`wiki/concepts/finder-tag-pipeline.md`](wiki/concepts/finder-tag-pipeline.md). When the user says "add to Dock", "pin to Dock", "Dock tile" → see [`wiki/concepts/dock-management.md`](wiki/concepts/dock-management.md). Sidebar Favorites is dead on Sequoia — [`wiki/concepts/finder-sidebar-locked.md`](wiki/concepts/finder-sidebar-locked.md) for why.

**Shipping an app: icon + About/Support/Help (added 2026-08-14):** Two pages that exist because
both were got wrong in a shipped product first. When the user says "app icon", "icon is too large",
"icns", "squircle", "iconutil", "icon looks wrong in the Dock" → see
[`wiki/concepts/macos-app-icon-sizing.md`](wiki/concepts/macos-app-icon-sizing.md): the shape is
**824×824 on a 1024×1024 canvas** (inset `0.098`, corner radius `0.2237` **of the shape**), every size
rendered natively, `lsregister -f` afterwards. When the user says "About box", "About window",
"donate", "support links", "Ko-fi", "Help menu", "the app quits when I click About", "black on grey",
"no menu bar" → see
[`wiki/concepts/macos-about-and-support-window.md`](wiki/concepts/macos-about-and-support-window.md).
Its three load-bearing rules: an `NSAttributedString` with no `.foregroundColor` draws **black**
(unreadable in dark mode); `applicationShouldTerminateAfterLastWindowClosed` **must be `false`**
because AppKit does not count a `.utilityWindow` panel, so the app otherwise quits itself when
About closes; and a `.nonactivatingPanel` has no menu bar in practice, so put the commands on a
`⋯` button and the content view's right-click menu. **An icon that looks too big has TWO causes —
full-bleed artwork AND the About panel drawing it larger than Apple's 64pt.**

**USB + HID devices — "why doesn't my device work on the Mac?" (added 2026-08-14):** When the
user says "USB device", "it doesn't show up", "no driver for this", "jog wheel", "foot pedal",
"game controller", "HID", "Shuttle"/"ShuttlePro", "write a driver for X", or plugs in anything
exotic → two tools, **used in this order**:

1. **[`bin/usbprobe`](bin/usbprobe)** (`list` · `tree` · `watch` · `find <q>` · `doctor`) — is the
   device on the bus **at all**? Python stdlib over `ioreg -a` XML. Answer this first: **absence
   here is not a driver problem.** macOS enumerates devices it has never heard of, so a device
   missing from `usbprobe list` has completed no USB handshake — that is cable/port/device, and no
   amount of code fixes it.
2. **[`bin/hidprobe`](bin/hidprobe)** (`list` · `elements` · `descriptor` · `watch` · `access`) —
   Swift + IOHIDManager. Once it is on the bus, this reads it. **`elements` BEFORE `watch`:** macOS
   already parsed the report descriptor, so it hands you every field with usage, bit size and
   logical range for free — guessing byte offsets from a hex dump is wasted effort. `watch` then
   confirms against physical reality, highlighting changed bytes and printing a before/after bit
   diff that turns a button press into a bit number in one press. It is hotplug-aware, so start it
   *before* plugging in.

**Four traps, each of which cost a wrong answer first:** (1) **`log stream`/`log show` are NOT USB
presence evidence** — at default log level this Mac logs *nothing* on attach; a confirmed replug of
a working mouse produced zero kernel lines. `ioreg` is the detector. (2) **Never parse flat `ioreg`
with awk/grep** — it mispairs `idVendor` with `idProduct` when IOKit emits keys in a different
order; parse the XML (`ioreg -a`). (3) **Interface nodes inherit their parent's `idVendor`/
`idProduct`**, so dedup on `Device Speed` presence or one device counts several times. (4) **Input
Monitoring gates ALL `IOHIDManager` access, not just keyboards**, and the grant follows the *binary*
— iTerm having it does not give your `.app` anything (same shape as the Screen Recording trap).
Reading HID = Input Monitoring; posting `CGEvent`s = **Accessibility**, a second separate grant.
Concepts: [`wiki/concepts/usb-hid-probing.md`](wiki/concepts/usb-hid-probing.md); worked example
(incl. a unit diagnosed dead across three hosts):
[`wiki/entities/contour-shuttlepro.md`](wiki/entities/contour-shuttlepro.md).

**iPhone as a camera / screen on the Mac (added 2026-08-14):** When the user says "iPhone as a
webcam", "iPhone screen on my Mac", "phonemirror"/"iPhonemirror", "record what the phone sees",
"Continuity Camera", "QuickTime won't rotate", or two/three phones side by side → use
[`bin/iphonemirror`](bin/iphonemirror); entity page
[`wiki/entities/iphonemirror.md`](wiki/entities/iphonemirror.md); the diagnosis knowledge is
[`wiki/concepts/iphone-usb-capture-probe.md`](wiki/concepts/iphone-usb-capture-probe.md). **Five
facts that each cost a wrong answer first:** (1) an iOS device is **invisible** to
`AVCaptureDevice` until `kCMIOHardwarePropertyAllowScreenCaptureDevices` is set — four probes
reported "no iPhone" while the phone was working, so never conclude absence from enumeration alone;
(2) that property must be **re-asserted periodically**, because `iOSScreenCaptureAssistant` exits
whenever no screen mirror is in use (e.g. while a Continuity Camera is open) and then every phone
reads as disconnected; (3) devices are **single-client** — one phone gives you mirror *or*
Continuity, never both, and QuickTime holding one hides it from everything; (4) `system_profiler
SPUSBDataType` can return an **entirely empty tree** — use `ioreg -rc IOUSBHostDevice`, and note
`/var/db/lockdown` is `drwx-----x _usbmuxd` so "empty" from a plain `ls` proves nothing; (5) a
phone that appears but won't pair is a **lock-screen race** — grep `iOSScreenCaptureAssistant` and
the `0xe800001a` / `0xe8000016` codes, set Auto-Lock to Never, replug, tap Trust. **Prefer
Continuity on A12+** (clean feed, no chrome, no rotation) and never run orientation heuristics on
it. **Cropping Camera.app's chrome must be GEOMETRY, never luminance** — the subject can itself be
black (a DOS CRT), which defeated four brightness-based attempts.

**AppKit multi-window traps (added 2026-08-14):** Before debugging "the window crashed / ignored my
keystroke / is the wrong size" in any app here → see
[`wiki/concepts/appkit-window-gotchas.md`](wiki/concepts/appkit-window-gotchas.md).
`isReleasedWhenClosed` defaults to **true** and double-releases under ARC (crash is
`objc_release` inside `objc_autoreleasePoolPop`, with none of your code in the trace); a
**borderless window cannot become key**, so every front-window command silently targets the wrong
window after you hide the title bar; never deallocate a controller inside its own
`windowWillClose`; the title bar is not content, so budget it before fitting an aspect ratio, and
tile against `NSScreen.visibleFrame`. Also: **SourceKit reports phantom errors** in any target that
compiles more than one file — `swiftc` is the authority, and such a target needs `@main` +
`-parse-as-library`.

**Finder Settings via `defaults` (added 2026-06-11):** Every checkbox in **Finder ▸ Settings** is a preference key — no UI scripting. When the user says "Finder settings", "show all extensions", "search the current folder", "keep folders on top", "search this Mac", "warn before emptying bin", or names any Advanced/General-pane toggle → use [`bin/finder-settings`](bin/finder-settings) / `/finder-settings` (show · set <name> on|off · search current|thismac|previous · apply). Key map + the `SCev`/`SCcf`/`SCsp` search-scope values are in [`wiki/concepts/finder-settings.md`](wiki/concepts/finder-settings.md). The tool relaunches Finder after any write. **Sidebar pane is NOT a `defaults` job** (`sfl2` store) — see [`wiki/concepts/finder-sidebar-locked.md`](wiki/concepts/finder-sidebar-locked.md).

**Mail flag → routing pipeline (added 2026-05-26):** Fourth instance of the trigger→worker chassis (Finder tag, Voice Memo `#process`, Stickies, now Mail flag). When the user says "mail flag", "flag color", "purple is Free Energy", "tag email to X", "auto-route email", "AppleToolbox mail row" → see [`wiki/concepts/mail-flag-pipeline.md`](wiki/concepts/mail-flag-pipeline.md). Edit `bin/mail-flag-config.json` to add/edit a contract; no rebuild needed. **Critical: Mail Rules cannot trigger on user-flagging (Apple limitation — rule conditions only see incoming-mail attrs), so the polling watcher in AppleToolbox (`MailFlagWatcherRunner`, 30s tick) is the primary path for manual flagging. Manual flag → automation fires within ≤30s. Mail Rules remain useful for "incoming pattern → auto-flag + dispatch" combos.**

**Mac → iPhone push triad (added 2026-05-26):** Three Apple-native, no-UI-hijack CLIs for getting things from terminal to phone. When the user says "send myself", "iMessage me", "imessageme", "push to my phone", "notify iPhone", "send file to phone" → pick by need:

| Need | Tool | Channel |
|---|---|---|
| Text to self (or anyone) | `imessage "text"` | iMessage text bubble — pure AppleScript verb, no UI hijack |
| File to self (screenshot, PDF, .shortcut) | `icloud-drop file --imessage` | iCloud Drive + iMessage URL bubble |
| Background-worker banner | `notify-iphone --title X --body Y` | iMessage-to-self (wraps `imessage` — banner is the iMessage itself, no Shortcut/Automation needed) |

Source: `bin/imessage`, `bin/icloud-drop`, `bin/notify-iphone`. Wiki: [`wiki/concepts/imessage-from-terminal.md`](wiki/concepts/imessage-from-terminal.md), [`wiki/concepts/iphone-notify-pipeline.md`](wiki/concepts/iphone-notify-pipeline.md). **Hard rule:** `bin/imessage` does NOT accept files — System Events keystrokes would hijack Esa's keyboard. Use `icloud-drop --imessage` for any file delivery. See project memory `feedback_never_ui_hijack_active_session.md`.

## Repo layout

`/Users/esaruoho/work/apple/`:

- `bin/` — 65+ CLI tools; slashes in `commands/`
- `commands/` — 30+ zero-roundtrip slash command pointers (install via `commands/install.sh`)
- `scripts/` — 301 launcher + workflow AppleScripts
- `dictionaries/` — 68 scripting-dictionary probe files
- `topbar/`, `homepod/`, `github-watcher/` — entity sub-packages
- `painpoints/`, `patents/` — Apple UX evaluations + automation patents
- `sources/sal/`, `analysis/sal/` — Sal Soghoian primary-source archive + working docs
- `wiki/` — knowledge layer:
  - **`wiki/INDEX.md`** — auto-generated catalog of every page with one-line description. **Read this first for any topical question.** Regenerate with `/wiki-index` or `python3 bin/wiki-index.py`.
  - `wiki/log.md` — append-only chronological record (ingests, lint passes, migrations).
  - `wiki/README.md` — schema and conventions.

## Wiki schema

| Subdir | Purpose |
|---|---|
| `wiki/entities/` | one page per *thing* — person, app, device, package |
| `wiki/concepts/` | one page per *how X works* — atlas, principle, pattern |
| `wiki/lessons/` | didactic / narrative / runbook |
| `wiki/operations/` | active project state — current work, status, plans |
| `wiki/compiled/` | auto-generated, do not hand-edit |

Each page: one H1, optional `description:` frontmatter, ≤250 lines, cross-link to related pages. After adding or editing, run `/wiki-index` then `/wiki-lint` to refresh the index and catch orphans / oversized pages / broken refs.

When you learn something new and durable, write it to the right subdir, then `/wiki-index`. The catalog is the source of truth for the LLM — keep it fresh.

**Auto-regen on commit (added 2026-05-26):** the indexes (`wiki/INDEX.md`, `bin/INDEX.md`, `scripts/workflows/INDEX.md`, `dictionaries/INDEX.md`, `wiki/compiled/EXPORTERS.md`) rebuild themselves on every `git commit` via `hooks/pre-commit` (installed via `bin/install-git-hooks` after clone). Zero Claude tokens. If you add a wiki page or bin script and forget to run `/wiki-index`, the commit will regen + restage the index automatically — atomic with the source change. Don't fight it; trust the hook.
