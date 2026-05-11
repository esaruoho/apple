# WWDC 2013 #416 — Introducing AppleScript Libraries

**Speakers:** Chris Page + Sal Soghoian · **53:00** · Track: Tools (OS X)
**Mavericks · 20th anniversary of AppleScript (1993-2013)**
**nonstrict:** https://nonstrict.eu/wwdcindex/wwdc2013/416/

## The pitch — AppleScript grows up

**Three architectural pieces solve a 20-year pain — user-authored libraries as first-class citizens:**

1. **`~/Library/Script Libraries/`** — drop a `.applescript` or `.scptd`, it becomes globally addressable
2. **`script <name>` reference syntax** — replaces `load script` with file-references
3. **`use <library>` clause** — top-of-script directive that pulls library verbs into the global namespace

Plus the bonus: **for the first time at WWDC ever, a live walk-through of authoring an `.sdef`.** Sal makes hand-authoring of scripting dictionaries publicly teachable.

## Sal's framing — the code-maven confession

> *"I'm one of those kind of people that is a code maven, I have sampled routines that do just about everything and I have them all over the place on my drives. I like to use routines and handlers in my scripts quite a bit instead of writing code over and over."*

**The product is the answer to Sal's own workflow pain.** WWSD-grade move — the engineering brief comes from the product manager's filesystem mess.

## Why not `load script`? Four shortcomings

- Exact file location known up front — fragile across machines
- Explicit loading every time, into a variable, then `tell` to
- Handler names known by heart — no English-like verbs
- No ASOC — couldn't call Cocoa from a loaded script

## Demo arc

### 1. The simple library — pure AppleScript

Teaching example: transform text case. AppleScript has no built-in `uppercase`. Sal authors a handler:

```applescript
on change case of text source_text given case indicator:caseIndicator
    -- iterate characters
    return result
end change case of text
```

Save as `AppleScript Text Transform.applescript` → drop in `~/Library/Script Libraries/`. Call:

```applescript
tell script "AppleScript Text Transform"
    change case of text "how now brown cow" given case indicator:1
end tell
```

### 2. The ASOC library — script bundle

Pure-AppleScript can't handle Unicode. Switch to ASOC:

```applescript
set cocoaString to current application's NSString's stringWithString:source_text
set adjusted to cocoaString's uppercaseString()
return adjusted as text
```

Save as `.scptd` (script bundle), tick "Uses AppleScript-ObjC". Unicode works (`hów nów bröwn ców`).

### 3. The `.sdef` walk-through (★ the headline)

Sal wants:
```applescript
transform text "how now brown cow" to upper case
```

To get that, the library publishes its own terminology. Sal authors the .sdef live:

```xml
<dictionary>
  <suite name="Text Utilities" code="TXTU">
    <command name="transform text" code="TXTUtxfm">
      <documentation><html><![CDATA[
        <p>Apply text transformation:</p>
        <pre>transform text "..." to upper case</pre>
      ]]></html></documentation>
      <direct-parameter type="text"/>
      <parameter name="to" code="ccnv" type="case conversion"/>
      <result type="text"/>
    </command>
    <enumeration name="case conversion" code="ECNV">
      <enumerator name="upper case" code="ECup"/>
      <enumerator name="lower case" code="EClo"/>
      <enumerator name="word case" code="ECwd"/>
    </enumeration>
  </suite>
</dictionary>
```

Rules Sal teaches:
- **Four-char codes:** Apple reserves lowercase, user codes uppercase
- **8-char command codes:** first 4 = suite, second 4 = command-specific
- **`<documentation>` with HTML inside CDATA** renders in Dictionary viewer
- **Direct parameter** = the noun the verb acts on; **named parameter** needs name + code

Drag .sdef into bundle Resources, point bundle drawer at it, save. Library now has a dictionary.

### 4. The `use` clause — making it top-level

```applescript
use script "AppleScript Text Utilities"
use scripting additions

tell application "Finder"
    set selectedItems to selection
    repeat with anItem in selectedItems
        set name of anItem to transform text (name of anItem) to upper case
    end repeat
end tell
```

**`use` loads the library globally.** Verbs are indistinguishable from built-in AppleScript verbs. The `tell` to the library disappears entirely.

## Five deployment paths

1. `~/Library/Script Libraries/` (per-user)
2. `/Library/Script Libraries/` (per-machine)
3. `/Network/Library/Script Libraries/` (enterprise)
4. Inside any **script bundle**'s `Contents/Resources/Script Libraries/`
5. Inside any **application bundle**'s `Contents/Resources/Script Libraries/`

The 5th path: **distribute a single `.app` that bundles its libraries internally.** User installs, libraries come with it, no setup.

## The 20th-anniversary close

> *"20 years ago AppleScript was given to the world. We want to take this opportunity to say thank you to all of the developers that made their apps scriptable. We want to say thank you to all the scriptors who wrote and write scripts everyday and share them with others. We want to thank our customers for using AppleScript and in addition we want to thank all of the engineers that worked on scriptable applications and worked at Apple."*

**Four constituencies in order: developers + scripters + customers + engineers.** The community model Sal holds through his entire Apple tenure. **Three years before he gets fired**, he is on stage thanking everyone who made AppleScript work.

## Power features delivered

- **`~/Library/Script Libraries/`** — global library search path
- **`script "<name>"` reference syntax** — auto-located libraries
- **`use` clause** — verbs become first-class language extensions
- **Library terminology via .sdef** — user verbs as legitimate as Apple's
- **Script bundle (`.scptd`) format** with ASOC checkbox
- **App-bundle-as-automation-module pattern** — libraries inside `Contents/Resources/Script Libraries/`

## Marketing copy version

**Headline:** AppleScript got a module system. Drop your reusable handlers in `~/Library/Script Libraries/`. Add `use script "MyLib"` to the top of any script. Your verbs are now first-class. Plus: hand-author your own scripting dictionary — *"it's just an XML file."*

**Audience takeaway:** stop copy-pasting handlers between scripts. Author a library once, deploy it five ways (user / system / network / inside-bundle / inside-app). Publish a terminology and your verbs read like English. On AppleScript's 20th birthday, Sal makes the language extensible by users for the first time.
