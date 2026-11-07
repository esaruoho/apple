# fm-converse Capture Session

## How to get back

- Date: 2026-09-22 22:17 EEST
- Transcript: current Codex session in `/Users/esaruoho/work/apple`
- Resume: use the active Codex conversation that produced `bin/fm-converse` capture
- Card: `features/fm-converse.feature`

## User Intent

Esa wanted all `fm-converse` chats to be capturable, not just the GUI path in
Converse.app. The important correction was that the value is not a manual export:
the chat itself should become a semantic object that Scaff can ingest and later
benefit from.

## Design

`fm-converse` already stored replay memory in `~/.cache/fm-converse/<key>.json`.
That stays as the model-memory buffer. The new behavior writes successful turns
into `~/work/converse/sessions/<key>/livefile.jsonl` using the same broad event
shape Converse.app already emits.

For terminal or named `fm-converse` sessions, the tool creates a session directory,
a `manifest.json`, and appends:

- `session.created`
- `talk.heard`
- `agent.responded`

For Converse.app-owned sessions, the app writes `talk.heard` before calling
`fm-converse`. The helper checks the recent livefile for that turn and skips its
own append, so the app remains the owner and duplicate replies are avoided.

After a new livefile turn is appended, `fm-converse` silently runs Scaff's
`semantic-convey-file converse-push` into `~/work/scaff/ConverseInbox`.

## Verification

- `python3 -m py_compile bin/fm-converse`
- `python3 test_fm_converse.py`

The tests cover successful livefile turn creation and duplicate avoidance when
Converse.app has already logged the user turn.

## 2026-09-24 — flubuild remote brain

Esa wanted the remote workstation exposed inside Converse.app as a selectable chat
brain, but with no mention of the machine name in the Apple repo. The Apple-side
name is therefore `flubuild`.

Implementation:
- `fm-converse --flubuild` posts the session's `messages[]` history to the remote
  OpenAI-compatible chat endpoint over SSH.
- The turn writes the exact same Converse livefile pair as other backends:
  `talk.heard` and `agent.responded`.
- The livefile labels the backend as `agent_type: flubuild`.
- The default flubuild generation cap is 2048 tokens via `FM_FLUBUILD_MAX_TOKENS`.

Verification:
- `python3 /Users/esaruoho/work/apple/test_fm_converse.py` passed.
- `PYTHONPYCACHEPREFIX=/private/tmp/converse-pycache python3 -m py_compile ...`
  passed.
- Live smoke:
  `/Users/esaruoho/work/apple/bin/fm-converse --flubuild --session flubuild-smoke-20260924 --timeout 45 "Reply with exactly: flubuild-ok"`
  returned `flubuild-ok`.

## FinderSearch Flubuild HTTP 400 correction

User screenshot showed urllib HTTP 400 with the response body hidden. Synthetic live probes confirmed the served model has max_model_len 8192 and oversized requests fail for prompt plus reply length. Installed tokenizer-aware Flubuild helper and response-body error handling. Six focused tests passed; oversized synthetic request succeeded with prompt_tokens 6144, completion_tokens 2048 and visible context-shortening notice. Full source report, spawning conversation and bundled transcript: /Users/esaruoho/work/FinderSearch/features/flubuild-context.feature and flubuild-context.session.md. Session ID 01a130d7-7216-74a3-879e-6dc343c5f8cb. No original user document content was sent during diagnostic probes.
