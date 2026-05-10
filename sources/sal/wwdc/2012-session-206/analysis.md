# WWDC 2012 Session 206 — Secure Automation Techniques in OS X (Analysis)

**Speakers:** Sal Soghoian (framing + four-scenario tour) + Chris Nebel (Mountain Lion engineering: code signing, access groups, NSUserScriptTask)
**Duration:** 50:13 · **Year:** 2012 (Mountain Lion)
**Source:** Whisper-generated transcript from nonstrict.eu (machine-transcribed; expect proper-noun and homophone errors — "Sal Segoin", "macos10automation.com", "Laia" = plist)

## The historical position

This is **the bridge talk** between the 2003 archive (AppleScript Studio, peer-to-Aqua) and the 2014/2016 modern era (JXA, Siri Shortcuts). Mountain Lion (10.8) introduced **two security regimes that could have killed Mac automation outright**: Gatekeeper (signed-only execution) and App Sandbox (Apple-Event walls between apps). Session 206 is Sal + Chris saying *here is how automation survives this*.

The session's whole architecture is a defense of WWSD #1 (democratization) under a hostile new security model. It's the only WWDC session where Sal's entire pitch is "your old code keeps working, here's the seam where you fit it back together."

## Sal's framing — the four-scenario decomposition

> *"What we've done is make it so that it becomes automation **with** security."*

Four scenarios laid out at the top, addressed in order:

1. **Personal automation** — scripts you write yourself, run on your own machine
2. **Distributing scripts** — sharing applets/droplets to other users (downloads)
3. **App-to-app automation** — one sandboxed app sending Apple Events to another
4. **Attaching scripts** — apps that host user-supplied scripts (script menus, mail rules, Aperture import actions)

This decomposition is **pure Sal-grade systematic thinking**: instead of one big "security is hard" talk, four clean buckets, each with a clear answer. Decomposition by user role, not by API surface.

## Sal's three design goals (the engineering brief)

> *"We had a couple goals in mind. First was to preserve the functionality that you're used to… Secondly, we wanted that interaction between the world of automation and the world of security to be as transparent as possible, without a lot of dialogues, without a lot of interaction required… And finally, we wanted to minimize any changes that we request of you as developers."*

Three goals, in priority order: **preserve functionality → transparent interaction → minimize developer churn**. This is the language of an internal product spec being read aloud at WWDC. Sal is signaling to the audience that automation-with-security was **fought for** inside Apple, not just bolted on.

## Scenario 1 — Personal automation: zero restrictions

> *"Anything that you write that's executed by the operating system runs with no restrictions whatsoever."*

The structural defense:

| Tool | Restrictions |
|------|-------------|
| Automator (workflows, applets, services) | **None** |
| AppleScript Editor + Script Menu + AppleScript-ObjC | **None** |
| Unix command line (osascript, automator CLI, shell) | **None** |

The reasoning: **if the OS executes the code, the OS is the trust boundary, not the script**. This is the WWSD-grade principle hidden in the engineering — *user-authored automation has the same trust level as the OS itself, because the user IS the OS administrator*.

Sal works this point hard, repeating "no restrictions" four or five times and milking the applause: *"if I keep saying the word no restrictions, you're going to keep applauding? I could just do this for an hour."* The audience is the AppleScript community, watching for whether Mountain Lion will break them. Sal is telling them: **you are safe; the OS itself is your privilege**.

The "I came to Apple 15 years ago" line dates Sal's arrival to **1997** — matching every other biographical anchor in the WWSD canon. *"Some days I feel like a dinosaur looking for a tar pit."*

## Scenario 2 — Distributing scripts: Gatekeeper and the code-signing dance

Gatekeeper preferences (Security & Privacy → General):

1. Mac App Store only
2. **Mac App Store + Identified Developers** ← default
3. Anywhere

