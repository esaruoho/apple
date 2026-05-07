# Sal Source Archive

This directory is the canonical archive for Sal Soghoian source material — primary sources kept verbatim, with extracted quotables and provenance notes pointed back to the canonical biography in `/sal-soghoian.md`.

## Layout

Each site or article gets its own capsule:

```text
sources/sal/<site>/                # site mirrors
  mirror/                          # untouched captured HTML and supporting files
  assets/                          # downloaded scripts, PDFs, ZIPs, images
  manifest.yaml                    # origin URLs, capture timestamps, status, extraction progress

sources/sal/articles/              # individual articles, interviews, profiles
  <slug>.md                        # clean markdown transcription with YAML frontmatter
  <slug>-wayback.html              # raw Wayback / source HTML if available
```

## Follow-on destinations

- Extract runnable code to `scripts/sal/<site-slug>/`
- Store page and concept notes in `analysis/sal/`
- Update `indexes/sal-sites.yaml`, `indexes/sal-scripts.yaml`, `indexes/sal-concepts.yaml`
- **Fold biographical / philosophical findings into `sal-soghoian.md`** — that file is the canonical "Who is Sal / What would Sal do" doc; this directory is the receipts.

---

## Articles index

### `articles/wired-soghoian-automation-2018.md`

**WIRED — "How One Apple Programmer Got Apps Talking to Each Other"**
Jordan McMahon, 2018-06-02. Photographer: Phuc Pham.
Source: <https://www.wired.com/story/soghoian-automation/>
Archive: <https://web.archive.org/web/20180602160148/https://www.wired.com/story/soghoian-automation/>
Local PDF: `~/Downloads/How Apple Programmer Sal Soghoian Got Apps Talking to Each Other _ WIRED.pdf`
Local HTML: `articles/wired-soghoian-automation-2018-wayback.html`
Local MD (clean transcription with quotables): `articles/wired-soghoian-automation-2018.md`

**Why this article matters to the canon — provenance for repeated phrases:**

| Phrase / claim | Provenance | Speaker |
|---|---|---|
| **"The Dean of Automation"** | WIRED 2018, photo caption + final pull-quote | **Paul Kent**, founder of pKreative event consulting, ex-MacWorld show manager |
| **"He ate his own dog food, he lived amongst the community and championed them."** | WIRED 2018 closing line | Paul Kent |
| **"Sal has a true open source mentality of opening the computer up for normal people."** | WIRED 2018 (featured pull-quote) | Steve Wozniak |
| **"[AppleScript] put incredible power in the hands of regular users without putting a lifetime of effort into this language."** | WIRED 2018 | Steve Wozniak |
| **"[Sal is] a combination of geek with mature sophistication."** | WIRED 2018 | Steve Wozniak |
| **"I'm Sal Soghoian, and you're wrong. My technology is better than Windows."** | WIRED 2018, recounting 1997 confrontation | Sal, to Steve Jobs |
| **"I might be this dog on my square yard of dirt … I'm gonna bite your leg."** | WIRED 2018 | Sal, retelling 1997 |
| **"It used to be easy when we were 100 times better than Windows. But now that we're not, you don't know what to do."** | WIRED 2018 | Steve Jobs, July 1997 |
| **"Automation, but for the rest of us."** | WIRED 2018, the Automator hallway-stakeout pitch line | Sal, 2004 |
| **"Stop! I want robots for icons."** | WIRED 2018 — origin of the Automator robot icon | Steve Jobs, 2004 |
| **"I'd like to invite Saul up on the stage, whom you all know."** | WIRED 2018, WWDC 2004 keynote | Steve Jobs |
| **Automator 1.0 ship date: April 29, 2005** | WIRED 2018 | — |
| **"Automation becomes more useful when it gets faster and can respond to more types of events…"** (screwdriver+hammer analogy) | WIRED 2018 | Ken Case, Omni Group CEO |
| **"I'd like to be an old guy, looking back at things, and say I did something that made people's lives better, that they were able to control their destiny to some degree…"** (the destiny credo) | WIRED 2018 | Sal |
| **"In October of 2016, he was let go from Apple … No warning, no early signs. Apple just said his position didn't exist anymore."** | WIRED 2018 | Jordan McMahon, narrating |
| **iOS automation lineage**: Pierce → Arment → Barnard/Youens → Workflow → Apple | WIRED 2018 — full chain with names and dates | — |
| **Barnard's "strategic blunder"** (had Automator-for-iOS in 2014, didn't ship out of App Store fear) | WIRED 2018 | David Barnard (in retrospect) |

All of the above have been folded into `sal-soghoian.md` in their relevant sections — see *Two Jobs Confrontations*, *His Credo*, *The Parallel iOS Track (2011–2017)*, and *What Others Say About Sal*.

### `articles/wired-soghoian-automation-2018-wayback.html`

Raw Wayback archive of the same WIRED article. Kept as the untouched source-of-truth in case the markdown transcription drifts. **Do not edit.**

---

## Site mirrors

| Capsule | Source | Status |
|---|---|---|
| `macosxautomation.com/` | <http://macosxautomation.com> | hub site, manifest TBD |
| `iworkautomation.com/` | <http://iworkautomation.com> | iWork scripting, last updated Oct 2014 |
| `photosautomation.com/` | <http://photosautomation.com> | Photos automation |
| `configautomation.com/` | <http://configautomation.com> | Apple Configurator automation |
| `dictationcommands.com/` | <http://dictationcommands.com> | Voice commands for macOS apps |
| `omni-automation.com/` | <http://omni-automation.com> | Omni JavaScript automation (post-Apple) |

See `sal-soghoian.md` § *Sal's Web Empire* for risk assessment and archival priority.
