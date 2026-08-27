#!/usr/bin/env python3
"""fm_render — the ONE place fm-* tools turn a model's Markdown reply into output.

A model reply is SHOWN through exactly one call — present() — which bundles the
three cross-cutting concerns so no tool ever re-rolls them or has to be asked:
  1. rich markdown   — md_to_ansi(): **bold**/#headings/-bullets/`code` → ANSI
  2. karaoke speech  — speak(): say-karaoke (per-word engine) in the premium voice
  3. voice/say choice— backend "say" (say-karaoke + Zoe) or "voicebox" (Kokoro/Heart)

Lower-level pieces are exposed too (md_to_ansi / md_to_plain / format_reply / speak)
but present() is THE contract: any tool that emits a model reply calls present()
(python) or `fm_render.py --present` (bash). See wiki/concepts/reply-presentation.md.

As a CLI (reads the reply text on stdin):
    fm-mlx ... | fm_render.py --present --host H --rt 1.2   # render rich + speak
    fm-mlx ... | fm_render.py --present --no-speak          # render only
    fm-mlx ... | fm_render.py                               # ANSI on TTY, plain when piped
    fm-mlx ... | fm_render.py --plain                       # always plain (speech/capture)

Apple-native: python3 stdlib only.
"""
import os
import re
import subprocess
import sys
import textwrap
from pathlib import Path

HERE = Path(__file__).resolve().parent
# The premium voice the whole family speaks in (the one convey's roundtable uses).
DEFAULT_VOICE = os.environ.get("FM_MLX_VOICE", "Zoe (Premium)")
# "say" = say-karaoke (per-word karaoke engine, AVSpeechSynthesizer, Zoe);
# "voicebox" = bin/voicebox-say (local Voicebox Kokoro/Heart). Override per-call or via env.
DEFAULT_BACKEND = os.environ.get("FM_SPEAK_BACKEND", "voicebox")  # the Voicebox (Kokoro/Heart), not macOS say

# ── Markdown → ANSI (terminal) ───────────────────────────────────────────────
_B, _I, _U, _DIM, _CODE, _R = "\033[1m", "\033[3m", "\033[4m", "\033[2m", "\033[96m", "\033[0m"


def md_to_ansi(text: str) -> str:
    """Render Markdown as ANSI styling for a real terminal."""
    out, in_fence = [], False
    for line in text.split("\n"):
        if line.strip().startswith("```"):
            in_fence = not in_fence
            continue                                   # drop fence markers
        if in_fence:
            out.append(_DIM + line + _R); continue
        # Emphasis carries COLOR, not just the bold/italic attribute — many terminals
        # (e.g. iTerm without a bold font face) render color but not bold *weight*, so
        # pure \033[1m looks like normal text. Color guarantees the emphasis is visible.
        _MDH = "\033[1m\033[4m\033[96m"   # heading: bold + underline + bright cyan
        _MDB = "\033[1m\033[93m"          # bold:    bold + bright yellow
        _MDI = "\033[3m\033[95m"          # italic:  italic + bright magenta
        h = re.match(r'^(#{1,6})\s+(.*)$', line)
        if h:
            out.append(_MDH + h.group(2).strip() + _R); continue
        line = re.sub(r'^(\s*)(\d+)\.\s+', r'\1' + _MDB + r'\2.' + _R + ' ', line)  # 1. numbered lists
        line = re.sub(r'^(\s*)[-*+]\s+', r'\1• ', line)            # bullets
        line = re.sub(r'`([^`]+)`', _CODE + r'\1' + _R, line)      # inline code
        line = re.sub(r'\*\*([^*]+)\*\*', _MDB + r'\1' + _R, line) # **bold** → bold yellow
        line = re.sub(r'__([^_]+)__', _MDB + r'\1' + _R, line)     # __bold__
        line = re.sub(r'(?<!\*)\*([^*\n]+)\*(?!\*)', _MDI + r'\1' + _R, line)  # *italic* → italic magenta
        line = re.sub(r'\[([^\]]+)\]\(([^)]+)\)',                  # [text](url)
                      _U + r'\1' + _R + _DIM + r' (\2)' + _R, line)
        out.append(line)
    return "\n".join(out)


