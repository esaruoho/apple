---
description: Folder-as-memory — every folder carries a sidecar triad (.memory.md + .savedSearch + mem: tag) so a directory speaks its own key points and architecture into Obsidian, Finder, and convey/DreamGraph.
---

# Folder Memory — the per-folder sidecar triad

> *A folder is already a memory. It just can't speak. The sidecar gives it a voice — one that Finder, Obsidian, and convey all hear.*

## The problem

A Smart Folder (`.savedSearch`, see [`finder-tag-pipeline.md`](finder-tag-pipeline.md) and `bin/smart`) is a **live Spotlight query rendered as a Finder window**. It's powerful but flat: it returns a *set of files*, never *what they mean* or *how they relate*. It can't express architecture — only membership.

Obsidian is the opposite: it's all about typed links and a graph, but it only sees Markdown inside its vault, and it has no idea a `.savedSearch` exists.

convey's DreamGraph is the memory layer, but nothing currently feeds it a per-folder "what is this directory and what are its load-bearing files."

So three systems each hold one third of "understanding a folder," and none of them talk. **Folder Memory is the bridge.**

## The triad (whitelabel of the report-card pattern)

This is the global report-card doctrine (`~/.claude/skills/report-card/`) applied to a *filesystem folder* as the unit. Building/understanding a folder emits its card. For folder `F`:

| Leg | Artifact | Who reads it |
|---|---|---|
| **Memory** (the *what/why*) | `F/.memory.md` | Obsidian (graph node + backlinks), convey/DreamGraph, any LLM, you |
| **Live view** (the *now*) | `F/.memory.savedSearch` | Finder — re-evaluated live by Spotlight every open |
| **Edges** (the *graph*) | xattr tag `mem:<slug>` on the key files | Spotlight → both the Smart Folder and any other Smart Folder that unions tags |

Cross-linked both ways: the `.md` carries a clickable `file://…/.memory.savedSearch` line (open the live view); the `.savedSearch` query is *derived from* the `.md` (the key files it names, or the `mem:<slug>` tag it stamps). Edit one, regenerate the other.

## Why this answers "can every folder have a Smart Folder that speaks to it?"

Yes — because the Smart Folder is no longer alone. On its own it's a dumb query. Paired with `.memory.md` it becomes the **entry point** to a memory: open the live view to browse files, open the note to read what they are and how they fit. The note is the understanding; the Smart Folder is the always-fresh index of it.

Recursively: a walker can sidecar every folder (with ignore rules — never node_modules, .git, build dirs). A repo then carries a **self-maintaining codemap**: one memory note per package, each with a live Smart Folder beside it.

## How the "understanding" gets generated (all Apple-native, zero-token, zero-cloud)

The Smart Folder is free (a plist). The *memory* is the hard part, and the on-device intelligence layer does it without a single API token (see skill body: NLEmbedding + FoundationModels):

1. **Enumerate** — `find F` (respecting ignore rules), classify by type.
2. **Cluster by meaning** — `bin/apple-embed` → 512-dim Neural-Engine vectors per file (filename + head of content) → `bin/apple-cluster-docs` (cosine + leader clustering). Each cluster ≈ a subsystem. *This is the "key points / architecture" grouping, done with arithmetic, no LLM.*
3. **Find the hubs (code-specific)** — cheap structural grep: count inbound references (imports/requires/`#include`/wikilinks). Most-referenced files = the load-bearing nodes. Spotlight can't do call graphs, so this lives outside it.
4. **Name it** — `bin/fm-submit` (FoundationModels on the Mini, **majority-vote N samples** — it's non-deterministic) writes a one-line gloss per cluster + a 2-sentence folder summary. Optional; clusters + hubs alone are already useful.
5. **Emit** — write `.memory.md` (summary, hub files, clusters with one-liners, link to the live view), write `.memory.savedSearch` (scope = `F`, query = recent + key types, or `kMDItemUserTags == "mem:<slug>"`), and stamp the hub files with `mem:<slug>`.

Steps 1–3 are deterministic and instant; step 4 is the only soft/optional one. Honest division of labour: **embedding selects, FoundationModels phrases, Spotlight keeps it live.**

## Dragging it into the three worlds

- **Finder** — `.memory.savedSearch` is a native Smart Folder; appears in the sidebar / is openable; stays fresh automatically because Spotlight re-evaluates.
- **Obsidian** — `.memory.md` is a vault node the moment it's in the vault. Its `[[links]]` to hub files (or to other folders' `.memory.md`) build the graph. A Dataview/embedded-query block can mirror the Smart Folder *inside* the note; a `file://` line opens the real Finder one. (Obsidian cannot read `.savedSearch` — the `.md` is the bridge.)
- **convey / DreamGraph** — each `.memory.md` is a DreamGraph node; the `mem:<slug>` tags and inter-folder links are edges. This is the same embed-to-narrow / vote-to-judge machinery DreamGraph already runs for forum-request dedup, pointed at the filesystem instead.

