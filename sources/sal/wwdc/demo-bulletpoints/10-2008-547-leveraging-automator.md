# WWDC 2008 #547 — Building and Leveraging Automator Actions

**Speakers:** Kerry Hazelgren, Emilie Kim, Sal Soghoian, Michael Silva · **50:46** · Track: Integration
**nonstrict:** https://nonstrict.eu/wwdcindex/wwdc2008/547/

> Snow Leopard era. Sal's full automation team on stage together. Two-part talk: build actions (Hazelgren) + leverage Automator inside your own app (Silva).

## The pitch

> *"Automator lets ordinary users create extraordinary automated workflows through an intuitive drag-and-drop interface. By working with Automator, your application can become part of complex, business-critical tasks in ways you never thought possible."*

## What's covered

### Part 1 — Building actions (Hazelgren + Kim)

Refresher + Snow Leopard additions:

- **Action templates in Xcode** for AppleScript, Cocoa-AS, Cocoa Obj-C, shell, Python, Ruby, Perl
- **`AMWorkflow`** — Cocoa class for running workflows
- **Better progress reporting** — indeterminate + determinate + cancellation hooks
- **Default values** — declare reasonable defaults in Info.plist so the action works out-of-the-box
- **Action variables** as first-class inputs (callback to 2007 #224's variables intro)

### Part 2 — Leveraging Automator inside your app (Michael Silva — ★ the headline)

**Your app can host the Automator engine.** Embed workflow execution into your shipping product:

```objc
NSURL *workflowURL = [NSURL fileURLWithPath:path];
NSError *error;
NSDictionary *output = [AMWorkflow runWorkflowAtURL:workflowURL
                                          withInput:myInput
                                              error:&error];
```

That's it. Your app shipped a folder of pre-baked .workflow files. The user picks one from your UI. Your app runs it. The user gets the result. They never opened Automator.

**Use cases Sal pitches:**
- A photo app that ships "Resize for Email", "Resize for Web", "Resize for Print" workflows as user-selectable presets
- A video tool that ships transcode workflows
- A document app with "Send to PDF Reviewers", "Archive to Read-Later" workflows

### Workflow editor inside your app

You can ALSO embed the **Automator workflow editor** as an NSView in your own app, letting users customize the workflows you ship.

- `AMWorkflowController` — the controller class
- `AMWorkflowView` — the editor view
- Hand-pick which action categories to expose (don't show "Internet" actions in a video tool)

### Sandbox prep (forward signal)

This session is two years before Mountain Lion's sandbox, but the architecture hints are visible: **workflows run in their own process**, app sends input, gets output. This decouples app stability from action behavior — and presages the 2012 #206 NSUserScriptTask architecture.

## Sal-team voice

The four-presenter format is interesting — Sal frames, Hazelgren teaches, Silva delivers the headline (embedded Automator), Kim handles Q&A. Different from the solo-Sal masterclasses; this is **product team mode**.

## Power features delivered

- **Embedded workflow execution** via `AMWorkflow` Cocoa API — your app runs Automator workflows in-process
- **Embedded workflow editor** via `AMWorkflowView` / `AMWorkflowController`
- **Scripting-language action templates** for Ruby/Python/Perl/shell maturity
- **Workflow variables** as first-class action inputs
- **Action defaults** declared in Info.plist for out-of-box usability
- **Progress + cancel hooks** for long-running actions

## Marketing copy version

**Headline:** Your app can be its own Automator — ship pre-baked workflows as user-selectable actions, run them in-process, let power users customize via the embedded editor.

**Audience takeaway:** if you ship a Cocoa app with any kind of preset/template/workflow concept, `AMWorkflow` collapses your boilerplate. Don't write your own "scripting" mechanism — embed Automator's. Your power users already know the editor. Your normal users see a clean dropdown of presets.
