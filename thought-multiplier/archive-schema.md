# Archive Schema — Thought Multiplier

## Seed Record (JSONL)

Each line in the archive is a JSON object:

```json
{
  "ts": "2026-03-20T09:15:32.123Z",
  "seed": "The original thought, exactly as typed. Never modified.",
  "branches": {
    "archive": true,
    "llm": true,
    "browser": false,
    "email": false,
    "graph": true
  },
  "context_tabs": [
    { "url": "https://example.com/article", "title": "Some article open at the time" }
  ]
}
```

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `ts` | ISO 8601 string | yes | Timestamp of seed capture |
| `seed` | string | yes | Raw text, never modified (RBI P5: dead center of rest) |
| `branches` | object | yes | Which destinations were enabled at send time |
| `context_tabs` | array | no | Open tabs at capture time (Chat with Tabs integration) |

## Rebound Record

Stored separately, keyed by seed timestamp:

```json
{
  "ts": "2026-03-20T09:15:32.123Z",
  "archive": true,
  "llm": {
    "model": "phi-4-mini",
    "prompt_template": "expand",
    "refined": "The LLM's refined version of the seed...",
    "processing_ms": 1250
  },
  "browser": {
    "url": "https://blog.example.com/new-post",
    "status": "published"
  },
  "email": {
    "to": "collaborator@example.com",
    "subject": "Re: idea",
    "status": "composed"
  },
  "graph": {
    "clusters": 4,
    "connections": 12,
    "nearest_seed": "2026-03-19T14:22:01.000Z"
  },
  "next_seed": "You've been circling around X — what if you tried Y?"
}
```

## Storage Locations

| Storage | Key Pattern | Purpose |
|---------|-------------|---------|
| localStorage | `ray-seed-{ISO ts}` | Individual seed records |
| localStorage | `ray-rebound-{ISO ts}` | Rebound data per seed |
| localStorage | `ray-archive-{ISO ts}` | Duplicate for archive branch |
| localStorage | `thought-multiplier-branches` | Toggle state (settings) |
| JSONL file | `~/thought-archive.jsonl` | Persistent local file (via Agent Scripter) |

## File Archive (thought-archive.jsonl)

Append-only JSONL. One seed per line. Read with:

```bash
# Count seeds
wc -l ~/thought-archive.jsonl

# Search seeds
grep -i "keyword" ~/thought-archive.jsonl | python3 -c "import sys,json; [print(json.loads(l)['seed'][:80]) for l in sys.stdin]"

# Seeds per day
cat ~/thought-archive.jsonl | python3 -c "
import sys,json,collections
days = collections.Counter(json.loads(l)['ts'][:10] for l in sys.stdin)
for d,c in sorted(days.items()): print(f'{d}: {c} seeds')
"
```
