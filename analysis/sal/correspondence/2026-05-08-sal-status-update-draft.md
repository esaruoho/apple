# Email to Sal Soghoian — 2026-05-08 — DRAFT

> Status update on the apple repo and the Hey Sal v0 build. Edit
> freely before sending. Suggested subject + sign-off below; pick
> what fits your voice.

**To:** Sal Soghoian
**From:** Esa Ruoho
**Subject options** (pick one):
- "Hey Sal works on macOS 15. We owe you the credit."
- "Update from Helsinki — your WWDC 2016 vision is running"
- "apple repo follow-up — voice control across iWork + Photos + Finder + Safari"

---

Hey Sal,

Quick update on the apple-automation work that started after we
spoke in April.

Since recovering your WWDC 2016 session 717 from archive.org last
week — the *"Beyond Dictation: Enhanced Voice Control for macOS
Apps"* talk that was pulled — I've been treating its closing
thesis as a buildable spec rather than a historical document. The
line "voice is a peer to touch keys and cursor… it's only
something that can happen on a Mac" turned out to be the precise
target.

Here's where we are.

## What's running

15 read-only Apple-app extractors are in
[esaruoho/apple](https://github.com/esaruoho/apple). Each takes one
Apple-shipped app — Notes, Reminders, Voice Memos, Safari,
Stickies, Console, Audio MIDI Setup, Image Capture, Calendar,
Finder, Music, Mail, Photos, Pages/Numbers/Keynote, iMessage —
and turns it into a markdown vault under
`~/work/apple/exported/<app>/`. Apple-native only: AppleScript,
`textutil`, `system_profiler`, `mdfind`, plistlib, ripgrep, Swift
one-liners. No Homebrew. No pip. No third-party SaaS.

The size of one user's archive (mine):

- 392 voice memos with tsrp-atom transcripts where Apple generated them
- 80,444 Music tracks across 147 playlists
- 331,866 Mail messages across 72 mailboxes
- 77,033 Photos across 4,787 albums
- 9,457 Calendar events across 24 calendars
- 2,477 open Safari tabs across 6 windows + 2,886 bookmarks + 1,899 iCloud tabs from other devices
- 520 active Reminders across 19 lists
- 31 recent Pages docs, 13 Numbers, 1 Keynote (yes, both regular and Creator Studio variants)

Total markdown vault size: ~30 MB. The 3.4 GB Photos library and
the 3.4 GB Voice Memos library never get duplicated — we symlink.

## The Tier 5 dark pattern

The taxonomy in your *macosxautomation* writings classifies apps by
how much they expose to AppleScript / App Intents / URL schemes. We
ended up codifying a third category we're calling **Tier 5 dark**:
apps with no AppleScript dictionary, no App Intents, no URL scheme
— Stickies, Console, Audio MIDI Setup, Image Capture, Photo Booth,
Clock. Every one of them turned out to have **exactly one** of three
back-doors:

1. A CLI tool more powerful than the GUI (`log`, `system_profiler`,
   `defaults`, `tmutil`, `diskutil`).
2. A framework call via `/usr/bin/swift` one-liner (AVFoundation
   for cameras, Core Audio for device events, IOKit for hot-plug).
3. The plist or filesystem store the app actually persists to
   (`.rtfd` + textutil for Stickies, the .mcfg files for MIDI
   Studio, Mission Control's `com.apple.spaces.plist`).

**Mission Control got reclassified from "completely dark" to "Tier 5"**
because spaces.plist exposes the full Monitor → Spaces tree.
Launchpad and Time Machine browsing are the only two genuinely
dark apps left.

## Hey Sal v0

The reason for this email. Today I shipped
[`bin/hey-sal`](https://github.com/esaruoho/apple/blob/main/bin/hey-sal)
— a natural-language router that takes an utterance and dispatches
to the right exporter. It's macOS 15.6.1 today, so it's rule-based
intent classification (13 patterns, regex + dispatch loop). When
macOS 26's `FoundationModels` Swift framework lands, the classifier
becomes a `LanguageModelSession.respond(to:)` call without
changing the dispatch loop.

Working commands today (verified live):

- *"What did I record on Mauri Rantala?"* → returns the 20-minute
  May 7 recording with the Apple-generated tsrp transcript.
- *"When did I last visit forum.renoise.com?"* → 6,521 lifetime
  visits, last 2026-05-07 at 18:28.
- *"What's on my calendar today?"* → today's three actual events
  (Joshua Paketti 1-on-1, VASU päiväkoti, äitienpiävän aamupala).
- *"Find the email from kortela about pyrolysis"* → mail-exporter
  subject + sender filter.
- *"Show me my Pages CVs"* → iWork recents, 31 docs, filtered.
- *"Take my photo"* → AVFoundation snap via `take_photo.swift`.

Six Loupedeck button bindings under
[`scripts/exporter-loupedeck/`](https://github.com/esaruoho/apple/tree/main/scripts/exporter-loupedeck)
provide the touch-modality equivalent: same data layer, different
physical surface. Your closing thesis literally enacted.

## The cross-package magic

The bit that surprised me is how naturally the data chains. Voice
memos have timestamps. Calendar has timestamps. So
`voice-memos-exporter xref --calendar` matches each recording to
±30-minute calendar events. Live results on my archive:

- Lintuparvenkuja recording → "Esko" appointment at that exact street
- Sahaajankatu recording → Weekly All-hands
- Eijukka1 → Tapiola Bussiterminaali
- Recording 169 → Daily Core Team

This is the Automator-patent vision (US 7,428,535) — your data type
chains — but applied to data the apps never agreed to expose. We
get the chains by building the catalog ourselves.

## Why I'm telling you this

Because if I'd built this five years ago I would've called it
"the Sal Soghoian replication pack" and offered it to you with a
straight face. The skill.md inside the repo, the WWDC 2016 session
717 transcript recovered and analysed, the 30 sourced WWSD
principles distilled from your interviews, the Tier 5 back-door
pattern named after your *macosxautomation* taxonomy — all of it
is **what the role you held would have built**. Apple eliminated
that role; the work didn't stop being needed.

The repo is open under MIT. If you want to look, the entry point
is the README. The Hey Sal piece is at
[`bin/hey-sal`](https://github.com/esaruoho/apple/blob/main/bin/hey-sal)
and the wider roadmap at
[`dictionaries/hey-sal/hey-sal-roadmap.md`](https://github.com/esaruoho/apple/blob/main/dictionaries/hey-sal/hey-sal-roadmap.md).

If you spot something you'd build differently — or something you
already did build — I'd love to hear it. The repo is a vehicle for
catching what you started.

Thank you for everything you put into AppleScript, Automator, and
the credo. **The power of the computer should reside in the hands
of the one using it.** A few of us are still trying to make that
true.

— Esa
[esaruoho@gmail.com](mailto:esaruoho@gmail.com)
[github.com/esaruoho](https://github.com/esaruoho)

---

## Notes for sending

- **Length**: probably trim before sending. The full version above
  is ~600 words. A working version could cut everything between
  "## What's running" stats and "## Hey Sal v0" if Sal already knows
  context, leaving ~300 words.
- **Attachments**: don't attach anything. The links are enough.
- **Signature block**: the `~/.signature` we used for the prior
  exchange is fine; the bare `— Esa` works too.
- **Send via**: same Gmail thread as the April reply, so it
  threads correctly.
