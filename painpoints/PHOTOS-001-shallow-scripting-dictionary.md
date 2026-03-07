# PHOTOS-001: Photos Scripting Dictionary Is a Read-Only Catalog

**App:** Photos.app
**Intent:** Programmatically import, edit, and export photos with specific settings
**Severity:** Automation dead-end — the sdef exists but covers only album/media object management
**Status:** Open
**Filed:** 2026-03-07

---

## The Friction

Photos has 18 AppleScript commands. Sounds generous. But look at what they actually do:

| What You Can Do | What You Cannot Do |
|---|---|
| List albums | Import photos from a folder |
| List media items | Apply any edit (crop, filter, adjust) |
| Get metadata (name, date, keywords) | Export with specific format/quality |
| Add items to albums | Create smart albums with rules |
| Search by keyword | Run batch edits across selections |
| Spotlight a media item | Control the editing UI |

The scripting dictionary is a **catalog viewer**, not an automation surface. You can read the library. You cannot act on it.

**The practical cost:** A photographer who wants to "import today's shoot, auto-enhance, tag with project name, export as JPEG at 80% quality" must do every step by hand. Every time. For every shoot.

---

## What Sal Would Say

> "The power of the computer should reside in the hands of the one using it."

A photographer's power is in their workflow: import, cull, edit, tag, export. Photos.app has opinions about all of these steps — but it refuses to let you script any of them.

Sal's Principle #2: **Solve a real problem.** Photographers repeat the same import-edit-export cycle hundreds of times. Repetitive manual work is the textbook definition of "a real problem automation should solve."

Sal's Principle #7: **Think in workflows.** The entire photo pipeline — camera to published image — should be expressible as a workflow. Photos breaks the chain. It's a black box in the middle of what should be a continuous pipeline.

---

## The Automation Surface (from our probe)

From the probe data: Photos has **18 AppleScript commands** and **16 classes** (album, media item, folder, keyword, etc.). It has Shortcuts actions for basic library queries but nothing for mutation.

No `import` command. No `export` command. No `edit` or `adjust` command. No `apply filter` command. No way to set export format, resolution, or quality. The scripting dictionary describes the library as a data structure but provides no verbs to act on it.

Photos also has **no URL scheme** for deep actions and **no CLI tool**. The Extensions API (PHEditingExtensionContext) exists for third-party editors but is not exposed to AppleScript or Shortcuts.

---

## What It Should Be

```applescript
-- Import a folder of photos, tag them, export as JPEG
tell application "Photos"
    set imported to import folder "/Users/esa/DCIM/2026-03-07/"
    repeat with photo in imported
        set keywords of photo to {"project-atlas", "march-2026"}
    end repeat
    export imported to "/Users/esa/Exports/" as JPEG with quality 80
end tell
```

```bash
# Or via Shortcuts CLI
shortcuts run "Import and Tag Photos" --input "/Users/esa/DCIM/2026-03-07/"
```

One action per step. The photographer describes the workflow; the computer executes it.

---

## Fix Paths

1. **Apple (ideal):** Add `import`, `export`, and `adjust` commands to the Photos scripting dictionary. Expose format, quality, and resolution as export parameters. Add a `smart album` class with rule-based creation.
2. **Shortcuts (partial):** Apple could add Shortcuts actions for "Import Photos from Folder," "Export Photos As," and "Apply Adjustment." These would at least enable Shortcuts-based workflows.
3. **AppleScript + Photos framework (hack):** A helper app bridging PhotoKit to AppleScript/CLI could expose import/export. Third-party tools like `osxphotos` (Python) exist but are not Apple-supported.
4. **`osxphotos` CLI (workaround today):** The open-source `osxphotos` tool can export with metadata, but cannot import or edit. It reads the Photos SQLite database directly.

---

---

*Part of the [Apple Automation Atlas](../README.md). Tagged for the attention of anyone at Apple who still believes the power of the computer should reside in the hands of the one using it.*

**Filed by [@esaruoho](https://github.com/esaruoho)** -- software tester, UI enthusiast, amateur scripter, automation/workflow obsessive, and user experience evaluator. Reporting the missing bits and pieces one at a time.