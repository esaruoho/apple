#!/usr/bin/env python3
"""fm_render — the ONE place fm-* tools turn a model's Markdown reply into output.

DRY home for what used to live inline in fm-converse. Three consumers share it:
  • the terminal  — md_to_ansi(): **bold**/#headings/-bullets/`code` → ANSI styling
  • the speaker   — md_to_plain(): strip the markers so `say`/`say-karaoke` doesn't
                    read "asterisk asterisk bold" aloud
  • piping        — emit_reply(): ANSI on a TTY, plain text when captured/piped

So "render the reply" is written once and reused by fm-converse, fm-mlx, and any
future fm-* sibling — instead of each re-implementing Markdown handling.

As a CLI (reads stdin):
    fm-mlx ... | fm_render.py            # ANSI on a TTY, plain when piped
    fm-mlx ... | fm_render.py --plain    # always plain (for speech / capture)

Apple-native: python3 stdlib only.
"""
import re
import sys

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
        h = re.match(r'^(#{1,6})\s+(.*)$', line)
        if h:
            out.append(_B + _U + h.group(2).strip() + _R); continue
        line = re.sub(r'^(\s*)[-*+]\s+', r'\1• ', line)            # bullets
        line = re.sub(r'`([^`]+)`', _CODE + r'\1' + _R, line)      # inline code
        line = re.sub(r'\*\*([^*]+)\*\*', _B + r'\1' + _R, line)   # **bold**
        line = re.sub(r'__([^_]+)__', _B + r'\1' + _R, line)       # __bold__
        line = re.sub(r'(?<!\*)\*([^*\n]+)\*(?!\*)', _I + r'\1' + _R, line)  # *italic*
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


def format_reply(answer: str, *, host=None, model=None, model_ms=None,
                 round_trip=None, tty=None, label="fm") -> str:
    """Frame a reply exactly like fm-chat: a green `fm  ›` label, the body rendered
    as Markdown (ANSI on a TTY, plain when piped), and a dim `[host · model · round-trip]`
    stats line built from whatever metadata is supplied. One formatter, every fm-* tool."""
    if tty is None:
        tty = sys.stdout.isatty()
    body = md_to_ansi(answer) if tty else answer
    head = f"{_GREEN}{_B}{label}  ›{_R} " if tty else f"{label}  › "
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


def main() -> int:
    argv = sys.argv[1:]
    text = sys.stdin.read()
    if "--plain" in argv:
        sys.stdout.write(md_to_plain(text) + "\n")
        return 0
    if "--chat" in argv:
        def opt(name):
            return argv[argv.index(name) + 1] if name in argv else None
        rt = opt("--rt")
        sys.stdout.write(format_reply(
            text.rstrip("\n"),
            host=opt("--host"), model=opt("--model"),
            round_trip=float(rt) if rt else None) + "\n")
        return 0
    emit_reply(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
