# Apple on-device ML / zero-roundtrip system for merlib-dump — state

**Snapshot: 2026-06-01.** What exists, what's warm, what's fast, what's blocked.

## The stack in one line

Apple's on-device ML frameworks (NaturalLanguage, Vision, Translation, Speech, CoreML) wrapped as `bin/` CLIs that embed/search/tag the merlib-dump archive **zero-token** (no Claude in the loop) and **zero-network** (no Homebrew/pip-deps at runtime, no API). Embeddings cache once; every query after is local.

## Tools (all in `~/work/apple/bin/`)

| Tool | Framework | Job |
|------|-----------|-----|
| `apple-embed` | NLEmbedding (512-dim) | the embedder — text → meaning vector |
| `apple-embed-pro` | CoreML MiniLM (384-dim) | sharper embedder (the upgrade path) |
| `embed` + `/embed` | — | corpus warmer, live progress; shares vault-grep cache |
| `vault-grep` | NLEmbedding | semantic search across a folder |
| `vault-cluster` | NLEmbedding | strongest paraphrase pairs WITHIN a corpus |
| `vault-consilience` | NLEmbedding | same idea ACROSS sources (cross-decade) |
| `apple-keywords` | NLTagger (POS) | "useful words" frequency — drops of/the junk, lemmatizes |
| `apple-ner` | NLTagger (.nameType) | person/place/org extraction |
| `ner-graph` | apple-ner | who-co-occurs-with-whom contacts graph |
| `apple-semantic-match` | NLEmbedding | meaning-similar file pairs in a folder |
| `apple-image-similar` | Vision FeaturePrint | visual dup / near-dup images |
| `apple-translate` | Translation | on-device translate (BLOCKED — see below) |
| `vault-distill` / `vault-promote` | claude CLI | digest a hit / promote to canonical vault |

## Cache state (`~/.vault-embeds/`, via `embed --stat`)

- **3.0 GB**, **3,814 embedded source files**, **287,772 cached embedding vectors**
- One JSONL per source file, keyed by sha1 of the absolute path; shared by every vault-* tool

### Warmed corpora (100%)

- **KeelyNet** — all 15 categories, **1000/1000 files, 176,363 prose lines.** One semantic space; cross-category queries work (neutral-spike query hit ENERGY + CONTACT/Puthoff + GRAVITY).
- **diary** — 348/348 files, 14,834 lines.
- plus prior-session corpora inside the 3,814-file total (music/paketti, others).

## Performance — SOLVED (2026-06-01)

A whole-KeelyNet query was **~59s wall-clock** — and the cosine was never the bottleneck; re-reading + JSON-parsing ~600k vectors out of thousands of files on EVERY query was (~34s).

**Fixed: the persisted matrix cache.** `vault-grep` now consolidates the whole JSONL cache into one mmap'd float32 matrix (`~/.vault-embeds/_matrix.npy`, L2-normalized rows) + parallel metadata (`_matrix_rows.npz`, `_matrix_files.json`, `_matrix_texts.txt`, `_matrix_manifest.json`). A query is then one `M @ q` matmul over the mmap. **Verified 59s → ~0.8s** (635,941 rows × 512-dim; query A 0.847s, query B 0.778s, results unchanged: ZPE 0.820, Tesla/Schumann 0.800).

**The non-obvious part — a SHARED, GROWING cache.** Other tools embed new corpora into `~/.vault-embeds/` constantly. A whole-cache freshness fingerprint marks the matrix stale and forces a 3-minute rebuild on the next query (this actually happened — an orphaned `convergence` run from another session was embedding all of merlib-dump into the cache mid-session). The fix is **base-matrix + live delta-merge**: rank the base matrix (fast) AND only the new/changed JSONL files read live, exclude any base rows whose file was re-embedded, and combine. The base is rebuilt only when truly absent or on explicit `vault-grep --rebuild-matrix`. The manifest stores `baked: {jsonl_name: mtime}` so the delta is "files newer than baked." When the delta exceeds 200 files, the tool prints a "run --rebuild-matrix to refold" hint.

