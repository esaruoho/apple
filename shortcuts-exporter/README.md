# shortcuts-exporter

Catalog every Shortcut in Shortcuts.app as readable markdown so AI assistants
(and humans) can study the user's automation library without opening the app.

## Why

The user's Shortcut library is the canonical "what does this person automate
on their Mac" map. Voice triggers, third-party-app glue, daily routines —
all of it routes through Shortcuts.app. Surfacing it as markdown lets
future Claude sessions cross-reference exporters with the user's own
workflows.

## Data source

`~/Library/Shortcuts/Shortcuts.sqlite` — the same Core Data store that
backs Shortcuts.app. Read via the WAL-safe snapshot helper
(`bin/lib/apple_sqlite_snapshot.py`) so the running Shortcuts.app's
uncommitted WAL state is visible.

## Subcommands

```bash
./scripts/shortcuts-exporter status     # counts + storage overview
./scripts/shortcuts-exporter list       # flat alphabetical list
./scripts/shortcuts-exporter folders    # folder tree with counts
./scripts/shortcuts-exporter show NAME  # full metadata for one Shortcut
./scripts/shortcuts-exporter export     # write the full vault under VAULT_PATH
```

## Vault layout

After `export`, your VAULT_PATH contains:

```
exported/shortcuts/
├── _index.md                 master list, sorted alphabetically
├── folders/
│   └── <slug>/_index.md      per-folder list
└── by-uuid/
    └── <uuid>.md             one file per Shortcut, with frontmatter
```

Each Shortcut's `.md` has YAML frontmatter (name, uuid, folder, actions,
triggers, runs, phrase, app_bundle, source, created, modified, last_run)
followed by a human-readable body and a copy-paste CLI invocation.

## What is NOT in the export

Action contents (`ZSHORTCUTACTIONS.ZDATA`) are stored as serialized
NSKeyedArchiver bplists referencing Apple-internal intent identifiers.
Decoding the action graph into human-readable steps is its own project;
the v0 export surfaces metadata only.

## Setup

```bash
cp .env.example .env
./scripts/shortcuts-exporter export
open ~/work/apple/exported/shortcuts/_index.md
```
