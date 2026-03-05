# Sal-Like Tools

Tools that follow Sal Soghoian's automation philosophy: one action, one result. No intermediate steps, no configuration dialogs. The power of the computer resides in the hands of the one using it.

## Criteria

A tool is "Sal-like" when it:
- Collapses multiple manual steps into a single verb
- Produces **durable** results (not ephemeral — teaches the machine, builds lasting context)
- Requires zero configuration at invocation time
- Works from wherever you are (no "first cd to..." prerequisites)

---

## `ghc` — GitHub Clone + Claude

**Command:** `ghc owner/repo`

**What it replaces** (7 manual steps → 1):
1. Browse GitHub, read the README
2. Clone the repo somewhere
3. Open Claude Code
4. Explain the project to Claude
5. Ask Claude to study the conventions
6. Build up context over multiple sessions
7. Forget half of it next time

**What it does:**
Clones the repo into the current directory, launches Claude Code, triggers the `github-cloner` skill which analyzes commits, PRs, issues, contributors, code structure, and conventions. Generates a permanent skill at `~/.claude/skills/<repo-name>/SKILL.md` that persists across all future Claude sessions, on any project, forever.

**Why it's Sal-like:**
One verb, permanent result. It doesn't just do a thing and throw away the context — it *teaches Claude the project*. That teaching persists. Sal always hated ephemeral automation. His Automator workflows, his AppleScript dictionaries — they built up a machine's understanding of what you do. `ghc` does the same for AI-assisted development.

**The final Sal mile:** Should eventually work from Spotlight. Type `ghc paketti`, hit enter, done. When the automation is so embedded in the OS that the terminal isn't even involved.

**Lives at:** `bin/ghc` in this repo, installed to `~/bin/ghc`
**Skill source:** [esaruoho/github-cloner](https://github.com/esaruoho/github-cloner) (public)
**Skills backup:** `esaruoho/esa-skills` (private, all 44+ Claude Code skills)
