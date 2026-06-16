"""mlx_agent_core — the agentic tool-calling loop + SAFE verb registry, shared.

Both the interactive CLI (bin/mlx-agent, Tailscale path) and the Mini-resident
queue worker (bin/fm-agent-service, Comms/Syncthing path) import this ONE core, so
the loop and the tool registry are never duplicated.

    model reasons → calls a convey/apple verb as a TOOL → reads result → repeats

SAFE by construction: read-only / idempotent verbs only, argv-array exec (never a
shell string), paths sandboxed under ROOT (default $HOME; the queue worker tightens
it to ~/work via AGENT_ROOT), every tool output bounded, the loop capped.

FEATURE-CARD >> features/mlx-agent-tool-loop.feature
"""
from __future__ import annotations

import json
import os
import subprocess
import time
import urllib.error
import urllib.request
from pathlib import Path

HERE = Path(__file__).resolve().parent
HOME = Path.home()
# ROOT bounds every tool path. Default = $HOME (the CLI). The queue worker sets
# AGENT_ROOT=~/work to tighten the blast radius of jobs arriving over Syncthing.
ROOT = Path(os.environ.get("AGENT_ROOT", str(HOME))).expanduser().resolve()

HOST = os.environ.get("FM_MLX_HOST", "http://cloudcitymacmini:8080")
MODEL = os.environ.get("FM_MLX_MODEL", "")     # "" → server picks its loaded model
TOOL_OUTPUT_CAP = 4000
HTTP_TIMEOUT = 180
CONVEY = str(HERE / "convey")


# ── sandbox ──────────────────────────────────────────────────────────────────
def _safe_path(p: str) -> Path:
    rp = Path(p).expanduser()
    if not rp.is_absolute():
        rp = Path.cwd() / rp
    rp = rp.resolve()
    if ROOT not in rp.parents and rp != ROOT:
        raise ValueError(f"refused: {rp} is outside {ROOT}")
    return rp


def _run(argv: list, cap: int = TOOL_OUTPUT_CAP) -> str:
    try:
        r = subprocess.run(argv, capture_output=True, text=True, timeout=120)
    except subprocess.TimeoutExpired:
        return f"[tool timed out after 120s: {' '.join(argv[:2])}]"
    except FileNotFoundError:
        return f"[tool not found: {argv[0]}]"
    out = (r.stdout or "") + (("\n[stderr] " + r.stderr) if r.returncode and r.stderr else "")
    out = out.strip() or "[no output]"
    return out[:cap] + ("\n…[truncated]" if len(out) > cap else "")


# ── tools (read-only / idempotent) ───────────────────────────────────────────
def t_list_dir(path="."):
    p = _safe_path(path)
    if not p.is_dir():
        return f"[not a directory: {p}]"
    items = sorted(e.name + ("/" if e.is_dir() else "") for e in p.iterdir()
                   if not e.name.startswith("."))
    return f"{p} ({len(items)} entries):\n" + "\n".join(items[:200])


def t_read_file(path, max_bytes=8000, offset=0):
    p = _safe_path(path)
    if not p.is_file():
        return f"[not a file: {p}]"
    try:
        full = p.read_text(encoding="utf-8", errors="replace")
    except Exception as e:
        return f"[unreadable: {e}]"
    off, cap = int(offset), int(max_bytes)
    chunk = full[off: off + cap]
    rest = len(full) - (off + len(chunk))
    if rest > 0:
        chunk += (f"\n[truncated: {rest} more bytes — call read_file again with "
                  f"offset={off + len(chunk)} to continue]")
    return chunk


def t_search_notes(query, dir="."):
    return _run([str(HERE / "vault-grep"), query, "--root", str(_safe_path(dir))])


def t_molecule(path):
    return _run([CONVEY, "molecule", str(_safe_path(path))])


def t_ask_file(path, question):
    return _run([CONVEY, "ask", str(_safe_path(path)), question])


def t_vision_ocr(path):
    return _run([str(HERE / "vision-ocr"), str(_safe_path(path))])


def t_folder_memory(dir="."):
    return _run([str(HERE / "folder-memory"), str(_safe_path(dir)), "--show"])


def t_tag_find(name, scope=None):
    argv = [str(HERE / "tag"), "find", name]
    if scope:
        argv += ["--scope", str(_safe_path(scope))]
    return _run(argv)