Sal explicitly warns: *"as developers, it's really important not to depend on [the power-user Right-click-Open workaround]. The default setting in Mountain Lion is that second one… So as somebody that provides tools for others to use, it's important for you not to rely on that."*

Chris Nebel's signing demo (the engineering meat):

1. **Set the bundle identifier** — new direct UI in Mountain Lion's Script Editor bundle-contents drawer; previously had to edit Info.plist by hand
2. **`chmod a-w` the applet's script** — *"Applets, by default, like to write back to themselves so they can do persistent properties. The problem is that once an applet is signed, writing back to it will actually invalidate the signature."* **Properties no longer persist.** Use NSUserDefaults / a separate preference file instead.
3. **`codesign --sign 'Developer ID Application: …' --identifier <bundle-id> <Applet.app>`**
4. After download, Gatekeeper now shows "downloaded from internet, are you sure?" instead of "unidentified developer, block".

**This is where Sal's 2003 droplet-with-preferences pattern (WWSD #38) breaks for distributed applets.** Locally-built droplets still get to use Finder-comment + duplicate-and-rename config. But distributed signed droplets must externalize their config to NSUserDefaults. The pattern survives for personal use but is structurally incompatible with code signing.

## Scenario 2.5 — The `applescript://` URL protocol

A side-pocket gotcha. Since Mac OS X **Tiger (2005)**, AppleScript code can be embedded in web pages via `applescript://` URLs with percent-encoded code. Clicking the link opens a new window in Script Editor pre-populated with the code.

Under Mountain Lion's default Gatekeeper, this still works **but now opens a read-only viewer first** — you can read/copy/drag-to-desktop the sample but can't directly Run it. Click **New Script** to spawn an editable Run-capable window.

Sal's tone here: *"Not a big issue, but I thought you'd want to know about it… A little bit more security I think we can all live with for a better world."* — code-aware concession that the friction is worth the safety.

## Scenario 3 — App-to-app automation: the Access Groups architecture (the headline)

The two-sided rule under sandboxing:

- **Receiving Apple Events:** unrestricted. Sandboxed scriptable apps stay just as scriptable as before. **One caveat:** file references must be real file types in the Apple Event, **not just text strings of paths** — the Apple Event Manager creates sandbox extensions for file refs but won't do it for plain-text paths (security risk: too easy to abuse).
- **Sending Apple Events:** **forbidden by default**. Otherwise *"Apple Events make a great way to escape the sandbox. You can use the Finder to escape any sort of file system restrictions… If you can talk to Safari, you can get around any network restrictions… You can just tell Terminal to do anything you like."*

### The temporary exception entitlement (the duct tape)

```xml
<key>com.apple.security.temporary-exception.apple-events</key>
<string>com.apple.mail</string>
```

Grants the sending app permission to send **any Apple Event** to the named bundle ID. Chris's verdict: *"This entitlement works, but we're not real happy with it… It allows you to send any event you want."* Violates principle of least privilege.

### The new architecture: Apple Event Access Groups

> *"An access group defines a set of scriptable operations, a set of commands and classes and properties. They can be sliced and diced in a very flexible way. They are part of the application's scripting interface. It's SDEF."*

This is **the structural delta of Mountain Lion** for automation. The sdef schema gains an `<access-group>` element that can be attached to commands, classes, properties, or whole suites:

```xml
<class name="application" code="capp" inherits="application">
    <element type="outgoing message">
        <access-group identifier="com.apple.mail.compose" access="read-write"/>
    </element>
</class>

<class name="outgoing message" code="bcke" plural="outgoing messages">
    <access-group identifier="com.apple.mail.compose" access="read-write"/>
    <property name="recipients" .../>
    ...
</class>
```

Mail and iTunes shipped Mountain Lion with access groups. The client entitlement becomes:

```xml
<key>com.apple.security.scripting-targets</key>
<dict>
    <key>com.apple.mail</key>
    <array><string>com.apple.mail.compose</string></array>
</dict>
```

