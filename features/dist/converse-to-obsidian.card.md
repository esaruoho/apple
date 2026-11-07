# Report Card — converse-to-obsidian — linked Markdown views of Converse sessions

> Source: `features/converse-to-obsidian.feature` · printable rendering · regenerate with `python3 print-card.py`

**Intent:** As someone discussing a repo with Converse and FM/MLX, I want the discussion rendered as linked Markdown notes, So that a repo such as scaff can benefit from the conversation in an Obsidian-style graph.

**Grades:** @build-verified × 1 · @built × 7 · @code-verified × 1 · @runtime-verified × 5

**Scenarios: 7**


---


## 1. A named Converse session exports to linked Markdown

`@built @runtime-verified`


- Given a Converse session name with talk.heard and agent.responded events
- When converse-to-obsidian exports it to an output directory
- Then it writes one session note and one note per turn
- And the session note links to each turn note with Obsidian wikilinks

<sub>cite: bin/converse-to-obsidian resolve_session, turns_from_events, render_session_note, render_turn_note</sub>


## 2. Existing fm-converse memory is usable before livefile turn logging lands

`@built @runtime-verified`


- Given livefile.jsonl contains no model turn pairs
- When ~/.cache/fm-converse/<session>.json contains paired user and assistant turns
- Then the exporter renders those cached pairs as Obsidian turn notes
- And a repo export links the notes to the repo context

<sub>cite: bin/converse-to-obsidian turns_from_cache</sub>


## 3. Future livefile agent events take precedence over cache state

`@built @code-verified`


- Given livefile.jsonl contains request and response events with matching request_id
- When the exporter reads the session
- Then it uses the livefile event pairs instead of the fm-converse cache fallback

<sub>cite: bin/converse-to-obsidian turns_from_events and main</sub>


## 4. The shared publisher updates Scaff and the Obsidian vault from one livefile

`@built @runtime-verified`


- Given a Converse session directory with livefile.jsonl
- When converse-publish runs for that session
- Then Scaff's ConverseInbox is refreshed through semantic-convey-file converse-push
- And the Obsidian-shaped vault receives linked session and turn notes
- And both views are derived from the same livefile source of truth

<sub>cite: bin/converse-publish publish_scaff, publish_vault · bin/converse-to-obsidian render_session_note, render_turn_note</sub>


## 5. Converse.app automatically calls the shared publisher after replies

`@built @build-verified`


- Given Converse.app logs an agent response into livefile.jsonl
- When the reply path finishes
- Then Converse.app invokes bin/converse-publish for the current session
- And it no longer owns a Scaff-specific export path

<sub>cite: /Users/esaruoho/work/converse/main.swift publishCurrentSession</sub>


## 6. fm-converse automatically calls the shared publisher after captured turns

`@built @runtime-verified`


- Given fm-converse captures a successful turn into livefile.jsonl
- When the turn is saved
- Then it calls converse-publish so Scaff and the Obsidian vault both benefit

<sub>cite: bin/fm-converse _publish_capture_session</sub>


## 7. Booting Converse.app automatically populates the vault after a model turn

`@built @runtime-verified`


- Given Converse.app starts or appends a model turn
- When converse-publish is available
- Then the corresponding Obsidian notes are refreshed without a manual export command
- And the source of truth remains livefile.jsonl rather than Markdown

