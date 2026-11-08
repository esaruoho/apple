# Putting images into Apple Notes — what works, what doesn't

Verified 2026-11-08 (macOS Darwin 24.6, Notes, iCloud account), while delivering a whiteboard set into a note.

| Method | Result |
|---|---|
| AppleScript `make new attachment at note id … with data (POSIX file …)` | ❌ Image rendered **twice**, second copy in sliced glitch strips. AppleScript `name of attachments` also lists each name twice — misleading as a check. |
| HTML body with `<img src="data:image/png;base64,…">` (via `make new note … body:`) | ❌ Stored as `public.data`; shows "File · 263 KB" chips, not images. Same for JPEG. |
| Clipboard `set the clipboard to (read file as «class PNGf»)` + Cmd-Down, Cmd-V | ✅ Stored as `public.png`, clean inline render, once each. |

**Gotcha:** files named `.png` from the whiteboard generator are JPEG inside (`file x.png`). Convert with `sips -s format png` before `«class PNGf»`.

**Verification:** count `public.png` rows in `NoteStore.sqlite` (`ZICCLOUDSYNCINGOBJECT where ZNOTE=<pk>`) **and** take a screenshot. Never trust the AppleScript attachment list alone.

**Tool:** `bin/notes-new` (create text note) → `bin/notes-append-images <note-id> imgs…`.
