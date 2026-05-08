# Hey Sal — Where the 15 Exporters Take Us

> 2026-05-08. Drafted after shipping the Tier 1 batch. The vision
> isn't "more exporters". It's what happens when the exporters are
> fed back into Esa's working life through voice + intent + Apple
> Intelligence — replicating exactly what Apple killed in November
> 2016 when they eliminated Sal Soghoian's role and pulled WWDC 2016
> session 717.

## The Sal context (recap)

In 2016, Sal Soghoian had a working **Siri-on-Mac prototype** with
hundreds of natural-language voice commands controlling iWork +
Photos + Finder. Demoed to top execs to silent-then-applauding
rooms. **Killed because shipping it would have made iOS Siri look
weaker.** WWDC 2016 session 717 ("Beyond Dictation: Enhanced Voice
Control for macOS Apps") was pulled a week after he gave it. Four
months later his position was eliminated.

The recovered transcript is at
`sources/sal/wwdc2016-session-717/717-transcript.txt`. The closing
thesis: **"voice is a peer to touch, keys, and cursor… it's only
something that can happen on a Mac."**

Apple has been trying to ship this product as "Apple Intelligence"
for two years and has not, as of macOS 15.6.1, gotten anywhere
close to what Sal demoed in 2016.

## What the 15 exporters give us — that nobody else has

A Mac user's life is scattered across ~20 Apple-shipped apps. Each
is a silo with its own UI, its own data store, its own
search-or-no-search story. Apple does not provide a unified query
layer across all of them. Spotlight comes closest, but it only
indexes content for a handful and treats every result as a file.

After today's build, every one of these is queryable as **plain
text in `~/work/apple/exported/`**:

```
notes / imessage / reminders / voice-memos / safari / stickies /
console / audio-midi / image-capture / calendar / finder / music /
mail / photos / iwork
```

Plus:
- **`bin/app-plist-probe.py`**: a meta-tool that already mapped
  1,934 plists across 518 Apple apps. Shows which apps still hold
  data we haven't catalogued.
- **31 scripting dictionaries** at `dictionaries/<app>/<app>.md`
  for every Tier 1 + Tier 2 app's full sdef.
- **The Tier 5 back-door pattern** documented at
  `~/.claude/projects/.../memory/tier_5_backdoor_pattern.md`.
- **`take_photo.swift`** + **`resolve_bookmark.swift`** + future
  Swift one-liners — Foundation/AVFoundation/IOKit reach without
  Homebrew or pip.

This is the exact "data layer" Sal needed in 2016 but didn't have
because the apps weren't open — Apple kept them as silos.
**Now they are open.** We did it ourselves.

## Layer 1 — `apple-grand-search`

The first thing to build: a unified CLI that queries every
exporter's vault in one go.

```bash
apple-grand-search "Kortela"
```

returns:

```
=== Voice Memos (3 hits) ===
  2026-02-27  Recording 181 Jukka Kortela  (2:02:20)  T  ← Apple transcript
  2026-02-26  Recording 180 Jukka Ursin    (50:13)
  2026-02-09  Jukka Kortela call

=== Safari (24 hits) ===
  forum.renoise.com → 13 open tabs / 11 iCloud  /opens link/
  Jukka Kortela Aalto research portal — visited 6 ×

=== Mail (47 hits) ===
  2026-02-27  jukka.kortela@aalto.fi  →  "Re: pyrolysis paper draft"
  2026-02-09  Esa Ruoho  →  "Kortela meeting agenda"

=== Calendar (3 hits) ===
  2026-02-27 09:30 Jukka Kortela call (Calendar: Free Energy)
  2026-02-26 14:00 Jukka Ursin precursor (Calendar: Free Energy)

=== Notes (5 hits) ===
  Free Energy / Kortela pyrolysis precursors.md
  Free Energy / 2026-02-26 Jukka Ursin call.md

=== Photos (1 hit, GPS-tagged) ===
  2025-09-12 Aalto campus  (60.184, 24.823)

=== Reminders (1 hit) ===
  Eheä Oppi: "Kortela whitepaper draft" (incomplete)
```

Built with ripgrep across the markdown vaults — no third-party
indexer. ~50 ms across the full ~30 MB corpus.

## Layer 2 — `apple-grand-export`

Single command runs every exporter in dependency order. Single
timestamped run produces a snapshot of the user's entire Apple
life:

```bash
apple-grand-export                 # ~2 minutes for the full archive
apple-grand-export --quick         # skip the slow ones (photos export, music --with-tracks)
```

Vault state becomes a daily / weekly cron candidate. Diff two
snapshots to see what changed (new mail, new tabs, new photos, new
recordings).

## Layer 3 — Apple Intelligence + Foundation Models

macOS 15.2+ ships **on-device foundation models** as the
`FoundationModels` Swift framework. Free, no network, no
third-party API key, no rate limits. Use it via Swift one-liner:

```swift
import FoundationModels
let response = try await LanguageModelSession().respond(
    to: "Summarize this voice memo transcript: \(text)"
)
```

Wire that into a `apple-summarize <markdown-file>` command. Then:
- **`voice-memos-exporter summarize <selector>`** — auto-five-bullet
  TL;DR appended to each .md sidecar, fully on-device.
- **`mail-exporter daily-digest --since yesterday`** — group new
  mail by sender + topic, summarize each cluster.
- **`safari-exporter dedupe --explain`** — for each duplicate
  cluster, the model picks which copy to keep based on
  history-visit recency + tab-group relevance.
- **`photos-exporter caption --album X`** — generate captions for
  every asset in an album using Apple's Vision framework + LLM.
- **`reminders-exporter prioritize --list X`** — re-rank reminders
  by inferred urgency from their text + due dates.

No data leaves the Mac. No API key. No subscription. This is the
piece Apple shipped in macOS 15.2 specifically to enable what the
exporters now make queryable.

## Layer 4 — Hey Sal (the actual thing)

The voice front-end. Sal's WWDC 2016 vision, finally replicated.

### Architecture

```
[mic] → macOS Vocal Shortcuts ("Hey Sal …")
      → captured utterance
      → FoundationModels intent classifier
      → dispatch to exporter or AppleScript
      → result
      → AVSpeechSynthesizer (or Discord, or Loupedeck LCD)
```

### Concrete commands

```
"Hey Sal, what did I record on Mauri Rantala?"
  → voice-memos-exporter list --match Mauri
  → cat the Apple transcript
  → speak it back

"Hey Sal, find Ruby's email from last month about CD Baby"
  → mail-exporter search --sender ruby --since 2026-04-01 --subject "CD Baby"
  → speak the subject + first line of body

"Hey Sal, when did I last visit Forum Renoise?"
  → safari-exporter search forum.renoise.com → top history result
  → "You last visited that 2026-05-07 at 18:28."

"Hey Sal, what's on my calendar for today?"
  → calendar-exporter upcoming -n 10 --filter today
  → speak summary

"Hey Sal, schedule a recording for tomorrow at 9"
  → calendar-exporter create + voice-memos-exporter watch hook

"Hey Sal, mark that reminder done"
  → reminders-exporter complete (latest)

"Hey Sal, show me my Pages CVs"
  → iwork-exporter recents --app pages | grep -i CV
  → "You have CVs from 2024 (English), 2024 (Music), 2025 (English)."

"Hey Sal, take my photo"
  → image-capture-exporter snap --camera FaceTime

"Hey Sal, summarize my latest voice memo"
  → voice-memos-exporter latest → whisper transcribe (--fi) →
    FoundationModels summarize → speak

"Hey Sal, what's the most-cited URL in my open tabs?"
  → safari-exporter dedupe --summary-only → top duplicate
  → "Renoise Forums root — 24 places, visited 6,527 times."
```

The intent classifier is one Swift file calling FoundationModels
with a system prompt that lists every available command. The
classifier emits JSON: `{exporter, subcommand, args}`. A small
shell loop dispatches.

### Why this matters

Sal showed it in 2016. Apple killed it because their Siri team
wanted parity. Apple Intelligence now exists but Apple has not
plugged it into the apps Sal had wired up. **We do it ourselves
because the apps' data is now in our hands** — not via the apps,
but via the exporters.

This is the piece the apple repo was set up to deliver. Sal's
vision realised on the user side.

## Layer 5 — Sal's data type chaining

The Automator patent (US 7,428,535) is built on **data type chains**:
"Image Events produces alias → Photos consumes alias → Keynote
consumes Photos asset". The exporters now make those chains
queryable as markdown:

| Source | Chain | Sink |
|--------|-------|------|
| voice-memos transcript (txt) | grep — | mail subjects, calendar events |
| photos GPS (lat,lon) | join — | safari history places |
| safari URL | match — | notes URL mentions, reminders URL mentions |
| calendar event title | match — | voice-memos recordings ±30min |
| mail sender | match — | contacts (Phase 2) |
| iwork recent file | path — | finder tags |
| stickies title | match — | free-energy archive corpus |

Each combination is a `xref` subcommand on one of the exporters.
We already noted these in the per-package READMEs as Phase 2. With
Apple Intelligence on top, **xref becomes automatic semantic
matching** rather than literal-string lookup.

## Layer 6 — Loupedeck physical interface

Esa's Loupedeck Live + Stream Deck are already wired to AppleScript
launchers. Now they can be wired to exporter actions:

| Button | Action |
|--------|--------|
| "Show today" | `calendar-exporter upcoming -n 10` → display |
| "Latest recording" | `voice-memos-exporter open latest` |
| "New sticky" (Phase 2) | `stickies-exporter create --body $(pbpaste)` |
| "What's open" | `safari-exporter status` → tab count per window |
| "Mark all read" (Phase 2) | `mail-exporter mark-read INBOX` |
| "Snap me" | `image-capture-exporter snap --camera FaceTime` |
| "Hey Sal" | trigger the voice command pipeline |

The hardware controller becomes the physical surface for Sal's
voice surface.

## Layer 7 — Cloudcity / BBS / Ray Browser integration

Esa's Ray Browser project has a personal-OS layer (Cloudcity,
Cloudcity-OS, the BBS). The exporters' markdown vaults are
**exactly the input format** that BBS expects: per-record .md
files with YAML frontmatter, organised hierarchically, ready to
ingest into the personal knowledge graph.

