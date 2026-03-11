#!/usr/bin/env python3
"""props — PR Operations TUI. Full status, strategic context, and actions.

Persistent terminal UI with keyboard navigation:
  List view:   up/down to navigate, enter to drill in, q to quit
  Detail view: r=rebase, b=build qa, B=build nightly, o=open, m=merge
               esc/left to go back to list
  Action view: live CI polling every 5 seconds, esc to return

Usage:
  props                      # TUI mode (default)
  props 2373                 # go straight to PR #2373
  props --status             # print status overview (no TUI)
  props --repo owner/repo    # specify repo
"""

import curses
import json
import os
import re
import subprocess
import sys
import threading
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


def fetch_ci_status(repo, pr_number):
    """Fetch fresh CI status for a single PR."""
    result = run_cmd([
        "gh", "pr", "view", str(pr_number), "--repo", repo,
        "--json", "statusCheckRollup"
    ])
    if result.returncode == 0:
        data = json.loads(result.stdout)
        return data.get("statusCheckRollup", [])
    return []


def analyze_checks(checks):
    """Return (pass, fail, pending, skip, details) from check list."""
    ci_pass = ci_fail = ci_pending = ci_skip = 0
    details = []
    for c in checks:
        conclusion = (c.get("conclusion") or "").upper()
        status = (c.get("status") or "").upper()
        name = c.get("name", c.get("context", "?"))
        if conclusion == "SUCCESS":
            ci_pass += 1
            details.append(("pass", name))
        elif conclusion == "FAILURE":
            ci_fail += 1
            details.append(("fail", name))
        elif conclusion in ("SKIPPED", "NEUTRAL"):
            ci_skip += 1
            details.append(("skip", name))
        else:
            ci_pending += 1
            details.append(("pending", name))
    return ci_pass, ci_fail, ci_pending, ci_skip, details


def build_pr_state(pr, compare, repo):
    """Build a state dict for a PR (used by both list and detail views)."""
    num = pr["number"]
    title = pr["title"]
    branch = pr["headRefName"]
    base = pr["baseRefName"]
    author = pr["author"]["login"]
    draft = pr.get("isDraft", False)
    body = (pr.get("body") or "")[:300]
    mergeable = pr.get("mergeable", "UNKNOWN")
    review = pr.get("reviewDecision") or "NONE"
    checks = pr.get("statusCheckRollup", [])
    behind = compare.get("behind", 0)
    ahead = compare.get("ahead", 0)

    ci_pass, ci_fail, ci_pending, ci_skip, ci_details = analyze_checks(checks)
    pillar = categorize(title, body, branch, repo)
    why = get_pillar_why(pillar, repo)

    blockers = []
    if ci_fail > 0: blockers.append("CI failing")
    if behind > 0: blockers.append(f"behind {base}")
    if mergeable == "CONFLICTING": blockers.append("conflicts")
    if review == "CHANGES_REQUESTED": blockers.append("changes requested")
    if draft: blockers.append("draft")

    return {
        "number": num, "title": title, "branch": branch, "base": base,
        "author": author, "draft": draft, "mergeable": mergeable,
        "review": review, "behind": behind, "ahead": ahead,
        "ci_pass": ci_pass, "ci_fail": ci_fail, "ci_pending": ci_pending,
        "ci_skip": ci_skip, "ci_details": ci_details,
        "pillar": pillar, "why": why, "blockers": blockers,
        "additions": pr.get("additions", 0), "deletions": pr.get("deletions", 0),
        "changedFiles": pr.get("changedFiles", 0),
        "commits": len(pr.get("commits", [])),
        "labels": [l["name"] for l in pr.get("labels", [])],
        "checks": checks,
    }


# ─── Curses TUI ───────────────────────────────────────────────────────────────

