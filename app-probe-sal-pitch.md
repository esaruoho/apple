# app-probe.py — The Tool Sal Would Have Killed For in 1997

## The Context

January 1997. Sal Soghoian walks into Apple as the new Product Manager for User Automation. Steve Jobs is axing technologies left and right. Cal Simone had just convinced Jobs to keep AppleScript alive by arguing the publishing industry depended on it. That argument bought time — not certainty.

Sal's first job: figure out which apps are scriptable, what they can do, and convince more app teams to add scripting support. His daily reality: open an app, check if it has a scripting dictionary, manually read through every command, class, property. Then walk to the next app team's office and ask "did you add scripting support yet?" Repeat for every app on the Mac.

There was no map. No atlas. No way to see the full automation surface of the platform at a glance.

## The Pitch

> Sal, you know how you spend weeks going app by app, opening Script Editor, checking dictionaries, writing down what's scriptable and what isn't? And then you still don't know about the URL schemes, the Services menu, the command-line tools hidden inside the bundle?
>
> This runs once. Sixty seconds. Every app on the Mac. Not just the scripting dictionary — thirteen layers deep. It finds automation surfaces the app teams themselves forgot they shipped. URL schemes nobody documented. Intents nobody announced. CLI tools buried in Contents/MacOS that aren't in any man page.
>
> You get back a single index. "Mail can do these 47 things. Finder exposes these 12 URL schemes. Photos has these Siri phrases." Every app, every automation surface, one file.
>
> You know how you're trying to convince the iWork team to add scripting support? Show them this. Show them that Pages has zero scripting commands while Finder has 200. That's not a bug report — that's a shame list. This tool makes the absence of automation visible, and visible absence is the strongest argument you'll ever make.

## Why This Works: The Psychology

**Loss aversion.** Sal doesn't need to argue *for* automation. He just needs to show what's *missing*. People feel losses more strongly than gains. A table full of zeros next to a column of hundreds hurts more than any pitch deck.

**The Zeigarnik effect.** Incomplete things nag at people. An app team seeing their app listed with empty columns next to fully-probed competitors wouldn't be able to ignore it. The incompleteness itself creates the motivation to act.

**Social proof as competitive pressure.** Sal's 1997 pitch to app teams was always "you should add scripting support." With app-probe, the pitch becomes "everyone else already did — why haven't you?" He wouldn't need to evangelize. The data evangelizes.

**The shame list.** This is the real weapon. app-probe doesn't just show what exists — it shows what doesn't. Every app without a scripting dictionary is a visible gap. Every app with URL schemes but no AppleScript support is an inconsistency. Product managers hate inconsistency more than they hate extra work.

## What app-probe.py Actually Finds

13 layers, 66 apps, one pass:

| Layer | What It Probes |
|-------|---------------|
| sdef | Scripting dictionaries (AppleScript commands, classes, properties) |
| URL schemes | Custom URL handlers (x-callback-url, deep links) |
| Document types | File types the app can open/edit |
| App Intents | Siri phrases + Shortcuts actions (from extract.actionsdata) |
| Services | macOS Services menu entries |
| Activities | NSUserActivity declarations |
| Entitlements | Sandbox permissions and capabilities |
| Frameworks | Linked frameworks (reveals hidden capabilities) |
| Spotlight | Spotlight importers and metadata types |
| LaunchServices | Registered content types |
| Plugins | App extensions and plugin points |
| Notifications | Notification categories and actions |
| CLI tools | Command-line binaries inside the app bundle |

**Results:** 378 total layer hits. 20 apps have App Intents. 35 expose URL schemes. 31 have scripting dictionaries.

## The Connection to the Patent

Sal's Automator patent (US 7,428,535) describes *relevance filtering* — given what action A outputs, which actions can accept it? The patent solved this for workflows. app-probe solves the prerequisite: before you can chain actions, you need to know what actions exist.

app-probe is the census that makes the patent's filtering possible. You can't filter for relevance if you don't have a complete inventory. In 1997, that inventory didn't exist and had to be built by hand. Now it takes sixty seconds.
