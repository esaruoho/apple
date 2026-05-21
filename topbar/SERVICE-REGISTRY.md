# AppleToolbox Service Registry

> AppleToolbox is a tiny client. Every capability is a localhost service with a verb. MCP is just the network-shaped version of the same verb table. Same registry feeds Loupedeck, Hey Sal, Claude, BBS-app, and the MCP bridge.

## Discovery sources

- ray-graph endpoint catalog: 304 documented `/api/*` paths in `server.py` (registry block); 482 mounted total
- bbs-app omnibar verbs: `src/main.ts` parses `editor:<id>`, `editor:<id>@<sec>`, `vault:`, `agent:`, `bbs:*`, `https://`, `~/…`, `/…`
- bbs-app already calls ray-graph for: `/api/list_videos`, `editor.html`, `dashboard.html`, `inbox.html`, `chat.html`, `tutor.html`, `suggester.html`, `health.html`, `parenting.html`, `COS_v1.00.html`, `cc-boot.json`

All ray-graph services live at `http://localhost:8000`.

## The verbs AppleToolbox needs (selection → service routing)

| Selection type | Verb | Service URL / endpoint | Notes |
|---|---|---|---|
| Local file (any) | **open in default app** | `open <path>` | Apple `open(1)` |
| Image | **show** | `open -a Preview <path>` | already wired in `bin/pair-and-tile` |
| Video file (local) | **scrub + clip** | `GET /api/list_videos` → resolve to `videoId` → `http://localhost:8000/editor.html?video=<id>` | the Media Editor — transcript-highlight-to-clip |
| Video (YouTube ID) | **scrub + clip** | `http://localhost:8000/editor.html?video=<id>&t=<sec>` | timestamp deep-link |
| Video → save clip | **clip-from-highlight** | `POST /api/editor/save_clip` | persisted as subnode of video node |
| Video → list clips | **list clips** | `GET /api/editor/clips?video=<id>` | |
| Video → state | **resume editor** | `GET /api/editor/state?video=<id>` | includes transcript |
| Anything | **reveal in Finder** | `open -R <path>` | already wired |
| Folder | **open Finder** | `open <path>` | |
| URL | **open in Safari** | `open <url>` | |

## ray-graph verbs grouped for AppleToolbox dispatch

### Media Editor (clip + transcript)
- `GET  /api/list_videos` — enumerate videos in media folder (resolver: path → videoId)
- `GET  /api/editor/state?video=<id>` — editor state including transcript
- `GET  /api/editor/video_node?video=<id>` — node ID for the video
- `GET  /api/editor/clips?video=<id>` — list saved clips
- `GET  /api/editor/picked_segments?video=<id>` — current picks
- `POST /api/editor/picked_segments` — save picks
- `POST /api/editor/save_clip` — extract clip as subnode
- `POST /api/editor/save_segment` — segment metadata
- `POST /api/editor/delete_clip` — remove clip

### Transcripts & Voicebox (word-level index, 490 K lines)
- `GET  /api/voicebox/check_words?video=<id>` — does word-level transcript exist
- `GET  /api/voicebox/lookup?word=<w>` — word occurrences across all sources
- `GET  /api/voicebox/index` — full index
- `GET  /api/voicebox/speakers` — distinct speakers
- `GET  /api/voicebox/stats` — index statistics
- `GET  /api/voicebox/transcription_status` — background queue
- `POST /api/voicebox/add_source` — add video to index
- `POST /api/voicebox/build_index` — rebuild
- `POST /api/voicebox/transcribe_words` — word-level transcript
- `POST /api/voicebox/transcribe_stream` — SSE streaming transcript
- `POST /api/voicebox/synthesize` — generate sentence playback from word picks
- `POST /api/voicebox/export` — render synthesized sentence to video
- `POST /api/voicebox/set_speaker` — assign speaker to source
- `POST /api/voicebox/tag-speaker` — speaker on transcript words

### Graph navigation (merlib-dump → bearden → bearden-talks-tesla resolver)
- `GET  /api/tree/*` — 9 traversal endpoints
- `GET  /api/nodes/*` — 5 CRUD endpoints
- `GET  /api/search/unified?q=<q>` — full search
- `GET  /api/search/semantic?q=<q>` — embedding search
- `GET  /api/mirror/lookup?q=<q>` — O(1) keyword scratch index (9,901 keywords)
- `POST /api/track_access` — log node access

### Ingestion (drop file into graph)
- `POST /api/upload_image`
- `POST /api/save_import_data`
- `POST /api/agent/notify_file_received`
- `POST /api/agent/analyze_file`
- `POST /api/enrich_url`

### bbs-app omnibar verbs (string → tab)
- `editor` / `bbs:editor` / `clip` / `media-editor` — open Media Editor
- `editor:<videoId>` / `editor:<videoId>@<seconds>` — deep-link
- `dashboard` / `graph` / `chat` / `boards` / `props` / `ocr` / `todo` / `tutor` / `suggester` / `compose`
- `vault:<path>` — open vault node
- `agent:<name>` — open agent
- `https://…` — open as web tab
- `~/…` or `/…` — open as file tab

## The unifying call shape

Every verb above reduces to one of three shapes:

```
GET  http://localhost:8000/<endpoint>?<args>          # read
POST http://localhost:8000/<endpoint>  body=<json>    # write
open <url-or-path>                                    # Apple native dispatch
```

So a single dispatcher function `do_verb(verb, payload) -> result` covers everything. That dispatcher is what gets exposed as MCP tools, Loupedeck button actions, Hey Sal intents, AppleToolbox menu items, and Claude tool calls. **Same registry. Same call shape. Five client surfaces.**

## Concrete dispatch examples

```bash
# Open the Media Editor on a YouTube video at 1:23
open "http://localhost:8000/editor.html?video=GeOQEEV3oYI&t=83"

# Resolve a local .mp4 path to a ray-graph videoId, then open the editor
curl -s 'http://localhost:8000/api/list_videos' \
  | jq -r '.videos[] | select(.path == "/Users/esaruoho/work/merlib-dump/lenr-canr/excess-heat-lenr-evidence.mp4") | .id'

# Tile two ray-graph surfaces side-by-side via the AX positioner
pair-and-tile \
  "http://localhost:8000/editor.html?video=GeOQEEV3oYI" \
  "http://localhost:8000/dashboard.html"

# Look up "vortex" across the entire word-level index
curl -s 'http://localhost:8000/api/voicebox/lookup?word=vortex' | jq

# Search the merlib-dump scratch index
curl -s 'http://localhost:8000/api/mirror/lookup?q=schauberger'
```

## What's missing for a fully-wired AppleToolbox

1. **Path → videoId resolver** — `/api/list_videos` returns the catalog but AppleToolbox needs a helper that takes a local path and gets back the id. Either client-side filter on the catalog, or a new `GET /api/video_by_path?path=…` endpoint in ray-graph.
2. **`pair-and-tile` URL support** — currently dispatches localhost URLs to Safari; should also route `localhost:8000/editor.html` directly to a BBS-app pane if BBS-app is running.
3. **MCP server wrapping the verb table** — one tool per verb, schema derived from this file.
4. **AppleToolbox menu item: "Send selection to Media Editor"** — calls the resolver, then opens the editor URL.
