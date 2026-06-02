# ENVOY / Foundry Compatible Software — General Principles

**Status:** Adopted 2026-05-27 from ENVOY architectural guidance.
**Scope:** Applies to *any* tool built in the chassis pattern, not just chat or live-conversation apps.

This guide is about **making software easy to connect to ENVOY/Foundry later**. You don't need to implement ENVOY or Foundry now. Following these principles keeps the door open.

## The short version

```
Keep an event log. Keep intent separate from action.
Keep authority separate from chat.
Keep artifacts portable.
Keep receipts for important changes.
Do not turn raw memory into canon automatically.
```

## 1. Preserve Events, Not Just Final State

Whenever something important happens, record a structured event. Don't only store the final file, message, or database row — keep a log of how it got there.

Good:
```
user requested X
system proposed Y
agent executed Z
verification passed
human approved
```

Bad: `final_result.txt`

## 2. Separate Communication From Authority

A message, chat reply, voice command, or agent suggestion is not automatically permission to act. Treat communication as **evidence**. Treat authority as a separate approval or grant.

```
message ≠ permission
suggestion ≠ approval
tool success ≠ completion
```

## 3. Use Append-Only Logs For Important Actions

Prefer append-only logs for meaningful state changes:

```
events.jsonl
provenance.jsonl
receipts.jsonl
audit.jsonl
```

Human-readable files are generated from those logs:

```
events → summary.md
events → dashboard
events → transcript
events → receipt
```

## 4. Make State Portable

A project, session, or task should be understandable as a directory.

```
my-session/
  manifest.json
  events.jsonl
  artifacts/
  receipts/
  exports/
  README.md
```

If copied to another machine, the folder should still explain what it is.

## 5. Attach Provenance To Artifacts

Every important artifact answers:

- Who created this?
- When?
- From what input?
- Using what tool/model?
- Under what permission?
- With what evidence?

Simple metadata at first; structured later.

## 6. Keep Human Intent Explicit

Store the user's intent separately from the machine's action.

```
intent:  "summarize this meeting"
action:  "called local whisper transcription"
result:  "summary.md created"
```

Future ENVOY/Foundry systems need to know what was asked, not only what happened.

## 7. Scope Dangerous Actions

If software can edit files, run commands, call APIs, spend money, publish content, or share data, require a scope:

```json
{
  "allowed_paths":    ["notes/"],
  "forbidden_paths":  [".env", "secrets/"],
  "allowed_actions":  ["read", "summarize"],
  "requires_approval": ["write", "publish", "delete"]
}
```

## 8. Treat Agents As Bounded Helpers

Agents propose, draft, summarize, classify, and execute scoped tasks. They never silently become the source of truth.

```
agent output → proposal
proposal → review
review → approval
approval → action
action → verification
verification → receipt
```

## 9. Verification Is Separate From Execution

A tool saying "done" is not enough. Record what was checked:

```
tests passed
hash verified
file exists
schema valid
human reviewed
deployment healthy
```

## 10. Receipts Beat Claims

Prefer evidence over statements.

Weak: `"the agent fixed it"`

Better:
```
claim id
changed files
test command
test output
review result
timestamp
actor
```

## 11. Memory Is Promoted, Not Dumped

Don't treat raw chat logs, transcripts, or agent summaries as permanent truth. Use stages:

```
raw notes
candidate summary
reviewed note
promoted knowledge
```

## 12. Avoid Hidden Magic

Make system decisions inspectable. If the app chose a model, skipped a file, denied an action, changed a setting, or used cached data — record that.

## 13. Minimal Event Shape

```json
{
  "id":         "evt_001",
  "type":       "artifact.created",
  "created_at": "2026-05-27T12:00:00Z",
  "actor":      "local-user",
  "tool":       "my-app",
  "intent_id":  "intent_001",
  "input_refs":  ["file_001"],
  "output_refs": ["artifact_001"],
  "body":       "Created summary from meeting transcript."
}
```

## 14. The General Compatibility Rule

If future ENVOY needs to ask:

- Who asked?
- What was allowed?
- What happened?
- What changed?
- What evidence exists?
- What is safe next?

The software should have enough structured records to answer.

## How this applies to the Apple chassis pattern

The recurring chassis in this skill is `trigger → worker → result`. The ENVOY-compatible version is:

```
trigger emits an intent event
   → worker emits action events
   → worker emits verification event
   → worker emits artifact event
   → result is the artifact PLUS the receipt trail
```

Concrete: a Finder-tag trigger that submits OCR work to the Mac Mini via Syncthing should log `intent: "ocr request"`, `action: "submitted to ocr-inbox"`, `verification: "ocr-results returned"`, `artifact: "<file>.pdf"`, with the chain visible.

Today most of the chassis pipelines just write logs; they don't yet emit typed events. Migrating them is a v2 concern. The point of this doc is that the *shape* of any new chassis should be event-first, not "log and forget".

## Companion docs

- Live-conversation-specific blueprint: `~/work/converse/DOCTRINE.md`
- Conversation entity / file structure: `~/work/apple/wiki/entities/conversation.md`
- Chassis pattern (where this doctrine lands operationally): grep wiki for "chassis" — the Finder-tag pipeline, the mail-flag pipeline, and the LaunchAgent pipelines all share the trigger→worker shape.