Dict keyed by target bundle ID, value = list of access group identifiers. **You get exactly the commands in that group, nothing else.**

Chris's design guidance for sdef authors: *"Divide things along functional boundaries. Look at the kind of clients you use. Look at the kind of tasks they do."* Access groups overlap freely — same command can sit in multiple groups (e.g., iTunes "read-only" and "read-write" overlap).

The specific decision about `send`: *"We actually made the specific decision that sending should be up to the user only. A sandboxed application really should not have permission to do this ever."* `send` is **not** in any access group — only personal scripts run by the user can send mail. **This is consent-by-not-granting** — a category of operation that the security model says "this is the user's decision, period."

## Scenario 4 — Attaching scripts: NSUserScriptTask and the consent-via-file-placement pattern

The architectural problem: a sandboxed application hosts a Script Menu / mail rules / Aperture import actions. User-supplied scripts arrive that need to send Apple Events to *other* apps. The host app can't know in advance which apps the user's scripts will target, so it can't request entitlements for all of them.

The solution, in Sal's words:

> *"The solution to this scenario… is to involve the user. The user takes the scripts and puts them in a sequestered folder that the system's aware of called Application Scripts. And then the application, when the user selects a script from the menu, the application requests the system to execute it. And because scripts written by you and executed by the system run without restrictions, the script runs without restrictions."*

**This is the central WWSD-grade insight of the entire session.** The user's act of placing a script in a magic folder *is consent*. The sandbox can't decide for the user, so the user decides for the sandbox.

### The mechanics

- **Folder:** `~/Library/Application Scripts/<host-app-bundle-id>/`
- **App permissions:** read, enumerate, create the folder, open in Finder — **but cannot write to it**. Only the user can put scripts there. (This is what makes the "user placed it = user consented" invariant load-bearing.)
- **API:** `NSUserScriptTask` (generic), plus three subclasses for typed control:
  - `NSUserAppleScriptTask`
  - `NSUserAutomatorTask`
  - `NSUserUnixTask`
- **Execution model:** scripts run **out of process** (a launchd-managed worker), inheriting OS-level trust, not the host app's sandbox. This also fixes the threading mess that `NSAppleScript` historically caused.
- **Discovery API:** `NSFileManager.URLForDirectory(.NSApplicationScriptsDirectory, in: .userDomainMask, ...)`
- **No entitlement required.** Base application behavior.

### The Apple Event passing recipe

For trigger-based scripts (mail rule fires, calendar event hits, Aperture import completes), the host app builds an `NSAppleEventDescriptor` carrying the change data (messages, files, photos) and calls:

```objc
[task executeWithAppleEvent:event completionHandler:^(NSAppleEventDescriptor *result, NSError *error) { ... }]
```

The completion handler receives both the error and the script's return-value descriptor. Fire-and-forget by passing `nil`.

### The "don't blindly find-and-replace" caveat

> *"NSUserScriptTask can replace NSAppleScript, AMWorkflow, and NSTask in your application, but don't just do a blind find-and-replace. Only use it for user scripts."*

App-internal scripts (built into the bundle, shipped to users) must keep using `NSAppleScript` / `NSTask` — they're trusted by the developer, not by the user-via-file-placement. Mixing the two is an architectural mistake.

## Two Apple-internal data points worth preserving

1. **The Mastered for iTunes Droplet** — *"It's being used by hundreds of thousands of professionals worldwide to preview their songs and their audio files as to how they're going to sound in preparation for iTunes. It's very high quality, and all of that preparation and all of that preview work is done by an AppleScript Droplet. So at Apple, this is an important tool for us."* Apple shipping an AppleScript droplet as a commercial mastering tool in 2012 = **Apple eats its own automation dogfood at production scale**. This validates WWSD #1 from the Apple-internal side.

