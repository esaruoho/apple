#!/usr/bin/env bash
# repo-puller.sh — the "git push → auto-pull" channel. Runs ON the companion.
# Every INTERVAL it fast-forward-pulls each repo in repos.conf; when a repo's
# HEAD actually changed AND its defer_check passes, it runs the post_pull_action.
# Writes a heartbeat each tick so the local side knows it's alive.
#
# Deploy: copy this + repos.conf to the companion, then launch detached:
#   nohup /opt/homebrew/bin/bash repo-puller.sh > repo-puller.stdout 2>&1 & disown
# (use /usr/bin/bash on stock macOS if you don't have a newer bash)
#
# This is the WHITELABELED puller — the repos it tracks live in repos.conf,
# which is gitignored. The mechanism is public; your repo list is private.

. "$(dirname "${BASH_SOURCE[0]}")/common.sh"
load_config || exit 1

INTERVAL="${REPO_PULLER_INTERVAL:-60}"
REPOS_CONF="${REPOS_CONF:-$COMPANION_PKG/repos.conf}"
HB="$(dirname "${BASH_SOURCE[0]}")/heartbeat.sh"

[ -f "$REPOS_CONF" ] || die "no repos.conf at $REPOS_CONF (copy repos.conf.example)"

log "repo-puller starting: interval=${INTERVAL}s conf=$REPOS_CONF"

pull_one() {
  local path="$1" branch="$2" action="$3" defer="$4"
  [ -d "$path/.git" ] || { warn "skip (not a git repo): $path"; return; }
  local before after
  before="$(git -C "$path" rev-parse HEAD 2>/dev/null)"
  git -C "$path" pull --ff-only origin "$branch" >/dev/null 2>&1 || {
    warn "pull failed: $path ($branch)"; return; }
  after="$(git -C "$path" rev-parse HEAD 2>/dev/null)"

  [ "$before" = "$after" ] && return        # nothing changed
  log "updated: $path  $before → $after"

  if [ -n "$defer" ] && bash -c "$defer" >/dev/null 2>&1; then
    log "deferring restart of $path (work in flight)"
    return
  fi
  case "$action" in
    ""|noop) : ;;
    *) log "post-pull action: $action"; bash -c "$action" || warn "action failed: $path" ;;
  esac
}

while :; do
  while IFS='|' read -r path branch action defer; do
    case "$path" in ''|\#*) continue ;; esac
    pull_one "${path}" "${branch:-main}" "${action:-}" "${defer:-}"
  done < "$REPOS_CONF"
  bash "$HB" repo-puller ok "interval=${INTERVAL}s" 2>/dev/null || true
  sleep "$INTERVAL"
done
