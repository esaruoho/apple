# Apple-skill slash commands

Zero-roundtrip Claude Code slash commands. Each `.md` here is a thin pointer
that shells out to a script in `../bin/` — once you type the slash, **no LLM
roundtrip happens**: the shell runs the deterministic tool and reports back.

This is the Sal pattern in Claude Code form: one verb, one result, no dialog.

## What's here

| Slash | Wraps | Pattern |
|-------|-------|---------|
| `/invert <path>` | `bin/invert` | Kindle dark→light inversion (file or folder) |
| `/sal-status` | `bin/sal-archive-status.py --write` | Refresh Sal archive dashboard |
| `/grand-search "<q>"` | `bin/apple-grand-search` | Search all bulk-exporter vaults |
| `/grand-export [--quick]` | `bin/apple-grand-export` | Run every bulk exporter |
| `/qr "<text>" <out.png>` | `bin/sal-qr` | Text → QR PNG (CoreImage) |
| `/photo <out.jpg>` | `bin/sal-take-photo` | Webcam → JPEG (AVFoundation) |
| `/md-rich <file.md>` | `bin/md-to-clipboard` | Markdown → rich-text clipboard |
| `/hey-sal "<sentence>"` | `bin/hey-sal` | Natural-language router → exporter |
| `/plist-probe [--md]` | `bin/app-plist-probe.py` | Scan 1,934 plists for mineable data |
| `/spotlight-export [apps...]` | `bin/spotlight-export.sh` | Compile workflows to Spotlight-reachable .apps |
| `/vocal-shortcuts-list` | `bin/list-vocal-shortcuts.py` | Dump registered Vocal Shortcuts |
| `/siri-phrases` | `bin/sal-siri-list-phrases.py` | Dump Sal-Siri 588-phrase corpus |
| `/workflow-catalog` | `bin/workflow-gen.py --catalog` | Regenerate `scripts.md` |
| `/apple-report [--ai] [--can-run "<spec>"]` | `bin/apple-report` | Full Mac capability dump + AI-workload "can I run X" |
| `/topbar` | `topbar/install.sh` | Install + launch SwiftBar menu-bar toolbox (one 🧰 with live status + click-to-run) |
| `/qr-wifi <SSID> <password>` | `bin/sal-qr` (wrapped) | Wi-Fi-join QR code |

## Install

Symlink each `.md` here into `~/.claude/commands/` so Claude Code can see them:

```bash
./commands/install.sh
```

That script just runs `ln -s` for every file in this directory. Safe to re-run.

## Design rules

- The slash file is **always** a thin shell-out — never asks Claude to "analyze"
  or "summarize". If a summary is wanted, it's a separate slash.
- Every tool writes its own output and (where applicable) ends by revealing the
  artifact (`open -R`, Finder reveal, `pbcopy`, etc.) — no "where did it go?"
  follow-up needed.
- Folder-batch is the multiplier: any tool that accepts a file should accept a
  folder too. This is the Apple-skill-as-LLM-Automator principle codified.

## Why "zero-roundtrip"

Coined in commit `97c2b0a` for `/invert`. The slash is the only LLM touch in the
whole chain — slash → bash → script → kernel → done. No tokens spent on
planning, parameter inference, retry logic, or summarizing.
