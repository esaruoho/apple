# MacVoices #17148 — Ken Case & Sal Soghoian discuss Omni Automation (AltConf 2017)

**Speakers:** Chuck Joiner (MacVoices host) + Ken Case (Omni Group CEO) + Sal Soghoian
**Length:** ~10 minutes (146-line transcript)
**Context:** MacVoices recorded at AltConf, running alongside WWDC 2017 in San Jose. Chuck's "first AllstarAllstar interview" of the show. **Eight months after Sal's October 2016 elimination from Apple, and the same AltConf trip as the Mac Observer / Jeff Gamet interview** in this corpus.
**Audit attestation:** every quoted phrase below verified verbatim by direct read of transcript.txt by Esa's auditor on 2026-05-11.

## The historical position

This is a **three-way** post-Apple Sal conversation. Where the Mac Observer interview is Sal-solo describing Omni Automation, here Ken Case provides the **vendor-side framing** — the CEO of Omni Group on what shipping a user-automation architecture means commercially. Sal is no longer the lone evangelist; he is introduced as a co-conspirator who has *been adopted* by another company's roadmap.

Ken's punchline lands the structural fact:

> *"Ken's going to adopt me. My last name's going to become Case."*

The line is a joke; the structural fact is real. Apple let Sal go; Omni picked him up; Omni Automation is the product of that pickup.

## Sal's framing — empowerment that crosses the Mac/iOS divide

> *"I've been in automation quite a long time. And the thing that really Thrills me about what the Omni Group is doing with Omni Automation is the fact that I can write a script that is productive for me on the Mac and that same script is going to be productive for me on my iOS device."*

The cross-platform thesis is the headline (same as the Mac Observer interview), but here Sal extends it past scripts to **data location**:

> *"It is also opened up the ability to be able to store information and and tools in other places beside in the application for example the I can store script in a web and have it interface with data from the webpage that I can then use in my Omni applications document so a mere tap on a table in a web page can suddenly heat map a graphic in my document."*

**Same OmniGraffle US-states heat-map demo as the Mac Observer interview** — but here Sal generalises it: scripts can live *anywhere* (web pages, plug-ins, documents) and reach into the app. The script is no longer bound to the application's resource folder.

## Ken's framing — performance as a marketing surface

> *"One of the interesting things about it being built on top of Apple's JavaScript Core is that it is also really highly tuned for performance. So it is blazingly fast, the automation scripting that we're doing. You know, we've been doing Automation in our apps with AppleScript since early OS X, but the difference in performance of these scripts versus the AppleScripts that were happening before is just night and day."*

This is the **CEO's case for the technology choice** — JavaScriptCore over AppleScript on performance grounds. Sal piles on:

> *"You can create 40 objects in a microsecond. You don't even see the separate objects being created. It's just a blur."*

