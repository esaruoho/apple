#!/bin/bash
# github-watcher.sh — PR & CI awareness bot for macOS
# Polls GitHub repos, sends macOS notifications on changes.
# Same pattern as homepod-climate.sh — LaunchAgent + bash + notify.
#
# Repos configured in repos.json (add/remove there, not here).
#
# Usage:
#   ./github-watcher.sh              # run once, notify on changes
#   ./github-watcher.sh --stdout     # print status, no notifications
#   ./github-watcher.sh --reset      # clear state, start fresh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STATE_DIR="${SCRIPT_DIR}/.state"
LOG_DIR="${SCRIPT_DIR}/logs"
REPOS_FILE="${SCRIPT_DIR}/repos.json"
TODAY=$(date +%Y-%m-%d)
LOG_FILE="${LOG_DIR}/${TODAY}.log"

mkdir -p "$STATE_DIR" "$LOG_DIR"

# --- Load repos from JSON ---
if [[ ! -f "$REPOS_FILE" ]]; then
  echo "Error: repos.json not found at $REPOS_FILE" >&2
  exit 1
fi

# Parse repos.json into owner/repo pairs
REPOS=()
while IFS= read -r line; do
  REPOS+=("$line")
done < <(/usr/bin/python3 -c "
import json
with open('$REPOS_FILE') as f:
    for r in json.load(f):
        print(f\"{r['owner']}/{r['repo']}\")
")

# --- Mode: reset ---
if [[ "$1" == "--reset" ]]; then
  rm -f "$STATE_DIR"/*.json
  echo "State cleared."
  exit 0
fi

STDOUT_ONLY=false
if [[ "$1" == "--stdout" ]]; then
  STDOUT_ONLY=true
fi

log() {
  echo "$(date '+%H:%M:%S') $1" >> "$LOG_FILE"
}

notify() {
  local title="$1"
  local message="$2"
  local subtitle="${3:-}"
  if [[ "$STDOUT_ONLY" == true ]]; then
    echo "[$title] $subtitle — $message"
  else
    osascript -e "display notification \"$message\" with title \"$title\" subtitle \"$subtitle\" sound name \"Glass\""
  fi
  log "$title | $subtitle | $message"
}

# Sanitize repo name for filenames
safe_name() {
  echo "$1" | tr '/' '_'
}

check_prs() {
  local repo="$1"
  local safe=$(safe_name "$repo")
  local state_file="${STATE_DIR}/${safe}_prs.json"
  local short_name=$(echo "$repo" | cut -d'/' -f2)

  local current
  current=$(gh pr list --repo "$repo" --json number,title,author,updatedAt,url --state open 2>/dev/null)

  if [[ -z "$current" || "$current" == "null" ]]; then
    return
  fi

  local current_numbers
  current_numbers=$(echo "$current" | /usr/bin/python3 -c "import sys,json; [print(p['number']) for p in json.load(sys.stdin)]" 2>/dev/null | sort)

  if [[ -f "$state_file" ]]; then
    local prev_numbers
    prev_numbers=$(cat "$state_file" | /usr/bin/python3 -c "import sys,json; [print(p['number']) for p in json.load(sys.stdin)]" 2>/dev/null | sort)

    # Find new PRs
    local new_prs
    new_prs=$(comm -13 <(echo "$prev_numbers") <(echo "$current_numbers"))

    for pr_num in $new_prs; do
      local pr_title
      pr_title=$(echo "$current" | /usr/bin/python3 -c "import sys,json; prs=json.load(sys.stdin); [print(p['title']) for p in prs if p['number']==$pr_num]" 2>/dev/null)
      local pr_author
      pr_author=$(echo "$current" | /usr/bin/python3 -c "import sys,json; prs=json.load(sys.stdin); [print(p['author']['login']) for p in prs if p['number']==$pr_num]" 2>/dev/null)
      notify "New PR — $short_name" "#${pr_num}: ${pr_title}" "by ${pr_author}"
    done

    # Find closed PRs (were open, now gone)
    local closed_prs
    closed_prs=$(comm -23 <(echo "$prev_numbers") <(echo "$current_numbers"))

    for pr_num in $closed_prs; do
      local pr_title
      pr_title=$(cat "$state_file" | /usr/bin/python3 -c "import sys,json; prs=json.load(sys.stdin); [print(p['title']) for p in prs if p['number']==$pr_num]" 2>/dev/null)
      notify "PR Closed — $short_name" "#${pr_num}: ${pr_title}" "merged or closed"
    done
  else
    # First run — just report count
    local count
    count=$(echo "$current_numbers" | grep -c '[0-9]' || true)
    if [[ "$count" -gt 0 ]]; then
      if [[ "$STDOUT_ONLY" == true ]]; then
        echo "[$short_name] $count open PR(s)"
        echo "$current" | /usr/bin/python3 -c "
import sys,json
for p in json.load(sys.stdin):
    print(f\"  #{p['number']}: {p['title']} (by {p['author']['login']})\")" 2>/dev/null
      fi
      log "$short_name: $count open PR(s) — initial state captured"
    fi
  fi

  # Save current state
  echo "$current" > "$state_file"
}

check_runs() {
  local repo="$1"
  local safe=$(safe_name "$repo")
  local state_file="${STATE_DIR}/${safe}_runs.json"
  local short_name=$(echo "$repo" | cut -d'/' -f2)

  local current
  current=$(gh run list --repo "$repo" --limit 5 --json databaseId,name,status,conclusion,updatedAt,headBranch 2>/dev/null)

  if [[ -z "$current" || "$current" == "null" ]]; then
    return
  fi

  if [[ -f "$state_file" ]]; then
    # Check for newly failed runs
    local failed
    failed=$(echo "$current" | /usr/bin/python3 -c "
import sys,json
prev = json.load(open('$state_file'))
curr = json.load(sys.stdin)
prev_ids = {r['databaseId']: r.get('conclusion','') for r in prev}
for r in curr:
    rid = r['databaseId']
    if r.get('conclusion') == 'failure':
        if rid not in prev_ids or prev_ids[rid] != 'failure':
            print(f\"{r['name']}|{r['headBranch']}\")
" 2>/dev/null)

    while IFS='|' read -r run_name branch; do
      [[ -z "$run_name" ]] && continue
      notify "CI Failed — $short_name" "$run_name" "branch: $branch"
    done <<< "$failed"

    # Check for newly successful runs (that were previously failing)
    local fixed
    fixed=$(echo "$current" | /usr/bin/python3 -c "
import sys,json
prev = json.load(open('$state_file'))
curr = json.load(sys.stdin)
prev_ids = {r['databaseId']: r.get('conclusion','') for r in prev}
for r in curr:
    rid = r['databaseId']
    if r.get('conclusion') == 'success':
        if rid in prev_ids and prev_ids[rid] == 'failure':
            print(f\"{r['name']}|{r['headBranch']}\")
" 2>/dev/null)

    while IFS='|' read -r run_name branch; do
      [[ -z "$run_name" ]] && continue
      notify "CI Fixed — $short_name" "$run_name" "branch: $branch"
    done <<< "$fixed"
  fi

  echo "$current" > "$state_file"
}

# --- Main loop ---
log "--- github-watcher run start (${#REPOS[@]} repos) ---"

for repo in "${REPOS[@]}"; do
  check_prs "$repo"
  check_runs "$repo"
done

log "--- github-watcher run complete ---"

if [[ "$STDOUT_ONLY" == true ]]; then
  echo ""
  echo "Watching ${#REPOS[@]} repos. State in $STATE_DIR"
fi
