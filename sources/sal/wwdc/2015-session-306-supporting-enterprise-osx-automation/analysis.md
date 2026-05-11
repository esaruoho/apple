# WWDC 2015 Session 306 — Supporting the Enterprise with OS X Automation (Analysis)

**Speakers:** Sal Soghoian, solo (no Chris Nebel, no guest demo)
**Duration:** ~50 min · **Year:** 2015 (El Capitan / 10.11 era)
**Source:** Whisper-generated transcript from nonstrict.eu (machine-transcribed; expect proper-noun and homophone errors — "Pearl" = Perl, "JXA" rendered correctly, "Otto the Automator" = Apple's cartoon robot mascot, "Karl Whelan" likely Carl-something, "Mac OS X" still the brand)

## The historical position

**This is Sal's last confirmed WWDC session.** Sixteen months later (October 2016), Apple eliminates his role. There's no 2016 session — Sal has said in subsequent interviews that the writing was on the wall internally well before the public firing.

Reading 306 in 2026, with full hindsight, the valedictory texture is unmistakable. Sal solo (no Nebel co-host this year), the title pitched at *enterprise* (the most institutionally-defensible audience for automation inside Apple), the framing aggressively centered on **inclusion / and-not-or**, and the closing 60 seconds about *"thank you for being part of this experience for me"* — all read in retrospect as Sal making the case for his discipline's continued existence to an Apple leadership that was no longer listening. He doesn't know yet that this is the last one, but the talk argues for automation's institutional value with the intensity of a man defending his job.

It also sits at peak technical breadth: AppleScript + AppleScript-ObjC + JXA (new, ~12 months old) + Automator + Folder Actions + Apple Configurator 2 Automator support (debuted Tuesday of WWDC week, demoed publicly here first). **The full Soghoian-era toolkit on display, simultaneously.**

## Sal's framing — verbatim opening

> *"Whoa, thank you and welcome to Session 306, Supporting the Enterprise with OS X Automation. I am Sal Soghoian. I am the Product Manager for Automation Technologies at Apple, and I'm excited to be here today. Some days I feel like I'm a dinosaur looking for a tar pit, but today is not one of those days."*

The "dinosaur looking for a tar pit" line is the same stock self-deprecation he used in 2012 #206 — recurring Sal-joke, not unique to 2015. **But the "today is not one of those days" inversion is new**, and reads in retrospect as a man explicitly *enjoying* a stage he won't get again.

Then the pivot — the people-first thesis:

> *"When you talk about an enterprise you're actually talking about people. People are what comprise an enterprise and make it successful, they are the people that come up with the creativity, they are the ones that implement solutions, they are the ones that create solutions. You are those kind of people. You look for a problem, and you look for ways to solve it. So throughout this talk today, I'm always going to look at things from a people perspective."*

**This is the strongest "people-first" framing Sal ever delivers at WWDC.** It explicitly rejects the standard enterprise framing (devices, deployments, MDM, fleet management) and replaces it with the workers running the fleet. The entire session is structurally anchored to this: every demo ends with *"let's take a people perspective and see how this looks to a person using this."* It is the WWSD credo (*"the power of the computer should reside in the hands of the one using it"*) translated into the enterprise vocabulary.

## What Sal covers (the substance)

### 0. Workflow-design strategies (the pre-amble)

Before any demos, Sal lays out four design principles for workflow construction:

1. **Use a variety of tools** — *"Don't solve everything with a hammer because then all of the problems appear to be nails. Use the right tool for the job, don't try to drive a nail with a wrench."*
2. **Make workflows modular** — components must be reusable across scenarios, swappable
3. **Identify bottlenecks** — *"they usually occur around complexity or a heavy repetition"*
4. **Pursue inclusion — and, not or** — *"the success of an organization depends upon the strategy of and, not or"*

The fourth principle is the load-bearing one. *"Many times people get locked into the idea that's often used for hardware that one piece of hardware has to go away in order for another piece of hardware to take its place."* He's making the OS X + iOS case to an audience that — by 2015 — was watching Apple's resource allocation visibly tilt toward iOS. **This is Sal making the inclusion argument inside the company's most contested resource debate.** The framing reads, in retrospect, as a quiet defense of OS X automation's continued investment.

### 1. The automation tool family (the inventory)

Sal lays out the full Soghoian-era toolkit, with explicit acknowledgement of JXA as a peer to AppleScript (not a replacement):

- **AppleScript** — *"the English-like language"*
- **AppleScript / Objective-C** — *"a window into the Cocoa framework… any of the Cocoa frameworks that provide the power for the OS and all of its apps are available to your script"*
- **JavaScript for Automation (JXA)** — *"if you like working with the JavaScript language or you like a more tight construct… provides you all of the abilities to control applications as similar to the way AppleScript does and it also provides you the window into the Cocoa frameworks"*
- **Automator** (*"Otto the Automator"*) — *"a visual tool for building automation recipes, through a drag-and-drop process"*
- **The full UNIX toolset** — *"all of the different shelves and some of your favorite languages, like Perl, Ruby, and Python"*

Then the four-whys restatement: *"automation can give you the speed, the accuracy, the consistent output, and the scalability that you need when you're dealing with solutions."* Same four whys as 2003 #718 (consistency, accuracy, speed, scale). **Vision-stable across twelve years.**

### 2. Scenario 1 — Workgroup image repository (Photos + File Sharing + AirDrop + Folder Actions)

The architecture:
- Mac at center serving 40-50 people on a LAN
- **File Sharing** (SMB/AFP) for desktop/laptop clients (Mac + Windows)
- **AirDrop** (Bluetooth + Wi-Fi) for iOS clients
- **Folder Actions** as the bridge that closes the loop: dropped files → Automator workflow → Photos library import

Sal calls Folder Actions out as the under-known piece: *"many of you might not know about Folder Actions, but a Folder Action is a system service that allows you to assign a workflow to a folder so that when items are placed into that folder, the system automatically provides them as input to a workflow that it executes for you automatically. And Folder Actions have been part of OS X since before it was OS X, we've had them since System 8.5."* — locating Folder Actions as a **30-year-stable** OS technology, which directly reinforces the vision-stability theme.

Two Folder Actions: one on `~/Public/Drop Box/`, one on `~/Downloads/`. Both import to Photos. Plus an **Auto-Accept AppleScript droplet** that auto-accepts AirDrop incoming when no user is at the receiving Mac. Companion site: `photosautomation.com`.

### 3. Scenario 2 — Document construction (Numbers → Keynote → AirDrop to iPad)

A "weekly sales report" workflow built entirely in Automator. The chain:
1. Create new Keynote presentation (gradient, mobile-sized)
2. Set title "Sales Report" + subtitle = today's date (Automator variable)
3. Apply dissolve transition (1.5 sec, on click)
4. Add new slide (title-at-top layout)
5. **Add Chart with Numbers Table Data** — pull from `ACME Widget Domestic Sales.numbers`, first table of active sheet
6. Save Document to `~/Documents/` with name `Sales Report <date>.key`
7. **Begin AirDrop with Disk Items** — push file to nearby iPad

The whole thing runs on stage; Sal accepts the AirDrop on iPad, opens it in Keynote-iOS, runs the presentation.

Sal's aside after the applause: *"Isn't it interesting? I'll bet you most of you didn't realize that stuff was actually in the OS, huh?"* — a rare flash of frustration at how underused the technology is. The PM whose product the audience just discovered. This lands differently when you know the discipline is one year from elimination.

> *"They act on your behalf with all the authority that you have as a user."*

This is the **2015 articulation of WWSD #1** (democratization). Automation = user-authority extension. Companion site: `iworkautomation.com`.

### 4. Scenario 3 — iOS device deployment via Apple Configurator 2 + Automator (the headline new feature)

> *"This will be the first time I'm demoing this, it's the first time anybody has seen this, and you guys are the ones that are going to see it."*

Apple Configurator 2 (announced Tuesday of WWDC week) shipped with **first-class Automator support** — a new action library category named "Apple Configurator". Sal builds a workflow on stage:

1. **Get Connected Devices** (filter by iPad/iPhone/iPod touch/Apple TV) — Sal picks iPad
2. **Copy Documents to Devices** × 3 — each instance targets a different iOS app:
   - Adobe Acrobat Reader: student handbook PDF, student newsletter PDF
   - Pages: book report template
   - Keynote: photo slideshow template
3. Confirmation dialog at start + end (via a custom helper script he keeps in his Scripts folder)

The whole workflow saved to `~/Library/Scripts/Applications/Apple Configurator/`, runnable from the system Script menu.

#### The "accidental administrator" doctrine

> *"In large organizations it's quite often a reality that the people who end up managing devices really don't have a great depth of knowledge about IT issues. So we call them, like, accidental administrators. It might be someone who assumes a role or assumes a task because another person has moved to a different part in the company, or organizations might merge together and people assume new responsibilities. So your challenge as an IT professional is to create tools that will solve these people's problems and allow them to set up mobile devices."*

**This is Sal's clearest articulation of the "automate FOR another human" principle** ever delivered at WWDC. The IT professional in the audience writes Automator workflows so the *accidental administrator* — the front-desk receptionist who got handed iPad-cart duty when someone left — can pick a menu item and provision a classroom. The IT pro never meets the accidental admin; the workflow is the artifact that carries IT-pro skill across the organizational gap.

This is the structural twin of the 2012 #206 *user-placed-file = consent* pattern, but at organizational scale: **workflow-placed-in-Scripts-menu = delegated authority**. The Scripts menu is the consent surface across human roles.

Companion site: `configautomation.com`.

### 5. The closing inventory of companion sites

Sal lists four Sal-personal sample-library URLs as the session's takeaway resources:
- `photosautomation.com`
- `configautomation.com`
- `iworkautomation.com`
- `macosxautomation.com`

**All four are Sal's personal shadow-documentation infrastructure** — not `developer.apple.com` paths. In retrospect, this is the surface that Sal continued maintaining *after* the 2016 firing, transitioning into `cmddconf.com`. The 2015 WWDC closing slide is a list of Sal-domain URLs that outlived his Apple tenure.

## Valedictory content (the consciously-tracked layer)

Lines that read in retrospect as last-words flavor:

1. **Opening — "today is not one of those days"** *(line 9)* — Sal explicitly carving out THIS stage from his "dinosaur" self-image. He's enjoying being here. He doesn't yet know he won't be back, but he's marking the moment as worth marking.

2. **The inclusion thesis — and-not-or** *(lines 15-17)* — *"the success of an organization depends upon the strategy of and, not or"* with the hardware-replacement aside. **This is Sal arguing inside Apple, in front of an Apple-curated audience, that the OS X discipline should not be sacrificed to iOS investment.** It is the load-bearing political claim of the talk. Sixteen months later, the and-not-or argument loses inside Apple and Sal's role is eliminated. In hindsight this section is a defense plea.

3. **"You guys are the ones that are going to see it"** *(line 67, Configurator 2 reveal)* — the world-premiere framing. Sal positioning the audience as witnesses to a debut. The PM who knows this is the freshest demo he has, presenting it as a gift. Reads with weight when you know it's his last debut.

4. **"I'll bet you most of you didn't realize that stuff was actually in the OS"** *(line 65)* — the rare flash of PM-frustration. The product the audience just discovered. Hindsight: a year later the PM gets eliminated and *the audience's not knowing* becomes part of the institutional argument for eliminating the role.

5. **"Spell, Sal, spell."** *(line 93)* — Sal coaching himself through a typo on stage during the Configurator demo. Small, human, recurring across his demos — but in 2015 it's the last time Apple's WWDC audience hears him do it. The Sal-talks-to-himself-on-stage tic.

6. **Closing — "thank you so much for being part of this experience for me"** *(line 99)* — final line before applause. The word *experience* is unusual here. Sal usually closes with *"have a great conference"* (and he does also say that). But *"being part of this experience FOR ME"* — first-person-singular framing of the WWDC stage as a personal experience — reads, with hindsight, as the line a man delivers when he's quietly aware this might be the last one. **It is the strongest valedictory-feeling line in the transcript.**

7. **"After I'm done here I'm going to go downstairs and hang out at the lab so you can come by and see me"** *(line 99)* — the lab promise. Sal making himself available to the community for one more in-person session. He kept the lab promise; the firing came 16 months later.

None of these are *explicit* last-words language. Sal doesn't know this is the last one. But the cumulative texture — the explicit moment-marking ("today is not one of those days"), the institutional defense plea (inclusion / and-not-or), the people-first framing pushed to its strongest formulation, the *"thank you for being part of this experience for me"* closer — adds up to a session that reads, post-October-2016, as a man making his discipline's case at full volume.

## WWSD-relevant takeaways

- **People-first as the explicit thesis** — *"when you talk about an enterprise you're actually talking about people"*. The strongest 2015 articulation of WWSD #1 (democratization). Belongs as the canonical primary-source citation for the principle.
- **And-not-or** as a candidate **new WWSD principle**: *inclusion over substitution*. When the institution wants to retire one tool to make room for another, the WWSD position is *keep both, let them work together*. This is OS X + iOS in 2015; it is also AppleScript + Shortcuts in 2024; it is Automator + App Intents in 2026. Same principle, three eras.
- **Accidental-administrator doctrine** — automate **for** the next human in the chain, not just for yourself. The IT pro builds for the accidental admin. Belongs in the WWSD catalog as the *organizational-scale* version of "user-placed-file = consent." Candidate principle: **delegated authority via shared workflow folder**.
- **Four whys restated** — *speed, accuracy, consistent output, scalability* (2015) matches *consistency, accuracy, speed, scale* (2003). Twelve-year vision-stability confirmed (WWSD #34).
- **Filename / menu-item = trigger** — Scripts menu workflow becomes the organization-wide command surface. Same architecture as 2013 Speakable Workflows (filename = phrase) and 2012 Application Scripts folder (file presence = consent). Three-era convergence on *filesystem-as-API-surface*.
- **Companion-site shadow infrastructure** — `photosautomation.com` / `configautomation.com` / `iworkautomation.com` / `macosxautomation.com` are Sal-curated documentation surfaces existing in parallel to `developer.apple.com`. After 2016 these transition to `macosxautomation.com` (still live) and `cmddconf.com`. **The shadow infrastructure outlives the role.**
- **JXA as peer** — explicitly framed as choice, not replacement: *"if you like working with the JavaScript language"*. Sal refuses the substitution framing for his own toolset. Same and-not-or principle applied internally.

## Reusable for the apple repo

- **`bin/sal-configurator2-recovery.py`** — Configurator 2's Automator action library was a major mid-2010s Sal asset. Worth a Wayback pass to recover `configautomation.com` samples — the 2015 #306 demo workflows (Get Connected Devices → Copy Documents to Devices × N) are the canonical starter set.
- **Accidental-administrator template for the apple repo's documentation** — every `bin/` tool should ship with a *"for the accidental administrator"* one-paragraph README section: assume the user inherited the Mac, knows nothing, just needs the menu item. This is the Sal-2015 framing applied to the apple repo's own audience.
- **And-not-or pattern in `painpoints/`** — when filing painpoints, refuse the substitution framing. The painpoint isn't "App Intents replaced AppleScript" — it's "App Intents and AppleScript don't compose cleanly." Sal-2015 enterprise framing applied to 2026 painpoint analysis.
- **Folder Actions as a current-still-live surface** — the 2015 demo (Drop Box folder → Photos import workflow) still works in Sequoia 2026 with minimal modification. Worth a `bin/folder-action-install.sh` helper that codifies the Sal-2015 pattern: pick folder, pick workflow, install. The drop-files-on-folder UX is *exactly* the 2003 droplet pattern (WWSD #38) at filesystem-level instead of icon-level.
- **Companion-site mirroring** — `photosautomation.com`, `configautomation.com`, `iworkautomation.com`, `macosxautomation.com` should all be Wayback-mirrored under `sources/sal/sites/` if not already. They are the post-Apple Sal documentation lineage.
- **"Spell, Sal, spell." as a verbatim signature** — worth saving in `sources/sal/signatures.md` (if that file gets created) alongside *"sick, sick, sick"* (2013) and *"some days I feel like a dinosaur looking for a tar pit"* (2012/2015). These are voice-fingerprint phrases for Sal-tagged content discovery.
- **Track "thank you for being part of this experience for me"** — file this verbatim line in `analysis/sal/correspondence/` notes as the closing line of Sal's final WWDC appearance, dated June 2015. Reference for any future Sal-tribute / Sal-context writing.

## Verbatim Sal-voice signatures

- *"Some days I feel like I'm a dinosaur looking for a tar pit, but today is not one of those days."*
- *"When you talk about an enterprise you're actually talking about people."*
- *"Don't solve everything with a hammer because then all of the problems appear to be nails."*
- *"The success of an organization depends upon the strategy of and, not or."*
- *"They act on your behalf with all the authority that you have as a user."*
- *"This will be the first time I'm demoing this, it's the first time anybody has seen this, and you guys are the ones that are going to see it."*
- *"I'll bet you most of you didn't realize that stuff was actually in the OS, huh?"*
- *"We call them, like, accidental administrators."*
- *"Spell, Sal, spell."*
- *"Thank you so much for being part of this experience for me."*