Together this gives the canonical Omni rationale: **same architecture as JXA (2014 #306), but executed by JavaScriptCore-on-WebKit instead of OSA**, with order-of-magnitude speed gains over AppleScript. Sal's Apple-era architecture continued at a third party, faster.

## The HTML extraction pattern — "you don't have to do anything special"

> *"You can use standard HTML practices to extract the data out of a table. You don't have to do anything special. That's standard routines that will convert the contents of a table on a web page into a Json object."*

This is the **pre-built integration** WWSD principle Sal has shipped since Mac OS X 10.0:
- Tables → JSON via standard DOM iteration
- JSON → script via JavaScript `replace` on a placeholder
- Script → app via the Omni Automation URL

No custom parser. No new file format. Standard web tech reused as automation glue. **WWSD #5 (use what's already there) operationalised on the web stack.**

## Plug-in distribution — "tap a link or double-click a file"

> *"The user could just tap a link on a page or double-click a file to install that and make that part of their Omni environment."*

> *"They can go to somebody that they trust, install this plug-in, and then have a whole set of tools that can affect what they're doing, but they don't need to write the automation themselves."*

The **plug-in-via-URL distribution model**, same as the Mac Observer interview, but with the trust framing made explicit: the user picks a **trusted author**, not a trusted file. The unit of trust is human, not technical.

This maps cleanly onto Sal's 2003 QuickTime-scripts collection on apple.com/applescript — Sal-as-trusted-author distributing ~150 scripts to ordinary users. Same pattern, 14 years later, just the delivery mechanism changed.

## The "no install" extreme — script on a web page, no installation required

> *"I'm a person that likes sharing the automation tools that I create because I get a joy from people responding and saying, you know, that really changed my life. I was able to save an hour every day and spend that time elsewhere. So they've developed the architecture in a way where I can put that Omni-automation tool in a web page and make it a button that you can click and it will affect your document and you don't have to install anything."*

**This is the strongest "frictionless distribution" quote in the post-Apple Sal corpus to date.** Tap the button → script runs → app changes. No download. No install. No menu. No file in a folder. The web page IS the automation.

> *"That's an option and flexibility that I've never seen in any automation language or functionality nobody's ever done anything that has this depth but this much flexibility at the same time."*

Sal explicitly stating this is **the most flexible automation architecture he has seen** — a remarkable claim from the person who shipped AppleScript, Automator, services, dictation commands, JXA, and Workflow integrations. Worth taking seriously, not just as marketing.

## Ken on Sal's hire — "within an hour"

> *"This project started about two years ago, and we've been working at it very hard for all of that time. But when we heard that Sal was available to work with us on this, that was, well, I guess within an hour, I was talking with him."*

**Two years ago = mid-2015.** Omni was already building Omni Automation a full year before Apple eliminated Sal. The collaboration arc:
- 2015: Omni starts Omni Automation internally
- Oct 2016: Apple eliminates Sal
- Oct-Nov 2016: Ken calls Sal within an hour of news breaking
- June 2017: AltConf announcement, the conversation above

This timeline matters for the apple repo's Sal-post-Apple lineage doc.

## Sal on why Omni — pre-existing Apple connection

> *"As a matter of fact, Apple had a lot of tools that I helped develop that we used internally to automate processes that were based on Omni applications like OmniPlan."*

**Apple internally used OmniPlan** — and Sal built automation tools around it while he was at Apple. The Omni relationship was already operational inside Apple Cupertino; the post-Apple work is a continuation, not a pivot.

## Sal-voice signature quotes

> *"Now the throngs of fans are about to engulf us all."* (Chuck's closer)

> *"I get a joy from people responding and saying, you know, that really changed my life."*

The joy-of-author signature — WWSD #1 (democratization) experienced from the author's side, not the user's side. Sal explicitly states the **motivational loop**: build → share → user reports impact → joy → build again.

## WWSD-relevant takeaways

- **WWSD #1 (democratization) given its motivational engine.** "I get a joy from people responding... that really changed my life. I was able to save an hour every day." The democratization principle is grounded in author-feedback joy, not abstract principle.
- **WWSD #5 (use what's already there) confirmed for the web stack.** "You can use standard HTML practices... You don't have to do anything special." Sal explicitly rejecting custom-parser / custom-format paths.
- **WWSD #20 (institution is not the relationship) gets a vendor-side confirmation.** Ken Case publicly stating he called Sal "within an hour" of Sal becoming available. The institution (Apple) is gone; the relationships persist enough that a CEO calls within 60 minutes.
- **WWSD #43 (one verb per action) reinforced via "tap a link."** The plug-in distribution model collapses the install + invoke pipeline into one human action: tap.

## CANDIDATE WWSD #46 — *"The unit of trust is the human, not the file"*

**Source quote:**
> *"They can go to somebody that they trust, install this plug-in, and then have a whole set of tools that can affect what they're doing, but they don't need to write the automation themselves."*

**Rationale:** Across Sal's career — 2003 QuickTime scripts on apple.com, dictation commands at DictationCommands.com, Omni Automation plug-ins, hundreds of scripts at macosxautomation.com — the **author identity is the security model**. Users don't read the code. They trust Sal, or trust someone-who-trusts-Sal. This is structurally different from app-store-style code review or sandbox-style technical containment. It is a human-web-of-trust model that Sal has operated for 25+ years and that Omni Automation made explicit policy.

**How to apply:** When designing a Hey Sal v2 or Loupedeck script distribution channel for the apple repo, do NOT design code-review/sandbox first. Design **author identity** first — git committer, signed identity, author URL — and let trust transit through the author, not the code.

## Reusable for the apple repo

- **Omni-automation.com mirror under `sources/sal/omni-automation/`** — already flagged from the Mac Observer interview; reaffirmed here as primary-source Sal post-Apple work.
- **The "two years ago" timeline (mid-2015 Omni Automation start) belongs in `analysis/sal/post-apple-timeline.md`.** Adjust the Sal-post-Apple lineage to reflect that the Omni collaboration is **older** than the Apple firing.
- **Apple-internally-used-OmniPlan finding worth its own line.** Apple's internal use of third-party automation-friendly software is a rarely-documented data point about how Sal's group actually operated inside Cupertino.
- **The "web page IS the automation" pattern is portable.** A Loupedeck button could open a webpage containing 32 buttons, each a Vocal-Shortcuts-style URL trigger. The user never installs anything new; they bookmark a page. This is a Hey Sal v2 distribution channel waiting to be built.
- **Trust-in-author pattern → git-signed apple-workflows distribution.** If apple-workflows is a public distribution channel, gpg-sign commits and surface the author identity in the install path (e.g. `bin/install-from-trusted-author --author esaruoho`).

## Audit footer — verbatim quote verification

All quotes verified by direct character match against transcript.txt:

| Quote | Line(s) |
|-------|---------|
| *"Ken's going to adopt me. My last name's going to become Case."* | 108-109 |
| *"I've been in automation quite a long time..."* | 30-33 |
| *"It is also opened up the ability to be able to store information..."* | 34-39 |
| *"One of the interesting things about it being built on top of Apple's JavaScript Core..."* | 59-63 |
| *"You can create 40 objects in a microsecond..."* | 64-65 |
| *"You can use standard HTML practices..."* | 48-50 |
| *"The user could just tap a link on a page or double-click a file to install that..."* | 78-80 |
| *"They can go to somebody that they trust, install this plug-in..."* | 83 |
| *"I'm a person that likes sharing the automation tools..."* | 88-96 |
| *"That's an option and flexibility that I've never seen in any automation language..."* | 101-104 |
| *"This project started about two years ago..."* | 111-114 |
| *"As a matter of fact, Apple had a lot of tools that I helped develop..."* | 122 |
| *"Now the throngs of fans are about to engulf us all"* | 139 |
| *"I get a joy from people responding..."* | 90-92 |

No paraphrasing in quote marks. The interpretive layering (post-Apple timeline, trust-in-author candidate, web-page-as-distribution) is mine, layered over verified-real lines.

## Whisper proper-noun confidence flags

- **"Chuck Joyner" (line 6, 140)** — actual host name is **Chuck Joiner** (MacVoices.com). Whisper consistently mishears the surname. Flag for corpus-wide replacement.
- **"Sal Seguyan" (line 13)** — mishearing of **Sal Soghoian**. Standard corpus-level Whisper issue.
- **"AllstarAllstar"** (line 7) — Whisper duplication of "All-Star All-Star" or "All-Star". Cosmetic.
- **"anomaly outliner"** (line 72) — Whisper mishearing of "Omni Outliner". Cosmetic, content clear from context.
- **"Json"** (line 50) and **"Tip a link"** (line 86) — minor Whisper capitalization / homophone errors. Cosmetic.
- **"Kim brings up"** (line 88) — should be **"Ken brings up"**. Whisper mishearing of Ken → Kim. Cosmetic; context disambiguates.
