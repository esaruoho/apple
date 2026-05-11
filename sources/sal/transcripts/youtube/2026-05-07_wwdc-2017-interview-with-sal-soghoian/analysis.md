# WWDC 2017 Interview with Sal Soghoian (Alt Conf, Mac Observer)

**Speakers:** Jeff Gamet (Mac Observer interviewer) + Sal Soghoian
**Length:** ~5 minutes (103-line transcript)
**Context:** Alt Conf, running alongside WWDC 2017 in San Jose. Sal's first Alt Conf appearance. **Eight months after the October 2016 elimination from Apple.**
**Audit attestation:** every quoted phrase below verified verbatim by direct read of transcript.txt by Esa's auditor on 2026-05-11.

## The historical position

This is **post-Apple Sal**, eight months after the firing. He's at Alt Conf, not WWDC proper. He's talking about **Omni Automation** — his collaboration with the Omni Group on JavaScript-based scripting for OmniGraffle, OmniFocus, OmniOutliner across Mac OS AND iOS.

The structural significance: **Sal extended JXA's architecture (his last Apple WWDC announcement, 2014 #306) into a third-party shipping product** — Omni Automation. The very pattern Apple shipped in 2014 with him, he continued to build with the Omni Group after Apple cut him.

## Sal's framing — Omni Automation as cross-platform JavaScript

> *"I'm here to talk about Omni Automation, which is a technology that's been working with the Omni Group of JavaScript for scripting their applications on both Mac OS and iOS."*

> *"The same script will work on both of them. It's based upon JavaScript core that ships with WebKit."*

The cross-platform line is the headline: **one script, both platforms**. JXA on Mac (2014) was Mac-only. Omni Automation generalizes the pattern to iOS via the same `JavaScriptCore` framework available on every Apple device.

## The flagship demo — OmniGraffle US states heat map

> *"I had a stencil in OmniGraffle that was a map of the United States... individual state objects on a page in OmniGraffle, but I went to a webpage and tapped a button, and it executed an Omni Automation script that extracted information about each state from the table on the page and dynamically colorized each state based upon the level of information that corresponded to it on the web page and it happens in a fraction of a second."*

The pipeline:
1. OmniGraffle document open with US states stencil
2. Webpage with data table for each state
3. User taps button on webpage
4. Webpage invokes Omni Automation script via URL format
5. Script reads webpage table, colorizes states in OmniGraffle by value
6. **Heat map appears in OmniGraffle in a fraction of a second**

**This is the 2017 incarnation of Sal's 2010 #302 "AppleScript as CGI" pattern** — webpage drives Mac app via embedded script invocation. Different stack (HTML+JS instead of CGI+AppleScript), same architectural shape.

## The plugin model — "tap a link on a webpage"

> *"These type of automation tools can be created as plugins to Omni applications and you can just tap a link on a web page or double click a file and have that installed into your app and it becomes part of your environment."*

**Plugins via URL.** The user doesn't write JavaScript. They tap a link. The script installs into the app and becomes available.

This is **Sal's 2013 #416 "AppleScript Libraries" pattern lifted to 2017's web era**:
- 2013: drop a .scptd into `~/Library/Script Libraries/`
- 2017: tap a webpage link → plugin installs into Omni app

Same idea: ship-via-place-a-file (or URL invocation) → script becomes a verb the user can call.

## Sal-voice signature quotes

> *"You can use it without knowing anything... you could just take advantage of it."*

User-author principle (WWSD #1 democratization) explicitly stated post-Apple. Sal is still telling the same story.

> *"Omni-automation.com is where I'm hanging out."*

Post-Apple Sal's center of gravity: **his own website** with **hundreds of scripts**. The institution is gone; the relationship persists (WWSD #20).

## WWSD-relevant takeaways

- **WWSD #1 (democratization) survives the firing.** Sal still pitches "you can use it without knowing anything" eight months after the elimination. The principle is structural, not org-chart-dependent.
- **WWSD #20 (institution is not the relationship).** ProGuide 2023 source-quoted this principle to MTC2019; the 2017 interview pre-dates that articulation by 2 years and operationally enacts the same idea — Sal continues the WWSD project on a different stage.
- **WWSD #43 (one verb per action) gets a Real-world plugin embodiment.** Omni Automation plugins are atomic: tap-link → one new verb. Composition is the user's job.
- **JXA's $ ObjC bridge generalizes to JavaScriptCore-on-iOS.** Sal's 2014 #306 architecture wasn't Mac-bound; the iOS extension was already implicit. Omni Automation is the proof.
- **No new WWSD principles needed.** The interview reaffirms #1, #20, and #38 (config-via-link generalization). No #46+ candidate.

## Reusable for the apple repo

- **Omni Automation as a JXA archive target.** Sal's Omni-automation.com hosts hundreds of his post-Apple scripts. Worth mirroring under `sources/sal/omni-automation/` for the same reasons macosxautomation.com is mirrored — it's primary-source Sal-authored automation. Wayback + live scrape.
- **Webpage-as-trigger pattern.** The OmniGraffle US-states demo is **directly portable to BBS/Cloudcity**: webpage tab + tap → AppleScript/JXA invocation → Renoise/Loupedeck/Logic responds. Same architectural ancestor as the Hey Sal v1 matcher (single phrase → N targets).
- **Plugin-via-URL distribution model.** Worth a `bin/install-jxa-plugin.py` that takes a URL or .scpt path and drops into the target app's `Contents/Resources/Script Libraries/` (per 2013 #416) — closing the distribution loop Sal modeled here for non-Omni apps.
- **The post-Apple-Sal lineage anchor.** This interview is the **first primary-source post-Apple Sal in the WWSD canon**. It dates Sal's commercial continuation to ~June 2017 (Alt Conf). Worth a `analysis/sal/post-apple-timeline.md` companion document.

## Audit footer — verbatim quote verification

All quotes used in this analysis verified by direct character match against transcript.txt:

| Quote | Line in transcript |
|-------|-------------------|
| *"I'm here to talk about Omni Automation..."* | 18-19 |
| *"The same script will work on both of them..."* | 22-23 |
| *"It's based upon JavaScript core that ships with WebKit"* | 23-24 |
| *"I had a stencil in OmniGraffle that was a map of the United States..."* | 44-53 |
| *"These type of automation tools can be created as plugins..."* | 58-61 |
| *"You can use it without knowing anything..."* | 58 |
| *"Omni-automation.com is where I'm hanging out"* | 89-90 |

No paraphrasing in quote marks. No interpretive layering presented as quotes. The interpretation (post-Apple anchor, cross-decade lineage links to 2013 #416 / 2014 #306 / 2010 #302) is mine, layered on top of verified-real lines.
