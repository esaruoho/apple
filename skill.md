---
name: apple
description: Write perfect AppleScript, automate macOS, and optimize workflows for Loupedeck Live integration
domain: global
version: 1.0.0
generated: 2026-03-05T00:00:00Z
tags: [applescript, macos, automation, loupedeck, finder, system-events, workflow]
triggers:
  keywords:
    primary: [applescript, apple script, osascript]
    secondary: [loupedeck, macos automation, finder, system events, activate app, bring to front]
---

# Apple Skill

> Write perfect AppleScript for macOS automation, Loupedeck Live integration, and Ray Browser workflow optimization.

## User Context

- **User**: Esa Ruoho — Apple aficionado, works at Ray Browser
- **Hardware**: Loupedeck Live (physical controller with programmable buttons)
- **Use case**: Loupedeck Live buttons trigger AppleScripts via osascript to launch/activate apps, automate workflows, and optimize the workday
- **OS**: macOS (Darwin)

## Loupedeck Live Integration

The Loupedeck Live software allows custom actions that can run shell commands. AppleScripts are executed via:
```bash
osascript /path/to/script.scpt
# or inline:
osascript -e 'tell application "Finder" to activate'
```

For Loupedeck buttons, scripts should be:
- **Fast** — no unnecessary delays
- **Reliable** — handle edge cases (app not running, etc.)
- **Single-purpose** — one button = one action

## AppleScript Best Practices

1. **Activate apps**: Use `tell application "AppName" to activate`
2. **Check if running**: `if application "AppName" is running then`
3. **System Events for UI**: `tell application "System Events"` for keystroke simulation, menu clicks, window manipulation
4. **Error handling**: Wrap risky operations in `try ... on error ... end try`
5. **Delays**: Only use `delay` when absolutely necessary (UI needs time to respond)
6. **Finder operations**: Finder is always running on macOS — just activate it

## Skill Location

Everything lives in `/Users/esaruoho/work/apple/`:
- `skill.md` — this file (skill definition + knowledge base)
- `scripts.md` — catalog of all AppleScripts
- `scripts/` — the actual `.applescript` files

## Self-Learning Behavior

**This skill is self-updating.** Every conversation in `/Users/esaruoho/work/apple/`:
- **Learn**: When Esa describes workflows, preferences, app behaviors, or macOS quirks — capture them in skill files
- **Update**: New scripts get added to `scripts.md`, new patterns get added to this file, new context gets added to memory
- **Remember**: The skill maintains a living memory at `~/.claude/projects/-Users-esaruoho-work-apple/memory/MEMORY.md` and topic-specific files in that directory
- **Grow**: Over time this skill accumulates deep knowledge of Esa's exact macOS setup, apps, workflows, and automation needs

When Esa tells you something new about his setup, apps, or preferences — **write it down immediately**. Don't wait to be asked.

## Patterns Catalog

See `scripts.md` for the growing catalog of AppleScripts created for Loupedeck Live buttons.