def md_to_plain(text: str) -> str:
    """Strip Markdown to clean spoken text — for `say` / `say-karaoke`.
    No asterisks, no hashes, no backticks, no link URLs read aloud."""
    out, in_fence = [], False
    for line in text.split("\n"):
        if line.strip().startswith("```"):
            in_fence = not in_fence
            continue                                   # drop fenced code entirely
        if in_fence:
            continue
        line = re.sub(r'^(#{1,6})\s+', '', line)                   # heading markers
        line = re.sub(r'^(\s*)[-*+]\s+', r'\1', line)              # bullet markers
        line = re.sub(r'`([^`]+)`', r'\1', line)                   # inline code
        line = re.sub(r'\*\*([^*]+)\*\*', r'\1', line)             # **bold**
        line = re.sub(r'__([^_]+)__', r'\1', line)                 # __bold__
        line = re.sub(r'(?<!\*)\*([^*\n]+)\*(?!\*)', r'\1', line)  # *italic*
        line = re.sub(r'\[([^\]]+)\]\([^)]+\)', r'\1', line)       # [text](url) → text
        out.append(line)
    # collapse the blank runs left by dropped fences/headings
    return re.sub(r'\n{3,}', '\n\n', "\n".join(out)).strip()


def emit_reply(text: str, file=None):
    """Print the reply: ANSI-rendered Markdown on a TTY, plain when piped."""
    f = file or sys.stdout
    f.write((md_to_ansi(text) if f.isatty() else text) + "\n")


# ── fm-chat-style framing — shared so fm-mlx looks the same as fm-chat ────────
_GREEN, _RESET = "\033[32m", "\033[0m"


def terminal_width(default=88) -> int:
    env_cols = os.environ.get("COLUMNS")
    if env_cols and env_cols.isdigit():
        return max(40, int(env_cols))
    try:
        return max(40, os.get_terminal_size().columns)
    except OSError:
        return default


def wrap_markdown(text: str, width: int, *, first_width: int | None = None,
                  continuation_indent: str = "") -> str:
    """Word-wrap markdown prose before ANSI is added, preserving preformatted blocks."""
    out = []
    in_fence = False
    current_first_width = first_width or width
    for line in text.split("\n"):
        stripped = line.strip()
        if stripped.startswith("```"):
            in_fence = not in_fence
            out.append(line)
            current_first_width = width
            continue
        if in_fence or not stripped or stripped.startswith("|"):
            out.append(line)
            current_first_width = width
            continue

        match = re.match(r"^(\s*(?:[-*+]\s+|\d+\.\s+)?)", line)
        prefix = match.group(1) if match else ""
        content = line[len(prefix):].strip()
        if not content:
            out.append(line)
            current_first_width = width
            continue

        available = max(20, current_first_width - len(prefix))
        subsequent = continuation_indent if current_first_width != width else prefix
        subsequent += " " * len(prefix)
        wrapped = textwrap.wrap(
            content,
            width=available,
            break_long_words=False,
            break_on_hyphens=False,
        )
        if not wrapped:
            out.append(line)
        else:
            out.append(prefix + wrapped[0])
            cont_width = max(20, width - len(subsequent))
            for part in textwrap.wrap(
                " ".join(wrapped[1:]),
                width=cont_width,
                break_long_words=False,
                break_on_hyphens=False,
            ):
                out.append(subsequent + part)
        current_first_width = width
    return "\n".join(out)


