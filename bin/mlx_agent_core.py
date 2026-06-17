"""mlx_agent_core — the agentic tool-calling loop + SAFE verb registry, shared.

Both the interactive CLI (bin/mlx-agent, Tailscale path) and the Mini-resident
queue worker (bin/fm-agent-service, Comms/Syncthing path) import this ONE core, so
the loop and the tool registry are never duplicated.

    model reasons → calls a convey/apple verb as a TOOL → reads result → repeats

SAFE by construction: read-only / idempotent verbs only, argv-array exec (never a
shell string), paths sandboxed under ROOT (default $HOME; the queue worker tightens
it to ~/work via AGENT_ROOT), every tool output bounded, the loop capped.

GROUNDED by construction: search_notes surfaces the winning FILES and the loop will
not accept an answer that cites a file the model never opened with read_file (it is
re-prompted to open + verify in the source first); fabricated paths are flagged.

FEATURE-CARD >> features/mlx-agent-tool-loop.feature
"""
from __future__ import annotations

import json
import os
import re as _re
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

# Anti-hallucination rule appended to the system prompt; the loop enforces it.
GROUNDING = ("GROUNDING RULES: Only cite or quote a file you actually opened with "
             "read_file this turn. After search_notes, open the single most relevant "
             "file with read_file and confirm the answer is in its text before you cite "
             "it. If search_notes returns nothing relevant, say you could not find it — "
             "do NOT invent a file path, a wiki page, or a quote.")

# cited path inside backticks `x.md` or a markdown link ](x.md) — linear, no backtracking.
_CITE_RE = _re.compile(r"`([A-Za-z0-9_][A-Za-z0-9_./-]*\.(?:md|markdown|txt|py|sh|json|feature|ya?ml))`"
                       r"|\]\(([A-Za-z0-9_][A-Za-z0-9_./-]*\.(?:md|markdown|txt|py|sh|json|feature|ya?ml))\)")
# a vault-grep hit line: "0.521  FILE.ext:123  snippet" — pull the file.
_SEARCH_FILE_RE = _re.compile(r"^[0-9.]+\s+([A-Za-z0-9_./-]+\.\w+):\d+")


def _resolve(cand: str) -> str:
    p = Path(cand)
    return str(p.resolve()) if p.is_absolute() else str((Path.cwd() / cand).resolve())


def _cited_paths(answer: str):
    """(raw, resolved-on-disk | None) for each distinct cited *.ext path in the answer."""
    out, seen = [], set()
    for m in _CITE_RE.findall(answer or ""):
        cand = m[0] or m[1]
        if not cand or cand in seen:
            continue
        seen.add(cand)
        p = Path(cand)
        if p.is_absolute() and p.exists():
            out.append((cand, str(p.resolve())))
        elif (Path.cwd() / cand).exists():
            out.append((cand, str((Path.cwd() / cand).resolve())))
        else:
            out.append((cand, None))
    return out


def verify_citations(answer: str) -> list:
    """Cited file paths that do NOT exist on disk (the fabricated ones)."""
    return [raw for raw, res in _cited_paths(answer) if res is None]


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
    raw = _run([str(HERE / "vault-grep"), query, "--root", str(_safe_path(dir))])
    files = []
    for line in raw.splitlines():
        m = _SEARCH_FILE_RE.match(line.strip())
        if m and m.group(1) not in files:
            files.append(m.group(1))
    if files:
        return ("TOP FILES (open the single most relevant one with read_file and confirm "
                "the answer is in its text BEFORE you cite it): " + ", ".join(files[:5])
                + "\n" + raw)
    return raw + "\n[no files matched — do not invent one; say you could not find it]"


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
                       "files. Returns the top matching files + passages; OPEN the top file "
                       "with read_file to verify before citing it.",
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
    """The agentic loop. Returns {ok, answer, trace, iters, err, unverified, reprompts}.

    Grounding enforcement: the model may not finalise an answer that cites an existing
    file it did NOT open with read_file this loop — it is re-prompted (up to twice) to
    open + verify in the source. Cited paths that don't exist on disk are flagged."""
    messages = []
    if system:
        messages.append({"role": "system", "content": system})
    messages.append({"role": "user", "content": task})
    trace = []
    opened = set()          # resolved paths the model actually read this loop
    reprompts = 0
    for i in range(max_iters):
        try:
            data = post(messages, retries=retries, host=host, model=model, allow=allow)
        except Exception as e:
            return {"ok": False, "answer": "", "trace": trace, "iters": i,
                    "err": f"could not reach the MLX server at {host or HOST}: {e}",
                    "unverified": [], "reprompts": reprompts}
        msg = data["choices"][0]["message"]
        calls = msg.get("tool_calls") or []
        if not calls:
            answer = (msg.get("content") or "").strip()
            cited = _cited_paths(answer)
            unopened = [raw for raw, res in cited if res and res not in opened]
            missing = [raw for raw, res in cited if res is None]
            if unopened and reprompts < 2 and i < max_iters - 1:
                reprompts += 1
                messages.append({"role": "assistant", "content": answer})
                it = "it" if len(unopened) == 1 else "them"
                messages.append({"role": "user", "content":
                    f"Do not answer yet. You referenced {', '.join(unopened)} but did not "
                    f"open {it} with read_file this turn. Call read_file on the file, confirm "
                    f"the answer is actually in its text, then answer and cite it. If the file "
                    f"does not contain the answer, say so plainly."})
                continue
            if missing:
                answer += ("\n\n⚠ unverified citation(s) — not on disk, may be invented: "
                           + ", ".join(missing))
            return {"ok": True, "answer": answer, "trace": trace, "iters": i,
                    "err": None, "unverified": missing, "reprompts": reprompts}
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
            if name == "read_file" and args.get("path"):
                try:
                    opened.add(_resolve(args["path"]))
                except Exception:
                    pass
            trace.append({"name": name, "args": args, "result_len": len(result)})
            if on_tool:
                try:
                    on_tool(name, args, result)
                except Exception:
                    pass
            messages.append({"role": "tool", "tool_call_id": c.get("id", name),
                             "name": name, "content": result})
    return {"ok": False, "answer": "", "trace": trace, "iters": max_iters,
            "err": f"hit the tool-call cap (max_iters={max_iters}) without a final answer",
            "unverified": [], "reprompts": reprompts}
