#!/usr/bin/env python3
"""prbuild — Trigger a Mac DMG build for a PR, watch it, download when done.

Collapses 9 manual steps into one command:
  GitHub (find PR) → GitHub (trigger) → wait → Discord (see notification) →
  Discord (click link) → Browser (download) → Finder (open)
becomes:
  prbuild → pick PR → DMG downloads

Usage:
  prbuild                    # interactive PR picker (fzf)
  prbuild 2373               # trigger for PR #2373
  prbuild --status           # show running/recent Mac DMG builds
  prbuild --channel nightly  # build on nightly channel (default: qa)
"""

import json
import os
import re
import subprocess
import sys
import time

REPO = "raybrowser/chromium-ray-poc"
WORKFLOW = "Mac DMG"
DEFAULT_CHANNEL = "qa"
DOWNLOAD_DIR = os.path.expanduser("~/Downloads")
GCS_BASE = "https://storage.cloud.google.com/ray-ci/dmg"


def run(cmd, capture=True, timeout=30):
    result = subprocess.run(cmd, capture_output=capture, text=True, timeout=timeout)
    return result


def notify(title, message, sound="Glass"):
    subprocess.run([
        "osascript", "-e",
        f'display notification "{message}" with title "{title}" sound name "{sound}"'
    ])


