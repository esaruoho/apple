#!/usr/bin/env python3
"""props — PR Operations. Full status, strategic context, and actions for any PR.

The fzf picker IS the triage view — CI status, rebase state, conflicts, pillar,
all visible before you pick. Pick a PR → go straight to action.

Usage:
  props                      # interactive picker with full status (fzf)
  props 2373                 # go straight to PR #2373
  props --status             # print status overview (no fzf)
"""

import json
import os
import re
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPOS_FILE = os.path.join(SCRIPT_DIR, "repos.json")

# --- Per-project pillar definitions ---
PILLAR_SETS = {
    "ray": {
        "pillars": [
            ("Intelligence",     r"intelligen|encoder|reranker|generator|onnx|cluster|semantic|embedding|ml[\- ]|machine.learn|phi-4|bge-|intent.*(profile|detect|cluster)|interest.profile|browsing.history.*cluster|knowledge.graph"),
            ("Agent System",     r"agent|orchestrat|mcp|tool.use|delete_history|browse.*tool"),
            ("Studio",           r"studio|app.gen|raystudio|credit|raybux|workspace|sandbox|digest"),
            ("UI / UX",         r"tabstrip|tab.strip|ui[\- ]|ux|design|layout|header|zone|chip|pin|favorite|nav.system|ray-ui|component|visual|icon|badge"),
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
    "circuitjs1": {
        "pillars": [
            ("Sim Accuracy", r"convergence|gmin|transit.time|capacitance|channel.length|modulation|mosfet.model|bjt|diode|scr|opamp|spice|rlgc|lossy|saturable|temperature"),
            ("New Components", r"add.*model|add.*element|new.*component|subcircuit|optocoupler|relay|timer|loss.free|current.source"),
            ("Visual / UX",   r"color|label|pin|display|scope|oscilloscope|trail|persistence|operating.region|logical.state|duty.cycle"),
            ("Import/Export",  r"import|export|spice|schematic|image|paste"),
            ("Examples",       r"example|circuit|community|contribution|555"),
            ("Bug Fixes",      r"fix|bug|unrealistic|spike|restore|rms"),
        ],
        "why": {
            "Sim Accuracy":  "SPICE-grade fidelity. Making the simulator match real-world component behavior.",
            "New Components": "Expanding the component library. More elements = more circuits people can simulate.",
            "Visual / UX":   "Making circuits readable at a glance. Color-coding, scopes, visual feedback.",
            "Import/Export":  "Interoperability. SPICE import, schematic image recognition, data exchange.",
            "Examples":       "Learning by example. Curated circuits that teach electronics concepts.",
            "Bug Fixes":      "Correctness. Fixing simulation errors and UI glitches.",
        },
    },
    "lenr.academy": {
        "pillars": [
            ("Content",        r"reference|link|external|resource|paper|parkhomov|mfmp|data"),
            ("Discovery",      r"discover|feedback|cycle|search|explore|tool"),
            ("UI / UX",        r"page|layout|component|design|visual|nav"),
            ("Infrastructure", r"ci|deploy|build|test|lint|dependabot|bump"),
        ],
        "why": {
            "Content":        "Building the LENR reference library. Papers, data, researcher profiles.",
            "Discovery":      "Helping users find connections. Feedback cycles, cross-referencing, search.",
            "UI / UX":        "Making LENR knowledge accessible. Clear navigation, readable layouts.",
            "Infrastructure": "Shipping pipeline. CI, deploys, dependencies.",
        },
    },
    "paketti": {
        "pillars": [
            ("Workflow",       r"workflow|shortcut|keybind|midi|osc|automation|pattern|sequence"),
            ("Instruments",    r"instrument|sample|plugin|vst|device|chain|effect|modulation"),
            ("Import/Export",  r"import|export|convert|format|file|load|save"),
            ("UI",             r"dialog|menu|gui|interface|button|view|panel"),
            ("Bug Fixes",      r"fix|bug|crash|error|nil|issue"),
        ],
        "why": {
            "Workflow":       "Speed. Fewer clicks between idea and sound.",
            "Instruments":    "Sound design power. Deeper instrument/device control.",
            "Import/Export":  "Format bridge. Getting sounds in and out of Renoise.",
            "UI":             "Accessible controls. Dialogs and menus that make sense.",
            "Bug Fixes":      "Stability. Fixing crashes and edge cases.",
        },
    },
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

C_RESET  = "\033[0m"
C_BOLD   = "\033[1m"
C_DIM    = "\033[0;90m"
C_RED    = "\033[1;31m"
C_GREEN  = "\033[1;32m"
C_YELLOW = "\033[1;33m"
C_BLUE   = "\033[1;34m"
C_CYAN   = "\033[1;36m"
C_WHITE  = "\033[0;37m"

GCS_BASE = "https://storage.cloud.google.com/ray-ci/dmg"


def run_cmd(cmd, timeout=30):
    return subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)


def notify(title, message, sound="Glass"):
    subprocess.run(["osascript", "-e",
        f'display notification "{message}" with title "{title}" sound name "{sound}"'])


def get_pillar_set(repo):
    name = repo.split("/")[-1].lower()
    owner = repo.split("/")[0].lower() if "/" in repo else ""
    if name == "circuitjs1": return PILLAR_SETS["circuitjs1"]
    if name == "lenr.academy": return PILLAR_SETS["lenr.academy"]
    if name == "paketti": return PILLAR_SETS["paketti"]
    if name == "apple": return PILLAR_SETS["apple"]
    if owner == "raybrowser" or name.startswith("ray"): return PILLAR_SETS["ray"]
    return PILLAR_SETS["ray"]


def categorize(title, body, branch, repo):
    pset = get_pillar_set(repo)
    combined = f"{title} {body} {branch}".lower()
    for name, pattern in pset["pillars"]:
        if re.search(pattern, combined):
            return name
    return "Other"


def get_pillar_why(pillar, repo):
    return get_pillar_set(repo)["why"].get(pillar, "")


def detect_repo():
    result = run_cmd(["git", "remote", "get-url", "origin"])
    if result.returncode == 0:
        url = result.stdout.strip()
        url = re.sub(r".*github\.com[:/]", "", url)
        url = re.sub(r"\.git$", "", url)
        return url
    return None


def fetch_prs_full(repo):
    """Fetch all open PRs with full metadata in one call."""
    result = run_cmd([
        "gh", "pr", "list", "--repo", repo, "--state", "open",
        "--json", "number,title,headRefName,baseRefName,author,isDraft,"
                  "mergeable,mergeStateStatus,reviewDecision,statusCheckRollup,"
                  "additions,deletions,changedFiles,commits,labels,body,url"
    ], timeout=30)
    if result.returncode == 0:
        return json.loads(result.stdout)
    return []


def fetch_compare(repo, base, head):
    result = run_cmd([
        "gh", "api", f"repos/{repo}/compare/{base}...{head}",
        "--jq", "[.behind_by, .ahead_by] | @tsv"
    ])
    if result.returncode == 0:
        parts = result.stdout.strip().split("\t")
        if len(parts) == 2:
            return {"behind": int(parts[0]), "ahead": int(parts[1])}
    return {"behind": 0, "ahead": 0}


def fetch_all_compares(repo, prs):
    """Fetch ahead/behind for all PRs in parallel."""
    compares = {}
    with ThreadPoolExecutor(max_workers=8) as pool:
        futures = {}
        for pr in prs:
            key = pr["number"]
            f = pool.submit(fetch_compare, repo, pr["baseRefName"], pr["headRefName"])
            futures[f] = key
        for f in as_completed(futures):
            compares[futures[f]] = f.result()
    return compares


def build_status_line(pr, compare, repo):
    """Build a single-line status string for fzf picker."""
    num = pr["number"]
    title = pr["title"]
    branch = pr["headRefName"]
    base = pr["baseRefName"]
    author = pr["author"]["login"]
    draft = pr.get("isDraft", False)
    body = (pr.get("body") or "")[:300]
    mergeable = pr.get("mergeable", "UNKNOWN")

    checks = pr.get("statusCheckRollup", [])
    ci_fail = sum(1 for c in checks if (c.get("conclusion") or "").upper() == "FAILURE")
    ci_pending = sum(1 for c in checks if (c.get("conclusion") or c.get("status") or "").upper()
                     not in ("SUCCESS", "FAILURE", "SKIPPED", "NEUTRAL"))
    ci_pass = sum(1 for c in checks if (c.get("conclusion") or "").upper() == "SUCCESS")

    behind = compare.get("behind", 0)

    pillar = categorize(title, body, branch, repo)

    # CI indicator
    if ci_fail > 0:
        ci = f"\033[1;31mCI✗{ci_fail}\033[0m"
    elif ci_pending > 0:
        ci = f"\033[1;33mCI● \033[0m"
    elif ci_pass > 0:
        ci = f"\033[1;32mCI✓ \033[0m"
    else:
        ci = f"\033[0;90mCI? \033[0m"

    # Rebase indicator
    if behind == 0:
        rebase = f"\033[1;32m✓sync\033[0m"
    elif behind < 10:
        rebase = f"\033[1;31m↓{behind:<4}\033[0m"
    else:
        rebase = f"\033[1;31m↓{behind:<4}\033[0m"

    # Conflicts
    if mergeable == "CONFLICTING":
        conflict = f"\033[1;31m⚡\033[0m"
    else:
        conflict = " "

    # Draft
    draft_str = f"\033[1;33mD\033[0m" if draft else " "

    # Pillar (short)
    pillar_short = pillar[:14].ljust(14)

    # Ready to merge?
    blockers = []
    if ci_fail > 0: blockers.append("ci")
    if behind > 0: blockers.append("rebase")
    if mergeable == "CONFLICTING": blockers.append("conflicts")
    if draft: blockers.append("draft")

    if not blockers:
        ready = f"\033[1;32m✓READY\033[0m"
    else:
        ready = f"\033[0;90m------\033[0m"

    # Title (truncated)
    title_trunc = title[:48].ljust(48)
    author_str = author[:16].ljust(16)

    return (f"{ci} {rebase} {conflict}{draft_str} {ready}  "
            f"#{num:<5}  {title_trunc}  "
            f"\033[0;90m{author_str}\033[0m  "
            f"\033[1;34m{pillar_short}\033[0m")


def pick_pr_fzf(prs, compares, repo):
    """Status-rich fzf picker — triage at a glance."""
    lines = []
    for pr in prs:
        compare = compares.get(pr["number"], {"behind": 0, "ahead": 0})
        line = build_status_line(pr, compare, repo)
        lines.append(line)

    header = (f"{'CI':4} {'SYNC':6} {'':2} {'READY':6}  "
              f"{'PR':<7} {'TITLE':48}  {'AUTHOR':16}  {'PILLAR':14}")

    try:
        result = subprocess.run(
            ["fzf", "--ansi", "--height=30", "--reverse",
             "--prompt=props> ",
             f"--header={header}",
             "--no-mouse"],
            input="\n".join(lines), capture_output=True, text=True
        )
    except FileNotFoundError:
        print("fzf not found. Use: props 2373", file=sys.stderr)
        sys.exit(1)

    if result.returncode != 0 or not result.stdout.strip():
        sys.exit(0)

    match = re.search(r"#(\d+)", result.stdout)
    if match:
        return int(match.group(1))
    sys.exit(1)


def display_pr(pr, repo, compare):
    """Full PR report."""
    num = pr["number"]
    title = pr["title"]
    branch = pr["headRefName"]
    base = pr["baseRefName"]
    author = pr["author"]["login"]
    body = (pr.get("body") or "")[:500]
    checks = pr.get("statusCheckRollup", [])
    mergeable = pr.get("mergeable", "UNKNOWN")
    review = pr.get("reviewDecision") or "NONE"
    draft = pr.get("isDraft", False)
    adds = pr.get("additions", 0)
    dels = pr.get("deletions", 0)
    files = pr.get("changedFiles", 0)
    commits = len(pr.get("commits", []))
    labels = [l["name"] for l in pr.get("labels", [])]
    behind = compare.get("behind", 0)
    ahead = compare.get("ahead", 0)

    pillar = categorize(title, body, branch, repo)
    why = get_pillar_why(pillar, repo)

    ci_pass = sum(1 for c in checks if (c.get("conclusion") or "").upper() == "SUCCESS")
    ci_fail = sum(1 for c in checks if (c.get("conclusion") or "").upper() == "FAILURE")
    ci_skip = sum(1 for c in checks if (c.get("conclusion") or "").upper() in ("SKIPPED", "NEUTRAL"))
    ci_pending = len(checks) - ci_pass - ci_fail - ci_skip

    print(f"\n{C_CYAN}{'━' * 60}{C_RESET}")
    print(f"{C_BOLD}  #{num}  {title}{C_RESET}")
    print(f"{C_CYAN}{'━' * 60}{C_RESET}")

    print(f"\n  {C_YELLOW}▸ {pillar}{C_RESET}")
    if why:
        print(f"    {C_DIM}{why}{C_RESET}")

    print(f"\n  {C_WHITE}Branch{C_RESET}    {C_BLUE}{branch}{C_RESET} → {base}")
    print(f"  {C_WHITE}Author{C_RESET}    {author}")
    print(f"  {C_WHITE}Changes{C_RESET}   {C_GREEN}+{adds}{C_RESET} {C_RED}-{dels}{C_RESET} in {files} files ({commits} commit{'s' if commits != 1 else ''})")
    if labels:
        print(f"  {C_WHITE}Labels{C_RESET}    {', '.join(labels)}")
    if draft:
        print(f"  {C_WHITE}Draft{C_RESET}     {C_YELLOW}Yes — not ready for merge{C_RESET}")

    print()
    if behind == 0:
        print(f"  {C_GREEN}✓ Up to date{C_RESET} with {base} ({ahead} ahead)")
    else:
        print(f"  {C_RED}✗ {behind} behind {base}{C_RESET} ({ahead} ahead) — needs rebase")

    if mergeable == "MERGEABLE":
        print(f"  {C_GREEN}✓ No conflicts{C_RESET}")
    elif mergeable == "CONFLICTING":
        print(f"  {C_RED}✗ Has merge conflicts{C_RESET}")
    else:
        print(f"  {C_YELLOW}● Merge: {mergeable}{C_RESET}")

    if review == "APPROVED":
        print(f"  {C_GREEN}✓ Approved{C_RESET}")
    elif review == "CHANGES_REQUESTED":
        print(f"  {C_RED}✗ Changes requested{C_RESET}")
    else:
        print(f"  {C_DIM}○ No reviews{C_RESET}")

    print()
    if ci_fail > 0:
        print(f"  {C_RED}✗ CI: {ci_fail} failing{C_RESET}", end="")
    elif ci_pending > 0:
        print(f"  {C_YELLOW}● CI: {ci_pending} pending{C_RESET}", end="")
    elif ci_pass > 0:
        print(f"  {C_GREEN}✓ CI: all passing{C_RESET}", end="")
    else:
        print(f"  {C_DIM}○ No CI{C_RESET}", end="")

    parts = []
    if ci_pass: parts.append(f"{ci_pass} passed")
    if ci_fail: parts.append(f"{ci_fail} failed")
    if ci_pending: parts.append(f"{ci_pending} pending")
    if ci_skip: parts.append(f"{ci_skip} skipped")
    if parts:
        print(f"  {C_DIM}({', '.join(parts)}){C_RESET}")
    else:
        print()

    for c in checks:
        conclusion = (c.get("conclusion") or c.get("status") or "?").upper()
        name = c.get("name", c.get("context", "?"))
        if conclusion == "SUCCESS":
            icon = f"{C_GREEN}✓{C_RESET}"
        elif conclusion == "FAILURE":
            icon = f"{C_RED}✗{C_RESET}"
        elif conclusion in ("SKIPPED", "NEUTRAL"):
            icon = f"{C_DIM}○{C_RESET}"
        else:
            icon = f"{C_YELLOW}●{C_RESET}"
        print(f"    {icon} {name}")

    blockers = []
    if ci_fail > 0: blockers.append("CI failing")
    if behind > 0: blockers.append(f"behind {base}")
    if mergeable == "CONFLICTING": blockers.append("conflicts")
    if review == "CHANGES_REQUESTED": blockers.append("changes requested")
    if draft: blockers.append("draft")

    print()
    if not blockers:
        print(f"  {C_GREEN}{C_BOLD}Ready to merge.{C_RESET}")
    else:
        print(f"  {C_RED}{C_BOLD}Blocked:{C_RESET} {', '.join(blockers)}")

    return {
        "behind": behind, "mergeable": mergeable, "ci_fail": ci_fail,
        "ci_pending": ci_pending, "draft": draft, "branch": branch,
        "base": base, "number": num, "title": title, "blockers": blockers,
    }


def show_actions(state, repo):
    """Interactive action menu."""
    num = state["number"]
    branch = state["branch"]
    base = state["base"]
    title = state["title"]

    is_ray_browser = (repo == "raybrowser/chromium-ray-poc")

    actions = []
    keys = []

    actions.append(f"  {C_WHITE}[o]{C_RESET} Open in browser")
    keys.append("o")

    if state["behind"] > 0:
        actions.append(f"  {C_YELLOW}[r]{C_RESET} Rebase on {base}")
        keys.append("r")

    if is_ray_browser:
        actions.append(f"  {C_BLUE}[b]{C_RESET} Build Mac DMG (qa)")
        keys.append("b")
        actions.append(f"  {C_BLUE}[B]{C_RESET} Build Mac DMG (nightly)")
        keys.append("B")

    if not state["blockers"]:
        actions.append(f"  {C_GREEN}[m]{C_RESET} Merge (squash)")
        keys.append("m")
    elif state["mergeable"] != "CONFLICTING" and not state["draft"]:
        actions.append(f"  {C_DIM}[m] Merge (blocked: {', '.join(state['blockers'])}){C_RESET}")

    actions.append(f"  {C_DIM}[q]{C_RESET} Quit")
    keys.append("q")

    print(f"\n  {C_CYAN}Actions:{C_RESET}")
    for a in actions:
        print(a)

    try:
        choice = input(f"\n  > ").strip()
    except (EOFError, KeyboardInterrupt):
        print()
        return

    if choice == "o":
        subprocess.run(["gh", "pr", "view", str(num), "--repo", repo, "--web"])
    elif choice == "r" and "r" in keys:
        do_rebase(repo, num, branch, base)
    elif choice == "b" and "b" in keys:
        do_build(repo, num, branch, title, "qa")
    elif choice == "B" and "B" in keys:
        do_build(repo, num, branch, title, "nightly")
    elif choice == "m" and not state["blockers"]:
        do_merge(repo, num, branch, title)


def do_rebase(repo, num, branch, base):
    print(f"\n  {C_YELLOW}▸ Rebasing {branch} on {base}...{C_RESET}")
    result = run_cmd([
        "gh", "api", "-X", "PUT",
        f"repos/{repo}/pulls/{num}/update-branch",
        "-f", "update_method=rebase"
    ])
    if result.returncode == 0:
        print(f"  {C_GREEN}✓ Rebase triggered.{C_RESET} CI will re-run.")
        notify("Rebase Triggered", f"PR #{num} rebasing on {base}")
    else:
        result2 = run_cmd([
            "gh", "api", "-X", "PUT",
            f"repos/{repo}/pulls/{num}/update-branch",
            "-f", "update_method=merge"
        ])
        if result2.returncode == 0:
            print(f"  {C_GREEN}✓ Branch updated (merge).{C_RESET} CI will re-run.")
            notify("Branch Updated", f"PR #{num} updated from {base}")
        else:
            print(f"  {C_RED}✗ Failed.{C_RESET} {(result.stderr or result2.stderr).strip()}")


def do_build(repo, num, branch, title, channel):
    print(f"\n  {C_BLUE}▸ Triggering Mac DMG ({channel})...{C_RESET}")
    result = run_cmd([
        "gh", "workflow", "run", "Mac DMG", "--repo", repo,
        "--ref", branch, "-f", f"channel={channel}"
    ])
    if result.returncode != 0:
        print(f"  {C_RED}✗ Failed:{C_RESET} {result.stderr.strip()}")
        return

    print(f"  {C_GREEN}✓ Build triggered.{C_RESET}")
    notify("DMG Build Started", f"PR #{num} — {title} ({channel})")

    print(f"  Waiting for run to appear...")
    time.sleep(5)

    for _ in range(12):
        r = run_cmd([
            "gh", "run", "list", "--repo", repo,
            "--workflow", "Mac DMG", "--branch", branch,
            "--limit", "1", "--json", "databaseId,status"
        ])
        if r.returncode == 0:
            runs = json.loads(r.stdout)
            if runs and runs[0]["status"] in ("queued", "in_progress", "waiting"):
                run_id = runs[0]["databaseId"]
                print(f"  Run: https://github.com/{repo}/actions/runs/{run_id}")
                print(f"\n  {C_CYAN}▸ Watching build...{C_RESET}\n")

                watch = subprocess.run(
                    ["gh", "run", "watch", str(run_id), "--repo", repo, "--exit-status"],
                    timeout=36000
                )

                if watch.returncode == 0:
                    log = run_cmd(["gh", "run", "view", str(run_id), "--repo", repo, "--log"], timeout=60)
                    dmg_name = None
                    if log.returncode == 0:
                        for line in log.stdout.split("\n"):
                            if "DMG_NAME=" in line and "RayDMG" in line:
                                m = re.search(r"DMG_NAME=(RayDMG-\S+\.dmg)", line)
                                if m:
                                    dmg_name = m.group(1)
                                    break
                    if dmg_name:
                        url = f"{GCS_BASE}/{dmg_name}"
                        print(f"\n  {C_GREEN}✓ DMG ready: {dmg_name}{C_RESET}")
                        subprocess.run(["open", url])
                        notify("DMG Ready", dmg_name, "Hero")
                    else:
                        print(f"\n  {C_GREEN}✓ Build succeeded.{C_RESET}")
                        notify("DMG Complete", f"PR #{num}")
                else:
                    print(f"\n  {C_RED}✗ Build failed.{C_RESET}")
                    print(f"    https://github.com/{repo}/actions/runs/{run_id}")
                    notify("DMG Failed", f"PR #{num} — {title}", "Basso")
                return
        time.sleep(5)

    print(f"  {C_YELLOW}Run not found.{C_RESET} Check GitHub Actions.")


def do_merge(repo, num, branch, title):
    try:
        confirm = input(f"\n  {C_RED}Squash merge #{num}?{C_RESET} Type PR number to confirm: ").strip()
    except (EOFError, KeyboardInterrupt):
        print("\n  Cancelled.")
        return
    if confirm != str(num):
        print("  Cancelled.")
        return

    result = run_cmd([
        "gh", "pr", "merge", str(num), "--repo", repo,
        "--squash", "--delete-branch"
    ])
    if result.returncode == 0:
        print(f"  {C_GREEN}✓ Merged and branch deleted.{C_RESET}")
        notify("PR Merged", f"#{num} — {title}", "Hero")
    else:
        print(f"  {C_RED}✗ Failed:{C_RESET} {result.stderr.strip()}")


def show_status(repo):
    """Print status overview (non-interactive)."""
    print(f"{C_DIM}Fetching PRs...{C_RESET}", end="\r")
    prs = fetch_prs_full(repo)
    if not prs:
        print(f"No open PRs on {repo}.")
        return

    print(f"{C_DIM}Fetching sync status...{C_RESET}", end="\r")
    compares = fetch_all_compares(repo, prs)

    name = repo.split("/")[-1]
    print(f"\n{C_CYAN}━━━ {name} — {len(prs)} open PRs ━━━{C_RESET}\n")

    header = f"  {'CI':4} {'SYNC':6} {'':2} {'READY':6}  {'PR':<7} {'TITLE':48}  {'AUTHOR':16}  {'PILLAR':14}"
    print(f"{C_DIM}{header}{C_RESET}\n")

    for pr in prs:
        compare = compares.get(pr["number"], {"behind": 0, "ahead": 0})
        print(f"  {build_status_line(pr, compare, repo)}")

    print()


def main():
    repo = detect_repo()
    pr_number = None

    args = sys.argv[1:]
    i = 0
    while i < len(args):
        if args[i] == "--status":
            if not repo:
                print("Not in a git repo.", file=sys.stderr)
                sys.exit(1)
            show_status(repo)
            return
        elif args[i] in ("--help", "-h"):
            print(__doc__)
            return
        elif args[i] == "--repo" and i + 1 < len(args):
            repo = args[i + 1]
            i += 2
            continue
        else:
            try:
                pr_number = int(args[i])
            except ValueError:
                print(f"Unknown: {args[i]}", file=sys.stderr)
                sys.exit(1)
        i += 1

    if not repo:
        print("Not in a git repo. Use: props --repo owner/repo", file=sys.stderr)
        sys.exit(1)

    if not pr_number:
        # Fetch everything, build rich fzf picker
        print(f"{C_DIM}Loading PRs...{C_RESET}", end="\r")
        prs = fetch_prs_full(repo)
        if not prs:
            print(f"No open PRs on {repo}.")
            return

        print(f"{C_DIM}Checking sync status...{C_RESET}", end="\r")
        compares = fetch_all_compares(repo, prs)
        print(f"                              ", end="\r")  # clear loading msg

        pr_number = pick_pr_fzf(prs, compares, repo)

        # We already have full data — find it
        pr = next((p for p in prs if p["number"] == pr_number), None)
        if pr:
            compare = compares.get(pr_number, {"behind": 0, "ahead": 0})
            state = display_pr(pr, repo, compare)
            show_actions(state, repo)
            return

    # Direct PR number — fetch fresh
    result = run_cmd([
        "gh", "pr", "view", str(pr_number), "--repo", repo,
        "--json", "number,title,headRefName,baseRefName,author,isDraft,"
                  "mergeable,mergeStateStatus,reviewDecision,statusCheckRollup,"
                  "additions,deletions,changedFiles,commits,labels,body,url"
    ])
    if result.returncode != 0:
        print(f"PR #{pr_number} not found.", file=sys.stderr)
        sys.exit(1)

    pr = json.loads(result.stdout)
    compare = fetch_compare(repo, pr["baseRefName"], pr["headRefName"])
    state = display_pr(pr, repo, compare)
    show_actions(state, repo)


if __name__ == "__main__":
    main()
