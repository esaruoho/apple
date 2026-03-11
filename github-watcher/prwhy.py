#!/usr/bin/env python3
"""prwhy — Show the WHY behind open PRs, grouped by strategic pillar.
Maps each PR to Ray Browser's vision: what it advances, not just what it changes."""

import json
import os
import re
import subprocess
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPOS_FILE = os.path.join(SCRIPT_DIR, "repos.json")

# --- Per-project pillar definitions ---
# Each project gets its own strategic context. The "why" is different per project.

PILLAR_SETS = {
    # Ray ecosystem — browser, UI, backend, infra, bots
    "ray": {
        "pillars": [
            ("Intelligence",     r"intelligen|encoder|reranker|generator|onnx|cluster|semantic|embedding|ml[\- ]|machine.learn|phi-4|bge-|intent.*(profile|detect|cluster)|interest.profile|browsing.history.*cluster|knowledge.graph"),
            ("Agent System",     r"agent|orchestrat|mcp|tool.use|delete_history|browse.*tool"),
            ("Studio",           r"studio|app.gen|raystudio|credit|raybux|workspace|sandbox|digest"),
            ("UI / UX",          r"tabstrip|tab.strip|ui[\- ]|ux|design|layout|header|zone|chip|pin|favorite|nav.system|ray-ui|component|visual|icon|badge"),
            ("Feed & Discovery", r"feed|discovery|crawl|rss|content|recommend|persona|suggestion|template.match"),
            ("Stability",        r"fix|bug|crash|sentry|guard|null|error|cleanup|dedup|replace.*with"),
            ("Accounts",         r"account|auth|login|logout|billing|payment|subscription|profile|settings|polar|oauth|token|refresh"),
            ("Infrastructure",   r"ci[\- /]|deploy|docker|action|workflow|bump|dependabot|cache|checkout|build"),
            ("Living History",   r"history|living.history|export.*tab|pinned.*export"),
            ("Spike / Research", r"spike|poc|experiment|explore|research|wip"),
        ],
        "why": {
            "Intelligence":     "Local ML stack — Ray's core differentiator. Encoder + Reranker + Generator on-device.",
            "Agent System":     "18+ tools for autonomous browser automation. MCP-compatible, orchestrator-driven.",
            "Studio":           "Generative app creation in the browser. Research → plan → generate → build → verify.",
            "UI / UX":          "Custom WebUI interface. TabStrip, Smart Favorites, keyboard-first workflow.",
            "Feed & Discovery": "Content intelligence. RSS ingestion, persona-driven recommendations, template matching.",
            "Stability":        "Production reliability. Crash guards, error handling, code health.",
            "Accounts":         "User system. Auth, billing, credits, profile — the economic layer.",
            "Infrastructure":   "CI/CD, dependencies, deploy pipeline — shipping velocity.",
            "Living History":   "Browsing history as a knowledge asset. Export, search, semantic recall.",
            "Spike / Research": "Exploration. Proving feasibility before committing to a direction.",
        },
    },
    # CircuitJS1 — electronic circuit simulator
    "circuitjs1": {
        "pillars": [
            ("Simulation Accuracy", r"convergence|gmin|transit.time|capacitance|channel.length|modulation|mosfet.model|bjt|diode|scr|opamp|spice|rlgc|lossy|saturable|temperature"),
            ("New Components",      r"add.*model|add.*element|new.*component|subcircuit|optocoupler|relay|timer|loss.free|current.source"),
            ("Visual / UX",         r"color|label|pin|display|scope|oscilloscope|trail|persistence|operating.region|logical.state|duty.cycle"),
            ("Import / Export",     r"import|export|spice|schematic|image|paste"),
            ("Example Circuits",    r"example|circuit|community|contribution|555"),
            ("Bug Fixes",           r"fix|bug|unrealistic|spike|restore|rms"),
        ],
        "why": {
            "Simulation Accuracy": "SPICE-grade fidelity. Making the simulator match real-world component behavior.",
            "New Components":      "Expanding the component library. More elements = more circuits people can simulate.",
            "Visual / UX":         "Making circuits readable at a glance. Color-coding, scopes, visual feedback.",
            "Import / Export":     "Interoperability. SPICE import, schematic image recognition, data exchange.",
            "Example Circuits":    "Learning by example. Curated circuits that teach electronics concepts.",
            "Bug Fixes":           "Correctness. Fixing simulation errors and UI glitches.",
        },
    },
    # LENR Academy — open-source LENR education
    "lenr.academy": {
        "pillars": [
            ("Content",       r"reference|link|external|resource|paper|parkhomov|mfmp|data"),
            ("Discovery",     r"discover|feedback|cycle|search|explore|tool"),
            ("UI / UX",       r"page|layout|component|design|visual|nav"),
            ("Infrastructure", r"ci|deploy|build|test|lint|dependabot|bump"),
        ],
        "why": {
            "Content":        "Building the LENR reference library. Papers, data, researcher profiles.",
            "Discovery":      "Helping users find connections. Feedback cycles, cross-referencing, search.",
            "UI / UX":        "Making LENR knowledge accessible. Clear navigation, readable layouts.",
            "Infrastructure": "Shipping pipeline. CI, deploys, dependencies.",
        },
    },
    # Paketti — Renoise workflow tools
    "paketti": {
        "pillars": [
            ("Workflow",       r"workflow|shortcut|keybind|midi|osc|automation|pattern|sequence"),
            ("Instruments",    r"instrument|sample|plugin|vst|device|chain|effect|modulation"),
            ("Import / Export", r"import|export|convert|format|file|load|save"),
            ("UI",             r"dialog|menu|gui|interface|button|view|panel"),
            ("Bug Fixes",      r"fix|bug|crash|error|nil|issue"),
        ],
        "why": {
            "Workflow":        "Speed. Fewer clicks between idea and sound.",
            "Instruments":     "Sound design power. Deeper instrument/device control.",
            "Import / Export": "Format bridge. Getting sounds in and out of Renoise.",
            "UI":              "Accessible controls. Dialogs and menus that make sense.",
            "Bug Fixes":       "Stability. Fixing crashes and edge cases.",
        },
    },
    # Apple — macOS automation
    "apple": {
        "pillars": [
            ("Automation",     r"script|automat|workflow|shortcut|applescript|osascript"),
            ("Probing",        r"probe|sdef|dictionary|extract|intents|layer"),
            ("Tools",          r"bin/|tool|cli|generator|export"),
            ("Documentation",  r"doc|readme|guide|whiteboard|painpoint"),
        ],
        "why": {
            "Automation":     "Putting power in the user's hands. Sal's credo, continued.",
            "Probing":        "Mapping Apple's automation surface. Every app, every layer.",
            "Tools":          "Pipeline tools. Extract → generate → export → trigger.",
            "Documentation":  "Teaching. Making automation accessible to everyone.",
        },
    },
}

