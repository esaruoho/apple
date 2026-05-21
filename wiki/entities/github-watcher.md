# GitHub Watcher

PR + CI awareness bot. Polls 20 repos every 10 min, surfaces state via macOS notifications + a dashboard + a curses TUI + a build trigger.

- **Location:** `github-watcher/` in this repo.
- **Pattern:** same shape as [HomePod climate](homepod.md) — bash script + LaunchAgent + `display notification` + Python dashboard server.
- **20 repos across 6 groups:** Personal (apple, paketti, lenr.academy, circuitjs1), Ray Core, Ray Frontend, Ray Backend, Ray Infra, Ray Bots.
- **`repos.json`** — single config file. Both watcher and dashboard read it. Add/remove repos there.
- **State** in `.state/`, **logs** in `logs/`.

## Architecture

```
gh CLI (poll) → JSON state files (diff) → display notification (alert) → Python server (dashboard)
```

## Components

| File | Purpose |
|------|---------|
| `github-watcher.sh` | Poller — runs every 10 min via LaunchAgent, diffs state, sends notifications |
| `dashboard-server.py` | Web dashboard on port 3008 — two-column grid, grouped by project |
| `dashboard.html` | Dashboard UI — auto-refreshes every 60 s, links to GitHub |
| `prwhy.py` | Strategic PR viewer — groups PRs by project-specific pillars |
| `props.py` | PR Operations TUI — curses list / detail / action views with inline triage, rebase, builds, conflict → Claude |
| `prbuild.py` | Mac DMG build trigger — fzf picker, watch run, extract DMG name, download |
| `repos.json` | Single config file — both watcher and dashboard read it |
| `com.esa.github-watcher.plist` | LaunchAgent for poller (every 10 min) |
| `com.esa.github-dashboard.plist` | LaunchAgent for dashboard server (KeepAlive) |

**Dashboard:** `http://localhost:3008` — two-column grid, grouped by category, summary bar, auto-refresh 60s.

**Notifications sent on:** new PR opened, PR closed/merged, CI run failed, CI run recovered.

## Strategic pillars (used by `prwhy`)

| Project | Pillars |
|---------|---------|
| Ray | Intelligence, Agent System, Studio, UI/UX, Feed & Discovery, Stability, Accounts, Infra, Living History, Spike |
| CircuitJS1 | Simulation Accuracy, New Components, Visual/UX, Import/Export, Example Circuits, Bug Fixes |
| LENR Academy | Content, Discovery, UI/UX, Infrastructure |
| Paketti | Workflow, Instruments, Import/Export, UI, Bug Fixes |
| Apple | Automation, Probing, Tools, Documentation |

## Bash functions

`pr` / `prlist` (raw `gh pr list`), `prwhy` (strategic view), `ghd` (open dashboard), `props` (TUI), `prbuild` (DMG trigger). All logged in [`bash-aliases.md`](bash-aliases.md) under "GitHub Automation".

## `props.py` — curses TUI for PR triage

~1,500 lines.

- **Three views:** LIST (navigate PRs with info panel), DETAIL (full PR report + actions), ACTION (live CI polling).
- **Keyboard:** ↑↓ navigate, enter drill in, esc/← go back, R rebase from list, r rebase from detail, b/B build DMG qa/nightly, o open browser, m merge, c resolve conflicts with Claude.
- **Info panel:** bottom of list view shows full details of highlighted PR — plain English CI status with failed check names, sync state, conflicts, pillar + why.
- **CI polling:** 5 s interval in background thread, updates in-place (no log flooding), waits 10–30 s for checks to appear post-rebase.
- **Conflict → Claude handoff:** press `c` → exits curses → `gh pr checkout` → `git rebase` → launches `claude` via `os.execlp` with full context (PR number, title, pillar, conflicting files).
- **Thread safety:** `threading.Lock` around all screen draws, `stdscr.timeout(100)` for responsive input.
- **Terminal compat:** `curs_set(0)` wrapped in `try/except` (some terminals don't support it).
- **Non-TUI mode:** `props --status` for ANSI one-liner output, `props --repo owner/repo` to specify repo.
- **Per-project pillars:** same `PILLAR_SETS` dict shared with prwhy.
- **GitHub API patterns:** compare API (`repos/{o}/{r}/compare/{base}...{head}`) for ahead/behind, update-branch API for rebase (falls back to merge), `gh workflow run` for builds.
- **ThreadPoolExecutor:** parallel compare API fetches for all PRs (max_workers=8).

## `prbuild.py` — DMG build trigger

Triggers Mac DMG builds from CLI, watches, downloads.

- Collapses 9 manual steps into one: find PR → trigger workflow → wait → Discord → click → browser → download → Finder → open.
- Uses `gh workflow run "Mac DMG"` with `workflow_dispatch`, polls `gh run list` for completion.
- Extracts DMG name from logs (`DMG_NAME=RayDMG-*.dmg`), opens GCS download URL in browser (auth-gated).
- fzf picker for interactive PR selection, or `prbuild 2373` for direct.

## Key insight

`gh` CLI is a "Tier 5 dark app" — no sdef, no App Intents, but already CLI-native. Wrapping it in bash functions + LaunchAgents + notifications + dashboards follows the same Apple automation patterns used for Finder and Music. See [tier-5-backdoor](../concepts/tier-5-backdoor.md).
