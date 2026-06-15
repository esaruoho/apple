# Session — mlx-agent-tool-loop

The spawning conversation for `bin/mlx-agent` (the on-device agentic tool-calling loop).

## How to get back
- Transcript: this Claude Code session in `~/work/convey` (project: -Users-esaruoho-work-convey)
- Date: 2026-06-15
- Resume: `claude --resume <id>` (id from the transcript; not fabricated here)

## The ask
Esa ran `/last30days` on "completely Apple methods of injecting data into a file
system, using MLX and otherwise … an agentic file system … talk to it and get the
responses back from Convey/Comms." The research (window 2026-05-16..06-15, X+HN+GitHub;
Reddit 403'd, no auth) surfaced Apple's WWDC26 session 232 "Run local agentic AI on the
Mac using MLX" and its four-layer stack: MLX → MLX-LM → MLX-LM Server (OpenAI-compatible,
tool-calling) → agent framework.

We mapped Convey onto that stack (docs in convey/docs/convey-vs-apple-mlx-stack-and-embeddings.md):
Esa is AHEAD on transport (Tailscale + Syncthing dual path), dual-brain (MLX + FM), a
filesystem-resident memory layer (molecule/DreamGraph/folder-memory) Apple doesn't ship,
and skill-armed identity. The ONE gap: the **agentic tool-calling LOOP**. `mlx-here` was
retrieve-then-prepend-then-ONE-completion (RAG); the model never decided on its own to
call a verb, read the result, and continue.

Esa: "adopt the highest value thing."

## What we built
`bin/mlx-agent` — the loop. Both halves already existed (mlx_lm.server speaks the OpenAI
tool-calling protocol; convey has a verb catalog), so this wires them:

    model reasons → calls a convey/apple verb as a TOOL → reads the result
                  → decides the next step → repeats → final answer

- Reuses `arm_apple.build_system(cwd)` for identity (same as mlx-here) + appends a note
  telling the model it has tools and should call them to verify rather than guess.
- SAFE-by-construction tool registry (8 read-only/idempotent verbs): list_dir, read_file,
  search_notes (NLEmbedding via vault-grep — the model now DRIVES the embedding cache),
  molecule, ask_file (convey ask), vision_ocr, folder_memory, tag_find. Args passed as
  argv arrays (never a shell string); paths sandboxed under $HOME; every output bounded;
  loop capped by --max-iters.
- Final answer presented via the ONE shared `fm_render.py --present` (DRY with fm-mlx).
- `mlx-here --agent/--tools <task>` routes into it (MLX-only; the loop needs the tool-
  calling server).

## Honest grading
- @built + @sim-verified: the loop logic (stubbed server: tool_call turn → execute →
  final answer returned), the presenter DRY path.
- @hw-verified (local): the 8 real verbs run read-only (search_notes returned real scored
  NLEmbedding passages), the $HOME sandbox refuses /etc/hosts, --dry-run + the mlx-here
  route print the registry.
- @untested / PENDING: the end-to-end live loop against Qwen3-4B on the Mini. On 2026-06-15
  the Mini's :8080 was serving TTS + GLM-OCR, not the chat model — so the live agentic
  loop was NOT exercised. Not claiming hw-verified until the chat model is served and a
  real task drives the belt. (This is the completion-framing rule: untested is untested.)

## Side effects surfaced
- The /last30days first-run wrote ~/.config/last30days/.env (SETUP_COMPLETE=true), chmod 600.
- Raw research saved at ~/Documents/Last30Days/apple-mlx-agentic-filesystem-*-raw-v3.md.
