# Tooling for running merlib-mirror — and the FoundationModels-guardrail verdict

**Question (2026-06-02):** what Apple-native tools would help run merlib-mirror /
the archive, and should pakettibot-agent use FoundationModels (or not, because of
the guardrails)?

## The guardrail verdict: prefer NOT, for archive content

FoundationModels (the Mini's on-device ~3B LLM) ships **aggressive Apple safety
guardrails**. `fm`'s own error path has a dedicated branch — *"Apple's on-device
safety guardrail blocked this (it's aggressive). Rephrase and try again."* The
free-energy archive is full of exactly the text those guardrails flag:

- **scalar-EM "weapons" physics** (Bearden's entire corpus),
- **medical claims** (colloidal silver, Rife, cancer protocols, Crile),
- **fringe / unverified science** the guardrail may treat as "misinformation".

So routing archive *content generation* through FM means frequent false refusals
on legitimate archival/analytical work. **Verdict: don't make FM the reasoning
engine for archive tasks.** pakettibot-agent already runs Claude Code locally on
the Mini — Claude handles fringe/archival content fine for legitimate analysis.

**Where FM IS safe to use** (narrow, benign, mechanical, structured):
- classify a filename / route a file to a folder,
- summarize a clearly-benign paragraph,
- extract a structured list (people, dates) from neutral text.

But note: **the deterministic on-device ML below does most of those WITHOUT any
guardrail at all** — embeddings, NER, and Vision are not generative, so they have
no safety filter and never refuse. That's the real reason to prefer them:
*non-generative on-device ML has zero guardrail surface.*

### The architecture

| Job | Use | Guardrail risk |
|-----|-----|----------------|
| rank / group / search / dedup / tag | deterministic on-device ML (NLEmbedding, NLTagger, Vision) | **none** — not generative |
| narrow benign generation (classify, neutral summary, structured extract) | FM, optionally | low if text is benign; will refuse on weapons/medical |
| reasoning over sensitive/fringe content, synthesis, judgement | Claude (pakettibot-agent already does this) | none |

So: FM as an *optional accelerator* for the safe mechanical slice, deterministic
ML for everything rankable, Claude for the content that matters. Don't push
archive prose through FM.

## Tools that would help run merlib-mirror (Apple-native, mostly zero-token)

Most of these reuse the on-device stack already built (`embed`, `vault-grep`,
`apple-keywords`, `apple-ner`/`ner-graph`, `apple-image-similar`, `mailgraph`,
`apple-translate`). New ones worth building:

1. **`merlib-dedup`** — flag duplicate / near-duplicate files across the whole
   dump: exact (sha), visual (`apple-image-similar` over the 1,789+ scans), and
   semantic (`vault-cluster` over reposted articles — KeelyNet's SWEET1-4A etc.).
2. **`merlib-route`** — for an incoming file, embed it and suggest which existing
   folder/inventor it belongs to (nearest-centroid over the warmed corpora).
3. **`merlib-tag`** — auto-assign tags matching the existing taxonomy by cosine to
   per-tag centroids (consistent frontmatter tagging, no manual pass).
4. **`merlib-linkcheck`** — deterministic mirror-health: broken internal links,
   missing resources (the `_missing_resources.txt` pattern), orphaned files,
   empty/zero-byte pages. No ML, pure stdlib.
5. **`ocr-triage`** — scan for image-only PDFs, queue them to the Cloudcity
   Syncthing OCR pipeline (never local OCR), track in the OCR ledger.
6. **`merlib-frontmatter`** — normalize/repair YAML frontmatter across the .md
   corpus (title/date/type/tags/source), report gaps.
7. **Archive-wide entity/citation graph** — `ner-graph` at archive scale → who
   appears where across the whole field (the free-energy who-cites-whom map).
8. **Consilience reports** — `vault-consilience` productionized: pick a claim,
   get the matching line from every source corpus (the cross-decade table).
9. **`merlib-translate`** — once language packs are installed, normalize the
   foreign corpora (gratisenergi = Norwegian, iet-forskningsrapporter = Scandi,
   Kozyrev = Russian) to English so they join the one semantic search space.
10. **Browsable index generation** — like `eml-to-views`: per-folder HTML/JSON
    indexes (chronological, by-author, by-topic) for any sub-collection.
11. **Audio → transcript → searchable** — `speech-transcribe` (on-device) over
    CFNPodcast / interview audio, then `embed` so spoken content joins the index.
12. **"What changed" tracker** — snapshot + diff so a re-mirror surfaces only the
    new/changed pages instead of a full re-review.

What I CANNOT do under the Apple-native pedigree: the network mirroring itself
(wget/ArchiveBox are third-party). The pedigree's strength is the *organize /
dedup / search / QC / cross-reference* half — which is most of "running" a mirror
once the bytes are down.

## See also

- [on-device-ml.md](on-device-ml.md) · [on-device-ml-archive-applications.md](on-device-ml-archive-applications.md)
- memory `fm_worker_fleet_llm` — the FM bridge + "guardrails aggressive" note
