# Apple Bundle ID Drift (post-2016)

**Apple silently changed iWork bundle IDs.** Sal's 2016 `.scptd` libraries hardcode the OLD IDs, and on current macOS they error -1728 ("Can't get application id"):

| Sal-era ID (2016) | Current (Sequoia 2026) | Affected libraries |
|---|---|---|
| `com.apple.iWork.Keynote` | `com.apple.Keynote` | DC-Keynote, DC-Keynote-Objects, DC-Assistive-Keynote, DC-Workspace |
| `com.apple.iWork.Pages` | `com.apple.Pages` | DC-Pages |
| `com.apple.iWork.Numbers` | `com.apple.Numbers` | DC-Numbers |

**Patch attempt** (`bin/patch-sal-libraries-for-current-bundle-ids.sh`) decompiles, sed-replaces, and tries to recompile. DC-Pages, DC-Workspace, DC-Keynote-Objects, DC-Assistive-Keynote recompile cleanly. **DC-Keynote and DC-Numbers fail to recompile** because the sdef classes (`«class Ktsh»` etc.) trigger "Access not allowed" assignment errors — Apple changed property accessibility in addition to bundle IDs.

**Live workaround:** `bin/sal-siri-match.py` has a **dead-bundle filter** that skips Sal handlers referencing any of these IDs. The matcher returns "no match" instead of running broken handlers. Replacement is via native user Shortcuts (USER_BOOST=1.5 in the matcher) — see `bin/build-sal-demo-shortcuts.py` for examples that bypass Sal libraries entirely with simple `tell application "Keynote" to ...` syntax (which resolves by name through LaunchServices regardless of bundle ID change).

