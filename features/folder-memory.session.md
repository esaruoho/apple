# Session — folder-memory

The spawning conversation for `bin/folder-memory` and `wiki/concepts/folder-memory.md`.
Faithful, not flattering — this is the grade's audit trail.

## How to get back

- Transcript: `file:///Users/esaruoho/.claude/projects/-Users-esaruoho-work-apple/fe44754d-fbae-4302-983d-c13b965b07ff.jsonl`
- Session ID: `fe44754d-fbae-4302-983d-c13b965b07ff`
- Resume: `claude --resume fe44754d-fbae-4302-983d-c13b965b07ff`
- Date: 2026-06-15, ~10:40–10:55 EEST

## The ask (Esa's words)

1. *"explain to me the creation of a smart folder — can markdown create a smart folder or maintain a graph smart folder of information"* → produced `wiki/concepts/folder-memory.md` (doctrine).
2. *"what can we do to drag smartfolders into the obsidian, file, convey, understanding. as a folder as a memory. can every folder have a smart folder that also speaks to that? … understanding the key points and the architecture of a file system. especially code."*
3. *"please build it and keep building until we have a folder we can talk to with a model. and a diff. and a system for being able to communicate with the vault contents, and understand a github repository. we start with the file. we make it smarter. the folder->smartfolder + markdown is something we need to do, because the files themselves already speak markdown, or are linked to files. the idea here that we are able to have a memory or related files based on their metadata, auto-formulates content that the mlx model can then help us with."*

## How it was built (the reasoning)

- Reused before re-rolling (DRY): the embedder (`apple-embed`), the model transports
  (`fm-mlx --raw`, `fm-submit`), the Smart-Folder plist shape (from `bin/smart` /
  `bin/tag-smart`), and the tag-graph idea (`bin/tag-trinity`) all already existed.
  `folder-memory` is the *composition*, not a new copy of any of them.
- Whitelabel of the report-card triad onto a filesystem folder as the unit:
  `.memory.md` (card) + `.memory.savedSearch` (live view) + `.memory.json` (snapshot/seed).
- Pipeline: enumerate (ignore-aware) → embed each file's repr → leader-cluster
  (no single-linkage chaining) → rank structural hubs by inbound references
  (FIXED-STRING / escaped-literal counting — obeys the catastrophic-backtracking ban)
  → render → emit Smart Folder scoped to the key files.
- The model is given the *structure* (clusters/hubs/types), never raw file dumps —
  embed-to-narrow, model-to-phrase, per the apple-skill division of labour.

## What was verified (honest grades)

All six scenarios run live on 2026-06-15 and were observed working:
- core triad on homepod/ (1.4s) and wiki/concepts/ (87 files, 9s)
- model summary on github-watcher/ — correctly named repos.json as the data hub
- `--chat` answered "what serves the dashboard?" → dashboard.html (5.3s, MLX)
- `--diff` + vibe narration on a scratch folder
- `--recursive --vault` mirrored notes into an Obsidian vault tree
- `--repo <local path>` wrote a navigable UNDERSTANDING.md

## Known limitations surfaced (not hidden)

- Clustering of topically-homogeneous prose (the wiki) collapses to one big cluster
  at any threshold — the light NLEmbedding model can't separate near-identical pages.
  Hub ranking + the model summary carry the architecture instead. Code folders,
  being heterogeneous, separate well. Documented as `@known-limitation` in the card.
- `.memory.md`'s model summary is NON-DETERMINISTIC → sidecars are `.gitignore`d
  (regenerable), not committed by default. The snapshot is stamped with its
  generation time so it never silently claims to be current.
- Self-refresh-on-commit (a pre-commit regen hook) is `@design @todo`, NOT built.

## RESULT

- Uncommitted at session end — left for Esa's review. Expected direct-push, no PR.
- Files: `bin/folder-memory` (new), `commands/folder-memory.md` (new),
  `wiki/concepts/folder-memory.md` (new), `.gitignore` (+sidecar patterns),
  `features/folder-memory.feature` + this `.session.md`.
