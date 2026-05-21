---
description: Finder tag helper — list/add/set/remove/clear tags, find files by tag, link related files together, or generate a Smart Folder from tags. Apple-native (xattr + plistlib + mdfind). Usage `/tag <subcommand> ...` (run `/tag` with no args to see the full help).
allowed-tools: Bash
argument-hint: <subcommand> [args] | smart <name> <tag>[,<tag>...] [--scope <dir>] [--any]
---

Run the apple-skill `tag` (or `tag-smart`) wrapper on `$ARGUMENTS`.

If `$ARGUMENTS` starts with `smart`, dispatch to `bin/tag-smart` with the rest; otherwise dispatch to `bin/tag`.

Use Bash to execute (one call, then stop):

```
case "$ARGUMENTS" in
  smart\ *) /Users/esaruoho/work/apple/bin/tag-smart ${ARGUMENTS#smart } ;;
  smart)    /Users/esaruoho/work/apple/bin/tag-smart ;;
  *)        /Users/esaruoho/work/apple/bin/tag $ARGUMENTS ;;
esac
```

Subcommands (via `bin/tag`):

- `list <file>...` — show tags
- `add <spec>[,<spec>...] <file>...` — add (preserves existing). `<spec>` is `Name` or `Name:color`
- `set <spec>[,<spec>...] <file>...` — replace
- `remove <name>[,<name>...] <file>...` — drop named tags
- `clear <file>...` — strip all tags
- `find <name> [--scope <dir>]` — files carrying this tag
- `find-all <name>[,<name>] [--scope <dir>]` — AND match
- `find-any <name>[,<name>] [--scope <dir>]` — OR match
- `link [--name N] [--color C] <file> <file>...` — stamp a shared tag across files (bind a conversation-md ↔ the app it spawned ↔ the skill it knowledge-bases)
- `rename <old> <new>` — rename a Finder user-tag globally
- `colors` — list the 7 color names + codes

Smart Folder (via `bin/tag-smart`):

- `/tag smart <name> <tag>[,<tag>...] [--scope <dir>] [--any]` — write a `.savedSearch` under `~/Library/Saved Searches/` and open it
- `/tag smart --tmp <tag>[,<tag>...] [--scope <dir>] [--any]` — throwaway in `/tmp`

After the command completes, report only the lines it printed. Do not summarize.
