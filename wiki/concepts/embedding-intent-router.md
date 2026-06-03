---
description: apple-intent routes natural language to an apple-do action via on-device NLEmbedding (no FoundationModels, no Tahoe — runs on the laptop). AppleBar is its ⌥Space command-bar front door. The non-Tahoe twin of fm's tool-routing.
---

# Embedding intent router — natural language → an Apple-skill action, no LLM

`fm` (the FoundationModels chat) lets the on-device 3B model *pick* which tool to
run. But FoundationModels is macOS-26-only, so it lives on the Mini. The
**embedding intent router** is the non-Tahoe twin: it decides which action you
mean using an **embedding match**, not a language model — so the deciding runs on
any Mac (the laptop included), with no LLM in the loop.

> Embed what you type → cosine-match it to the `apple-do` capability registry →
> run the closest action.

## The two pieces

| Piece | What | Where it runs |
|---|---|---|
| `bin/apple-intent` | The engine. `NLEmbedding` (512-dim sentence vectors, macOS 10.15+) embeds the query and each action's example phrasings; the best cosine match wins; it execs `apple-do <action>`. | Any Mac |
| `apple-bar/AppleBar.app` | The front door. A menu-bar agent that drops a **Spotlight-style command bar** on **⌥Space**: type a request, it runs `apple-intent` and shows the result inline. | Any Mac (the laptop) |

The action set is exactly the one `apple-do` (and `fm`) already expose:
`home / now / fleet / spotlight / search / ocr`. One registry, three front doors —
type the verb yourself (`apple-do`), say it in words to the 3B model (`fm`), or say
it in words to the embedding (`apple-intent` / AppleBar).

## Why embeddings, not keywords

Meaning, not string overlap. Verified (none of these share a keyword with the
action's name, all route correctly):

```
"is it chilly in the house"        → home   (0.60)
"what's the mini up to"            → fleet  (0.81)
"pull the words out of this pdf"   → ocr    (0.87)
"dig up my notes on global hotkeys"→ search (0.62)
"should i bring a jacket"          → (0.40, below threshold → asks, doesn't guess)
```

A query below the confidence threshold (default 0.45) prints the top candidates
and bails rather than running the wrong thing.

## Using it

```bash
apple-intent "how warm is it at home"      # runs: apple-do home
apple-intent --dry-run "is the mini busy"  # prints the match, runs nothing
apple-intent --top 3 "..."                 # ranked matches + scores
apple-intent --json "..."                  # machine-readable
```

AppleBar: `./apple-bar/build.sh` → menu-bar `◧` icon + **⌥Space** opens the bar.
(⌥Space is the conventional launcher hotkey — Alfred's default — so it costs you
the rarely-typed non-breaking-space. Change the keycode in `registerHotKey()` if
you'd rather keep ⌥Space free.)

## Whitelabel: how the reports read

Raw tool output is robotic ("HomePod climate (calibrated): 24.45°C, 49.5% relative
humidity. Reading taken 2026-06-03T07:45:11Z (1 min ago)."). apple-intent turns it
into a human line, two ways — you pick per query:

- **↩ — template (instant, default).** A whitelabel config at
  `~/.config/apple-intent/reports.json` holds a per-action phrasing string you
  own; apple-intent extracts the fields (mechanism, in code) and fills your
  wording. Edit the file to rebrand any report — no rebuild.
  ```
  "home": "It's {tempC}°C at home, {humid}% humidity ({age})."
       → It's 24.45°C at home, 49.5% humidity (1 min ago).
  ```
  When a template needs a field that wasn't found, it falls back to the raw line
  rather than printing a half-filled template. `--raw` skips templating entirely;
  `{raw}` is always available as a passthrough field.

- **⌘↩ — LLM rephrase (on demand).** `apple-intent --speak` (the bar's ⌘↩) reruns
  the line through the on-device 3B model on the Mini (`fm-submit`) with a "say
  this like a human, keep every number, add nothing" prompt:
  ```
  → It's currently 24.45°C at home with 49.5% humidity.
  ```
  Costs the ~8s Syncthing round-trip and needs the Mini; if it's unreachable or
  the model declines, apple-intent keeps the template line (graceful fallback).
  Mechanism in code, **wording in the config you own** — the same public-mechanism
  / private-whitelabel split as the [companion-mac fabric](companion-mac-fabric.md)
  and Fleet's machine-card config.

## Making it smarter

When a real query routes to the wrong action, **add a phrasing** to that intent's
`examples` in `bin/apple-intent` (and a matching capability in `apple-do` if it's a
new action). That's the whole maintenance model — no retraining, no model file.
The catalog is small, so `NLEmbedding` is plenty here (unlike whole-vault search,
where `bin/vault-rag`'s CoreML MiniLM is needed — see [on-device-ml.md](on-device-ml.md)).

## Arg handling (honest limit)

The embedding picks the *action* reliably. It does not *extract arguments* — for
`search`/`spotlight`/`ocr` the whole query is passed through to `apple-do`, which
its own tool interprets. A 3B model (`fm`) fills arguments by reasoning; the
embedding router doesn't. Fine for "search my notes about X"; weaker for "ocr the
third file in Downloads". Improve per-action with light prefix-stripping if needed.

## See also
- `bin/apple-do` — the capability registry + dispatch this routes over
- `bin/apple-semantic-match`, `bin/apple-embed` — the same `NLEmbedding` engine
- [on-device-ml.md](on-device-ml.md) — the on-device ML family (NLEmbedding, MiniLM, FM)
- [global-keyboard-shortcuts.md](global-keyboard-shortcuts.md) — the Carbon hotkey channel AppleBar uses
