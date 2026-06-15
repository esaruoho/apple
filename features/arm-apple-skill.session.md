# Session — arm-apple-skill

The spawning conversation for `features/arm-apple-skill.feature`. Faithful, not flattering.

## How to get back
- Transcript: this Claude Code session in `/Users/esaruoho/work/apple`
- Date: 2026-06-15
- Resume the work, not the chat: `cd ~/work/apple && mlx-here`

## The ask (Esa, verbatim intent)
> We have, in Convey, a method of running an MLX LM with "What would Bearden say"
> and "What would Russell say". Can we make fm-chat actually arm the Apple skill —
> `fm-chat --apple --mlx` — so the knowledge of the Apple skill is within it, so
> we're not spinning our wheels. Make it possible to be in `~/work/apple` and run
> `mlx-here` (or `mlx-chat`, same idea as `fm-chat --mlx`), so the context of the
> folder I'm on is received, the memory of the skills is loaded, and the answers
> can be gotten.

## What I studied first (so as not to re-roll)
- Convey's roundtable arms personas via `convey/knows.py` → `retrieve(corpus, query)`:
  a persona's `knows:` points at a markdown file or dir; the few passages most
  relevant to the turn (lexical overlap, cached, zero-dep) are injected into the
  prompt. "Bearden" answers from the 652-claim Bearden ledger, not its weights.
- The Apple skill's knowledge: `skill.md` (11 KB identity + tool order + hard
  rules), `wiki/INDEX.md` (30 KB catalog — auto-generated), `wiki/` (135 content
  pages, 1.2 MB). Far too big to dump → retrieval is the right tool.

## Decisions
- **Reuse `convey.knows.retrieve`** (DRY), don't re-roll it. `bin/arm_apple.py`
  imports it; degrades gracefully to identity-only if convey is absent.
- **`--apple` flag on `fm-chat`** (works for both MLX and FM brains), not a fork.
  Identity → system instruction (set once). Knowledge → retrieved per turn.
- **`bin/mlx-here`** = `fm-chat --mlx --apple --cwd "$PWD"`; `mlx-chat` is a symlink.
  `--fm` switches to the FoundationModels brain.
- **Skip the catalogs in retrieval.** First cut over the whole `wiki/` dir let
  `INDEX.md`'s dense bullet lists out-score real content. Fixed: retrieve from the
  content subdirs (`concepts/entities/lessons/devices/operations`) only.

## Verified live (Mini, 2026-06-15)
- Both brains online first: `FM online` (10 s), `MLX online` (cold→warm).
- `mlx-here --quiet` from `~/work/apple`: banner "🍎 Apple skill armed", identity
  loaded, retrieval ON.
- Grounding rule HELD: asked for the clipboard tool, model answered ONLY from the
  retrieved knowledge and refused to invent a tool name (round-trip 73 s — Qwen3-4B
  thinking mode is verbose; the 180 s timeout covers it).

## Two bugs Esa hit, fixed same session (2026-06-15)
1. **Ctrl-C crashed the REPL.** Pressing Ctrl-C while a reply was being spoken
   raised an uncaught `KeyboardInterrupt` deep in `speak_reply`'s
   `subprocess.communicate()` → full traceback. Fix: catch `KeyboardInterrupt`
   inside `speak_reply` (terminate the speaker, print "(speech stopped)", return)
   AND around the `ask`/`ask_mlx` call in the turn body (cancel the turn, back to
   prompt). A second Ctrl-C at the empty prompt still exits with "bye."
2. **Wrong voice — macOS `say`/Eddy ("1980s robot, German accent").** fm-chat and
   fm-mlx were speaking through `say-karaoke` (AVSpeechSynthesizer). Esa wants
   **Voicebox** — the same Kokoro/Heart voice the Claude Stop hook uses. Fix: new
   `bin/voicebox-say` (local Voicebox POST /speak → poll → afplay, honors the
   `~/.config/voicebox/speak.state` switch, writes the shared `/tmp/voicebox-speak.pid`
   so `/voiceboxstop` + ⇧⌥⌘. also stop it). Both `fm-chat.speak_reply` and
   `fm-mlx` now call it instead of say-karaoke. Verified: spoke in Heart voice;
   SIGTERM mid-playback killed afplay cleanly, no traceback.

## Live-data hook + voice correction (2026-06-15, follow-up)
- **Live-data hook** (Esa: "add a small live-data hook so armed chats can answer
  bin/homepod style sensor questions"). New `bin/live_data.py`: routes a query to
  `homepod-now` (ambient room climate) and the Syncthing-published
  `machine-card-<host>.json` cards (per-machine CPU/GPU die temp, thermal pressure,
  load, memory, uptime, battery, top procs). `arm_apple.augment_prompt` injects a
  LIVE DATA block FIRST; the system prompt tells the model to use those exact
  numbers and not claim "no sensor access". "you / running on" resolves to the Mini
  (where the model runs). Verified: Mini → CPU die 102.7°C; room → 24.35°C/51.5%;
  non-live question → no injection.
- **Voice correction.** I first switched the speaker to Voicebox (`bin/voicebox-say`),
  but Esa clarified: "say-karaoke would have been perfect, had it not been Eddy —
  it should be the pro premium one we already use." So the speaker reverted to
  say-karaoke with **Zoe (Premium)** (the premium voice convey's roundtable uses),
  in both `fm-chat.speak_reply` and `fm-mlx` (default `FM_MLX_VOICE`/`--voice` Zoe).
  The Ctrl-C hardening stays. `bin/voicebox-say` is left in place as an available
  opt-in local-Voicebox speaker, but is no longer wired as the default.

## Playback control: stop / pause / resume (2026-06-15, follow-up)
Esa: "i use ⌃⌥⌘. to stop any audio. including this. and i should be able to halt
and pause and continue later, on reading of it. and i should be able to interrupt
it, too." The chat speech (say-karaoke) ignored ⌃⌥⌘. because voicebox-stop only
killed the Voicebox afplay path, and say-karaoke wrote no PID and handled no signals.
- `say-karaoke.swift`: writes `/tmp/say-karaoke.pid`; retained DispatchSource signal
  handlers — SIGTERM/SIGINT = stop+exit (cleanup pidfile), SIGUSR1 = pause⇄resume at
  word boundary. GOTCHA fixed live: the stop sources were first created inside a
  `for` loop → went out of scope → cancelled → the SIG_IGN'd signal was silently
  ignored (stop did nothing). Fixed by top-level `let termSrc`/`intSrc`.
- `voicebox-stop`: now also kills /tmp/say-karaoke.pid + `pkill -f .cache/apple/say-karaoke`.
- `bin/speech-toggle`: sends SIGUSR1 → pause/resume.
- AppleToolbox: new global hotkey **⌃⌥⌘,** (id 8, kVK_ANSI_Comma) → speech-toggle,
  companion to ⌃⌥⌘. (id 2) → voicebox-stop. Esa chose comma (pairs with period).
  Built + relaunched; registration logged no failure. Verified end-to-end: pause
  keeps the process alive and silent, resume continues, stop exits clean + removes
  pidfile.

## Known limitation / next step
- Lexical retrieval missed `md-to-clipboard`/`rtfc` for one phrasing though the
  page exists. The skill itself flags the upgrade: NLEmbedding semantic retrieval
  (`bin/apple-embed` / `apple-semantic-match`, shared `~/.vault-embeds/` cache) is
  the recall improvement. Left for v2 — v1 is honest-when-unsure, which is the
  correct failure mode.
