# WWDC 2009 #607 — Using Services in Snow Leopard for Scripting IT Tasks

**Speakers:** Sal Soghoian + Steve Hayman · **45:55** · Track: Mac
**nonstrict:** https://nonstrict.eu/wwdcindex/wwdc2009/607/

## The pitch — Point-of-Need

> *"Computers are the most powerful for us when the tools that we need are nearby the things that we have selected. We call this Point-of-Need."*

The session's WWSD-grade unit. Automation should live in the immediate vicinity of the user's selection — not in a menu bar, not in a separate app.

## The four C's (Sal's mnemonic)

| C | Snow Leopard Services delivers |
|---|-------------------------------|
| **Contextual** | Services menu filters by selected data type |
| **Convenient** | Three Finder surfaces; text-aware in Safari/iChat/Terminal |
| **Configurable** | First-ever per-Service enable/disable + keyboard shortcut |
| **Customizable** | **Automator now builds Services** as first-class workflow template |

> *"If you meet any press people, you go, I must tell you about Services. They are contextual, convenient, configurable, and customizable. You will write on this, yes you will."*

## Demos

### Sal: Automator → Service path
1. New workflow → **Service template**
2. Pick input data type (text, files, no input)
3. Pick target app filter (or "any")
4. Drag actions → "output replaces selection"
5. Save → `~/Library/Services/<name>.workflow`
6. Right-click → service appears

### Hayman: NeXTSTEP 3.3 demo via VMware
Runs the original *Open Sesame* Services that let an ordinary user re-open a file as root. He co-wrote it. Historical depth — Services as architecture predates Mac OS X by a decade.

### Hayman: Three IT scenarios
1. **Personal admin** — Service "open Terminal CD'd to selected Finder folder"
2. **Fleet management** — SSH to all selected ARD machines; prompt for shell command, run as root on all
3. **Client cooperation** — sort selected text (one-line shell); check in homework files

> *"You can sit in here for a Remote Desktop and just type commands all the time and they're suddenly being spread across all these different computers."*

**Fleet-management-by-keystroke, 2009.**

## Power features delivered

- **AppleScriptObjC (ASOC)** ships in Snow Leopard — AppleScript calls any Cocoa class/method directly
- **Services as Automator workflow target** — every workflow can be a Service
- **Per-Service keyboard shortcuts** in System Preferences
- **Apple Event-based fleet command pattern** (SSH + ARD + Services)
- **macosxautomation.com soft-launch** — Sal announces the website that becomes his post-Apple platform

## The iPhone-fed-the-Mac trick

> *"With the smaller area to work with and one of these required as the input device, it made us rethink our whole strategy."*

**Sal explicitly credits the iPhone for forcing the Point-of-Need rethink.** Eight years before Catalyst (2018) made the reverse-flow narrative official.

## Marketing copy version

**Headline:** Stop hunting for tools. The tool comes to you. Snow Leopard's redesigned Services architecture puts every automation action one right-click away from whatever you've got selected.

**Audience takeaway:** if you write Automator workflows, ship them as Services. Every Cocoa app on the user's Mac picks them up automatically — and the user binds them to a keyboard shortcut, never opens your tool's UI again.
