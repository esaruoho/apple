# WWDC 2005 Session 138 — AppleScript for C, C++, and Java Programmers (Analysis)

**Speaker:** Sal Soghoian (solo; AppleScript + Automator product manager)
**Year:** 2005 (Tiger shipping, Automator in field for ~1 year)
**Source:** https://nonstrict.eu/wwdcindex/wwdc2005/138/
**Note:** Whisper transcript; expect proper-noun and homophone artifacts ("Sal Segoyan", "South Segoia", "Cheryl" credited for the path-to-folder rename, "Apps Script" = AppleScript-compatible Python OSA).

## Sal's framing — demystification, not conversion

> *"There's been a lot of interest from programmers in using AppleScript, maybe not full-time, maybe just an occasional script. And it's always been very daunting and challenging for programmers to use this language. They're very frustrated by it… maybe a session on AppleScript for programmers, people that already know how to program, people already know how to use code, people already know how to make money doing what they do, but occasionally want to use AppleScript and would like it demystified for them."*

This is Sal's **audience-broadening** session — and it's deliberately not a conversion pitch. The framing is **complement, not replacement**: AppleScript as the *occasional* tool a compiled-language programmer reaches for when they want to control iTunes, script the Finder, or wire applications together. Sal's signature self-deprecation runs through the whole talk: *"It's the duct tape role that covers the entire computer"*, *"If you're a Perl person, buy Maalox by the gallon."* The pitch is: this language is funky, the funk is intentional, and once demystified it's a money-shaped tool.

## What Sal covers (the substance)

### 1. The economic argument (planted early)

> *"80% of Apple's top-tier customers use AppleScript… that's a rack of Xserves running different applications, all controlled with AppleScript. This is a money situation. AppleScript's really a money technology. There are a lot of major corporations that you know about that build their business using this language."*

7,000 print publication jobs daily on a rack of Xserves controlled by AppleScript. Sal's framing for the programmer audience: **don't dismiss this as a toy** — it's running production pipelines at scale. WWSD #33 (the four whys: consistency / accuracy / speed / scale) is the latent answer to *why this rack exists*.

### 2. The English-like syntax pitch — and its honest cost

> *"Move the green car before the red car. That's something I would say. Get the name of every student whose graduation comes after June 1st… AppleScript was designed to mimic this kind of a syntax. So the goal being that someone could just think of what they want to do, and the actual code would be what they just thought. Of course, it didn't count on TV dumbing down America so that we can't speak anymore, but that's the basic principle of what's going on."*

Sal shows side-by-side Python (Apps Script OSA) vs AppleScript for the same operation — `tell application Finder to get the name of every folder of home` — and admits the **180-degree shift in thinking** the language demands. The pitch is honest: *"this is a little bit of a challenging, but we're gonna spend some time looking at the syntax so that you can understand why it's this way and how you can momentarily escape reality and let your mind drift and write a line of AppleScript and then come back into writing some structured code again."*

The honesty matters. Sal isn't claiming AppleScript is easier than C — he's claiming it's **closer to the spoken description of the task**, which makes it durable: *"customers like it… because they can go back into their scripts months later and actually read the script and figure out what it does."* That's WWSD #33's *consistency* through the user-readability lens.

### 3. The tell-statement as the unit of automation

Sal builds the whole syntax tour around one structural claim: **a tell statement always contains two things — a reference to the object and the action to perform.** Variations:

- `tell application QuickTime Player to tell the front movie to tell the last track to get its duration`
- `tell application QuickTime Player to get the duration of the last track of the front movie`

Same operation, two readings. *"Any way you want to put these two things together… you're fine. Any way that you want to write it is fine indeed. It will work. And if AppleScript works, it's right. There is no right way to do something. It's no right way to make money. Well, maybe there is, okay."*

Then **tell blocks** (open/close, statements between), **nested tell blocks** (inner block walks deeper into the object hierarchy), and the cleanup move: replace chained `tell application Finder to tell home to tell folder documents to tell…enta enta enta` with a single outer tell + an inner tell that names the deep object path directly.

### 4. The "clean and wax" verb-set

Sal's signature phrase across every WWDC appearance, planted hard here:

> *"It cleans and waxes in one motion. It's very nice. It not only finds and it does at the same time. Finds, does. Finds, does. The power of AppleScript."*

Example: `tell application Finder to duplicate every document file of the entire contents of folder documents of home whose name contains "Smith project" to the disk named backup`. **One line** = find + iterate + copy. WWSD #36 (clean-and-waxing) and **#37 entire-contents recursion** both ship here in their primary-source form. *"All of that done with one line of AppleScript… all of your iterations and recursive routine for you all in one statement."*

### 5. The path-reference hellscape (and the lifesavers)

The longest section of the talk. Sal walks five reference types: **nested**, **path**, **alias**, **POSIX**, **file URL** — and admits up front: *"this is some of the stuff that really gets people that aren't familiar with AppleScript… for right now, this is your new nightmare. Path references, I should be more salesman on this."*

