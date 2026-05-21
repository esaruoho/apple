# Scripting Dictionaries (Domain Knowledge)

**31 apps extracted** to `dictionaries/` via `bin/sdef-extract.py`. Each app has:
- `<app>.yaml` — machine-readable: commands, classes, properties, data types
- `<app>.md` — human-readable: full scripting reference with descriptions
- `<app>-examples.md` — ready-to-use AppleScript snippets
- `<app>-probe.yaml` — 13-layer automation probe (from app-probe.py)
- `<app>-probe.md` — human-readable probe results

**Data type chaining** (`dictionaries/_index.yaml`): maps which apps produce/consume which data types — the Automator patent (US 7,428,535) vision realized as a lookup table.

### Key Chains Discovered
- **Image Events → 7 apps**: Produces `alias`/`file` → feeds into Automator, Logic Pro, Preview, Script Editor, TextEdit, iMovie, System Information
- **System Events → 9 apps**: Produces `file` → feeds into Music, Photos, Keynote, Numbers, Pages, QuickTime, Terminal, Mail, Bluetooth
- **Mail → Mail**: `outgoing message` loops back for mail merge workflows
- **Contacts → Contacts**: `person` type for contact manipulation
- **12 apps produce `document`** → feeds into Keynote, Numbers, Pages, QuickTime
- **System Events** is the universal bridge (89 classes, 31 commands) — it can control ANY app's UI

