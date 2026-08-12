---
layout: default
title: Painpoints
---

# Automation painpoints

Fourteen filings against macOS, each one a place where the Mac already holds the
capability and refuses to hand it to the person using the machine. Written the way a
bug report should be written — reproduce it, measure it, say precisely what should
happen instead.

> *"The power of the computer should reside in the hands of the one using it."*
> — [Sal Soghoian](https://github.com/esaruoho/apple/blob/main/wiki/entities/sal-soghoian.md)

Most of these are **automation walls**: an app that ships a scripting dictionary with
the verbs missing, or none at all. One of them is different — SYSTEM-SETTINGS-002 is a
**correctness bug**, where Apple built the right tool and wired it to the wrong number.

---

## Featured

### [The Hidden 7.4 Gigabytes →](./system-settings-002.html)

**SYSTEM-SETTINGS-002** — System Settings ▸ General ▸ Storage ▸ Messages decides *what
to list* using a database field that is wrong by up to **8279×**, then *displays and
sorts* using the real size on disk. Of 53 attachments ≥100 MB (12.3 GB) on one machine,
it surfaces 27 (4.8 GB) and conceals 26 (7.4 GB) — including the single largest file in
the entire store.

Full evidence, measured: [read the filing →](./system-settings-002.html)

---

## All filings

| ID | Title | App |
|---|---|---|
| **SYSTEM-SETTINGS-002** | [The Storage Panel Filters on a Field That Lies](./system-settings-002.html) | System Settings ▸ Storage ▸ Messages |
| PLATFORM-001 | [macOS Automation Is Splintered Across Five Incompatible Layers](https://github.com/esaruoho/apple/blob/main/painpoints/PLATFORM-001-automation-fragmentation.md) | macOS (platform-wide) |
| SYSTEM-SETTINGS-001 | [The Most Important Config App on macOS Has Almost No Automation](https://github.com/esaruoho/apple/blob/main/painpoints/SYSTEM-SETTINGS-001-most-important-app-least-scriptable.md) | System Settings.app |
| MESSAGES-001 | [Messages Is Write-Only by Design](https://github.com/esaruoho/apple/blob/main/painpoints/MESSAGES-001-write-only-automation.md) | Messages.app |
| TIME-MACHINE-001 | [The Backup App That Can't Be Automated](https://github.com/esaruoho/apple/blob/main/painpoints/TIME-MACHINE-001-no-scripting-for-backups.md) | Time Machine.app |
| DISK-UTILITY-001 | [The Disk Management App Has Zero Scripting](https://github.com/esaruoho/apple/blob/main/painpoints/DISK-UTILITY-001-no-scripting-for-disk-management.md) | Disk Utility.app |
| ACTIVITY-MONITOR-001 | [The Process Manager You Can't Manage Programmatically](https://github.com/esaruoho/apple/blob/main/painpoints/ACTIVITY-MONITOR-001-no-scripting-for-process-management.md) | Activity Monitor.app |
| SCREENSHOT-001 | [The Screen Capture App That Can't Be Scripted](https://github.com/esaruoho/apple/blob/main/painpoints/SCREENSHOT-001-no-scripting-for-screen-capture.md) | Screenshot.app |
| PREVIEW-001 | [Default PDF Viewer Has Zero AppleScript Support](https://github.com/esaruoho/apple/blob/main/painpoints/PREVIEW-001-no-applescript-despite-being-default-viewer.md) | Preview.app |
| PHOTOS-001 | [Photos Scripting Dictionary Is a Read-Only Catalog](https://github.com/esaruoho/apple/blob/main/painpoints/PHOTOS-001-shallow-scripting-dictionary.md) | Photos.app |
| HOME-001 | [HomeKit Has No CLI and No AppleScript](https://github.com/esaruoho/apple/blob/main/painpoints/HOME-001-no-applescript-homekit-cli.md) | Home.app |
| NOTES-001 | [Recording Audio Should Be One Action](https://github.com/esaruoho/apple/blob/main/painpoints/NOTES-001-record-audio.md) | Notes.app |
| MAIL-002 | [No Bulk Ingest for Saved Text Archives](https://github.com/esaruoho/apple/blob/main/painpoints/MAIL-002-no-bulk-ingest-for-saved-text-archives.md) | Mail.app |
| SHORTCUTS-001 | [iOS Has No "When File Added to Folder" Trigger](https://github.com/esaruoho/apple/blob/main/painpoints/SHORTCUTS-001-ios-no-file-folder-trigger.md) | Shortcuts.app (iOS) |

---

## The pattern across all fourteen

Read together, the filings say the same thing in fourteen dialects.

**The data is already on the machine.** Messages holds every conversation in a SQLite
database. Photos holds every image and its metadata. Activity Monitor reads process
tables the kernel already publishes. HomePod has a thermometer in the room you are
standing in. Nothing needs to be invented — it needs to be handed over.

**The scaffolding is often already built.** Messages' dictionary defines `message`,
`chat`, and `buddy` classes with no verbs that read them. Photos ships a dictionary
that catalogs but cannot edit. Apple designed for the access and then did not ship it.

**Privacy is the stated reason, and it is not a good one.** macOS already has the
Automation privacy framework: the user grants permission per app, explicitly, in
System Settings. Blocking a person from scripting their own data is not privacy. It is
paternalism with a privacy-shaped explanation.

**Where a tool does exist, it must be correct.** SYSTEM-SETTINGS-002 is the newest
filing and the odd one out: Apple identified a real problem, built the panel, shipped
it — and pointed its filter at the wrong field. A missing feature sends you looking for
another way. A tool that silently omits the answer sends you away believing there is
nothing more to find. That is the worse failure.

---

*Filed by [@esaruoho](https://github.com/esaruoho) — software tester, UI enthusiast,
amateur scripter, automation and workflow obsessive, user experience evaluator.
Reporting the missing bits and pieces one at a time.*

[← Back to Automation for the Rest of Us](../)
