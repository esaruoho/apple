# _apple_energy.py — shared process/terminal/claude introspection for apple-energy.
# Imported by the `now`, `claude`, and `jump` verbs (all add APPLE_ENERGY_BIN to sys.path).
# Apple-native: only shells out to ps / pgrep / lsof / osascript. No deps.

import os
import re
import glob
import json
import time
import calendar
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


# strip OSC 8 hyperlinks + SGR colour codes so column widths use VISIBLE length
_ESC_RE = re.compile(r"\x1b\]8;;.*?(?:\x1b\\|\x07)|\x1b\[[0-9;]*m")


def _vislen(s):
    return len(_ESC_RE.sub("", str(s)))


def hyperlink(url, text):
    """OSC 8 terminal hyperlink — Cmd-click in iTerm2/Terminal follows the URL."""
    return "\x1b]8;;%s\x1b\\%s\x1b]8;;\x1b\\" % (url, text)


def render_table(headers, rows, aligns=None):
    """Unicode box-drawing table, hyperlink/colour-aware (pads by visible width).
    aligns: list of 'l'|'r' per data column; headers are centered."""
    cols = len(headers)
    widths = [_vislen(h) for h in headers]
    for r in rows:
        for i in range(cols):
            widths[i] = max(widths[i], _vislen(r[i]))
    aligns = (aligns or ["l"] * cols)

    def pad(s, w, a):
        s = str(s)
        extra = max(0, w - _vislen(s))
        if a == "c":
            left = extra // 2
            return " " * left + s + " " * (extra - left)
        if a == "r":
            return " " * extra + s
        return s + " " * extra

    def border(left, mid, right):
        return left + mid.join("─" * (w + 2) for w in widths) + right

    def line(cells, al):
        return "│" + "│".join(" " + pad(c, w, a) + " "
                              for c, w, a in zip(cells, widths, al)) + "│"

    out = [border("┌", "┬", "┐"),
           line(headers, ["c"] * cols),
           border("├", "┼", "┤")]
    for r in rows:
        out.append(line(r, aligns))
    out.append(border("└", "┴", "┘"))
    return "\n".join(out)


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


# ---- session-name mapping (PID → Claude Code session + its title) ----------
# Claude Code stores one transcript per session at
#   ~/.claude/projects/<encoded-cwd>/<session-id>.jsonl
# The running process doesn't keep it open, but a session's first message
# timestamp == the process's start time (to the second), so we pair PID↔session
# by start time; the name is customTitle → summary → first user-message snippet.

def _proj_dir(cwd):
    return os.path.expanduser("~/.claude/projects/" + re.sub(r"[^A-Za-z0-9]", "-", cwd))


def _iso_epoch(ts):
    m = re.match(r"(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})", ts or "")
    if not m:
        return None
    return calendar.timegm(tuple(int(x) for x in m.groups()) + (0, 0, 0))  # ts is UTC


def _first_ts_epoch(path):
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            for i, line in enumerate(f):
                if i > 30:
                    break
                if '"timestamp"' not in line:
                    continue
                try:
                    ts = json.loads(line).get("timestamp")
                except Exception:
                    continue
                if ts:
                    return _iso_epoch(ts)
    except OSError:
        pass
    return None


def pid_start_epoch(pid):
    out = _run(["ps", "-p", str(pid), "-o", "lstart="]).strip()
    if not out:
        return None
    try:
        return time.mktime(time.strptime(out, "%a %b %d %H:%M:%S %Y"))  # local → epoch
    except Exception:
        return None


def session_name(path):
    ct = summ = snip = None
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            for line in f:
                try:
                    d = json.loads(line)
                except Exception:
                    continue
                t = d.get("type")
                if t == "custom-title" and d.get("customTitle"):
                    ct = d["customTitle"]  # last-write-wins
                elif t == "summary" and not summ:
                    summ = d.get("summary") or d.get("text")
                elif t == "user" and snip is None:
                    c = (d.get("message") or {}).get("content", "")
                    if isinstance(c, list):
                        c = " ".join(x.get("text", "") for x in c
                                     if isinstance(x, dict) and x.get("type") == "text")
                    c = str(c).strip().replace("\n", " ")
                    if c and not c.startswith("<"):
                        snip = c
    except OSError:
        pass
    return (ct or summ or snip or "").strip()


def _session_for(pid, info, claimed):
    cwd = cwd_of(pid)
    if not cwd:
        return (None, "", False)
    files = glob.glob(os.path.join(_proj_dir(cwd), "*.jsonl"))
    if not files:
        return (None, "", False)
    files.sort(key=lambda p: os.path.getmtime(p) if os.path.exists(p) else 0, reverse=True)
    files = files[:60]
    pstart = pid_start_epoch(pid)
    best, bestdelta = None, None
    if pstart is not None:
        for fp in files:
            if fp in claimed:
                continue
            st = _first_ts_epoch(fp)
            if st is None:
                continue
            dl = abs(st - pstart)
            if bestdelta is None or dl < bestdelta:
                best, bestdelta = fp, dl
    if best is not None and bestdelta is not None and bestdelta <= 180:
        return (best, session_name(best), True)          # confident (start-time match)
    for fp in files:                                     # fallback: freshest unclaimed
        if fp not in claimed:
            return (fp, session_name(fp), False)
    return (None, "", False)


def session_map(info):
    """pid -> (name, confident). Confident = start-times matched within 180s."""
    out, claimed = {}, set()
    for p in sorted(claude_pids(), key=lambda p: pid_start_epoch(p) or 0):
        fp, name, conf = _session_for(p, info, claimed)
        if fp:
            claimed.add(fp)
        out[p] = (name, conf)
    return out


def annotate(pid, info, args, topcmd="", cur="", sessmap=None):
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
        nm = ""
        if sessmap and pid in sessmap and sessmap[pid][0]:
            name, conf = sessmap[pid]
            nm = " «%s»" % ((name if conf else "~" + name)[:34])
        return "claude %s %s%s · %s · %s · %s %s" % (
            r["ver"], flag, nm, r["age"], r["cwd"], r["term"], r["tty"])
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
