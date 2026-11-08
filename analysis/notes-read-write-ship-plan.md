# Apple Notes read+write — whitelabel audit + ship plan (2026-11-08)

## Audit
| Piece | Location | Whitelabeled? |
|---|---|---|
| WRITE: `bin/notes-new` | public `esaruoho/apple` | Yes — no personal paths; defaults iCloud/Notes; account/folder are flags |
| `/notes-new` command | `commands/notes-new.md` | Yes (fixed: removed hardcoded /Users/esaruoho path) |
| READ: `notes-exporter/` | public `esaruoho/apple` | Mostly — README/config.example generic; `config.json` is personal and should stay gitignored |
| `notes` skill (`~/.claude/skills/notes`) | local only | No — names BBS vault paths; its `scripts` symlink was broken (pointed at old `notes-export/`), repaired to `notes-exporter/scripts` |

## Gaps before shipping as "the" Notes skill
1. One skill doc covering read AND write (exporter + notes-new), generic paths.
2. Write side is create-only. Next safe verbs: `notes-append --id` (append to a note *this tool created*, by id), `notes-list` (read-only folders/notes).
3. Test file runnable without a Mac Notes account (md_to_html cases) + build gate.
4. Untested: Google/IMAP Notes account; Notes on older macOS (table import).
5. Decide shape: stays inside `esaruoho/apple` (already public) vs standalone `esaruoho/apple-notes` repo mirrored like apple-energy/apple-rec (standalone canonical on divergence).
