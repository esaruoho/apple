# What we know about Paketti ↔ MCP — current state

Drafted: 2026-05-08, after the smoke-test demo (main.lua reload pipeline) and before the queue-bridge daemon was built. This is the landscape I should design against, not around.

## Three relevant skills, three different roles

| Skill | What it is | Where it lives | Direction |
|---|---|---|---|
| `paketti` | Dev skill for the 8-year QoL Lua tool inside Renoise (1,183 commits, 886 issues, ≈1,491-line `main.lua`, `_AUTO_RELOAD_DEBUG = true`). | `~/work/paketti` (iCloud-symlinked into Renoise's Tools dir, same inode). Skill at `~/.claude/skills/paketti/`. | Edit-target: this is the codebase Claude modifies. |
| `remcp` | A *Lua tool inside Renoise* (`com.renoise.ReMCP.xrnx`) that runs a JSON-RPC 2.0 / Streamable-HTTP MCP server on `localhost:19714/mcp`. ≈55 tools across song/transport/tracks/patterns/sequencer/instruments/devices. | `/Users/esaruoho/work/tools/Tools/com.renoise.ReMCP.xrnx`. Skill at `~/.claude/skills/remcp/`. Helper: `~/.claude/skills/remcp/rmcp.sh`. | **Outside → Renoise**: any client (Claude Code, Claude Desktop, curl) drives Renoise. No `eval_lua` tool exposed (deliberate security choice). |
| `renoise-mcp` | Python FastMCP server using **OSC** (`/renoise/*` UDP) instead of HTTP. Includes `evaluate_lua` for raw Lua eval, plus pattern-gen primitives (breakbeat styles, scale-aware basslines). | `https://github.com/zakhap/renoise-mcp`, brand-new (1 commit). Skill at `~/.claude/skills/renoise-mcp/`. | Outside → Renoise via OSC UDP 127.0.0.1:8000. |

`renoise-api` is the underlying API reference (Lua API v6.2 LuaCATS) the other skills lean on.

## State on this Mac, right now

- **Renoise 3.5.4** is running (PID 5577, frontmost-able via System Events).
- **Paketti** is loaded (`org.lackluster.Paketti.xrnx` in V3.5.4 Tools dir, `_AUTO_RELOAD_DEBUG = true`, our smoke-branch in `main.lua` already proven end-to-end at 17:41).
- **ReMCP** is installed at `~/work/tools/Tools/com.renoise.ReMCP.xrnx` but the server is **not running** — `lsof :19714` empty, `GET /health` empty. The user has to flip it on inside Renoise (Tools menu → ReMCP → Start) or via the Pattern Editor menu entry.
- **renoise-mcp (Python OSC)** — not verified installed locally; it's a separate repo and would run as a Python process speaking OSC, not relevant to a no-extra-dependency setup.

## Implication for the bridge we sketched in `backend-design.md`

The queue-file design I drafted assumed nothing about MCP. ReMCP changes the calculus on the **outbound** path (Renoise → Claude / world → Renoise) substantially:

### Path 1 — what we already proved (file-drop only)
Renoise (Lua) → write `<id>.json` to inbox → launchd watcher → `claude --print` → write `/tmp/paketti-claude-flag.txt` + `touch main.lua` → `_AUTO_RELOAD_DEBUG` reload → modal dialog.

- Works without ReMCP running.
- Async. Renoise UI stays responsive.
- Claude has no live read of song state — only the snapshot Paketti chose to put in `context`.

### Path 2 — ReMCP-augmented (if user starts the server)
Same outbound path, but inside the daemon's `claude --print` invocation we can now:

- Configure Claude Code with the ReMCP server (`claude mcp add --transport http renoise http://localhost:19714/mcp`) so Claude can call `song_get_info`, `transport_get_position`, `tracks_list`, `patterns_get_notes`, etc. **live** during the request.
- This means the `context` block in the request becomes optional / minimal — Claude can pull whatever it needs via MCP tool calls. Paketti just needs to send the prompt; Claude introspects the song.
- And critically: Claude can **act on the song** the same way (set BPM, add notes, add devices) without going through file-drop and without waiting for a reload.

### Path 3 — the symmetric case (Claude → Paketti directly)
Once Claude can read song state via ReMCP, the only things it needs the file-drop for are:

1. **Editing Paketti source files** (Claude already does this via Edit/Write — no MCP needed; the iCloud symlink + `_AUTO_RELOAD_DEBUG` does the rest).
2. **Showing a dialog back to the user** (the smoke-branch pattern).

ReMCP exposes no `app_show_message` or `eval_lua` tool today — by design (security: no remote-Lua-eval surface). So the dialog-back path either stays as flag-file + reload, OR we **add a custom ReMCP tool**: drop `tools/paketti_dialog.lua` exposing `paketti_show_message(text)` that calls `renoise.app():show_message(text)`. The skill explicitly documents how (`~/.claude/skills/remcp/SKILL.md` "Adding a custom tool — the extension model").

## Index conventions (don't get bitten)

ReMCP and the Renoise UI disagree on indexing:

| Object | UI | ReMCP API |
|---|---|---|
| Patterns | 0 | **0** |
| Instruments | 0 | **0** |
| Tracks | 1 | **1** |
| Lines, note cols, fx cols | 1 | **1** |
| DSP devices | 1 (idx 1 = Mixer, non-removable) | **1** |

Anything Paketti sends or Claude requests via ReMCP must match this. Paketti's existing Lua already speaks Renoise-native indexing (so the `context` block from `backend-design.md` was already correct).

## Concurrency / undo gotcha

ReMCP wraps each call in one undo step. Tight inner loops over HTTP create N undo steps; if Claude generates a 64-line drum pattern via 64 `pattern_set_note` calls, that's 64 undos. The remcp skill explicitly recommends shipping a single Lua block via a custom tool for atomic ops. If we end up letting Claude write whole patterns through MCP, we should add a `pattern_set_lines_bulk` tool (or `pattern_apply_lua` if we accept the eval surface for trusted local use).

## Daemon redesign — what changes

The daemon I specced in `backend-design.md` doesn't change much. The single concrete addition:

- When invoking `claude --print`, **also pass `--mcp-config`** with a JSON config that registers `http://localhost:19714/mcp` as the `renoise` MCP server, conditional on `curl -s --max-time 1 http://localhost:19714/health` returning `200 ok`.
- Skip MCP registration when the server is down — Claude then operates blind on song state but can still edit `~/work/paketti` files.

Pseudocode addition to `invoke_claude()`:

```python
mcp_config = None
try:
    h = subprocess.run(["curl","-s","--max-time","1","http://localhost:19714/health"],
                       capture_output=True, text=True, timeout=2)
    if "ok" in h.stdout:
        mcp_config = write_temp_mcp_config({
            "mcpServers": {
                "renoise": {
                    "type": "http",
                    "url": "http://localhost:19714/mcp"
                }
            }
        })
except Exception:
    pass
args = ["claude", "--print", "--output-format", "json",
        "--add-dir", str(PAKETTI_DIR),
        "--permission-mode", "acceptEdits"]
if mcp_config:
    args += ["--mcp-config", mcp_config]
if req.get("resume_session") and SESSION_FILE.exists():
    args += ["--resume", SESSION_FILE.read_text().strip()]
```

## One bridge, three modes

| Mode | What it means | ReMCP needed? | Edits Paketti? |
|---|---|---|---|
| `ask` | Q&A. Claude reads source + (optionally) live song. No edits. | optional (richer answers if up) | no |
| `edit` | Claude modifies `~/work/paketti`. Reload + smoke-branch dialog summarises. | optional | yes |
| `act` | Claude drives the song directly via ReMCP — no Paketti edit, no reload. Dialog optional. | **required** | no |

`act` is the new mode that ReMCP unlocks. The smoke-branch v1 dialog still works as the "what happened" report at the end.

## What to build first, in priority order

1. **The daemon + plist + protocol from `backend-design.md`** — works without ReMCP, gives `ask`/`edit` immediately. Independent of whether the user ever starts ReMCP.
2. **Health-check + conditional `--mcp-config`** — one ~20-line addition to the daemon. Lets Claude introspect the live song when ReMCP happens to be running.
3. **One custom ReMCP tool: `paketti_show_message`** — added to ReMCP's `tools/` dir, exposes `renoise.app():show_message(text)`. Lets Claude pop the result-dialog directly via MCP instead of waiting for a `_AUTO_RELOAD_DEBUG` cycle. Faster round trip in `act` mode.
4. **A custom `paketti_eval_lua` tool** — guarded behind a localhost-only flag. Paketti has eight years of one-shot Lua patterns; Claude already writes Lua well; closing this gap collapses 80 % of "act on the song" into a single MCP call with proper undo. Worth doing carefully because it is the RCE-into-Renoise surface the upstream remcp author deliberately omitted. For local single-user use, it's the right trade.

## Surprising cross-skill leverage

- The `renoise-api` skill is the LuaCATS reference; combined with `paketti-patterns.md` (eight years of distilled Paketti idioms), Claude can already write idiomatic Renoise Lua with no further docs.
- The `paketti` skill catalogs `unused-apis.md` — Renoise APIs Paketti hasn't touched yet. Useful as a hint to Claude when the user asks "what could you build for me here?"
- `renoise-mcp` (Python OSC) and `remcp` (Lua HTTP) are sister skills; remcp's tool surface is a near-superset for non-Lua-eval use cases. If the OSC version's pattern-gen primitives (breakbeat, basslines) are wanted, port them as ReMCP custom tools — keeps everything single-process inside Renoise.

## What I'm NOT doing without confirmation

- Adding `paketti_eval_lua` to ReMCP. That's an RCE surface; user should green-light explicitly.
- Modifying ReMCP source under `~/work/tools/Tools/com.renoise.ReMCP.xrnx`. Different repo, kraken's code.
- Auto-starting ReMCP via Cloudcity-Boot.app. The user starts it from Renoise when they want it.
