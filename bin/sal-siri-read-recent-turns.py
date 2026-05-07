#!/usr/bin/env python3
"""
Sal's Siri — recent-turns reader (v3 multi-turn context).

Invoked by the "Sal's Siri" Shortcut via a Run Shell Script action BEFORE the
Use Model call. Reads:
  ~/Library/Application Support/Sal-Siri/turn-log.jsonl
and emits a compact, model-ready text block:

  PREVIOUS TURN: {<last successful turn JSON>}
  RECENT TURNS:
    -1: <slug> [params=<...>] @ <app>:<sel> (<status>) <Δt ago>
    -2: <slug> [params=<...>] @ <app>:<sel> (<status>) <Δt ago>
    -3: <slug> [params=<...>] @ <app>:<sel> (<status>) <Δt ago>

Default: read up to 5 most-recent turns. Filter out turns older than 30 minutes
(stale state — voice users typically resume context within minutes, not hours).

Usage:
  ./read-recent-turns.py              # default: 5 turns, 30-min staleness window
  ./read-recent-turns.py 8 60         # last 8 turns, 60-minute window

Stdout is the entire text block to splice into the Shortcut's combined prompt.
Stderr is silent on success, brief diagnostic on file-missing.
"""
import json
import os
import sys
import time
from pathlib import Path

DEFAULT_N = 5
DEFAULT_STALE_MINUTES = 30

def main():
    n = int(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_N
    stale_minutes = float(sys.argv[2]) if len(sys.argv) > 2 else DEFAULT_STALE_MINUTES

    sal_dir = Path(os.path.expanduser("~/Library/Application Support/Sal-Siri"))
    log_path = sal_dir / "turn-log.jsonl"
    last_state_path = sal_dir / "last-state.json"

    # PREVIOUS TURN block — last successful turn from last-state.json
    if last_state_path.exists():
        try:
            last_state = json.load(open(last_state_path))
        except Exception:
            last_state = None
    else:
        last_state = None

    if last_state is None:
        print("PREVIOUS TURN: <none>")
    else:
        # Drop epoch timestamp from the rendered form (model doesn't need it)
        rendered = {k: v for k, v in last_state.items() if k != "timestamp"}
        print(f"PREVIOUS TURN: {json.dumps(rendered)}")

    # RECENT TURNS block — last N turns from turn-log.jsonl, freshest first,
    # filtered by staleness window
    if not log_path.exists():
        print("RECENT TURNS: <none>")
        return

    now = time.time()
    cutoff = now - stale_minutes * 60.0
    rows = []
    try:
        with open(log_path) as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    rows.append(json.loads(line))
                except json.JSONDecodeError:
                    continue
    except Exception as e:
        print(f"RECENT TURNS: <log read failed: {e}>")
        return

    # Filter and trim
    fresh = [r for r in rows if r.get("ts", 0) >= cutoff]
    recent = fresh[-n:][::-1]   # newest first

    if not recent:
        print("RECENT TURNS: <none in last %.0f min>" % stale_minutes)
        return

    print("RECENT TURNS:")
    for i, r in enumerate(recent, start=1):
        slug = r.get("slug", "?")
        params = r.get("params", {})
        status = r.get("status", "?")
        ctx = r.get("context", "")
        ts = r.get("ts", 0)
        delta_s = max(0, int(now - ts))
        if delta_s < 60:
            ago = f"{delta_s}s ago"
        elif delta_s < 3600:
            ago = f"{delta_s // 60}m ago"
        else:
            ago = f"{delta_s // 3600}h ago"
        params_s = json.dumps(params, separators=(",", ":")) if params else "{}"
        print(f"  -{i}: {slug} params={params_s} @ {ctx} ({status}) {ago}")

if __name__ == "__main__":
    main()
