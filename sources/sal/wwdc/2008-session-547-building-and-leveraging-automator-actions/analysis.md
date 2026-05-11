# WWDC 2008 Session 547 — Building and Leveraging Automator Actions (Analysis)

**Speakers:** Kerry Hazelgren (Automator Engineering Manager) + Emilie Kim ("Automator ninja") + Sal Soghoian (third-party-developer intro) + Michael Silva (Savant Systems guest demo)
**Era:** Snow Leopard (Mac OS X 10.6) preview, last session before the beer bash
**Source:** https://nonstrict.eu/wwdcindex/wwdc2008/547/

## Framing — the developer-facing pitch

This is **not a Sal-led session.** Sal appears only in the final third to introduce Savant Systems. The session is the *Automator team's* developer-facing pitch. The structural significance: 2007 Session 224 sold Scripting Bridge to AppleScript people; 2008 Session 547 sells Automator-as-plug-in-architecture to Objective-C people. Emilie's opening line is the giveaway:

> *"There is a common misconception that automator is simply a front end for AppleScript… this is false. Automator is not a front end to AppleScript."*

**Developer-audience inoculation** — Apple sees Cocoa developers dismissing Automator as an AppleScript GUI, and Emilie is killing that perception in the first three minutes.

## What the session covers

### 1. The three action types — and what's new in Snow Leopard
| Type | Language | Xcode template |
|------|----------|---------------|
| Cocoa | Objective-C, subclass `AMBundleAction`, override `runWithInput:` | Cocoa |
| AppleScript | `on run {input, parameters}` handler | AppleScript |
| ShellScript | bash/ruby/python/perl, stdin → stdout | Shell Script |

Snow Leopard changes: 64-bit only (Cocoa), garbage collection, custom UTIs, dynamic input/output types (`selectedInputType`/`selectedOutputType`), determinate progress (`progressValue`).

### 2. The Unix-pipe mental model
> *"You can kind of think of this workflow as a set of Unix pipes. You have a bunch of commands, and then data flows through them as they would in pipes."*

**The simplest correct conceptual model of Automator ever given on-record at WWDC** — and it's given by an engineer, not by Sal. Recipe metaphor for end users; pipe metaphor for developers.

### 3. Action-UI guidelines (Aqua-compliance enforcement)
- Small controls, small labels, 10px border
- Two Automator-specific IB controls: `AMTokenField` (variable-aware text input) and `AMPathPopUpButton` (pre-populated locations)
- Progress indicators, output previews

Emilie's structural principle:
> *"If you find your action has five tabs and a tab view, and each tab has its own functionality and its own set of controls, maybe that means your action should actually be five separate actions."*

**Candidate WWSD principle: #43 — One action, one verb; if you have a tab view, you have five actions.**

### 4. Demo 1 — Carrie's three actions
1. **Find Images** — shell script, `mdfind` Pictures
2. **Convert Images to Letterbox Format** — AppleScript action with `NSPopUpButton` bound via Cocoa Bindings to `parameters["conversionMethod"]`
3. **Adjust Gamma** — pre-existing Cocoa action retrofit for Snow Leopard (32/64 universal, GC, three lines for progressValue, 10.6 SDK)

The **irreversible-operation flag**: actions declare destructive intent in plist; Automator auto-inserts `Copy Finder Items` before them. **Consent-by-framework**: someone other than the user-at-runtime makes the safety visible.

### 5. `AMWorkflow` / `AMWorkflowController` / `AMWorkflowView` recap
Same three classes as 2007, now with a year of API maturity. Kerry's Sketch demo: workflow with `Take Video Snapshot`, seven lines of code, picture-taker feature added. **The 2007 Sal ambition shipped.**

### 6. Sal's Savant introduction — the validating use case
Sal: *"This developer has built their own actions for their application and integrated workflows application to do something that was just so incredible."*

Savant Systems = Mac-based whole-house home-automation (touch panels, lighting, AV, Apple TV). Their Blueprint software lets installers wire rooms schematically. **Every button on every Savant touch-panel UI is bound to an Automator workflow.** Installers add lighting dim, amplifier warm-up pauses, with drag-drop. **No code, no script — drag-drop reconfiguration of a $100k home automation install.**

> *"We're not limited to using just savant-built automator actions. We can use any automator action."*

**Architectural endpoint of Sal's 2007 plug-in-universe pitch**, one year later, with a real commercial product proving it works. 2008 dogfood validation of WWSD #1 (democratization).

## WWSD-relevant takeaways
- **Unix-pipe pedagogy** — Emilie's stdin/stdout-typed-pipeline model is the cleanest engineer-facing description of Automator on record.
- **One verb per action** — Candidate **#43 — Decompose composite UIs into atomic actions.** Same rule for AppleScript handlers, Shortcuts, Hey-Sal verbs.
- **Irreversible-operation flag = consent-by-framework** — developer's plist declaration is the consent surface; Automator inserts the safeguard. Compare to 2012's user-placed-file-as-consent: *different mechanism, same principle.*
- **Cocoa Bindings into parameters dictionary** — distillation of WWSD #38 droplet-with-preferences into a developer API.
- **Automator-as-plug-in-architecture proven by Savant** — 2007 pitched it, 2008 demoed it commercially. Direct dogfood evidence for WWSD #1.

## Reusable for the apple repo
- **Custom action templates** — Xcode still ships them. `bin/new-action.sh` wrapper scaffolds Cocoa/AppleScript/Shell actions from apple-repo terminology.
- **Unix-pipe metaphor for `bin/workflow-gen.py`** — `--pipe-doc` flag emits pipe-style annotated diagram.
- **`AMTokenField` survives** — variable-aware token text field embeddable in custom exporters that need variable-aware filename templating.
- **Determinate progress in shell actions** — `progressValue` is AppleScript-scriptable; recipe in `workflow-gen.py` for any list-processing action.
- **`AMWorkflow` from JXA** — `ObjC.import('Automator')` + `+[AMWorkflow runWorkflowAtURL:input:error:]`. Single-line workflow exec from `osascript -l JavaScript`. Direct ancestor of Hey-Sal voice-route-to-workflow.
- **Savant pattern for Renoise/Paketti** — every Renoise UI button already bound to Lua; insert a `.workflow`-equivalent layer (Lua workflow files) and users drag-reconfigure Paketti behaviors.
- **"Irreversible operation = insert Copy Finder Items"** — generalize as `--safe` flag on destructive `bin/`-tool wrappers; copy-to-`/tmp/<tool>-backup/` before modifying.
