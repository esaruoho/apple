"""Shared discovery + snapshot of running Claude Code sessions.

One copy of this logic, imported by both `sesh` and `port-revive`. Anything that
needs to know "which Claude Code sessions are alive, in which folders, with which
ids" comes here rather than re-rolling the ps/lsof/transcript dance.

FEATURE-CARD >> features/sesh.feature
"""

import json
import os
import re
import shlex
import subprocess
from datetime import datetime
from pathlib import Path

STATE = Path.home() / ".local" / "state" / "apple"
SNAPSHOT = STATE / "claude-sessions.json"

# The CLI is invoked by absolute path in some sessions and bare in others, so
# match on the trailing component rather than the whole word.
_PROC_RE = re.compile(r"^(\d+)\s+(\S*/)?claude\s*(.*)$")
_UUID_RE = re.compile(r"--resume\s+([0-9a-f-]{36})")


def _sh(cmd):
    try:
        return subprocess.run(cmd, capture_output=True, text=True).stdout or ""
    except Exception:
        return ""


def _pid_cwd(pid):
    for line in _sh(["lsof", "-a", "-p", str(pid), "-d", "cwd", "-Fn"]).splitlines():
        if line.startswith("n"):
            return line[1:]
    return None


def _newest_session_for(cwd):
    """Claude Code stores transcripts under ~/.claude/projects/<cwd, / -> ->."""
    proj = Path.home() / ".claude" / "projects" / cwd.replace("/", "-")
    if not proj.is_dir():
        return None
    js = sorted(proj.glob("*.jsonl"), key=lambda p: p.stat().st_mtime, reverse=True)
    return js[0].stem if js else None


def running():
    """[{pid, cwd, session, skip_perms, resume}] for every live Claude Code session."""
    me = os.getpid()
    out = []
    for line in _sh(["ps", "-axo", "pid=,command="]).splitlines():
        m = _PROC_RE.match(line.strip())
        if not m:
            continue
        pid = int(m.group(1))
        if pid == me or "shell-snapshots" in line:
            continue
        args = m.group(3)
        sid = (u.group(1) if (u := _UUID_RE.search(args)) else None)
        cwd = _pid_cwd(pid)
        if sid is None and cwd:
            sid = _newest_session_for(cwd)
        skip = "--dangerously-skip-permissions" in args
        out.append({
            "pid": pid,
            "cwd": cwd,
            "session": sid,
            "skip_perms": skip,
            "resume": resume_cmd(cwd, sid, skip),
        })
    return out


def resume_cmd(cwd, sid, skip_perms=True):
    """The shell one-liner that puts a session back where it was.

    cwd is shlex-quoted: real paths here contain spaces (the Paketti .xrnx one
    under Mobile Documents does).
    """
    if not (cwd and sid):
        return None
    flags = " --dangerously-skip-permissions" if skip_perms else ""
    return f"cd {shlex.quote(cwd)} && claude{flags} --resume {sid}"


def save(sessions):
    STATE.mkdir(parents=True, exist_ok=True)
    SNAPSHOT.write_text(json.dumps(
        {"saved": datetime.now().isoformat(timespec="seconds"), "sessions": sessions},
        indent=2))
    return SNAPSHOT


def load():
    if not SNAPSHOT.exists():
        return None
    try:
        return json.loads(SNAPSHOT.read_text())
    except Exception:
        return None
