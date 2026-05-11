# WWDC 2013 Session 416 — Introducing AppleScript Libraries (Analysis)

**Speakers:** Sal Soghoian (architecture + the .sdef walk-through) + Chris Page (AppleScript team — live coding the Library + ASOC variant)
**Year:** 2013 (Mac OS X 10.9 Mavericks)
**Source:** https://nonstrict.eu/wwdcindex/wwdc2013/416/

## The historical position

**The AppleScript-Libraries-launch session**, delivered on **the 20th anniversary of AppleScript shipping** (1993 → 2013). Mavericks introduces three architectural pieces that solve a 20-year pain — user-authored libraries as first-class citizens:

1. **`~/Library/Script Libraries/`** — the magic folder. Drop a `.applescript` or `.scptd` here, it becomes globally addressable.
2. **`script <name>` reference syntax** — replaces `load script` with file-references.
3. **`use <library>` clause** — top-of-script directive that loads the library into the global namespace.

Plus the bonus: **for the first time at WWDC ever, a live walk-through of authoring an `.sdef`**. Sal makes hand-authoring of scripting dictionaries publicly teachable.

**This session turns AppleScript into a real programming environment with a module system.**

## Sal's framing — the code-maven confession

> *"Those who were at the first session understand that I'm one of those kind of people that is a code maven, I have sampled routines that do just about everything and I have them all over the place on my drives… I like to use routines and handlers in my scripts quite a bit instead of writing code over and over."*

Sal speaks first as a **user with the problem**, not as the product manager with the solution. *"This real big jumble that you try to manage."* **The product is the answer to Sal's own workflow pain.** WWSD-grade move — the engineering brief comes from the user's filesystem mess.

## What Sal + Chris cover (the substance)

### 1. Why not `load script`? Four shortcomings

> *"This means that there's no custom terminology, you have to remember handler names, you have to remember the order of the various components of the handler and there's no access to the power of AppleScript objective C."*

- Exact file location known up front — fragile across machines
- Explicit loading every time — into a variable, then `tell` to
- Handler names known by heart — no English-like verbs
- No ASOC — couldn't call Cocoa from a loaded script

### 2. The simple library — pure AppleScript path

Teaching example: **transform text case**. AppleScript has no built-in `uppercase` verb. Sal authors a handler, saves as `AppleScript Text Transform.applescript`, drops in `~/Library/Script Libraries/`. Call from a client:

```applescript
tell script "AppleScript Text Transform"
    change case of text "how now brown cow" given case indicator:1
end tell
```

The library reference is the new construct: `script "AppleScript Text Transform"` — no extension, no path, auto-located.

### 3. The ASOC library — script bundle path

Pure-AppleScript can't handle Unicode/accented characters. Switch to ASOC:

```applescript
set cocoaString to current application's NSString's stringWithString:source_text
set adjusted to cocoaString's uppercaseString()
return adjusted as text
```

Save as a **script bundle** (`.scptd`) instead of flat. Bundle drawer exposes name, identifier, version, terminology file, **"Uses AppleScript-ObjC" checkbox**. The accented-`o` test (`hów nów bröwn ców`) proves Unicode works.

### 4. The terminology problem and the `.sdef` walk-through

> *"Remembering the names of 150 or 200 different handlers, that's really a pain. I want to be able to use this kind of terminology."*

Sal wants:

```applescript
transform text "how now brown cow" to upper case
```

To get that, the library has to **publish its own scripting terminology**. *"For the first time ever anywhere — an example of how to create a scripting dictionary."* Sal walks every tag:

