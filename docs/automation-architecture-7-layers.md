---
layout: default
title: "Apple's Automation Architecture — 7 Layers"
---

# Apple's Automation Architecture — 7 Layers


[← Back to home](./)
Discovered through framework analysis:

```
Layer 1: Apple Events / OSA        ← osascript, OSAKit, ScriptingBridge, AppleScriptObjC (DEPTH)
Layer 2: Automator                  ← AMWorkflow, AMAction
Layer 3: Intents (legacy, ObjC)     ← INIntent, 14 apps
Layer 4: AppIntents (modern, Swift) ← 82 protocols, 23 apps (WIDTH)
Layer 5: Shortcuts/WorkflowKit      ← Visual composition of Layer 4
Layer 6: Siri/AssistantSchema       ← Natural language routing
Layer 7: Apple Intelligence         ← GenerativeAssistantActions
```

The `shortcuts run` CLI is the bridge: Layer 1 scripts can invoke Layer 4-6 actions.

**Layer 1 nuance:** *ScriptingBridge* (Cocoa → AppleScript, used from Swift/ObjC) and *AppleScriptObjC* (AppleScript → Cocoa, used from `.applescript` files) are opposite directions of the same bridge. ASObjC is the most powerful Apple-native automation surface on the system — see [asobjc.md](asobjc.md).

**160+ private frameworks** power the automation stack internally, including 80+ Siri frameworks, WorkflowKit (Shortcuts engine), ActionKit, and bridge frameworks like `_Photos_AppIntents`.
