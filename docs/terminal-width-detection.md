---
layout: default
title: "Terminal width detection in Bash — `stty size </dev/tty`, not `tput cols`"
---

---
description: How to reliably read the terminal column count from a Bash CLI dashboard so layouts actually reflow on resize. `tput cols` inside `$(...)` command substitution can return 80 even on a 200-col window — `stty size </dev/tty` is the durable answer. Discovered 2026-05-26 while making the comms/statuses.sh three-pane dashboard responsive.
---

# Terminal width detection in Bash — `stty size </dev/tty`, not `tput cols`


[← Back to home](./)
## The trap

A CLI dashboard wants to lay out content in N equal columns sized to the user's terminal width. The intuitive choice:

```bash
cols=$(tput cols 2>/dev/null || echo 200)
col_w=$(( (cols - gap*(n-1)) / n ))
```

This is **unreliable inside command substitution `$(...)`**. `tput` queries terminal capabilities via the terminfo database and the kernel's window-size ioctl. The ioctl needs an open file descriptor connected to the controlling terminal. Inside `$(...)`, Bash redirects stdout to a pipe so the value can be captured — and on some Bash builds (notably macOS's `/bin/bash 3.2.57` and some Homebrew variants), tput then falls back to its default of **80 columns** because it can't probe the terminal through the pipe.

Symptom: you resize an iTerm2 / Apple Terminal window from 100 cols out to 220 cols, and your dashboard's columns never grow. They stay glued to the width they had when the loop started, or to 80. `clear`+`render` cycles don't help because every `render` re-reads the broken value.

## The durable answer

```bash
get_term_cols() {
  local c
  if c=$(stty size </dev/tty 2>/dev/null); then
    c="${c#* }"                              # "rows cols" → "cols"
    if [[ "$c" =~ ^[0-9]+$ && "$c" -gt 0 ]]; then
      printf '%s' "$c"; return
    fi
  fi
  if [[ -n "${COLUMNS:-}" && "$COLUMNS" -gt 0 ]]; then
    printf '%s' "$COLUMNS"; return
  fi
  if c=$(tput cols 2>/dev/null); then
    [[ "$c" -gt 0 ]] && { printf '%s' "$c"; return; }
  fi
  printf '200'
}
```

Why this works:

1. **`stty size </dev/tty`** — opens the controlling terminal device explicitly (`</dev/tty`) regardless of what stdout/stdin are redirected to. The kernel reads the current `TIOCGWINSZ` from the tty. Output is `"<rows> <cols>"`. Works inside `$(...)`, pipes, subshells, tmux, screen, iTerm2, Apple Terminal, ssh sessions. **This is the most portable terminal-size query on macOS/Linux.**
2. **`$COLUMNS`** — fallback. Bash maintains this as a magic variable and updates it on SIGWINCH **in interactive shells**, but not always in scripts. Worth checking second.
3. **`tput cols`** — last resort. Sometimes works, sometimes doesn't.
4. **Hardcoded fallback** — better 200 than 80, since 80 produces visibly broken output and 200 is "looks fine on most modern displays."

## Resize handling — SIGWINCH

Even with correct width detection, a long `sleep N` between renders means resizes feel laggy. Catch the signal:

```bash
RESIZED=1
trap 'RESIZED=1' WINCH
while true; do
  if [[ "$RESIZED" == "1" ]]; then
    clear; render; RESIZED=0
  fi
  # Short naps that wake on SIGWINCH so resize feels instant.
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    sleep 1
    [[ "$RESIZED" == "1" ]] && break
  done
  [[ "$RESIZED" != "1" ]] && { clear; render; }
done
```

Bash's `sleep` is interruptible by signals. `trap '…' WINCH` sets a flag, the loop breaks out of the inner 10×1s wait, re-renders. Effect: resizes reflow within ~1 second; idle refresh still happens every 10 s.

## How to apply

- Any Bash CLI that lays out columns, ASCII tables, progress bars, or any width-dependent rendering: use `stty size </dev/tty` first.
- Always provide a hardcoded fallback (200 is fine) so non-tty contexts don't divide by zero.
- For `--watch` style loops: trap SIGWINCH and break the sleep early so the user sees layout follow their drag in ≤1 s, not after the next 10 s tick.

## Companion concepts

- `concepts/pr-m-utf8-trap.md` — once you know the right width, BSD `pr -m` will still byte-truncate your separator lines mid-UTF-8-codepoint. Use Python's `unicodedata.east_asian_width` for actual character-width-aware merging.

## Reference implementation

`~/work/comms/statuses.sh` — three-pane status dashboard, this width-detection function plus SIGWINCH handling, in 30 lines of Bash.

## Status

- 2026-05-26 — discovered after multiple "the columns don't widen when I resize" frustrations. `tput cols` had been returning 80 inside `$(...)` while Esa's iTerm2 was at 200+. Replaced with `stty size`. Verified on macOS Sequoia 15.6.1 / iTerm2 / Apple Terminal.
