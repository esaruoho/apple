# WWDC 2007 Session 206 — Building Automator Actions (Analysis)

**Speaker:** Sal Soghoian (solo on stage; Kerry Hazelgren — Automator engineering manager — and Chris Nebel referenced from the audience)
**Year:** 2007 (Leopard pre-release; Automator 2.0 / IB3)
**Source:** https://nonstrict.eu/wwdcindex/wwdc2007/206/
**Note:** Whisper transcript; expect proper-noun homophones ("Apple Script", "Pearl" = Perl, "intriguer" = integer, "Nabiscoesk" for Sal's "Nabisco-esque" demo-action naming joke). This is the **demo-disaster session** — multiple live failures, recovered through transparency and Sal's signature self-deprecation.

## Sal's framing — Automator as **visual programming**

> *"Back in Tiger, we came up with a very interesting and powerful technology that allows users to create automations, kind of like recipes for doing things over and over on their computer. And customers often think of it in their terms as visual programming."*

The framing pivot from 2004's "AppleScript for non-programmers" pitch: by 2007 Automator has its own audience identity. The opening fantasy is verbatim *"computer, I want you to go to a webpage, find all the images on that page, download them to my hard drive, and then put them into iPhoto"* — natural-language task description, which the **workflow** (the recipe) and its **actions** (the steps) make real. This is the **canonical 2007 user-model statement**, and it's the same sentence shape Sal repeats in every later Shortcuts/Automator session. The "Eddy for Best Productivity Software from MacWorld" applause-bait is the social-proof leg of the pitch — Automator-as-tool has industry recognition, not just internal Apple advocacy.

## What Sal covers (the substance)

### 1. Automator actions are Xcode projects

> *"Automator actions are Xcode projects. They're built in Xcode just like all other applications are built in Xcode, all the good applications are built in Xcode."*

The structural delta: a 2007 Automator action is **not a script** — it's an Xcode bundle. Three Xcode templates:

1. **AppleScript-based action** — run code is an `.applescript`
2. **Cocoa-based action** — run code is `.m`/`.h` Objective-C classes
3. **Shell-based action** — run code is a shell script

And the language-bridge claim: *"within AppleScript, you can use the `call method` command to talk to frameworks, or you can use the `do shell script` command to talk to the command line. Or within shell you could use an `osascript` command to send an Apple Event. And… scripting bridge that allows Cocoa and Ruby and Python to be able to send Apple Events to other applications."* Every template can reach every other language. **No verb is unreachable.** This is the architectural completion of the WWSD #1 promise — automation is now language-agnostic.

### 2. Three philosophies for designing actions

Sal names three strategies, deliberately not ranked:

1. **Use Apple Events** — *"It's probably the most used method… simple and fast, very lightweight in its inter-application communication."* The action is a thin wrapper that sends Apple Events to FileMaker / InDesign / Aperture.
2. **Call external code sources** — *"there's a lot of code hanging around in the OS that you can rely on… your action can call that code."* AddressBook framework, command-line utilities (`mdfind` in Sal's later demo).
3. **Call internal code sources** — your own libraries / applications / command-line utilities **bundled inside the action's bundle**. *"It's a bundle. Whatever you want to put in and call internally, you could do."*

> *"With this action, I might use some Apple events. With this action I want to do a little bit more interface, I want to use some objective C."*

The action is **a unit of choice** — pick the philosophy per-action, mix freely. This is WWSD-grade modularity: small composable units, each free to use the most appropriate technology.

### 3. Four places an action can live (deployment)

Sal enumerates:

- `/System/Library/Automator/` — Apple-shipped only, **do not put yours here**
- `/Library/Automator/` — top-level library, system-wide third-party
- `~/Library/Automator/` — per-user
- `<YourApp.app>/Contents/Library/Automator/` — **shipped inside your application bundle**; Launch Services discovers them automatically. *"Aperture uses, Soundtrack Pro uses, the barebones BBEdit uses. A lot of companies put their Automator actions within their own bundle."*
- **Action Pack** — a templated bundle from `automator.us` for third-party developers without a host app. *"To get rid of it or update it, the user just takes the pack and puts it in the trash and then downloads the latest pack."* Drag-and-drop installation, no installer. WWSD #39 (**user-placed-file = consent**) in its 2007 pre-sandbox form.

### 4. Build action #1 — `find images by keyword` (Shell template)

Live build. The shell run-code:

```bash
while read folder_path; do
  mdfind -onlyin "$folder_path" "kMDItemContentType == 'public.jpeg' && kMDItemKeywords == '${keywordString}'"
done
```

Two Sal-grade teaching points buried here:

- **`mdfind` was the 2005 Spotlight CLI** — *"MD find is a shell command that was introduced in Tiger. MD find is for Metadata. It's the spotlight command line tool."* Primary source for the `mdfind` introduction date.
- **Environment-variable parameter binding** — `${keywordString}` is filled at runtime from the parameter declared in Interface Builder. *"This dollar sign bracket keywordString is going to be replaced by whatever the user has typed in there."* This is the **shell action's calling convention** — parameters are env vars, input is stdin, output is stdout.

UI build: drag an **Automator Token Field** onto the action's view (*"a special kind of text field that will take either text or tokens"* — primary source for the 2007 introduction of the workflow-variables-in-text-fields feature), bind its value to a declared parameter named `keywordString`, check **"continuously updates value"** (*"once the user types, it won't accidentally delete that if they tab out of it"* — the famous bind-trap).

Then the target's Info pane: **bundle identifier** (`com.yourcompany.automator.findImagesByKeyword`), name, application association (Preview), category (`AMCategoryPhotos`), icon-name, input type (`NSString` = POSIX path), output type, parameter list (`keywordString` : string).

**The demo fails.** The Spotlight index doesn't see the keywords on the demo machine's image files. Sal's recovery: *"It's not our fault. That's the important thing I've learned in product management. It's not my fault."* (Audience laughter.) **This becomes the running gag of the session.**

### 5. Build action #2 — `select images` (Cocoa template, ImageKit IKImageBrowser)

Sal opens the pre-prepared Objective-C project. Header + main `.m` already filled. The build is in IB3:

- Open the nib
- Drag an **ImageBrowser** (from the new ImageKit framework, *"this window has a translucent effect to it"* — primary source for the IB3 HUD-look introduction)
- Wire **File's Owner → ImageBrowser** as `_browser` outlet (control-drag)
- Wire **ImageBrowser → File's Owner** as `dataSource` (the second wiring fails on Sal's machine — *"I've just been informed that that's a bug. That on some of the demo machines it appears and on some it don't."*)
- Wire **Cancel button → File's Owner** as `cancel:`, **OK button → File's Owner** as `ok:` (control-drag from each button)

**The demo fails again.** The HUD window does appear when Sal copies the pre-built action into `~/Library/Automator/`, but the result gel doesn't display the selected images. *"It is a beta. So this is, you'll get a nice dialogue that actually looks good in real life."* Recovery via grace.

### 6. Build action #3 — `convert images to letterbox format` (AppleScript template)

Same scaffolding. The AppleScript run handler signature Sal teaches verbatim:

```applescript
on run {input, parameters}
    set conversionMethod to |conversionMethod| of parameters
    repeat with imgRef in input
        if conversionMethod is 0 then
            padImage(imgRef)
        else
            cropImage(imgRef)
        end if
    end repeat
    return input
end run
```

Three Sal-grade teaching points:

1. **`input` is auto-coerced from POSIX paths to AppleScript alias references** — *"Automator will pass in this variable called input at the top. A list of file references in alias format. So it'll take the POSIX paths, convert them into an alias reference that AppleScript understands."* The type-coercion-between-actions feature (called out in 2004 #723) is now formalized as **action-level input declaration**: `com.apple.applescript.alias-object`.
2. **`parameters` is a record** — extract values by their parameter-name key, declared in the target's Info pane.
3. **Pipe-delimit parameter names in script bodies** — `|conversionMethod| of parameters` — *"that's to indicate to the script that this is a parameter, just like that. Otherwise it thinks it's a variable."* Primary source for the pipe-delimiter convention.

UI: drag a **pop-up button** (small control per Automator guidelines — *"vertical space is at a premium"*), populate with `pad` / `crop`, bind `selectedIndex` to `conversionMethod` parameter (integer, default 0). The action **uses Image Events** (Sal's 2005 favorite) to actually crop/pad — `tell application "Image Events" to …`.

**This demo works.** Sal's punch line: *"And finally if you use AppleScript it works all the time, so ha."* (Applause.)

### 7. The closing assembly

The three actions chained into one workflow: `Get Specified Finder Items` → `find images by keyword` (skipped due to demo-machine Spotlight bug) → `select images` (HUD picker) → `convert images to letterbox format` (pad or crop) → `Open Images in Preview`. The final letterboxed Corsica sunrise + Monaco coast + Florence Westin Excelsior images appear in Preview, exactly as designed. **Despite three live failures, the assembled workflow works end-to-end.** The demo doesn't recover *in spite of* the failures — it recovers *by being structured as multiple recoverable pieces*. That's WWSD-grade workflow design eating its own dogfood live.

## WWSD-relevant takeaways

- **#1 democratization** — phrased here as *"customers often think of it in their terms as visual programming."* The user-as-programmer claim, with no compiled-language gatekeeping.
- **#31 peer to Aqua** — Automator action's UI is built in **the same Interface Builder used for native Cocoa apps**, with **the same Cocoa Bindings**, with **the same small-control guidelines**. The action is a **peer UI citizen**, not a second-class scripting widget.
- **#33 four whys** — implicit in the deployment story: ship actions inside your app bundle → consistency across installs, accuracy via Launch Services discovery, speed of drag-and-drop install, scale via action packs.
- **#35 GUI scripting last resort** — the Apple Events / external-code / internal-code triad explicitly puts **GUI scripting nowhere**. Three first-class options exist before you'd ever resort to UI scripting.
- **#38 droplet-with-preferences** — the action's parameter dialog is the **modernized droplet-with-preferences pattern**. Same intent (per-instance config), better surface (real UI bound to typed parameters), no Finder-comment hack.
- **#39 user-placed-file = consent** — Action Packs are pure user-placed-file consent: drop the bundle anywhere on disk, Launch Services + Automator discover it, no installer, no privilege escalation. Primary source for the pattern five years before Sal would formalize it in the 2012 sandbox talk.
- **Candidate principle: graceful-failure-as-feature** — Sal's demo recovery isn't accidental; the workflow's **action-level granularity makes partial failure recoverable**. If a step fails, you bypass it and continue. *"That's okay. We can bypass this action anyway."* This is WWSD-grade error-locality — failures stay within their action, not the workflow. Worth a named principle: **#42 — fail at the action boundary, not the workflow boundary**.

## Reusable for the apple repo

- **`bin/automator-action-scaffold.py`** — emit an Xcode project scaffold for any of the three templates (AppleScript/Cocoa/Shell) with the parameter-binding boilerplate pre-wired. Same niche `bin/workflow-gen.py` fills for inline scripts; this would fill the persistent-action niche.
- **The `on run {input, parameters}` template** — every AppleScript in `bin/spotlight-export` / `bin/shortcut-gen` should be wrappable as an Automator action by adding this handler. A `--as-action` flag on the existing generators would emit the runnable Automator action bundle directly. Recovers the 2007-era deployment surface for the 2026 `bin/` tools.
- **Action Pack as portable distribution** — the 2007 Action Pack template (bundle with auto-update from website) is the **pre-Notarization equivalent** of `bin/spotlight-export`'s ad-hoc-codesigned `.app` bundles. Worth investigating whether Sequoia 2026 still honors Action Packs without Notarization (memory's Spotlight TCC fix suggests yes, with ad-hoc codesign).
- **The pipe-delimited parameter convention** — `|conversionMethod| of parameters` — should be the recommended pattern in every `bin/` AppleScript that takes runtime parameters. Currently most scripts use positional `do shell script` args; the pipe-convention is more readable and survives reflection.
- **`mdfind` + `kMDItemContentType` + `kMDItemKeywords`** combo from Sal's shell action is directly portable to `bin/sal-grand-search` — the apple-grand-search tool currently uses Spotlight but doesn't accept arbitrary `kMDItem*` predicates. Adding a `--mdquery '<raw-mdfind-expr>'` mode is one afternoon's work and unlocks the entire Spotlight metadata vocabulary.
- **The graceful-failure stance for `painpoints/`** — when an Apple app's automation surface breaks (as Spotlight did live in Sal's demo), the WWSD-grade move is to **document the bypass, not stop the workflow**. Sal's *"That's okay. We can bypass this action anyway"* is the right register for `painpoints/` resolutions: name the failure, name the bypass, ship the working remainder.
- **Sal-voice catalog from this session** — *"It's not my fault"*, *"go to the bar across the street when we're done, not that I drink"*, *"Did I kill the goat this morning?"*, *"Through the magic of chemistry"*, *"AppleScript works all the time, so ha."* The last one is signature Sal vindication and belongs in any WWSD-canon quote sheet.
