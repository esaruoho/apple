# WWDC 2007 #224 — Next Generation Automation

**Speaker:** Sal Soghoian (solo) · **47:27** · Track: Leopard Innovations
**nonstrict:** https://nonstrict.eu/wwdcindex/wwdc2007/224/

## The pitch

Title is signal — Leopard's "next generation" of automation = **Services as a first-class workflow surface, Automator workflows as services, Cocoa scripting maturity**.

## What's covered — the Leopard automation big picture

### Workflows-as-Services

The headline shift: **any Automator workflow can be installed as a system Service.** Drop the .workflow into `~/Library/Services/` (or `/Library/Services/`), Automator's "Save as Service" menu writes it there.

Result: every app that supports Services (~every Cocoa app + a lot of Carbon) gets your workflow in:
- The application menu's Services submenu
- The contextual menu when right-clicking selected content
- Bound to a keyboard shortcut via System Prefs → Keyboard

**This is the moment Automator stops being a standalone app and becomes a platform.**

### Service input/output

The Service contract:
- **Input** — selected text, selected file(s), no input, or contextual data
- **Output** — replace selection, paste replacement, open in new doc, do nothing
- **Filter applications** — restrict which apps see the service
- **Filter file types** — only show service when the selection matches

Sal demos: select an address in TextEdit → right-click → Services → "Add to Address Book" → contact created.

### Variables in workflows (new for Leopard)

Pre-Leopard: each action took the previous action's output. Linear chains only.
Leopard adds **variables** — store an output, refer to it later. Branch + reuse.

- `Set Value of Variable` action
- `Get Value of Variable` action
- `Show Variables` reveal — the workflow editor's new bottom drawer

Demo: workflow grabs current date → stores as `today` → multiple branches reference `today` later (rename folder, set Finder comment, write to filename).

### Cocoa Scripting maturity

- **`NSScriptCommand` improvements** — better error reporting, subject parameter, considering/ignoring
- **Direct property handling** — your `scriptable` properties get auto-handlers, no glue code
- **Coercion sugar** — implicit conversions between common types

### Automator action recording

**You can now record yourself doing a task in the Finder/an app, and Automator generates the workflow.** Record button in the toolbar. Captures GUI Scripting steps. Sal flags this with the same warnings as 2003 #401 — last-resort, fragile, get real scriptability instead — but acknowledges it as a learning tool.

## Sal's voice signature

> *"Next generation automation means automation that doesn't just sit in Automator. It sits everywhere on your Mac."*

This is the **services-everywhere** doctrine — automation surfaces multiply in Leopard.

## Power features delivered

- **Workflows-as-Services** — every Automator workflow is a system-wide command
- **Workflow variables** — non-linear chains, store + reuse outputs
- **Service input/output filtering** — fine-grained context activation
- **Automator action recording** — GUI Scripting capture (with caveats)
- **Cocoa Scripting maturity** — fewer hoops to make an app scriptable
- **Keyboard binding for Services** via System Prefs

## Marketing copy version

**Headline:** Your Automator workflow doesn't have to stay in Automator. Ship it as a Service — and the right-click menu of every app on the user's Mac picks it up.

**Audience takeaway:** if you build any kind of selection-based or file-based tool, the Services pipeline turns one workflow into instant integration with every Cocoa app. The user binds it to a keyboard shortcut, never opens your tool's UI again — and you've delivered the smallest possible automation surface that scales the widest.
