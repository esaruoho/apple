# ACTIVITY-MONITOR-001: The Process Manager You Can't Manage Programmatically

**App:** Activity Monitor.app
**Intent:** Programmatically query CPU, memory, disk, network usage — or kill/prioritize processes — the operations every developer and sysadmin needs
**Severity:** Architectural gap — the only GUI for process management has zero automation surface
**Status:** Open
**Filed:** 2026-03-09

---

## The Friction

Activity Monitor has **zero AppleScript commands**. No scripting dictionary. No App Intents. No URL schemes. No Shortcuts actions. No Services menu entries.

| What Activity Monitor Shows | What You Can Script |
|---|---|
| CPU usage per process | Nothing |
| Memory pressure and per-process RAM | Nothing |
| Disk reads/writes per process | Nothing |
| Network traffic per process | Nothing |
| GPU usage per process | Nothing |
| Kill a runaway process | Nothing |
| Change process priority | Nothing |
| **View energy impact** | **Nothing** |

You can look at the data through the GUI. You cannot ask for it programmatically. You cannot act on it programmatically.

**The practical cost:** "If CPU is above 90%, kill the runaway process" is an automation that every developer wants. "Log memory usage every 5 minutes" is a monitoring task every sysadmin needs. Neither can be built with Shortcuts, Automator, or AppleScript. All of them require shell scripts with `ps`, `top`, and `kill`.

---

## What Sal Would Say

> "The power of the computer should reside in the hands of the one using it."

Activity Monitor shows you what your computer is doing. But it won't let you automate responses to what it shows you. You can watch a process eat 100% CPU. You cannot tell your computer "if that happens, do this." The monitoring is passive. The user is passive. That's the opposite of automation.

Sal's Principle #2: **Solve a real problem.** "My Mac is slow and I don't know why" is the #1 support question. "Automatically quit apps using more than 4GB of RAM" would solve it. Activity Monitor has the data. It just won't share it.

Sal's Principle #7: **Think in workflows.** Monitor → detect → act is the fundamental automation loop. Activity Monitor only does step 1, and only through a GUI window you have to stare at.

---

## The Automation Surface (from our probe)

From `dictionaries/activity-monitor/activity-monitor-probe.yaml`: 3 layers active out of 13.

| Layer | Status |
|-------|--------|
| Scripting Dictionary | None |
| URL Schemes | None |
| App Intents | None |
| Services | None |
| Entitlements | 7 (all private — sysmond, GPU wrangler) |
| Frameworks | 19 |
| Spotlight | Present |
| CLI Tools | `top`, `ps`, `vm_stat`, `iostat` |

The app reads from `sysmond` (system monitoring daemon) via private XPC. The daemon has all the data. The app displays it. Users cannot query the daemon directly.

---

## What It Should Be

```applescript
-- Query system state like any other app
tell application "Activity Monitor"
    set cpuLoad to overall CPU usage  -- returns percentage
    set memPressure to memory pressure  -- "normal", "yellow", "red"

    -- Find expensive processes
    set hogs to every process whose CPU usage > 50
    repeat with p in hogs
        log (name of p) & ": " & (CPU usage of p) & "%"
    end repeat

    -- Act on runaway processes
    if memPressure is "red" then
        set biggest to first process where memory usage is maximum
        quit biggest
    end if
end tell
```

```bash
# Or Shortcuts actions for non-technical users
shortcuts run "Show Top CPU Processes"
shortcuts run "Kill Runaway Process"
shortcuts run "Log System Stats"
```

---

## Fix Paths

1. **Apple (ideal):** Add a scripting dictionary — expose `process` class with `CPU usage`, `memory usage`, `disk activity`, `network activity` properties. Add `quit process`, `sample process` commands. Even read-only access would be transformative.
2. **Shortcuts (partial):** Add Shortcuts actions: "Get CPU Usage," "Get Memory Pressure," "List Top Processes." Even without kill capability, monitoring Intents would let users build notification workflows.
3. **`top` / `ps` (workaround today):** `top -l 1 -o cpu -n 5` gives top 5 processes by CPU. `ps aux --sort=-%mem | head` for memory. Powerful but requires parsing text output — fragile, not composable with Shortcuts.
4. **`kill` / `killall` (workaround for action):** `killall "App Name"` or `kill -9 PID`. No confirmation, no undo. Works but dangerous without the context Activity Monitor provides.
5. **System Events (partial):** `tell application "System Events" to set processList to name of every process` gives process names. But no CPU/memory data — System Events knows what's running, not how hard.

---

---

*Part of the [Apple Automation Atlas](../README.md). Tagged for the attention of anyone at Apple who still believes the power of the computer should reside in the hands of the one using it.*

**Filed by [@esaruoho](https://github.com/esaruoho)** — software tester, UI enthusiast, amateur scripter, automation/workflow obsessive, and user experience evaluator. Reporting the missing bits and pieces one at a time.
