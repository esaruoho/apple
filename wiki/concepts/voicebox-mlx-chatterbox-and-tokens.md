---
description: Two separate questions untangled — (1) MLX-accelerate Chatterbox so Esa's clone runs on the Apple GPU instead of CPU; (2) stop Claude burning tokens "getting Esa to speak" (a babysitting problem, not a synthesis-speed problem). 2026-06-16.
---

# Voicebox: MLX-Chatterbox + the token question

Esa asked: "can we use MLX for Chatterbox so Claude doesn't eat up all the tokens just
trying to get Esa to speak?" These are TWO different problems. Separating them:

## Problem A — tokens (the real ask, and it's NOT about MLX)
Synthesis runs **100% locally** in voicebox — it costs **zero Claude tokens** whether it's on
CPU or GPU. The tokens burned in the demo were **Claude babysitting**: spawning background
tasks, polling `tasks/*.output`, `until pgrep` wait-loops, re-reading files. That's an
orchestration choice, not a synthesis cost.

**Fix = zero-roundtrip speaking (the apple-skill rule):** fire `esa "..."` detached and STOP.
`speak.py` plays the audio itself (afplay) — Claude does not need to wait for or watch it.
The replay proved it: one `afplay … &`, done, ~0 tokens. So the token fix is behavioral +
(optionally) a `--notify` that pings macOS/iMessage on completion so there's a signal without
polling. MLX changes nothing here.

## Problem B — speed/reliability (where MLX genuinely helps)
Chatterbox is **hardcoded to CPU on Mac**: `chatterbox_backend.py:53`
`get_torch_device(force_cpu_on_mac=True, …)`. The Apple GPU (MPS, available) is unused. That
CPU path is slow and flaky — e.g. the BBS demo's "The bulletin board never died." needed **8
seed-retries** (Chatterbox's silent-truncation failure mode), accepted as best-partial.

**MLX-Chatterbox already exists and is installed** in voicebox's venv:
`mlx_audio/tts/models/chatterbox` + `chatterbox_turbo`. Weights cached
(`~/.cache/huggingface/hub/models--ResembleAI--chatterbox`). It supports reference-audio
cloning, and `mlx_audio.tts.generate` CLI is present. So the SAME Esa clone could run on the
GPU via MLX — faster, far fewer retries.

The gap: voicebox's `mlx_backend.py` currently only wires MLX to **Qwen3-TTS**, not to the
installed mlx_audio Chatterbox. So enabling it is a **backend change** to voicebox (a fork of
jamiepine/voicebox), not a config flip. Two routes:
1. **Wire mlx_audio Chatterbox into voicebox** as a selectable engine/variant (proper fix;
   upstream-able). Then `default_engine: chatterbox` clones render on MPS.
2. **Call `mlx_audio.tts.generate` directly** from a thin renderer (bypass voicebox for the
   clone path) using an Esa reference wav from the master zip. Faster to prototype; diverges
   from the voicebox pipeline (loses the chunk/verify/cache engine unless re-implemented).

### Caveat — clone fidelity must be tested
The Esa/Bearden profiles were cloned via **PyTorch** Chatterbox. mlx_audio Chatterbox does
zero-shot cloning from a reference wav; it should reproduce the voice from the same reference
audio (we have it — the sample wavs are in the `.voicebox.zip` masters), but fidelity vs the
PyTorch clone needs an A/B listen before switching the default.

## Recommendation
- **Now, free:** adopt zero-roundtrip speaking (fire-and-forget; optional `--notify`). Solves
  the token complaint immediately. No MLX needed.
- **Next, scoped:** prototype route 2 — `mlx_audio.tts.generate` with an Esa reference wav on
  MPS — as an A/B vs the current CPU render. If fidelity holds, do route 1 (wire it into
  voicebox as the Mac GPU path for Chatterbox). This is the durable speed/reliability win.

## INTEGRATION DONE — works on GPU (2026-06-16). Patch: `patches/voicebox-mlx-chatterbox.patch`
Wired mlx_audio Chatterbox into voicebox as the Mac-GPU path. Three changes (local to the
`jamiepine/voicebox` checkout — UPSTREAM, not Esa's fork, so preserved as a patch, not pushed):
1. **`backends/chatterbox_mlx_backend.py`** (new) — `ChatterboxMLXTTSBackend`, same TTSBackend
   contract, runs `mlx-community/chatterbox-fp16` on Metal. Mirrors the PyTorch backend's
   anti-ramble params (**repetition_penalty=2.0** is the key — mlx-audio's default 1.2 rambled
   to 48s). Caps the reference clip to 15s.
2. **`backends/__init__.py`** — engine `chatterbox` routes to the MLX backend when
   `backend_type=="mlx"` (mirrors the qwen branch); opt out with `VOICEBOX_CHATTERBOX_MLX=0`.
3. **`services/profiles.py`** — chatterbox engines now use ONE substantial sample, not all
   samples combined. (Esa's 169 samples combined = a **3083s / 51-min** reference that garbled
   MLX to coverage 0.1; chatterbox wants a short single reference.)

**Result:** end-to-end `esa` CLI → voicebox → MLX on Metal → clean Esa voice, **coverage 0.97**.

**Honest speed:** per-attempt GPU gen ~**5s for a 4.8s clip (RTF ~1.0x)** — i.e. roughly
CPU-parity at fp16, NOT a dramatic speedup. And some seeds add a trailing artifact (" 1." /
" 3 ") → coverage ~0.74 → retries (3 attempts in the test). So as-is it WORKS on the GPU but
isn't yet clearly faster than CPU.

**Two follow-ups to actually make it faster:**
- Tune `repetition_penalty` (2.0 → ~2.4) for the MLX backend to suppress the trailing artifact
  → fewer retries → faster effective.
- Try the faster checkpoints via `VOICEBOX_CHATTERBOX_MLX_REPO`:
  `mlx-community/chatterbox-turbo-fp16` (turbo) or a quant (`chatterbox-4bit`/`8bit`) — smaller,
  faster, the real speed win. One env-var change + an A/B fidelity listen.

**Durability:** voicebox is upstream; these live on disk + in `patches/voicebox-mlx-chatterbox.patch`.
To version them properly, fork voicebox (same question as the ~/bin scripts).
