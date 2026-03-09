# TIME-MACHINE-001: The Backup App That Can't Be Automated

**App:** Time Machine.app
**Intent:** Programmatically start, stop, schedule, verify, or restore backups — the most critical data protection operation on any computer
**Severity:** Architectural gap — backup automation is invisible to AppleScript, Shortcuts, and Automator
**Status:** Open
**Filed:** 2026-03-09

---

## The Friction

Time Machine has **zero AppleScript commands**. No scripting dictionary. No App Intents. No URL schemes. No Shortcuts actions. No Services. Not even entitlements — it's the most minimal system app we've probed.

| What Time Machine Does | What You Can Script |
|---|---|
| Start a backup | Nothing |
| Stop a backup | Nothing |
| Set backup destination | Nothing |
| Exclude folders from backup | Nothing |
| Check backup status | Nothing |
| Browse backup history | Nothing |
| Restore from backup | Nothing |
| **Verify backup integrity** | **Nothing** |

2 layers active out of 13. The app links 3 frameworks (`BackupCore`, `OSAKit`, and system basics) and has Spotlight metadata. That's it. The thinnest automation surface of any Apple app.

**The practical cost:** "Back up before deploying" is a workflow every developer should have. "Verify last backup succeeded" is a check every user should automate. "Back up, then erase, then restore" is the standard migration path. None of these can be built without dropping to `tmutil` in Terminal.

---

## What Sal Would Say

> "The power of the computer should reside in the hands of the one using it."

Backups protect the user's data — the most important thing on their computer. But the user cannot automate their own data protection. They cannot script "back up before I leave for the day." They cannot verify "did my backup actually work?" They have to trust that the hourly automatic backup is running and hope for the best.

Sal's Principle #2: **Solve a real problem.** "Did my backup work?" is a real question with no scriptable answer. "Back up right now before I do something risky" is a real need with no one-button solution.

Sal's Principle #3: **Keep it local.** Backups are the ultimate local operation — your data, your disk, your machine. If any operation should be automatable on-device, it's this one.

---

## The Automation Surface (from our probe)

From `dictionaries/time-machine/time-machine-probe.yaml`: 2 layers active out of 13. The lowest of any app we've probed.

| Layer | Status |
|-------|--------|
| Scripting Dictionary | None |
| URL Schemes | None |
| App Intents | None |
| Entitlements | None |
| Frameworks | 3 (BackupCore, OSAKit, system) |
| Spotlight | Present |
| CLI Tools | `tmutil` |

The app is a launcher. It opens the Time Machine browser UI. All backup logic lives in the `backupd` daemon. `tmutil` talks to the daemon. The app talks to the daemon. Users cannot talk to the daemon.

---

## What It Should Be

```applescript
-- Backup automation like any other app
tell application "Time Machine"
    -- Check status
    set lastBackup to date of latest backup
    set backupStatus to status  -- "idle", "backing up", "verifying"

    -- Trigger backup
    if (current date) - lastBackup > 4 * hours then
        start backup
        display notification "Backup started — last one was " & lastBackup
    end if

    -- Verify integrity
    set isValid to verify latest backup
    if not isValid then
        display alert "Backup verification failed!"
    end if
end tell
```

```bash
# Or Shortcuts actions
shortcuts run "Back Up Now"
shortcuts run "Check Last Backup"
shortcuts run "Verify Backup"

# Workflow: before risky operation
shortcuts run "Back Up Now" && rm -rf node_modules && npm install
```

---

## Fix Paths

1. **Apple (ideal):** Add a scripting dictionary — expose `backup` class with `date`, `size`, `status`, `destination` properties. Add `start backup`, `stop backup`, `verify backup` commands. Even read-only status would let users build monitoring workflows.
2. **Shortcuts (minimal):** Add two Shortcuts actions: "Start Backup" and "Get Last Backup Date." That's enough for 90% of automation needs. Time Machine already runs in the background — just let Shortcuts trigger it.
3. **`tmutil` (workaround today):** The real automation surface. `tmutil startbackup`, `tmutil latestbackup`, `tmutil listbackups`, `tmutil status`. Full backup control from CLI. But invisible to Shortcuts, Automator, and non-technical users.
4. **LaunchAgent (workaround for scheduling):** Custom plist that runs `tmutil startbackup` on a schedule or trigger. Works but requires Terminal knowledge and manual plist editing — not "the power of the computer in the hands of the user."
5. **`do shell script` bridge (hack):** `do shell script "tmutil startbackup"` in AppleScript. Works but requires admin password for some operations, and the user is writing shell commands inside AppleScript — two languages to do one thing.

---

---

*Part of the [Apple Automation Atlas](../README.md). Tagged for the attention of anyone at Apple who still believes the power of the computer should reside in the hands of the one using it.*

**Filed by [@esaruoho](https://github.com/esaruoho)** — software tester, UI enthusiast, amateur scripter, automation/workflow obsessive, and user experience evaluator. Reporting the missing bits and pieces one at a time.
