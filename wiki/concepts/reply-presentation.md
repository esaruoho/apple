---
description: The one shared way every fm-* tool SHOWS a model reply — rich markdown + karaoke speech + voice, via fm_render.present(). Stop re-rolling these three per tool.
---

# Reply presentation — one shared `present()`, never re-rolled

**The rule:** any tool that displays a model reply calls **`fm_render.present()`** (Python) or **`bin/fm_render.py --present`** (bash). It does NOT print the reply itself, and it does NOT wire up its own speaker. The three cross-cutting concerns are owned in one place.

## Why this page exists

By the 9th reply-emitting tool (`mlx-here`/`fm-chat --mlx`), the same request kept recurring: *"if you show markdown, it must be rich markdown; and it must do karaoke + voicebox/say."* Each new tool was built from the ground up and had to be **asked** to do these three things. That is a DRY failure — the Convey principle is that a capability is built once and consumed, not re-rolled per tool.

Rendering *was* shared (`fm_render.md_to_ansi` / `format_reply`), but the **speak act** was re-rolled in every tool (`fm-chat` had `speak_reply`, `fm-mlx` piped to `say-karaoke` inline) and nothing bound "render + speak" into a single call. So a new tool could render but forget to speak, or speak in the wrong voice. `present()` closes that hole.

## The three concerns `present()` bundles

1. **Rich markdown** → `md_to_ansi()`: `**bold**` / `# headings` / `- bullets` / `` `code` `` / `*italic*` / `[links](url)` → ANSI on a TTY, plain when piped.
2. **Karaoke speech** → `speak()` → `bin/say-karaoke` (AVSpeechSynthesizer, per-word engine). Writes `/tmp/say-karaoke.pid` so the global **⌃⌥⌘.** (stop) and **⌃⌥⌘,** (pause/resume) hotkeys control it.
3. **Voice / backend** → premium **Zoe (Premium)** by default (the voice convey's roundtable uses), NOT Eddy. Backend is `say` (say-karaoke) or `voicebox` (`bin/voicebox-say`, Kokoro/Heart). Override per-call or via `FM_MLX_VOICE` / `FM_SPEAK_BACKEND`.

Ctrl-C during speech stops playback and returns cleanly (`(speech stopped)`), never crashes.

## The API

```python
from fm_render import present
present(answer, host="cloudcitymacmini", model_ms=6000, round_trip=1.2,
        speak_aloud=True, voice=None, backend=None)   # voice/backend None → defaults
```

```bash
# bash tools (reply text on stdin):
... | python3 bin/fm_render.py --present --host H --model M --rt 1.2          # render + speak
... | python3 bin/fm_render.py --present --no-speak                            # render only
... | python3 bin/fm_render.py --present --voice "Zoe (Premium)" --backend voicebox
```

Lower-level pieces remain exposed for special cases (`md_to_ansi`, `md_to_plain`, `format_reply`, `speak`, `emit_reply`), but **`present()` is the default and the contract.**

## Consumers (keep this list honest)

- `bin/fm-chat` (and therefore `mlx-here` / `mlx-chat`, `fm-chat --mlx`, `fm-chat --apple`) — calls `present()`.
- `bin/fm-mlx` — calls `fm_render.py --present` in its interactive branch.
- **Any future reply-emitting tool** — MUST call `present()` / `--present`. If you find yourself typing `say-karaoke` or `format_reply` directly in a new tool, stop: use `present()`.

Related: [`headless-renderer-testing`](headless-renderer-testing.md) · the `say` skill · [`global-keyboard-shortcuts`](global-keyboard-shortcuts.md) (the stop/pause hotkeys). Companion memory: `feedback_reuse_before_rerolling`.
