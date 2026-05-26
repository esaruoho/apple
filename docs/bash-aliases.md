---
layout: default
title: "macOS / Apple-Native Bash Aliases & Functions"
---

# macOS / Apple-Native Bash Aliases & Functions


[← Back to home](./)
Extracted from Esa's `~/.bash_profile` — the pure Apple/macOS-native commands and patterns.

## App Launchers

| Alias | Command | Purpose |
|-------|---------|---------|
| `renoise` | `/Applications/Renoise.app/Contents/MacOS/renoise` | Launch Renoise directly from CLI |
| `nightlyfeed` | `Ray Nightly.app --enable-features=RayFeedPrototypes` | Launch Ray Nightly with feed flag |

## Directory Navigation

| Alias | Target | Purpose |
|-------|--------|---------|
| `t9` | `/Volumes/T9/` | T9 external drive |
| `t7` | `/Volumes/macOS/chromium-ray-poc/src` | macOS volume Chromium source |
| `skills` | `~/.claude/skills` | Claude skills directory |
| `poc` | `/Volumes/T9/chromium-ray-poc/src/chrome/ray` | Ray POC source |

## macOS-Specific Functions

### `src()` — Smart Chromium Source Directory
Checks if external volume `/Volumes/macOS` exists, falls back to `~/work/chromium-ray-poc`. Volume-aware directory switching.

### `ask()` — Voice Dictation + Claude
```bash
function ask() {
    osascript ~/ask/start_dictation.scpt &
    claude
}
```
Triggers macOS dictation via AppleScript in background, then launches Claude. **This is a Sal-worthy pattern** — combining AppleScript with CLI tools.

### `utmd()` / `utms()` — UTM Virtual Machine Management
Full disposable VM lifecycle management using `/Applications/UTM.app/Contents/MacOS/utmctl`. Clones base VMs, runs them, auto-cleans on exit. Uses macOS-native UTM virtualization.

### `shardify()` — Log Shard Processing
Processes Ray Browser CI/test log files, splits by shard, filters for failures.

## Developer Workflow Tools

### `ghc` — GitHub Clone + Claude
```bash
ghc owner/repo
ghc https://github.com/owner/repo
```
Clones a GitHub repo into the current directory and immediately launches Claude Code with the `github-cloner` skill. If the repo already exists locally, it just `cd`s in and launches Claude. From `~/work`, running `ghc esaruoho/paketti` creates `~/work/paketti/` and opens Claude there — ready to generate a development skill for that project. Lives at `~/bin/ghc`, symlinked from `~/.claude/skills/github-cloner/scripts/ghc`.

## GitHub Automation

Automating GitHub actions from the CLI — building blocks for repo management workflows.

| Alias/Function | Command | Purpose |
|----------------|---------|---------|
| `pr` / `prlist` | `gh pr list` (with git repo check) | List PRs for current repo |
| `prwhy` | `prwhy.py` (strategic PR viewer) | PRs grouped by project pillar with the WHY |
| `prwhy --all` | All watched repos | Full strategic picture across all projects |
| `props` | `props.py` (curses TUI) | Interactive PR triage — CI, sync, rebase, builds, conflict→Claude resolution |
| `props 2373` | Jump to PR #2373 | Direct to detail view for a specific PR |
| `props --status` | ANSI overview (no TUI) | One-liner status for all PRs |
| `prbuild` | `prbuild.py` | Trigger Mac DMG builds, watch, download. 9 steps → 1 |
| `prbuild 2373` | Build for PR #2373 | Direct DMG build trigger |
| `ghd` | `open http://localhost:3008` | Open GitHub Watcher dashboard |
| `ghc` | Clone + Claude + skill gen | See above |

### `prwhy` — Strategic PR Viewer

Shows open PRs grouped by *what they advance*, not when they were created. Each project gets its own strategic pillars:

- **Apple** → Automation, Probing, Tools, Documentation
- **Paketti** → Workflow, Instruments, Import/Export, UI, Bug Fixes
- **CircuitJS1** → Simulation Accuracy, New Components, Visual/UX, Import/Export, Example Circuits, Bug Fixes
- **LENR Academy** → Content, Discovery, UI/UX, Infrastructure

