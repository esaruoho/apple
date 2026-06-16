"""relay_core — hand an MLX (small-model) exchange to Claude, in the repo.

The loop Esa wants: talk to the free local MLX brain to draft/explore, then
RELAY that to Claude (the capable model) either to (a) judge how well MLX did,
or (b) actually make the code changes. This module is the shared seam used by
both `bin/mlx-relay` (named Converse/fm-converse discussions) and `fm-chat`'s
in-REPL `/relay` — so the prompt shape + the `claude` invocation live in ONE
place (DRY).

Modes:
  critique — claude reads the repo (read-only tools) and grades MLX's answer.
  apply    — claude may Edit/Write to implement it (supervised by the allowlist;
             you git-diff after). The model invoked it knowingly.
  copy     — assemble the Claude-ready prompt and put it on the clipboard, to
             paste into an interactive Claude where you watch every edit.
"""
from __future__ import annotations

import subprocess
import sys

# Tool allowlists per mode. critique stays read-only; apply grants edits.
_ALLOWED = {
    "critique": ["Read", "Grep", "Glob", "Bash(git *)"],
    "apply":    ["Read", "Grep", "Glob", "Edit", "Write", "Bash(git *)"],
}


def format_exchange(turns) -> str:
    """turns = [(role, text), ...] → a readable transcript block."""
    out = []
    for role, text in turns:
        who = "Me" if role == "user" else "MLX"
        out.append(f"{who}: {text}")
    return "\n\n".join(out)


def build_prompt(exchange: str, repo: str, mode: str, note: str = "") -> str:
    note = (note or "").strip()
    tail = f"\n\nAlso: {note}" if note else ""
    if mode == "apply":
        return (
            f"A smaller on-device model (MLX Qwen3-4B, running locally) was asked "
            f"about the project in this directory ({repo}). Here is the exchange:\n\n"
            f"------\n{exchange}\n------\n\n"
            f"Implement this in the repo. If the model's suggestion is wrong, "
            f"incomplete, or unsafe, implement the CORRECT version instead and say "
            f"how it differed from what the model claimed. Make the actual edits, "
            f"then summarize the diff (files + what changed)." + tail
        )
    # critique (default)
    return (
        f"I asked a smaller on-device model (MLX Qwen3-4B, running locally) about "
        f"the project in this directory ({repo}). Here is the exchange:\n\n"
        f"------\n{exchange}\n------\n\n"
        f"Assess how correct and complete the model's answer is AGAINST THE ACTUAL "
        f"CODE in this repo — read the relevant files. State plainly: what it got "
        f"right, what's wrong or hallucinated, what's missing, and what I should "
        f"double-check. Cite real files/lines. Don't edit anything." + tail
    )


def run_claude(prompt: str, repo: str, mode: str) -> int:
    """Run `claude -p` in `repo` with the mode's tool allowlist, streaming Claude's
    output to this terminal. Returns claude's exit code (127 if not installed).

    NOTE: `--allowedTools <tools...>` is VARIADIC — if the prompt follows it as a
    positional, claude eats the prompt as tool names ("Input must be provided…").
    So we pass the allowlist as ONE space-joined string and feed the prompt on
    STDIN, which can't be swallowed."""
    allowed = " ".join(_ALLOWED.get(mode, _ALLOWED["critique"]))
    cmd = ["claude", "-p", "--allowedTools", allowed]
    try:
        return subprocess.run(cmd, cwd=repo or None, input=prompt, text=True).returncode
    except FileNotFoundError:
        sys.stderr.write("relay: `claude` CLI not found on PATH.\n")
        return 127


def to_clipboard(prompt: str) -> bool:
    try:
        subprocess.run(["pbcopy"], input=prompt, text=True, timeout=10, check=True)
        return True
    except Exception:
        return False


def relay(turns, repo: str, mode: str = "critique", note: str = "") -> int:
    """The one entry point. turns=[(role,text)...] (the exchange to relay)."""
    if not turns:
        sys.stderr.write("relay: nothing to relay (no MLX turns).\n")
        return 2
    exchange = format_exchange(turns)
    prompt = build_prompt(exchange, repo, mode, note)
    if mode == "copy":
        if to_clipboard(prompt):
            print(f"✓ relay prompt on the clipboard ({len(prompt)} chars).")
            print(f"  Paste it into an interactive Claude in {repo or 'this repo'} "
                  f"(`cd {repo} && claude`) where you can supervise every edit.")
            return 0
        sys.stderr.write("relay: pbcopy failed.\n")
        return 1
    banner = ("⟶ relaying to Claude for ANALYSIS (read-only) …" if mode == "critique"
              else "⟶ relaying to Claude to APPLY CHANGES (it may edit files — git diff after) …")
    print(banner)
    print(f"  repo: {repo or '(current dir)'}\n")
    return run_claude(prompt, repo, mode)
