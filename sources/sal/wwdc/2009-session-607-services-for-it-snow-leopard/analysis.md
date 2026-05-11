# WWDC 2009 Session 607 — Using Services in Snow Leopard for Scripting IT Tasks (Analysis)

**Speakers:** Sal Soghoian (framing + Services architecture + end-user demos) + Steve Hayman (IT scenarios + ARD/SSH demos + NeXTSTEP nostalgia)
**Era:** Snow Leopard (Mac OS X 10.6) — day after keynote, balloon-pop callback from Phil Schiller demo
**Source:** https://nonstrict.eu/wwdcindex/wwdc2009/607/

## Sal's framing — Point-of-Need

> *"Computers are the most powerful for us when the tools that we need are nearby the things that we have selected, and are pertinent to the items that we have selected, so that they work on that kind of data and we're not bothered with other choices and other options that get in the way of our flow of thought. And we call this Point-of-Need."*

**Point-of-Need is the WWSD-grade unit of this session.** Sal's clearest articulation of *where automation should live in space* — not in a menu bar, not in a separate app, but in the immediate vicinity of the user's selection. Spatial complement to the four whys + the 2007 time why: *automation buys you time, and it has to live where your attention already is.*

Sal's characterization of pre-Snow-Leopard Services: *"It's been delivered in a manner that looks pretty much like a dorm room closet… pseudo-contextual in that some of the things that are grayed out changed to be some other things that are grayed out. It's not convenient, it's not configurable, it's not customizable, and it's just downright messy."*

## What Sal and Hayman cover

### 1. The four C's — Contextual, Convenient, Configurable, Customizable

Sal's mnemonic, drilled in: *"so that if you meet any press people, you go, I must tell you about Services. They are contextual, convenient, configurable, and customizable. You will write on this, yes you will."*

| C | What it means in Snow Leopard |
|---|------------------------------|
| **Contextual** | Services menu filters by selected data type via Data Detectors |
| **Convenient** | Three surfaces in Finder; text-aware in Safari/iChat/Terminal |
| **Configurable** | First-ever per-Service enable/disable + **keyboard shortcut assignment** |
| **Customizable** | **Automator can now build Services** as first-class workflow template |

Automator → Service path: new workflow → Service template → input data type + target app + "output replaces selection" → drag actions → save → `~/Library/Services/<name>.workflow`.

### 2. The iPhone framing trick
> *"With the smaller area to work with and one of these required as the input device, it made us rethink our whole strategy about delivering functionality to the user."*

**Sal explicitly credits the iPhone for forcing the Point-of-Need rethink.** Primary-source on-record acknowledgement that mobile constraints fed back into desktop UX in the Snow Leopard era — eight years before Catalyst (2018) made the reverse-flow narrative official.

### 3. Hayman's NeXTSTEP nostalgia and IT framing
Steve Hayman runs **a live NeXTSTEP 3.3 demo** (via VMware) of the original *Open Sesame* Services that let an ordinary user re-open a file as root via Services menu. He co-wrote it — *"with this other guy. I don't know what happened to the other guy."* (Alphabetical order = Hayman first.)

Three IT scenarios:
1. **Tools for your own admin work** — Service opens Terminal CD'd to selected Finder folder
2. **Tools for managing other computers** — SSH to all selected ARD machines; prompt for UNIX command and run as root on all selected (`rm -rf ~Nader` joke)
3. **Tools for client cooperation** — sort selected text (one-line shell `sort`); check in homework files to server folder

Hayman's `do shell script` vs `do script in Terminal` confusion mid-demo is preserved verbatim — **AppleScript footgun on-record from Apple's own demo.**

> *"You can sit in here for a Remote Desktop and just type-- type commands all the time and they're suddenly being spread across all these different computers."*

**Fleet-management-by-keystroke, 2009.**

### 4. The post-Services tool ladder
Sal closes with the next rung:
- `Run Shell Script` action (bash/zsh/perl/python/ruby)
- `Run AppleScript` action
- **AppleScript-Cocoa (AppleScriptObjC)** — new in Snow Leopard, AppleScript can call *any* Cocoa framework call directly
- Custom Automator actions (Cocoa / Shell / AppleScript templates)

> *"Not only can you call the shell using the do shell script command, now you can just get straight at any Cocoa call."*

**AppleScriptObjC is AppleScript's last major capability expansion before Sal's firing in 2016.** 2009 is the primary-source announcement. Closes the bridge 2003's `call method` hinted at — *AppleScript's verb set is now the union of all Cocoa.*

### 5. The macosxautomation.com soft-launch
> *"I want you to go to macosxautomation.com. It's a great website, new website, and it hosts AppleScript and Services and it hosts Automator. Complete sites for each one of those."*

**On-record launch announcement of macosxautomation.com** — the site that became Sal's personal automation platform after he left Apple in 2016. **2009 is the foundational date for the archive currently being recovered into `sources/sal/macosxautomation/`.** Sal also previews `macosxautomation.com/training` — precursor lineage to his commercial post-Apple training work.

## WWSD-relevant takeaways
- **Point-of-Need** — Candidate **#44 — Automation must live within reach of the selection.** Failure mode: menu bar dumping ground. Any automation surface requiring the user to leave their current focus is broken-by-design.
- **The four C's** — belongs in the WWSD canon as the **evaluation rubric for any automation UI**. `painpoints/` write-ups can score Apple apps against the four C's in 2026.
- **iPhone-fed-back-into-Mac** — on-record primary source for mobile→desktop UX feedback. The reverse narrative is more common; the 2009 quote is the rebuttal.
- **Workflow-as-Service installation pattern** — `~/Library/Services/<name>.workflow` still active in Sequoia 2026. Parallel architecture to `~/Library/Application Scripts/<bundle-id>/`; Services folder is the older broader sibling.
- **AppleScriptObjC** — primary-source 2009. Still works in Sequoia.
- **Fleet automation as personal automation** — Hayman's ARD-Service pattern: same Services architecture sorts text *or* runs commands on 8 remote machines. **One mechanism, two scales.** Candidate **#45 — The same automation surface should scale from one selection to a fleet.**

## Reusable for the apple repo
- **`bin/install-service.py`** — install workflow into `~/Library/Services/`, optionally assign keyboard shortcut via `defaults write pbs NSServicesStatus`.
- **Probe `~/Library/Services/` in the bulk-exporter family** — user-Services exporter alongside Notes/Reminders/Voice Memos. Catalog installed Services + bound shortcuts + workflow contents.
- **Four-C evaluation in `painpoints/`** — every write-up scored yes/no/partial across Contextual/Convenient/Configurable/Customizable.
- **AppleScriptObjC recipes** — `bin/workflow-gen.py` `--asoc` flag emits ASOC bridging boilerplate.
- **ARD-style fleet command pattern** — `bin/fleet-do.sh` for SSH-host parallel execution. Loupedeck button binding makes it a hardware-fleet surface.
- **Services-folder watcher** — launchd agent watching `~/Library/Services/`; `bin/services-status.py` reads/writes `~/Library/Preferences/pbs.plist` for backup and version control of Service shortcut bindings.
- **macosxautomation.com archive anchor** — 2009 WWDC is the launch date. Wayback snapshots before June 2009 are pre-Apple-team-resourced. `sources/sal/macosxautomation/` recovery effort can be timeline-anchored against this primary-source date.
- **Sal-voice signature:** *"You will write on this, yes you will."*