```
~/work/apple/exported/  →  Ray Browser BBS personal data layer
```

Voice memos become BBS posts. Calendar events become BBS timeline
entries. Mail conversations become BBS threads. Safari open tabs
become "current focus" indicators. Stickies become quick-capture
thoughts. **The Mac becomes a personal OS where everything is
indexed, semantically searchable, and voice-addressable.**

## Layer 8 — The public side (one-command bootstrap)

```bash
git clone https://github.com/esaruoho/apple ~/work/apple
cd ~/work/apple
./bin/apple-bootstrap
```

does for any Apple user:
1. Grants Full Disk Access (open System Settings, instructions).
2. Copies every `.env.example` to `.env` (defaults to `exported/<name>/`).
3. Runs `bin/app-plist-probe.py --md` to find what's mineable on
   that user's Mac.
4. Runs every read-only exporter once.
5. Opens `~/work/apple/exported/INDEX.md` in their editor.

In under 10 minutes, a fresh user has every Apple-shipped app's
data in markdown form. **The repo becomes the canonical "everything
from your Mac in one Obsidian-grade vault" tool.** Open source.
Apple-native. No Homebrew, no pip, no third-party SaaS.

That's the goal stated in the README. We're 80% of the way there
after today's build. The remaining 20% is the layers above.

