---
description: How Converse and fm-converse should publish discussions as Obsidian-readable linked notes without making Markdown the source of truth.
---

# Converse Obsidian Graph

Converse already has the right storage doctrine:

> The transcript is a view. The event log is the document.

For Obsidian, keep that doctrine. Do not make Obsidian read
`~/.cache/fm-converse/*.json` as the primary record. That cache is a model-memory
buffer. The real conversation should live in the Converse session directory as
`livefile.jsonl`, and Obsidian should receive Markdown views rendered from it.

## Current Split

- Converse sessions live in `~/work/converse/sessions/<session>/`.
- Each session has `manifest.json`, `livefile.jsonl`, and a derived transcript.
- Converse already emits `agent.requested` and `agent.responded` for generic agents.
- `fm-converse` stores FM/MLX continuity separately in `~/.cache/fm-converse/<session>.json`.
- That means the visible Converse document and the model-memory state can drift.

## Desired Shape

Every FM/MLX turn should be a pair of linked events in `livefile.jsonl`:

- `agent.requested` for the user turn sent to FoundationModels or MLX.
- `agent.responded` for the model reply.
- Both share a `request_id`.
- Both carry `agent`, `agent_type`, `brain`, `model`, `cwd`, and `session_id`.
- The response may link back to a prompt/context event if the sent payload includes
  replayed history, retrieved skill passages, or file text.

The cache can remain, but it becomes rebuildable:

```
livefile.jsonl -> fm-converse memory cache
livefile.jsonl -> transcript.md
livefile.jsonl -> Obsidian session note
livefile.jsonl -> Obsidian turn notes
livefile.jsonl -> graph edges
```

## Obsidian Export

Create an exporter, for example `bin/converse-to-obsidian`, that reads a session
directory and writes Markdown into the vault:

```
Converse/
  Sessions/
    2026-09-22 mlx apple.md
  Turns/
    req_a1b2c3d4.md
  Models/
    MLX Qwen3-4B.md
    Apple FoundationModels.md
  Contexts/
    apple repo.md
```

The session note is the readable timeline. Turn notes are the graph atoms. Obsidian
can then connect:

- session -> each request/response turn
- request -> response through `request_id`
- response -> model note
- turn -> governing repo/context note
- turn -> attached files or selected ranges
- turn -> topics extracted later by a summarizer

## Session Note Shape

The session note should be pleasant to read:

```markdown
---
type: converse-session
session_id: mlx-apple-obsidian-graph
source: ~/work/converse/sessions/mlx-apple-obsidian-graph/livefile.jsonl
doctrine: envoy-livefile-v1
---

# Converse: Apple Obsidian Graph

Model turns:

- [[req_a1b2c3d4]] - MLX Qwen3-4B - Apple repo
- [[req_e5f6g7h8]] - FoundationModels - Apple repo

## Timeline

### Esa
How should Obsidian read my FM/MLX discussions?

### MLX Qwen3-4B
Treat the event log as the document and render Obsidian views from it...
```

## Turn Note Shape

Each model turn gets one note:

```markdown
---
type: converse-turn
request_id: req_a1b2c3d4
session_id: mlx-apple-obsidian-graph
agent: MLX Qwen3-4B
agent_type: mlx
model: mlx-community/Qwen3-4B-Instruct-2507-8bit
cwd: /Users/esaruoho/work/apple
status: ok
---

# MLX turn req_a1b2c3d4

Session: [[Converse Apple Obsidian Graph]]
Model: [[MLX Qwen3-4B]]
Context: [[apple repo]]

## User

...

## Response

...
```

## Implementation Steps

1. Extend `fm-converse` so after every successful FM/MLX turn it also appends
   `agent.requested` and `agent.responded` into the current session's
   `livefile.jsonl`.
2. Keep writing `~/.cache/fm-converse/<session>.json` for now, so the current UI and
   memory behavior do not break.
3. Add a rebuild path that can reconstruct the cache from `livefile.jsonl`, proving
   the event log is the source of truth.
4. Add `bin/converse-to-obsidian <session-dir> --vault <path>` to render session and
   turn notes.
5. Add an optional watcher/export command later, but keep the first version a
   deterministic one-shot exporter.

## Rule

Obsidian should never be the storage backend. Obsidian is the reading and linking
surface. Converse remains the conversation document. The bridge is a renderer from
typed events to linked Markdown.
