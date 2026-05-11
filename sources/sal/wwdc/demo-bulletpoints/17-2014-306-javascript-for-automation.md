# WWDC 2014 #306 — JavaScript for Automation

**Speakers:** Sal Soghoian + David Steinberg · **52:33** · Track: Services
**nonstrict:** https://nonstrict.eu/wwdcindex/wwdc2014/306/
**PDF:** https://devstreaming-cdn.apple.com/videos/wwdc/2014/306xxjtg7uz13v0/306/306_javascript_for_automation.pdf (204 pages)

## The pitch — JXA arrives

**JavaScript becomes a peer language to AppleScript on the OSA bus.** Same Apple Events, same Cocoa Scripting, same Object Models — JavaScript syntax over the top.

This is the **JXA launch session**. Sal frames + does the Mavericks-to-Yosemite arc. Steinberg does the engineering deep-dive.

## Sal's two-year arc framing

Mavericks (2013) shipped: notifications, code-signing, AppleScript Libraries. Yosemite (2014) ships: JXA, dictation commands, speakable workflows.

**Apple was investing in automation surfaces every year from 2013-2014.** Sal's enterprise patrons are visible — the Configurator team, the iWork team, the Final Cut team — all making sure scriptability survives.

## The flagship demo — Keynote batch export in JXA

```javascript
var Keynote = Application('Keynote')
var Progress = $.NSProgress.alloc.init
Progress.totalUnitCount = Keynote.documents.length

Keynote.documents.forEach(function(doc) {
    var outPath = Path('/tmp/' + doc.name() + '.pdf')
    Keynote.export(doc, {as: 'PDF', to: outPath})
    Progress.completedUnitCount++
})
```

What it shows:
- **`Application('Keynote')`** — bind to a running scriptable app
- **Array methods on AE elements** — `.documents.forEach` works like a JS array
- **`Path()`** — collapses AppleScript's five-reference-type matrix to one constructor
- **Record syntax for named parameters** — `{as: 'PDF', to: outPath}` replaces AppleScript's `using export settings`
- **`$.NSProgress`** — the `$` ObjC bridge, alive on the same bus as JXA

## The tri-lingual Dictionary viewer

Script Editor 2 (Yosemite) lets you open any sdef and view it in **three dialects simultaneously: AppleScript, JavaScript, Objective-C**. Switch with a popup. Same dictionary, three syntaxes.

**This is Apple acknowledging the dictionary IS the truth, and the languages are skins.**

## The five identifier forms

```javascript
Application('Safari')                       // by name
Application('com.apple.mail')               // by bundle ID
Application('/Applications/TextEdit.app')   // by path
Application(763)                            // by process ID
Application.currentApplication()            // by current process
```

Same five identifier types AppleScript has had since Tiger.

## The four syntactic surfaces

| Surface | Example |
|---------|---------|
| **Property** | `Safari.name`, `doc.url()` (getter), `doc.url = '...'` (setter) |
| **Element collection** | `Safari.documents[0]`, `Safari.windows['Apple']`, `Safari.windows['#412']` (by ID) |
| **Command** | `Safari.open(...)`, `message.reply({replyAll: true})` |
| **Class constructor** | `TextEdit.Document({text: 'Hello'})`, `TextEdit.documents.push(doc)` |

## The killer feature — `.whose({...})` queries

```javascript
Mail.inbox.messages.whose({subject: 'JavaScript'})
```

That's `every message of inbox of application "Mail" whose subject is "JavaScript"` in record syntax. Comparators are `_`-prefixed: `{age: {_greaterThan: 30}}`, `{name: {_contains: 'Smith'}}`.

**Sal's 2003 "cleaning and waxing" principle (WWSD #36) reborn in JavaScript.** Query + act in one expression.

## Applet event handlers

```javascript
function run() { /* launched without files */ }
function openDocuments(docs) { /* file-drop */ }
function printDocuments(docs) { /* print-to-app */ }
function idle() { return 60; /* called every 60s */ }
function reopen() { /* dock icon click while running */ }
function quit() { /* return false to cancel */ }
```

