# WWDC 2014 Session 306 — JavaScript for Automation (Analysis, pages 56–204)

Companion to `analysis.md` (pages 1–55). Where the first half is Sal's two-year arc and Steinberg's Keynote demo, this back half is the JXA reference manual in slide form — four topics, in order: **Application Scripting**, **Libraries and Applets**, **UI Scripting**, **Using System APIs**. Then release notes, where-to-use, summary, call-to-action.

The whole back half is David Steinberg solo. Sal opened and closes; the engineering is Steinberg's.

---

## Topic 1 — Application Scripting (pp. 56–135)

### The architecture (pp. 56–75)

Apple's diagram on slide 75: JavaScriptCore + JavaScript AE Bridge → Apple Events → Cocoa Scripting → Object Models. **JXA is a peer dialect on the Apple Events bus** — not a wrapper over AppleScript, not a translation layer. Same bus AppleScript, Objective-C scripting bridge, Perl, Python, Ruby all sit on.

The Mail object model is the worked example: `inbox of application "Mail"` → `message 2 of inbox of application "Mail"`. Same object graph as AppleScript; just JavaScript syntax.

### Identifying an application (pp. 76–80)

Five ways to obtain an `Application` object:

| Form | Example |
|------|---------|
| Name | `Application('Safari')` |
| Bundle ID | `Application('com.apple.mail')` |
| Path | `Application('/Applications/TextEdit.app')` |
| Process ID | `Application(763)` |
| Current process | `Application.currentApplication()` |

