# DISK-UTILITY-001: The Disk Management App Has Zero Scripting

**App:** Disk Utility.app
**Intent:** Programmatically mount, unmount, erase, partition, or inspect disks — the operations every sysadmin and power user needs to automate
**Severity:** Architectural gap — the only GUI for disk management is invisible to automation
**Status:** Open
**Filed:** 2026-03-09

---

## The Friction

Disk Utility has **zero AppleScript commands**. No scripting dictionary at all. No App Intents. No URL schemes. No Shortcuts actions.

| What Disk Utility Does | What You Can Script |
|---|---|
| Mount/unmount volumes | Nothing |
| Erase and format disks | Nothing |
| Create/resize partitions | Nothing |
| Create/convert disk images | Nothing |
| Run First Aid (repair) | Nothing |
| RAID management | Nothing |
| **View disk info** | **Nothing** |

The app has 9 private entitlements — including `com.apple.private.storagekitd.destructive` (direct daemon access for erasure) and `allow-obliterate-device` (firmware-level wipe). All the power is there. None of it is exposed to users.

**The practical cost:** Every deployment script, every automated backup workflow, every lab machine that needs reformatting — all of them bypass Disk Utility entirely and shell out to `diskutil`. The GUI app and the automation path have zero overlap.

---

## What Sal Would Say

> "The power of the computer should reside in the hands of the one using it."

Disk management is one of the most fundamental computer operations. If a user can click "Erase" in a GUI, they should be able to script "Erase" in AppleScript. The capability exists — it's just hidden behind private entitlements and XPC daemons that only Apple's own app can talk to.

Sal's Principle #6: **Use the whole toolkit.** The toolkit here is broken in half. The GUI does one thing. The CLI (`diskutil`) does the same thing. They don't connect. There's no AppleScript bridge, no Shortcuts action, no way to chain disk operations into a visual workflow.

Sal's Principle #7: **Think in workflows.** "Erase disk → format as APFS → restore from backup → verify" is a workflow. Today it's a bash script. It should be an Automator workflow or a Shortcut.

---

## The Automation Surface (from our probe)

From `dictionaries/disk-utility/disk-utility-probe.yaml`: 3 layers active out of 13.

| Layer | Status |
|-------|--------|
| Scripting Dictionary | None |
| URL Schemes | None |
| Document Types | None |
| App Intents | None |
| Services | None |
| Entitlements | 9 (all private) |
| Frameworks | 23 |
| Spotlight | Present |
| CLI Tools | `diskutil`, `hdiutil` |

The app is a thin GUI wrapper around `storagekitd` (the storage daemon). All logic lives in the daemon. The GUI talks to it via private XPC. Users cannot.

---

## What It Should Be

```applescript
-- Automate disk operations like any other app
tell application "Disk Utility"
    set allDisks to every disk
    repeat with d in allDisks
        if name of d is "Backup" then
            unmount d
        end if
    end repeat

    -- Format an external drive
    erase disk "disk3" as "APFS" named "NewBackup"

    -- Create a disk image
    create image at "/tmp/archive.dmg" from folder "/Users/me/Documents" with encryption
end tell
```

```bash
# Or Shortcuts actions
shortcuts run "Erase External Drive"
shortcuts run "Create DMG from Folder"
shortcuts run "Mount Backup Volume"
```

---

## Fix Paths

1. **Apple (ideal):** Add a scripting dictionary to Disk Utility — expose `disk`, `volume`, and `partition` classes with `mount`, `unmount`, `erase`, `repair` commands. Gate destructive operations behind authentication prompts (like `diskutil` already does with sudo).
2. **Shortcuts (partial):** Add Shortcuts actions for safe operations: "Mount Volume," "Unmount Volume," "Get Disk Info," "Create Disk Image." Skip destructive ones if security is a concern.
3. **`diskutil` (workaround today):** The real automation surface. `diskutil list`, `diskutil mount`, `diskutil eraseDisk`. More powerful than the GUI — supports RAID, CoreStorage, APFS containers. But it's CLI-only, which locks out Shortcuts and Automator users.
4. **`hdiutil` (workaround for images):** `hdiutil create`, `hdiutil convert`, `hdiutil attach`. Full disk image automation. Also CLI-only.
5. **System Events UI scripting (fragile):** Click through the Disk Utility GUI via accessibility APIs. Breaks on every macOS update.

---

---

*Part of the [Apple Automation Atlas](../README.md). Tagged for the attention of anyone at Apple who still believes the power of the computer should reside in the hands of the one using it.*

**Filed by [@esaruoho](https://github.com/esaruoho)** — software tester, UI enthusiast, amateur scripter, automation/workflow obsessive, and user experience evaluator. Reporting the missing bits and pieces one at a time.
