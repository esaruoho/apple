# rec-subtitle — the spawning session (vocabulary / proper-noun alignment)

**How to get back**
- Transcript: `file:///Users/esaruoho/.claude/projects/-Users-esaruoho-work-apple/83395bda-acce-4e8c-b9dd-bdca7412bf4e.jsonl`
- Session ID: `83395bda-acce-4e8c-b9dd-bdca7412bf4e`
- Resume: `claude --resume 83395bda-acce-4e8c-b9dd-bdca7412bf4e`
- Date: 2026-08-23, ~00:15–00:30 EEST (Europe/Helsinki)

## The request (verbatim in substance)

> "recburn. the transcripter there has trouble understanding when i say 'Paketti'. for instance,
> it detects it as 'Pucketty', and 'Renoise' is detected as 'Reno', and sometimes 'Paketti' is
> detected as 'Pocketty'. can you figure out how to align recburn so that the transcription part
> definitely figures out that its 'Paketti'. same for if whisper detects 'Lacklustre' — it should
> instead write 'Lackluster'."

The load-bearing word is **definitely**. That ruled out the obvious answer.

## What was already there, and why it wasn't the answer

`rec-subtitle.swift` already had `--prompt` → `whisper --initial_prompt`, and
`screen-audio-record.swift` already had `--burn-prompt` feeding it. So a "fix" could have been a
one-liner: put the words in a default prompt and call it done.

That would have been wrong. `--initial_prompt` conditions the decoder's first window — it makes
the right spelling *more likely*. It does not make it certain, it decays over a long recording,
and it silently does nothing when the model is confident about its wrong guess. Shipping only
the bias would have answered a different question than the one asked.

## The decision: fix it at both ends

1. **Bias** (probabilistic, cheap, helps everywhere): the canonical terms become the
   `--initial_prompt` automatically — Esa no longer types anything.
2. **Repair** (deterministic, and the reason this can be promised): the finished `.srt` is swept
   and rewritten before anything is burned into the picture.

Both halves read one file, so there is one place to add a word.

## Two design calls worth recording

**Sound-alikes, not edit distance.** "Pucketty" → "Paketti" is edit distance 3 — too far for any
threshold that isn't also a false-positive machine. But Whisper heard the *sounds* correctly and
only spelled them wrong, so the right metric is phonetic: American Soundex codes Pucketty,
Pocketty, Packetti, Paketi and Paketti all `P230`; Lacklustre and Lackluster both `L242`. That
means the unlisted manglings get caught too — Esa does not have to enumerate them in advance.

**The English-word veto.** A phonetic sweep left alone would rewrite real speech. So any token
that appears in `/usr/share/dict/words` is never touched, no matter what it rhymes with:
*"I put the **packet** in the tracker"* survives verbatim, while *"Packetti"* (not a word) is
repaired. Nonsense tokens are exactly the ones Whisper invents for a name it doesn't know.

Side effect surfaced deliberately: canonical terms are also **case-normalised**, so a lowercase
"lackluster" becomes "Lackluster". For Esa (the artist name) that is right; for someone using
the tool on the adjective it would over-capitalise. It is one line and the vocabulary is a file.

## Honesty about the grades

Six new scenarios on the card. The five graded `@hw-verified` were actually run — a 3-cue `.srt`
put through `--fix-srt` (6 corrections, correct output), the sibling-file lookup with no flags,
and the 10-assertion `--self-test`. The `@built` one is the `--initial_prompt` wiring: it
compiles and the argument is assembled, but "did Whisper spell it right more often because of
the prompt" was **not** measured against a real recording, so it is not claimed.

The self-test exists because of the project's own rule that pure logic gets checked headlessly
before anything claims to work — `build.sh` now runs it right after compiling, so a broken rule
fails the build instead of a screencast.

## Not done

No live end-to-end recording was made — the sweep was proven on transcripts, not on a fresh
`recburn` take. The vocabulary ships with Esa's own terms (Renoise, Paketti, Redux, Lackluster,
Esa Ruoho, Impulse Tracker, Cloudcity, Loupedeck); anyone else's list is a file edit away.

---

# Session addendum — 2026-08-27: "Paketti" came back as "Pocket to"

## How to get back

- Transcript: `file:///Users/esaruoho/.claude/projects/-Users-esaruoho-work-apple/f6b36e8e-f9ea-4a77-af51-f4674a93172e.jsonl`
- Session ID: `f6b36e8e-f9ea-4a77-af51-f4674a93172e` · `claude --resume f6b36e8e-f9ea-4a77-af51-f4674a93172e`
- Date: **2026-08-27**, EEST. Same session as
  [`recburn-voice-balance`](recburn-voice-balance.feature) — the audio fix came first, then
  Esa noticed the subtitle.

## What Esa said

> "additionally, i said "Paketti" and it thought it was "Pocket to". that's no good."

## Why the existing vocabulary layer did not catch it

All three passes had a reason to decline, and each reason was individually correct:

| pass | why it missed |
|---|---|
| listed aliases | that spelling was not in the list |
| Soundex fuzzy | it tokenises one word at a time; this was two |
| dictionary veto | "pocket" is real English, so hands off — by design |

The uncomfortable part is the third row. The English-word veto exists to stop the tool
rewriting ordinary speech, and it is the *same rule* that blinds it here. That is not a
loose end, it is a structural blind spot: **when Whisper meets a name it does not know it
substitutes the nearest thing in its own vocabulary, and its vocabulary is English.** The
nonsense spellings the tool already handles ("Pucketty") are the easy half of the problem.

## The signal that made it fixable

Whisper wrote **"Pocket to"** — capital P, in the middle of a sentence. Whisper capitalises
mid-sentence when it thinks it is writing a proper noun. So it had already told us it
believed this was a name; nothing was reading that.

Gate for the new multi-word pass, all four required:

1. first token capitalised, **and not because a sentence began**
2. concatenation is not itself an English word
3. Soundex of the concatenation matches a vocabulary term
4. length within 3 characters of that term

"reached into my pocket to grab it" fails (1). "Pocket to is what I use" fails (1) as
sentence-initial. Both are asserted in the self-test, because the false-positive direction
is the one that would corrupt real speech.

## A second, smaller fix, and a bug I introduced

Whisper's most common mangling is inserting a space into a name, and the alias list had
grown to enumerate spacings: "pack etty", "pa ketti", "packet he", "packet e". Aliases are
now matched with an optional separator between every letter, so **one entry covers every
spacing** — the list went 66 → 56 with strictly more coverage.

That change then caused a bug of my own: "pocket to" and "pocketto" became the *same*
pattern, so the run fixed the line once and reported **"Paketti ×2"**. The text was right;
only the claim about it was wrong. Caught by reading the tool's own output on the real
recording and not believing it. Fixed by deduping aliases on letter sequence, and the
reported count is now asserted by `checkCount` in the self-test — a tool that overstates
what it did is not worth reading.

## Verification

- `rec-subtitle --self-test`: **16/16**, gated by `build.sh`
- on the real transcript: `corrected 1 word — Paketti ×1`, line 3 now reads
  "…modifications I made to the **Paketti** Single Cycle Waveform Rider."
- the video was re-burned from the (already audio-fixed) `-flat.mov`, then the burned video
  was remuxed against that file's audio **stream-copied**, so the corrected-audio track has
  exactly one generation of encoding, not two.
