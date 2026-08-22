---
description: Making Whisper spell your proper nouns right — bias the decoder with --initial_prompt, then repair the .srt with a Soundex sweep vetoed by the system dictionary. The recburn vocabulary layer.
---

# Transcript vocabulary alignment (Paketti, not "Pucketty")

Whisper spells names it has never seen **phonetically**. On Esa's screencasts that means
`Paketti` → "Pucketty" / "Pocketty" / "Packetti", `Renoise` → "Reno", `Lackluster` →
"Lacklustre". The audio was heard correctly; only the spelling is wrong.

## Why `--initial_prompt` alone is not the fix

`whisper --initial_prompt "Renoise, Paketti, Lackluster."` conditions the decoder's first
window and genuinely helps — but it is a **nudge, not a guarantee**: it decays over a long
recording and does nothing when the model is confident in its wrong guess. Anyone promising
"definitely" on bias alone is overselling it.

## The fix is at both ends

| Half | Mechanism | Property |
|---|---|---|
| **Bias** | canonical terms → `whisper --initial_prompt` | probabilistic, free, helps everywhere |
| **Repair** | sweep the finished `.srt`, rewrite to canonical | **deterministic** — this is the guarantee |

Both read one vocabulary file, so a new word is added in one place.

## The repair sweep, in three steps

1. **Listed mishearings** — regex, case-insensitive, longest-alias-first, `[ -]+` between an
   alias's words so "lack luster" / "lack-lustre" both match.
2. **Case normalisation** — a canonical term written in the wrong case is rewritten
   ("renoise" → "Renoise"). Note this also capitalises the adjective *lackluster*; correct for
   the artist name, a deliberate trade.
3. **Sound-alikes nobody listed** — **American Soundex**, not edit distance. "Pucketty" is
   edit-distance 3 from "Paketti" (too far for any safe threshold) but codes `P230`, the same
   as Pocketty / Packetti / Paketi / Paketti. Lacklustre and Lackluster both code `L242`.

### The veto that makes step 3 safe

A phonetic sweep on its own would rewrite ordinary speech. So **any token that is a real
English word (`/usr/share/dict/words`) is never touched**, whatever it rhymes with:

> "I put the **packet** in the tracker" — untouched. "**Packetti**" — repaired.

Nonsense tokens are precisely what Whisper invents for a name it does not know, so the
dictionary is a near-perfect discriminator. Also required: token ≥5 chars, canonical ≥5 chars,
length difference ≤3. Possessives are preserved (`Pucketty's` → `Paketti's`).

## Where the vocabulary lives

First hit wins: `--vocab FILE` · `$RECBURN_VOCAB` · `.recburn-vocabulary.json` beside the
recording · `./.recburn-vocabulary.json` · `~/.config/recburn/vocabulary.json` ·
`recburn-vocabulary.json` beside the binary (shipped; also inside `RecBurn.app/Contents/MacOS`).
Editing it needs **no rebuild**.

```json
{ "terms": ["Renoise", "Paketti", "Lackluster"],
  "corrections": { "Paketti": ["pucketty", "pocketty"], "Renoise": ["reno"] },
  "fuzzy": true }
```

## Using it

```bash
recburn                              # vocabulary applied automatically (bias + sweep)
recburn --no-vocab                   # raw transcription
recburn --burn-vocab other.json      # a different vocabulary for this take
rec-subtitle --fix-srt old.srt       # align a transcript you already have, in place
rec-subtitle --self-test             # 10 headless assertions (build.sh gates on this)
```

Implementation: `bin/rec-subtitle.swift` (`Vocabulary`, `loadVocabulary`, `soundex`,
`correctText`, `correctSRT`, `vocabularySelfTest`), pass-through in
`bin/screen-audio-record.swift`. Report card: `features/rec-subtitle.feature`.
Mirrored to the public [`esaruoho/apple-rec`](https://github.com/esaruoho/apple-rec).

Related: [`recburn` pipeline report](../../features/rec-pipeline-report.md) ·
[`speech-transcribe`](../../bin/speech-transcribe.swift) (Apple-native alternative engine).
