# apple — Feature Reference

> **Generated** from the Gherkin report cards in this folder by `python3 print-card.py --readme`. Do not hand-edit — edit the `.feature` card and regenerate. Each entry below = one card: *what it does* (intent + behaviour scenarios) and *how it does it* (the procs/files the behaviour is cited to).

Each card is a triad: the `.feature` spec, a `.session.md` (the conversation that produced it), and a RESULT-LOG of what shipped.

## Contents

- [Capture one application's audio to a .wav without a loopback driver](#app-audio-record) — `app-audio-record.feature`
- [Read macOS energy & power telemetry from the command line](#apple-energy) — `apple-energy.feature`
- [AppleBar karaoke — the chat answer is revealed in sync with the spoken voice](#applebar-karaoke) — `applebar-karaoke.feature`
- [AppleBar — what the session accomplished](#applebar-session) — `applebar-session.feature`
- [The architecture of any repository, whitelabeled](#archof) — `archof.feature`
- [Arm the Apple skill into the Mini's on-device chat brain](#arm-apple-skill) — `arm-apple-skill.feature`
- [On-device dictation button](#dictation-button) — `dictation-button.feature`
- [Directions home via Apple Maps](#directions-home) — `directions-home.feature`
- [Front and rear iPhone cameras in one picture](#dualcam) — `dualcam.feature`
- [Find My — open the right tab and surface the right person/device](#find-my) — `find-my.feature`
- [Read & control Finder Settings from the command line](#finder-settings) — `finder-settings.feature`
- [Fleet shows each Mac once, correctly named, and one click screen-shares to it](#fleet-identity-and-view) — `fleet-identity-and-view.feature`
- [fm-converse — a remembering conversation with the on-device LLM](#fm-converse) — `fm-converse.feature`
- [chat/ask answers are banked to a FoundationModels Knowledgebank](#fm-knowledgebank) — `fm-knowledgebank.feature`
- [fm-mlx reuses Say, Karaoke, and Markdown (DRY)](#fm-mlx-dry) — `fm-mlx-dry.feature`
- [A reasoning model's thinking is filed, never shown](#fm-think-no-leak) — `fm-think-no-leak.feature`
- [Give a folder a voice — the per-folder sidecar triad](#folder-memory) — `folder-memory.feature`
- [Free-energy lens voices are a shared switch](#free-energy-lens-voices) — `free-energy-lens-voices.feature`
- [freellmask-mail answers each email once, and never speaks for an untranscribed video](#freellmask-mail-anti-loop-and-video-gate) — `freellmask-mail-anti-loop-and-video-gate.feature`
- [Hey Sal folded into AppleBar — hands-free voice over the one routing pipeline](#hey-sal-fold) — `hey-sal-fold.feature`
- [Read HomePod temperature + humidity from the laptop, live and on demand](#homepod-live-climate) — `homepod-live-climate.feature`
- [Copy iCloud Drive files and folders to external storage without Finder errors](#icdcopy) — `icdcopy.feature`
- [image-playground — on-device pictures, locally, as the prose's twin](#image-playground) — `image-playground.feature`
- [An iPhone photo, on the Mac clipboard, the way you took it](#iphone-clip) — `iphone-clip.feature`
- [iPhoneMirror — live, auto-oriented, auto-cropped mirror of a USB iPhone screen](#iphonemirror-rotated-live-mirror) — `iphonemirror-rotated-live-mirror.feature`
- [mailfe is a reusable Convey belt from source material to emailed analysis](#mailfe-convey-belt) — `mailfe-convey-belt.feature`
- [AppleBar parses markdown in its result pane](#markdown-attributed) — `markdown-attributed.feature`
- [Home address from the Contacts me-card](#me-address) — `me-address.feature`
- [Where am I right now — device-presence geolocation for a desktop Mac](#me-location) — `me-location.feature`
- [The on-device agentic tool-calling loop on the Mini's MLX brain](#mlx-agent-tool-loop) — `mlx-agent-tool-loop.feature`
- [Post-process a screen recording's audio (split / flatten)](#rec-audio) — `rec-audio.feature`
- [Subtitle a screen recording (.srt sidecar + burn-in)](#rec-subtitle) — `rec-subtitle.feature`
- [Two presses of the same key always get the shell back](#recburn-abort) — `recburn-abort.feature`
- [Trigger recburn from anywhere through one seam, and hand off a typed result](#recburn-automation-surfaces) — `recburn-automation-surfaces.feature`
- [Deliver a recording at a normal listening level, measured not guessed](#recburn-loudness) — `recburn-loudness.feature`
- [Redact a region of a finished recburn video without re-rendering it](#recburn-redact) — `recburn-redact.feature`
- [The only thing that ends a take is the person making it](#recburn-stream-recovery) — `recburn-stream-recovery.feature`
- [Lift the voice against the app audio, measured not guessed](#recburn-voice-balance) — `recburn-voice-balance.feature`
- [Burn a live click counter into a screen recording](#recburnclick) — `recburnclick.feature`
- [Record screen + system audio to one .mov with no loopback driver](#screen-audio-record) — `screen-audio-record.feature`
- [Refuse to commit an account id, bank last-4, key or token](#secret-scan) — `secret-scan.feature`
- [The master session list is bootable with one word](#sesh) — `sesh.feature`
- [Desktop & Dock visibility from the command bar](#shell-toggles) — `shell-toggles.feature`
- [Live Spotlight-style suggestions in AppleBar](#spotlight-suggestions) — `spotlight-suggestions.feature`
- [Recover a wedged USB-C port without losing the work on the machine](#usb-port-revive) — `usb-port-revive.feature`
- [One button for "Claude talks to me" (server + speech together)](#voicebox-speak-toggle) — `voicebox-speak-toggle.feature`
- [voicebox-worker — a TTS queue that survives the worker dying mid-job](#voicebox-worker) — `voicebox-worker.feature`
- [A Voice Memo tagged #audio becomes a .wav sample on disk](#voicememo-audio-tag-to-wav) — `voicememo-audio-tag-to-wav.feature`


<a id="app-audio-record"></a>
## Capture one application's audio to a .wav without a loopback driver

`features/app-audio-record.feature` · [session](app-audio-record.session.md)

**Behaviour (23 scenarios):**

- all-system tap writes a real, non-silent WAV  (ran live 2026-07-29) — `@hw-verified`
- app scoping really scopes — a silent app yields digital silence while other audio plays  (ran live 2026-07-29) — `@hw-verified`
- --out is a FILE only if it ends in .wav, otherwise a FOLDER  (ran live 2026-07-29) — `@hw-verified`
- an app that holds an open stream but renders nothing is called out  (ran live 2026-07-29) — `@hw-verified`
- teardown is silent, not an error  (ran live 2026-07-29) — `@hw-verified`
- --list enumerates tappable applications  (ran live 2026-07-29) — `@hw-verified`
- no --seconds means record until Ctrl-C — `@built`
- recorder's own audio never leaks into the capture — `@built`
- a capture that never received audio fails loudly instead of writing a stub — `@built`
- the picker lists apps and marks who is ACTUALLY making sound  (ran live 2026-07-29) — `@hw-verified`
- it survives a terminal that can't hide the cursor  (ran live 2026-07-29) — `@hw-verified`
- arrow keys + Enter produce a .wav  (ran live 2026-07-29, driven through a pty) — `@hw-verified`
- Enter raises the picked app before the tap opens  (logic ran headlessly 2026-07-29) — `@hw-verified`
- the meter line is also the clock  (ran live 2026-07-29, pty) — `@hw-verified`
- stop the capture with a keypress, not just Ctrl-C  (ran live 2026-07-29, pty) — `@hw-verified`
- "first, then" — record Renoise TO Ableton Live as one gesture  (2026-07-29) — `@hw-verified`
- the path is handed over as DATA, not scraped from prose  (ran live 2026-07-29) — `@hw-verified`
- a silent grab is never handed onward  (ran live 2026-07-29) — `@hw-verified`
- destinations resolve by bundle id or by name, and refusals are admitted  (2026-07-29) — `@hw-verified`
- combos are remembered — the second time is one keypress  (ran live 2026-07-29) — `@hw-verified`
- two MIDI buttons — fire a combo with no UI at all  (ran live 2026-07-29) — `@hw-verified`
- the second MIDI button stops an open-ended capture  (ran live 2026-07-29) — `@hw-verified`
- every entry path is smoke-tested, including the bare one  (ran live 2026-07-29) — `@hw-verified`

**Grade:** @built ×3 · @hw-verified ×20


<a id="apple-energy"></a>
## Read macOS energy & power telemetry from the command line

`features/apple-energy.feature` · [session](apple-energy.session.md)

**Behaviour (16 scenarios):**

- now prints a no-sudo snapshot of top apps by energy impact  (ran live) — `@built`
- watch samples powermetrics over a window and ranks per-process energy — `@built`
- power reports actual system watts, not relative units  (ran live, headers) — `@built`
- adapter prints wattage + battery state, no sudo  (ran live) — `@built`
- claude enumerates running Claude Code sessions by version  (ran live) — `@built`
- claude TTYs are Cmd-clickable to jump to the session  (registration ran live) — `@built`
- the aejump handler sends the AppleEvent directly (TCC-correct)  (diagnosed live) — `@built`
- now is a proper 4-column table, not a freeform blob  (ran live) — `@built`
- claude and now render as Unicode box-drawing tables  (ran live) — `@built`
- claude/now/jump show the SESSION NAME, not just the project  (ran live) — `@built`
- jump focuses a claude session's terminal window/tab  (resolution + tty-read ran live) — `@built`
- heat frames watts AS heat and shows the thermal drivers  (ran live, no-sudo part) — `@built`
- kill SIGTERMs a hog now but refuses critical processes  (ran live) — `@built`
- off finds the launchd job, dry-runs by default, disables on --yes  (dry-run ran live) — `@built`
- power POLICY is out of bounds
- same capability is reachable as a zero-roundtrip slash — `@built`

**How it does it:** **Source files:** `bin/_apple_energy.py`

**Grade:** @built ×15


<a id="applebar-karaoke"></a>
## AppleBar karaoke — the chat answer is revealed in sync with the spoken voice

`features/applebar-karaoke.feature`

**Behaviour (5 scenarios):**

- AppleBar compiles and launches with the synth wired
- a chat answer is shown whole, then brightens word-by-word as spoken — `@built`
- the result appears WITHOUT waiting for speech (the original bug, fixed) — `@built`
- speech stops when the bar is dismissed or reopened — `@built`
- voice + markdown handling

**How it does it:** **Source files:** `AppleBar.swift`

**Grade:** @built ×3


<a id="applebar-session"></a>
## AppleBar — what the session accomplished

`features/applebar-session.feature`

**Behaviour (8 scenarios):**

- Headless Markdown renderer test (stop screenshotting render bugs) — `@shipped`
- FoundationModelsChat exports the conversation — `@shipped`
- apple-intent — the embedding intent router (non-Tahoe twin of fm) — `@shipped`
- AppleBar — the Spotlight-style command bar — `@shipped`
- One shared catalog + one shared dictation engine (DRY) — `@shipped`
- Capabilities wired (the "Conveys") — `@shipped @built`
- Each unit carries its own report card (the discipline)
- Incidents closed

**Grade:** @built ×1 · @shipped ×6


<a id="archof"></a>
## The architecture of any repository, whitelabeled

`features/archof.feature`

**What it does:** As Esa, wanting to point ONE tool at ANY repo and see its architecture in a consistent shape — the report-card doctrine (same skeleton, repo-specific skin) applied to codebases.

**Behaviour (6 scenarios):**

- Read a repo's shape, language-agnostic — `@built`
- The wiring is drawn, not just listed (so you can SEE it) — `@built`
- Custom require-wrappers are understood (not just bare import) — `@built`
- Safe and bounded (no laptop-cooking grep) — `@built`
- Reusable everywhere — one source of truth — `@built`
- Apple-native, dependency-free — `@stock`

**How it does it:** **Source files:** `Filee.swift`

**Grade:** @built ×5 · @stock ×1


<a id="arm-apple-skill"></a>
## Arm the Apple skill into the Mini's on-device chat brain

`features/arm-apple-skill.feature` · [session](arm-apple-skill.session.md)

**What it does:** As Esa, standing in a repo folder, I want to chat with the Mini's MLX (or FM) LLM with the Apple skill's knowledge and my current folder already loaded, so I am not re-explaining the repo to a stateless model every turn — the same way Convey arms a roundtable persona with a corpus ("What would Bearden say"). Background: Given the Mini runs the MLX server (Qwen3-4B) and the fm-worker (FoundationModels) And convey.knows.retrieve is importable for per-turn wiki retrieval And bin/arm_apple.py assembles identity + folder context + retrieval

**Behaviour (17 scenarios):**

- mlx-here arms the skill from the current folder — `@built @hw-verified`
- identity is set once, knowledge is retrieved per turn — `@built @hw-verified`
- retrieval pulls real content, not the catalog — `@built @hw-verified`
- --apple works on the FoundationModels brain too — `@built`
- graceful degrade when convey is absent — `@built`
- the spoken reply uses Voicebox, not macOS say — `@built @hw-verified`
- voicebox-say integrates with the existing stop paths — `@built`
- Ctrl-C never crashes the chat — `@built @hw-verified`
- armed chats answer live sensor/state questions — `@built @hw-verified`
- live-data routing is precise — `@built @hw-verified`
- the spoken voice is the premium voice, not Eddy — `@built @hw-verified`
- the spoken reading can be stopped, paused, and resumed — `@built @hw-verified`
- AppleToolbox's ~/bin helper symlink must exist — `@built @hw-verified`
- showing a reply is ONE shared call, never re-rolled (DRY) — `@built @hw-verified`
- the controls act only on a live reading
- DispatchSource signal sources must be retained — `@built`
- Qwen3-4B thinking mode is verbose

**Grade:** @built ×15 · @hw-verified ×11


<a id="dictation-button"></a>
## On-device dictation button

`features/dictation-button.feature` · [session](dictation-button.session.md)

**What it does:** As a toolbox user, I can speak a request instead of typing it. The mic + recogniser logic lives once, in OnDeviceDictation; each app wires its three callbacks (onText / onStateChange / onError) to its own UI.

**Behaviour (10 scenarios):**

- A fresh engine is idle
- On-device recognition is preferred (audio stays local)
- AppleBar's button is the real dictation glyph, not a cartoon emoji — `@built`
- Stopping an idle engine is a safe no-op
- Tapping the mic authorises, listens, and streams text into the field — `@built @untested`
- Return stops the mic, then runs what was heard — `@built @untested`
- A final result arriving after stop is dropped (no duplicate text) — `@built @untested`
- AppleBar consumes the shared engine, not its own copy (DRY) — `@built`
- AppleToolbox's SpeechDictationController sits on top of the shared engine — `@todo`
- Converse is a separate path, not a consumer

**How it does it:** **Source files:** `shared/Dictation.swift`, `dictation-tests.swift`, `apple-bar/AppleBar.swift`, `converse/main.swift`

**Grade:** @built ×5 · @todo ×1 · @untested ×3


<a id="directions-home"></a>
## Directions home via Apple Maps

`features/directions-home.feature` · [session](directions-home.session.md)

**What it does:** Asking how to get home (or how far it is) opens Maps with a route home.

**Behaviour (6 scenarios):**

- Navigation phrases route to directions, not the thermostat
- Temperature words ONLY hit the climate sensor (narrowed)
- directions opens Maps.app (not the browser) from current location to home — `@built`
- the SOURCE is deduced from device presence, not left to a GPS-less desktop — `@built`
- the DESTINATION is clever — it's your OTHER anchor, not always "home" — `@built`
- The Maps URL pattern is reused from ray-graph, not re-invented

**Grade:** @built ×3


<a id="dualcam"></a>
## Front and rear iPhone cameras in one picture

`features/dualcam.feature`

**Behaviour (6 scenarios):**

- both sensors run simultaneously — `@built`
- five layouts, cycled by tapping — `@built`
- it is built to be FILMED, not used — `@built`
- it compiles and signs  (2026-08-17) — `@hw-verified`
- the build discovers the team instead of hardcoding it  (2026-08-17) — `@hw-verified`
- INSTALL IS BLOCKED — the free team is full — `@built`

**Grade:** @built ×4 · @hw-verified ×2


<a id="find-my"></a>
## Find My — open the right tab and surface the right person/device

`features/find-my.feature` · [session](find-my.session.md)

**Behaviour (5 scenarios):**

- "find" and the wife phrasings all route to the wife (Olga)
- devices and phone phrasings route distinctly
- it RELIABLY switches tab even when Find My is already open on another tab
- there is NO row selection — Find My takes no text input
- one tool, three bindings — DRY, not three near-copies


<a id="finder-settings"></a>
## Read & control Finder Settings from the command line

`features/finder-settings.feature` · [session](finder-settings.session.md)

**Behaviour (7 scenarios):**

- show prints the live state of every known toggle  (ran live) — `@built`
- apply sets Esa's preset and relaunches Finder  (ran live) — `@built`
- set flips any one boolean toggle on or off — `@built`
- search selects the "When performing a search" scope — `@built`
- every checkbox change is invisible until Finder relaunches  (ran live) — `@built`
- the same capability is reachable as a zero-roundtrip slash — `@built`
- the Sidebar pane is out of scope

**Grade:** @built ×6

**Commits:** `bfef17f` bin/finder-settings + /finder-settings slash + wiki concept page · `48a22f4` skill.md routing pointer (deploy)


<a id="fleet-identity-and-view"></a>
## Fleet shows each Mac once, correctly named, and one click screen-shares to it

`features/fleet-identity-and-view.feature` · [session](fleet-identity-and-view.session.md)

**Behaviour (10 scenarios):**

- A churned hostname no longer splits a Mac into two Fleet cards — `@runtime-verified`
- Pinning a static HostName ends the mDNSResponder name-conflict storm
- Fleet forgets a card whose file was deleted — `@runtime-verified`
- The Mini probes Hertsi over a static IP, immune to mDNS breakage — `@runtime-verified`
- Hertsi's card is always titled HertsiMacPro, never MacPro — `@runtime-verified`
- The Mac Pro is genuinely renamed to HertsiMacPro
- fleet-files screen accepts a Machine Card id and picks the right transport — `@runtime-verified`
- A clickable app screen-shares to a peer in one double-click — `@runtime-verified`
- Fleet shows a VIEW button on every peer card — `@build-verified`
- AppleToolbox lists a VIEW item per peer under a Screen Share menu — `@runtime-verified`

**How it does it:** **Source files:** `fleet/Fleet.swift`, `machine-card-probe-assemble.py`, `topbar/AppleToolbox.swift`

**Grade:** @build-verified ×1 · @runtime-verified ×7

**Commits:** `c7cfcfd` machine-card: canonical name immune to Bonjour storms · `ba7df63` fleet: refresh evicts Syncthing peers whose card file vanished · `fbdce17` wiki: rename a Mac via SSH · `3dc5e4d` bin/build-screen-app: clickable "Screen <peer>.app" · `5512dde` Fleet + AppleToolbox: one-click VIEW (Screen Sharing) to any peer · `aeca2cc` machine-card-probe: resolve Hertsi via static IP from peers.json · `8fce465` machine-card-probe: TEMP debug logging (reverted by 717554d) · `717554d` machine-card-probe: drop temp debug; force canonical name HertsiMacPro


<a id="fm-converse"></a>
## fm-converse — a remembering conversation with the on-device LLM

`features/fm-converse.feature`

**What it does:** As someone talking to Apple's FoundationModels model on the Mac Mini, I want each message to carry the prior dialogue and come back rendered, So that Converse's Cmd-1 is a real conversation, not unrelated one-shots.

**Behaviour (8 scenarios):**

- A follow-up question keeps the prior context — `@built`
- Replay stays inside the 4096-token FoundationModels window — `@built`
- Markdown renders as ANSI on a terminal, plain when piped — `@built`
- A worker/guardrail/timeout error is surfaced, not swallowed — `@built`
- A file path is read and summarised instead of sent literally — `@built @untested`
- Context-overflow self-heal retries without history — `@built @untested`
- The conversation is keyed to the newest Converse session dir — `@built`
- Stored conversation is volatile and reportcard-less — `@built`

**How it does it:** **Source files:** `bin/fm.swift`

**Grade:** @built ×8 · @untested ×2


<a id="fm-knowledgebank"></a>
## chat/ask answers are banked to a FoundationModels Knowledgebank

`features/fm-knowledgebank.feature`

**Behaviour (5 scenarios):**

- a chat answer from the on-device model is appended to the bank
- the bank is append-only with a one-time header
- only real answers are banked — `@built`
- the chat answer is spoken back in Zoe (talk, like convey talk)
- the bank location is conventional and overridable

**Grade:** @built ×1


<a id="fm-mlx-dry"></a>
## fm-mlx reuses Say, Karaoke, and Markdown (DRY)

`features/fm-mlx-dry.feature` · [session](fm-mlx-dry.session.md)

**What it does:** As the operator of the fm-* family I want fm-mlx to lean on the capabilities that already exist So that Markdown rendering, speech, and voice live in ONE place each Background: Given the Mini's mlx_lm.server (Qwen3-4B) is reachable over Tailscale And bin/fm_render.py is the single Markdown renderer And bin/say-karaoke is the single speak+highlight tool And the `say` skill's chosen voice is "Eddy"

**Behaviour (8 scenarios):**

- the reply is shown the SAME way as fm-chat, in richtext
- it speaks by default (automatic talk), TTY-gated
- a captured/piped call stays silent (roundtable safety)
- nothing is duplicated — one renderer, one framer
- --raw is the shared brain interface
- fm-chat --mlx is a live REPL that prints AND says each reply
- convey roundtable uses the MLX brain BY DEFAULT, the same way
- md_to_plain strips markers for speech; md_to_ansi styles for the terminal


<a id="fm-think-no-leak"></a>
## A reasoning model's thinking is filed, never shown

`features/fm-think-no-leak.feature` · [session](fm-think-no-leak.session.md)

**What it does:** The brain deliberates. Deliberation is scratch work that is SUPPOSED to read like "wait, hold on, let me re-read that" — and a human must never see it. But it is the most correctable artifact the bot produces, so it is never dropped: it is filed to a JSONL on the Mini under the Syncthing share, readable from any peer with no SSH. Background: Given the Mini runs mlx_lm.server 0.31.2 with Qwen/Qwen3-14B-MLX-4bit And traces are filed to ~/work/comms/queue/paketti-faq/thinking.jsonl And that path is inside the comms Syncthing folder, so the laptop sees it

**Behaviour (19 scenarios):**

- The exact payload that leaked to Discord now yields no answer, not a trace — `@hw-verified`
- A completed answer ships clean while its thinking is filed silently — `@hw-verified`
- reasoning fields are NEVER promoted to the answer — `@built`
- An untagged trace is still caught — `@built`
- An unclosed think tag leaves no answer behind — `@built`
- Discord is guarded at the last mile — `@built`
- The revise prompt no longer forces the model to deliberate in circles — `@built`
- The filed thinking is extractable and correctable from the laptop — `@hw-verified`
- The 14B reasoner gets a budget it can actually finish in — `@built`
- A correction typed as two quick messages arrives as ONE thought — `@hw-verified`
- Our own provenance header is never fed back to the model — `@built`
- Prompt delimiters are not copied into the answer — `@built`
- Blank messages are never posted — `@built`
- The model's answer is never our own grounding read back to us — `@built`
- A drafted answer cannot cite the changelog by bare date — `@built`
- A "has this been fixed?" question actually reaches the fix — `@hw-verified`
- The thread is re-answered with prose, not deliberation — `@hw-verified`
- A 4-bit 14B still under-uses grounding it was handed — `@todo`
- The circling rate is watched, not just recorded — `@todo`

**Grade:** @built ×11 · @hw-verified ×6 · @todo ×2


<a id="folder-memory"></a>
## Give a folder a voice — the per-folder sidecar triad

`features/folder-memory.feature` · [session](folder-memory.session.md)

**What it does:** As Esa, I want every folder (especially code) to carry an auto-formulated memory of itself — what it is, its load-bearing files, its subsystems — that Finder, Obsidian and the on-device model can all read, so a filesystem becomes navigable and talkable instead of opaque. Background: Given bin/apple-embed produces on-device 512-dim NLEmbedding vectors And the Mini exposes an MLX brain (fm-mlx --raw) and FoundationModels (fm-submit) And the target is a directory readable on this Mac

**Behaviour (8 scenarios):**

- Build the triad for one folder — `@built`
- Auto-formulate the architecture with the on-device model — `@built`
- Talk to the folder — `@built`
- Vibe diff across time — `@built`
- Fold into an Obsidian vault — `@built`
- Understand a whole repository — `@built`
- Self-refresh on commit — `@todo`
- Clustering of topically-homogeneous prose is weak

**Grade:** @built ×6 · @todo ×1


<a id="free-energy-lens-voices"></a>
## Free-energy lens voices are a shared switch

`features/free-energy-lens-voices.feature`

**What it does:** As the operator of Cloudcity's free-energy workflows I want Russell, Bearden, Prigogine, and Hilarion lens output to be controlled by one switch So that cloudcity-llm replies and KeelyNet batch emails can turn those voices on or off together Background: Given the shared switch is named `FREE_ENERGY_LENS_VOICES` And truthy values are `1`, `true`, `yes`, and `on` And falsey values are `0`, `false`, `no`, and `off` And the recognised lens names are `russell`, `bearden`, `prigogine`, and `hilarion`

**Behaviour (7 scenarios):**

- cloudcity-llm includes lens voices for free-energy routed mail — `@built`
- cloudcity-llm suppresses lens voices when the switch is off — `@built`
- KeelyNet batch emails can include the same lens voices — `@built`
- KeelyNet can override the shared switch locally — `@built`
- a requested single lens maps to the same vocabulary — `@built`
- lens voice never weakens source fidelity — `@built`
- off-topic mail does not summon the free-energy lens voices — `@built`

**Grade:** @built ×7


<a id="freellmask-mail-anti-loop-and-video-gate"></a>
## freellmask-mail answers each email once, and never speaks for an untranscribed video

`features/freellmask-mail-anti-loop-and-video-gate.feature` · [session](freellmask-mail-anti-loop-and-video-gate.session.md)

**What it does:** Background: Given the agent polls the cloudcity-llm@agentmail.to inbox every 45 seconds And it only considers messages whose labels do not include "sent"

**Behaviour (9 scenarios):**

- handled message-ids are persisted in insertion order — `@built`
- a message that has been answered can never be answered again — `@built`
- the ledger builds itself on a machine that has never had it — `@built`
- a thread cannot exceed its hourly reply ceiling — `@built`
- an email that is just a YouTube link is a convey request, not a question — `@built`
- a video's page is not the video — `@built`
- the answer about a video comes from the real transcript — `@built`
- a failed transcription job stays retryable — `@built`
- a Short with no speech reports itself — `@untested`

**Grade:** @built ×8 · @untested ×1


<a id="hey-sal-fold"></a>
## Hey Sal folded into AppleBar — hands-free voice over the one routing pipeline

`features/hey-sal-fold.feature` · [session](hey-sal-fold.session.md)

**Behaviour (7 scenarios):**

- applebar://listen and applebar://open route to AppleBar's handler
- listen mode wakes the bar and starts the shared on-device dictation — `@built`
- speaking auto-runs through apple-intent after a silence gap (hands-free)
- no speech at all → release the mic (no energy hog) — `@built`
- the mic BUTTON shares the same hands-free path (no listen-forever) — `@built`
- the fold adds NO second router — voice reuses the existing chain
- the Vocal Shortcut becomes a thin launcher (the user's one edit)

**How it does it:** **Source files:** `AppleBar.swift`, `shared/Dictation.swift`

**Grade:** @built ×3


<a id="homepod-live-climate"></a>
## Read HomePod temperature + humidity from the laptop, live and on demand

`features/homepod-live-climate.feature` · [session](homepod-live-climate.session.md)

**What it does:** The HomePod is a HomeKit thermo-hygrometer. The always-on Mini logs it every 15 min into a Syncthing-shared daily JSONL; any joined Mac reads that file. This card adds a live on-demand path so the laptop can poll the sensor itself (it is a HomeKit client; the HomePod is the hub) and fold the fresh reading back into the same shared log.

**Behaviour (7 scenarios):**

- Default read returns the latest synced reading, offline — `@runtime-verified`
- --live polls the sensor directly via the local Shortcut — `@runtime-verified`
- --live persists the fresh reading so the default read reflects it — `@runtime-verified`
- --live falls back to the synced file when it can't read live — `@built @runtime-untested`
- /climate in mlx-here surfaces a live reading with zero LLM tokens — `@runtime-verified`
- quit leaves mlx-here, with or without a slash — `@runtime-verified`
- `homepod` in the terminal shows the climate (alias repaired) — `@built`

**Grade:** @built ×2 · @runtime-untested ×1 · @runtime-verified ×5


<a id="icdcopy"></a>
## Copy iCloud Drive files and folders to external storage without Finder errors

`features/icdcopy.feature` · [session](icdcopy.session.md)

**Behaviour (26 scenarios):**

- latest folder ranking can be copied by number — `@built`
- folder ranking rows are actual folders — `@built`
- folder ranking defaults to useful iCloud scope and reports scan progress — `@built`
- folder ranking table has stable aligned numeric columns — `@built`
- AbletonCloud can be ranked without typing the long iCloud path — `@built`
- command has the one-and-done shape Esa asked for — `@built`
- copy is resumable after iCloud or disk interruption — `@built`
- verification is checksum-based before success is claimed — `@built`
- Finder metadata does not make a verified copy fail — `@built`
- verification differences are repaired automatically — `@built`
- iCloud files are explicitly materialized before rsync copy — `@built`
- Apple FileProvider enums are hidden in normal use — `@built`
- stalled download progress says elapsed time and timeout remaining — `@built`
- interrupted iCloud download phase exits cleanly — `@built`
- a stuck iCloud download fails with the exact file instead of hanging — `@built`
- slow iCloud completion is allowed to finish in one command — `@built`
- resident bytes count as ready even if FileProvider status is stale — `@built`
- zero visible progress is reported but not treated as failure — `@built`
- wrapper script stays parse-clean after shell edits — `@built`
- source data is never deleted by the wrapper — `@built`
- quoted Terminal-escaped paths are accepted — `@built`
- icdcheck confirms a fully-local folder is PERFECT — `@built @sim-verified`
- icdcheck flags dataless placeholders and in-flight downloads — `@built @sim-verified`
- icdcheck never triggers a download (read-only audit) — `@built`
- icdcheck emits machine-readable JSON for tooling — `@built`
- icdcheck reuses the materializer engine rather than re-rolling status logic — `@built`

**How it does it:** **Key procs:** `icdcopy`

**Grade:** @built ×26 · @sim-verified ×2


<a id="image-playground"></a>
## image-playground — on-device pictures, locally, as the prose's twin

`features/image-playground.feature` · [session](image-playground.session.md)

**What it does:** As someone asking Apple's on-device models about the world, I want a picture drawn from the same prompt to arrive with the words, So that "what does a tiger look like?" gives me the tiger AND the prose.

**Behaviour (16 scenarios):**

- The CLI generates an image from a prompt — `@built`
- Bare prompt → derived filename, auto-open — `@built`
- A failed run never opens a stale same-named file — `@built`
- Transient "image creation failed" is retried, not surrendered — `@built`
- Image Playground distills — it does not honor detailed prompts — `@built`
- Illustrate Selection in Converse (⌘2) inserts a picture inline — `@built`
- The image loop — every message in Converse also draws a picture — `@built`
- A relative -o path lands in the user's cwd, not "/" — `@built`
- Apple's content guardrail is explained, not echoed — `@built`
- A question phrase still yields the subject — `@built`
- --check reports availability and the styles this Mac supports — `@built`
- Headless generation is impossible by Apple's design — `@built`
- /image draws a one-off picture inside Converse, no model call — `@built`
- Illustrate ON pairs every reply with a picture — `@built @untested`
- A picture can't be drawn while Converse is in the background — `@built`
- Images embed without file-system access — `@built`

**How it does it:** **Source files:** `bin/image-create.swift`, `main.swift`

**Grade:** @built ×16 · @untested ×1


<a id="iphone-clip"></a>
## An iPhone photo, on the Mac clipboard, the way you took it

`features/iphone-clip.feature`

**Behaviour (4 scenarios):**

- --watch — YOU shoot it, it lands on the clipboard
- blind mode — the Mac fires a Continuity-Camera grab
- Arm it from the AppleToolbox menu bar
- Disarm / re-arm cycle behaves — `@built`

**Grade:** @built ×1


<a id="iphonemirror-rotated-live-mirror"></a>
## iPhoneMirror — live, auto-oriented, auto-cropped mirror of a USB iPhone screen

`features/iphonemirror-rotated-live-mirror.feature` · [session](iphonemirror-rotated-live-mirror.session.md)

**What it does:** QuickTime Player can mirror a Lightning-connected iOS device, but its Edit ▸ Rotate Left / Rotate Right / Flip items are DISABLED during a live capture session, and its scripting dictionary has no rotate terminology at all. So a phone held in landscape whose iOS UI is locked to portrait cannot be un-rotated live — you can only record and then rotate the file. This app rotates the AVCaptureVideoPreviewLayer instead, so the window is already correct and a one-shot screen recording needs no post-edit.

**Behaviour (33 scenarios):**

- A Lightning iPhone is found at all — `@built @hw-verified`
- The live feed is rotated, which QuickTime cannot do — `@built @hw-verified`
- Orientation is chosen by reading the SCENE, not the chrome — `@built @hw-verified`
- OCR garbage from upside-down chrome is rejected — `@built @hw-verified`
- Camera.app's mode wheel is cropped out by default — `@built @hw-verified`
- Camera.app's ICON control row is also cropped out — `@built @hw-verified`
- Bare invocation just works — `@built @hw-verified`
- Detection does not deadlock the main thread — `@built @untested`
- The device is single-client, and that is explained not swallowed — `@built @untested`
- The crop constant is calibrated, and nudgeable when it is not right — `@built @hw-verified`
- Space hides every other app — `@built @hw-verified`
- It ships the SHARED Help and donate panel, like every app here — `@built @hw-verified`
- It has a real app icon, on the macOS icon grid — `@built @hw-verified`
- There is exactly ONE copy of the app, in /Applications — `@built @hw-verified`
- Several phones at once, ticked on and off from a menu — `@built @hw-verified`
- Unticking a device does not crash the app — `@built @hw-verified`
- Each device remembers its own calibration — `@built @hw-verified`
- Continuity Cameras are offered but never auto-opened — `@built @hw-verified`
- Detection is CONTINUOUS, not one-shot — `@built @hw-verified`
- Menu rows never swap slots — `@built @hw-verified`
- A device row never vanishes while you reach for it — `@built @hw-verified`
- A saved calibration seeds, it does not lock — `@built @hw-verified`
- A yanked cable leaves the window alone — `@built @hw-verified`
- The screen-capture assistant is kept alive — `@built @hw-verified`
- Continuity Cameras get no Vision pass at all — `@built @hw-verified`
- Layout is one keypress before a take — `@built @hw-verified`
- ⌘0 rescues minimised windows — `@built @hw-verified`
- Front-window commands hit the window you clicked — `@built @hw-verified`
- The picture does not flip on its own — `@built @hw-verified`
- Orientation can be hard-locked for a demo — `@built @untested`
- A Continuity Camera that flaps does not flap its window — `@built @hw-verified`
- Device enumeration must be LIVE, not a per-process snapshot — `@built @hw-verified`
- recburn can bake the phone feed in directly — `@todo`

**Grade:** @built ×32 · @hw-verified ×29 · @todo ×1 · @untested ×3


<a id="mailfe-convey-belt"></a>
## mailfe is a reusable Convey belt from source material to emailed analysis

`features/mailfe-convey-belt.feature`

**What it does:** As the operator of the personal archive I want any text-bearing input to move through a typed analysis belt So that KeelyNet files, pasted notes, PDFs, images, and future sources can reuse the same extraction, analysis, rendering, and delivery stages Background: Given the belt stages are named `intake`, `extract_text`, `assemble_packet`, `analyze`, `render`, and `deliver` And `process` remains the separate media/YouTube-to-transcript belt And `mailfe` is the current CLI front door for this belt And `mail-free-energy-analysis` is the current Cloudcity analysis-and-email stage And `FREE_ENERGY_LENS_VOICES` controls Russell, Bearden, Prigogine, and Hilarion lens sections

**Behaviour (14 scenarios):**

- the front door accepts stdin as a source — `@built`
- the front door accepts one local file — `@built`
- the extraction stage normalizes many file types to text — `@built`
- unknown binary files fail before analysis — `@built`
- multiple sources can be combined into one packet — `@built`
- analysis is a stage, not the front door — `@built`
- visual material gets a treatment, not just OCR text — `@built`
- generated whiteboards are optional visual derivatives — `@built`
- source images are carried as email attachments — `@built`
- rendering turns Markdown into rich email HTML — `@built`
- delivery is an interchangeable output stage — `@built`
- the belt distinguishes analysis from transcription — `@built`
- the belt is reusable by other Convey front doors — `@built`
- Convey names each stage as a first-class verb — `@todo`

**Grade:** @built ×13 · @todo ×1


<a id="markdown-attributed"></a>
## AppleBar parses markdown in its result pane

`features/markdown-attributed.feature`

**Behaviour (4 scenarios):**

- headings, bold, code, and rules render (not raw markers)
- AppleBar shows the rendered markdown, not the raw text — `@built`
- the karaoke speak-back settles on the same render
- it is the attributed sibling of the HTML renderer, not a duplicate

**How it does it:** **Source files:** `shared/MarkdownAttributed.swift`, `shared/markdown-attributed-tests.swift`, `apple-bar/AppleBar.swift`

**Grade:** @built ×1


<a id="me-address"></a>
## Home address from the Contacts me-card

`features/me-address.feature` · [session](me-address.session.md)

**What it does:** Asking where my home is returns my address, not the room temperature.

**Behaviour (6 scenarios):**

- "where is my home" routes to the address lookup, not the thermostat
- Climate questions still route to the HomePod sensor
- The address resolves from the me-card, or by name if none is set — `@built`
- Resolve once, then serve from cache (no repeated Contacts prompts)
- The address reads through unstyled (whitelabel passthrough) — `@built`
- It uses Contacts AppleScript, not the network

**Grade:** @built ×2


<a id="me-location"></a>
## Where am I right now — device-presence geolocation for a desktop Mac

`features/me-location.feature` · [session](me-location.session.md)

**Behaviour (9 scenarios):**

- the Workspace LAN fingerprint resolves to the Workspace address
- no known place → print nothing, exit 1 (caller falls back gracefully) — `@built`
- gateway_mac beats peers beats ssid — `@built`
- --learn captures the current signature into a named place — `@built`
- the Home LAN fingerprint resolves to Home, and the commute partner flips
- a named Bonjour device (Time Capsule) is a location signal — lazily browsed
- --route resolves the whole route in one call (origin + destination)
- commute_to makes "here" generate "there" — the clever-Directions seam
- home is a constant, here is a variable — they are different questions

**Grade:** @built ×3


<a id="mlx-agent-tool-loop"></a>
## The on-device agentic tool-calling loop on the Mini's MLX brain

`features/mlx-agent-tool-loop.feature` · [session](mlx-agent-tool-loop.session.md)

**What it does:** As Esa, I want the local MLX model to DRIVE the convey conveyor belt — decide to search my notes, open a file's molecule, OCR an image — instead of me wiring each step, so Convey becomes "a CLI the on-device model drives" (the WWDC26 session 232 thesis), not just "a CLI a human drives". Both halves already existed: the MLX-LM Server speaks the OpenAI tool-calling protocol, and convey has a verb catalog; this wires them into a loop. Background: Given the Mini serves a tool-calling chat model (Qwen3-4B) at FM_MLX_HOST And bin/mlx-agent registers SAFE read-only convey+apple verbs as OpenAI tools And arm_apple.build_system arms the governing skill of the folder as the system prompt

**Behaviour (10 scenarios):**

- the loop executes a tool then returns a final answer — `@built @sim-verified`
- the SAFE tool registry runs the real verbs read-only — `@built @hw-verified`
- the sandbox refuses paths outside $HOME — `@built @hw-verified`
- --dry-run lists the registry and mlx-here --agent routes here — `@built @hw-verified`
- a real task drives the belt end-to-end on the Mini — `@built @hw-verified`
- long files are paged (a bug the live run surfaced) — `@built @hw-verified`
- transient 502/503 reload windows are retried (a 2nd bug the live run surfaced) — `@built @hw-verified`
- the queue twin runs the loop on the Mini (Comms/Syncthing path) — `@built @sim-verified`
- the loop refuses an answer that cites an un-opened file (grounding enforcement) — `@built @hw-verified`
- the final answer is shown via the ONE shared presenter (DRY) — `@built @sim-verified`

**Grade:** @built ×10 · @hw-verified ×7 · @sim-verified ×3


<a id="rec-audio"></a>
## Post-process a screen recording's audio (split / flatten)

`features/rec-audio.feature`

**Behaviour (4 scenarios):**

- split writes each audio track to its own .m4a  (ran live) — `@hw-verified`
- flatten mixes all audio into one track, video passthrough  (ran live) — `@hw-verified`
- version-safe export runs on Ventura+ with no deprecation warnings  (ran live) — `@hw-verified`
- rec --mic auto-runs flatten to make a YouTube-ready file  (ran live) — `@hw-verified`

**How it does it:** **Source files:** `rec-audio.swift`, `screen-audio-record.swift`

**Grade:** @hw-verified ×4


<a id="rec-subtitle"></a>
## Subtitle a screen recording (.srt sidecar + burn-in)

`features/rec-subtitle.feature` · [session](rec-subtitle.session.md)

**Behaviour (18 scenarios):**

- transcribe → .srt sidecar via whisp (Whisper)  (ran live) — `@hw-verified`
- --burn hard-paints the subtitles into the video  (ran live) — `@hw-verified`
- version-safe burn export (Ventura+)  (ran live) — `@hw-verified`
- --mini routes transcription to the Mac Mini (keeps CPU off this mac) — `@built`
- one-command pipeline — rec --mic --pip --burn — `@built`
- transcription shows progress and elapsed time — `@built`
- burn-in reports its export time — `@built`
- subtitle glyphs keep their counters open (no more muddy a/e)  (ran live) — `@hw-verified`
- known mishearings are rewritten to the canonical spelling  (ran live) — `@hw-verified`
- mishearings NOBODY listed are caught by sound  (ran live) — `@hw-verified`
- ordinary speech is never rewritten  (ran live) — `@hw-verified`
- the same vocabulary biases Whisper before it decodes — `@built`
- the vocabulary is a file, editable without a rebuild  (ran live) — `@hw-verified`
- the rules are checked headlessly, so a regression fails the build  (ran live) — `@hw-verified`
- "Paketti" came back as "Pocket to" and every guard let it through  (2026-08-27) — `@hw-verified`
- Whisper's own capitalisation is what makes the fix safe  (2026-08-27) — `@hw-verified`
- list the letters, never the spacings  (2026-08-27) — `@hw-verified`
- fixing a line once and reporting it twice  (caught + fixed 2026-08-27) — `@hw-verified`

**How it does it:** **Source files:** `rec-subtitle.swift`, `screen-audio-record.swift`

**Grade:** @built ×5 · @hw-verified ×13

**Commits:** `4725ebc` (srt + burn-in), 1705700 (--mini Mini routing + one-command --burn chain).


<a id="recburn-abort"></a>
## Two presses of the same key always get the shell back

`features/recburn-abort.feature` · [session](recburn-abort.session.md)

**Behaviour (9 scenarios):**

- the second Ctrl-C abandons transcription and exits at once  (measured 2026-08-22) — `@hw-verified`
- killing the child is not enough — the tree has to go  (measured 2026-08-22) — `@hw-verified`
- what is kept and what is deleted  (measured 2026-08-22) — `@hw-verified`
- the escape hatch is announced when it becomes true  (2026-08-22) — `@hw-verified`
- the watchdog fires when finishWriting never returns  (observed 2026-08-22) — `@hw-verified`
- an abort must never corrupt the .mov it is abandoning — `@built`
- SIGTERM climbs the same ladder — `@built`
- one press is never destructive
- the manifest says so

**Grade:** @built ×2 · @hw-verified ×5


<a id="recburn-automation-surfaces"></a>
## Trigger recburn from anywhere through one seam, and hand off a typed result

`features/recburn-automation-surfaces.feature` · [session](recburn-automation-surfaces.session.md)

**Behaviour (14 scenarios):**

- the engine emits a typed manifest that round-trips into the app's decoder  (contract ran) — `@hw-verified`
- on stop the engine writes <stem>.recburn.json and prints its path — `@built`
- the app reads the manifest instead of scraping prose, with a two-level fallback — `@built`
- recburn:// is the single control seam and routes toggle/start/stop  (compiled + registered) — `@hw-verified`
- Services menu exposes Toggle/Start/Stop, assignable to a global hotkey — `@built`
- App Intents surface Toggle/Start/Stop to Shortcuts + Siri — `@built`
- recburn-url is the portable seam for hardware buttons + shell  (installed) — `@hw-verified`
- this card adds entrances + an exit, not new capture mechanics
- the app persists the completed recording to one stable manifest for chaining — `@built`
- value intents return the recording as chainable Shortcuts values — `@built`
- "Record" is the start action's title  (compiled + verified in binary) — `@hw-verified`
- recburn-youtube uploads a recording and returns its URL — `@built`
- Publish to YouTube is a first-class chainable action — `@built`
- sane upload defaults — unlisted, timestamp title, category, caption track — `@built`

**How it does it:** **Source files:** `bin/screen-audio-record.swift`

**Grade:** @built ×9 · @hw-verified ×4


<a id="recburn-loudness"></a>
## Deliver a recording at a normal listening level, measured not guessed

`features/recburn-loudness.feature` · [session](recburn-loudness.session.md)

**Behaviour (9 scenarios):**

- the absolute peak is the wrong thing to normalise against  (measured 2026-08-14) — `@hw-verified`
- whole-file RMS is also wrong, because a screencast is mostly pauses  (2026-08-14) — `@hw-verified`
- the whole thing is lifted, on Esa's own material  (ran live 2026-08-14) — `@hw-verified`
- the ceiling is a ceiling — a bug the tool's own output caught  (fixed 2026-08-14) — `@hw-verified`
- it happens in flatten, so the subtitled video inherits it  (ran live 2026-08-14) — `@hw-verified`
- near-silence is not amplified into hiss  (observed live 2026-08-14) — `@hw-verified`
- the volume is SHOWN, not just changed  (ran live 2026-08-14) — `@hw-verified`
- delivered on the real 78-minute recording  (ran live 2026-08-14) — `@hw-verified`
- recburn does it automatically, on every take  (ran live 2026-08-14) — `@hw-verified`

**Grade:** @hw-verified ×9


<a id="recburn-redact"></a>
## Redact a region of a finished recburn video without re-rendering it

`features/recburn-redact.feature` · [session](recburn-redact.session.md)

**Behaviour (29 scenarios):**

- only the keyframe span that contains the frames is re-encoded  (real file, 2026-08-13) — `@hw-verified`
- the audio track is remuxed, never cut and never re-encoded  (real file, 2026-08-13) — `@hw-verified`
- a cut point is MEASURED, never computed from timestamps  (bug found + fixed 2026-08-13) — `@hw-verified`
- the container's own frame count can be a lie  (observed 2026-08-13) — `@hw-verified`
- the head is cut by frame count, not by -to  (bug found + fixed 2026-08-13) — `@hw-verified`
- the redaction is gated on FRAME NUMBER, not on time  (bug found + fixed 2026-08-13) — `@hw-verified`
- never pass both -map 0:v:0 and -map "[vout]"  (bug found + fixed 2026-08-13) — `@hw-verified`
- segments are joined as MPEG-TS, not MOV  (real file, 2026-08-13) — `@hw-verified`
- a frame shift is caught even though the counts add up  (verified both ways 2026-08-13) — `@hw-verified`
- the coverage is a mosaic THEN a blur, not a soft smudge  (real file, 2026-08-13) — `@hw-verified`
- --find needs no times at all  (run live 2026-08-13) — `@hw-verified`
- --find samples at FULL resolution and ACCURATE, both for a measured reason  (2026-08-13) — `@hw-verified`
- the •••• mask is not four bullets  (bug found + fixed 2026-08-13) — `@hw-verified`
- the first full sweep produced 3 false windows out of 4  (found + fixed 2026-08-13) — `@hw-verified`
- the redaction defeats OCR, proven by pointing --find at the output  (2026-08-13) — `@hw-verified`
- --find prints the sampling gap instead of implying completeness  (2026-08-13) — `@hw-verified`
- a matched secret is truncated in the report  (2026-08-13) — `@hw-verified`
- --scan finds WHICH frames, --probe finds WHERE  (both run live 2026-08-13) — `@hw-verified`
- the source file is never touched  (enforced 2026-08-13) — `@hw-verified`
- verification is fast enough to always run  (measured 2026-08-13) — `@hw-verified`
- --method black and --method blur — `@built`
- a window that reaches the first or last frame of the file — `@built`
- a source with no audio track — `@built`
- the presets are measured, not universal
- --find is triage, not a guarantee
- this redacts the copy, not the past
- --find-text hunts a name, not just the built-in secret patterns  (2026-08-14) — `@hw-verified`
- the splice produces a silent 2-frame A/V drift on some files  (FOUND 2026-08-14) — `@hw-verified`
- the GOP length is measured, not assumed  (2026-08-14) — `@hw-verified`

**Grade:** @built ×3 · @hw-verified ×23

**Commits:** `a8e562d` recburn-redact: take one second of a screencast back, without


<a id="recburn-stream-recovery"></a>
## The only thing that ends a take is the person making it

`features/recburn-stream-recovery.feature` · [session](recburn-stream-recovery.session.md)

**Behaviour (8 scenarios):**

- dropped frames do not stop anything  (measured 2026-08-22) — `@hw-verified`
- killing replayd no longer ends the take  (measured 2026-08-22) — `@hw-verified`
- the interruption is on the record, not just in the scrollback  (2026-08-22) — `@hw-verified`
- why writing into the same file works at all
- two failures are deliberately NOT retried through — `@built`
- giving up is unmistakable — `@built`
- a cut-short take does not silently cost you the render  (2026-08-22) — `@hw-verified`
- what is still stale

**Grade:** @built ×2 · @hw-verified ×4


<a id="recburn-voice-balance"></a>
## Lift the voice against the app audio, measured not guessed

`features/recburn-voice-balance.feature` · [session](recburn-voice-balance.session.md)

**Behaviour (10 scenarios):**

- normalisation cannot fix this, and the delivered file proved it  (2026-08-27) — `@hw-verified`
- the two audio tracks do not start at the same instant  (measured 2026-08-27) — `@hw-verified`
- the mic gain is whatever it takes, not a number someone typed  (2026-08-27) — `@hw-verified`
- it does not distort, which is the whole constraint  (re-measured 2026-08-27) — `@hw-verified`
- the measure pass and the write pass run the identical chain  (2026-08-27) — `@hw-verified`
- --no-rebalance is bit-exact with the old behaviour  (2026-08-27) — `@hw-verified`
- one audio track, or a mic that was never used, is left alone  (2026-08-27) — `@hw-verified`
- the balance decision refuses the three ways it could be harmful
- the ducker ducks on its attack and recovers on its release
- what the reported ducking percentage does and does not mean

**Grade:** @hw-verified ×7


<a id="recburnclick"></a>
## Burn a live click counter into a screen recording

`features/recburnclick.feature` · [session](recburnclick.session.md)

**Behaviour (13 scenarios):**

- counting clicks needs NO event tap and NO Accessibility prompt  (probed live 2026-07-29) — `@hw-verified`
- the number is really in the pixels  (ran live 2026-07-29) — `@hw-verified`
- corner and label are honoured  (ran live 2026-07-29) — `@hw-verified`
- plain `rec` is unchanged  (ran live 2026-07-29) — `@hw-verified`
- the counter goes UP as you click — `@built`
- --clicks composes with --pip and --mic — `@built`
- recburnclick inherits RECBURN's settings, not rec's  (ran live 2026-07-29) — `@hw-verified`
- a chained wrapper can be subtracted from  (ran live 2026-07-29) — `@hw-verified`
- the click counter is a RecBurn.app menu setting with its own corner — `@built`
- the counter can be zeroed mid-recording  (ran live 2026-08-10) — `@hw-verified`
- the counter really does go UP on real clicks  (observed live 2026-08-10) — `@hw-verified`
- any trigger can fire the reset — it is a signal, not a keystroke  (ran live 2026-08-10) — `@hw-verified`
- ⌃⌥⌘Space zeroes the counter from anywhere — `@built`

**Grade:** @built ×4 · @hw-verified ×9


<a id="screen-audio-record"></a>
## Record screen + system audio to one .mov with no loopback driver

`features/screen-audio-record.feature` · [session](screen-audio-record.session.md)

**Behaviour (20 scenarios):**

- single-app audio isolation captures screen + only that app's sound  (ran live) — `@hw-verified`
- Ctrl-C stops cleanly and finalizes a playable file  (ran live) — `@hw-verified`
- --list enumerates displays and audible apps  (ran live) — `@hw-verified`
- whole-display capture with all system audio — `@built`
- optional microphone as a second audio track — `@built`
- --out omitted writes into the CURRENT folder  (ran live) — `@hw-verified`
- rec is the one-word terminal launcher  (ran live) — `@hw-verified`
- AppleToolbox 🧰 ▸ Record Screen & Audio is a start/stop toggle — `@built`
- mic toggles on/off live during a recording via SIGUSR1  (ran live) — `@hw-verified`
- an unused mic track does not break finalization  (ran live) — `@hw-verified`
- --reveal opens the file in Finder on finalize  (ran live) — `@hw-verified`
- AppleToolbox ⌃⌥⌘R start/stop with a Sound-only vs Sound+Mic chooser — `@built`
- AppleToolbox ⌃⌥⌘M toggles the mic live during a recording — `@built`
- --pip bakes the webcam into a corner as a circle  (ran live) — `@hw-verified`
- --burn runs the whole pipeline in one command — `@built`
- on-stop summary reports the recording length and mic status  (ran live) — `@hw-verified`
- start banner states plainly whether the mic is recording  (ran live) — `@hw-verified`
- q + Enter stops the recording as an alternative to Ctrl-C — `@built`
- Sequoia re-prompts screen-recording permission
- The terminal says when frames are being dropped, and names the thief — `@built @untested`

**How it does it:** **Source files:** `bin/screen-audio-record.swift`

**Grade:** @built ×8 · @hw-verified ×11 · @untested ×1


<a id="secret-scan"></a>
## Refuse to commit an account id, bank last-4, key or token

`features/secret-scan.feature`

**Behaviour (5 scenarios):**

- it blocks the exact pair that leaked  (ran live 2026-08-16) — `@hw-verified`
- the patterns are imported, never redefined  (2026-08-16) — `@hw-verified`
- two of those patterns are wrong for a repo and are dropped  (measured 2026-08-16) — `@hw-verified`
- deliberate examples can be kept  (2026-08-16) — `@hw-verified`
- it reads what will be COMMITTED, not what is on disk  (2026-08-16) — `@hw-verified`

**Grade:** @hw-verified ×5


<a id="sesh"></a>
## The master session list is bootable with one word

`features/sesh.feature`

**What it does:** As someone who loses a day's worth of Claude Code sessions to every restart I want one verb that saves them when they exist and restores them when they don't So that a restart costs nothing and I never have to remember what was open

**Behaviour (11 scenarios):**

- Sessions are open, so sesh saves them — `@built @hw-verified`
- Nothing is open, so sesh boots the snapshot — `@built @hw-verified`
- Never resume a session that is already open — `@built @hw-verified`
- Never overwrite a good snapshot with an empty one — `@built @hw-verified`
- Folders with spaces survive the round trip — `@built @hw-verified`
- Dry run shows the plan without launching anything — `@built @hw-verified`
- Session discovery has exactly one implementation — `@built @hw-verified`
- A folder that no longer exists is skipped, not fatal — `@built @untested`
- iTerm launch failure falls back to printed commands — `@built @untested`
- Restore window/tab layout, not just the session set — `@todo`
- Boot sessions that were closed rather than only those live at save — `@todo`

**Grade:** @built ×9 · @hw-verified ×7 · @todo ×2 · @untested ×2


<a id="shell-toggles"></a>
## Desktop & Dock visibility from the command bar

`features/shell-toggles.feature`

**Behaviour (3 scenarios):**

- "hide … desktop" and "hide the dock" route to their actions
- desktop hides (or shows) all Desktop icons — `@built`
- dock auto-hides (or stays shown) — `@built`

**Grade:** @built ×2


<a id="spotlight-suggestions"></a>
## Live Spotlight-style suggestions in AppleBar

`features/spotlight-suggestions.feature` · [session](spotlight-suggestions.session.md)

**What it does:** Typing ranks the capabilities in real time; arrow keys pick; Return runs the pick.

**Behaviour (5 scenarios):**

- Typing shows a ranked, navigable suggestion list — `@built`
- The picked suggestion runs exactly that action (no re-routing)
- One catalog, two readers (DRY)
- More Apple capabilities recognised
- "?" stays converse, not a suggestion

**How it does it:** **Source files:** `AppleBar.swift`

**Grade:** @built ×1


<a id="usb-port-revive"></a>
## Recover a wedged USB-C port without losing the work on the machine

`features/usb-port-revive.feature` · [session](usb-port-revive.session.md)

**What it does:** As someone whose second USB-C port intermittently goes completely dead I want to tell the two failure modes apart and try every reboot-free lever So that a restart is the last resort rather than the first, and so that when a restart IS unavoidable it does not cost me eight Claude Code sessions

**Behaviour (14 scenarios):**

- Classify a fault that only a restart recovered — `@built @hw-verified`
- launchd service churn must not be mistaken for bus activity — `@built @hw-verified`
- An ordinary idle gap must not be read as a wedge — `@built @hw-verified`
- Software replug of a device or hub that wedged — `@built @hw-verified`
- Root is not assumed to be required — `@built @hw-verified`
- Rung 1 is honest about not applying to a dead port — `@built @hw-verified`
- Sleep/wake as the only reboot-free lever on the port hardware — `@built @untested`
- Rung 2 never fires by accident — `@built @hw-verified`
- Tell a dead port apart from an empty port — `@built @hw-verified`
- The watch predicate must match LIVE kernel USB lines — `@built @hw-verified`
- Watch must survive silence, because silence is the finding — `@built @hw-verified`
- A restart must not cost the day's sessions — `@built @hw-verified`
- Automatically snapshot sessions when a wedge is detected — `@todo`
- Establish the root cause rather than only recovering from it — `@todo`

**Grade:** @built ×12 · @hw-verified ×11 · @todo ×2 · @untested ×1


<a id="voicebox-speak-toggle"></a>
## One button for "Claude talks to me" (server + speech together)

`features/voicebox-speak-toggle.feature` · [session](voicebox-speak-toggle.session.md)

**What it does:** As Esa, when I enable Claude speech in AppleToolbox it both works and is on — the Voicebox server is started for me if it was down, and Claude is set to talk. I never have to check whether the server is running. Disabling silences Claude.

**Behaviour (9 scenarios):**

- Default is ON when no state file exists
- Enabling starts the server if it is down, then sets Claude talking
- Enabling when the server is already up just sets the flag
- Disabling silences Claude and cuts current playback
- status reports both halves and the effective outcome
- toggle does the sensible thing from any state
- The AppleToolbox row shows the COMBINED truth in three states — `@built`
- This is NOT the server-side speaker-claim gate
- Server detection is by listening port, not a brittle cmdline match

**How it does it:** **Source files:** `~/.claude/hooks/voicebox_speak.py`, `topbar/AppleToolbox.swift`

**Grade:** @built ×1


<a id="voicebox-worker"></a>
## voicebox-worker — a TTS queue that survives the worker dying mid-job

`features/voicebox-worker.feature` · [session](voicebox-worker.session.md)

**What it does:** As the operator of the Mini's clone-voice render pipeline, I want a job the worker crashed on to be retried, not silently lost, And one poison job to never wedge the whole queue, So that "render complete" means every sentence is really rendered or really failed.

**Behaviour (6 scenarios):**

- A job the worker died on mid-synth is re-queued at boot — `@built`
- A poison input that orphans every time is capped, never wedges the queue — `@built`
- A non-JSON (.txt) job's content is preserved on recovery — `@built`
- A stalled generation is bounded and cancelled so one job can't freeze the queue — `@built`
- pending counts only UNCLAIMED jobs — an orphan reads as done until next boot — `@built`
- The guardian can kickstart the worker before its own synth budget — `@built`

**Grade:** @built ×6


<a id="voicememo-audio-tag-to-wav"></a>
## A Voice Memo tagged #audio becomes a .wav sample on disk

`features/voicememo-audio-tag-to-wav.feature` · [session](voicememo-audio-tag-to-wav.session.md)

**What it does:** The live submitter is the Swift VoiceMemoPipeline inside AppleToolbox (the menu-bar app with Full Disk Access). It already routes #process memos to whisp for transcription. #audio is a SECOND, independent output: the recording's audio, transcoded to a WAV sample under ~/Music/samples/VoiceMemos/, named by the recording's own timestamp + a slug of its title. Background: Given AppleToolbox is running with Full Disk Access And it polls CloudRecordings.db every 30 s And ffmpeg is installed at /opt/homebrew/bin/ffmpeg

**Behaviour (4 scenarios):**

- a downloaded memo tagged #audio is exported to WAV — `@hw-verified`
- the export fires automatically once a deferred memo downloads — `@built`
- #audio and #process on the same memo both fire — `@built`
- idempotent + atomic — `@built`

**Grade:** @built ×3 · @hw-verified ×1

