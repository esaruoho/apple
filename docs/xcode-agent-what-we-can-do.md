# Xcode 27 `agent` + our stack — what we can actually do (theory, grounded)

Grounded in what we VERIFIED by running it (not guessed). Speculation is labelled.

## Verified facts (the unlock)
- `xcrun agent` = **`mcpbridge`**: an MCP (Model Context Protocol) STDIO bridge to **Xcode's tool
  service**. Raw form `xcrun mcpbridge` reads JSON-RPC 2.0 from stdin, forwards to Xcode's tools.
- `xcrun agent <name>` **execs an EXTERNAL agent BINARY** (claude/codex/gemini/mock-agent) after
  fetching Xcode-provided config: the agent's binary path, **auth tokens, env, settings**, plus the
  Xcode MCP toolset. It uses **ACP (Agent Client Protocol)**. Verified: it errors if the agent binary
  isn't installed ("Could not find 'claude' binary" / ACPError "Agent binary not found").
- Xcode's MCP tools: `XcodeGlob`, `XcodeGrep`, `XcodeRead`, `XcodeUpdate`, `XcodeLS`,
  `GetTargetBuildSettings`, `TaskCreate`. These give an agent **precise, project-scoped** access
  (exact build settings, file contents) — not guessing.
- The 7 shipped skills are standard **SKILL.md bundles** (SKILL.md + references/ + scripts/).

## ⚠️ Licensing — the hard boundary
Xcode 27 is **pre-release** under Apple's Developer Program License (confidentiality). So:
- **Do NOT publish the verbatim Apple bundles** (public repo, public skill). Already untracked from
  the public `esaruoho/apple` repo; they live gitignored/local only.
- We CAN use the **knowledge** privately, and publish only our **own-words** guidance derived from it.
- Our tooling (agent loops, mcpbridge clients, app scaffolders) is our code + Apple's public dev
  tools — fine to build and (our parts) publish.

## What we can do — concrete
### 1. Benefit from the knowledge (works NOW, privately)
`fa-apple-skills` folds the bundles into (a) `~/work/apple/references/xcode27-agent-skills/` which the
**apple email-space's skill_context already reads**, and (b) a private `apple-skills` convey corpus.
So asking the bot / convey "how do I do X in SwiftUI 27 / harden my Xcode build / migrate to Swift
Testing" now draws on **Apple's authoritative playbooks**. Re-run `fa-apple-skills` after each Xcode
update to refresh.

### 2. Improve AppleToolbox / our Swift apps (real)
`swiftui-specialist` + `swiftui-whats-new-27` + `uikit-app-modernization` = Apple's own patterns;
`audit-xcode-security-settings` = hardening. Apply them to AppleToolbox, apple-bar, the exporters:
correct @State/@Observable usage, multi-window scene handling, Enhanced Security build settings.
Plus `GetTargetBuildSettings`/`XcodeRead` give **precise** project data instead of guessing.

### 3. "An Xcode we talk to via our OWN models" — architecturally real
`xcrun mcpbridge` exposes Xcode's tools over MCP. So **any MCP client can drive Xcode** (read/edit
files, build settings, run the tool service). Two paths to use OUR free/on-device brains:
- **(a) mcpbridge client:** an agent loop we write that speaks MCP to `xcrun mcpbridge`, with the
  "brain" = freellmapi (nemotron/gemini, free tier) OR MLX (Qwen-Coder on the Mini, on-device $0) OR
  Apple **FoundationModels** (on-device $0). Start read-only (introspect a project), then read-write.
- **(b) ACP agent:** wrap our brain as an ACP-speaking agent binary so `xcrun agent cloudcity`
  launches it inside Xcode's tool sandbox (the `mock-agent` is the template). More work, more native.

### 4. "Shortcuts-style chat → app" at $0 (the vision, honestly bounded)
Apple's Xcode 27 Agent already does chat→build (via `xcrun agent claude`). The FREE version: drive
mcpbridge with our models, guided by the Apple skills so generated code follows Apple's own guidance.
Pipeline on the Mini: prompt → our model (skill-guided) → scaffold SwiftUI project → `xcodebuild` →
iterate.
- **HONEST caveats:** "$0 / zero-token" is true in the **billing** sense (on-device / free tier), NOT
  in physics — local compute costs time + power. FoundationModels (~3B on-device) is good for
  scaffolding/simple apps, weak on complex codegen; MLX can run bigger coders but slower and it
  contends with the fleet on the Mini. Realistic sweet spot: a **free local SwiftUI scaffolding +
  best-practices assistant**, escalating to gemini (free tier) for hard problems.

## Build roadmap + VERIFIED outcomes (2026-07-04)
1. ✅ `fa-apple-skills` — on-demand export → private KB fold. WORKS.
2. ✅ apple email-space is Xcode-skill-aware (reads the bundles). WORKS.
3. ⚠️ `xcode-agent` — MCP client over `xcrun mcpbridge`: BUILT + handshake works headless
   (server "xcode-tools" v25245.3). BUT **`tools/list` returns 0 even with a project open + first-launch
   done**. Apple **gates the Xcode MCP tools to agents Xcode itself launches** (claude/codex/gemini via
   `xcrun agent`), NOT to external MCP clients. So an external free-brain agent can't use the tools.
4. ❌ ACP `cloudcity` agent — NOT feasible. Agent list is hardcoded (claude/claude-ext/codex/gemini/
   mock-agent); launch config (binary path, tokens, env) is **fetched from a running Xcode** and set in
   Xcode's GUI — no static registration. (`xcrun agent claude` can't even find the installed claude CLI
   because the path is Xcode-config-driven.) mock-agent refuses CLI launch.
5. ✅ `swiftgen` — chat→SwiftUI-app scaffolder, skill-guided, $0 default + gemini escalation. WORKS
   (not gated — pure codegen via freellmapi + the private Apple lens).

## The honest bottom line
- **Free chat→app scaffolding + best-practices review WORKS** (`swiftgen`, `$0`, Apple-guided). This is
  the real, usable win.
- **Driving Xcode's LIVE MCP tools with our own free brain is BLOCKED by Apple's design** — the tools are
  reserved for Xcode-launched, hardcoded agents (claude/codex/gemini, with YOUR API keys). Not routable.
- One native-ish path (future, hacky): configure the `gemini` agent in Xcode's GUI pointed at a `gemini`
  CLI shim that hits freellmapi. Requires Xcode GUI config + a live agent session. Not worth it now.
