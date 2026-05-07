---
title: Sal Soghoian Transcript Analysis — Pass 2 (Standing Up To Jobs, MacVoices CMDdConf, ProGuide 067, MacWorld 2012)
sources:
  - sources/sal/transcripts/youtube/2026-05-06_sal-soghoian-standing-up-to-steve-jobs/transcript.txt
  - sources/sal/transcripts/youtube/2026-05-07_macvoices-17175-sal-soghoian-on-automation-and-the-cmd-d-conference/transcript.txt
  - sources/sal/transcripts/youtube/2026-05-07_proguide-episode-067-apple-s-dean-of-automation-sal-soghoian/transcript.txt
  - sources/sal/transcripts/youtube/2026-05-07_sal-soghoian-interview/transcript.txt
extracted: 2026-05-07
purpose: Pass 2 of Sal-transcript deep analysis — extracts new stories, methods, names, and mechanisms not present in TWiT 2018 / MTC2019.
related: analysis/sal/transcripts-analysis.md
---

# Sal Soghoian Transcripts — Pass 2 Deep Analysis

Four more primary-source talks. Reading order by depth:

1. **ProGuide Episode 067** (Andrew J. Mason, 2023-08-25, ~57 min, 501 lines) — the deepest interview yet. Full pre-Apple biography, dozens of inside-Apple operational stories (code bounties, Lego payments, Steve emails, Siri prototype), then Sal's philosophical framework (Observer/Participant + Forward Motion).
2. **Standing Up To Steve Jobs** (TWiT, 2018-08-11, ~7.7 min, 132 lines) — the full Town Hall confrontation story expanded, with names of the other 1997 product managers.
3. **MacVoices #17175** (Chuck Joyner, 2017-08-02, ~31 min, 304 lines) — promoting Command-D conference. Carpenter-father origin of "underlying principle" method, Omni JavaScript automation thesis, Steve Jobs's trucks-vs-cars updated to "transportation/teleporting."
4. **TWiT MacWorld interview** (Leo Laporte, 2012-01-30, ~2.6 min, 59 lines) — short biographical color: Berklee 1974-79 grad, MIDI guitar performer, wife Naomi.

Total new spoken-Sal content: ~98 min. **Combined with Pass 1, the corpus is ~155 min of Sal in his own voice.**

---

## ProGuide 067 — The Deepest Single Sal Interview

This interview, conducted in 2023 (seven years after his Apple firing, two years before the Wired profile), is the most operationally detailed account Sal has given. It splits into five movements: pre-Apple biography → recruitment → inside-Apple political mechanics → Steve Jobs relationship → post-Steve drift + philosophical frame.

### Story 1 — The Delaware Water Gap pre-history

> "I used to live in a music community, an arts community in Pennsylvania called Delaware Water Gap. That's the actual name of the town because you're right on the Delaware River where the gap is coming in between the mountains, and it's in the Poconos. And it's a very famous arts and music community. And I was living over a bar in there."

New facts not in any other transcript:
- **Delaware Water Gap, PA** — Sal's pre-AppleScript location
- **Lived above a bar** in town
- **Bought a used Mac** to teach himself
- **Self-taught ReadySetGo** (the page-layout app that was either ReadySetGo or PageMaker before Quark)

### Story 2 — The Greek Diner, the video shop, the bar

The first paying-design-work story. Once he got good at ReadySetGo and produced menus for the bar he lived above:

> "The next thing I know, the other businesses around town beside the bar I was living at started to ask me, can you do my thing over again? You know, the little video shop and the diner, the Greek diner down the street."

This is a primary-source mini-story about how Sal's "I should automate this" instinct first appeared as a service business. It's the seed of his entire later approach: someone has a manual layout problem; Sal makes it easier.

### Story 3 — Charlottesville and Joe Gibson

> "I moved to Charlottesville, Virginia, where I had lived before — I had gone to the University of Virginia at one time. And I got a job in a print service bureau with this lady, Joe Gibson. She had been in the print industry for 29, 30 years and she taught me all the real stuff."

New facts:
- **Sal attended University of Virginia** (briefly — "at one time")
- **Joe Gibson, female print-industry veteran (29-30 years)** — Sal's real teacher in print fundamentals (line letting, etc.)
- **Linotronic in the shop** — image-setter for high-quality output
- **Quark XTension developers were already collaborating with Sal pre-AppleScript** ("I was working with developers of Quark extensions and coming up with these ideas and testing them for them")

### Story 4 — The $14 floppy (correction)

In the WIRED article and TWiT 2018 the figure was $15. In ProGuide Sal says:

> "I paid the fourteen dollars to get a 400K disk with the scriptable Finder on it from Apple."

**$14, not $15.** TWiT/WIRED rounded or Sal's memory differs across tellings. Either way: a small, decisive purchase.

### Story 5 — The Quark Express dictionary lineage

> "Quark Express was one of the apps we were using in publishing and it was scriptable because Dave Dave and Ralph Rich had worked with Tim Gill and put the dictionary in there."