def fetch_prs():
    result = run([
        "gh", "pr", "list", "--repo", REPO,
        "--json", "number,title,headRefName,author",
        "--state", "open"
    ])
    if result.returncode != 0:
        print(f"Error fetching PRs: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    return json.loads(result.stdout)


def pick_pr_fzf(prs):
    """Interactive PR picker using fzf."""
    lines = []
    for pr in prs:
        author = pr.get("author", {}).get("login", "?")
        lines.append(f"#{pr['number']}  {pr['title']}  ({author})  [{pr['headRefName']}]")

    fzf_input = "\n".join(lines)
    try:
        result = subprocess.run(
            ["fzf", "--height=20", "--reverse", "--prompt=Pick PR to build DMG> ",
             "--header=Select a PR to trigger Mac DMG build"],
            input=fzf_input, capture_output=True, text=True
        )
    except FileNotFoundError:
        print("fzf not found. Install with: brew install fzf", file=sys.stderr)
        print("Or pass a PR number directly: prbuild 2373", file=sys.stderr)
        sys.exit(1)

    if result.returncode != 0 or not result.stdout.strip():
        print("No PR selected.")
        sys.exit(0)

    # Extract PR number from selected line
    selected = result.stdout.strip()
    match = re.match(r"#(\d+)", selected)
    if not match:
        print(f"Could not parse selection: {selected}", file=sys.stderr)
        sys.exit(1)

    pr_number = int(match.group(1))
    return next(pr for pr in prs if pr["number"] == pr_number)


def find_pr_by_number(prs, number):
    for pr in prs:
        if pr["number"] == number:
            return pr
    # Not in open PRs — try fetching directly
    result = run([
        "gh", "pr", "view", str(number), "--repo", REPO,
        "--json", "number,title,headRefName,author"
    ])
    if result.returncode == 0:
        return json.loads(result.stdout)
    print(f"PR #{number} not found.", file=sys.stderr)
    sys.exit(1)


def trigger_build(branch, channel):
    """Trigger Mac DMG workflow for a branch."""
    print(f"\033[1;33m▸ Triggering Mac DMG build...\033[0m")
    print(f"  Branch:  {branch}")
    print(f"  Channel: {channel}")

    result = run([
        "gh", "workflow", "run", WORKFLOW,
        "--repo", REPO,
        "--ref", branch,
        "-f", f"channel={channel}"
    ])

    if result.returncode != 0:
        print(f"\033[1;31mFailed to trigger build:\033[0m {result.stderr}", file=sys.stderr)
        sys.exit(1)

    print(f"\033[1;32m✓ Build triggered.\033[0m Waiting for it to appear...")
    return True


def find_run(branch, since_trigger=True):
    """Find the most recent Mac DMG run for this branch."""
    # Give GitHub a moment to register the run
    for attempt in range(12):
        result = run([
            "gh", "run", "list", "--repo", REPO,
            "--workflow", WORKFLOW,
            "--branch", branch,
            "--limit", "1",
            "--json", "databaseId,status,conclusion,createdAt,headBranch"
        ])
        if result.returncode == 0:
            runs = json.loads(result.stdout)
            if runs:
                r = runs[0]
                # If the run is very recent (queued/in_progress), it's ours
                if r["status"] in ("queued", "in_progress", "waiting"):
                    return r
                # If completed, it might be a previous run — check if just triggered
                if attempt < 3:
                    time.sleep(5)
                    continue
                return r
        time.sleep(5)

    print("Could not find the triggered run. Check GitHub Actions manually.", file=sys.stderr)
    sys.exit(1)


def watch_run(run_id):
    """Watch a run until completion, with live output."""
    print(f"\n\033[1;36m▸ Watching run {run_id}...\033[0m")
    print(f"  https://github.com/{REPO}/actions/runs/{run_id}\n")

    result = subprocess.run(
        ["gh", "run", "watch", str(run_id), "--repo", REPO, "--exit-status"],
        timeout=36000  # 10 hours max for Chromium builds
    )

    return result.returncode == 0


def extract_dmg_name(run_id):
    """Extract DMG filename from run logs."""
    result = run([
        "gh", "run", "view", str(run_id), "--repo", REPO, "--log"
    ], timeout=60)

    if result.returncode != 0:
        return None

    for line in result.stdout.split("\n"):
        if "DMG_NAME=" in line and "RayDMG" in line:
            match = re.search(r"DMG_NAME=(RayDMG-\S+\.dmg)", line)
            if match:
                return match.group(1)
    return None


def download_dmg(dmg_name):
    """Open GCS download URL in browser (auth-gated, requires Google login)."""
    url = f"{GCS_BASE}/{dmg_name}"
    dest = os.path.join(DOWNLOAD_DIR, dmg_name)

    print(f"\n\033[1;32m▸ DMG ready: {dmg_name}\033[0m")
    print(f"  Opening download in browser...")
    print(f"  URL: {url}")

    # GCS is auth-gated — open in browser where user is logged into Google
    subprocess.run(["open", url])

    notify("DMG Ready", f"{dmg_name}", "Hero")
    return dest


def show_status():
    """Show running/recent Mac DMG builds."""
    result = run([
        "gh", "run", "list", "--repo", REPO,
        "--workflow", WORKFLOW,
        "--limit", "10",
        "--json", "databaseId,status,conclusion,headBranch,createdAt,name"
    ])

    if result.returncode != 0:
        print(f"Error: {result.stderr}", file=sys.stderr)
        sys.exit(1)

    runs = json.loads(result.stdout)

    if not runs:
        print("No recent Mac DMG builds.")
        return

    print(f"\n\033[1;36m━━━ Mac DMG Builds ━━━\033[0m\n")

    for r in runs:
        status = r["conclusion"] or r["status"]
        if status == "success":
            icon = "\033[1;32m●\033[0m"
        elif status == "failure":
            icon = "\033[1;31m●\033[0m"
        elif status in ("in_progress", "queued", "waiting"):
            icon = "\033[1;33m●\033[0m"
        else:
            icon = "\033[0;90m●\033[0m"

        branch = r["headBranch"]
        run_id = r["databaseId"]
        print(f"  {icon} {status:13}  {branch:45}  {run_id}")

    print()


def main():
    channel = DEFAULT_CHANNEL
    pr_number = None

    # Parse args
    args = sys.argv[1:]
    i = 0
    while i < len(args):
        if args[i] == "--status":
            show_status()
            return
        elif args[i] == "--channel" and i + 1 < len(args):
            channel = args[i + 1]
            i += 2
            continue
        elif args[i] == "--help" or args[i] == "-h":
            print(__doc__)
            return
        else:
            try:
                pr_number = int(args[i])
            except ValueError:
                print(f"Unknown argument: {args[i]}", file=sys.stderr)
                sys.exit(1)
        i += 1

    # Fetch PRs
    prs = fetch_prs()

    # Pick or find PR
    if pr_number:
        pr = find_pr_by_number(prs, pr_number)
    else:
        pr = pick_pr_fzf(prs)

    branch = pr["headRefName"]
    title = pr["title"]
    number = pr["number"]
    author = pr.get("author", {}).get("login", "?")

    print(f"\n\033[1;36m━━━ prbuild ━━━\033[0m")
    print(f"  PR:      #{number} — {title}")
    print(f"  Author:  {author}")
    print(f"  Branch:  {branch}")
    print(f"  Channel: {channel}")
    print()

    # Confirm
    try:
        confirm = input(f"Trigger Mac DMG build? [Y/n] ").strip().lower()
    except (EOFError, KeyboardInterrupt):
        print("\nCancelled.")
        sys.exit(0)

    if confirm and confirm != "y":
        print("Cancelled.")
        sys.exit(0)

    # Trigger
    trigger_build(branch, channel)

    # Find the run
    time.sleep(5)
    run_info = find_run(branch)
    run_id = run_info["databaseId"]

    # Watch it
    success = watch_run(run_id)

    if success:
        # Extract DMG name and download
        dmg_name = extract_dmg_name(run_id)
        if dmg_name:
            download_dmg(dmg_name)
        else:
            print("\n\033[1;33mBuild succeeded but couldn't extract DMG name from logs.\033[0m")
            print(f"Check: https://github.com/{REPO}/actions/runs/{run_id}")
            notify("DMG Build Complete", f"PR #{number} — check GitHub Actions")
    else:
        print(f"\n\033[1;31m✗ Build failed.\033[0m")
        print(f"  https://github.com/{REPO}/actions/runs/{run_id}")
        notify("DMG Build Failed", f"PR #{number} — {title}", "Basso")


if __name__ == "__main__":
    main()