**Same six event hooks AppleScript applets have had since System 7.** The 1991 droplet model ports verbatim.

## Libraries

`~/Library/Script Libraries/toolbox.scpt` becomes:

```javascript
var toolbox = Library('toolbox')
toolbox.log('hello world')
```

**Libraries are bilingual** — same .scpt callable from either AppleScript or JXA.

## UI Scripting

```javascript
var SE = Application('System Events')
var notes = SE.processes['Notes']
notes.windows[0].buttons[0].click()
SE.keystroke('m', {using: 'command down'})
```

**Built on Accessibility, same APIs since Panther 2003.** Carries the 2003 #401 "last resort" warning forward silently (WWSD #35).

## The headline — the `$` ObjC bridge (★ the architectural delta)

> *"Every NSClassName is reachable as `$.ClassName`."*

```javascript
var str = $.NSString.alloc.initWithUTF8String('bar')
str.writeToFileAtomically('/tmp/foo', true)
```

**Translation rule:** strip colons from ObjC selectors, camel-case, pass args positionally. `writeToFile:atomically:` → `writeToFileAtomically(...)`.

Bridge ops:
- `ObjC.wrap(...)`, `ObjC.unwrap(...)`, `ObjC.deepUnwrap(...)`
- `ObjC.import('Cocoa')` — load a framework

`$()` = bridged nil. Check with `obj.isNil()`.

### Subclassing — define new ObjC classes from JavaScript

```javascript
ObjC.registerSubclass({
    name: 'AppDelegate',
    superclass: 'NSObject',
    protocols: ['NSApplicationDelegate'],
    properties: { window: 'id' },
    methods: {
        'applicationDidFinishLaunching:': {
            types: ['void', ['id']],
            implementation: function(notification) {
                $.NSLog('App finished launching')
            }
        }
    }
})
```

**JXA can be a Cocoa app's full delegate.** Implement NSWindowDelegate, NSTableViewDataSource, anything. Real ObjC classes visible to the Cocoa runtime, JavaScript implementation.

**This is the 2014 fulfillment of Sal's 2003 "AppleScript should never be the ceiling" pitch (`call method` bridge).** Eleven years apart, the architectural pattern lands.

## Where to use JXA — same six surfaces

1. **Script Editor**
2. **Applets/Droplets** (osacompile)
3. **Script Menu**
4. **Automator** — Run JavaScript action
5. **Services** — JXA in workflows
6. **osascript -l JavaScript** — CLI

## Sal's three calls to action

- *Script applications.*
- *Make your applications scriptable.*
- ***Tell others to make their applications scriptable.***

**The third is pure Sal.** Audience-as-evangelism. 2014 restatement of WWSD #1.

## Power features delivered

- **JavaScript as peer language** on OSA bus (with AppleScript, ObjC scripting bridge, Perl, Python, Ruby)
- **`Path()` constructor** collapses 5-reference-type matrix
- **`.whose({...})`** queries with `_`-prefixed comparators
- **Tri-lingual Dictionary viewer** in Script Editor 2
- **`$` ObjC bridge** — full Cocoa runtime from JavaScript
- **`ObjC.registerSubclass`** — define new ObjC classes at runtime
- **6 applet event handlers** — same model as AppleScript since System 7
- **Cross-dialect libraries** — same .scpt callable from AppleScript or JXA
- **`osascript -l JavaScript`** CLI

## Marketing copy version

**Headline:** JavaScript is now a peer language on macOS. Same Apple Events, same scripting bus, same 1991 droplet model — JavaScript syntax. Plus: full ObjC runtime via `$`, including `registerSubclass` to define new Cocoa classes from JS at runtime.

**Audience takeaway:** if you already know JavaScript, the entire macOS automation surface is now available to you. If you already know AppleScript, JXA collapses the coercion matrix (`Path()` replaces the five reference types) and gives you the ObjC bridge without `call method` ceremony.