## Honest boundaries (don't oversell)

- A Smart Folder's edges are only what **Spotlight can match**: tags, filename, content-type, dates, size, full-text. Rich typed relations ("A *calls* B") are **not** expressible in the `.savedSearch` — they live in the `.md` and in DreamGraph, not in Finder.
- The Smart Folder stays live; the `.memory.md` is a **snapshot** — it needs regeneration (a `pre-commit` hook or a watcher) to stay true. Stale memory that claims to be current is the completion-framing trap; stamp the note with its generation time + commit.
- Code *semantics* (imports, call graphs) are not Spotlight-queryable. The structural-grep + embedding pass supplies them; Spotlight only renders the resulting file set.
- Be selective. Sidecaring every folder including `node_modules`/`.git`/`dist` is noise. Walk with an ignore list.

## Tooling (built 2026-06-15)

`bin/folder-memory` / `/folder-memory` — Apple-native Python3 stdlib composing `apple-embed` + `fm-mlx`/`fm-submit`. Report card: [`features/folder-memory.feature`](../../features/folder-memory.feature).

```
folder-memory <dir>                 build/refresh the triad (with model summary)
folder-memory <dir> --no-model      deterministic only (instant; no model call)
folder-memory <dir> --chat          talk to the folder ("you ARE this folder's memory")
folder-memory <dir> --diff          vibe diff vs the stored .memory.json snapshot
folder-memory <dir> --recursive     sidecar every folder in the tree (ignore-aware)
folder-memory <dir> --vault <vdir>  fold the notes into an Obsidian vault (mirrors tree)
folder-memory --repo <url|path>     clone + understand a repo → aggregate UNDERSTANDING.md
folder-memory <dir> --show|--open   print the memory / open the Smart Folder in Finder
  --brain mlx|fm   --tag   --max-files N   --k-threshold X   --ext .a,.b
```

Verified on the apple repo: hub ranking surfaced `on-device-ml.md` / `asobjc.md` as the load-bearing wiki pages; the model summary of `github-watcher/` correctly named `repos.json` as the data hub. Sidecars are `.gitignore`d (regenerable; model output is non-deterministic) — `git add -f <dir>/.memory.md` to commit a specific one.

### Honest grade on what's NOT done

- **Self-refresh on commit** (a `pre-commit` regen per the zero-token auto-regen principle) is designed, not built — the snapshot stamps its generation time so it never lies about being current, but you must re-run to refresh.
- **Clustering of homogeneous prose** collapses to one big cluster (light embedding model) — hubs + model summary carry the architecture there; code folders separate cleanly.

## Related

- [`finder-tag-pipeline.md`](finder-tag-pipeline.md) — the tag→Smart Folder graph mechanism this builds on (`bin/tag-smart`, `bin/tag-trinity`).
- [`asobjc.md`](asobjc.md) — why `.savedSearch` is built with `plistlib`, not a Cocoa class (`NSSavedSearch` is not public).
- `bin/smart`, `bin/apple-embed`, `bin/apple-cluster-docs`, `bin/fm-submit` — the existing parts being composed.
- Report-card doctrine (`~/.claude/skills/report-card/`) — the triad shape this whitelabels onto folders.