def format_reply(answer: str, *, host=None, model=None, model_ms=None,
                 round_trip=None, tty=None, label="fm", width=None, gap="  ") -> str:
    """Frame a reply exactly like fm-chat: a green `fm  ›` label, the body rendered
    as Markdown (ANSI on a TTY, plain when piped), and a dim `[host · model · round-trip]`
    stats line built from whatever metadata is supplied. One formatter, every fm-* tool."""
    if tty is None:
        tty = sys.stdout.isatty()
    plain_head = f"{label}{gap}› "
    head = f"{_GREEN}{_B}{plain_head}{_R}" if tty else plain_head
    head_visible = len(plain_head)
    if tty:
        wrap_width = width or terminal_width()
        wrapped = wrap_markdown(
            answer,
            wrap_width,
            first_width=wrap_width - head_visible,
            continuation_indent=" " * head_visible,
        )
        body = md_to_ansi(wrapped)
    else:
        body = answer
    out = head + body
    bits = []
    if host:
        bits.append(host)
    if model:
        bits.append(model)
    if model_ms:
        bits.append(f"model {model_ms / 1000:.1f}s")
    if round_trip is not None:
        bits.append(f"round-trip {round_trip:.1f}s")
    if bits:
        stat = "     [" + " · ".join(bits) + "]"
        out += (f"\n{_DIM}{stat}{_R}" if tty else f"\n{stat}")
    return out


# ── the speaker — say-karaoke (karaoke engine) or voicebox, one home ──────────
def speak(text: str, voice: str = None, backend: str = None):
    """Speak `text` aloud the family's way. backend "say" → say-karaoke (per-word
    karaoke engine) in the premium voice; "voicebox" → bin/voicebox-say (Kokoro/
    Heart). Speaks md_to_plain(text) so markers aren't read aloud. The speaker
    writes /tmp/say-karaoke.pid (or the voicebox pid file) so ⌃⌥⌘. (stop) and ⌃⌥⌘,
    (pause/resume) control it. On Ctrl-C, stop playback and RE-RAISE so the caller
    can return to its prompt. Silent on any other error."""
    voice = voice or DEFAULT_VOICE
    backend = backend or DEFAULT_BACKEND
    cmd = ([str(HERE / "voicebox-say")] if backend == "voicebox"
           else [str(HERE / "say-karaoke"), "--voice", voice])
    proc = None
    try:
        proc = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.DEVNULL,
                                stderr=subprocess.DEVNULL, text=True)
        proc.communicate(md_to_plain(text))
    except KeyboardInterrupt:
        if proc and proc.poll() is None:
            try:
                proc.terminate()
            except Exception:
                pass
        raise
    except Exception:
        pass


def present(answer: str, *, host=None, model=None, model_ms=None, round_trip=None,
            label="fm", speak_aloud=True, voice=None, backend=None, tty=None, width=None):
    """THE one call to SHOW a model reply: rich-markdown render to the terminal AND
    speak it aloud (karaoke voice). Every reply-emitting tool uses this so rich
    markdown + karaoke + voice are never re-rolled or forgotten. Ctrl-C during
    speech stops playback and returns cleanly (prints '(speech stopped)')."""
    print(format_reply(answer, host=host, model=model, model_ms=model_ms,
                       round_trip=round_trip, label=label, tty=tty, width=width))
    if speak_aloud:
        try:
            speak(answer, voice=voice, backend=backend)
        except KeyboardInterrupt:
            print(f"\n{_DIM}  (speech stopped){_R}")


def main() -> int:
    argv = sys.argv[1:]
    text = sys.stdin.read()

    def opt(name):
        return argv[argv.index(name) + 1] if name in argv else None

    if "--plain" in argv:
        sys.stdout.write(md_to_plain(text) + "\n")
        return 0
    # --force-color (or FORCE_COLOR=1) forces ANSI even when stdout isn't detected
    # as a TTY — the robust path for callers that know they're talking to a terminal
    # but whose tty detection is unreliable (some iTerm/tmux/wrapper setups).
    force_tty = True if ("--force-color" in argv or os.environ.get("FORCE_COLOR")) else None
    if "--present" in argv:
        rt = opt("--rt")
        # Speak unless told not to; render rich on a TTY (or when forced), plain when piped.
        present(text.rstrip("\n"),
                host=opt("--host"), model=opt("--model"),
                round_trip=float(rt) if rt else None,
                speak_aloud=("--no-speak" not in argv),
                voice=opt("--voice"), backend=opt("--backend"), tty=force_tty)
        return 0
    if "--chat" in argv:
        rt = opt("--rt")
        sys.stdout.write(format_reply(
            text.rstrip("\n"),
            host=opt("--host"), model=opt("--model"),
            round_trip=float(rt) if rt else None, tty=force_tty) + "\n")
        return 0
    emit_reply(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