## Concrete next steps in priority order

1. **`apple-grand-search`** (1 hour) — single CLI, ripgrep over
   `exported/`, ranked output. Highest leverage per hour.
2. **`apple-grand-export`** (30 min) — wraps the 15 exporters,
   parallel where possible, single timestamped commit hook.
3. **`apple-summarize`** Swift+FoundationModels wrapper (1 hour).
4. **First `xref` subcommand** on voice-memos: `xref --calendar`
   matches each recording against ±30 min Calendar events.
5. **Hey Sal v0** (2 hours) — Vocal Shortcuts + intent classifier
   + dispatch shell loop. 10 commands enough for a demo.
6. **Loupedeck button → exporter action mapping** (1 hour) — write
   a few `.scpt` wrappers that call the exporters with fixed args.
7. **`apple-bootstrap`** (1 hour) — one-command setup for any
   Apple user clone-and-run.

That's a single afternoon's worth of work to land all seven layers
at MVP quality. After that, the apple repo isn't just "16 export
packages" — it's **the Sal-vision realised**, fully Apple-native,
fully open-source, on every Apple user's Mac.

## Why this is structurally hard for Apple to do

Apple's incentive is to keep apps as silos so iCloud + AppleCare +
Apple Intelligence all have proprietary lock-in. **Their structure
doesn't reward unification — ours does.** We can ship the unified
layer because we don't have a profit motive that would be
threatened by it. Sal saw this in 2016 and got fired for it.

**The apple repo is, in a real sense, what Sal would have built if
they hadn't fired him.** Continuing to build toward that target is
what makes the project mean something beyond a collection of
exporters.
