# WWDC 2007 Session 224 — Next Generation Automation (Analysis)

**Speaker:** Sal Soghoian (Product Manager, Automation Technologies — title introduced *in this session*)
**Era:** Leopard (Mac OS X 10.5) preview
**Source:** https://nonstrict.eu/wwdcindex/wwdc2007/224/

## Sal's framing — automation as time-recovery

> *"We can all accumulate money, we can accumulate — wait — we could accumulate all kinds of things. But we can't accumulate more time. And the only way you get time is automation."*

This is the first WWDC recording in which Sal articulates **time** as the fifth "why" beyond the 2003 four whys (consistency / accuracy / speed / scale). Time is the *meta-why*. It's also the moment his title shifts from "Product Manager for AppleScript" to **Product Manager for Automation Technologies** — the title under which he was fired in 2016. *"Saul, who y'all know"* — Steve Jobs' nickname for Sal, on-record.

## What Sal covers

### 1. AppleScript in Leopard — "It's plumbing"
> *"Every so often you get those operating system releases where you don't see the glorious frosting features or candles. We really just go in and, like, tear out walls and fix plumbing and fix wiring."*

- 64-bit support, full Unicode, modernized SDEFs (dynamic, synonym elements, embedded code samples)
- Real error messages replacing `NSReceiverEvaluationScriptError 4` with `Document 1, invalid index`
- New application object model: address by POSIX path, bundle ID, four-character code; new intrinsics `version`, `id`, `frontmost`, `running`
- Read/write property lists (no more `do shell script defaults …`)
- Reliable folder actions (own process, runs from filesystem)
- *"Thanks to Steve. We have current documentation that will be current with Leopard."*
- Image Events `pad color`, Script Editor string compression, new scriptable Dock/Network/Accounts/iChat

### 2. Scripting Bridge — the architectural headline
> *"The system is built upon Apple events. And that will never go away in Mac OS X."*

Pre-Leopard: `NSAppleEventDescriptor` (fast but requires unpublished four-character codes) or `NSAppleScript` (string-of-AppleScript, slow). Scripting Bridge collapses both: `sdp` generates header files, link the framework, *"there is no step three."* Demo of fetching current iTunes track in Objective-C, **PyObjC**, **RubyCocoa**, AppleScript — same Apple Event, four languages. **The pluralization of automation languages on macOS happens here in 2007**, seven years before JXA.

> *"They were joined by the guys who write Objective-C, and they were joined by of the guys that write Ruby, and they were joined by the guys that write Python."*

Automation as coalition-building — Scripting Bridge brings allies who outnumber the developers resisting scriptability.

### 3. Microsoft Office side-note
Microsoft Office 2008-for-Mac drops Visual Basic, ships with AppleScript + Automator support. Paul Berkowitz writes a 150-page MacTech VB→AppleScript conversion guide. Third-party validation of WWSD #31 (AppleScript as peer to Aqua).

### 4. Automator 2.0 — the maturity release
- **Starting Points** — sheet-drop assistant categorized by *data type*, not by app
- **Streamlined interface** — actions by category, slide-in popovers for description/log/variables, built-in Media Picker
- **In-action data accessors** — Results / Options / Description inline
- **Workflow Variables** — named, system-aware (current IP, user name, today's date), draggable into pop-ups/text fields
- **Watch Me Do** — UI recording via Accessibility framework, last-resort fallback

Sal explicitly orders the fallback ladder:
> *"You can then convince your developer that I really need this. If you're not going to give me this, then give me scripting dictionary. Otherwise I will camp out on your yard and I will never go away."*

**Primary-source articulation of WWSD #35 (GUI scripting as last resort).** Recording is leverage against the developer to ship a dictionary.

### 5. Automator Frameworks — the hidden headline
> *"The knock-out feature… the hidden feature of this release."*

`AMWorkflow` (load+run, one line), `AMWorkflowController` (data in, monitor), `AMWorkflowView` (drop Automator's editor view into your app). Demo: button → `Take Video Snapshot` action → photo path returned. *"I didn't have to write any of the video code."*

> *"That is if it's what I think it is, it's dangerous… If I want to add Quartz Composer into my application, I don't have to write Quartz Composer code… I can take any third party app that supports Automator actions and have them inside of my own app."*

**Automator as universal plug-in framework for macOS** — direct ancestor of App Extensions (2014) and App Intents (2020).

### 6. The customer-loyalty argument
> *"Once you give them automation, they're yours. You have loyal customers forever."*

Business argument for automation aimed at developers, not users. Scriptability is retention.

## WWSD-relevant takeaways
- **Time as the fifth why** — Candidate WWSD principle: **#41 — Automation buys back time, the one resource that doesn't accumulate.**
- **Categorize by data type, not by application** — Starting Points UX reform. Candidate **#42 — Index automations by what the user has selected, not by which app provides them.**
- **GUI scripting as ladder rung, not endpoint** — explicit primary-source for WWSD #35.
- **Scripting Bridge as coalition** — pluralizing host languages buys political mass for scriptability.
- **Automator Frameworks = plug-in architecture without code** — direct ancestor of App Extensions / App Intents.

## Reusable for the apple repo
- **`sdp` header generation** — `bin/sdef-extract.py` could add `--bridge` flag emitting ObjC/Swift/Python headers from the 31 captured sdefs.
- **Starting Points pattern for `apple-grand-search`** — categorize captured automations by data type, not source app.
- **Workflow Variables in shell** — `bin/workflow-gen.py` recipes could ship with `@@current-ip@@`, `@@today@@`, `@@user-fullname@@` placeholders expanded at run time.
- **Watch Me Do equivalent for Loupedeck** — accessibility recording + osacompile output. Fallback ladder: sdef-first, recording-last.
- **`AMWorkflow` survives in Sequoia** — `/System/Library/Frameworks/Automator.framework`. A `bin/run-workflow.py` (PyObjC) wrapper would resurrect the universal-plug-in vision.
- **Sal-voice signature:** *"It's plumbing"* — tag for structural-not-user-visible painpoints.