TOOLS: dict = {
    "list_dir": (t_list_dir, {
        "description": "List the non-hidden entries of a directory (under the agent root).",
        "parameters": {"type": "object", "properties": {
            "path": {"type": "string", "description": "directory path (default '.')"}}}}),
    "read_file": (t_read_file, {
        "description": "Read a text file (under the agent root). Long files are paged: if "
                       "the result ends with '[truncated: N more bytes — offset=…]', call "
                       "again with that offset to read the rest.",
        "parameters": {"type": "object", "properties": {
            "path": {"type": "string"},
            "max_bytes": {"type": "integer", "description": "bytes per read, default 8000"},
            "offset": {"type": "integer", "description": "byte offset, default 0"}},
            "required": ["path"]}}),
    "search_notes": (t_search_notes, {
        "description": "On-device semantic search (Apple NLEmbedding) over a folder's text "
                       "files. Returns the most relevant passages with file paths.",
        "parameters": {"type": "object", "properties": {
            "query": {"type": "string"},
            "dir": {"type": "string", "description": "folder to search (default '.')"}},
            "required": ["query"]}}),
    "molecule": (t_molecule, {
        "description": "Show a file's molecule — its typed bonds to other files "
                       "(part_of, produces, derived_from, associated_with).",
        "parameters": {"type": "object", "properties": {
            "path": {"type": "string"}}, "required": ["path"]}}),
    "ask_file": (t_ask_file, {
        "description": "Answer a question about a specific file, grounded in its molecule context.",
        "parameters": {"type": "object", "properties": {
            "path": {"type": "string"}, "question": {"type": "string"}},
            "required": ["path", "question"]}}),
    "vision_ocr": (t_vision_ocr, {
        "description": "Extract text from an image or PDF with Apple Vision (on-device).",
        "parameters": {"type": "object", "properties": {
            "path": {"type": "string"}}, "required": ["path"]}}),
    "folder_memory": (t_folder_memory, {
        "description": "Show a folder's .memory.md — its auto-formulated understanding.",
        "parameters": {"type": "object", "properties": {
            "dir": {"type": "string", "description": "default '.'"}}}}),
    "tag_find": (t_tag_find, {
        "description": "Find files carrying a given Finder tag (via Spotlight/mdfind).",
        "parameters": {"type": "object", "properties": {
            "name": {"type": "string"},
            "scope": {"type": "string", "description": "optional folder to scope to"}},
            "required": ["name"]}}),
}


def openai_tools(allow: list | None = None) -> list:
    """The tools schema. `allow` may NARROW the registry (never widen it)."""
    names = [n for n in TOOLS if (allow is None or n in allow)]
    return [{"type": "function", "function": {"name": n, **TOOLS[n][1]}} for n in names]


def exec_tool(name: str, args: dict) -> str:
    fn = TOOLS.get(name, (None, None))[0]
    if fn is None:
        return f"[unknown tool: {name}]"
    try:
        return fn(**(args or {}))
    except TypeError as e:
        return f"[bad arguments for {name}: {e}]"
    except ValueError as e:
        return f"[{e}]"
    except Exception as e:
        return f"[tool {name} error: {e}]"


def post(messages: list, retries: int = 4, host: str | None = None,
         model: str | None = None, allow: list | None = None) -> dict:
    """One round-trip, retrying through transient 500/502/503/504 reload windows."""
    body = {"messages": messages, "tools": openai_tools(allow), "tool_choice": "auto"}
    m = model if model is not None else MODEL
    if m:
        body["model"] = m
    data = json.dumps(body).encode()
    url = f"{host or HOST}/v1/chat/completions"
    last = None
    for attempt in range(retries):
        try:
            req = urllib.request.Request(url, data=data,
                                         headers={"Content-Type": "application/json"})
            with urllib.request.urlopen(req, timeout=HTTP_TIMEOUT) as resp:
                return json.loads(resp.read().decode())
        except urllib.error.HTTPError as e:
            last = e
            if e.code not in (500, 502, 503, 504):
                raise
        except (urllib.error.URLError, ConnectionError) as e:
            last = e
        if attempt < retries - 1:
            time.sleep(2.0 * (attempt + 1))
    raise last if last else RuntimeError("post failed")


def run_loop(task: str, system: str = "", max_iters: int = 6, on_tool=None,
             host: str | None = None, model: str | None = None,
             allow: list | None = None, retries: int = 4) -> dict:
    """The agentic loop. Returns {ok, answer, trace, iters, err}.
    on_tool(name, args, result) is called after each tool executes (the worker
    uses it to stream a partial trace; the CLI uses it to print live tool calls)."""
    messages = []
    if system:
        messages.append({"role": "system", "content": system})
    messages.append({"role": "user", "content": task})
    trace = []
    for i in range(max_iters):
        try:
            data = post(messages, retries=retries, host=host, model=model, allow=allow)
        except Exception as e:
            return {"ok": False, "answer": "", "trace": trace, "iters": i,
                    "err": f"could not reach the MLX server at {host or HOST}: {e}"}
        msg = data["choices"][0]["message"]
        calls = msg.get("tool_calls") or []
        if not calls:
            return {"ok": True, "answer": (msg.get("content") or "").strip(),
                    "trace": trace, "iters": i, "err": None}
        messages.append({"role": "assistant", "content": msg.get("content") or "",
                         "tool_calls": calls})
        for c in calls:
            fn = c.get("function", {})
            name = fn.get("name", "")
            try:
                args = json.loads(fn.get("arguments") or "{}")
            except Exception:
                args = {}
            if allow is not None and name not in allow:
                result = f"[tool {name} not permitted for this job]"
            else:
                result = exec_tool(name, args)
            trace.append({"name": name, "args": args, "result_len": len(result)})
            if on_tool:
                try:
                    on_tool(name, args, result)
                except Exception:
                    pass
            messages.append({"role": "tool", "tool_call_id": c.get("id", name),
                             "name": name, "content": result})
    return {"ok": False, "answer": "", "trace": trace, "iters": max_iters,
            "err": f"hit the tool-call cap (max_iters={max_iters}) without a final answer"}
