# WWDC 2012 #206 — Secure Automation Techniques in OS X

**Speakers:** Sal Soghoian + Chris Nebel · **50:13** · Mountain Lion
**nonstrict:** https://nonstrict.eu/wwdcindex/wwdc2012/206/

## The pitch — the bridge talk

**Bridge between the 2003 AppleScript Studio era and the 2014/2016 modern era.** Mountain Lion introduced Gatekeeper + App Sandbox — two security regimes that could have killed Mac automation outright. This session is Sal + Chris explaining how automation survives.

> *"What we've done is make it so that it becomes automation **with** security."*

## Sal's four-scenario decomposition

| Scenario | The answer |
|----------|-----------|
| **Personal automation** — scripts you write yourself | **No restrictions** — anything executed by the OS is unrestricted |
| **Distributing scripts** | Code-sign your applets (Developer ID + `codesign`) |
| **App-to-app automation** | Apple Event Access Groups + `scripting-targets` entitlement |
| **Attaching scripts** (mail rules, script menus) | `NSUserScriptTask` + `~/Library/Application Scripts/<bundle-id>/` |

## Scenario 1 — Personal automation: zero restrictions

> *"Anything that you write that's executed by the operating system runs with no restrictions whatsoever."*

The trust boundary is **the user + the OS**, not the app. Automator, AppleScript, Script Menu, shell, `osascript` — all unrestricted because the OS executes them.

Sal milks the applause: *"If I keep saying the word no restrictions, you're going to keep applauding? I could just do this for an hour."*

## Scenario 2 — Distribution: code-sign your applets

Chris Nebel's three-step:
1. **Set bundle identifier** — new direct UI in Mountain Lion's Script Editor bundle drawer
2. **`chmod a-w` the applet's script** — signed applets can't write back to themselves (invalidates the signature). **Properties no longer persist. Use NSUserDefaults instead.**
3. **`codesign --sign 'Developer ID Application: …' --identifier <bundle-id> <Applet.app>`**

After download, Gatekeeper shows "downloaded from internet, are you sure?" instead of "unidentified developer, block."

**Breaks the 2003 Finder-comment-as-config pattern (WWSD #38) for distributed droplets.** Pattern survives for personal use only.

## Scenario 3 — App-to-app: Apple Event Access Groups (the architectural delta)

**Two-sided rule under sandboxing:**
- **Receiving Apple Events:** unrestricted (scriptable apps stay scriptable, one caveat: pass file refs, not text paths)
- **Sending Apple Events:** **forbidden by default**

**Why:** *"Apple Events make a great way to escape the sandbox. You can use the Finder to escape any file system restrictions. If you can talk to Safari, you can get around any network restrictions. You can just tell Terminal to do anything you like."*

### The temporary-exception entitlement (the duct tape)

```xml
<key>com.apple.security.temporary-exception.apple-events</key>
<string>com.apple.mail</string>
```

Grants permission to send **any Apple Event** to Mail. Chris: *"This entitlement works, but we're not real happy with it."* Violates least privilege.

### The new architecture: Apple Event Access Groups

`<access-group>` element in the target app's sdef defines subsets of the scripting interface:

```xml
<class name="application">
    <element type="outgoing message">
        <access-group identifier="com.apple.mail.compose" access="read-write"/>
    </element>
</class>
```

Client entitlement:

```xml
<key>com.apple.security.scripting-targets</key>
<dict>
    <key>com.apple.mail</key>
    <array><string>com.apple.mail.compose</string></array>
</dict>
```

**Exactly the commands in that group, nothing else.**

Mail + iTunes ship Mountain Lion with access groups. The `send` Apple Event in Mail is **deliberately in no access group** — *"sending should be up to the user only. A sandboxed application really should not have permission to do this ever."*

## Scenario 4 — Attached scripts: `NSUserScriptTask` + Application Scripts folder

**The central WWSD insight of the session.**

The problem: a sandboxed app hosts a Script Menu / mail rules. User scripts arrive that need to talk to other apps. Host can't request entitlements for all of them.

The solution:

> *"The user takes the scripts and puts them in a sequestered folder called Application Scripts. The application requests the system to execute it. Because scripts written by you and executed by the system run without restrictions, the script runs without restrictions."*

**The user's act of placing a script in a magic folder *is consent.***

### Mechanics

- **Folder:** `~/Library/Application Scripts/<host-app-bundle-id>/`
- **Permissions:** app can read, enumerate, create the folder, open in Finder — **but cannot write to it.** Only the user can place scripts.
- **API:** `NSUserScriptTask` + three typed subclasses: `NSUserAppleScriptTask`, `NSUserAutomatorTask`, `NSUserUnixTask`
- **Execution:** scripts run **out of process**, inheriting OS-level trust, not the host app's sandbox
- **No entitlement required.** Base app behavior.

## Power features delivered

- **Code-signing for AppleScript applets** with Developer ID
- **Apple Event Access Groups** — granular per-command permission system in sdef
- **`scripting-targets` entitlement** — dictionary of per-app access-group lists
- **`NSUserScriptTask`** + three typed subclasses for sandbox-safe user-script execution
- **`~/Library/Application Scripts/<bundle-id>/` as a consent surface**
- **The "send is no one's entitlement" pattern** — some powers belong only to user-driven scripts

## Sal's data point

> *"The Mastered for iTunes Droplet is being used by hundreds of thousands of professionals worldwide. All of that preparation and preview work is done by an AppleScript Droplet."*

**Apple shipping an AppleScript droplet as a commercial mastering tool in 2012.** Apple eats its own automation dogfood at production scale.

## Marketing copy version

**Headline:** Mountain Lion ships Gatekeeper and the App Sandbox. Your AppleScript world survives — and gets safer. Code-sign your applets. Mark up your sdef with Access Groups. Let users place scripts in Application Scripts folders. Consent-by-architecture replaces "give me everything" entitlements.

**Audience takeaway:** if you ship a scriptable app, add `<access-group>` markup to your sdef this year. If you ship a host app with a script menu, switch to NSUserScriptTask. If you distribute droplets, code-sign them.
