---
description: Evaluation of the 4 cloned-voice personas (bearden, esa, milton/erickson, rob) — is it a whitelabeled connection tool, do they share file format + creation profile, and what a unified "file system of voices" (voice card) would look like. 2026-06-15.
---

# Voice-clone whitelabel evaluation (2026-06-15)

**Question asked:** are the 4 voices (Bearden, Esa, Milton/Erickson, Rob) using the same
file format and the same creation profile? Is this a whitelabeled connection tool? And what
are the possibilities for making it a *file system of voices* that connects to the broader
file system we're building.

## Verdict in one line
**Yes — it is already whitelabeled at the RUNTIME layer (one engine, N config instances), and
the voice itself is a uniform format (a Voicebox profile UUID). But the per-voice FILE SYSTEM
has drifted: 3 different home dirs, 4 different levels of completeness, and 2 of 4 voices have
NO reproducible creation profile stored.** The mechanism is unified; the filesystem is not.

## What IS uniform (the whitelabel works)

| Layer | Shared artifact | Per-voice variation |
|---|---|---|
| Engine | `hyp/personas/_shared/voicebox_speak.py` (25 KB, ALL logic: chunk/retry/transcribe-verify/cache/ffmpeg-concat/auto-pause/fallback) | none — single source |
| Config contract | `PersonaConfig` dataclass: `name, env_prefix, profiles{key:(display,uuid)}, default_profile_key, audio_dir, cache_dir, direct_address_strip, filename_template, fallback_title` | the field values |
| CLI shim | `speak.py` — identical shape ×4 (import engine, declare CONFIG, `Speaker(CONFIG).cli()`) | the CONFIG literal |
| Bash launcher | `bearden`/`esa`/`milton`/`rob` in ~/bin — identical shape ×4 (health-check → voicebox-start → optional `--chat` via `claude -p` → exec speak.py) | name, speak.py path, persona trigger |
| Voice storage | a **Voicebox profile = UUID + N samples** — same format for every voice | the UUID + sample count |
| Creation pipeline | `train_clone.py` — generic: `<source_wav> <profile_name>` → Whisper JSON → <25 s chunks → ffmpeg slice → create profile → upload samples | source wav + name only |

So the answer to "same file format / same creation profile": **the formats and the creation
pipeline are generic and identical in shape.** A voice is `PersonaConfig` + a Voicebox UUID;
it is made by `train_clone.py` from samples. This is a whitelabeled connection tool: the
"connection" is `PersonaConfig` (text → which cloned voice), the mechanism is shared.

## What is NOT uniform (the drift — and the zero-data-loss gap)

Per-voice directory completeness, today:

| Voice | Home | git? | signature | phrasing | samples/ | train_clone | SKILL/rules | renders home |
|---|---|---|---|---|---|---|---|---|
| **Rob** | hyp/personas/rob | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ (+dialogue.py, verify.py) | hyp/audio |
| **Erickson** | hyp/personas/erickson | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | hyp/audio |
| **Bearden** | merlib-dump/personas/bearden | ✗ | ✗ | ✗ | ✗ | ✗ | ✓ (+rules/) | merlib-dump/audio/bearden |
| **Esa** | esa-voice | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | esa-voice/renders |

Voicebox profiles + sample counts (the actual clones): Bearden 416, Esa 169, Rob-teaching 103,
Erickson 22, Rob-sleep 5.

**The critical finding:** the *reproducible creation profile* (`train_clone.py` + `samples/`)
exists for only **Erickson** (full) and **Rob** (samples but no train_clone). **Bearden and Esa
have neither** — if their Voicebox profile (416 / 169 samples) were lost, there is no stored
recipe or corpus in their dir to rebuild it. That is the real zero-data-loss hole, and it's
worse than the ~/bin launcher question: two of the highest-sample voices are unreproducible.

Also: 2 of 4 voice homes (merlib-dump, esa-voice) are **not git repos at all**, so even what
they do have (Bearden's rules/, Esa's renders/) is unversioned.

## The possibilities — a "file system of voices" (voice card)

This maps directly onto the report-card / convey file-system doctrine: each voice becomes a
uniform, self-describing, reproducible **voice card** — one directory that is the unit of a
voice, spawned from one whitelabel template. Proposed canonical layout:

```
voices/<persona>/
  voice.yaml          # PersonaConfig AS DATA (name, env_prefix, profiles{key:[display,uuid]},
                      #   default, strip, filename_template) — kills the per-voice speak.py boilerplate;
                      #   one shared speak.py reads voice.yaml. THIS is the "connection".
  creation.yaml       # the creation profile RESULT: source_wav(s), sample_count, chunk params,
                      #   resulting UUID, date — the recipe's output, so a clone is reproducible.
  samples/            # the corpus (text + audio refs) — the input to train_clone
  voice-signature.md  # character / cadence
  phrasing-library.md # vocabulary
  SKILL.md, rules/    # the discipline (what-would-X-say)
  renders/  cache/    # outputs
  README.md, deployment.md
shared/
  voicebox_speak.py   # the engine (one)
  train_clone.py      # the creation pipeline (one, generic)
  speak.py            # one shim that reads voices/<persona>/voice.yaml
```

