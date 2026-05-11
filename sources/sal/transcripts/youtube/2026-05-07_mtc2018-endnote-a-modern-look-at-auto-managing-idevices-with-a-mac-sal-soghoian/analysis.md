# MacTech Conference 2018 EndNote — "A Modern Look at Auto-Managing iDevices with a Mac" (Sal Soghoian)

**Speaker:** Sal Soghoian (introduced by Neil Ticktin of MacTech)
**Length:** ~55 minutes (810-line transcript)
**Context:** MacTech Conference 2018, Los Angeles. **Two years after the October 2016 elimination from Apple.** The session is the conference **EndNote** — explicitly programmed to "set tones all the way through" (per Neil's intro). Sal returns as a returning headliner, no longer the "mystery speaker" of 2016 or the surfboard parable of 2017.
**Audit attestation:** every quoted phrase below verified verbatim by direct read of transcript.txt by Esa's auditor on 2026-05-11.

## The historical position

This is **post-Apple Sal as a working consultant** — explicitly so. The intro notes Sal "is the Apple script guy. Period. And he is still doing a whole bunch of stuff... He's working with folks like Omni Software and a whole bunch of other clients that are out there." Where MTC2017 was a Sal-evangelises-Omni-Automation talk, MTC2018 is a Sal-teaches-you-a-Mac-admin-recipe talk, with a quietly bombshell mid-talk disclosure:

> *"It's created by the services group professional services team at Apple which I do contract with and work on this utility..."*

**Sal is still on contract to Apple in late 2018.** This is the single most operationally important fact in the post-Apple Sal corpus from this period — Apple eliminated his position but kept him on as a Professional Services contractor working on the Apple Provisioning Utility for tens-of-thousands-of-iPads deployments. The institutional separation was not as clean as the firing narrative implies.

## Sal's framing — empowerment for the "accidental administrator"

> *"I'm all about automation. I'm all about the concept of making it easier for you to do something and empowering you. So today I'm going to be talking about a kind of automation, Mac-based automation, that you might not have thought of before."*

> *"These people are accidental administrators. Every company has them. Someone might have left their job and somebody else is suddenly put in charge of 50 iPads. Somebody got promoted or something happened and all of a sudden the organization moves and somebody that's not really technical about it suddenly has to manage these devices."*

**"Accidental administrator" is Sal's empowerment-target archetype here**, equivalent to the "ordinary user" archetype of his Apple-era talks. Same WWSD #1 democratization principle, projected onto enterprise-IT users. The Mac admin in the room is being asked to **build a tool that makes a non-Mac-admin colleague functional** without code-writing.

## The agenda — six components of a tethered iDevice automation station

> *"Today my agenda is we're going to be talking about how to create a Mac station that will automatically set up iOS devices when they are plugged into it. It will require a Mac and will require you know different iOS devices that we're going to manage and they're going to be tethered to the Mac via a cable we're not going to be doing a Wi-Fi thing today and it also will require a minimal amount of user interaction from the user we don't want the user to have to do very much at all minimal amount and the best part is it's going to be an easy setup for you no code writing at all."*

Sal explicitly enumerates six recipe components: Apple Configurator, Automator workflow, content caching, MDM (Jamf Now / Jamf Pro), attachment agent, **tether response chain (TRC)** — a term Sal makes up live:

> *"A term I made up myself, it's called a tether response chain. We're going to create a tether response chain, a TRC, man, of course. I was doing a TRC the other day."*

The self-aware joke about coining the acronym mid-talk is signature Sal-voice (cf. **WWSD #11** — name things like speech, not labels). The TRC is now a real named pattern that didn't exist before this talk.

## The principle of attachment

> *"For this set of people, we can provide a different type of solution, and it's based upon a very fundamental principle. It's the principle of attachment."*

> *"What we're going to look at is we're going to examine how to create an automated scenario for iOS refresh as soon as it gets attached to the Mac. That's all they're going to have to do is just plug it in. They won't have to go to a menu. They won't have to make any other choices. And you're going to do this for them without writing a line of code?"*

**Attachment as automation trigger.** Same architectural shape as Hey Sal v1's voice-as-trigger pattern — a single user action (plug in / speak phrase) becomes a fully scripted multi-step sequence. The pattern is **trigger → recipe → side-effects → done**, with no menu navigation by the user. This is **the iOS-deployment instance of WWSD #43 (one verb per action).**

## The architecture — `cfgutil exec` + LaunchAgent + Automator workflow

> *"In the CFG util there is a very powerful command it's this one, E-X-E-C, X, whatever, execute, but it's just for attachment. It will sense and execute whenever a device is attached or detached from the machine. It knows about that device and will run."*

> *"Be aware it's not re-entrant. It doesn't have all the protections that the Automator workflow gives you, so if you try to do this from the command line, you're not going to be successful."*

> *"What we're going to do is create a launch agent that runs a shell command that executes the workflow. That's going to be our strategy for this scenario."*

**The three-component TRC:**
1. **LaunchAgent** (`~/Library/LaunchAgents/*.plist`) — long-running daemon
2. **Command shell script** — `cfgutil exec -a <command-file>` triggers on attach/detach
3. **Automator workflow** (`~/Library/Workflows/attachment-workflow.workflow`) — the actual recipe

Sal walks through the exact file paths, the exact `cfgutil` flag, the exact env-var passthrough (`ECID`, `UDID`, `path`, `device name`, `firmware version`, `location`, `build version`). **This is the most operationally detailed talk in the post-Apple Sal corpus.**

## The re-entrancy engineering detail

> *"When you attach multiple devices to the USB port on a Mac, the USB port on a Mac is not designed to handle 10 devices simultaneously. You need to have something that kind of does a load balancing, that delays certain ones until the other ones are completed, and this action will handle all of that process for you as well."*

> *"There's nothing you need to do but have this action at the and it will make your workflow re-entrant protected, and it will also make the whole machine load balanced so you can put 40 devices on one Mac."*

**Sal authored an Automator action that does USB load-balancing across 40 simultaneously-attached iDevices.** This is not a "user-facing democratization" talk — it is a **fleet-deployment hardening** talk. The Automator action does what enterprise IT would normally pay a JAMF-engineer to do.

## The stub-file pattern — handling iOS reconnect mid-workflow

> *"During the process of getting erased and reformatted and everything, an iOS device will automatically disconnect itself from the computer and then reconnect, thereby triggering that whole process again."*

> *"Is it looks to see if there's a stub, and if there is, ignores the request and allows your workflow to keep running properly."*

**A stub file in a known location is the lock-out signal.** Workflow start → write stub; on each subsequent attach event, check stub; if present, ignore. Workflow end → delete stub. This is **the same architectural trick as DC-XXX lock files / Hey Sal's matcher's debounce** — minimal-state coordination via filesystem.

## The Apple Provisioning Utility disclosure

> *"Apple has a tool that they use when you need to professionally manage shared use devices so that there's zero touch, so that you can go from a pallet of iPads to delivered devices quickly. And it's called the Apple Provisioning Utility. This hasn't been shown. I'm showing you this and you can't go online and see this video."*

> *"It's created by the services group professional services team at Apple which I do contract with and work on this utility because it's a great automation tool and I love and the guys on the team are absolutely amazing."*

> *"You can do up to 40 different iOS devices per Mac at a time. So if you have five Macs with this set up, and you're doing 40 per, you're doing like 200 iOS devices simultaneously."*

**Three findings here:**

1. **Apple Provisioning Utility exists** as an internal tool, never publicly released. Used by United Airlines (the pilots-with-iPads photo), retail, law enforcement. 40 devices per Mac, batch-processed via Automator workflow.
2. **Sal contracts with Apple's Professional Services team in 2018** on this utility. The "fired in October 2016" narrative needs amendment — Sal's relationship with Apple post-elimination is **a Professional Services contract on an internal automation tool**.
3. **The talk shows live video of the utility** to a roomful of Mac admins, which Sal explicitly notes cannot be found online. The MTC2018 endnote may be the only public glimpse of Apple Provisioning Utility on record.

This single mid-talk disclosure shifts the post-Apple-Sal lineage significantly.

## The Jamf Pro extension-attribute live demo

> *"What I'm going to do is I'm going to show you how to create a small command script that talks directly to the Jamf Crow server. So when the command gets executed, it's going to change an extension attribute on the device. And by changing the extension attribute, it's going to put that device in a different device group."*

> *"So we're basically going to make it so that you can take a device, walk up to a machine, plug it in, and it will instantly set up for a certain scenario. Then I can take the device, go to another machine, plug it in, and set it up for another scenario."*

The live demo: plug in iPad → cfgutil exec → curl-to-Jamf-API → change extension attribute → Jamf moves device into a different group → group's config profile applies → device wallpaper changes + apps hide/show.

> *"There go the apps. And it's blue."*

**The classroom-rotating-iPads use case** — a school where one iPad cart serves geography, math, science classes; the appropriate-class iPad config follows the **physical location of the Mac the iPad is attached to.** Plug into the science-Mac → device becomes a science-device. Move to geography-Mac → device becomes a geography-device. No re-imaging. No human admin in the loop.

## Sal-voice signature quotes

> *"Bob comes in and goes, I got the device. How do you update this? And you go, Bob, plug it into the thing, go get a donut. And so you plug it in like that, and then here's what happens."*

**Bob-and-the-donut** is the canonical Sal-voice user-empowerment scenario. Same rhetorical move as the Apple-era "your mom" or "your grandmother" stand-in user. Sal personalises the abstract role; the audience laughs and remembers.

> *"That way you won't forget to accidentally plug in your own phone and have it erased like happened to me. I learned that one."*

**Self-deprecating engineering disclosure.** Sal admits he wiped his own phone testing this; the audience laughs; the safety pattern (load/unload shell scripts in script menu) gets remembered.

> *"The next time I meet you guys, I want you all driving Ferraris. So we gotta up your stock in the company, right? Tesla's don't count."*

**Closing line.** Empowerment-as-career-leverage framing for the audience of Mac admins.

> *"Are we going to see a similar solution for the Mac?"* / *"Oh, put me on the spot. Whoa. I cannot comment on that topic."*

**The Q&A end.** Sal explicitly declines to comment on a Mac-side equivalent of the Apple Provisioning Utility — implying one exists or is in development, and his contract scope covers it. **This is Sal's strongest signal that the Apple Professional Services contract is substantive, not symbolic.**

## WWSD-relevant takeaways

- **WWSD #1 (democratization)** projected onto enterprise-IT users: the "accidental administrator" is the equivalent of the "ordinary user" — same principle, different audience.
- **WWSD #5 (use what's already there)** at its most concrete: `cfgutil` + Automator + LaunchAgent + content caching + Apple Configurator are all built-in or free. No new code. No new tool. Sal builds an enterprise-grade iDevice provisioning station from stock macOS components.
- **WWSD #11 (name commands like speech, not labels)** evidenced live by Sal coining "tether response chain" / "TRC" mid-talk. He literally invents a name in front of the audience to make the pattern recognisable.
- **WWSD #20 (institution is not the relationship)** complicated by the Professional Services disclosure — Sal kept the *engineering* relationship with Apple even after losing the *evangelism* relationship. The institution didn't fully sever; it just changed the contract type. Worth a footnote in the canon.
- **WWSD #43 (one verb per action)** at the user surface — the entire 6-component recipe collapses to one user action: plug in the cable.

## CANDIDATE WWSD #49 — *"The trigger is the only user action"*

**Source quote:**
> *"That's all they're going to have to do is just plug it in. They won't have to go to a menu. They won't have to make any other choices."*

**Rationale:** Across Sal's career — dictation commands (one phrase), Vocal Shortcuts (one phrase), Automator services (one Quick Action), Spotlight launch (one mdfind hit), and now tethered iOS provisioning (one cable plug) — the pattern is the same: **the trigger is the ENTIRE user action surface; everything else is recipe.** This is more specific than #43 (one verb per action). #43 says each automation is one verb; #49 says the **user's experience of automation** should be reduced to a single trigger, after which they do *nothing*. The trigger may be voice, plug, hotkey, drop, tap; but it is ONE event, and the entire downstream recipe runs without further user input.

**How to apply:** When designing Hey Sal v2 actions, audit each one for the "after the trigger, the user does nothing more" property. If a Hey Sal action requires a follow-up dialog, confirmation, or selection — it has not yet met the WWSD #49 bar. Either pre-select via context (last-frontmost-app, last-selected-track, last-opened-file) or split into two distinct triggers.

## CANDIDATE WWSD #50 — *"The accidental administrator is the design target"*

**Source quote:**
> *"And as an administrator, your challenge is, can you create a set of tools that make it easier for these people to do their job? And the answer is yes."*

**Rationale:** Sal explicitly identifies **the non-technical person who inherits a technical responsibility** as the empowerment target. This is structurally different from #1 (democratization for ordinary users) because it is empowerment-via-intermediary: the Mac admin builds the tool, the accidental admin uses it. Two distinct user roles, one design pattern. Worth canonising distinct from #1 because the apple repo's `bin/workflow-gen.py` and Loupedeck binding catalog have an equivalent structure — Esa builds the tools; future-Esa (the "accidental admin of his own Mac three months from now") uses them. The accidental-administrator principle says: **design for the person who inherits the tool, not the person who built it.**

**How to apply:** When writing apple-repo scripts, write the help text and the recovery messages for the version of Esa who has not touched the script in 6 months and forgot the conventions. The Bob-and-the-donut user is the design target, not the Esa-who-just-built-it user.

## Reusable for the apple repo

- **The TRC (tether response chain) pattern is directly portable.** A Mac admin building a workstation provisioning station for new-employee onboarding could use the same `cfgutil exec` → LaunchAgent → Automator workflow recipe. Worth a `bin/trc-template/` scaffold in the apple repo.
- **The Apple Provisioning Utility disclosure** belongs in `analysis/sal/post-apple-timeline.md` and `sal-soghoian.md`. The October-2016-firing narrative needs the Professional-Services-contract amendment. Possibly worth a focused Sal-correspondence outreach: ask Sal what the contract scope and end date were.
- **The stub-file debounce pattern** is portable to Hey Sal v1's matcher (currently no debounce). If the user says "play kick" three times in two seconds (Vocal Shortcuts double-trigger), a stub file at `/tmp/hey-sal-debounce-<verb>` could lock for 500ms.
- **The `cfgutil` env-var → Automator workflow input pattern** is portable to **any USB-attach trigger** — Loupedeck plug, MIDI controller attach, USB-MIDI device attach. Worth a `bin/usb-attach-automator.sh` generic wrapper.
- **The 40-devices-per-Mac load-balancing pattern** is portable to Hey Sal's matcher when running batch operations across N Renoise/Logic tracks. Same hardening question, different surface.
- **The "what cannot be googled" Apple-internal-tool screen recording** — if the YouTube video is still up, the apple repo should mirror it under `sources/sal/videos/2018-mtc-endnote.mp4` (gitignored per CLAUDE.md private-asset policy) so the Apple Provisioning Utility footage is preserved.

## Audit footer — verbatim quote verification

All quotes verified by direct character match against transcript.txt:

| Quote | Line(s) |
|-------|---------|
| *"It's created by the services group professional services team at Apple which I do contract with..."* | 587-590 |
| *"I'm all about automation. I'm all about the concept of making it easier for you..."* | 28-30 |
| *"These people are accidental administrators..."* | 129-133 |
| *"Today my agenda is we're going to be talking about how to create a Mac station..."* | 36-44 |
| *"A term I made up myself, it's called a tether response chain..."* | 206-208 |
| *"For this set of people, we can provide a different type of solution..."* | 170-172 |
| *"What we're going to look at is we're going to examine how to create an automated scenario..."* | 173-184 |
| *"In the CFG util there is a very powerful command..."* | 446-448 |
| *"Be aware it's not re-entrant..."* | 449-451 |
| *"What we're going to do is create a launch agent that runs a shell command..."* | 462-464 |
| *"When you attach multiple devices to the USB port on a Mac..."* | 390-394 |
| *"There's nothing you need to do but have this action at the and it will make your workflow re-entrant protected..."* | 395-397 |
| *"During the process of getting erased and reformatted..."* | 376-379 |
| *"Apple has a tool that they use when you need to professionally manage shared use devices..."* | 581-584 |
| *"You can do up to 40 different iOS devices per Mac at a time..."* | 597-598 |
| *"What I'm going to do is I'm going to show you how to create a small command script..."* | 649-655 |
| *"So we're basically going to make it so that you can take a device, walk up to a machine, plug it in..."* | 656-663 |
| *"There go the apps. And it's blue."* | 734 |
| *"Bob comes in and goes, I got the device..."* | 524-527 |
| *"That way you won't forget to accidentally plug in your own phone..."* | 486-488 |
| *"The next time I meet you guys, I want you all driving Ferraris..."* | 781-783 |
| *"Are we going to see a similar solution for the Mac?"* / *"I cannot comment on that topic."* | 801-804 |
| *"And as an administrator, your challenge is, can you create a set of tools..."* | 133-135 |
| *"That's all they're going to have to do is just plug it in..."* | 178-181 |

No paraphrasing in quote marks. Interpretive layering (TRC portability, accidental-admin principle, Apple-Professional-Services-contract amendment) is mine, layered over verified-real lines.

## Whisper proper-noun confidence flags

- **"Sal Segoia" (line 22)**, **"Sal Zagoya" (line 754)** — mishearings of **Sal Soghoian**. Standard corpus issue; note the 2018 talk Whisper produced *two different* mishearings within one transcript.
- **"Jamf Crow" (line 650)** — mishearing of **Jamf Pro**. Cosmetic.
- **"CFG util" / "cfgutil"** — Sal pronounces both ways; actual tool is `cfgutil`. Cosmetic.
- **"Jamf cloud" / "Jamf floud"** (line 221) — mishearing of **"Jamf cloud"**. Cosmetic.
- **"macosautomation.com" (line 19)** — actual domain is **macosxautomation.com** (with x). Whisper dropped the x. Verify against site name in canon.
- **"configautomation.com"** (lines 352, 437, 742) — appears to be a real Sal domain Sal references as his iOS-attachment-workflow site, distinct from macosxautomation.com and DictationCommands.com. Worth confirming the domain exists / is mirrorable.
- **"iOSification" (line 543)** — coinage by Sal, not a Whisper error. The act of "being taught how to tap dialogues in different places on a regular basis."
- **"Tom Kohler from Jamf"** (line 686) — proper name; verify spelling against Jamf staff records.
- **"Brettford" (line 110)** / **"Brett cart" (line 618)** — mishearings of **Bretford** (the iPad-cart manufacturer). Cosmetic.
- **"D20"** (line 110) — Bretford product model; verify.
- **"Patrick" / "Greg"** (lines 2-3) — earlier MacTech keynote/secondnote speakers; not Sal-relevant.
- **"hola home screen" (line 532)** — mishearing of **"Aloha home screen"** or simply **"the home screen"**. Cosmetic.
- **"in the prepare"** (line 439) — partial sentence; Whisper-fragmentary but content clear from context.
- **"register your wallpaper" / similar word-soup** — cosmetic conference-Whisper artefacts; content recoverable.
