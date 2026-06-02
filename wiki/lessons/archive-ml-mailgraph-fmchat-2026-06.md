# Session retrospective — on-device ML on the archive, mailgraph, fm-chat (2026-06-01/02)

A long session applying the Apple on-device ML stack to the free-energy archive
(merlib-dump + the Norman Wootan KeelyNET USB), building new tools, fixing a
real data gap, and making the Mini's LLM resumable. What we built and learned.

## New tools (all `~/work/apple/bin/`, Apple-native, zero-token)

| Tool | What | Framework |
|------|------|-----------|
| `embed` + `/embed` | corpus warmer with live progress + `--status`/`--stat` | NLEmbedding |
| `apple-keywords` | "useful words" word-cloud — POS-filter + lemmatize, drops of/the junk | NLTagger |
| `apple-ner` | person/place/org extraction | NLTagger .nameType |
| `ner-graph` | co-occurrence contacts graph **with alias resolution** | apple-ner |
| `mailgraph` + `/mailgraph` | directed who-wrote-to-whom from From:/To: headers; SVG render; threads | stdlib |
| `bbs-to-eml` | WILDCAT BBS message base → RFC822 .eml | stdlib |
| `fm-chat` | resumable chat with the Mini's FoundationModels, in `sessions` | FoundationModels |
| `folder-wordcloud` | bounded word-cloud backing the Finder Quick Action | apple-keywords |

## Things proven on the data

- **KeelyNet** warmed whole (1,000 files / 176k lines) → one semantic space;
  cross-category queries land (neutral-spike → ZPE/Puthoff/Bearden).
- **Word-cloud fingerprints differ by corpus**: KeelyNet = circuit/magnet/coil;
  Bearden/Cheniere = scalar/vacuum/potential/radar/weapon. The vocabulary IS the
  signature.
- **mailgraph > ner-graph for contacts**: header parsing (the addressing) beats
  NER co-occurrence (inference). Jerry Decker is the KeelyNet hub (2,076 sent),
  Wootan⇄Decker the densest dialogue.
- **fm-chat on the Mini works** over the Syncthing fm-inbox→worker bridge
  (~1s model, ~4.5s round-trip), now persisted + resumable in `sessions` (F glyph).

## Lessons

1. **One bad byte kills a UTF-8 decode.** `String(data:encoding:.utf8)` returns
   `nil` for the WHOLE input if any byte is invalid → empty corpus → bogus "no
   input". Old web-mirror / DOS text needs a **Latin-1 fallback** (never fails).
   This was the Word Cloud Quick Action "doesn't work" bug.

2. **"Tidier" is not "complete" — verify a derived subset before trusting it.**
   The `.eml` export looked clean but covered **1994 only** (missing 1995–96,
   ~3,282 messages). The source `raw.md` files never had those years; the data
   lived only on the USB. Esa's skepticism ("why 5,635 → 1,658?") was right.
   Always check by counts/date-range, never infer completeness.

3. **Entity resolution is hard and needs escapes.** NER noise makes fake name
   clusters ("Given Norman", "Heck Jerry") that defeat naive merging. What worked:
   nickname map + last-name anchoring + junk-word filter + frequency-dominant
   disambiguation, plus a `--show-merges` audit so it's not a black box. The
   bare-surname-equals-someone's-first-name case (Maxwell physicist vs Maxwell
   Chikumbutso) is genuinely unsolvable heuristically — flag it, don't hide it.

4. **Render Apple-native.** Graphviz isn't on the pedigree → `mailgraph` emits
   **SVG by hand** (pure stdlib) and `qlmanage -t` makes a PNG. No Homebrew.

5. **ML ranks/groups; Claude reasons.** Cast the cheap wide net zero-token
   (clusters, graphs, clouds) over EVERYTHING; spend Claude tokens only on the
   shortlist. The hand-built `*-analysis.md` files are what step 2 looks like.

6. **Self-matching `pgrep` wait-loops spin forever** (zombie shells, CPU burn).
   See memory `feedback_no_self_matching_pgrep_waits`. Wait for the harness
   notification instead.

7. **The `wc -l | tr -d ' '` pipe returns empty in this shell** intermittently —
   use Python for counts when it matters.

## Data outcome

`messages-eml/` completed: 1994 (1,996) · **1995 (2,375, was 2)** · **1996 (658,
was 0)** → 5,029 total. Canonical source-of-truth is whole; the derived views
(`messages-md`, `*.html`, `.mbox`, `timeline.json`) are still 1994-only and
regenerable.

## See also

- [../operations/merlib-ml-system-state.md](../operations/merlib-ml-system-state.md)
- [../concepts/on-device-ml.md](../concepts/on-device-ml.md)
- [../concepts/on-device-ml-archive-applications.md](../concepts/on-device-ml-archive-applications.md)
