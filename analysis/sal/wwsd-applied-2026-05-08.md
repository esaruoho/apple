# WWSD Applied — 2026-05-08 Session

> Walking the day's build through the 30 sourced "What Would Sal Do"
> principles from `sal-soghoian.md`. Where each principle showed up
> in concrete code today.

## The macro shape — Sal's credo

> "The power of the computer should reside in the hands of the one using it."

Today: shipped 14 + 7 = **21 tools** that put Apple-shipped-app data
back into the user's hands as plain markdown. Music library, photos,
mail, voice memos, calendar, safari tabs — all queryable via
ripgrep, all sittable in any Obsidian-grade vault, all addressable
via Hey Sal voice commands. The user owns it. Apple's silos open.

## Per-principle walkthrough

### #1 — Look for the underlying principle (the Carpenter Move)

The **Tier 5 dark back-door pattern** is the day's clearest Carpenter
Move. Stickies/Console/Audio MIDI/Image Capture all started as
"Tier 5 — minimal automation". Three probes in, the underlying
principle named itself:

> Every Tier 5 dark app is reachable via exactly one of three back-doors:
> 1. A more-powerful CLI (`log`, `system_profiler`, `defaults`)
> 2. A Swift framework one-liner (AVFoundation, Core Audio, IOKit)
> 3. The plist or filesystem store + `textutil`

That principle is now `~/.claude/projects/.../memory/tier_5_backdoor_pattern.md`. Every future Tier 5 app gets cracked in under 5 minutes by matching against the three back-doors.

### #2 — Forward Motion with a Paddle

The session moved through 14 packages without architectural debate.
Every package follows the same skeleton:
```
<name>-exporter/
├── README.md
├── .env.example   (defaults to ~/work/apple/exported/<name>)
├── .gitignore     (.env)
└── scripts/
    ├── <name>-exporter        bash wrapper
    └── <name>_exporter.py     argparse with status / list / export
```

The skeleton was decided after the 4th package and now serves as
the template. Forward motion. The paddle is the shared shape.

### #3 — Speak the Receiver's Language

Every exporter speaks **markdown** as its output format because
markdown is the receiver-language of Obsidian, GitHub, AI assistants,
and any text editor. Not JSON, not SQLite dumps, not proprietary
formats. The receiver chooses the lens; we just ship markdown.

The Hey Sal intent classifier speaks the **user's** natural
language — "what did I record on Mauri Rantala", "when did I last
visit forum.renoise.com" — not "exporter cli flag syntax". The user
doesn't have to translate.

### #11 — Name commands like speech, not labels

`apple-grand-search` (not `find_in_apple_vault.sh`).
`apple-grand-export` (not `run_all_extractors.py`).
`hey-sal` (not `voice_command_dispatcher.py`).
`apple-bootstrap` (not `setup_apple_repo.sh`).
`apple-summarize` (not `txt_summarizer_v3.py`).

Every command name reads like English. You can dictate them.

### #13–#17 — Sal's hand-crafted Siri phrase rules

The 13 Hey Sal intent patterns aren't filename-derived. Each is
hand-crafted from how Esa would actually phrase the request. Same
discipline Sal demanded for Vocal Shortcuts. The pattern bank is
small (13) on purpose; it's better to have 13 phrases that reliably
fire than 130 that mostly miss.

### #28 — Procedural-vs-Task Commands (WWDC 2016 session 717)

Hey Sal v0 implements both:

- **Procedural** ("show me my pages CVs") → `iwork-exporter recents
  --app pages | grep CV`. Step-by-step.
- **Task** ("take my photo") → `image-capture-exporter snap`. One
  invocation, one outcome.

The intent classifier's job is to recognize which mode the user is
in and dispatch accordingly.

### #29 — Voice as Peer Modality (session 717)

> "Voice is a peer to touch, keys, and cursor — only something that
> can happen on a Mac."

Concretized today:
- **Touch** modality → `scripts/exporter-loupedeck/*.applescript`
  (six button bindings).
- **Keys** modality → `bin/<every-tool>` invoked from Terminal.
- **Cursor** modality → opening the `~/work/apple/exported/INDEX.md`
  in any editor.
- **Voice** modality → `bin/hey-sal --speak`.

All four sit on the same data layer (the 15 exporters). All four
expose the same actions. Sal's peer-modality vision is the
**shape of the bin/ directory**.

### #30 — Seven-Purpose Framework for voice commands (session 717)

Sal's framework: a voice command earns its keep when it serves at
least one of seven purposes. Hey Sal's 13 commands satisfy:

| Purpose | Command |
|---------|---------|
| Reduce friction for frequent action | `take my photo`, `latest recording` |
| Speak data the user can't see at a glance | `what's on my calendar today` |
| Cross-app query the GUI doesn't support | `find email from X about Y`, `most-cited URL in tabs` |
| Ambient awareness | `what's in my apple library` (status across all) |
| Hands-busy access | every command, when bound to Hey Sal voice trigger |
| Bridge between modalities | Loupedeck button → Hey Sal → spoken response |
| Memory aid | `when did I last visit X.com`, `what did I record on Y` |

Every Hey Sal command earns its slot.

## Closing — the Sal email is in the repo

`analysis/sal/correspondence/2026-05-08-sal-status-update-draft.md`
is the draft to send. It frames the apple repo as **what the role
Apple eliminated would have built**. Not as a tribute, not as
fan-art — as the next iteration of the work he started, anchored
in his own published principles.

Where Sal had to fight Apple's silo incentive in 2016, we sidestep
it: we don't have a silo incentive. So we can ship the unification
layer. **The apple repo is in a real sense what Sal would have
built if they hadn't fired him.**

That sentence is in the README. It's in the email draft. It's
worth keeping in mind as the seven layers (search / export /
hey-sal / summarize / bootstrap / xref / loupedeck) accumulate
into something Esa actually uses every day.
