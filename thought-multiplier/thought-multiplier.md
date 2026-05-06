# The Thought Multiplier — BBS Made Real Inside Ray Browser

## Part 1: The Original Prompt (What Was Asked)

> This is not a Ray Browser feature. **This IS BBS/Cloudcity** — the personal operating system vision from October 2025 (bbs.txt), now finding its concrete implementation path through Ray Browser's converging stack.

Esa identified a fundamental imbalance in how computers handle human thought: you type once, it goes to one place. To send the same seed idea to four destinations, you type four times. This is **addition** when the physics of thought (Russell's P2) demands **multiplication**.

### The Red Thread (Why This Is BBS)

BBS has always been about this. From the Scribe archive:

- **The Tree Model** (Feb 28): *"our droids are talking to each other... doing the underlying knowledge transfer while we converse about something more fun... instead of us being human clipboards trying to paste around stuff."* — The Thought Multiplier IS the droid. It eliminates the clipboard-human.

- **Dynamic BBS Feeds** (Mar 9): Jaakko independently arrived at the BBS pipeline architecture. `BBS: Ingest → Extract → Analyze → Synthesize → Knowledge Graph → Dashboard` maps exactly onto `Ray: Agent → Scrape → Transform → JSON → Datasource Pool → Studio App`. The Thought Multiplier is the **ingest surface** of this pipeline — the point where human thought enters the system.

- **The Hypergraph Vision** (Mar 18): *"Ray is a browser that remembers what you care about... Foundation for Cloudcity."* The graph destination in this plan isn't a feature — it's the BBS knowledge graph itself, growing from every seed you type.

- **Profile as Living Knowledge Document** (Mar 9): *"Profile + tabstrip state + app creation DNA. Knowledge transfer through circles."* The self-updating Studio apps in this plan ARE the BBS profile — tools that carry your thinking patterns and evolve with you.

### Three Lineages Converging in One Plan

| Lineage | Contribution | Where It Shows Up |
|---------|-------------|-------------------|
| **Sal Soghoian** (Apple automation) | Data type chaining, one-input parallel pipelines, user-first power | Layer 2 (The Fork), the Agent Scripter pipeline |
| **Walter Russell** (RBI) | Self-Multiplication, Rebound, Dead Centers, Love Cycle | The WHY behind every architectural choice |
| **BBS/Cloudcity** (Esa's vision) | The operating system that replaces siloed internet | The WHAT — this entire plan is BBS's ingest→process→distribute cycle |

Ray Browser is the WHERE — the only browser with the stack to run all three simultaneously.

Ray Browser is the only browser with the converging stack to fix this: AI Agent (18 tools, tab interaction), Agent Scripter (visual pipeline with variable substitution), Studio (app baking from natural language, versioned, profile-persistent), Chat with Tabs (LLM that sees your open tabs), and local inference (Phi-4, no cloud required).

The plan: combine these into a **Thought Multiplier** — type once, radiate to many, catch every rebound.

---

## Part 2: The Architecture (Five Layers)

### Layer 1: The Seed Capture (Studio App)

**What**: A Studio-baked app — a single, beautiful text field that lives as a pinned tab. This is the "still center" (P5) from which all motion springs.

**How it works in Ray today**:
- Built via Studio (`chrome://ray-ui/studio/`) — describe it in natural language
- "Build me a minimal text input app with a large textarea, a Send button, and a settings gear. When I press Send, it stores the text in localStorage under `ray-seed-{timestamp}` and dispatches a custom event `seed-ready` on the window."
- Studio bakes it as an HTML/CSS/JS app, sandboxed iframe, persisted to your profile
- Pin this tab. It's always there. It's your **concentration point** (P4 — implosion before explosion)

**What it captures**:
- The raw seed text (original thought, never modified)
- Timestamp
- Optional: which tabs are currently open (context snapshot via Chat with Tabs)

**RBI mapping**: P4 (Implosion) — all energy gathers here before radiating outward. P5 (Dead Center of Rest) — the moment between typing and sending.

---

### Layer 2: The Fork (Agent Scripter Pipeline)

**What**: An Agent Scripter script that takes the seed and **radiates** it to multiple destinations simultaneously.

**How it works in Ray today**:
- Agent Scripter lives at `feed/src/components/workspaces/agent-creator/`
- Scripts are `TabScript` objects with multiple `ScriptStep` objects
- Steps with no `{{step_id.output}}` dependencies run **in parallel**
- Steps that reference previous outputs run **sequentially**

**The Fork Script** (5 parallel branches from one seed):

```
Seed Input (from Layer 1 localStorage)
    |
    +---> Branch 1: ARCHIVE (raw text → local file/RayGraph)
    |
    +---> Branch 2: LLM PROCESS (seed → Phi-4 local → refined version)
    |
    +---> Branch 3: BROWSER/CMS (seed → navigate to blog tab → paste into editor)
    |
    +---> Branch 4: EMAIL (seed → navigate to email tab → compose → paste)
    |
    +---> Branch 5: GRAPH (seed → Studio visualization app → update)
```

**Each branch uses existing Agent tools**:
- Branch 1: `fetch_url` to POST to a local endpoint (or `send_to_studio` for RayGraph)
- Branch 2: Local Phi-4 inference via Intelligence Service (no cloud, private)
- Branch 3: `activate_tab` → `click_element` → `press_key` (type the seed into a CMS)
- Branch 4: `activate_tab` → `click_element` on Compose → `press_key` to paste
- Branch 5: `navigate` to the graph Studio app tab → inject seed data

**All five branches run in parallel** because none depends on another's output. This is instantaneous radiation from a single point — Russell's explosion after implosion.

**RBI mapping**: P2 (Self-Multiplication) — one thought, five expressions. P9 (Thought Transference) — "many spots of sunlight upon the walls and floor... all extensions of one light."

---

### Layer 3: The Destinations (What Each Branch Produces)

#### 3A: The Archive (Raw Seed Preservation)
- **Purpose**: The original thought is NEVER lost or modified
- **Implementation**: A local JSON-Lines file or RayGraph entry
- **Format**: `{ "ts": "...", "seed": "...", "context_tabs": [...] }`
- **Why it matters (RBI P5)**: The dead center of rest — the seed exists in its pure form, the still point from which all transformations radiate

#### 3B: The LLM Processing (Local Phi-4)
- **Purpose**: Transform the seed — expand, refine, challenge, reframe
- **Implementation**: Phi-4 Mini via ONNX Runtime (on-device, 9GB model)
- **Prompt template**: Configurable per use case:
  - "Expand this idea into three paragraphs": for blog writing
  - "Find the logical weakness in this argument": for thinking
  - "Rewrite this as a professional email": for communication
  - "Extract the core principle and state it in one sentence": for distillation
- **Output**: Stored alongside the seed in the archive (3A), tagged as `processed`
- **Privacy**: Chat with Tabs privacy screening catches sensitive seeds before they touch cloud LLMs
- **Why it matters (RBI P3)**: This IS the rebound. The wall (Phi-4) provides the energy. You catch the ball.

#### 3C: The Browser Page (Web Publishing)
- **Purpose**: The seed (or its LLM-processed form) lands in a web context immediately
- **Implementation**: Agent navigates to a known CMS/blog/wiki tab, finds the editor element via accessibility tree, types the content
- **Variants**: Could target Notion, WordPress, Ghost, a company wiki, or another Studio app
- **Why it matters (RBI P9)**: Thought transference — your idea extends from your mind through the machine to the world

#### 3D: The Email (Direct Communication)
- **Purpose**: The seed becomes a message to a specific person
- **Implementation**: Agent activates Gmail/Outlook tab → clicks Compose → fills To/Subject/Body
- **Personalization**: The LLM branch (3B) could produce an email-specific version
- **Why it matters (RBI P8)**: Service Interchange — balanced exchange begins with reaching out

#### 3E: The Graph (Visual Pattern Recognition)
- **Purpose**: See your thinking patterns over time — word frequency, topic clusters, idea evolution
- **Implementation**: Another Studio-baked app that reads from the archive (3A) and renders a live graph
- **Visualization options**:
  - Timeline of seeds (when do you think best?)
  - Topic clusters via BGE embeddings (what are you circling around?)
  - Seed → transformation diff (how much does the LLM change your original?)
  - Connection graph (which seeds reference each other?)
- **Why it matters (RBI P1)**: Two-Way Thinking made visible. You see both the outward expression (what you typed) and the inward pattern (what you're actually thinking about across days/weeks)

---

### Layer 4: The Rebound Capture (Closing the Loop)

**What**: Each destination produces a response. The system captures these and presents them back.

**How it works in Ray today**:
- Agent Scripter `{{step_id.output}}` captures each branch's result
- A **second-phase script** runs after the parallel fork completes:

```
Fork results arrive:
    |
    +---> 3B output (LLM refinement) → compare with original seed
    |
    +---> 3C result (published URL) → store in archive
    |
    +---> 3D result (email sent confirmation) → log
    |
    +---> 3E result (graph updated) → screenshot via `screenshot_tab`
    |
    v
REBOUND SUMMARY (another Studio app — a dashboard)
```

- The Rebound Summary is a **pinned Studio app tab** showing:
  - Your original seed
  - The LLM's transformation (diff-highlighted)
  - Where it was published
  - The graph update
  - A "Next seed" prompt — feeding the next cycle

**RBI mapping**: P3 (The Rebound) — "In a game of tennis, one player serves but two play." You served the seed. Four destinations played back. Now you serve again, informed by all four rebounds.

---

### Layer 5: The Self-Updating Tool (Studio Versioning)

**What**: The entire Thought Multiplier system IS a set of Studio apps. They evolve through conversation.

**How it works in Ray today**:
- Every Studio app has: conversation history (turns), multiple versions (numbered, revertable), publish state
- To update the tool, you don't rewrite code — you continue the conversation:
  - "Add a Slack destination as Branch 6"
  - "Make the LLM branch use Claude instead of Phi-4 for longer seeds"
  - "Change the graph to show weekly topic clusters instead of daily"
- Studio generates a new version. Old versions persist. You can revert.
- Apps are tied to your user profile — log in on another machine, your tools are there

**The tools carry the history of your thinking about how you want to think.** Each version is a record of you refining your own thought-multiplication process. The tool becomes a living expression of P2 — self-multiplying not just your thoughts, but your capacity to multiply thoughts.

**RBI mapping**: P6 (Information Becomes Knowledge) — the tool isn't static code. It's information (your prompts) digested into knowledge (a working system). P10 (Voltage) — each refinement raises the standard. "The temporary abnormalcy becomes a normalcy through acceptance of that standard."

---

## Part 3: The Build Sequence

### Phase 1: The Seed + Archive (Minimum Viable Multiplication)
1. **Studio app**: Single text field + Send button → stores to localStorage
2. **Agent Scripter script**: Reads seed → writes to local archive file
3. **Result**: You type once, it's preserved forever. 1 destination, but the foundation is laid.

### Phase 2: Add the LLM Branch (First Rebound)
4. **Extend the script**: Add Phi-4 local processing step in parallel
5. **Studio app update**: Show original + LLM refinement side by side
6. **Result**: Type once → 2 outputs (original + transformed). First rebound captured.

### Phase 3: Add Browser + Email Branches (Full Radiation)
7. **Extend the script**: Add tab-navigation branches for CMS and email
8. **Configure targets**: Which tabs are your CMS? Your email? (settings in the Studio app)
9. **Result**: Type once → 4 destinations. Full parallel radiation.

### Phase 4: Add the Graph (See Your Thinking)
10. **New Studio app**: Visualization dashboard reading from the archive
11. **BGE embeddings**: Cluster seeds by semantic similarity (local, on-device)
12. **Result**: Your thought patterns become visible over time.

### Phase 5: The Rebound Dashboard (Close the Loop)
13. **New Studio app**: Summary of all branch outputs after each seed
14. **"Next seed" prompt**: The dashboard suggests what to think about next, based on patterns
15. **Result**: The full RBI Love Cycle: GIVING → DEAD CENTER → REGIVING → BALANCE → next GIVING

### Phase 6: Profile Portability + Sharing
16. **All apps in user profile**: Travel between machines
17. **Export/share**: Other Ray users can import your Thought Multiplier configuration
18. **Result**: P9 — your tool becomes an extension that others can adopt. "IBM is a Principle which can never die" — the tool outlives any single session.

---

## Part 4: How This IS BBS (The Architecture Overlay)

The Thought Multiplier maps 1:1 onto the BBS architecture:

```
BBS ARCHITECTURE                    THOUGHT MULTIPLIER IN RAY
─────────────────                   ────────────────────────────
7 Ingest Surfaces                   Layer 1: Seed Capture (Studio app)
  (CLI, Finder, Services,            - The pinned text field IS an ingest surface
   Clipboard, Browser,               - Chat with Tabs = another ingest surface
   Hot Folder, Bookmarks)            - Voice dictation → text = another surface
                                      - Every surface feeds the SAME pipeline

Ingest → Extract → Analyze          Layer 2: The Fork (Agent Scripter)
  → Synthesize                        - Raw seed → archive (extract)
                                      - Seed → Phi-4 (analyze)
                                      - Seed → destinations (synthesize)

Knowledge Graph                      Layer 3E: The Graph
  (YAML frontmatter,                  - BGE embeddings cluster seeds
   hypergraph of interests)           - Ray's self-organizing hypergraph
                                      - THIS IS the BBS knowledge graph

Dashboard / Compositor               Layer 4: Rebound Dashboard
  (presents knowledge)                - Studio app showing all outputs
                                      - "Next seed" suggestion = agentic curation

Open/Closed Circles                  Layer 5: Profile Portability
  (visibility control)                - Studio apps in profile = Closed Circle tools
                                      - Shared app templates = Open Circle sharing

Profile|Profile Mirror               Layer 5: Self-Updating Tools
  (shared data persists               - Conversation history = shared context
   on both sides)                     - Version history = the mirror of evolution
```

### The Missing Piece BBS Was Waiting For

The BBS pipeline existed conceptually. The 7 ingest surfaces existed. But the **processing layer** — the part where a seed idea gets multiplied into multiple useful forms simultaneously — required:

1. **An AI Agent that can interact with tabs** (arrived: Ray AI Agent, 18 tools)
2. **A visual pipeline builder** (arrived: Agent Scripter with variable substitution)
3. **An app factory that creates tools from language** (arrived: Studio)
4. **On-device intelligence that doesn't leak** (arrived: Phi-4 Mini + BGE embeddings)
5. **A profile system that carries tools** (arrived: Studio versioning + user accounts)

All five arrived inside Ray Browser. The BBS ingest→process→distribute cycle can now run **inside the browser itself**, not as a collection of shell scripts and LaunchAgents.

### The Droids Talking (Background Mode)

The Feb 28 Scribe entry described "droids" doing knowledge transfer in the background while humans converse. In Ray, this maps to:

- **`kBackground` agent type** — hidden, can only access spawned tabs, runs without interrupting the user
- The Thought Multiplier's fork branches can run as **background agents** — you type the seed, press Send, and continue browsing while all 5 branches execute silently
- When branches complete, the Rebound Dashboard updates — you check it when YOU want to, not when the machine demands attention
- This is BBS's fundamental UX promise: **the system works FOR you in the background, not AT you in the foreground**

### Circles in Practice

- **Closed Circle**: Your Thought Multiplier configuration, your seed archive, your graph — private to you
- **Open Circle**: The Thought Multiplier as a Studio app template — shareable. Other Ray users import your tool, customize the branches for their own destinations
- **Profile|Profile**: When you share a seed with a collaborator, BOTH of you keep the record. The droid passes the knowledge; the humans keep the context

---

## Part 5: Why Only Ray Browser Can Do This

| Requirement | Ray | Chrome | Arc | ChatGPT Desktop |
|------------|-----|--------|-----|-----------------|
| Programmatic tab interaction | AI Agent (18 tools) | No | No | No |
| Visual pipeline builder | Agent Scripter | No | No | No |
| App generation from natural language | Studio | No | No | No |
| On-device LLM (no cloud) | Phi-4 Mini | No | No | No |
| On-device embeddings | BGE-small / BGE-M3 | No | No | No |
| LLM sees your tabs | Chat with Tabs | No | No | No |
| Apps persist to user profile | Studio versioning | No | No | No |
| Privacy screening on prompts | Local encoder | No | No | No |

No other browser has even THREE of these. Ray has all eight.

---

## Part 6: RBI Cycle Map

```
THE THOUGHT MULTIPLIER AS RUSSELL'S LOVE CYCLE

         GIVING (you type the seed)         REGIVING (4 destinations respond)
      0 ---- 1 ---- 2 ---- 3 ---- 4 ---- 0 ---- 4 ---- 3 ---- 2 ---- 1 ---- 0
   BALANCE   |      |      |      |    CENTER   |      |      |      |    BALANCE
     (rest)  |      |      |      |   (fork)    |      |      |      |   (next seed)
             |      |      |      |             |      |      |      |
          compose  think  focus  SEND        graph  email  blog   LLM
          the      the    the    the         shows  sent   posted refined
          seed     seed   seed   seed        pattern              version

P5: Dead    P4: Implosion gathers        P2: Self-Multiplication radiates
Centers     energy inward                 energy outward through 4 channels
of Rest     before explosion
                                          P3: Each channel rebounds —
                                          the wall provides the energy
```

---

## Part 7: Sal's Verdict — The Automator Patent Fulfilled

Sal's Automator patent (US 7,428,535) described **data type chaining**: one action's output becomes the next action's input. But Automator had four fatal constraints:

1. **Sequential only** — one chain, one path, one output
2. **No intelligence** — actions are dumb transforms, can't understand the data
3. **No persistence** — workflows are static .workflow files, don't evolve
4. **No reach** — Automator can't touch browser tabs, can't talk to web apps

The Thought Multiplier solves all four:

| Automator Constraint | Thought Multiplier Solution | BBS Connection |
|---------------------|---------------------------|----------------|
| Sequential | Parallel fork via Agent Scripter | BBS has 7 ingest surfaces, not 1 |
| No intelligence | Phi-4 local + Claude cloud | The "droid" that does knowledge transfer |
| No persistence | Studio versioning + profile | Profile\|Profile mirror, tools travel |
| No reach | AI Agent's 18 tools (tab interaction) | Browser IS the operating system |

Sal would say: *"This is what I was trying to build. The Automator patent was the seed. It took 20 years and a browser that thinks to grow it."*

The credo lives: *"The power of the computer should reside in the hands of the one using it."* The Thought Multiplier puts the multiplication power in the user's hands — they type the seed, they choose the destinations, they refine the tool through conversation. No programmer required. No "joining the food chain." Pure Sal.

### What Apple Automation Teaches About Implementation Order

From building 288 workflow scripts in this repo, the pattern is clear:

1. **Start with the simplest thing that works** (the activate-finder.applescript principle)
2. **Make it reliable before making it clever** (MosaicKnob lesson: simple beats clever)
3. **Never hide what the user didn't ask to hide** (MosaicKnob lesson: don't minimize excess windows)
4. **One button = one action** (Loupedeck principle: each branch should be independently testable)
5. **Two-pass execution** (Safari overlap bug: resize first, position second → in the Multiplier: capture seed first, fork second)

---

## Part 8: Verification

After each phase, verify:
- **Phase 1**: Type a seed → confirm it appears in localStorage and archive file
- **Phase 2**: Type a seed → confirm both original and Phi-4 output appear side-by-side
- **Phase 3**: Type a seed → confirm CMS editor and email compose are populated
- **Phase 4**: Type 10 seeds over a day → confirm graph shows clustering
- **Phase 5**: Type a seed → confirm rebound dashboard shows all 4 outputs + next-seed suggestion
- **Phase 6**: Log in on second machine → confirm all Studio apps are present

---

## Part 9: Agent Scripter Pipeline Specifications

### Phase 1: Seed + Archive Only

```json
{
  "name": "Thought Multiplier — Archive",
  "description": "Capture seed from Seed Capture tab and write to local archive",
  "steps": [
    {
      "id": "read_seed",
      "action": "execute_javascript",
      "params": {
        "code": "const keys = []; for (let i = 0; i < localStorage.length; i++) { const k = localStorage.key(i); if (k.startsWith('ray-seed-')) keys.push(k); } const latest = keys.sort().reverse()[0]; return localStorage.getItem(latest);"
      }
    },
    {
      "id": "archive",
      "action": "execute_javascript",
      "depends_on": ["read_seed"],
      "params": {
        "code": "const seed = JSON.parse('{{read_seed.output}}'); localStorage.setItem('ray-archive-' + seed.ts, JSON.stringify(seed)); return 'archived';"
      }
    }
  ]
}
```

### Phase 2: Seed + Archive + LLM

```json
{
  "name": "Thought Multiplier — Fork (2 branches)",
  "description": "Archive seed AND process through local Phi-4",
  "steps": [
    {
      "id": "read_seed",
      "action": "execute_javascript",
      "params": {
        "code": "const keys = []; for (let i = 0; i < localStorage.length; i++) { const k = localStorage.key(i); if (k.startsWith('ray-seed-')) keys.push(k); } const latest = keys.sort().reverse()[0]; return localStorage.getItem(latest);"
      }
    },
    {
      "id": "archive",
      "action": "execute_javascript",
      "depends_on": ["read_seed"],
      "params": {
        "code": "const seed = JSON.parse('{{read_seed.output}}'); localStorage.setItem('ray-archive-' + seed.ts, JSON.stringify(seed)); return 'archived';"
      }
    },
    {
      "id": "llm_process",
      "action": "local_inference",
      "depends_on": ["read_seed"],
      "params": {
        "model": "phi-4-mini",
        "prompt": "Expand and refine the following idea. Be concise but insightful. Preserve the original intent while strengthening the argument:\n\n{{read_seed.output}}"
      }
    },
    {
      "id": "store_rebound",
      "action": "execute_javascript",
      "depends_on": ["archive", "llm_process"],
      "params": {
        "code": "const seed = JSON.parse('{{read_seed.output}}'); const rebound = { archive: true, llm: { refined: '{{llm_process.output}}' } }; localStorage.setItem('ray-rebound-' + seed.ts, JSON.stringify(rebound)); return 'rebound stored';"
      }
    }
  ]
}
```

### Phase 3: Full Fork (5 branches)

```json
{
  "name": "Thought Multiplier — Full Fork",
  "description": "5-branch parallel radiation: archive, LLM, browser, email, graph",
  "steps": [
    {
      "id": "read_seed",
      "action": "execute_javascript",
      "params": {
        "code": "const keys = []; for (let i = 0; i < localStorage.length; i++) { const k = localStorage.key(i); if (k.startsWith('ray-seed-')) keys.push(k); } const latest = keys.sort().reverse()[0]; return localStorage.getItem(latest);"
      }
    },
    {
      "id": "branch_archive",
      "action": "execute_javascript",
      "depends_on": ["read_seed"],
      "params": {
        "code": "const seed = JSON.parse('{{read_seed.output}}'); localStorage.setItem('ray-archive-' + seed.ts, JSON.stringify(seed)); return JSON.stringify({status: 'archived', ts: seed.ts});"
      }
    },
    {
      "id": "branch_llm",
      "action": "local_inference",
      "depends_on": ["read_seed"],
      "params": {
        "model": "phi-4-mini",
        "prompt": "Expand and refine the following idea. Be concise but insightful:\n\n{{read_seed.output}}"
      }
    },
    {
      "id": "branch_browser",
      "action": "activate_tab",
      "depends_on": ["read_seed"],
      "params": {
        "tab_pattern": "{{settings.cms_tab_pattern}}",
        "then": [
          { "action": "click_element", "selector": "{{settings.cms_editor_selector}}" },
          { "action": "press_key", "text": "{{read_seed.output}}" }
        ]
      }
    },
    {
      "id": "branch_email",
      "action": "activate_tab",
      "depends_on": ["read_seed"],
      "params": {
        "tab_pattern": "{{settings.email_tab_pattern}}",
        "then": [
          { "action": "click_element", "selector": "[aria-label='Compose']" },
          { "action": "press_key", "text": "{{read_seed.output}}" }
        ]
      }
    },
    {
      "id": "branch_graph",
      "action": "execute_javascript",
      "depends_on": ["read_seed"],
      "params": {
        "code": "window.dispatchEvent(new CustomEvent('seed-ready', { detail: JSON.parse('{{read_seed.output}}') })); return 'graph notified';"
      }
    },
    {
      "id": "store_rebound",
      "action": "execute_javascript",
      "depends_on": ["branch_archive", "branch_llm", "branch_browser", "branch_email", "branch_graph"],
      "params": {
        "code": "const seed = JSON.parse('{{read_seed.output}}'); const rebound = { archive: true, llm: { refined: '{{branch_llm.output}}' }, browser: { status: '{{branch_browser.output}}' }, email: { status: '{{branch_email.output}}' }, graph: { status: '{{branch_graph.output}}' } }; localStorage.setItem('ray-rebound-' + seed.ts, JSON.stringify(rebound)); window.dispatchEvent(new CustomEvent('rebound-complete')); return 'full rebound stored';"
      }
    }
  ]
}
```

### Parallelism Diagram

Steps that depend ONLY on `read_seed` (not on each other) run **in parallel**:

```
read_seed
    |
    +---> branch_archive  (parallel)
    +---> branch_llm      (parallel)
    +---> branch_browser   (parallel)
    +---> branch_email     (parallel)
    +---> branch_graph     (parallel)
    |
    v
store_rebound (waits for ALL branches)
```

---

## Part 10: Archive Schema

### Seed Record (JSONL)

```json
{
  "ts": "2026-03-20T09:15:32.123Z",
  "seed": "The original thought, exactly as typed. Never modified.",
  "branches": {
    "archive": true,
    "llm": true,
    "browser": false,
    "email": false,
    "graph": true
  },
  "context_tabs": [
    { "url": "https://example.com/article", "title": "Some article open at the time" }
  ]
}
```

### Rebound Record

```json
{
  "ts": "2026-03-20T09:15:32.123Z",
  "archive": true,
  "llm": {
    "model": "phi-4-mini",
    "prompt_template": "expand",
    "refined": "The LLM's refined version of the seed...",
    "processing_ms": 1250
  },
  "browser": {
    "url": "https://blog.example.com/new-post",
    "status": "published"
  },
  "email": {
    "to": "collaborator@example.com",
    "subject": "Re: idea",
    "status": "composed"
  },
  "graph": {
    "clusters": 4,
    "connections": 12,
    "nearest_seed": "2026-03-19T14:22:01.000Z"
  },
  "next_seed": "You've been circling around X — what if you tried Y?"
}
```

---

## Part 11: Studio Prompts (Paste Into Ray Studio)

### Seed Capture (Phase 1)

```
Build me a minimal text input app with a large textarea, a Send button, and a settings gear icon. Dark theme (#0a0a0f background, #7c6aef accent). When I press Send or Cmd+Enter, it stores the text in localStorage under `ray-seed-{ISO timestamp}` as JSON with fields: ts, seed, branches (object of enabled destinations), context_tabs (empty array). Then dispatch a custom event `seed-ready` on the window with the seed data as detail. Show a brief "Seed captured" flash notification. Below the input, show the 5 most recent seeds with relative timestamps, clickable to reload. The settings gear toggles a panel with 5 destination toggles: Archive (on by default), LLM Process, Browser/CMS, Email, Graph. Persist toggle state in localStorage under `thought-multiplier-branches`. Show total seed count in the header.
```

### Rebound Dashboard (Phase 5)

```
Build me a dashboard app that reads seed data from localStorage (keys starting with `ray-seed-`) and shows the most recent seed with its rebound data. Dark theme (#0a0a0f background). Show: the original seed text in a card, then a 2-column grid of 5 branch cards (Archive green #4ade80, LLM pink #f472b6, Browser blue #60a5fa, Email amber #fbbf24, Graph purple #a78bfa). Each card has: branch name, status (Saved/Complete/Published/Sent/Updated or Pending), and the output text. Rebound data comes from localStorage under `ray-rebound-{timestamp}` as JSON with archive, llm, browser, email, graph fields. At the bottom, a "Next Seed" card with accent border shows a suggestion (from rebound.next_seed). Clicking it dispatches `navigate-to-seed` event. Auto-refresh every 3 seconds. Listen for `seed-ready` and `rebound-complete` custom events.
```

### Graph Viewer (Phase 4)

```
Build me a thought pattern visualization app. Dark theme (#0a0a0f). Three view modes via toolbar buttons: Clusters (canvas graph), Timeline (vertical list), Words (tag cloud). Reads seeds from localStorage (keys `ray-seed-*`). Clusters view: canvas with colored dot nodes grouped by word-overlap similarity (Jaccard > 0.15). Timeline view: chronological list with colored dots and timestamps. Words view: word frequency cloud excluding stop words, sized by frequency. Show stats (seed count, cluster count) in the toolbar. Auto-refresh on `seed-ready` events. 6 cluster colors rotating: green, pink, blue, amber, purple, orange.
```

### Seed Capture v2 — With LLM Side-by-Side (Phase 2 Update)

```
Update: after sending a seed, show a split view below the textarea. Left side: "Original" with the raw seed text. Right side: "Refined" with the LLM output (read from localStorage `ray-rebound-{ts}` field llm.refined). Highlight differences with a green left border. Add a "Copy Refined" button. If no LLM output yet, show "Processing..." with a subtle pulse animation. Poll localStorage every 2 seconds for the rebound data.
```
