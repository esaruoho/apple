---
description: ELI5 recap of the 2026-06-15→16 session — voicebox on/off switch, voice consolidation into convey/voices, reproducibility backfill, MLX-Chatterbox GPU integration, and the live seconds counter. What we did, accomplished, and left on the table.
---

# Session recap (2026-06-15 → 06-16): the voices

## ELI5 — what we did

Think of the computer's "talking voices" like a box of toy walkie-talkies, one for
each character (Esa, Bearden, Rob, Milton).

1. **A light switch for the talking.** We put an ON/OFF switch in the menu-bar (🧰
   AppleToolbox) so Claude only talks out loud when you want. Then we made the ON button
   *smart*: it also turns the walkie-talkie base-station (Voicebox) on if it was off — so
   "ON" always means "it actually works," you never have to check.

2. **We fixed a broken finder.** The tool that checks "is the base-station on?" was looking
   for it by a nickname that kept changing, so it often said "off" when it was really on. We
   changed it to look by the *radio channel* (the port) instead — that never changes.

3. **We put loose toys in the toy box.** A bunch of little scripts were lying on the floor
   (in `~/bin`, not saved anywhere). We put the important ones into the proper toy box (git),
   so they can't get lost.

4. **We found all four walkie-talkies were the SAME toy, just in different drawers.** Same
   shape, same batteries — only scattered. So we moved all four (plus their shared engine)
   into ONE drawer: `convey/voices/`. We updated every label that pointed at the old drawers
   and fixed the ones that had broken.

5. **We wrote down how each voice was made.** Two voices (Esa, Bearden) had no recipe — if
   the voice got erased, it was gone forever. We saved the recipe (`creation.yaml`), the word-
   list it was trained on, and a full backup file you can re-load to rebuild the exact voice.

6. **We made the voices run on the fast chip.** The voices were running on the slow part of
   the computer (CPU) because of an old safety rule. We wired them to the fast Apple GPU
   (Metal). Two things were broken and we fixed them: the voice rambled for 48 seconds (a
   knob called "don't-repeat-yourself" was too low), and it got fed a 51-MINUTE example clip
   (way too long — we cut it to a short one). Now it speaks cleanly on the GPU.

7. **We added a stopwatch.** When you run `esa "hello"`, a little ⏳ counter now shows how
   many seconds you've been waiting.

## What we ACCOMPLISHED (shipped + pushed)
- **AppleToolbox voicebox ON/OFF switch** that also starts the server — proven live.
  (`apple` repo, `bin/voicebox-speak`, menu row, `/voicebox-speak`.)
- **Robust server detection** (lsof-by-port, not brittle pgrep). `bin/voicebox-status` etc.
  now version-controlled in `apple/bin`.
- **All 4 voice cards consolidated into `convey/voices/`** — one git home, all refs updated,
  broken skill symlinks repointed. (`convey` + `hyp` repos.)
- **Reproducibility backfill for Bearden + Esa** — `creation.yaml` + `samples/transcripts.jsonl`
  + re-importable `.voicebox.zip` masters (388 MB / 111 MB), sha256 recorded.
- **MLX-Chatterbox GPU backend wired into voicebox** — works end-to-end, clean Esa voice,
  Whisper coverage 0.97. Preserved as `apple/patches/voicebox-mlx-chatterbox.patch`.
- **Live ⏳ seconds counter** in every persona CLI (shared engine).

## What we LEFT ON THE TABLE
- **Make the GPU voice actually FAST.** It works on the GPU but is ~CPU-speed at fp16, and a
  "trailing artifact" makes it retry. Fixes pending: bump `repetition_penalty` 2.0→~2.4, and
  try `chatterbox-turbo` / quantized checkpoints (one env-var: `VOICEBOX_CHATTERBOX_MLX_REPO`).
- **A durable home for the ~500 MB voice masters.** They sit in non-git render folders; git-lfs
  is declined. Same "needs a real backup store" question as the OCR outputs (mediabank-style).
- **Fork Voicebox** so the MLX patch is properly version-controlled (its remote is upstream
  `jamiepine/voicebox`, so we could only save a patch, not push).
- **Backfill erickson/rob reproducibility** too (same as Esa/Bearden).
- **Track the other loose `~/bin` scripts** — `ocrq` → comms, `ray-dev.sh` → ray (or leave).
- **Make `merlib-dump` and `esa-voice` git repos** (they hold unversioned voice data).
