# _apple_energy.py — shared process/terminal/claude introspection for apple-energy.
# Imported by the `now`, `claude`, and `jump` verbs (all add APPLE_ENERGY_BIN to sys.path).
# Apple-native: only shells out to ps / pgrep / lsof / osascript. No deps.

import os
import subprocess

# terminal-emulator comm substrings → display name (walked up the ppid chain)
TERMS = {
    "iterm2": "iTerm2", "iterm": "iTerm2", "terminal": "Terminal",
    "ghostty": "Ghostty", "wezterm": "WezTerm", "kitty": "kitty",
    "alacritty": "Alacritty", "warp": "Warp", "hyper": "Hyper",
    "tmux": "tmux", "screen": "screen",
}
# generic interpreters whose bare name is useless — annotate with script/parent
_RUNTIME_PREFIXES = ("python", "node", "ruby", "perl", "bash", "zsh",
                     "deno", "bun", "java", "php", "osascript")
# well-known system processes → one-line "what it is" (so "WindowServer" isn't a mystery)
KNOWN = {
    "WindowServer": "macOS display compositor (system, can't quit)",
    "kernel_task": "macOS kernel",
    "mds": "Spotlight indexing", "mds_stores": "Spotlight index store",
    "mdworker": "Spotlight worker", "mdworker_shared": "Spotlight worker",
    "mediaanalysisd": "Photos media analysis (faces/scenes)",
    "photoanalysisd": "Photos analysis",
    "coreaudiod": "Core Audio server",
    "syncthing": "Syncthing file sync",
    "bluetoothd": "Bluetooth daemon", "hidd": "input devices",
    "cloudd": "iCloud sync", "bird": "iCloud Documents sync",
    "backupd": "Time Machine backup", "powerd": "power management",
    "spotlightknowledged": "Spotlight knowledge",
}


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


def human_age(etime):
    """ps etime ([[DD-]HH:]MM:SS) → readable '7d 22h' / '1h 29m' / '5m'."""
    if not etime or etime == "?":
        return "?"
    days = 0
    e = etime
    if "-" in e:
        d, e = e.split("-", 1)
        try:
            days = int(d)
        except ValueError:
            days = 0
    try:
        parts = [int(x) for x in e.split(":")]
    except ValueError:
        return etime
    while len(parts) < 3:
        parts.insert(0, 0)
    h, m, s = parts[-3], parts[-2], parts[-1]
    if days > 0:
        return "%dd %dh" % (days, h)
    if h > 0:
        return "%dh %dm" % (h, m)
    if m > 0:
        return "%dm" % m
    return "%ds" % s


def is_runtime(low):
    return low == "sh" or any(low.startswith(r) for r in _RUNTIME_PREFIXES)


def proc_maps():
    """Return (info, args): pid -> {ppid,etime,tty,comm} and pid -> full command."""
    info = {}
    for l in _run(["ps", "-ww", "-Ao", "pid=,ppid=,etime=,tty=,comm="]).splitlines():
        parts = l.split(None, 4)
        if len(parts) == 5:
            pid, ppid, etime, tty, comm = parts
            info[pid] = {"ppid": ppid, "etime": etime, "tty": tty, "comm": comm}
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
        ppid = info[cur]["ppid"]
        b = base(info[cur]["comm"]).lower()
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


def current_version():
    v = os.path.basename(os.path.realpath(os.path.expanduser("~/.local/bin/claude")))
    return v if v and v != "." else "?"


def claude_pids():
    pids = set()
    for src in (["pgrep", "-x", "claude"], ["pgrep", "-f", "/versions/2."]):
        for x in _run(src).split():
            pids.add(x)
    return sorted(pids, key=lambda s: int(s) if s.isdigit() else 0)


def claude_row(pid, info):
    """Full identity for one claude session (for the claude table + jump)."""
    d = info.get(pid, {})
    ver = version_of(pid) or "?"
    cur = current_version()
    return {
        "pid": pid,
        "ver": ver,
        "old": ver != cur and ver != "?" and cur != "?",
        "age": human_age(d.get("etime", "?")),
        "tty": d.get("tty", "?"),
        "term": terminal_of(pid, info) or "?",
        "cwd": tilde(cwd_of(pid)),
    }


def annotate(pid, info, args, topcmd="", cur=""):
    """Human-readable 'what is this process' for the `now` table."""
    d = info.get(pid)
    if not d:
        # process exited during top's sample window — top still knows its (truncated) name
        return ((topcmd or "?") + " · ended").strip()
    comm = d["comm"]
    name, low = base(comm), base(comm).lower()
    if low == "claude" or "/versions/2." in comm:
        r = claude_row(pid, info)
        flag = "OLD" if r["old"] else "ok"
        return "claude %s %s · %s · %s · %s %s" % (
            r["ver"], flag, r["age"], r["cwd"], r["term"], r["tty"])
    if name in KNOWN:
        return "%s — %s" % (name, KNOWN[name])
    if is_runtime(low):
        toks = args.get(pid, "").split()
        script = ""
        for t in toks[1:]:
            if t.startswith("-"):
                continue
            script = base(t)
            break
        par = info.get(d["ppid"])
        tail = terminal_of(pid, info) or (base(par["comm"]) if par else "")
        lbl = name
        if script:
            lbl += " — " + script
        if tail:
            lbl += " (← " + tail + ")"
        return lbl
    return name