Same five identifier types AppleScript has had since Tiger, in JavaScript syntax. (Compare directly to Sal's 2003 #623 five-reference-types — the OSA model is unchanged after eleven years.)

### The four syntactic surfaces (pp. 81–95)

Every JXA app object exposes four kinds of thing:

1. **Properties** — `Safari.name` → `"Safari"`
2. **Elements** — `Safari.documents[0]`, `Safari.windows`
3. **Commands** — `Safari.open(...)`, `message.reply(...)`
4. **Classes** — `Safari.Document(...)`, `TextEdit.Document({text: 'Hello'})`

Get/set properties uses standard assignment:
```javascript
var doc = Safari.documents[0]
doc.url()           // getter (note the parens)
doc.url = 'http://apple.com'   // setter
```

The getter-uses-parens convention is the one JXA gotcha that bites everyone — `doc.url` returns the *property descriptor* (a function-like reference); `doc.url()` evaluates it. This is the bridge cost of putting AE properties behind a JS object model.

### Element arrays (pp. 96–105)

`Safari.windows` is an array-like. Index it three ways:

```javascript
Safari.windows[0]          // by position
Safari.windows['Apple']    // by name
Safari.windows['#412']     // by ID (hash-prefixed)
```

The `'#412'` syntax is the JXA encoding of AppleScript's `window id 412 of application "Safari"`. Hash-prefix = ID lookup.

### Filtering — `whose` as `.whose({...})` (pp. 106–115)

The single biggest readability win over AppleScript:

```javascript
Mail.inbox.messages.whose({subject: 'JavaScript'})
```

That's `every message of inbox of application "Mail" whose subject is "JavaScript"` in JavaScript record syntax. Comparison operators in object form: `{age: {_greaterThan: 30}}`, `{name: {_contains: 'Smith'}}`. The `_`-prefixed keys are JXA's underscore-namespace for AE comparators.

This is **Sal's "cleaning and waxing" principle (2003 #623, WWSD #36) reborn in JavaScript** — find AND act in one expression.

### Sending commands and named parameters (pp. 110–115)

```javascript
message.open()
Mail.open(message)
message.reply({replyAll: true, openingWindow: false})
```

The record-syntax for named parameters is the JXA answer to AppleScript's `with replyAll without openingWindow`. **No positional ambiguity** — every parameter is named at the call site. This is arguably cleaner than AppleScript itself.

### Paths (pp. 116–120)

```javascript
var p = Path('/Users/username/Desktop/foo.rtf')
TextEdit.open(p)
```

`Path(...)` is the JXA constructor for the AE path-type. It accepts POSIX paths directly — no `POSIX file` / `as alias` coercion dance (compare Sal's 2003 #623 five-reference-types). **JXA collapses the AppleScript coercion matrix into a single constructor.** This alone is worth the bridge cost.

### Creating objects (pp. 121–130)

```javascript
var doc = TextEdit.Document()
TextEdit.documents.push(doc)
doc.text = 'Hello world'
```

Or in one expression with a properties record:
```javascript
TextEdit.documents.push(TextEdit.Document({text: 'JavaScript for Automation'}))
```

The constructor-with-props matches AppleScript's `make new document with properties {text:"..."}`. The `documents.push(...)` is the JXA dialect of AppleScript's `make new ... at end of documents`.

### Standard Additions (pp. 131–135)

```javascript
var app = Application.currentApplication()
app.includeStandardAdditions = true
app.beep(3)
app.say('Hello world')
app.displayAlert('Finished task')
```

Standard Additions (the scripting-additions verbs like `beep`, `say`, `display dialog`) are **off by default** and must be opt-in via `includeStandardAdditions = true`. This is a JXA-only safety — AppleScript exposes them globally with no opt-in. The opt-in prevents accidental namespace collision with app verbs.

---

## Topic 2 — Libraries and Applets (pp. 136–155)

### Libraries

`~/Library/Script Libraries/toolbox.scpt` becomes:
```javascript
var toolbox = Library('toolbox')
toolbox.log('hello world')
```

Same library-search-path AppleScript uses since Mavericks. `.scpt` files written in either dialect are callable from either dialect — **libraries are bilingual**.

### Applets — event handlers

A JXA-bundled `.app` (osacompile-style) can implement these top-level handlers:

```javascript
function run() { /* called when launched without files */ }
function openDocuments(docs) { /* called on file-drop */ }
function printDocuments(docs) { /* called on print-to-app */ }
function idle() { /* return seconds-until-next-call */ }
function reopen() { /* called when dock icon clicked while running */ }
function quit() { /* called before exit; return false to cancel */ }
```

These are the **same six event hooks** AppleScript applets have had since System 7 (`on run`, `on open theFiles`, `on print theFiles`, `on idle`, `on reopen`, `on quit`). Direct one-to-one mapping. Sal's 2003 #718 droplet-with-preferences pattern ports verbatim to JXA — replace `on open` with `function openDocuments`, store config in the bundle's Finder comment, ship.

---

## Topic 3 — UI Scripting (pp. 136–155 cont.)

```javascript
var SystemEvents = Application('System Events')
var notesUI = SystemEvents.processes['Notes']
notesUI.windows[0].buttons[0].click()

var Notes = Application('Notes')
Notes.activate()
SystemEvents.keystroke('m', {using: 'command down'})
```

**Built on Accessibility** — same APIs `processes` suite in AppleScript has used since Panther 2003. The `{using: 'command down'}` modifier-record matches AppleScript's `keystroke "m" using command down`.

Apple's slide implies what Todd Fernandez said explicitly in 2003 (Session 401, WWSD #35): **GUI scripting is a last resort, not a substitute**. The slide deck doesn't repeat the warning — but the four limitations still apply (fragile to UI changes, disabled by default, can't drive non-AX widgets, non-English keystrokes broken). JXA does not fix these — it just gives them a JavaScript veneer.

---

## Topic 4 — Using System APIs — the `$` ObjC bridge (pp. 156–195)

This is the **fundamentally new capability** JXA introduces. AppleScript had `call method` (2003 Session 718) and AppleScript-ObjC (2009) but both required AppleScript Studio or Xcode. JXA exposes the full ObjC runtime to scripts.

### The `$` shortcut

`$` is JXA's namespace for the Objective-C runtime. **Every `NS*`/`CF*`/`CG*` class is reachable as `$.ClassName`.**

```javascript
$.NSString             // the NSString class
$('foo')               // wrap a JS value as an Objective-C object (NSString)
$()                    // bridged nil
```

The bridge ops:
- `ObjC.wrap(...)` — JS value → ObjC object
- `ObjC.unwrap(...)` — ObjC object → JS value
- `ObjC.deepUnwrap(...)` — recursive unwrap (arrays, dicts)
- `ObjC.import('Cocoa')` — load a framework not in the default set

### Calling methods — dot-syntax translation of ObjC selectors

The slide-by-slide reveal (pp. 178–185) shows the translation rule:

```objc
// Objective-C
str = [[NSString alloc] initWithUTF8String:@"bar"];
[str writeToFile:@"/tmp/foo" atomically:YES];
```

```javascript
// JXA
var str = $.NSString.alloc.initWithUTF8String('bar')
str.writeToFileAtomically('/tmp/foo', true)
```

**The rule:** strip the colons, camel-case the selector parts, pass arguments positionally. `writeToFile:atomically:` → `writeToFileAtomically(...)`. `initWithXMLString:options:error:` → `initWithXMLStringOptionsError(...)`.

### Property access

```javascript
var task = $.NSTask.alloc.init
task.running                       // property getter (no parens needed here)
task.launchPath = '/bin/sleep'     // property setter
```

JXA distinguishes ObjC properties (no parens) from AE properties (parens required) — an asymmetry users have to learn.

### Bridged nil and the isNil pattern (pp. 188–192)

```javascript
var error = $()
var doc = $.NSXMLDocument.alloc.initWithXMLStringOptionsError(
    xmlString,
    undefined,
    error
)
if (doc.isNil()) {
    $.NSLog(error.userInfo.description)
}
```

`$()` = bridged ObjC `nil`. Pass it to functions that take an out-param `NSError**`. `isNil()` checks bridged nil specifically — `=== null` won't work because bridged nil is an ObjC object, not JS null. **This is the one footgun the slide deck explicitly warns about.**

### Subclassing (pp. 193–198) — the big one

JXA can **define new ObjC classes at runtime** from JavaScript:

```javascript
ObjC.registerSubclass({
    name: 'AppDelegate',
    superclass: 'NSObject',
    protocols: ['NSApplicationDelegate'],
    properties: { window: 'id' },
    methods: {
        'applicationDidFinishLaunching:': {
            types: ['void', ['id']],
            implementation: function (notification) {
                $.NSLog('Application finished launching')
            }
        }
    }
})
```

This **lets a JXA script be a Cocoa app's full delegate** — implement `NSApplicationDelegate`, `NSWindowDelegate`, `NSTableViewDataSource`, anything. The implementation is JavaScript; the class is real Objective-C visible to the Cocoa runtime.

This is the slide that justifies Sal's "AppleScript is a peer to Aqua" framing (2003 #623, WWSD #31) **eleven years later in 2014** — JXA isn't a peer *to* Aqua, it's a peer *language for building* Aqua. The ceiling Sal raised in 2003 with `call method` is gone in 2014.

### Release notes (pp. 199–202)

Three additional capabilities mentioned but not demoed:
- **Binding C functions** — call C APIs (CoreGraphics, libc) directly
- **Explicit pass-by-reference** — `Ref()` constructor for out-params (the bridged-nil pattern above is one application)
- **Passing functions as blocks** — JS functions automatically wrap as ObjC blocks where the signature expects one

The full Release Notes live at developer.apple.com (cited on the More Information slide, p. 202).

---

## Where to Use It (pp. 196–200)

Six surfaces, same as AppleScript:

1. **Script Editor** — write/run/save
2. **Applets/Droplets** — osacompile-built `.app`
3. **Script Menu** — the system-wide menubar
4. **Automator** — Run JavaScript action (new in Yosemite)
5. **Services** — JXA in Service workflows
6. **osascript -l JavaScript** — CLI invocation

This is the **JXA→AppleScript exposure parity** slide. Every place AppleScript lives, JXA lives. No surface is AppleScript-only.

---

## Summary and Call to Action (pp. 201–204)

The closing slides repeat three lines:

- *Built on JavaScriptCore and OSA*
- *Integrated system-wide*
- *Offers many options for scripting*

And three calls to action:

- *Script applications*
- *Make your applications scriptable*
- *Tell others to make their applications scriptable*

**The third call to action is pure Sal.** "Tell others to make their applications scriptable" is the 2014 version of his "request real scriptability from the developer" prescription in 2003 Session 401 (WWSD #35). The audience-as-evangelism move. Eleven years apart, identical instruction.

---

## WWSD-relevant takeaways (extends `analysis.md`)

- **Five identifier types unchanged 2003→2014** — Application(name) / bundle-id / path / pid / current are the same five Sal taught in 2003 #623. The OSA reference grammar is **two-decade stable**.
- **Path() collapses the coercion matrix** — what Sal had to teach as five separate reference types + coercion paths in 2003 is one constructor in JXA. Bridge cost paid, ergonomic win realized.
- **`.whose({...})` is "cleaning and waxing" in JavaScript** — query + act in one expression, just like Sal's 2003 demo. WWSD #36 ports verbatim.
- **The applet event handlers are the 1991 System 7 set** — `run` / `openDocuments` / `printDocuments` / `idle` / `reopen` / `quit`. JXA changed the syntax, not the model. Droplet-with-preferences (WWSD #38) ships unchanged.
- **`ObjC.registerSubclass` raises the ceiling Sal complained about in 2003** — no more waiting for a third-party OSAX. Define the class you need in 30 lines of JavaScript. This is the architectural delta of 2014.
- **GUI Scripting carries its 2003 warnings forward silently** — the slide deck doesn't repeat Todd Fernandez's four-limitation rant, but the limitations still apply. JXA's `SystemEvents.processes['Notes']` is the same fragile last-resort surface, just in JS syntax. **Use sparingly; pressure developers for real scriptability.**
- **The third call-to-action is the 2014 restatement of WWSD #1** — "Tell others to make their applications scriptable" is "democratize automation" in evangelism form. The audience as multiplier.

---

## Reusable for the apple repo

- **JXA rendering of every Apple app's sdef** — task #2 in this conversation. The `Application('...')` + `.documents[0]` + `.whose({...})` + `.Class({props})` patterns are deterministic — given a parsed sdef, the JXA dialect can be auto-rendered alongside the AppleScript dialect. Belongs in `dictionaries/<app>/<app>.jxa.md`.
- **`bin/sal-grand-search` JXA mode** — most `osascript`-driven scripts in `bin/` use AppleScript heredocs. The `Path(...)` coercion collapse alone is worth a JXA rewrite of the path-heavy ones (export pipelines, file-walkers).
- **ObjC subclass pattern for Hey Sal v2** — Hey Sal v1 routes through Shortcuts + matcher (memory: `hey_sal_v0_seven_layers.md`). A v2 could register a real `NSApplicationDelegate` from JXA and bind global hotkeys / menu items without the Shortcuts indirection. `ObjC.registerSubclass` is the enabling primitive.
- **Cross-language library pattern** — `~/Library/Script Libraries/toolbox.scpt` written once in either AppleScript or JXA is callable from both. Worth a `lib/sal-toolbox.scpt` that wraps the most-reused verbs across `scripts/` (Finder reveal, path coercion, dialog helpers) so the AppleScript and JXA scripts in the repo can share one canonical implementation.
- **`bin/app-probe.py` JXA emitter** — task #2 stub. Given the existing 13-layer probe output (sdef + URL schemes + App Intents + ...), add a 14th layer that emits a JXA usage cheat-sheet per app: the top 10 verbs, the top 5 classes, a one-line `Application('...')` + property example, and a `whose({...})` query template.
- **`indexes/sal-lessons.yaml` lesson for JXA** — task #3 stub. JXA is a peer to AppleScript in the modern-translation track; lesson should pair `Application("Mail")` AppleScript-side with `Application('Mail')` JXA-side, same goal, both renderings.