Usage: `prwhy` (current repo), `prwhy esaruoho/paketti`, or `prwhy --all`.

### GitHub Watcher — PR & CI Awareness Bot

LaunchAgent that polls repos every 10 minutes and sends macOS `display notification` alerts on:
- New PR opened
- PR closed/merged
- CI run failed
- CI run recovered (was failing, now passing)

Dashboard at `http://localhost:3008` — two-column grid grouped by project, auto-refreshes every 60 seconds.

**Underlying pattern:** Same architecture as HomePod climate sensor — periodic poll → state diff → notification → dashboard. The pattern transferred domains wholesale (temperature → PRs). See "Core Principle: Pattern Reusability" in `skill.md`.

### `props` — PR Operations TUI

Curses-based terminal UI for interactive PR triage. Three views: list (navigate with ↑↓, info panel at bottom), detail (full report + actions), action (live CI polling, updated in-place).

**Keyboard shortcuts:**
- **List view**: ↑↓ navigate, enter drill in, R rebase from list, r refresh, esc/q quit
- **Detail view**: r rebase, b/B build DMG qa/nightly, o open in browser, m merge, esc/← back
- **Action view**: c resolve conflicts with Claude Code, o open in browser, esc/← back

When conflicts are detected, press 'c' to: checkout the PR branch → attempt rebase → identify conflicting files → launch Claude Code with full context (PR number, title, pillar, conflict files). Claude takes over the terminal via `os.execlp`.

### `prbuild` — Mac DMG Build Trigger

Collapses 9 manual steps into one: find PR → trigger workflow → wait → Discord notification → click link → browser → download → Finder → open DMG. Uses `gh workflow run "Mac DMG"` with `workflow_dispatch`. Polls for completion, extracts DMG filename from logs, opens GCS download URL.

**Why this matters:** `props` now covers `gh pr merge`, `gh api repos/.../update-branch` (rebase), and `gh workflow run` (builds) — the key `gh` subcommands are wrapped in the TUI with keyboard shortcuts. The progression from passive watching (github-watcher) to strategic viewing (prwhy) to interactive triage (props) proves the Pattern Reusability principle.

## Finder & Desktop Controls

Quick `defaults` commands for Finder behavior — usable directly or via Claude:

| Alias | Command | Purpose |
|-------|---------|---------|
| `deskhide` | `defaults write com.apple.finder CreateDesktop -bool false && killall Finder` | Hide all desktop icons |
| `deskshow` | `defaults write com.apple.finder CreateDesktop -bool true && killall Finder` | Show desktop icons |
| `kf` | `killall Finder` | Restart Finder |
| `hide` | `defaults write com.apple.dock autohide -bool true && killall Dock` | Auto-hide Dock |
| `show` | `defaults write com.apple.dock autohide -bool false && killall Dock` | Show Dock |
| `topbar` | `killall -KILL SystemUIServer` | Restart menu bar |

## .DS_Store Cleanup

| Name | Form | Purpose |
|------|------|---------|
| `ds` | alias `rm .DS_Store` | Delete `.DS_Store` from current directory only |
| `dsprune` | bash function | Recursively delete `.DS_Store` from one or more paths (default: CWD) |

`dsprune` usage:

```bash
dsprune                       # recursive from CWD
dsprune ~/Desktop ~/Downloads # multiple paths, per-path + total count
dsprune -n ~/Pictures         # dry run: list matches, delete nothing
dsprune --dry .               # same, long form
dsprune --help
```

Implementation: `find "$p" -type f -name .DS_Store -print -delete` per path. Dry mode (`-n` / `--dry`) drops `-delete` so it just lists matches. Counts are reported per path; a grand total prints when more than one path is given. Source: `~/.bash_profile`.

## osascript Usage

The `ask()` function shows the pattern: `osascript ~/ask/start_dictation.scpt &` — running AppleScript from bash in the background. This is the same pattern we use for Loupedeck Live buttons.

## Patterns for AppleScript Integration

1. **Background AppleScript**: `osascript script.scpt &` — fire and forget
2. **Volume-aware paths**: Check if `/Volumes/X` exists before using it
3. **App launch via Contents/MacOS/**: Direct binary launch bypasses Finder
4. **UTM CLI control**: macOS virtualization controllable from shell