The pragmatic out: `POSIX path of <alias>` and `<posix-string> as POSIX file [as alias]` as the two converters. *"You can build little subroutines with those, and it becomes just an easy thing to do back and forth. Eventually, we hope to make it so that you won't have to worry about any of this stuff, but for right now, I want to give you guys the truth and the good stuff."* The 2005 honesty about path types is candor in service of the audience — programmers respect honesty about API jank more than they respect a sales pitch.

### 6. Finding things — the by-property query

The pitch turns confident here. **AppleScript queries** combine: positional indicator + target object type + target container + object specifier + target property + comparison operator + value. Live examples:

- `the first document file of home whose name contains "Smith"`
- `every document file of folder pictures whose file type is "JPEG" or name extension is in {…}, and name contains "Smith project"`
- `every document file of the entire contents of folder documents of home whose name contains "Smith Project"`

Sal: *"Using these kind of queries with AppleScript, you can really locate things to work with very easily in a single line. Instead of iterating and do four repeat loops and stuff like that, you just use one line."* The pitch to programmers is **predicate-as-control-flow** — AppleScript's `whose`-clauses are an early SQL-WHERE inside an imperative shell, two decades before NSPredicate became fashionable in Swift.

### 7. Special folders + info-tools + repeat/conditional/error handlers

Closing third is the cleanup pass: `path to documents folder`, `path to library folder from user domain`, `info for <alias>`, `system info` (Tiger). Then conditionals (single-line `if … then`, multi-line `if … else if … else … end if`), repeat loops (`repeat <n> times`, `repeat while`, `repeat until`, `repeat with i from 1 to count`, `repeat with x in list`), and the **try/on error** block with `number errorNumber` parameter trapping (`-128` = user cancel) — the same template every Sal-grade AppleScript still uses in 2026.

The famous *"this should just work" trap* — `repeat with x in list` returns **references**, not values; `set end of foundList to contents of x` is the fix. *"I can't tell you how many programmers have pounded their head on that going, 'This should just work. It should just work.' Now you know the answer."*

## WWSD-relevant takeaways

- **#1 democratization** — phrased here in the *programmer-complement* register: AppleScript exists so the non-programmer can do what the programmer does, but also so the programmer can stop writing a 200-line Cocoa app when one line of AppleScript would suffice.
- **#33 four whys** — *"80% of Apple's top-tier customers use AppleScript"* + the 7,000-jobs-daily Xserve rack = primary-source for the *scale* and *speed* legs.
- **#34 vision-stability since 1992** — *"AppleScript was originally designed back in 1992 to be that way."* Direct primary-source confirmation of the 1992 anchor date.
- **#36 cleaning-and-waxing** — *"Finds, does. Finds, does. The power of AppleScript."* Primary source for the cleaning-and-waxing principle. Codify the *exact* quote in the WWSD canon.
- **#37 entire-contents recursion** — `entire contents of folder documents of home whose name contains "Smith project"` does the recursive walk *as part of the query*. Primary source. The whole expression-as-control-flow idea belongs to this session.
- **Candidate principle: query-as-control-flow** — predicate clauses (`whose`, `where`) collapse `for + if + collect` into one expression. Worth a named WWSD addition: **#41 — predicate replaces iteration where possible**. Same logical principle as Renoise's `instrument:find` or BBS's vault-search-by-tag.
- **Sal-voice catalog** — *"duct tape role"*, *"a dinosaur looking for a tar pit"*, *"buy Maalox by the gallon"*, *"momentarily escape reality and let your mind drift and write a line of AppleScript and then come back into writing some structured code again"*. The dinosaur/tar-pit and Maalox lines are signature.

## Reusable for the apple repo

- **`bin/applescript-cheat-sheet.py`** — a generator that emits the 5-reference-types cheat sheet (nested / path / alias / POSIX / file-URL) + the canonical converters (`POSIX path of …`, `… as POSIX file as alias`). Sal's nightmare table belongs as a one-screen reference in `bash-aliases.md` or as a Spotlight-searchable `.app`.
- **Predicate-as-control-flow port to Renoise/Paketti** — Renoise Lua already supports `for instr in song().instruments` but lacks the `whose` filter at the language level. A Paketti helper like `find_samples(predicate)` that takes an inline filter closure is the same WWSD-#41 move.
- **The `entire contents` recursion idiom** is the AppleScript ancestor of `find . -type f`. Worth calling it out in `scripts/workflows/` as a teaching comment: AppleScript was doing one-line recursive predicate walks **eight years before** `find` got `-iregex` in macOS.
- **try/on-error template** — every osascript-emitting tool in `bin/` should wrap its generated script with the `on error errMsg number errNum` template Sal teaches here. The `-128` cancel-check is a one-line UX upgrade.
- **`whose`-clause inventory in 31 sdefs** — `bin/sdef-extract.py` could grow a `--predicates` mode that lists every class supporting `whose` filters across the 31 captured dictionaries. That's the 2026 inventory of *which Apple apps still support query-as-control-flow* vs which lost it (the post-XPC Music app, notably).
- **Tone for `painpoints/` write-ups** — Sal's *"this is your new nightmare… I want to give you guys the truth and the good stuff"* is the right register. Honest about jank, generous with workarounds. Adopt as house-style for `painpoints/`.
