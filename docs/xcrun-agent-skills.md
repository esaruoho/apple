# `xcrun agent` / `xcrun agent skills export` — VERIFIED (2026-07-03)

Run for real on the Mac Mini with **Xcode 27.0 (build 27A5209h)**. Everything below is confirmed by
running the tool — NOT guessed. (An earlier email-bot answer that described `--format json` flags, a
JSON schema, and "Siri/Shortcuts capabilities" was **100% fabrication**; ignore it.)

## What `xcrun agent` actually is
`xcrun agent` resolves to `Xcode-beta.app/Contents/Developer/usr/bin/agent`, which is **`mcpbridge` —
a STDIO bridge between MCP (Model Context Protocol) clients and Xcode's MCP tool service**. Run with
no subcommand it reads JSON-RPC 2.0 from stdin and forwards to Xcode's tool service.

It has two useful forms:

### 1. Launch a coding agent WITH Xcode's tools
```
xcrun agent <agent-name>          # supported: claude, claude-ext, codex, gemini, mock-agent
xcrun agent claude --dry-run      # print the resolved command without executing
```
It connects to a running Xcode, fetches the agent's binary path, **auth tokens, environment, and
settings**, then execs the agent with full terminal access + Xcode MCP tools. (i.e. Apple ships a
first-class way to run Claude/Codex/Gemini as coding agents inside Xcode's tool sandbox.)

### 2. Export the built-in agent skills
```
xcrun agent skills export [--output-dir <path>] [--replace-existing]
# default output dir: ./xcode-skills
```
Exports every globally-available **SKILL.md bundle** Apple ships. Verified output:
`Exported 7 skills to <dir>`.

## The 7 skills Apple ships (Xcode 27)
Each is a **SKILL.md bundle** — `SKILL.md` + a `references/` folder (+ `scripts/` for some) — the
SAME format as Claude Code / our own skills. Saved in this repo at **`references/xcode27-agent-skills/`**.

| Skill | What it does |
|---|---|
| `swiftui-specialist` | Authoritative SwiftUI best practices from Apple (Animatable, Environment, ForEach/List identity, localization, soft-deprecated APIs). "Supersedes prior training." |
| `swiftui-whats-new-27` | New SwiftUI APIs/behaviors/deprecations in the 2027 OS releases (@State became a macro; reorderable(); AsyncImage caching; swipeActions; toolbar overflow; DocumentGroup). |
| `uikit-app-modernization` | Modernize UIKit for multi-window (replace mainScreen/interfaceOrientation/app-lifecycle/safe-area with scene-appropriate APIs). |
| `c-bounds-safety` | Adopting the C `-fbounds-safety` extension: pointer annotations, build settings, runtime debugging of bounds violations. |
| `audit-xcode-security-settings` | Audit + progressively enable security build settings / Enhanced Security hardening (warnings, static analyzer, pointer auth, memory tagging, C++ hardening). |
| `modernize-tests` | Migrate XCTest → Swift Testing / adopt modern Swift Testing features. |
| `device-interaction` | Verify iOS app behavior on device/simulator via screenshots, UI hierarchy, touch interactions. |

## Apple's MCP tools these skills call (worth knowing)
The skill bodies instruct the agent to prefer Xcode's MCP tools over shell:
`XcodeGlob` (file discovery), `XcodeGrep` (content search), `XcodeRead` / `XcodeUpdate` (file r/w),
`XcodeLS` (dir listing), `GetTargetBuildSettings`, plus `TaskCreate` for progress tracking. They
explicitly forbid `ls`/`find`/`cat`/`grep` inside a project (extra permission prompts + bypasses
project scoping). Their workflow style (phases, visible plan, TaskCreate tracker) is close to ours.

## Why this matters to us
- Apple has standardized on the **SKILL.md bundle** format — direct validation of the skill approach
  used across `~/work/apple`, convey, and the Claude skills.
- `xcrun agent claude|gemini|codex` is a supported way to run a coding agent inside Xcode with its
  MCP toolset — a convey/apple integration path (e.g. drive Xcode-scoped edits via an agent).

## Install note (how it got here)
Xcode 27 beta 2 was too big for the Mini's 95%-full internal disk, so it lives at
`/Applications/Xcode-beta.app` (extracted by Esa). `xcode-select` currently points at it. The export
was captured and copied into this repo via SSH (pakettibot bridge was jammed at the time).

## Reproduce
```
sudo xcode-select -s /Applications/Xcode-beta.app/Contents/Developer   # if not already
xcrun agent skills export --output-dir /tmp/xcode-skills --replace-existing
```