**Also fixed: `apple-ner` compiled.** Was `#!/usr/bin/env swift` (re-parses + JITs the whole file every invocation, ~0.48s startup) → now a self-building bash wrapper (`bin/apple-ner`) that `swiftc -O`-compiles `bin/apple-ner.swift` to a cached binary on first use / source change, same pattern as `vision-ocr`. **Verified 0.48s → 0.11s** warm startup → the 2,116-file Wootan `messages-split/` contacts graph becomes practical.

## FoundationModels — AVAILABLE on the Mini (2026-06-01)

We'd written off the on-device LLM because the *laptop* (M3 Pro, 15.6.1) lacks it. Wrong scope: the **CloudcityMacMini (M2 Pro, macOS 26.3)** has FoundationModels **live** — verified via the file-bridge: framework present + `SystemLanguageModel.default.availability == .available`. The ~3B on-device LLM (`LanguageModelSession`) is usable on the Mini, zero-token, zero-network. **Next worker to build:** an FM-on-Mini service (summaries / structured extraction / classification) alongside ocr/voicebox/whisp, dispatched via the Syncthing inbox. See [on-device-ml.md](../concepts/on-device-ml.md) availability note.

## Blocked

- **Translation** — `translationd` cache empty; no language packs installed. DE/FR/RU→EN return blank until: System Settings ▸ General ▸ Language & Region ▸ Translation Languages ▸ Add Language (one-time, per pair). Then `apple-translate --to en` works offline.

## Proven on merlib-dump this session

- KeelyNet ENERGY word cloud (NLTagger): energy, power, field, wave, current, potential, vacuum, source, tesla, magnetic, charge, water, force — a real topical fingerprint, function words auto-dropped.
- Cross-category semantic search over 176k lines.
- `embed` / `/embed` warmer with live progress + `--status` / `--stat`.

## Next steps (ranked)

1. ~~Persisted `.npy` matrix cache → 59s → ~2s~~ **DONE (59s → ~0.8s), with delta-merge for the growing shared cache.**
2. ~~Compile `apple-ner`~~ **DONE (0.48s → 0.11s).** Run the full Wootan `messages-split/` contacts graph now that it's feasible.
3. **FM-on-Mini worker** — wire `SystemLanguageModel` (the Mini's on-device LLM) into a Syncthing-dispatched service for zero-token summaries / structured extraction over the archive.
4. **Bounded folder word-cloud Quick Action** — `bin/folder-wordcloud` + "Word Cloud.workflow" (samples ≤800 files, skips >400KB, detaches). Generalize the pattern to other right-click ML actions (Find Duplicates, Semantic Map).
5. **Install Translation language packs** → cross-language normalization of the Norwegian/Scandi/Russian corpora.
6. **`embed` should refold the matrix** after warming a corpus (call `vault-grep --rebuild-matrix`) so the delta stays empty.

## Word Cloud from Finder (2026-06-01)

`bin/folder-wordcloud <dir>` backs the **"Word Cloud" Finder Quick Action** (`bin/build-wordcloud-quickaction` installs it to `~/Library/Services/`). Right-click a folder → Quick Actions → Word Cloud → writes a persistent `_WORDCLOUD.md` and opens it. **Bounded by design** (apple-keywords `--dir` recurses unbounded — a right-click on merlib-dump's 31,876 files was an 11-min double-pass grind): samples ≤`WORDCLOUD_MAX_FILES` (800) files, skips files >`WORDCLOUD_MAX_KB` (400), runs once, nice'd, detaches so Finder returns instantly.

## See also

- [on-device-ml.md](../concepts/on-device-ml.md) — framework map
- [on-device-ml-archive-applications.md](../concepts/on-device-ml-archive-applications.md) — the 9 application patterns
- [coreml-sentence-transformer-upgrade.md](../concepts/coreml-sentence-transformer-upgrade.md) — apple-embed-pro design
