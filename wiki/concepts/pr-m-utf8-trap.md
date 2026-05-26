---
description: BSD `pr -m -w COLS` (the obvious tool for merging two CLI dashboards side-by-side) truncates each line at the byte boundary, slicing multi-byte UTF-8 characters mid-codepoint. Result is mojibake `?` boxes from `─` separators and `█` / `░` progress bars. Use a Python wcwidth-aware merger instead. Discovered 2026-05-25.
---

# `pr -m` UTF-8 trap — why your separator lines look like `?` boxes

## The trap

You want to put two CLI dashboards side-by-side. BSD `pr` looks perfect:

```bash
pr -m -t -w "$cols" <(./ocr-status.sh) <(./whisp-status.sh)
```

`-m` merges files in parallel columns, `-t` suppresses headers, `-w` sets total page width. Each input becomes one column, equal split.

It works fine for ASCII content. Then your dashboards start using `─` (U+2500 BOX DRAWINGS LIGHT HORIZONTAL — 3 bytes in UTF-8), `█` (U+2588 — 3 bytes), and emoji (4 bytes). `pr -m` truncates each line at `cols/n` **bytes**, not characters. When the byte cutoff lands inside the middle of a 3-byte `─`, the terminal sees an invalid UTF-8 sequence and renders it as `?` in a box.

Symptom: separator lines like `─────────────[?]` at the end. Progress bars like `[█████░░░░[?]`. Anywhere a multi-byte character lands near the column boundary, mojibake.

`pr` has no UTF-8 awareness. The GNU `pr` on Linux has the same byte-truncation. There is no option to fix it.

## The durable answer — Python wcwidth-aware merger

Replace `pr -m` with a small Python helper that counts **display width** via `unicodedata.east_asian_width`:

```python
import unicodedata

def display_width(s: str) -> int:
    w = 0
    for ch in s:
        if unicodedata.combining(ch):
            continue
        cp = ord(ch)
        ea = unicodedata.east_asian_width(ch)
        if ea in ('F', 'W'):
            w += 2
        # Most macOS-Terminal-rendered emoji land in these ranges:
        elif 0x1F300 <= cp <= 0x1FAFF or 0x2600 <= cp <= 0x27BF:
            w += 2
        else:
            w += 1
    return w

def pad_clip(line: str, target: int) -> str:
    cur = display_width(line)
    if cur == target:
        return line
    if cur < target:
        return line + (" " * (target - cur))
    # Clip: walk the string, accumulate display width, stop one column
    # short to leave room for an ellipsis, then pad to target.
    out, used = [], 0
    for ch in line:
        cw = display_width(ch)
        if used + cw > target - 1:
            break
        out.append(ch); used += cw
    out.append("…"); used += 1
    if used < target:
        out.append(" " * (target - used))
    return "".join(out)
```

For each row, call `pad_clip(line, col_width)` on each pane's content and join with a separator. Now `─` characters are counted as width 1 and never get sliced; emoji are counted as width 2 so column alignment is preserved.

### Emoji width — the fudge

`unicodedata.east_asian_width` returns `'A'` (Ambiguous) for most emoji. By spec, terminals can render them as either width 1 or width 2. **macOS Terminal and iTerm2 render most BMP/SMP emoji at width 2.** The fudge:

```python
elif 0x1F300 <= cp <= 0x1FAFF or 0x2600 <= cp <= 0x27BF:
    w += 2
```

Covers SMP Miscellaneous Symbols and Pictographs (1F300–1FAFF) and BMP Dingbats / Miscellaneous Symbols (2600–27BF). If you find a specific emoji rendering as width 1 in your terminal, narrow the range.

## Other UTF-8 byte-truncation traps on macOS

- **`cut -c N-M`** — counts bytes, not characters. Same trap.
- **`head -c N`** — bytes. Same trap.
- **`awk '{print substr($0, 1, N)}'`** — bytes on BSD awk; characters on GNU awk (`gawk`). Don't rely on it being portable.
- **`fold -w N`** — bytes. Same trap.
- **`column`** without `-c` — happens to use ANSI escape codes naively, miscounts CJK and emoji.

**Safe alternatives:** Python (above), `gawk` with `LC_ALL=en_US.UTF-8`, or `perl -CSDA -e 'print substr($_, 0, N)'` (Perl handles UTF-8 natively when given `-CSDA`).

## How to apply

- Any time you're merging two-or-more CLI outputs into columns, do NOT use `pr -m`. Hand the inputs to a Python helper that counts display width.
- Same applies to any width-dependent cropping of mixed-script content (Japanese filenames, Finnish ä/ö, emoji headers).
- If you must stay in pure Bash, build the source scripts to never emit lines longer than the per-column width — then no truncation is needed. That's brittle though — the moment a filename is too long, you're back in trouble.

## Reference implementation

`~/work/comms/statuses.sh` — the three-pane dashboard. Bash wrapper computes column widths, exports each pane's output as `PANE0/PANE1/PANE2` env vars, then a 25-line Python block does the wcwidth-aware merge.

## Companion concepts

- `concepts/terminal-width-detection.md` — get the correct terminal width before you compute column widths, or this entire pipeline is moot.

## Status

- 2026-05-25 — `pr -m` had been producing `[?]` boxes in `statuses.sh` for weeks. Replaced with Python wcwidth-aware merger. Verified on macOS Sequoia 15.6.1 in iTerm2 + Apple Terminal.
