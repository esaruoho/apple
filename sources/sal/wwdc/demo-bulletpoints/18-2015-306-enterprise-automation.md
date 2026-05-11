# WWDC 2015 #306 — Supporting the Enterprise with OS X Automation

**Speaker:** Sal Soghoian (solo) · **48:56** · Track: Distribution (iOS, macOS)
**Sal's LAST confirmed WWDC before the October 2016 firing.**
**nonstrict:** https://nonstrict.eu/wwdcindex/wwdc2015/306/

## The pitch — the and-not-or thesis

> *"Today is not one of those days."*

Sal's stock opener was *"some days I feel like a dinosaur looking for a tar pit."* In 2015 he **inverts the joke**. Reads in retrospect as Sal knowing this stage is worth marking.

The political claim of the talk: **OS X automation should NOT be sacrificed for iOS investment. It's `and`, not `or`.** Sal is on Apple's own stage arguing that the discipline he runs shouldn't be cut. He loses the argument 16 months later.

## The three demos

### Demo 1 — Folder-Action image repository

> *"This will be the first time I'm demoing this. It's the first time anybody has seen this."*

Setup:
- Network folder shared across an enterprise team
- AppleScript folder-action attached
- Watches for incoming images
- On drop: applies a per-team standard (resize, watermark, metadata strip), files into dated subfolders

**The accidental-administrator doctrine.** A non-technical employee placed in charge of a shared folder becomes an automation administrator without knowing it. The folder action does the work.

### Demo 2 — Numbers → Keynote → AirDrop document construction

Multi-app pipeline:
- Numbers spreadsheet with employee data
- AppleScript iterates rows, generates a personalized Keynote slide per employee
- Each slide AirDrop'd to the targeted employee's iOS device

**The Mac as document factory, iOS as consumption surface.** Same pattern as 2010 #302 (iPad content pipeline), updated to a 2015 enterprise context.

### Demo 3 — Apple Configurator 2 + Automator iOS device provisioning (★ world premiere)

> *"This is the first time anybody has seen this, and you guys are the ones that are going to see it."*

**Apple Configurator 2** ships with **Automator action support**. The provisioning workflow becomes a drag-drop pipeline:
- *Add Devices* action — accepts a list of iOS device serials
- *Install App* action — pushes an .ipa
- *Restore From Backup* action — applies a baseline image
- *Add to Group* action — assigns to MDM group
- *Email Receipt* action — confirms to the IT person

Sal: *"I bet most of you didn't realize that stuff was actually in the OS."*

**Rare PM-frustration aside.** The features were already there. Apple just didn't market them. **This is Sal's complaint about his own org, on stage.**

## The accidental-administrator doctrine

The unifying theme across all three demos: **automation administrators are not the people IT hired for the job.** They're:
- The shared-folder owner (Demo 1)
- The Numbers user who builds the slides (Demo 2)
- The IT generalist (Demo 3)

**The doctrine:** automation must be ergonomic enough that whoever finds themselves with the responsibility can fulfill it — not just AppleScript specialists. **Organizational-scale extension of WWSD #1 (democratization).**

## Valedictory content (in retrospect)

Seven lines flagged as valedictory:

1. **The opening joke inversion** — *"Today is not one of those days"* marks the stage as worth marking
2. **The and-not-or framing** — political argument inside Apple, on Apple's stage, about whether OS X automation should be cut
3. **"First time anybody has seen this"** (Configurator 2) — world-premiere framing on a feature his team built
4. **"I bet most of you didn't realize that stuff was actually in the OS"** — PM frustration aside about his org's marketing
5. **The four-constituency thank-you** repeats (developers + scripters + customers + engineers)
6. **The community model** is articulated more carefully than ever — *"all of these people"*
7. **Closing line: *"Thank you so much for being part of this experience for me."***

The final line's unusual **first-person-singular "experience-for-me"** phrasing reads as the strongest valedictory marker in the transcript. Sal didn't know this would be his last WWDC. But on the recording, it reads as if he did.

## Power features delivered

- **Apple Configurator 2 + Automator integration** — iOS device provisioning as drag-drop workflow
- **Folder-Action-based shared-folder automation** for enterprise teams
- **Multi-app document factories** (Numbers + Keynote + AirDrop)
- **AppleScript + JXA + Automator + Services + Terminal** — the full five-pillar canon now (Terminal added in 2011, Services in 2007)
- **The accidental-administrator doctrine** as the organizational-scale extension of WWSD #1

## Sal voice (verbatim)

> *"Automation is the life blood of any organization, providing speed, accuracy, and the ability to efficiently scale in-house processes."* — opening, the four-whys verbatim

> *"With tools like Automator, AppleScript, and the new JavaScript for Automation (JXA), creating problem-solving solutions has become even easier and even more interesting."*

> *"This will be the first time I'm demoing this, it's the first time anybody has seen this, and you guys are the ones that are going to see it."*

> *"Thank you so much for being part of this experience for me."* (closing)

## Marketing copy version

**Headline:** Automation isn't optional for enterprise. The accidental administrator runs the shared folder, builds the documents, provisions the devices. OS X gives them the tools — AppleScript, JXA, Automator, Apple Configurator 2 — to do it without writing a single line of code.

**Audience takeaway:** if you're at an enterprise that uses Macs, this is the WWDC session that justifies the budget. If you're an Apple watcher, watch this one knowing it's Sal's last. The man is on stage making the case for his own discipline 16 months before Apple eliminates the role.

## Historical note

WWDC 2016 had no Sal session. Sal had presented every year 2003-2015 (with the only gap being 2014's lack of a second talk). His silence at WWDC 2016 is the first audible sign of what was to come. He was officially eliminated in **October 2016**, four months after WWDC 2016. **2015 #306 is the last primary-source on-stage Sal.**

The successor event — WWDC **2018 #717 "Introducing Siri Shortcuts and AppleScript"** — is Apple announcing the technology that replaced Sal's discipline. **Sal himself never presented at WWDC again.**