Names confirmed across both ProGuide and TWiT 2018:
- **Dave Shaver** (or "Dave Dave" — likely whisper artifact for "Dave Shaver")
- **Ralph Risch**
- **Tim Gill** — founder of Quark
This is the technical lineage of the first dictionary Sal read.

### Story 6 — Real estate magazines: 20-second page layout

The first scaled automation Sal built:

> "First thing I started doing was trying to figure out how to automate real estate publications because in the grocery stores they had these magazines with house description, house description, house description. And I'm looking at it going, well, that could just be a record in a FileMaker Pro database, and then this is a box. So all I have to do is figure out some way to relate that box to this. Well, I could use the MLS number… I figured out how to write an AppleScript to get the information from the database into the box and format it… **I was able to do an entire page layout in 20 seconds and it was accurate, it wasn't any mistakes.**"

Mechanism: tag the QuarkXPress boxes with MLS numbers, store house data in FileMaker Pro keyed by MLS, AppleScript joins the two and lays out the page. Then Sal escalated to **scanned image automation** (no manual halftones), then **3-color split electronic separation** for a county-wide real estate group's full-color cover.

WWSD implication: the very first scaled automation Sal built was *eliminating the manual page-layout job entirely* — a self-undercutting move from someone who was making his living doing exactly that work for clients. Sal's instinct was always to **automate the work he himself was paid to do**, even at the cost of his own billable hours.

### Story 7 — The AT&T $3,000 script (10 minutes of work)

> "I got contacted by AT&T. AT&T says, can you write us a script? We got 40-page documents and we have to find every occurrence of AT&T. It has to be this blue, it has to be this font, turn this way with this. And I said, no problem. **That'll be three thousand bucks. And you know I'll write it in 10 minutes and then sit on it for a week before I send it to him to make them think I worked on it.**"

This is the most candid pricing-story Sal has on tape. The economic asymmetry is the whole point: the *value* is the corrected document; the *time* to produce it is 10 minutes once you know how. He sat on the deliverable for a week so the client wouldn't feel cheated. **WWSD: bill on outcome, not on hours. Don't let speed devalue the work.**

### Story 8 — Better Homes and Gardens recipe fractions

> "I wrote the script for Better Homes and Gardens that did the fractions for their recipes."