class PropsTUI:
    # Views
    VIEW_LIST = "list"
    VIEW_DETAIL = "detail"
    VIEW_ACTION = "action"

    def __init__(self, stdscr, repo, prs, compares):
        self.stdscr = stdscr
        self.repo = repo
        self.prs = prs
        self.compares = compares

        # Build state for each PR
        self.states = []
        for pr in prs:
            cmp = compares.get(pr["number"], {"behind": 0, "ahead": 0})
            self.states.append(build_pr_state(pr, cmp, repo))

        self.view = self.VIEW_LIST
        self.cursor = 0
        self.scroll_offset = 0
        self.selected_idx = None

        # Action view state
        self.action_log = []       # brief history: ("ok"/"err"/"info", "text")
        self.action_status = ""    # one-line status message
        self.action_running = False
        self.action_thread = None
        self.ci_polling = False
        self.ci_poll_thread = None
        self.ci_live = []          # live CI check state: [("pass"/"fail"/"pending"/"skip", "name")]
        self.ci_last_poll = ""     # timestamp of last poll

        # For thread-safe screen updates
        self.lock = threading.Lock()

        try:
            curses.curs_set(0)
        except curses.error:
            pass
        curses.start_color()
        curses.use_default_colors()
        curses.init_pair(1, curses.COLOR_GREEN, -1)   # green
        curses.init_pair(2, curses.COLOR_RED, -1)      # red
        curses.init_pair(3, curses.COLOR_YELLOW, -1)   # yellow
        curses.init_pair(4, curses.COLOR_CYAN, -1)     # cyan
        curses.init_pair(5, curses.COLOR_BLUE, -1)     # blue
        curses.init_pair(6, curses.COLOR_WHITE, -1)    # white
        curses.init_pair(7, curses.COLOR_BLACK, curses.COLOR_WHITE)  # selected row

        self.stdscr.timeout(100)  # 100ms for responsive input + thread updates

    def run(self):
        while True:
            with self.lock:
                self.draw()
            key = self.stdscr.getch()
            if key == -1:
                continue
            if not self.handle_key(key):
                break

    def handle_key(self, key):
        if self.view == self.VIEW_LIST:
            return self.handle_list_key(key)
        elif self.view == self.VIEW_DETAIL:
            return self.handle_detail_key(key)
        elif self.view == self.VIEW_ACTION:
            return self.handle_action_key(key)
        return True

    # ─── List View ──────────────────────────────────────────────────────

    def handle_list_key(self, key):
        if key == ord('q') or key == 27:  # q or esc
            return False
        elif key == curses.KEY_UP or key == ord('k'):
            if self.cursor > 0:
                self.cursor -= 1
        elif key == curses.KEY_DOWN or key == ord('j'):
            if self.cursor < len(self.states) - 1:
                self.cursor += 1
        elif key == 10 or key == curses.KEY_RIGHT:  # enter or right
            self.selected_idx = self.cursor
            self.view = self.VIEW_DETAIL
            self.detail_scroll = 0
        elif key == ord('R'):
            # Shift-R: rebase highlighted PR directly from list
            st = self.states[self.cursor]
            if st["behind"] > 0:
                self.selected_idx = self.cursor
                self._action_rebase_and_return(st)
        elif key == ord('r'):
            # lowercase r: refresh data
            self._refresh_data()
        return True

    def _refresh_data(self):
        """Re-fetch all PR data."""
        self.action_log = [("info", "Refreshing...")]
        self.view = self.VIEW_ACTION
        self.action_running = True

        def do_refresh():
            try:
                prs = fetch_prs_full(self.repo)
                if prs:
                    compares = fetch_all_compares(self.repo, prs)
                    with self.lock:
                        self.prs = prs
                        self.compares = compares
                        self.states = []
                        for pr in prs:
                            cmp = compares.get(pr["number"], {"behind": 0, "ahead": 0})
                            self.states.append(build_pr_state(pr, cmp, self.repo))
                        if self.cursor >= len(self.states):
                            self.cursor = max(0, len(self.states) - 1)
                        self.action_log.append(("ok", f"Loaded {len(prs)} PRs."))
                else:
                    with self.lock:
                        self.action_log.append(("err", "No PRs found."))
            except Exception as e:
                with self.lock:
                    self.action_log.append(("err", str(e)))
            finally:
                with self.lock:
                    self.action_running = False

        self.action_thread = threading.Thread(target=do_refresh, daemon=True)
        self.action_thread.start()

    def _refresh_data_silent(self):
        """Re-fetch all PR data in background without leaving current view."""
        def do_refresh():
            try:
                prs = fetch_prs_full(self.repo)
                if prs:
                    compares = fetch_all_compares(self.repo, prs)
                    with self.lock:
                        self.prs = prs
                        self.compares = compares
                        self.states = []
                        for pr in prs:
                            cmp = compares.get(pr["number"], {"behind": 0, "ahead": 0})
                            self.states.append(build_pr_state(pr, cmp, self.repo))
                        if self.cursor >= len(self.states):
                            self.cursor = max(0, len(self.states) - 1)
            except Exception:
                pass

        threading.Thread(target=do_refresh, daemon=True).start()

    def draw_list(self):
        h, w = self.stdscr.getmaxyx()
        self.stdscr.erase()

        repo_name = self.repo.split("/")[-1]
        title = f" props — {repo_name} — {len(self.states)} open PRs "
        self.safe_addstr(0, 0, title, curses.color_pair(4) | curses.A_BOLD)

        # Header
        hdr = f" {'CI':4} {'SYNC':5} {'':1} {'READY':6}  {'PR':<6} {'TITLE':40}  {'AUTHOR':12}  {'PILLAR':12}"
        self.safe_addstr(2, 0, hdr[:w], curses.A_DIM)

        # Reserve bottom panel: separator + up to 7 info lines + keyhints
        panel_height = 9
        list_start = 3
        list_height = max(1, h - list_start - panel_height)

        # Adjust scroll offset to keep cursor visible
        if self.cursor < self.scroll_offset:
            self.scroll_offset = self.cursor
        elif self.cursor >= self.scroll_offset + list_height:
            self.scroll_offset = self.cursor - list_height + 1

        for i in range(list_height):
            idx = self.scroll_offset + i
            if idx >= len(self.states):
                break
            row = list_start + i
            st = self.states[idx]
            is_selected = (idx == self.cursor)
            self.draw_status_line(row, st, w, is_selected)

        # ─── Bottom info panel for highlighted PR ───
        self.draw_info_panel(list_start + list_height, w, h)

    def draw_status_line(self, row, st, w, selected):
        """Draw a single PR status line (plain curses, no ANSI)."""
        # CI indicator
        if st["ci_fail"] > 0:
            ci_text = f"CI✗{st['ci_fail']}"
            ci_color = curses.color_pair(2) | curses.A_BOLD
        elif st["ci_pending"] > 0:
            ci_text = "CI● "
            ci_color = curses.color_pair(3) | curses.A_BOLD
        elif st["ci_pass"] > 0:
            ci_text = "CI✓ "
            ci_color = curses.color_pair(1) | curses.A_BOLD
        else:
            ci_text = "CI? "
            ci_color = curses.A_DIM

        # Sync
        if st["behind"] == 0:
            sync_text = "✓sync"
            sync_color = curses.color_pair(1) | curses.A_BOLD
        else:
            sync_text = f"↓{st['behind']:<4}"
            sync_color = curses.color_pair(2) | curses.A_BOLD

        # Conflicts
        conflict_text = "⚡" if st["mergeable"] == "CONFLICTING" else " "
        conflict_color = curses.color_pair(2) | curses.A_BOLD

        # Draft
        draft_text = "D" if st["draft"] else " "
        draft_color = curses.color_pair(3) | curses.A_BOLD

        # Ready
        if not st["blockers"]:
            ready_text = "✓READY"
            ready_color = curses.color_pair(1) | curses.A_BOLD
        else:
            ready_text = "------"
            ready_color = curses.A_DIM

        # PR number
        pr_text = f"#{st['number']:<5}"

        # Title (truncated)
        max_title = min(40, w - 55)
        title_text = st["title"][:max_title].ljust(max_title)

        # Author
        author_text = st["author"][:12].ljust(12)

        # Pillar
        pillar_text = st["pillar"][:12].ljust(12)

        base_attr = curses.color_pair(7) if selected else 0

        col = 1
        self.safe_addstr(row, col, ci_text, ci_color | (curses.A_REVERSE if selected else 0))
        col += 5
        self.safe_addstr(row, col, sync_text, sync_color | (curses.A_REVERSE if selected else 0))
        col += 6
        self.safe_addstr(row, col, conflict_text, conflict_color | (curses.A_REVERSE if selected else 0))
        self.safe_addstr(row, col + 1, draft_text, draft_color | (curses.A_REVERSE if selected else 0))
        col += 3
        self.safe_addstr(row, col, ready_text, ready_color | (curses.A_REVERSE if selected else 0))
        col += 8
        self.safe_addstr(row, col, pr_text, base_attr)
        col += 7
        self.safe_addstr(row, col, title_text, base_attr | curses.A_BOLD if selected else base_attr)
        col += max_title + 2
        self.safe_addstr(row, col, author_text, curses.A_DIM | (curses.A_REVERSE if selected else 0))
        col += 14
        self.safe_addstr(row, col, pillar_text, curses.color_pair(5) | curses.A_BOLD | (curses.A_REVERSE if selected else 0))

    def draw_info_panel(self, top_row, w, h):
        """Draw a rich info panel at the bottom showing full details of highlighted PR."""
        if not self.states or self.cursor >= len(self.states):
            return

        st = self.states[self.cursor]

        # Separator line
        self.safe_addstr(top_row, 0, "─" * (w - 1), curses.color_pair(4))

        row = top_row + 1

        # Line 1: PR number + full title + pillar
        line1_pr = f" #{st['number']}  "
        line1_title = st["title"]
        line1_pillar = f"  [{st['pillar']}]"
        max_t = w - len(line1_pr) - len(line1_pillar) - 2
        if max_t > 0:
            line1_title = line1_title[:max_t]
        self.safe_addstr(row, 0, line1_pr, curses.A_BOLD)
        self.safe_addstr(row, len(line1_pr), line1_title, curses.A_BOLD)
        self.safe_addstr(row, len(line1_pr) + len(line1_title), line1_pillar, curses.color_pair(5) | curses.A_BOLD)
        row += 1

        # Line 2: Why (pillar description)
        if st["why"]:
            self.safe_addstr(row, 1, st["why"][:w-3], curses.A_DIM)
        row += 1

        # Line 3: Branch + sync status (human-readable)
        branch_info = f" {st['branch']} → {st['base']}"
        self.safe_addstr(row, 0, branch_info[:w-1], curses.color_pair(5))
        row += 1

        # Line 4: Sync + conflicts + draft (full English sentences)
        sync_parts = []
        if st["behind"] == 0:
            sync_parts.append(("In sync with " + st["base"], curses.color_pair(1)))
        else:
            sync_parts.append((f"{st['behind']} commits behind {st['base']} — needs rebase", curses.color_pair(2) | curses.A_BOLD))

        if st["mergeable"] == "CONFLICTING":
            sync_parts.append(("  |  Has merge conflicts", curses.color_pair(2) | curses.A_BOLD))
        if st["draft"]:
            sync_parts.append(("  |  Draft PR", curses.color_pair(3)))

        col = 1
        for text, attr in sync_parts:
            self.safe_addstr(row, col, text, attr)
            col += len(text)
        row += 1

        # Line 5: CI status (full English + failed check names)
        if st["ci_fail"] > 0:
            failed_names = [name for kind, name in st["ci_details"] if kind == "fail"]
            ci_msg = f" CI: {st['ci_fail']} failed"
            if failed_names:
                ci_msg += " — " + ", ".join(failed_names[:3])
                if len(failed_names) > 3:
                    ci_msg += f" (+{len(failed_names) - 3} more)"
            self.safe_addstr(row, 0, ci_msg[:w-1], curses.color_pair(2) | curses.A_BOLD)
        elif st["ci_pending"] > 0:
            pending_names = [name for kind, name in st["ci_details"] if kind == "pending"]
            ci_msg = f" CI: {st['ci_pending']} running"
            if pending_names:
                ci_msg += " — " + ", ".join(pending_names[:3])
                if len(pending_names) > 3:
                    ci_msg += f" (+{len(pending_names) - 3} more)"
            self.safe_addstr(row, 0, ci_msg[:w-1], curses.color_pair(3))
        elif st["ci_pass"] > 0:
            self.safe_addstr(row, 0, f" CI: all {st['ci_pass']} checks passing", curses.color_pair(1))
        else:
            self.safe_addstr(row, 0, " CI: no checks", curses.A_DIM)
        row += 1

        # Line 6: Passing checks summary (if there are failures, show what passed too)
        if st["ci_fail"] > 0 and st["ci_pass"] > 0:
            self.safe_addstr(row, 0, f" ({st['ci_pass']} passing, {st['ci_skip']} skipped)"[:w-1], curses.A_DIM)
            row += 1

        # Line 7: Ready / Blocked verdict
        if not st["blockers"]:
            self.safe_addstr(row, 0, " Ready to merge", curses.color_pair(1) | curses.A_BOLD)
        else:
            self.safe_addstr(row, 0, f" Blocked: {', '.join(st['blockers'])}"[:w-1], curses.color_pair(2))
        row += 1

        # Key hints at very bottom
        keys = " ↑↓:navigate  enter:detail  R:rebase  r:refresh  esc/q:quit"
        self.safe_addstr(h - 1, 0, keys[:w-1], curses.A_DIM)

    # ─── Detail View ────────────────────────────────────────────────────

    def handle_detail_key(self, key):
        if key == 27 or key == curses.KEY_LEFT:  # esc or left
            self.view = self.VIEW_LIST
        elif key == ord('o'):
            self._action_open_browser()
        elif key == ord('r'):
            st = self.states[self.selected_idx]
            if st["behind"] > 0:
                self._action_rebase(st)
        elif key == ord('b'):
            st = self.states[self.selected_idx]
            if self.repo == "raybrowser/chromium-ray-poc":
                self._action_build(st, "qa")
        elif key == ord('B'):
            st = self.states[self.selected_idx]
            if self.repo == "raybrowser/chromium-ray-poc":
                self._action_build(st, "nightly")
        elif key == ord('m'):
            st = self.states[self.selected_idx]
            if not st["blockers"]:
                self._action_merge(st)
        elif key == curses.KEY_UP or key == ord('k'):
            if self.detail_scroll > 0:
                self.detail_scroll -= 1
        elif key == curses.KEY_DOWN or key == ord('j'):
            self.detail_scroll += 1
        elif key == ord('q'):
            return False
        return True

    def draw_detail(self):
        h, w = self.stdscr.getmaxyx()
        self.stdscr.erase()

        st = self.states[self.selected_idx]
        is_ray = (self.repo == "raybrowser/chromium-ray-poc")

        lines = []  # list of (text, attr) tuples

        lines.append((f" #{st['number']}  {st['title']}", curses.color_pair(4) | curses.A_BOLD))
        lines.append(("━" * min(60, w - 2), curses.color_pair(4)))
        lines.append(("", 0))

        # Pillar
        lines.append((f" ▸ {st['pillar']}", curses.color_pair(3) | curses.A_BOLD))
        if st["why"]:
            lines.append((f"   {st['why']}", curses.A_DIM))
        lines.append(("", 0))

        # Branch info
        lines.append((f" Branch    {st['branch']} → {st['base']}", curses.color_pair(5)))
        lines.append((f" Author    {st['author']}", 0))
        lines.append((f" Changes   +{st['additions']} -{st['deletions']} in {st['changedFiles']} files ({st['commits']} commits)", 0))
        if st["labels"]:
            lines.append((f" Labels    {', '.join(st['labels'])}", 0))
        if st["draft"]:
            lines.append((" Draft     Yes — not ready for merge", curses.color_pair(3)))
        lines.append(("", 0))

        # Sync status
        if st["behind"] == 0:
            lines.append((f" ✓ Up to date with {st['base']} ({st['ahead']} ahead)", curses.color_pair(1)))
        else:
            lines.append((f" ✗ {st['behind']} behind {st['base']} ({st['ahead']} ahead) — needs rebase", curses.color_pair(2)))

        # Conflicts
        if st["mergeable"] == "MERGEABLE":
            lines.append((" ✓ No conflicts", curses.color_pair(1)))
        elif st["mergeable"] == "CONFLICTING":
            lines.append((" ✗ Has merge conflicts", curses.color_pair(2)))
        else:
            lines.append((f" ● Merge: {st['mergeable']}", curses.color_pair(3)))

        # Review
        if st["review"] == "APPROVED":
            lines.append((" ✓ Approved", curses.color_pair(1)))
        elif st["review"] == "CHANGES_REQUESTED":
            lines.append((" ✗ Changes requested", curses.color_pair(2)))
        else:
            lines.append((" ○ No reviews", curses.A_DIM))
        lines.append(("", 0))

        # CI
        if st["ci_fail"] > 0:
            lines.append((f" ✗ CI: {st['ci_fail']} failing  ({st['ci_pass']} passed, {st['ci_pending']} pending, {st['ci_skip']} skipped)", curses.color_pair(2)))
        elif st["ci_pending"] > 0:
            lines.append((f" ● CI: {st['ci_pending']} pending  ({st['ci_pass']} passed, {st['ci_fail']} failed, {st['ci_skip']} skipped)", curses.color_pair(3)))
        elif st["ci_pass"] > 0:
            lines.append((f" ✓ CI: all passing  ({st['ci_pass']} passed, {st['ci_skip']} skipped)", curses.color_pair(1)))
        else:
            lines.append((" ○ No CI", curses.A_DIM))

        # Individual checks
        for kind, name in st["ci_details"]:
            if kind == "pass":
                lines.append((f"   ✓ {name}", curses.color_pair(1)))
            elif kind == "fail":
                lines.append((f"   ✗ {name}", curses.color_pair(2)))
            elif kind == "pending":
                lines.append((f"   ● {name}", curses.color_pair(3)))
            else:
                lines.append((f"   ○ {name}", curses.A_DIM))

        lines.append(("", 0))

        # Ready / Blocked
        if not st["blockers"]:
            lines.append((" Ready to merge.", curses.color_pair(1) | curses.A_BOLD))
        else:
            lines.append((f" Blocked: {', '.join(st['blockers'])}", curses.color_pair(2) | curses.A_BOLD))

        lines.append(("", 0))

        # Actions
        lines.append((" Actions:", curses.color_pair(4) | curses.A_BOLD))
        lines.append(("  [o] Open in browser", 0))
        if st["behind"] > 0:
            lines.append((f"  [r] Rebase on {st['base']}", curses.color_pair(3)))
        if is_ray:
            lines.append(("  [b] Build Mac DMG (qa)", curses.color_pair(5)))
            lines.append(("  [B] Build Mac DMG (nightly)", curses.color_pair(5)))
        if not st["blockers"]:
            lines.append(("  [m] Merge (squash)", curses.color_pair(1)))
        elif st["mergeable"] != "CONFLICTING" and not st["draft"]:
            lines.append((f"  [m] Merge (blocked: {', '.join(st['blockers'])})", curses.A_DIM))

        # Clamp scroll
        max_scroll = max(0, len(lines) - (h - 2))
        if self.detail_scroll > max_scroll:
            self.detail_scroll = max_scroll

        # Draw
        for i, (text, attr) in enumerate(lines):
            row = i - self.detail_scroll
            if row < 0 or row >= h - 1:
                continue
            self.safe_addstr(row, 0, text[:w-1], attr)

        # Footer
        footer = " esc/←:back  ↑↓:scroll  o:open  r:rebase  b/B:build  m:merge  q:quit"
        self.safe_addstr(h - 1, 0, footer[:w-1], curses.A_DIM)

    def _action_open_browser(self):
        st = self.states[self.selected_idx]
        subprocess.Popen(["gh", "pr", "view", str(st["number"]), "--repo", self.repo, "--web"],
                        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    def _do_rebase_api(self, st):
        """Execute rebase API call. Returns True on success."""
        num = st["number"]
        base = st["base"]

        result = run_cmd([
            "gh", "api", "-X", "PUT",
            f"repos/{self.repo}/pulls/{num}/update-branch",
            "-f", "update_method=rebase"
        ])

        if result.returncode == 0:
            with self.lock:
                self.action_log.append(("ok", f"Rebase triggered for #{num} on {base}."))
            notify("Rebase Triggered", f"PR #{num} rebasing on {base}")
            return True

        # Fallback to merge
        result2 = run_cmd([
            "gh", "api", "-X", "PUT",
            f"repos/{self.repo}/pulls/{num}/update-branch",
            "-f", "update_method=merge"
        ])
        if result2.returncode == 0:
            with self.lock:
                self.action_log.append(("ok", f"Branch #{num} updated (merge) from {base}."))
            notify("Branch Updated", f"PR #{num} updated from {base}")
            return True

        err = (result.stderr or result2.stderr).strip()
        is_conflict = "conflict" in err.lower()
        with self.lock:
            if is_conflict:
                self.action_log.append(("err", f"Conflicts — can't auto-rebase #{num}."))
                self.action_log.append(("info", "Needs manual conflict resolution."))
                self.action_log.append(("info", "Press 'o' to open in browser, or esc to go back."))
                # Update cached state
                if self.selected_idx is not None and self.selected_idx < len(self.states):
                    self.states[self.selected_idx]["mergeable"] = "CONFLICTING"
                    s = self.states[self.selected_idx]
                    if "conflicts" not in s["blockers"]:
                        s["blockers"].append("conflicts")
            else:
                self.action_log.append(("err", f"Failed: {err}"))
        return False

    def _action_rebase(self, st):
        """Rebase from detail view — stays in action view with CI polling."""
        self.view = self.VIEW_ACTION
        self.action_log = [("info", f"Rebasing #{st['number']} on {st['base']}...")]
        self.action_status = "Rebasing..."
        self.ci_live = []
        self.ci_last_poll = ""
        self.action_running = True
        self.ci_polling = False

        def do_rebase():
            if not self._do_rebase_api(st):
                with self.lock:
                    self.action_running = False
                return

            with self.lock:
                self.action_running = False
                self.action_log.append(("info", "Waiting for CI checks to appear..."))
                self.ci_polling = True

            self._start_ci_poll(st["number"])

        self.action_thread = threading.Thread(target=do_rebase, daemon=True)
        self.action_thread.start()

    def _action_rebase_and_return(self, st):
        """Rebase from list view — shows progress, then auto-returns to list."""
        self.view = self.VIEW_ACTION
        self.action_log = [("info", f"Rebasing #{st['number']} on {st['base']}...")]
        self.action_status = "Rebasing..."
        self.ci_live = []
        self.ci_last_poll = ""
        self.action_running = True
        self.ci_polling = False
        self._return_to = self.VIEW_LIST

        def do_rebase_and_poll():
            if not self._do_rebase_api(st):
                with self.lock:
                    self.action_running = False
                return

            with self.lock:
                self.action_running = False
                self.action_log.append(("info", "Waiting for CI checks to appear..."))
                self.ci_polling = True

            self._start_ci_poll(st["number"], auto_return=True)

        self.action_thread = threading.Thread(target=do_rebase_and_poll, daemon=True)
        self.action_thread.start()

    def _action_build(self, st, channel):
        self.view = self.VIEW_ACTION
        self.action_log = [("info", f"Triggering Mac DMG ({channel}) for #{st['number']}...")]
        self.action_running = True
        self.ci_polling = False

        def do_build():
            num = st["number"]
            branch = st["branch"]
            title = st["title"]

            result = run_cmd([
                "gh", "workflow", "run", "Mac DMG", "--repo", self.repo,
                "--ref", branch, "-f", f"channel={channel}"
            ])

            if result.returncode != 0:
                with self.lock:
                    self.action_log.append(("err", f"Failed: {result.stderr.strip()}"))
                    self.action_running = False
                return

            with self.lock:
                self.action_log.append(("ok", f"Build triggered ({channel})."))
            notify("DMG Build Started", f"PR #{num} — {title} ({channel})")

            # Wait for run to appear
            with self.lock:
                self.action_log.append(("info", "Waiting for run to appear..."))

            time.sleep(5)
            run_id = None
            for _ in range(12):
                r = run_cmd([
                    "gh", "run", "list", "--repo", self.repo,
                    "--workflow", "Mac DMG", "--branch", branch,
                    "--limit", "1", "--json", "databaseId,status"
                ])
                if r.returncode == 0:
                    runs = json.loads(r.stdout)
                    if runs and runs[0]["status"] in ("queued", "in_progress", "waiting"):
                        run_id = runs[0]["databaseId"]
                        break
                time.sleep(5)

            if not run_id:
                with self.lock:
                    self.action_log.append(("err", "Run not found. Check GitHub Actions."))
                    self.action_running = False
                return

            with self.lock:
                self.action_log.append(("info", f"Run {run_id} found. Polling status..."))
                self.action_running = False
                self.ci_polling = True

            # Poll the build run
            while self.ci_polling:
                r = run_cmd([
                    "gh", "run", "view", str(run_id), "--repo", self.repo,
                    "--json", "status,conclusion,jobs"
                ])
                if r.returncode == 0:
                    data = json.loads(r.stdout)
                    status = data.get("status", "?")
                    conclusion = data.get("conclusion", "")

                    jobs = data.get("jobs", [])
                    job_lines = []
                    for job in jobs:
                        jname = job.get("name", "?")
                        jstatus = job.get("conclusion") or job.get("status", "?")
                        job_lines.append(f"  {jname}: {jstatus}")

                    with self.lock:
                        self.action_log.append(("info", f"Build: {status} {conclusion}"))
                        for jl in job_lines:
                            self.action_log.append(("dim", jl))

                    if status == "completed":
                        if conclusion == "success":
                            # Try to extract DMG name
                            log = run_cmd(["gh", "run", "view", str(run_id), "--repo", self.repo, "--log"], timeout=60)
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
                                with self.lock:
                                    self.action_log.append(("ok", f"DMG ready: {dmg_name}"))
                                subprocess.Popen(["open", url], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                                notify("DMG Ready", dmg_name, "Hero")
                            else:
                                with self.lock:
                                    self.action_log.append(("ok", "Build succeeded."))
                                notify("DMG Complete", f"PR #{num}")
                        else:
                            with self.lock:
                                self.action_log.append(("err", f"Build {conclusion}."))
                            notify("DMG Failed", f"PR #{num} — {title}", "Basso")

                        with self.lock:
                            self.ci_polling = False
                        break

                time.sleep(5)

        self.action_thread = threading.Thread(target=do_build, daemon=True)
        self.action_thread.start()

    def _action_merge(self, st):
        """Merge requires confirmation — handled in action view with a prompt."""
        self.view = self.VIEW_ACTION
        self.action_log = [
            ("warn", f"Squash merge #{st['number']}?"),
            ("info", f"  {st['title']}"),
            ("info", ""),
            ("warn", f"Press 'y' to confirm, any other key to cancel."),
        ]
        self.action_running = False
        self.ci_polling = False
        self._merge_pending = st

    def _do_merge_confirmed(self, st):
        self.action_log.append(("info", f"Merging #{st['number']}..."))
        self.action_running = True

        def do_merge():
            num = st["number"]
            title = st["title"]
            result = run_cmd([
                "gh", "pr", "merge", str(num), "--repo", self.repo,
                "--squash", "--delete-branch"
            ])
            if result.returncode == 0:
                with self.lock:
                    self.action_log.append(("ok", "Merged and branch deleted."))
                notify("PR Merged", f"#{num} — {title}", "Hero")
            else:
                with self.lock:
                    self.action_log.append(("err", f"Failed: {result.stderr.strip()}"))
            with self.lock:
                self.action_running = False

        self.action_thread = threading.Thread(target=do_merge, daemon=True)
        self.action_thread.start()

    def _start_ci_poll(self, pr_number, auto_return=False):
        """Poll CI status every 5 seconds until all checks complete or user presses esc.

        After rebase, GitHub takes 10-30 seconds to create CI checks.
        We wait for checks to appear before reporting status.
        If auto_return is True, return to list view + refresh when CI finishes.
        """
        def poll():
            # Phase 1: Wait for checks to actually appear (up to 60s)
            checks_found = False
            for wait_attempt in range(12):
                if not self.ci_polling:
                    return
                checks = fetch_ci_status(self.repo, pr_number)
                total = len(checks)
                if total > 0:
                    checks_found = True
                    with self.lock:
                        self.action_log.append(("info", f"CI checks detected ({total} checks). Polling..."))
                    break
                with self.lock:
                    ts = time.strftime("%H:%M:%S")
                    self.action_log.append(("dim", f"[{ts}] Waiting for CI checks to appear... ({wait_attempt + 1}/12)"))
                time.sleep(5)

            if not checks_found:
                with self.lock:
                    self.action_log.append(("warn", "No CI checks appeared after 60s. Check GitHub."))
                    self.ci_polling = False
                if auto_return:
                    self._auto_return_to_list()
                return

            # Phase 2: Poll until all checks resolve — update live state in-place
            while self.ci_polling:
                checks = fetch_ci_status(self.repo, pr_number)
                ci_pass, ci_fail, ci_pending, ci_skip, details = analyze_checks(checks)
                total = ci_pass + ci_fail + ci_pending + ci_skip

                with self.lock:
                    self.ci_last_poll = time.strftime("%H:%M:%S")
                    self.ci_live = details
                    self.action_status = f"{ci_pass} passed, {ci_fail} failed, {ci_pending} running, {ci_skip} skipped"

                    # Update the cached state for this PR
                    if self.selected_idx is not None and self.selected_idx < len(self.states):
                        s = self.states[self.selected_idx]
                        s["ci_pass"] = ci_pass
                        s["ci_fail"] = ci_fail
                        s["ci_pending"] = ci_pending
                        s["ci_skip"] = ci_skip
                        s["ci_details"] = details
                        s["behind"] = 0  # just rebased
                        blockers = []
                        if ci_fail > 0: blockers.append("CI failing")
                        if s["mergeable"] == "CONFLICTING": blockers.append("conflicts")
                        if s["review"] == "CHANGES_REQUESTED": blockers.append("changes requested")
                        if s["draft"]: blockers.append("draft")
                        s["blockers"] = blockers

                if ci_pending == 0 and total > 0:
                    with self.lock:
                        if ci_fail > 0:
                            self.action_status = f"Done: {ci_fail} failed, {ci_pass} passed"
                            self.action_log.append(("err", f"CI done: {ci_fail} failed."))
                            notify("CI Failed", f"PR #{pr_number}: {ci_fail} checks failed", "Basso")
                        else:
                            self.action_status = f"Done: all {ci_pass} checks passed"
                            self.action_log.append(("ok", f"CI done: all {ci_pass} passing."))
                            notify("CI Passed", f"PR #{pr_number}: all checks passed", "Hero")
                        self.ci_polling = False
                    break

                time.sleep(5)

            if auto_return:
                self._auto_return_to_list()

        self.ci_poll_thread = threading.Thread(target=poll, daemon=True)
        self.ci_poll_thread.start()

    def _auto_return_to_list(self):
        """Return to list view and refresh data after an action completes."""
        time.sleep(1)  # brief pause so user sees the final status
        with self.lock:
            self.view = self.VIEW_LIST
            self.ci_polling = False
            self.action_running = False
        # Refresh in background
        self._refresh_data_silent()

    # ─── Action View ────────────────────────────────────────────────────

    def handle_action_key(self, key):
        # Check merge confirmation
        if hasattr(self, '_merge_pending') and self._merge_pending:
            st = self._merge_pending
            self._merge_pending = None
            if key == ord('y'):
                self._do_merge_confirmed(st)
            else:
                self.action_log.append(("info", "Cancelled."))
            return True

        if key == ord('o') and self.selected_idx is not None:
            self._action_open_browser()
            return True

        if key == 27 or key == curses.KEY_LEFT:  # esc or left
            self.ci_polling = False
            self.action_running = False
            return_to = getattr(self, '_return_to', None)
            if return_to:
                self.view = return_to
                self._return_to = None
                self._refresh_data_silent()
            elif self.selected_idx is not None:
                self.view = self.VIEW_DETAIL
            else:
                self.view = self.VIEW_LIST
        elif key == ord('q'):
            self.ci_polling = False
            return False
        return True

    def draw_action(self):
        h, w = self.stdscr.getmaxyx()
        self.stdscr.erase()

        row = 0

        # Title: PR info
        if self.selected_idx is not None and self.selected_idx < len(self.states):
            st = self.states[self.selected_idx]
            self.safe_addstr(row, 0, f" #{st['number']}  {st['title'][:w-10]}", curses.color_pair(4) | curses.A_BOLD)
        else:
            self.safe_addstr(row, 0, " props", curses.color_pair(4) | curses.A_BOLD)
        row += 1

        # If CI is being polled, show the live updating check list
        if self.ci_live:
            self.safe_addstr(row, 0, "─" * (w - 1), curses.color_pair(4))
            row += 1

            # Status summary
            if self.ci_last_poll:
                status_line = f" {self.action_status}  (updated {self.ci_last_poll})"
            else:
                status_line = f" {self.action_status}"
            self.safe_addstr(row, 0, status_line[:w-1], curses.A_BOLD)
            row += 2

            # Each check on its own line — updates in place, no flooding
            for kind, name in self.ci_live:
                if row >= h - 2:
                    break
                if kind == "pass":
                    icon = "✓"
                    label = "passed"
                    attr = curses.color_pair(1)
                elif kind == "fail":
                    icon = "✗"
                    label = "FAILED"
                    attr = curses.color_pair(2) | curses.A_BOLD
                elif kind == "pending":
                    # Animate the spinner per-check
                    spinner = "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
                    frame = spinner[int(time.time() * 4) % len(spinner)]
                    icon = frame
                    label = "running"
                    attr = curses.color_pair(3)
                else:
                    icon = "○"
                    label = "skipped"
                    attr = curses.A_DIM

                check_line = f"  {icon} {name:50} {label}"
                self.safe_addstr(row, 0, check_line[:w-1], attr)
                row += 1

        # Below CI checks (or if no CI yet): show the message log (brief history)
        row += 1
        log_height = max(1, h - row - 2)
        log_len = len(self.action_log)
        start_idx = max(0, log_len - log_height)

        for i, (kind, text) in enumerate(self.action_log[start_idx:]):
            draw_row = row + i
            if draw_row >= h - 1:
                break
            if kind == "ok":
                attr = curses.color_pair(1) | curses.A_BOLD
            elif kind == "err":
                attr = curses.color_pair(2) | curses.A_BOLD
            elif kind == "warn":
                attr = curses.color_pair(3) | curses.A_BOLD
            elif kind == "dim":
                attr = curses.A_DIM
            else:
                attr = 0
            self.safe_addstr(draw_row, 1, text[:w-2], attr)

        # Footer
        if self.action_running or self.ci_polling:
            spinner = "⣾⣽⣻⢿⡿⣟⣯⣷"
            frame = spinner[int(time.time() * 4) % len(spinner)]
            self.safe_addstr(h - 1, 1, f"{frame} Polling every 5s... (esc to stop)", curses.color_pair(3))
        else:
            self.safe_addstr(h - 1, 1, "esc/←:back  q:quit", curses.A_DIM)

    # ─── Drawing dispatch ───────────────────────────────────────────────

    def draw(self):
        if self.view == self.VIEW_LIST:
            self.draw_list()
        elif self.view == self.VIEW_DETAIL:
            self.draw_detail()
        elif self.view == self.VIEW_ACTION:
            self.draw_action()
        self.stdscr.refresh()

    def safe_addstr(self, row, col, text, attr=0):
        """Write text to screen, silently ignoring out-of-bounds."""
        h, w = self.stdscr.getmaxyx()
        if row < 0 or row >= h or col >= w:
            return
        try:
            self.stdscr.addnstr(row, col, text, w - col - 1, attr)
        except curses.error:
            pass


def run_tui(repo, pr_number=None):
    """Load data and launch curses TUI."""
    # Show loading message before curses takes over
    print("Loading PRs...", end="\r", flush=True)
    prs = fetch_prs_full(repo)
    if not prs:
        print(f"No open PRs on {repo}.")
        return

    print("Checking sync status...", end="\r", flush=True)
    compares = fetch_all_compares(repo, prs)
    print("                              ", end="\r", flush=True)

    def main(stdscr):
        tui = PropsTUI(stdscr, repo, prs, compares)

        # If a specific PR number was given, jump straight to detail
        if pr_number:
            for i, st in enumerate(tui.states):
                if st["number"] == pr_number:
                    tui.cursor = i
                    tui.selected_idx = i
                    tui.view = PropsTUI.VIEW_DETAIL
                    tui.detail_scroll = 0
                    break

        tui.run()

    curses.wrapper(main)


# ─── Non-TUI mode (--status) ─────────────────────────────────────────────────

C_RESET  = "\033[0m"
C_BOLD   = "\033[1m"
C_DIM    = "\033[0;90m"
C_RED    = "\033[1;31m"
C_GREEN  = "\033[1;32m"
C_YELLOW = "\033[1;33m"
C_BLUE   = "\033[1;34m"
C_CYAN   = "\033[1;36m"
C_WHITE  = "\033[0;37m"


def build_ansi_status_line(st):
    """Build ANSI-colored status line for --status mode."""
    if st["ci_fail"] > 0:
        ci = f"{C_RED}CI✗{st['ci_fail']}{C_RESET}"
    elif st["ci_pending"] > 0:
        ci = f"{C_YELLOW}CI● {C_RESET}"
    elif st["ci_pass"] > 0:
        ci = f"{C_GREEN}CI✓ {C_RESET}"
    else:
        ci = f"{C_DIM}CI? {C_RESET}"

    if st["behind"] == 0:
        rebase = f"{C_GREEN}✓sync{C_RESET}"
    else:
        rebase = f"{C_RED}↓{st['behind']:<4}{C_RESET}"

    conflict = f"{C_RED}⚡{C_RESET}" if st["mergeable"] == "CONFLICTING" else " "
    draft_str = f"{C_YELLOW}D{C_RESET}" if st["draft"] else " "

    if not st["blockers"]:
        ready = f"{C_GREEN}✓READY{C_RESET}"
    else:
        ready = f"{C_DIM}------{C_RESET}"

    title_trunc = st["title"][:48].ljust(48)
    author_str = st["author"][:16].ljust(16)
    pillar_short = st["pillar"][:14].ljust(14)

    return (f"{ci} {rebase} {conflict}{draft_str} {ready}  "
            f"#{st['number']:<5}  {title_trunc}  "
            f"{C_DIM}{author_str}{C_RESET}  "
            f"{C_BLUE}{pillar_short}{C_RESET}")


def show_status(repo):
    print(f"{C_DIM}Fetching PRs...{C_RESET}", end="\r")
    prs = fetch_prs_full(repo)
    if not prs:
        print(f"No open PRs on {repo}.")
        return

    print(f"{C_DIM}Fetching sync status...{C_RESET}", end="\r")
    compares = fetch_all_compares(repo, prs)

    states = []
    for pr in prs:
        cmp = compares.get(pr["number"], {"behind": 0, "ahead": 0})
        states.append(build_pr_state(pr, cmp, repo))

    name = repo.split("/")[-1]
    print(f"\n{C_CYAN}━━━ {name} — {len(states)} open PRs ━━━{C_RESET}\n")

    header = f"  {'CI':4} {'SYNC':6} {'':2} {'READY':6}  {'PR':<7} {'TITLE':48}  {'AUTHOR':16}  {'PILLAR':14}"
    print(f"{C_DIM}{header}{C_RESET}\n")

    for st in states:
        print(f"  {build_ansi_status_line(st)}")

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

    run_tui(repo, pr_number)


if __name__ == "__main__":
    main()