2. **The 1997 anchor** — "I came to Apple 15 years ago." Subtract from 2012 = 1997. Matches every other biographical anchor in the WWSD canon. Reinforces vision-stability: by 2012 Sal had been at Apple 15 years; the 2003 sessions caught him at year 6; the 2014 session at year 17.

## WWSD-relevant takeaways

- **Four-scenario decomposition** — the systematic-thinking move belongs in Sal's WWSD-pattern catalog. When a hostile constraint lands (sandbox/Gatekeeper), don't argue with it — partition the user roles it affects and answer each partition cleanly.
- **"Scripts written by you, executed by the system, run without restrictions"** — the structural defense of WWSD #1 under sandboxing. The trust boundary is the user-OS pair, not the app. **Candidate WWSD principle: trust the OS-user pair, not the app.**
- **Consent-by-file-placement** — `~/Library/Application Scripts/<bundle-id>/` as a user-consent surface. The user placing a file *is* the entitlement. **Candidate WWSD principle: user-placed-file = consent.** This pattern echoes the 2003 droplet-with-preferences (config in Finder comment) — both treat the filesystem as a UI for user intent.
- **"Sending should be up to the user only"** — the `send` Apple Event in Mail is deliberately outside any access group. There are categories of operation that **cannot be granted to apps, only to user-driven scripts**. This is a concrete operational expression of WWSD-grade thinking — some powers belong to the human, period.
- **Access groups = least privilege applied to AppleScript dictionaries** — the security-era refinement of Sal's 2003 "request real scriptability from the developer" prescription (WWSD #35). Now the request becomes: *and ship your sdef with proper access groups*.
- **Signed-applet config breakage** — distributed droplets can no longer use the WWSD #38 Finder-comment-as-config pattern (because writing back invalidates the signature). The pattern survives for personal use; distributed apps must externalize to NSUserDefaults. **Operational note**, not a contradiction.

## Reusable for the apple repo

- **`~/Library/Application Scripts/<bundle-id>/`** is a still-live surface in Sequoia 2026. Worth a probe pass: which Apple apps currently advertise this folder? Hey Sal could install voice-callable scripts here for sandboxed Apple apps that expose handlers (Mail, Aperture-successor, Photos, Calendar via EventKit).
- **`NSUserScriptTask` from JXA** — `ObjC.import('Foundation')` then `$.NSUserAppleScriptTask.alloc.initWithURLError(...)`. This is the JXA way to run user scripts out-of-process. Could replace several places in `bin/` that currently shell out to `osascript` and reinherit the parent's sandbox.
- **Access group inventory** — `bin/sdef-extract.py` could be extended (or a sister probe added) to list every `<access-group>` element across the 31 captured sdef.xml files. That's the 2026 inventory of which Apple apps still ship granular scripting permissions vs. just the temporary exception.
- **The four-scenario template** for `painpoints/` write-ups — when an Apple app fails an automation use case, decompose by Sal's four scenarios first (is this personal, distribution, app-to-app, or attached?) before proposing a fix. The four buckets ask different questions of the OS.
- **Signed-droplet helper** — `bin/sign-droplet.sh` that wraps the Chris Nebel three-step (set bundle ID, `chmod a-w` the script, `codesign` with Developer ID) into one command for distributing `bin/spotlight-export` artifacts. Already partly solved by the existing Spotlight TCC fix (memory: shared bundle identifier + ad-hoc codesign); this would be the Developer-ID-signed variant for actual distribution.
- **WWSD candidate principles #39–40** (proposed):
  - **#39 — User-placed-file = consent.** When the sandbox can't decide, the filesystem records the user's intent. Same logic as the 2003 droplet-with-prefs Finder-comment pattern, generalized.
  - **#40 — Some powers belong to the user, period.** Sending mail / launching subprocesses / talking to Terminal aren't operations the app should be entitled to — only operations the user-via-script can perform. Belongs in the WWSD canon as the operational complement to "AppleScript is a peer to Aqua" (WWSD #31): some peer rights only exist for the human at the keyboard.
