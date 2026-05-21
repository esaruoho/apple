# Wiki Log

Append-only chronological record of wiki ingests, queries, lint passes, and structural changes.

Format: `## [YYYY-MM-DD] <verb> | <summary>` so the log is greppable:

```bash
grep "^## " wiki/log.md | tail -5    # last 5 entries
grep "ingest" wiki/log.md            # all ingests
```

---

## [2026-05-21] migrate | wiki/ skeleton created — 20 root .md files moved into entities/concepts/lessons/compiled

Initial three-layer split per Karpathy LLM Wiki post. Raw sources stay in `sources/` / `dictionaries/` / `patents/` / `whiteboards/`; executing layers stay in `bin/` / `commands/` / `scripts/`; the new `wiki/` is the LLM-owned knowledge layer. 50 cross-ref rewrites in skill.md / README.md / CLAUDE.md. Generators (`bin/workflow-gen.py`, `bin/gen-skill-indexes.py`) updated to write into `wiki/compiled/`.

## [2026-05-21] ingest | 14 standalone memory files promoted from memory/ into wiki/

`app_plist_probe`, `clipboard_rich_text_recipe`, `mail_smartbox_writes_dead`, `quicktime_pro_scriptability_cliff`, `safari_export_schema_gotchas`, `sal_cross_decade_lineages`, `steve-jobs-rbi`, `tier_5_backdoor_pattern`, `vocal_shortcuts_trigger_position`, `voice_memos_tsrp_atom` → `wiki/concepts/`. `hey_sal_v0_seven_layers`, `sal_session_717_replication_state`, `wwdc_archive_complete` → `wiki/operations/`. `whiteboard_knob` → `wiki/entities/`. One session-recap deleted. MEMORY.md trimmed 301 → 96 lines.

## [2026-05-21] migrate | skill.md tome → index (1,265 → 130 lines)

38 H2 sections extracted to wiki/ pages. New skill.md keeps frontmatter + User Context + conditional Boot Protocol + wiki index. Boot now skips `sal-archive-status.py` unless the message mentions Sal / WWSD / archive / transcript / dashboard / status.

## [2026-05-21] lint | dedup pass — 12 pages had "## From skill.md" appendices, all merged

App-probe, pattern-reusability, thought-multiplier, loupedeck-window-management, whiteboard-knob, sal-like, mail-smart-mailboxes-dead, vocal-shortcuts-trigger, github-watcher rewritten to single coherent pages. Sal-soghoian, automation-tiers, spotlight-automation: appendix stripped (existing top covered everything in deeper detail). One unique nugget saved: principles #28-30 (WWDC 2016 Session 717 Tier 2) inserted into sal-soghoian.md as new Tier 2 section.

## [2026-05-21] build | wiki-index + wiki-lint pipeline + INDEX.md + log.md

`bin/wiki-index.py` auto-generates `wiki/INDEX.md` from filesystem walk + frontmatter/H1/first-paragraph. `bin/wiki-lint.py` checks orphans, oversized pages (>250 lines), broken cross-refs, `## From skill.md` regressions, missing H1, stale memory-type frontmatter. Slash wrappers: `/wiki-index` and `/wiki-lint`. skill.md shrunk further by replacing inline index with pointer to `wiki/INDEX.md`.
