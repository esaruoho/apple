# Session — fm-mlx-dry (the vibe diff that spawned the card)

Faithful, not flattering. This is the conversation that drove
`features/fm-mlx-dry.feature` and its innards.

## How to get back
- Transcript: `file:///Users/esaruoho/.claude/projects/-Users-esaruoho-work-convey/a84dce1e-3f77-4adc-b2b0-a98153cf7553.jsonl`
- Session ID: `a84dce1e-3f77-4adc-b2b0-a98153cf7553`
- Resume: `claude --resume a84dce1e-3f77-4adc-b2b0-a98153cf7553`
- When: 2026-06-10, ~16:55 EEST (2026-06-10T13:55Z)
- Working dir at the time: `/Users/esaruoho/work/convey` (the change lives in `/Users/esaruoho/work/apple`)

## The request (verbatim)
> the fm-mlx should be DRY principle. 1. Say says it. 2. Karaoke is used. 3. Markdown is exists.

## How I read it
Three capabilities fm-mlx should *reuse* rather than reinvent:
1. **Say says it** — the reply gets spoken (the `say` skill's voice, Eddy).
2. **Karaoke is used** — speak via the existing `bin/say-karaoke` (per-word highlight),
   not a fresh `say` call.
3. **Markdown is exists** — a Markdown renderer already existed (inline in
   `fm-converse`); reuse it, don't write a second one.

## What I found before touching anything
- `fm-mlx` was a bare `curl … | python -c 'print(content)'` — no rendering, no speech.
- The Markdown renderer (`md_to_ansi` + `emit_reply`) lived **only** inside
  `fm-converse` — a duplicate waiting to happen. That was the real DRY smell.
- `bin/say-karaoke` already speaks + emits JSON word ranges; it takes `--voice`.
- `Eddy` is a real `AVSpeechSynthesisVoice` name (checked on this machine), and it's
  the voice the `say` skill standardises on ("friendly robot").

## What I did
1. **Extracted** the renderer into `bin/fm_render.py` — `md_to_ansi`, a new
   `md_to_plain` (strip markers for speech so it doesn't say "asterisk asterisk"),
   `emit_reply`, and a `--plain` CLI.
2. **Refactored** `fm-converse` to `from fm_render import emit_reply` and deleted its
   ~25-line inline copy. (DRY: one renderer now.)
3. **Rewrote** `fm-mlx` to keep its curl transport but route the reply through
   `fm_render` (terminal) and, on `--say`, pipe the plain form into `say-karaoke
   --voice Eddy`. Added `--voice` / `FM_MLX_VOICE` override and `--help`.
4. Regenerated `bin/INDEX.md`; emitted this triad.

## Decisions / judgement calls (so the next reader knows why)
- **Speaking is opt-in (`--say`), not default.** "Say says it" implies speech, but a
  CLI that always talks would break piping and surprise. Opt-in is the safe default;
  trivially promoted to default later if Esa wants it always-on.
- **Voice = Eddy by default**, matching the `say` skill — ties all three reused
  pieces together. Overridable with `--voice` / `$FM_MLX_VOICE`.
- **Kept `_italic_` (single-underscore) unhandled** in both ansi and plain, exactly as
  the original fm-converse renderer did — DRY means same behaviour, not new behaviour.
  Flagged here so it's a deliberate match, not an oversight.
- **Karaoke JSON → /dev/null** on the CLI: there's no UI to consume the per-word
  highlight stream in a terminal, so it's discarded; the speaking is the payoff.

## Verified (live, this session)
- Mini reachable: `GET /v1/models` → HTTP 200.
- `fm-mlx "…**Hello**…"` → printed via emit_reply.
- `fm-mlx --say "…**DRY**…"` → terminal kept the markdown, speech said "DRY works".
- `fm-converse --help` → execs cleanly with the new import.
- `fm_render.py --plain` → strips headings/bullets/bold/code/fences.

## Side effects surfaced
- `fm-converse` no longer carries its own renderer — any future Markdown tweak is made
  once, in `fm_render.py`, and both tools inherit it.
- `bin/INDEX.md` regenerated (auto-gen; fm_render.py is a library, not listed as a CLI).

---

## Round 2 — "automatic talk + shown like fm-chat, in richtext" (same session)

### The request (verbatim)
> fm-mlx should be automatic talk. the response from fm-mlx should be shown the same
> way as fm-chat response, in richtext. if not, then whats the point. do the work to
> apple. figure it out.

(Esa had also edited fm-mlx himself between rounds, adding `--system` for the MLX
roundtable. Kept that.)

### How I read it
- **Automatic talk** = speak by DEFAULT, not opt-in `--say`. But fm-mlx is also called
  programmatically (the roundtable, via `--system`) — auto-talking there = many voices
  at once. So: speak by default **gated to an interactive TTY**; `--say` forces even
  when piped, `--quiet`/`-q` suppresses.
- **Shown the same way as fm-chat, in richtext** = adopt fm-chat's framing (green
  `fm  ›` label + dim `[host · model · round-trip]` stats) AND render Markdown as ANSI
  richtext. fm-chat's own output was raw (not richtext), so the DRY answer is to factor
  the framing into a shared `format_reply()` and have BOTH fm-chat and fm-mlx call it —
  then they're literally identical, and both gain richtext.

### What I did
1. Added `format_reply()` to `fm_render.py` (green `fm ›` + md_to_ansi body + stats
   line built from host/model/round-trip) and a `--chat` CLI mode.
2. Rewrote fm-mlx: auto-talk (`say="auto"` → speak iff `[ -t 1 ]`), `--say`/`--quiet`
   flags, measures round-trip, shows via `fm_render.py --chat --host … --model … --rt …`.
3. Refactored fm-chat to `from fm_render import format_reply` and print through it
   (was a bespoke `print(f"...fm ›...")`). Now fm-chat renders richtext too — same code.

### Decisions / judgement calls
- **Auto-talk is TTY-gated, not unconditional.** Esa said "automatic talk"; literal
  always-on would make the roundtable's captured calls all speak at once. Gating to an
  interactive terminal honors "automatic" for a human at the keyboard while keeping
  scripted use silent. `--say` is the escape hatch to force it.
- **fm-chat now renders richtext too.** To be "the same way," the cleanest path is one
  shared `format_reply` — which means fm-chat gains Markdown rendering. That's an
  enhancement, but it's exactly what makes "shown the same way, in richtext" literally
  true rather than approximately.

### Verified (live, this session)
- `format_reply(tty=True)` → green `fm ›`, **bold**, `• bullet`, cyan `code`, dim stats.
- fm-mlx default + piped → framed output, **silent** (roundtable safe).
- fm-mlx `--say` piped → spoke "forced speech".
- fm-chat `--help` execs cleanly with the new import.
- (Interactive TTY path: auto-speaks + ANSI richtext — logic + formatter both verified.)

---

## Round 3 — "continue the conversation from CLI + the MLX roundtable, DRY" (same session)

### The request (verbatim, lightly de-dictated)
> I would like for there to be some way of continuing the conversation from the command
> line — what would that be? And do we have the FM MLX round table in the same way as why
> we have the FM round table itself … we used to have a way of talking into the FM round
> table directly from the terminal and it would keep printing them and saying them. I would
> like there to be a dry principal whether FM MLX roundtable works in the exact same way.

### What I found
- The "FM roundtable" is **`convey roundtable`** (convey/cli.py `cmd_roundtable`) — N
  FoundationModels personas in their own voices, transcript wired into itself, karaoke,
  kb + dreamgraph. Its brain was hardwired to **fm-submit** (FoundationModels).
- The brain is called at ONE site: `Popen([fm, "--id", job, "--system", system,
  "--timeout", T, prompt])`. So a backend switch is a few-line change, not a rewrite.
- Continue-a-conversation already half-existed: `fm-converse --mlx` is stateful one-shot.
  No live REPL for MLX existed (fm-chat was FoundationModels-only).

### Decisions (asked Esa via AskUserQuestion — both forks materially changed the build)
1. **Continue-the-conversation → `fm-chat --mlx` live REPL** (he picked this over the
   one-shot-stateful option). Type → prints richtext → speaks → type again.
2. **MLX roundtable → make MLX the DEFAULT brain** (he picked this over a --mlx flag or a
   separate command). `convey roundtable` now uses Qwen3-4B by default; `--fm` falls back.

### What I did
1. **`fm-mlx --raw`** — the shared *brain interface*: reply text only, no framing, no
   speech. Both fm-chat --mlx and the roundtable call it, so the MLX transport lives once.
2. **`fm-chat --mlx`** — added the flag; `ask_mlx()` shells `fm-mlx --raw` with a live
   spinner; `speak_reply()` pipes `md_to_plain` → say-karaoke (Eddy). Speaks by default in
   --mlx mode, `--quiet` mutes, `--voice` picks. FM mode unchanged. Uses the same
   `format_reply` framing, so MLX and FM replies look identical.
3. **`convey roundtable` brain = MLX by default** — backend-agnostic Popen builds
   `fm-mlx --raw --system <persona> <transcript>` (the brain must be silent: convey owns
   the karaoke + per-voice `say`). `--fm` restores fm-submit. Banner prints `brain: …`.
   Added a `brain_fails` guard: 3 consecutive hard brain errors stop the table, so a down
   MLX server can't hot-loop (a risk the FM path's worker-poll didn't have).

### Decisions / judgement calls
- **Why MLX as default fits "the exact same way":** Qwen3-4B has a far bigger context
  window than on-device FM, so the table holds more conversation before resetting — the
  same loop, just a brain that chokes less. The FM-specific overflow-on-stderr reset stays
  (it simply won't fire for MLX); the budget reset still applies to both.
- **The brain must be silent.** fm-mlx auto-talks, but inside the roundtable that would
  double-speak over convey's per-persona voices — hence `--raw` (no speech) is mandatory
  for brain use. Same reason fm-chat --mlx uses `--raw` and does its own say.
- **fm-chat FM mode left text-only.** Esa asked for the MLX REPL to speak; I didn't change
  the working FM REPL's silence. One flag away if he wants it later.

### Verified (live, this session)
- `fm-mlx --raw --system "be a pirate" "say hello"` → "Arrr! Hello, matey! …", no framing.
- `fm-chat --mlx --quiet` (piped) → MLX banner, spinner, `fm  › … [cloudcitymacmini ·
  round-trip 0.7s]`.
- `convey roundtable "is the sky blue" --turns 3 --no-speak --panel 2` → `brain:
  MLX/Qwen3-4B`, 3 conversing turns, transcript saved, dreamgraph +3 claims.
- `convey roundtable --help` lists `--fm`; `--fm` path selects FoundationModels (banner).

### Continue-the-conversation — the answer to "what would that be?"
- **Live REPL:** `fm-chat --mlx` (new) — keeps printing and saying, like the old roundtable.
- **Stateful one-shot (already existed):** `fm-converse --mlx "msg"` — remembers between calls.
