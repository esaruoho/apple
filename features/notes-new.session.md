# notes-new — session

## How to get back
- Transcript: `~/.claude/projects/-Users-esaruoho-work-apple/86265a9a-f9a3-4edf-9750-98c4a6179061.jsonl`
- Session ID: `86265a9a-f9a3-4edf-9750-98c4a6179061`
- Resume: `claude --resume 86265a9a-f9a3-4edf-9750-98c4a6179061`
- Date: 2026-11-08 ~21:35 EET (verified with `date`)

## Audit trail
1. Esa asked whether the apple skill knew enough to create a new Note and post content safely.
   Finding: the notes skill is export-only (read); the only creation code was an unguarded snippet in `bin/workflow-gen.py:870`.
2. Esa: "sure. be careful." → built `bin/notes-new`.
3. Read-only probe: accounts = Google, iCloud.
4. Tests: dry-run HTML OK; Recently Deleted refused; missing folder refused, not created;
   one real note "notes-new test (safe to delete)" created in iCloud/Notes
   (id x-coredata://…/ICNote/p13468); plaintext read back matched, escaping intact.
   The test note was left in place on purpose (the tool never deletes notes), for Esa to remove.

## RESULT
- Commit: see `git log -- bin/notes-new` (direct-push, no PR)
- Files: bin/notes-new, commands/notes-new.md, features/notes-new.feature, features/notes-new.session.md