```xml
<dictionary>
  <suite name="Text Utilities" code="TXTU" description="...">
    <command name="transform text" code="TXTUtxfm" description="...">
      <documentation><html><![CDATA[
        <p>Apply text transformation, for example:</p>
        <pre>transform text "how now brown cow" to upper case</pre>
      ]]></html></documentation>
      <direct-parameter type="text" description="the text to transform"/>
      <parameter name="to" code="ccnv" type="case conversion" description="..."/>
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

Sal's annotations:
- **Four-character codes** — Apple reserves lowercase; user codes uppercase
- **8-character command codes** — first 4 = suite code, second 4 = command-specific
- **`<documentation>`** — HTML inside CDATA renders in Script Editor's Dictionary viewer
- **Direct vs named parameter** — direct = the noun the verb acts on; named = needs name + code

Drag the `.sdef` into bundle's Resources, point bundle drawer at it, save. Library now has a dictionary.

### 5. The `use` clause — making libraries top-level

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

`use` loads the library **globally**. Verbs are now indistinguishable from built-in AppleScript verbs. The `tell` to the library disappears entirely.

### 6. Five deployment paths

1. `~/Library/Script Libraries/` (per-user)
2. `/Library/Script Libraries/` (per-machine)
3. `/Network/Library/Script Libraries/` (enterprise — sysadmin-managed)
4. Inside any **script bundle**'s `Contents/Resources/Script Libraries/`
5. Inside any **application bundle**'s `Contents/Resources/Script Libraries/`

The fifth path: **distribute a single `.app` that bundles its libraries internally**. Install the app, libraries come with it, no setup.

### 7. The 20th anniversary closing

> *"One more thing, this is a very important day for us because 20 years ago AppleScript was given to the world… we want to take this opportunity on the 20th anniversary to say thank you to all of the developers that made their apps scriptable, we want to say thank you to all the scriptors who wrote and write scripts everyday and share them with others. We want to thank our customers for using AppleScript and in addition we want to thank all of the engineers that worked on scriptable applications and worked at Apple in creating this."*

**Emotional inflection point of the WWSD canon.** Four constituencies in order — developers, scripters, customers, engineers. Three years before he gets fired, here he is on stage publicly thanking everyone.

## Verbatim Sal-voice signatures

- *"You're going to like Libraries, they're going to be useful for you."*
- *"I think once you see how it's done, it's not so frightening, it's pretty easy to do it's just an XML file."*
- *"It's worth it to add that little bit of extra in your scripting definition file when you create it."*
- Chris Page: *"And the slowest part of this is giving it a name."*

## WWSD-relevant takeaways

- **WWSD #1 (democratization) lifted to library authorship.** Users write their own scripting dictionaries. *"It's just an XML file."* The peer-to-Aqua principle (WWSD #31) applied to scripting terminology itself.
- **`use` clause = library-as-vocabulary.** Automation isn't just calling methods, it is **extending the language**. Candidate WWSD #43 — *User vocabularies extend the language, not just the API.*
- **`Contents/Resources/Script Libraries/`** = app-bundle as automation-module. Structural complement to 2012's `~/Library/Application Scripts/<bundle-id>/` (WWSD #39). Bidirectional model: **user** drops scripts into Application Scripts to grant capability **to** apps; **developer** drops libraries into Resources/Script Libraries to extend capability **from** apps.
- **WWSD #34 (vision-stability) sealed by 20th-anniversary speech.** Four-constituency model: developers + scripters + customers + engineers.
- **Code-maven self-confession as engineering brief.** Sal's filesystem mess was the spec.

## Reusable for the apple repo

- **`bin/sdef-author.py`** — port Sal's walk-through into a generator. Inputs: suite, four-char code, commands. Output: `.sdef` ready for a script bundle. Pairs with existing `bin/sdef-extract.py` — **bidirectional sdef toolchain**.
- **`~/Library/Script Libraries/` probe** — `bin/sal-script-libraries-probe.py` enumerates installed libraries, reads bundle identifiers + versions + .sdef terminology. Dual to `bin/app-plist-probe.py` for user-authored automation vocabulary.
- **`use`-clause migration helper** — `bin/applescript-use-migrate.py` scans `scripts/` for `load script` and rewrites to `use` against synthesized libraries.
- **Library + Loupedeck pairing** — ship a single Cocoa AppleScript Applet whose Resources contain 20 mini-libraries. One install, all libraries internal.
- **20th-anniversary speech archival** — extract verbatim into `analysis/sal/twenty-year-speech-2013.md` as canonical-Sal text.
- **Cross-reference to 2012 session 206.** Libraries are the constructive complement to access groups: 2012 = how the OS limits scripts across boundaries; 2013 = how user-authored vocabulary extends scripts within scope. **Read together: the full Sal-era security-and-extensibility model.**