This is the same script mentioned in WIRED 2018 (and in Sal's published bio) — but ProGuide gives it as one item in a longer list of paid commercial scripts, framing it as part of the *reputation-building portfolio*, not a hobby project.

### Story 9 — The "kill the baby" recruitment threat

This is the most dramatic recruitment story Sal has told:

> "Apple… they came to me and they said, we want you to join. And I go, well, why would I want to do that? You know, you're asking me to take a 50% pay cut to join you. **And they basically threatened to kill the baby, right? They said, well, AppleScript's gonna die unless you come here.**"

Apple's pitch wasn't "we want your skills." It was: **without you, the technology you love will die.** That's a hostage-negotiation pitch, and Sal recognized it as such ("they basically threatened to kill the baby"). He still joined.

WWSD implication: the technology you have a profound emotional connection to can become leverage against you. Sal joined Apple knowing he was being emotionally manipulated, because the manipulation was *true* — AppleScript would have died without him.

### Story 10 — The "Poseidon Adventure" of January 1997

> "I joined Apple in January of '97 as the AppleScript product manager. And at that time, it was like the Poseidon Adventure — you know, where the columns were falling down and Shelley Winters was doing the breaststroke through the hallway. It was insanity, it was really crazy. **But that was the best possible thing for me because it meant that all the barriers were down and we could actually take a vision and move forward with it.**"

This is the strategic insight in the chaos: when an organization is in collapse, the political-overhead layer that prevents work from happening also collapses. Sal walked into a structural vacuum that made his job — political stewardship of a fragile technology — *easier*, not harder.

WWSD implication: **organizational collapse is opportunity for marginal projects.** When the leadership is fighting fires, you can move things that would never have cleared the gates in normal times.

### Story 11 — AppleScript briefly under the ColorSync product manager

Buried in the ProGuide narrative is a stunning org-chart artifact:

> "At one time AppleScript was put under ColorSync. They didn't know what to do with it, so they assigned — I reported to the ColorSync product manager. It was like, what?"

A scripting language reporting to a *color-management* product manager because nobody knew what bucket it belonged in. This is the absolute political nadir for AppleScript inside Apple. Sal rode it out.

### Story 12 — "Lost them all in one day"

> "Then there was massive shake-ups, and one day I lost my boss's boss, my boss, my companion, my peers — lost them all in one day. It was just like total clear-house. And I was left, and people were coming to me with their projects saying, can you keep this alive? And give me the source code for their projects — like Data Detectors, you know, they gave me their stuff trying to keep it alive."

Sal as the **last-man-standing custodian of orphaned automation projects**. Engineers literally handed him source code as they were laid off, hoping he could shepherd it through. **Data Detectors** is named explicitly — the source-code-for-safekeeping pattern.

### Story 13 — Code kidnapping (Espinoza + QuickTime PM)

> "Chris Espinoza, Apple employee number eight, was my engineering counterpart. He and the QuickTime product manager at the time **kidnapped the code base** and basically took it off the server and had it. And they brought me on board to protect it. And he made a deal with Steve Glass to get AppleScript to become part of the operating system so we could be protected. But at the cost we had to give up our autonomy."

Mechanism: Espinoza + the QuickTime PM **physically removed the AppleScript codebase from Apple's servers** to protect it from being killed. The deal with Steve Glass (NB: probably **Bertrand Serlet** or "Steve Glass" is a Whisper artifact for someone else — verify) brought it into the OS, but at the cost of AppleScript's revision-cycle independence.

WWSD implication: when bureaucracy threatens a technology, **physical removal of the artifact** can be a legitimate stewardship move. (Compare: the Sal archive recovery work in this repo. Same principle — remove the artifact from a system that won't preserve it, hold it elsewhere.)

### Story 14 — The Patton email at midnight

The cleanest origin story for the AppleScript-becomes-development-language move:

> "I had a friend that was vice president over in marketing. He had ridden in the plane with Steve from New York from a Macworld, and he told me about the conversations they had. He told me Steve's favorite movie. He said, **Steve's favorite movie is Patton.** I won't believe it, but it's *Patton.* And I went, well, it kind of makes sense. And I came from a military family so I know how to speak military. So I wrote Steve an email. I said, Steve, look, I'm just a sergeant. I'll do what you tell me. I'll go where you want me to go. I'll fight the fight. But you got me out here in the middle of nowhere with no supply line. How am I supposed to take it to Microsoft if I don't have the stuff that I need to get ahead? And I sent it off to him. It was like the middle of the night, you know, like midnight."

The next morning:

> "I get a call from Espinoza going, what did you do? I said, what do you mean? He goes, what did you do? We got a meeting today with Avi and Phil."

Outcome of the meeting with **Avi Tevanian and Phil Schiller**:

> "Espinosa says, no, we want to be part of Project Builder and Interface Builder. And Avi had been sitting there kind of like, I gotta do this, and went, oh, I can understand that. He goes, yeah, we want to be a peer development language. They went, hmm, okay. What do you need? Espinoza goes, one engineer. He goes, what? He goes, we need **Tim Bumgarner**. **And it was this brilliant man who could architect the thing. And he goes, you got him. And that changed everything because then we became a development language. We could actually make an app out of AppleScript using Aqua and everything else.**"

WWSD implication: **Speak the receiver's language.** Sal didn't write Steve a logical case for AppleScript. He wrote a *Patton-themed* military-metaphor letter at midnight because he knew Steve's favorite movie. That email got AppleScript Objective-C, Tim Bumgarner, and integration into Project Builder / Interface Builder — i.e., the entire developer-grade scripting story that defined the next decade.

### Story 15 — Code bounties in the elevator

> "I became notorious for certain kind of things. Like I was famous for putting bounties on code. **I would put a bounty up in the elevator: $1,200, for somebody that can write me code that does blah.** Like the QuickTime Player to get that scriptable was a bounty in the elevator and Building 2. And about 30 minutes I got a couple of calls from guys: are this serious? I said, yeah, I'll give you 1,200 in cash."

Then once he had the bounty-funded code:

> "Strip it, take out your identifiers, your job numbers, everything. Just give me the code. And then once I had that, [it was] figuring out how to get it in — making a deal with somebody else to put this in here or install it into there."

### Story 16 — The `do shell script` purchase

> "There was a guy I bought the code for [`do shell script`] from. And it took me a while to figure out how to get it into the operating system. But it got slid into a build, and once it was in there, it became used by everybody. And it's still like one of the most number-one used things. **But it was basically a bounty I paid some engineer.**"

The single most-used AppleScript command — `do shell script` — entered macOS via **Sal personally paying an engineer for the code and smuggling it into a build.** Not via a feature spec, a roadmap meeting, or an OKR. A side-channel cash transaction in an elevator.

### Story 17 — The Lego Millennium Falcon payments

> "Then there were certain guys that wouldn't accept money. So I used Legos. The famous Star Wars Millennium Falcon. **I used to buy the Millennium Falcon kits and I would come into an engineer and put it on his desk.** And they'd look at it like, oh, this is something that they can't justify their wife spending $500 on a Millennium Falcon kit. But you know, it's like — you just give me the code, I'll take care of the rest of it."

The economic insight: some engineers wouldn't take cash (legal/ethical/expense-reporting reasons). But a $500 Lego Millennium Falcon was something they *wanted* but couldn't justify buying themselves. Sal weaponized **the spousal-veto problem** as a payment vector. Genius and slightly horrifying — perfectly Sal.

WWSD implication: **align the payment to what the recipient cannot otherwise obtain.** Cash is fungible and refusable; targeted in-kind transfers are uniquely valuable to the specific recipient.

### Story 18 — The Yvonne Christic security resolution

> "We had to work with the security guys, Yvonne Christic's team. Two diametrically opposed philosophies — automation wants everything wide open, and the security team wants everything tight. And those guys are so brilliant and their attitude was constantly, how do we make this work? **And we figured out this whole concept that's still in use today: that if the user installs this at a certain place, the operating system will run your scripts. And the act of the user installing it means that the user wants us to have power. The application can't install it, but the application can ask the user to install it.**"

This is the formal mechanism for "user-authorized scripts" — the ScriptingAdditions / Library/Scripts user-installed model. Still in use. **Yvonne Christic's team** named as the security-side counterparty.

WWSD implication: when two principles conflict (open vs. secure), find the **authorization gesture** that lets both be true simultaneously. The user's own act of installation is the authorization.

### Story 19 — The Siri prototype (the most heartbreaking story)

> "I worked with the speech team and then the Siri team came on and I worked with them. And **we actually had the prototyping engine for Siri.** They had this engine based on JavaScript. We had it tied into AppleScript and to Apple events. And we had as a prototype hundreds of commands to control all the iWork apps, Photos, the Finder, everything. **It was all voice and it was natural language. You didn't have to memorize a phrase. It was just — you tell it what you wanted to do and it understood. And we presented this all the way up to the top levels and people were stunned. Literally I gave presentations on this with my partner from the Siri team. The room was silent and then it applause. It was just like knocked the breath out of them.**"

But:

> "It was on the Mac. It wasn't on iOS. And I think that caused problems because they didn't want iOS to look bad — not bad but not as capable. **Right? Yeah.**"

**This is the lost product.** A working Siri-on-Mac prototype with hundreds of natural-language voice commands controlling all Apple's first-party apps was demonstrated to top execs in ~2014-2015, got applause, and was killed because it would have made iOS Siri look weaker by comparison.

Modern context: this is exactly the technology Apple has been struggling to build under "Apple Intelligence" for the last two years. **Sal had a working prototype a decade earlier.** It was killed for cross-platform-marketing reasons.

WWSD implication: **the best demos die for political reasons.** A prototype that earns silent-then-applauding rooms can still be killed if it disrupts a parallel team's narrative. The political question (does this make iOS look weaker?) trumped the technical one (does this work?).

### Story 20 — WWDC session 717, 2016 (the pulled video)

> "I actually gave a talk at WWDC about — I used the standard dictation software as an example. And I showed this whole thing and it upset a lot of people. They actually pulled the session. **It was session 717, 2016, and I gave the session and then they took down the videos like a week later.**"

October 2016 was when Sal's position was eliminated. WWDC 2016 was June 2016. **The pulled session 717 was four months before he was let go.**

This places the firing in a more specific causal context than is publicly documented: Sal pushed too hard on the dictation/automation theme at WWDC 2016, the session was retracted, and a few months later his role was eliminated. It's not "Apple eliminated automation" in a vacuum — there was a specific provocation.

**Action item for the archive:** find session 717 from WWDC 2016 (now scrubbed) — this is a high-value missing artifact. Check Wayback for `developer.apple.com/wwdc/2016/717` and any community mirrors.

### Story 21 — The Viacom / Media 100 setup

> "I had spent like a couple weeks on site at Viacom. They were doing all those promos — those little things that go 'tomorrow on FX channel we have Bob Discovers America.' I wrote a script: it would hack all that up, put them on a thing, figure out what of the 13 channels based on the name, pull the appropriate video background, put it in, create — open up Photoshop and Illustrator, create all the text overlay with an alpha channel, build the entire thing, lay them all out on one line… **They went from 1,800 promos that used to take like weeks with four guys back-to-back to 30 minutes with a bunch of scripts.**"

The Final Cut Pro political move:

> "I was trying to get the Final Cut guys to do this. I couldn't convince the engineers that they needed to spend the time and do it. So I pulled a move on them and Steve, it turned out too. I used to speak at the executive briefing center, and I knew that HBO and a bunch of the guys from New York were showing up. So I asked Viacom, hey, can I show your solution to your competitors? And they're like, okay yeah. I got into the queue of people that were going to show those things. I was the last one. And I showed them. **I said, look at — Viacom said I could show you this. And then all of a sudden everybody's like, what. And then after me was Steve. And the first thing this guy said to him: we want automation. And he didn't know anything. So I basically set him up to get bombarded.**"

Outcome:

> "It turned out, didn't work, you know. Steve said, look — I got to go with the engineering manager. They say they don't have the time and the resources. We're way behind on this. I'm sorry, we can't do this."

WWSD implication: **even Sal's best political moves failed sometimes.** The Viacom-bombardment move was clever and well-targeted, but the engineering manager's "no time / no resources" trumped Steve's interest. **Final Cut Pro never got proper AppleScript support** — and Sal frames this as a loss he carried.

### Story 22 — The Phil Woods / Poconos connection

> "If you take a musician like Phil Woods — when I lived in the Poconos, Phil was a local guy, and amazing musician, just phenomenal. Constantly voted best alto player in the world."

**Phil Woods (1931-2015)** was one of the greatest alto saxophonists in jazz history (Grammy winner, played on Billy Joel's "Just the Way You Are" solo). Sal lived in the Poconos and personally knew him. This is biographical color but also the source of Sal's musical thinking.

### Story 23 — Observer / Participant duality

The philosophical centerpiece of the ProGuide interview:

> "I think that when you use the analogy of left side / right side brain, that's not really what's going on. What's really going on is **there's two different roles that you assume: Observer and Participant.** If we think of it that way, then it's pertinent to everything."

Worked example with Phil Woods playing live:

> "If you take Phil and he's playing in a group, and you could stop — if you could say, Phil, stop, and then ask him: okay, what's going on right now? Phil could tell you everything that he was doing, the arc of where he was going, what's happening, who's playing what over here, what the bass note is, what's the harmony back here. He could tell you exactly everything that was going on at that moment. **But that's the Observer side. At the same time, he was the Participant.** The creative flow of ideas and his response to all of the things that are going on with the rest of the group and his natural inspiration is allowed to come out at the same time. **You assume a role of both Participant and Observer.**"

WWSD #20 candidate: **Observer + Participant, simultaneously.** Sal explicitly rejects the left-brain / right-brain framing — it's not two halves, it's two simultaneous roles. The script-writer is both *running* the automation and *watching* it run, and the value comes from being able to switch roles within a single second.

### Story 24 — Forward Motion and the river

> "I call it Forward Motion. We're constantly moving forward, we can't go backwards. You can't go back in time and correct that bad note. But you can recognize that and develop a tool: okay, **let's think of it this way — I'm in a river that's moving and the current's moving. I can't go back upstream. But I have a paddle. And I can recognize that there's a rock coming up, and I can turn the paddle to get me to move just to the left of it.** Having Forward Motion gives us the ability to adjust, to correct mistakes, to correct deficiencies, to correct defects."

WWSD #21 candidate: **Forward Motion with a paddle.** You can't undo. You can adjust. Observation alone is regret; observation + the paddle is correction.

### Story 25 — Climate, pain, and the inflection moment

> "It's been my experience that if you're a person that requires pain to learn something, [pain] will be provided to you in the amount required. And I'm seeing that principle applied to the world at large — that all of society is now becoming aware. We're getting levels of pain that are making us aware and having to respond. And that means we're going to do fundamental changes."

> "I'm never going to have a need for a sled. When I was a kid, there used to be snow on the ground and you would buy — every kid had like a beat-up sled. And then it stopped snowing. So things are going to change. But I think out of it, it gives us the opportunity to become tighter and more understanding and more empathetic and to figure out solutions together."

Direct climate-change lament + integration into his "pain teaches" framework. Closing: "**we'll figure out how to clump together in that river and keep going.**" The river metaphor returns, now applied to the species, not the individual.

---

## Standing Up To Steve Jobs (TWiT 2018) — The Full Town Hall Story

This 7.7-minute clip is the long-form version of the WIRED article's confrontation anecdote. Key additions to the canonical story:

### The April 13th comparison

Sal turns to Espinoza in the meeting:

> "I said, when was the last time you were in a meeting with Steve? Espinoza is one of the original Mac engineers — he has a brain like a machine. And he goes, oh, it was April 13th. **And I said, so what's the difference? And he goes, they're not trying to get rid of them. Big difference.**"

This is Espinoza's read on the room's tone: **at the April 13th pre-Sal-era meeting, Steve wasn't trying to fire people. By the time of Sal's first meeting, Steve was.** That sharpens Sal's confrontation: he was pushing back inside a room where dismissal was the active default.

### The product-manager bench in 1997

Sal names the small handful of PMs holding Apple together:

- **Sal Soghoian** — AppleScript / Automation
- **Mitchell Weinstock** — QuickTime ("masterful at marketing a technology way beyond just him doing that. He looked like an entire organization of 50 people.")
- **Richard Ford** — Network ("master at running things through the system. He could get them through the system very quickly.")
- **Eric Zelinka** — Mac OS X Server ("took over Mac OS X Server and just turned it from a raw lump of coal into this fantastic thing. He was [the] consummate inside guy.")

> "Being a product manager was — there was only a handful, there was like maybe 10 of us in the company at the time."

**Apple in early 1997 had ~10 product managers total.** That's the org Sal walked into. The four named here are the ones Sal still remembers as effective; the rest didn't survive.

### "People falling off the roof"

> "Steve had started wielding the axe since he got there. I mean, every day you would hear people fall off the roof. It'd be like, ah! Splop! Ah! Splop! All day long. Not literally, but okay. He would work his way through, you know, it was the cluster of buildings."

The most visceral picture of the 1997 layoffs: Sal heard them as "ah! splop!" all day long. **It needed to be done.**

### Sal's read on the test

> "After that, did you know that, or did you see red? What was it that gave you permission to say, Steve, you're wrong? Well, I figured it this way: Apple asked me to join. I might be a dog on my square yard of dirt, but I know every piece of that square yard, and you're on my square yard of dirt and I'm gonna bite your leg off. And I know what I'm talking about. And he was wrong. And you need to hear this. So he went on to something else and then he tested somebody else, and I figured out — **oh, he's testing who he has to work with. And everybody that fought him back stayed and the rest of the people left.** Right? Basically is how it worked. And so after that, he liked me."

The dog-on-square-yard-of-dirt metaphor matches the WIRED article's quote — **same self-framing across two different tellings five years apart.** This is a load-bearing self-narrative, not an off-the-cuff quip.

### Steve as automation ally

> "Steve got automation very quickly. Steve was an ally and an advocate of automation. He didn't necessarily understand all the different details about writing the code and everything, but he understood its importance and its role and why it was necessary for customers to have that option. And while he was there, **we got resources that we needed consistently. He made sure that we had the resources we needed to advance the technology with each system release.**"

This is the strongest Sal-on-tape statement that **Steve Jobs was an active patron of automation.** Not just tolerant — actively allocated resources every release cycle. This is the implied premise of the WIRED article's "his biggest champion at Apple, Steve Jobs, was gone" framing.

---

## MacVoices CMDdConf (2017) — Method, Lineage, Father

### The carpenter father

Sal traces the *method* of automation to his father:

> "I get a lot of my inspiration about automation from my father. My father was a master carpenter, and I learned a lot from him in the way that he could look at something and figure out what the fundamental principle behind it was. **And he imparted in me the concept that if you learn the principle behind something, then you could replicate it everywhere.**"

This is repeated — almost verbatim — in ProGuide 067:

> "One of the things that I've just had as part of my life, I think, was taught to me by my father — was to look for the underlying principle behind something. You see something working and you would look at it and go, why is that doing what it does? Why is it having that effect?"

**Two independent transcripts both source Sal's "underlying principle" method to his carpenter father.** This is the genealogy of Sal's epistemology: cabinetmaking → AppleScript → Automator → APU. The same move at every scale: *identify the principle, replicate it everywhere.*

This is the **single-paragraph sourced answer** to "where does Sal's method come from." It's not from CS, not from MIT, not from Apple. It's from his father, on a shop floor.

### "Square one" teaching philosophy

> "I've always been a firm believer in square one. All the classes I've ever taught, I've always started at square one. And I've found that the people that have more advanced knowledge don't mind having a thorough groundwork laid in a class."

WWSD: **don't gate your teaching by audience level.** Start every class from zero. Advanced learners benefit from grounding; beginners benefit from inclusion.

### The Command-D conference (Aug 8-9, 2017, Santa Clara)

- **Aug 8:** Scripting Bootcamp (Ray Robertson teaching)
- **Aug 9:** Command-D conference itself
- **Speakers:** Andy Ihnatko, Jason Snell, David Sparks, John Pugh, John Welsh, Ray Robertson, Allison Sheridan, Sal Soghoian
- **Sponsors:** Jamf, Omni Group
- **Name origin:** "Command-D for duplicate. It's one of your most fundamental forms of automation. You select a file, Command-D, it's duplicated."
- **Cost:** $399 day pass

### Trucks → Cars → Transportation → Teleporting

Sal updates Steve Jobs's trucks-and-cars metaphor:

> "I don't think it's going to be a matter of trucks and cars. **It's going to be transportation. And right now transportation's not at the point that we want it to be at. When it gets to be teleporting, then we're there.**"

The interviewer says "never heard it expressed that way before." It's a Sal-original framing: the platform debate (Mac vs iPad) is downstream of a more fundamental question — whether the user's *intent* moves directly to the *result* without intermediate friction. Teleporting is the limit case.

### Omni Automation thesis

> "Omni is basing their structures on something that is part of every Apple device, which is WebKit. And within WebKit is core JavaScript. So you take one of the most fundamental automation languages that there is — it's part of the internet and part of everything that we do, and it ships on every Apple device — and you base your object model scripting on top of that for both Mac and iOS. So you write that JavaScript for the Mac and it works the same on iOS."

The architectural insight Sal carried out of Apple: **the universal automation primitive is WebKit/JavaScript, not Apple's own languages.** Because JavaScript ships on every Apple device, OS-portable scripting becomes possible. This is the technical bet Omni made post-Sal-firing, and Sal helped them make it.

### "Automation as knitting"

> "Quite often I'll be sitting there in the TV room with Naomi, and we'll be eating dinner or something, and I'll be putting together a little script. And **it's kind of like knitting.** It's just — it's great to finally solve something and have a nice tool that you can use and share with others when you're done."

**Sal scripts in the evenings, with his wife Naomi, in the TV room, like someone knits.** This is the closest thing on tape to Sal's daily practice. Scripting is not work-time-only — it's a hobbycraft.

### Recognition cue: "There's got to be a better way"

> "Sometimes the biggest challenge of automation is recognizing that something can be automated… **If you find yourself saying 'there's got to be a better way,' that's a definite point toward you need to examine automation. Or if you find yourself going, ugh, I don't want to do this, then that's a sign that you need to automate some process.**"

WWSD operational rule: **two phrases are the trigger.** "There's got to be a better way" and "I don't want to do this." Both signal an automation candidate.

### Apple-internal evangelism: encrypted PDFs with address-book groups

> "While I was at Apple, I used to spend a lot of time in other groups and other departments helping people automate simple processes that they did in the office. And I did that just to make acquaintances and see what other groups were doing… Many times it was something as simple as just automating the process of creating encrypted PDFs with an address book group. And I would constantly get emails from people throughout the year going, **'I just wanted to say one more time, thank you. I've run this script now 4,000 times.'**"

Sal's internal-Apple evangelism strategy: solve *small* problems for other teams as a way to build relationships, not just to pitch big ideas. Encrypted-PDF-from-address-book-group is the *smallest possible useful automation*, and Sal would write it for any team that asked. Then years later he'd get thank-you emails because the script had run 4,000 times.

WWSD: **the thank-you-after-4,000-runs is the metric.** Solve small problems for individual people; let usage compound silently over years.

---

## TWiT MacWorld 2012 — Biographical Color

A 2.6-minute clip. Sal as a guitarist at Macworld, not as Apple staff.

- **Wife:** Naomi (Sal asked Leo to "say hi to Naomi")
- **Berklee College of Music** — graduated 1979, started 1974
- **Peers at Berklee in the 70s:** Kevin Eubanks, Ralph Moore (both became major jazz figures)
- **Scholarship requirement:** "If you had money you were in, whether you could stay or not, that was totally up to you. You had to earn your way."
- **Plays solo MIDI guitar** — was performing Friday at Macworld music studio at 12:30
- **Sal's view of Macworld:** "It's mostly about people at this point. I really agree. I think it's very much about the relationships that we establish among the community with each other."
- **Self-description:** "I'm like a dinosaur looking for a tar pit when it comes to Macworlds."

This is consistent with the MTC2019 closing: **friendship is the institutional asset.** Sal's 2012 view is already that Macworld is about *people*, not products. Eight years before he applied the same frame to MacTech.

---

## New WWSD Principles (Pass 2 additions, #20–#27)

### WWSD #20 — Observer + Participant simultaneously
**Source:** ProGuide 067. *"There's two different roles that you assume: Observer and Participant. If we think of it that way, then it's pertinent to everything."*
**Application:** Reject the left-brain/right-brain framing. When you're scripting, you're both running the script and watching it. Switch roles within a single second. Most automation bugs come from being only the participant; most analysis paralysis comes from being only the observer.

### WWSD #21 — Forward Motion with a paddle
**Source:** ProGuide 067. *"I'm in a river that's moving and the current's moving. I can't go back upstream. But I have a paddle."*
**Application:** You can't undo. You can adjust. Observation without intervention is regret; intervention without observation is panic. Automation is the paddle — the small, well-aimed steering input that compounds over the trip.

### WWSD #22 — Look for the underlying principle (the Carpenter Move)
**Source:** ProGuide 067 + MacVoices CMDdConf. *"He imparted in me the concept that if you learn the principle behind something, then you could replicate it everywhere."* Sourced explicitly to Sal's master-carpenter father.
**Application:** When you can't make sense of a system, ask "what's the underlying principle?" Then replicate. This is the genealogy of Sal's entire method, and it predates AppleScript by decades.

### WWSD #23 — Bill on outcome, not on hours
**Source:** ProGuide 067. The AT&T $3,000 / 10-minute script story. *"That'll be three thousand bucks. And you know I'll write it in 10 minutes and then sit on it for a week before I send it to him."*
**Application:** When you've automated the hard part, the value is in the outcome, not the elapsed time. Don't let speed devalue the work. (Cousin: when applying this in practice, hold the deliverable long enough that the *experienced* time matches the value. Sal sat on the AT&T script for a week.)

### WWSD #24 — Speak the receiver's language
**Source:** ProGuide 067. The Patton-themed midnight email to Steve Jobs that won Tim Bumgarner and made AppleScript a peer development language.
**Application:** The technical merits of your case are necessary but not sufficient. Knowing the receiver's *frame* (Steve's favorite movie was Patton; Sal came from a military family; military metaphor is the lingua franca) is what gets the YES. Find the frame, write inside it.

### WWSD #25 — Pay in what cash can't buy
**Source:** ProGuide 067. The Lego Millennium Falcon side-payment to engineers who wouldn't accept cash.
**Application:** When cash is refused (legal, ethical, expense-reporting), find the in-kind asset the recipient *wants* but *can't justify*. The aligned-personal-want payment is uniquely effective. Generalizes beyond Legos: limited-edition books, conference passes, hard-to-source music gear, etc.

### WWSD #26 — Authorization as the bridge between conflicting principles
**Source:** ProGuide 067. The Yvonne Christic security-team resolution. *"The act of the user installing it means that the user wants us to have power."*
**Application:** When two principles directly conflict (open vs. secure, automation vs. privacy), look for the *authorizing gesture* the user can perform to make both true at once. The user's installation, consent, or signature is the bridge — not a compromise on either principle, but a third axis that the principles don't actually cover.

### WWSD #27 — Identify the trigger phrases
**Source:** MacVoices CMDdConf. *"There's got to be a better way" / "I don't want to do this."*
**Application:** Two specific phrases mark an automation candidate. Listen for them — in your own self-talk, in colleagues' complaints, in Slack messages, in support tickets. Each utterance is a script that hasn't been written yet.

---

## Cross-Pass Synthesis — What Sal's Method Actually Is

Reading Pass 1 + Pass 2 together, Sal's method has six layers, in order from inheritance to outcome:

1. **Inheritance — the carpenter's move:** look for the underlying principle (from his father)
2. **Recognition — the trigger phrases:** "there's got to be a better way" / "I don't want to do this" (WWSD #27)
3. **Method — observer + participant simultaneously:** see and act in one motion (WWSD #20)
4. **Tool — composable primitives, not rewrites:** AppleScript → Automator → APU all share substrate (WWSD #15)
5. **Politics — speak the receiver's language; pay in what cash can't buy:** the Patton email and the Millennium Falcon (WWSD #24, #25)
6. **Distribution — attachment as universal trigger:** plug it in, something happens (WWSD #12)

This is a complete strategy, derivable from primary-source spoken Sal, that goes from inheritance through to scaled deployment. It maps cleanly onto the Apple repo's working layers:

- bin/ pipeline = the principle-extraction layer (carpenter)
- workflows = the composable-primitives layer (Automator)
- Loupedeck integration = the attachment layer
- Sal site mirrors = the political-stewardship layer (codekipnapping for the next generation)
- Discord bridge / pakettibot = the speak-the-receiver's-language layer

---

## Story Inventory Update

Pass 1 inventory: 24 stories (TWiT 2018 origin, MTC2019 talk, WIRED Jobs stories).

Pass 2 additions:

26. Delaware Water Gap pre-history (Greek diner / video shop / bar menus)
27. Charlottesville + UVA + Joe Gibson / Linotronic
28. Quark XTension developer collaboration pre-AppleScript
29. The $14 (not $15) floppy
30. Real-estate magazine 20-second page layout
31. AT&T $3,000 script in 10 minutes
32. Better Homes and Gardens recipe fractions
33. The "kill the baby" recruitment threat
34. AppleScript briefly under ColorSync product manager
35. The "lost them all in one day" mass layoff and Data Detectors source-handoff
36. The code-base kidnapping (Espinoza + QuickTime PM)
37. The Patton midnight email + Tim Bumgarner / Avi / Phil meeting
38. Code bounties in the elevator ($1,200 cash for QuickTime Player)
39. The `do shell script` purchase
40. Lego Millennium Falcon engineer payments
41. Yvonne Christic security-team resolution (user-installed scripts)
42. **The Siri prototype that got applause and was killed for iOS-comparison reasons**
43. **WWDC session 717 (2016) — pulled video, four months before firing**
44. Viacom / Media 100: 1,800 promos in 30 minutes (and the failed Final Cut Pro setup)
45. Phil Woods / Poconos jazz neighbor (origin of Observer/Participant framing)
46. Mitchell Weinstock / Richard Ford / Eric Zelinka (the 1997 PM bench)
47. "People falling off the roof — ah! splop!" — 1997 layoffs heard daily
48. Father the master carpenter — origin of "underlying principle" method
49. Encrypted-PDF-from-address-book script — 4,000+ runs, internal-Apple evangelism strategy
50. Naomi (wife) + Berklee 1974-79 + Phil Woods peers (Eubanks, Ralph Moore) + MIDI guitar performances at Macworld

**Total distinct Sal stories now archived: 50.**

---

## High-Priority Open Threads From Pass 2

1. **WWDC 2016 session 717.** Sal says it was pulled a week after he gave it. This is a missing artifact that may exist in mirror archives, conference attendee notes, or the Wayback for `developer.apple.com/wwdc/2016/717`. Worth a discovery pass.

2. **The Siri-on-Mac prototype.** A working voice-controlled AppleScript-tied prototype with hundreds of NL commands across iWork/Photos/Finder. If any internal Apple slides, demos, or videos of this exist anywhere (developer leaks, ex-employee posts, blog summaries), they would be archive-central. **This is the most important missing artifact in Sal's career.**

3. **"Steve Glass" / "Bertrand Serlet"** — verify which Apple SVP made the deal that brought AppleScript into the OS. Whisper transcript said "Steve Glass"; that name doesn't match a known Apple executive. Probably a transcription artifact for someone else; check the timeline.

4. **Tim Bumgarner.** Named as the engineer who architected AppleScript's integration into Project Builder / Interface Builder, making AppleScript a peer development language. Find his post-Apple trajectory; he may be a future contributor / interview target.

5. **Yvonne Christic's security team.** Named as the team that built the user-installed-script-engine model still in use today. Worth tracing; her group's design choices propagated into modern macOS sandboxing.

6. **Joe Gibson.** Sal's print-industry mentor in Charlottesville. 29-30 years experience as of ~1990. Likely retired or deceased. If she's findable, she's a primary source for the pre-Apple Sal.

7. **Phil Woods Poconos connection.** Phil Woods (1931-2015) was based in the Delaware Water Gap area for decades. Sal's quote suggests they were neighbors / acquaintances. If Sal has any photos, recordings, or stories with Woods, they're worth preserving for the music side of the Sal archive.

8. **Two albums: Blue Indigo "Catwalk" and "To Be With You."** ProGuide intro confirms two Sal albums on Apple Music under the band name "Blue Indigo." Worth indexing in `analysis/sal/discography.md` (does not yet exist).

9. **Sal's military family background.** Stated as "I came from a military family so I know how to speak military." Not previously mentioned in any Sal biographical material. Worth noting in `sal-soghoian.md`.
