# Pattern Reusability

**If you identify a pattern of manual labour and organize it, that pattern becomes an underlying principle which allows for any other reorganization of the pattern.**

The deepest design principle of this project. Every tool here proves it.

## The evolution

1. **HomePod climate** identified the pattern: periodic poll → state diff → notification → dashboard. Manual labour (checking the thermometer) organized into a principle (LaunchAgent + bash + JSON state + Python server).
2. **GitHub Watcher** reused the exact same principle for a different domain. The pattern didn't care whether it was temperature or PRs. Poll, diff, notify, display — transferred wholesale.
3. **prwhy** added a layer: same PR data, reorganized by *strategic meaning* instead of chronology. Same input, different principle applied, different insight produced.
4. **The sdef pipeline** is the same thing at a different scale: `sdef-extract` (poll apps) → `workflow-gen` (organize into recipes) → `spotlight-export` (make reachable) → `shortcut-gen` (make triggerable). Each step is a reorganization of what the previous step produced.
5. **props** extended the pattern from passive monitoring to active triage. Same PR data, but now you can act on it — rebase, build, merge — without leaving the terminal. When it hits a wall (merge conflicts), it hands off to Claude Code with full context. Watch + notify → watch + triage + act + delegate, without breaking the underlying architecture.

> Scripts are single-use; principles are reusable.

## Why this matters

This is what Sal understood intuitively. Automator's patent (US 7,428,535) is literally about this: actions that produce typed data, fed into actions that consume it, with automatic relevance filtering. The pattern is: **identify the manual step → extract the principle → apply it everywhere.**

This is also Russell's Self-Multiplication (P2) discovered independently through automation practice. It is the thread that connects Apple ↔ Paketti ↔ Ray ↔ BBS as one project.

## The practical test

When you build something, ask: *"what is the underlying pattern here, and where else could it apply?"*

- If the answer is "only here," you've built a script.
- If the answer is "anywhere there's periodic state to watch," you've built a principle.
