# _apple_energy.py — shared process/terminal/claude introspection for apple-energy.
# Imported by the `now` and `claude` verbs (both add APPLE_ENERGY_BIN to sys.path).
# Apple-native: only shells out to ps / pgrep / lsof. No deps.

import os
import subprocess

# terminal-emulator comm substrings → display name (walked up the ppid chain)
TERMS = {
    "iterm2": "iTerm2", "iterm": "iTerm2", "terminal": "Terminal",
    "ghostty": "Ghostty", "wezterm": "WezTerm", "kitty": "kitty",
    "alacritty": "Alacritty", "warp": "Warp", "hyper": "Hyper",
    "tmux": "tmux", "screen": "screen", "vscode": "VSCode",
    "code helper": "VSCode", "electron": "Electron",
}
# generic interpreters whose bare name is useless — annotate with script/parent
_RUNTIME_PREFIXES = ("python", "node", "ruby", "perl", "bash", "zsh",
                     "deno", "bun", "java", "php", "osascript")


def _run(cmd):
    try:
        return subprocess.run(cmd, capture_output=True, text=True).stdout
    except Exception:
        return ""


def base(c):
    return os.path.basename(c) if "/" in c else c


def tilde(p):
    if not p:
        return p
    return p.replace(os.path.expanduser("~"), "~")


def is_runtime(low):
    return low == "sh" or any(low.startswith(r) for r in _RUNTIME_PREFIXES)


def proc_maps():
    """Return (info, args): pid -> (ppid, comm) and pid -> full command line."""
    info = {}
    for l in _run(["ps", "-ww", "-Ao", "pid=,ppid=,comm="]).splitlines():
        parts = l.split(None, 2)
        if len(parts) == 3:
            info[parts[0]] = (parts[1], parts[2])
    args = {}
    for l in _run(["ps", "-ww", "-Ao", "pid=,command="]).splitlines():
        pid, _, cmd = l.strip().partition(" ")
        if pid:
            args[pid] = cmd
    return info, args


def terminal_of(pid, info):
    """Walk the parent chain until we hit a known terminal emulator."""
    cur, seen = pid, 0
    while cur in info and seen < 40:
        seen += 1
        ppid, comm = info[cur]
        b = base(comm).lower()
        for k, v in TERMS.items():
            if k in b:
                return v
        if cur == "1" or ppid in ("0", ""):
            break
        cur = ppid
    return ""


def version_of(pid):
    """Claude Code version = basename of the running executable under versions/."""
    for ln in _run(["lsof", "-p", str(pid)]).splitlines():
        f = ln.split()
        if len(f) >= 9 and f[3] == "txt" and "/versions/" in ln:
            return base(f[-1])
    return ""


def cwd_of(pid):
    for ln in _run(["lsof", "-a", "-p", str(pid), "-d", "cwd", "-Fn"]).splitlines():
        if ln.startswith("n"):
            return ln[1:]
    return ""


def claude_pids():
    pids = set()
    for src in (["pgrep", "-x", "claude"], ["pgrep", "-f", "/versions/2."]):
        for x in _run(src).split():
            pids.add(x)
    return sorted(pids, key=lambda s: int(s) if s.isdigit() else 0)


def annotate(pid, info, args):
    """A human-readable 'what is this process' string for the `now` table."""
    pp = info.get(pid)
    if not pp:
        return "?"
    ppid, comm = pp
    name, low = base(comm), base(comm).lower()
    term = terminal_of(pid, info)
    if low == "claude" or "/versions/2." in comm:
        s = "claude"
        v = version_of(pid)
        cwd = cwd_of(pid)
        if v:
            s += " " + v
        if cwd:
            s += " in " + tilde(cwd)
        if term:
            s += " (" + term + ")"
        return s
    if is_runtime(low):
        toks = args.get(pid, "").split()
        script = ""
        for t in toks[1:]:
            if t.startswith("-"):
                continue
            script = base(t)
            break
        par = info.get(ppid)
        tail = term or (base(par[1]) if par else "")
        lbl = name
        if script:
            lbl += " — " + script
        if tail:
            lbl += " (← " + tail + ")"
        return lbl
    return name