# Map repo names to pillar sets
REPO_TO_SET = {}


def get_pillar_set(repo):
    """Determine which pillar set to use for a given repo."""
    repo_name = repo.split("/")[-1].lower()
    owner = repo.split("/")[0].lower() if "/" in repo else ""

    if repo_name in REPO_TO_SET:
        return PILLAR_SETS[REPO_TO_SET[repo_name]]
    if repo_name == "circuitjs1":
        return PILLAR_SETS["circuitjs1"]
    if repo_name == "lenr.academy":
        return PILLAR_SETS["lenr.academy"]
    if repo_name == "paketti":
        return PILLAR_SETS["paketti"]
    if repo_name == "apple":
        return PILLAR_SETS["apple"]
    if owner == "raybrowser" or repo_name.startswith("ray"):
        return PILLAR_SETS["ray"]
    return PILLAR_SETS["ray"]  # default


def categorize(title, body, branch, repo=""):
    pset = get_pillar_set(repo)
    combined = f"{title} {body} {branch}".lower()
    for name, pattern in pset["pillars"]:
        if re.search(pattern, combined):
            return name
    return "Other"


def get_pillar_why(pillar, repo=""):
    pset = get_pillar_set(repo)
    return pset["why"].get(pillar, "")


def get_label(repo):
    """Look up friendly label from repos.json."""
    if os.path.exists(REPOS_FILE):
        with open(REPOS_FILE) as f:
            for r in json.load(f):
                if f"{r['owner']}/{r['repo']}" == repo:
                    return r.get("label", r["repo"])
    return repo.split("/")[-1]


def fetch_prs(repo):
    try:
        result = subprocess.run(
            ["gh", "pr", "list", "--repo", repo,
             "--json", "number,title,body,headRefName,author",
             "--state", "open"],
            capture_output=True, text=True, timeout=30
        )
        if result.returncode == 0 and result.stdout.strip():
            return json.loads(result.stdout)
    except (subprocess.TimeoutExpired, json.JSONDecodeError):
        pass
    return []


def show_repo_why(repo):
    label = get_label(repo)
    prs = fetch_prs(repo)

    if not prs:
        return

    groups = {}
    group_order = []

    for pr in prs:
        title = pr["title"]
        body = (pr.get("body") or "")[:500]
        branch = pr.get("headRefName", "")
        author = pr.get("author", {}).get("login", "?")
        pillar = categorize(title, body, branch, repo)

        if pillar not in groups:
            groups[pillar] = []
            group_order.append(pillar)
        groups[pillar].append((pr["number"], title, author, branch))

    print(f"\n\033[1;36m━━━ {label} ({repo}) — {len(prs)} open PRs ━━━\033[0m")

    for pillar in group_order:
        why = get_pillar_why(pillar, repo)
        print(f"\n  \033[1;33m▸ {pillar}\033[0m")
        if why:
            print(f"    \033[0;90m{why}\033[0m")
        for num, title, author, branch in groups[pillar]:
            print(f"    \033[0;37m#{num}  {title}  \033[0;90m({author})  \033[0;34m{branch}\033[0m")


def get_current_repo():
    try:
        result = subprocess.run(
            ["git", "remote", "get-url", "origin"],
            capture_output=True, text=True
        )
        if result.returncode == 0:
            url = result.stdout.strip()
            # Handle both HTTPS and SSH
            url = re.sub(r".*github\.com[:/]", "", url)
            url = re.sub(r"\.git$", "", url)
            return url
    except Exception:
        pass
    return None


def main():
    if len(sys.argv) > 1 and sys.argv[1] == "--all":
        if not os.path.exists(REPOS_FILE):
            print("Error: repos.json not found", file=sys.stderr)
            sys.exit(1)
        with open(REPOS_FILE) as f:
            repos = json.load(f)
        for r in repos:
            show_repo_why(f"{r['owner']}/{r['repo']}")
    elif len(sys.argv) > 1:
        show_repo_why(sys.argv[1])
    else:
        repo = get_current_repo()
        if not repo:
            print("Not a git repo. Use: prwhy owner/repo  or  prwhy --all")
            sys.exit(1)
        show_repo_why(repo)

    print()


if __name__ == "__main__":
    main()
