# Sal Soghoian — The Automation Oracle

> **Trigger words**: "what would sal do", "sal", "wwsd"

## Who Is Sal

**Sal Soghoian** — Product Manager of Automation Technologies at Apple Inc., January 1997 to October 2016. Nearly 20 years as the sole internal champion for the idea that the Mac should be scriptable and automatable by its users.

### His Credo

> **"The power of the computer should reside in the hands of the one using it."**

### What He Built at Apple

- **AppleScript revival** — saved it from languishing, got it PowerPC-native in Mac OS 8.5, transitioned it to Mac OS X
- **Automator** — his signature creation. Demoed it on stage with Steve Jobs at WWDC 2004 (Jobs called him "Saul")
- **System Services** — inter-application automation mechanism
- **JavaScript for Automation (JXA)** — JS as alternative scripting language (OS X Yosemite)
- **Dictation Commands** — custom voice-triggered commands on macOS
- **Application scripting support** in Photos, iWork, Finder, Mail, and other Apple apps
- **AppleScriptObjC, Scripting Bridge** — bridging AppleScript to Cocoa

### His Philosophy

1. **Democratization over dependency** — automation shouldn't require being a programmer
2. **Local over cloud** — *"If you can do it yourself, don't send your data to someone to manage or manipulate for you."* / *"Whenever possible, avoid joining the food chain."*
3. **User automation is not app extensions** — true user automation (AppleScript, Automator, Services, UNIX CLI) gives genuine power and control
4. **Automation as a right, not a feature** — fundamental to what makes the Mac the Mac
5. **Practical over theoretical** — scripts on almost every page, not reams of boring theory

### His Departure (November 2016)

Apple **eliminated his position entirely** — didn't replace him, dissolved the role.

> "I am no longer employed by Apple Inc. But, I still believe my credo to be as true today as ever."
> "If user automation technologies are important to you, then now is the time for all good men and women to reach out, speak up and ask questions."

**Community reaction was seismic**: John Gruber called it "ominous" and "profoundly worrisome." Brent Simmons, MacSparky, Six Colors, 9to5Mac, MacRumors — the entire Apple press mourned.

### Post-Apple Work

- **MacStories guest series** (Jan 2017) — argued the case for continued user automation
- **CMD-D: Masters of Automation Conference** (2017) — his own conference in Santa Clara
- **Omni Automation** — JavaScript-based automation for OmniFocus/OmniGraffle/OmniOutliner/OmniPlan (macOS + iOS)
- **Dictation Commands** — hundreds of voice-triggered commands for macOS apps

### Key Resources

| Resource | URL |
|----------|-----|
| macOS X Automation | macosxautomation.com |
| iWork Automation | iworkautomation.com |
| Dictation Commands | dictationcommands.com |
| Omni Automation | omni-automation.com |
| CMD-D Conference | cmddconf.com |
| Twitter/X | @macautomation |
| Book | *AppleScript 1-2-3* (Apple Pro Training Series, with Bill Cheeseman) |

### Patent

**US 7,428,535 B1** — "Automatic Relevance Filtering" (Sep 23, 2008)
Co-inventor with Eric S. Peyton, Tim W. Bumgarner, Todd R. Fernandez.
See `patents/US7428535-automatic-relevance-filtering.pdf` and `patents/US7428535-analysis.md`.

---

## "What Would Sal Do" — The 10 Principles

When writing AppleScript, channel Sal's mindset:

1. **The user comes first.** Every script exists to put power in the user's hands. Does this script empower or create dependency?

2. **Solve a real problem.** Never write a script that doesn't address an actual workflow pain point. Sal discovered AppleScript solving publishing automation — every script needs a clear "why."

3. **Keep it local.** Prefer on-device processing over cloud services. Protect user data. "Avoid joining the food chain."

4. **Make it readable.** AppleScript's English-like syntax is a feature, not a quirk. Write scripts that read like instructions a human could follow.

5. **Build incrementally.** Start with something that works, then expand. Fundamentals → tools/techniques → real-world applications.

6. **Use the whole toolkit.** AppleScript is the hub, but chain with `do shell script`, System Events for UI, Automator, `osascript` from Terminal. Best tool for the job.

7. **Think in workflows, not scripts.** What application produces the data? What transforms it? What consumes it?

8. **Tell applications what to do, not how.** Work with the application's scripting dictionary and object model, not against it.

9. **Educate and share.** The automation community grows through generosity. Write scripts others can learn from.

10. **Never give up on automation.** Sal's response to losing his position wasn't despair — it was action: write more, teach more, build more.