Then a voice is registered into the broader file system exactly like a feature/report card:
`voice.yaml` is the spec, `creation.yaml` + `samples/` is the reproducible "how it was made",
`voice-signature.md` is the why/character. One template spawns a voice; the file system can
enumerate, rebuild, and connect voices the same way it enumerates cards.

## Open decisions (NOT acted on — evaluation only)
1. One repo for all voices, or keep them near their corpora? (hyp already hosts engine + 2 voices.)
2. Make merlib-dump / esa-voice git repos, or relocate Bearden/Esa voice dirs into a git home?
3. Backfill `train_clone.py` + `samples/` for Bearden and Esa (close the reproducibility hole).
4. Promote `PersonaConfig` literals → `voice.yaml` data + one shared `speak.py`.
5. The ~/bin launchers (bearden/esa/milton/rob) become symlinks into wherever the cards live.

## Consolidation decision (2026-06-15): convey is the home
Esa: "maintain proper format, same format, but put it into the same place. convey is the
logical place." Confirmed by convey already owning the concept:
`principles/0022-the-computer-speaks-back-voice-response-mechanism-whitelabeled`,
`0009-read-a-response-aloud-via-voicebox`, `0014-narrate-a-corpus-in-a-cloned-voice`,
plus `voicebox.filerule`.

**Directive: relocate, do NOT refactor.** Keep the exact same format (PersonaConfig + speak.py
shim + shared engine); only change WHERE it lives. No voice.yaml rewrite in this pass.

### Sizing that shapes the move
- Code/text per voice is tiny: bearden 156K, esa 1.1M (mostly its renders), erickson 68K,
  rob 144K, _shared 68K. `samples/` are text `.md`. All git-safe.
- Audio OUTPUT is huge + regenerable: `merlib-dump/audio/bearden` 1.4G, `hyp/audio` 1.4G.
  **MUST stay out of git.** Leave renders/cache where they are; only relocate code.

### STATUS: EXECUTED 2026-06-16 (move + update-all-refs, no origin symlinks)
Done: all 4 voice cards + shared engine + train_clone now live in `convey/voices/`
(commit `97d574d`); removed from hyp (`55dced9`) and from merlib-dump/esa-voice (non-git).
Shims rewired (import → `convey/voices/_shared`; audio_dir → each voice's existing out-of-git
render home). `~/bin/{bearden,esa,milton,rob}` → symlinks into the cards. The 4 broken
`~/.claude/skills/what-would-*-say` symlinks repointed into convey. hyp doc refs updated.
2.8 GB of renders deliberately left in place. Verified: all 4 shims load + resolve their
voicebox profile; live esa synth reached generation through the moved chain.

### Reproducibility backfill — DONE 2026-06-16 (Bearden + Esa), convey `2d6aa93`
Closed the hole. Each of Bearden (416 samples) and Esa (169) now carries, git-tracked:
`creation.yaml` (UUID, source, engine, dates + master path/sha256 + rebuild commands) and
`samples/transcripts.jsonl` (every training sample's reference text, exported live from the
voicebox `/profiles/{id}/samples` API) + `samples/README.md`. The re-importable binary
masters (`/profiles/{id}/export` → `.voicebox.zip`: Bearden 388 MB/416 wavs, Esa 111 MB/169
wavs) were integrity-verified and stored in each voice's out-of-git render home
(`merlib-dump/audio/bearden/masters/`, `esa-voice/masters/`), sha256 in creation.yaml.
Still open: (a) a DURABLE backup home for the ~500 MB of masters (git-lfs declined; same
mediabank-style question as OCR outputs); (b) same backfill for erickson/rob if wanted
(their voicebox audio corpus also lives only in voicebox).

### Original plan (copy → verify → symlink-back) — superseded by the move-no-symlinks choice
```
convey/voices/
  _shared/voicebox_speak.py        # the one engine (from hyp/personas/_shared)
  _shared/train_clone.py           # the one creation pipeline (from erickson; generic)
  bearden/   esa/   erickson/   rob/   # each = the persona's code/text dir, verbatim
```
- speak.py imports rewired to `convey/voices/_shared`; audio_dir/cache_dir left pointing at the
  existing (out-of-git) render homes so no 2.8 GB move.
- ~/bin launchers (bearden/esa/milton/rob) → symlinks into convey/voices + their SPEAK= paths
  updated; brought under version control with the rest.
- Originals in hyp/merlib-dump/esa-voice replaced by symlinks → convey/voices, so every existing
  path (skills, docs, sys.path) still resolves. Delete nothing until verified.
- Dependents to update (small, contained): the 4 speak.py imports, the 4 launchers, hyp's
  SKILL.md/USAGE.md/references path mentions, these apple wiki docs.
- Reproducibility hole (Bearden/Esa lack train_clone+samples) tracked as follow-up, not blocker.

