#!/usr/bin/env python3
"""gen-boot-app.py — emit the boot-app AppleScript from panes.conf.

Reads a panes.conf (Name|command per line) and prints an iTerm2 AppleScript
that opens one window with one pane per line, each running its command. The
output carries the SSH-launch window guard so `open` over SSH works headless.

Apple-native: stdlib only. Pipe the output to osacompile (see build.sh).

Usage:  gen-boot-app.py [panes.conf]   # default: ./panes.conf next to this file
"""
import os
import sys


def esc(s: str) -> str:
    """Escape a string for an AppleScript double-quoted literal."""
    return s.replace("\\", "\\\\").replace('"', '\\"')


def load_panes(path):
    panes = []
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            name, _, cmd = line.partition("|")
            panes.append((name.strip(), cmd.strip()))
    return panes


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    conf = sys.argv[1] if len(sys.argv) > 1 else os.path.join(here, "panes.conf")
    if not os.path.exists(conf):
        sys.exit(f"no panes.conf at {conf} (copy panes.conf.example)")
    panes = load_panes(conf)
    if not panes:
        sys.exit(f"{conf} lists no panes")

    out = []
    out.append('tell application "iTerm"')
    out.append("    activate")
    out.append("    delay 2")
    out.append("    -- SSH-launch rescue: `open` over SSH does not restore a")
    out.append("    -- window. Without this guard `tell current window` errors -1728.")
    out.append("    if (count of windows) is 0 then")
    out.append("        create window with default profile")
    out.append("        delay 1")
    out.append("    end if")
    out.append("    tell current window")

    # First pane = the initial session. Each subsequent pane splits the
    # previous one, alternating vertical/horizontal so panes stay readable.
    for i, (name, cmd) in enumerate(panes):
        sv = f"sess{i}"
        if i == 0:
            out.append(f"        set {sv} to current session")
        else:
            direction = "vertically" if i % 2 == 1 else "horizontally"
            out.append(
                f"        tell sess{i-1} to set {sv} to "
                f"(split {direction} with default profile)"
            )
        out.append(f"        tell {sv}")
        out.append(f'            set name to "{esc(name)}"')
        if cmd:
            out.append(f'            write text "{esc(cmd)}"')
        out.append("        end tell")

    out.append("    end tell")
    out.append("end tell")
    print("\n".join(out))


if __name__ == "__main__":
    main()
