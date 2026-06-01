# On-device ML for mirrored archives — what it brings beyond search

**The question (2026-06-01):** we have `embed`/`vault-grep` doing semantic search. What *else* can the on-device ML stack bring to a mirrored archive like KeelyNet ENERGY or the Norman Wootan corpus?

**The framing that matters.** The Wootan articles already in `merlib-dump/articles/` — `norman-wootan-mra-contacts-network-analysis.md`, `keelynet-bbs-wootan-dump-highlights-summary.md`, `norman-wootan-mra03-photo-document-analysis.md`, `wootan-mra-1994-prior-art-analysis.md` — were **hand-built by Claude reading files one at a time.** Token-expensive, and only ever covered the handful of files a human thought to feed in. The on-device ML stack produces the same *kinds* of output — entity graphs, paraphrase chains, dedup, topic clusters — but **zero-token, across the whole mirror, re-runnable as it grows.** That's the upgrade: from "Claude read these 12 files" to "every file in the mirror, every time, for free."

Each application below names the Apple framework, the bin tool, and a runnable command.

---

## 1. Cross-source consilience — the same claim across decades/authors (`vault-consilience`)

The killer app. Wootan's "neutral spike — earth-origin, super-luminal, all-penetrating" is a *claim*. Where else in the mirror does that same physical idea appear under different words? Milewski's Superlight, Bearden's scalar, KeelyNet's aether-tap entries, Kozyrev's time-energy. Consilience finds the best paraphrase in *each* source — zero shared vocabulary required.

```bash
embed ~/work/merlib-dump/sources/norman-wootan
vault-consilience "earth-origin super-luminal all-penetrating energy spike" \
  --root ~/work/merlib-dump/keelynet/ENERGY \
  --root ~/work/merlib-dump/sources/norman-wootan \
  --root ~/work/merlib-dump/Cheniere.org
```

This is the machine version of the hand-built consilience articles — but it scans 61k+ lines instead of the dozen files a human pre-selected.

## 2. Internal echo / repost detection (`vault-cluster`)

KeelyNet BBS reposted the same text under many filenames across years (SWEET1/SWEET2/SWEET4A; FREE-N1/FREEPOL/FREENRG2). `vault-cluster` finds the strongest cross-file paraphrase pairs in one corpus — surfacing "this 1995 post is the same content as this 1998 post, reworded." Cleans the mirror; reveals which sources are original vs. echoes.

```bash
vault-cluster --root ~/work/merlib-dump/keelynet/ENERGY --top 40 --threshold 0.85
```

## 3. Image dedup + scan clustering (Vision FeaturePrint, `apple-image-similar`)

The Wootan corpus is image-heavy (MRA scope photos, scanned letters, schematic scans). FeaturePrint embeds each on the Neural Engine and ranks by visual content:
- **dedup** — the same scope photo saved 3× at distance 0.0
- **cluster** — group "all the oscilloscope-trace photos" vs "all the handwritten-letter scans" vs "all the schematic diagrams" without opening one

```bash
apple-image-similar --dir ~/work/merlib-dump/normanwootan-mra02-saturable-core-series-resonant- --top 30
```

## 4. Entity co-occurrence graph (NLTagger NER, `apple-ner`)

`norman-wootan-mra-contacts-network-analysis.md` was built by hand. NER rebuilds it automatically and at mirror-scale: run `apple-ner` over every Wootan file, take PersonalName/OrganizationName, and co-occurrence-within-file = the edges. Hodowanec, Puthoff, Raivo, Hector, Milewski, Davson, Schappeller all fall out as nodes. Re-run when new mail arrives and the graph updates itself — no Claude in the loop.

```bash
cat ~/work/merlib-dump/sources/norman-wootan/*.md | apple-ner --table
# → feed person/org pairs into a co-occurrence counter = the network
```

## 5. Email-corpus semantic sort (NLEmbedding over the .eml backup)

The Wootan messages are the proof-of-concept of `backup-mailbox`. Once embedded, an inbox becomes *topic-sortable*: which mails are about MRA Q-factor, which about saturable-core geometry, which about patent prosecution — clustered by meaning, not by date or sender. `vault-grep "MRA ultra-high-Q measurement" --root <mail-dir>` answers the inbox by question.

## 6. Auto-tagging to the existing taxonomy (NLEmbedding)

Diary files carry hand-written tags (`ferroresonance`, `neutral-spike`, `shaded-pole-motor`). Embed each existing tag once; for any new mirrored file, cosine its body against the tag centroids and suggest the nearest tags. New mirror content inherits the taxonomy automatically — consistent tagging with no manual pass.

## 7. Orphan / uniqueness detection (inverted `vault-cluster`)

Invert the cluster: find entries whose *nearest neighbour anywhere is still far*. Those are the documents that echo nothing else in the mirror — either the most original primary sources or the most suspect outliers. A "what is genuinely unique here?" pass over the whole archive.

## 8. Cross-language normalization (Translation framework, `apple-translate`)

The mirror has non-English corpora: `gratisenergi-donsmith` / `gratisenergi-freeenergy` (Norwegian), `iet-forskningsrapporter-nr-2` (Scandinavian), Kozyrev (Russian), Schauberger (German). NLEmbedding is English-tuned, so foreign content ranks poorly. Pipe through `apple-translate --to en` first → then embed → and the whole mirror becomes one searchable, cross-language semantic space. (Prereq: install the language packs once via Settings ▸ Translation Languages.)

## 9. Audio → text → embed (Speech framework, `speech-transcribe`)

Any podcast/interview audio in the mirror (CFNPodcast, `audio/`) runs through `speech-transcribe` (on-device `SFSpeechRecognizer`) → transcript → `embed` → searchable alongside the text. Closes the loop: spoken-word mirror content joins the same semantic index as the documents.

---

## The pattern underneath

Every hand-built `*-analysis.md` in the archive is a *manual pass* — Claude read N files and wrote a synthesis. On-device ML turns each of those manual passes into a **standing, zero-token capability** that runs over the entire mirror and re-runs for free whenever the mirror grows. Same Russell self-multiplication thread the whole apple skill rides: identify the pattern of manual labour → organize it → it becomes a reusable principle.

The honest division of labour: **ML ranks and groups; Claude reasons.** Use the on-device tools to surface candidates (the consilience pairs, the entity edges, the dup clusters, the orphans) zero-token across everything — then spend Claude tokens only on the shortlist that actually needs synthesis. That's the cheap-wide-net / expensive-deep-read split.

## See also

- [on-device-ml.md](on-device-ml.md) — the framework map + tool reference
- [coreml-sentence-transformer-upgrade.md](coreml-sentence-transformer-upgrade.md) — the sharpness upgrade path when NLEmbedding's ranking is too coarse
- `bin/embed` — corpus warmer; `bin/vault-grep` / `vault-cluster` / `vault-consilience` — the consumers
