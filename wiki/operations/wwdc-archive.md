---
name: WWDC Sal archive complete (17 sessions, 2003-2015)
description: Status of the WWDC Sal Soghoian archive — 17 confirmed sessions captured with transcript+analysis, 21 inferred sessions enumerated for future passes, five-pillar canon, WWSD #31-45
type: project
originSessionId: f28a1d2b-4331-43e3-9b69-6e7756ffc44e
---
The WWDC Sal Soghoian archive at `sources/sal/wwdc/` contains **17 confirmed sessions across 13 years (2003-2015)**, each with metadata.md + transcript.md + analysis.md. Plus a WWDC PDF for 2014 #306 (204 pages).

**Why:** primary-source spoken Sal on Apple's own stage, predating the existing 2012-2023 interview corpus by 9 years. Sal was eliminated October 2016; WWDC 2016 had no Sal session. The 2015 #306 transcript is the last primary-source on-stage Sal.

**How to apply:** When the user mentions Sal, WWDC, or any specific automation feature (AppleScript Libraries, Automator, Services, JXA, NSUserScriptTask, QuickTime Player Pro scripting), the WWDC archive is the primary reference. Cross-check against `sources/sal/wwdc/README.md` for the master index + the synthesis section.

## The 17 sessions

| Year | # | Title | Captured |
|------|---|-------|----------|
| 2003 | 306 | AppleScript Studio | metadata + transcript + analysis |
| 2003 | 401 | AppleScript Update (Panther) | ★ |
| 2003 | 623 | AppleScript for SysAdmins (Sal solo masterclass) | ★ unlisted on apple.com |
| 2003 | 718 | AppleScript and QuickTime | ★ |
| 2004 | 723 | A Powerful Combination: AppleScript and QuickTime | ★ |
| 2005 | 138 | AppleScript for C, C++, and Java Programmers | ★ |
| 2007 | 206 | Building Automator Actions | ★ |
| 2007 | 224 | Next Generation Automation | ★ |
| 2008 | 547 | Building and Leveraging Automator Actions | ★ |
| 2009 | 607 | Using Services in Snow Leopard for Scripting IT Tasks | ★ |
| 2010 | 302 | Automating the Creation of iPad Content | ★ |
| 2011 | 133 | Lion-Sized Automation | ★ |
| 2012 | 206 | Secure Automation Techniques in OS X | ★ |
| 2013 | 416 | Introducing AppleScript Libraries | ★ |
| 2013 | 417 | OS X Automation Update (Mavericks) | ★ |
| 2014 | 306 | JavaScript for Automation | **PDF 204pp** + 2-part analysis |
| 2015 | 306 | Supporting the Enterprise with OS X Automation | ★ **Sal's last WWDC** |

Plus 22 Sal-team sessions captured for archival completeness (2003-2009 Automator/AppleScript/Scripting talks where Sal's team led but Sal himself was not on stage). All 22 transcripts under `sources/sal/wwdc/<year>-session-<num>-*/`. **Sal-presence verified by grep across all 22: none feature Sal as a speaker.** The 17 Sal-on-stage corpus IS complete. The 22 Sal-team sessions contribute no new WWSD principles — they're kept for institutional context (Sal as named resource: "go talk to Sal Soghoian, our product manager").

## The five-pillar canon (the structural model Sal taught at WWDC)

1. **AppleScript** (1993)
2. **Automator** (2004)
3. **Services** (2009 redesign)
4. **Terminal** (2011 induction — WWDC 2011 #133)
5. **JXA** (2014 — WWDC 2014 #306)

Load-bearing structure for probing future Apple OS versions: which pillar has been removed, neutered, or relocated?

## WWSD canon now 45 principles (was 27)

- Tier 0 (#1-11): philosophy + biographical
- Tier 0+ (#12): hallway-pitch
- Tier 1 (#13-27): 2012-2023 interviews
- Tier 2 (#28-30): WWDC 2016 session 717 (which is actually WWDC 2018)
- **Tier 3 (#31-38): 2003 WWDC sessions** — peer-to-Aqua, hands-and-fingers, four whys, vision-stability, GUI-scripting-last-resort, cleaning-and-waxing, entire-contents recursion, droplet-with-preferences
- **Tier 4 (#39-45): 2007-2015 WWDC sessions** — user-placed-file=consent, some-powers-belong-to-the-user, time-as-meta-why, index-by-data-type, one-verb-per-action, four-Cs-Point-of-Need, one-mechanism-scales-from-selection-to-fleet

Source docs:
- `analysis/sal/wwsd-updates-from-2003-transcripts.md` (Tier 3 proposal)
- `analysis/sal/wwsd-updates-from-2007-2015-transcripts.md` (Tier 4 proposal)
- `sal-soghoian.md` (canonical, updated to 45 principles)

## Correction: WWDC 2016 #717 is actually WWDC 2018 #717

The legacy folder `sources/sal/wwdc2016-session-717/` actually contains the WWDC **2018** Workflow→Shortcuts announcement session. Sal was already eliminated by 2018. Apple announced the successor technology without him. **There is no WWDC 2016 Sal session.**

## QuickTime Player 7 Pro vs QT Player X scriptability cliff

WWDC 2003 #718 + WWDC 2004 #723 cover QT Player **7 Pro** scripting — annotations (40 fields), chapter manipulation, track-level operations, HREF embedding, media skins, `current matrix`, `save export settings` (.qtex). **Modern QuickTime Player X has had its sdef drastically stripped.** The 150-script QuickTime Scripts collection mostly does not work on Sequoia QT Player X.

If you still have QT 7 Pro on a legacy Mac (10.6-10.11), the 2003/2004 scripts work verbatim. Otherwise: drop to `avconvert`/`ffmpeg`/AVFoundation via Swift one-liners for the things QT Player X can't do.

Full reference: `sources/sal/wwdc/demo-bulletpoints/01-QUICKTIME-PRO-AUTOMATION.md`.
