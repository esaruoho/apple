# How This Repo Was Built — One Conversation, 167 Files

> From a single Loupedeck Live button press to 167 public files, 31 extracted scripting dictionaries, 64 launcher scripts, 34 whiteboards, and a complete macOS automation knowledge base — all in one Claude Code conversation.

## What Was Built

| Component | Count | Purpose |
|-----------|-------|---------|
| Launcher scripts | 64 | One-button app activation for Loupedeck Live |
| Scripting dictionaries | 31 apps | Full sdef extraction (YAML + MD + examples) |
| Data type chaining index | 1 | Cross-app workflow compatibility map |
| Whiteboards | 34 (5 sets) | Visual educational content |
| Knowledge files | 8+ | Atlas, Sal profile, patent analysis, etc. |
| **Total public files** | **167** | Pushed to github.com/esaruoho/apple |

## The Conversation — 22 Prompts, 8 Phases

Every file in this repo was created through a single conversation with [Claude Code](https://claude.ai/claude-code). Here are the exact prompts, in order, that built it all.

---

### Phase 1: Foundation (Prompts 1-4)

**Goal:** Create a skill that writes perfect AppleScript, starting with one script.

#### Prompt 1 — The Spark
```
make me a global Apple skill. the skill is able to write perfect AppleScript.
the first errand i give you, is, create me an AppleScript that brings the
Finder.app in macOS to the forefront. the app that i am using, loupedeck Live
programmer, doesn't let me open the app itself, since it's not listed, so now
i have to modify the loupedeck live's icons on the screen, with the editor, to
make me one that runs AppleScript. i want to basically store that i'm an apple
afficionade, and that i have a loupedeck live, and i want to optimize my
workday. let's go.
```

**Result:** Created skill definition, script catalog, and the first script: `tell application "Finder" to activate`. Tested it — Finder came to front.

#### Prompt 2 — Self-Learning
```
ok. remember, the skill from now on, in this folder, always updates itself
when i describe things to it, and learns from it. and has a memory. got it?
```

**Result:** The skill became self-updating — every conversation adds knowledge.

#### Prompt 3 — What Can You Do?
```
what apple scripts are you able to write for me? what have you written?
please open the folder where you stored the applescript.
```

**Result:** Showed catalog of possibilities: Mail, Safari, Music, Photos, Notes, Calendar, Finder, System Events, Terminal automation.

#### Prompt 4 — Relocate
```
i propose the apple skill is stored in the apple folder we're at. do you see?
```

**Result:** Moved skill files to the working directory, co-located with scripts.

---

### Phase 2: GitHub + Sal Soghoian (Prompts 5-9)

**Goal:** Create a public GitHub repo and integrate Sal Soghoian's automation philosophy.

#### Prompt 5 — Create the Repo
```
now write me a github repository called esaruoho/apple. pump it full of
exciting marketing speech, based on what i've described about my role as a
workflow / optimizer / user experience specialist / software tester /
electronic musician. base it on what i've done with Paketti — so.. we're
gonna start this process of teaching a faster way for claude to know
applescript.
```

**Result:** Created `esaruoho/apple` on GitHub with full README — badges, author bio, Paketti reference, Patreon link.

#### Prompt 6 — The Oracle
```
now, let's be clever about this. let's use Sal Soghoian, an Apple Alumni.
He worked at Apple in 1997 and until 2016. find about this dude. 'what would
sal do' 'sal' are the trigger words for this knowledge.
```

**Result:** Researched Sal Soghoian — Apple's Product Manager of Automation Technologies (1997-2016), co-inventor of Automator. Created `sal-soghoian.md` with full profile, philosophy, and "What Would Sal Do" (WWSD) 10 principles.

#### Prompt 7 — Bash Profile
```
how about you know the stuff in my .bash_profile that's pure apple commands.
stuff like 'o' to open a finder in a folder. this kinda stuff? the really
regular OS only stuff. check it out!
```

**Result:** Extracted macOS-native bash patterns — app launchers, directory navigation, the `osascript script.scpt &` fire-and-forget pattern, the `ask()` function bridging AppleScript dictation with CLI tools.

#### Prompt 8 — The Patent
```
here's a patent Sal was involved in fostering. please store it, and analyze
what it does for automation.
```

**Result:** Stored and analyzed US Patent 7,428,535 — "Automatic Relevance Filtering" — the Automator patent. Core innovation: context-aware action filtering with automatic data type bridging using breadth-first search.

#### Prompt 9 — Author Identity
```
mark myself as, on the readme.md for Apple repository, that i'm a user
automation expert, software developer, author, tester, musician. i'm a user
experience evaluator. i develop my own music automation tools to other apps.
```

**Result:** Updated README with complete author bio.

---

### Phase 3: All Apps + Launchers + Atlas (Prompts 10-11)

**Goal:** Create launchers for every Apple app and map the full automation landscape.

#### Prompt 10 — Edit the Aliases
```
open in sublime text the bash aliases so i can freely edit it.
```

#### Prompt 11 — Go Deeper
```
i wanna go a bit deeper. i believe some of these are fundamental "human
rights", so to speak. i propose we do it so that we use all the Apple apps
in /Applications, and all the Apple Utilities, and make App Launches for each
of them. then we query each of them for Sal-like content, for API automation
workflow optimizing, using automator + applescript. thusly we're able to
explain the terminal side of things, i.e. how to optimize these things and
what are the benefits. i believe it's all been strung together like pearls on
a chain, and you just need to look at Sal's work with Automator, AppleScript,
Terminal and all that other stuff.
```

**Result:**
- Listed all apps in `/System/Applications/` and `/Applications/`
- Checked which apps have scripting dictionaries via `sdef` — found 22 fully scriptable, 6 scriptable utilities, 3 hidden powerhouses (System Events, Image Events, Finder in CoreServices)
- Created `apple-automation-atlas.md` — complete map: 7-layer architecture, 4-tier scriptability model, CLI tools
- Generated **64 launcher scripts** in `scripts/launchers/`
- **Bug encountered:** Bash heredoc consumed `$app_name` variable, producing `activate-.applescript`. Fixed by rewriting the generator in Python.

---

### Phase 4: Whiteboards (Prompt 12)

**Goal:** Generate educational whiteboards for visual learning.

#### Prompt 12 — Visualize Everything
```
incorporate the whiteboard skill as an "Apple" skill. the idea here is that
what you've created, the .bash_profile extract, first of all, i need to see
it, second of all, please roll me whiteboards on the topic.
```

**Result:** Generated 3 sets in parallel:
- `bash-aliases/` — 5 boards on macOS bash patterns
- `automation-atlas/` — 5 boards on the full scriptability map
- `sal-soghoian/` — 4 boards on Sal's career and philosophy

---

### Phase 5: Scripting Dictionary Extraction (Prompt 13)

**Goal:** Extract sdef from all 31 scriptable apps as machine-readable domain knowledge.

#### Prompt 13 — The Big One
```
can we basically use the scripting dictionary to modify the Apple Skill so
it's available to us as knowledge? domain knowledge, one chapter at a time.
basically, since you have the domain knowledge now, present to me a method
for automating every single apple app and passing information across them,
and having proper automation control over the apps we want to run and what
we want to start. so basically a box we shout into on an interface level,
and it's stored as markdown/yaml.
```

**Result:**
- Created `bin/sdef-extract.py` — Python tool extracting sdef XML from all 31 scriptable apps
- Generates per-app: `.yaml` (machine-readable), `.md` (human-readable), `-examples.md` (ready-to-use snippets)
- Generates master `_index.yaml` with **data type chaining** — which apps produce/consume which data types
- **31 apps extracted**, 347 commands, 408 classes
- **Key discovery:** Finder lives at `/System/Library/CoreServices/Finder.app`, not `/System/Applications/`
- **Data type chaining revealed:**
  - Image Events → 7 apps (alias/file)
  - System Events → 9 apps (file)
  - 12 apps produce `document` → feeds into Keynote/Numbers/Pages/QuickTime
  - **System Events is the universal bridge** (89 classes, 31 commands)

---

### Phase 6: Public/Private Split (Prompts 14-17)

**Goal:** Separate private and public content, push to GitHub.

#### Prompt 14
```
can we please update the apple repository with this information
```

#### Prompt 15
```
please look at my .bash_profile and consider. the public version of this repo
cannot be having work-related things, especially commandlines. although, why not?
```

#### Prompt 16
```
is there a best practices method that we've learned from Sal + sdef, that
would let us understand what the commandline arguments for an app are?
```

**Result:** Probed 6 intelligence layers beyond sdef:
1. sdef (scripting dictionaries)
2. URL schemes (PlistBuddy → CFBundleURLTypes)
3. Document types (CFBundleDocumentTypes)
4. CLI help (--help, man pages)
5. Entitlements (codesign)
6. Man pages

**Discoveries:** Music responds to `itms://`, `music://`; Shortcuts has a proper CLI; Safari `--help` just launches the app (GUI apps don't support it).

#### Prompt 17
```
i think what we should do is maintain two versions. one with my private
skills, that i don't push out to the public repo.. and the other version,
which has the pertinent "public product" things.
```

**Result:** Created `.gitignore` splitting private from public. Committed and pushed **167 files** to GitHub.

---

### Phase 7: Deep Dive Whiteboards (Prompts 18-19)

#### Prompt 18
```
roll me 10 whiteboards about what you've discovered about sdef, from the
point of view of how Sal designed it, also do the possibilities
```

#### Prompt 19
```
now please describe to me this and bake me 10 whiteboards about the
understanding
```

**Result:** 20 more whiteboards across 2 sets:
- `sdef-deep-dive/` — 10 boards from the atlas perspective
- `sdef-understanding/` — 10 boards on how Sal connected every app

**Bug:** `--deep` flag not supported with file input. Fixed by using `--full --smart-prompts`.

---

### Phase 8: Final Polish (Prompts 20-22)

#### Prompt 20
```
update apple github repo. tell me what you did
```

#### Prompt 21
```
update the skill
```

**Result:** Updated skill to v2.0.0 with all accumulated knowledge.

#### Prompt 22
```
use replay skill so this is stored as a conversation, that can then be shown
as markdown, the full conversation, and thus show how the apple github repo
was created.
```

**Result:** This document.

---

## Key Decisions

| Decision | Why |
|----------|-----|
| Use Python for launcher generation, not bash heredocs | Bash heredocs ate variables, Python was reliable |
| Extract sdef as YAML + MD + examples | Machine-readable + human-readable + actionable |
| Build data type chaining index | Realizes Sal's Automator patent vision as a lookup table |
| Public/private split via .gitignore | Personal configs stay local, universal automation goes public |
| System Events as universal bridge | 89 classes, 31 commands — controls ANY app's UI |

## Errors and Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| Scripts named `activate-.applescript` | Bash heredoc consumed `$app_name` | Rewrote generator in Python |
| `--deep` flag failed on whiteboards | Not supported with file input | Used `--full --smart-prompts` |
| `sdef Finder.app` returned nothing | Finder at `/System/Library/CoreServices/` | Updated path registry |
| Safari `--help` launched the app | GUI apps don't support `--help` | Documented as expected behavior |
| File still tracked after .gitignore | Was tracked from initial commit | `git rm --cached` |

## Timeline

| Time | Phase | What Happened |
|------|-------|---------------|
| 07:01 | Foundation | First script, skill creation |
| 07:26 | GitHub + Sal | Repo created, Sal researched, patent analyzed |
| 07:42 | All Apps | 64 launchers, automation atlas |
| 07:50 | Whiteboards | 14 visual boards generated |
| 07:55 | sdef Extraction | 31 apps, 347 commands, 408 classes |
| 08:01 | Public/Private | .gitignore, 167 files pushed |
| 08:05 | Deep Dive | 20 more whiteboards |
| 08:13 | Final | Skill v2.0.0, replay saved |

**Total time: ~75 minutes.**

---

## The Philosophy

This repo exists because of a simple belief, borrowed from **Sal Soghoian**:

> *"The power of the computer should reside in the hands of the one using it."*

Every script here is one button press away from making that real.

---

*Built with [Claude Code](https://claude.ai/claude-code) in a single conversation.*
