#!/opt/homebrew/bin/bash
# sal-transcribe-podcasts.sh — orchestrator for Sal Soghoian Apple Podcasts.
#
# As of the unified whisp-submit (which now accepts both YouTube and direct
# audio URLs), this script is a thin wrapper around the same queue path the
# YouTube track uses. It:
#
#   1. Runs bin/sal-resolve-podcast-mp3s.py to refresh apple-podcast-mp3-urls.txt
#   2. Submits the resolved MP3 URLs via ~/work/whisp-transcripts/whisp-submit
#      (which writes pending/.url files with kind: audio so whisp-worker
#      knows to curl + run whisp directly instead of yt-dlp)
#   3. Optionally polls the queue until it drains
#   4. Syncs resulting transcripts from ~/work/whisp-transcripts/transcripts/
#      into apple/sources/sal/transcripts/podcasts/<show>/<slug>.txt
#      with a frontmatter wrapper carrying provenance
#   5. Commits + pushes the apple repo if anything new arrived
#   6. Drops a final summary into the pakettibot inbox so it lands on
#      Discord. (Per-episode completion notifications are automatic via
#      whisp-worker's events bridge; this is the roll-up.)
#
# Designed for CloudcityMacMini.local. No SSH, no daemon — whisp-worker
# is already running.
#
# Env:
#   APPLE_REPO         default /Users/esaruoho/work/apple
#   WHISP_TRANSCRIPTS  default /Users/esaruoho/work/whisp-transcripts
#   POLL_TIMEOUT_SEC   max wall-clock seconds to wait for queue to drain (0 = no wait)
#   SKIP_COMMIT        set 1 to skip git commit + push of the apple repo
#   PAKETTIBOT_INBOX   default ~/work/comms/queue/pakettibot-inbox

set -euo pipefail

APPLE_REPO="${APPLE_REPO:-/Users/esaruoho/work/apple}"
WHISP_TRANSCRIPTS="${WHISP_TRANSCRIPTS:-${HOME}/work/whisp-transcripts}"
POLL_TIMEOUT_SEC="${POLL_TIMEOUT_SEC:-0}"
SKIP_COMMIT="${SKIP_COMMIT:-0}"
PAKETTIBOT_INBOX="${PAKETTIBOT_INBOX:-${HOME}/work/comms/queue/pakettibot-inbox}"

MP3_TXT="${APPLE_REPO}/analysis/sal/apple-podcast-mp3-urls.txt"
YAML="${APPLE_REPO}/analysis/sal/apple-podcast-mp3-urls.yaml"
OUT_BASE="${APPLE_REPO}/sources/sal/transcripts/podcasts"

mkdir -p "${OUT_BASE}"

# 1. Refresh the resolved MP3 URL list
echo "[sal-podcasts] Refreshing resolved MP3 URLs..."
python3 "${APPLE_REPO}/bin/sal-resolve-podcast-mp3s.py" || {
    echo "[sal-podcasts] resolver failed" >&2
    exit 1
}

if [[ ! -x "${WHISP_TRANSCRIPTS}/whisp-submit" ]]; then
    echo "[sal-podcasts] whisp-submit not executable at ${WHISP_TRANSCRIPTS}/whisp-submit" >&2
    exit 1
fi

# 2. Submit the resolved MP3 URLs to whisp-submit (which detects kind=audio)
echo "[sal-podcasts] Submitting MP3 URLs to whisp-submit..."
"${WHISP_TRANSCRIPTS}/whisp-submit" --no-push --file "${MP3_TXT}" || true

# 3. Optionally wait for queue to drain
if [[ "${POLL_TIMEOUT_SEC}" -gt 0 ]]; then
    echo "[sal-podcasts] Waiting up to ${POLL_TIMEOUT_SEC}s for queue to drain..."
    deadline=$(( $(date +%s) + POLL_TIMEOUT_SEC ))
    while (( $(date +%s) < deadline )); do
        pending=$(ls "${WHISP_TRANSCRIPTS}/queue/pending"/*.url 2>/dev/null | wc -l | tr -d ' ')
        processing=$(ls "${WHISP_TRANSCRIPTS}/queue/processing"/*.url 2>/dev/null | wc -l | tr -d ' ')
        if [[ "${pending}" -eq 0 && "${processing}" -eq 0 ]]; then
            echo "[sal-podcasts] Queue is empty."
            break
        fi
        echo "  pending=${pending}  processing=${processing}  (waiting...)"
        sleep 30
    done
fi

# 4. Sync any audio-kind transcripts from whisp-transcripts into apple repo,
#    organized by podcast show. Match by URL (each whisp transcript has
#    metadata.yaml with the audio URL).
echo "[sal-podcasts] Syncing audio transcripts into ${OUT_BASE}..."
copied=0

# Build a Python-driven matcher that walks resolved YAML + transcript dirs
copied=$(python3 - "$YAML" "$WHISP_TRANSCRIPTS/transcripts" "$OUT_BASE" <<'PY'
import os, re, sys, json, datetime
from pathlib import Path

yaml_path, whisp_dir, out_base = sys.argv[1], sys.argv[2], sys.argv[3]
text = Path(yaml_path).read_text()

# Minimal block parser (same shape as sal-transcribe-podcasts.sh used)
blocks = []
cur = {}
for line in text.splitlines():
    if line.startswith("  - apple_url:"):
        if cur: blocks.append(cur)
        cur = {"apple_url": line.split(":", 1)[1].strip()}
    elif line.startswith("    "):
        m = re.match(r"\s+(\w+):\s*(.*)$", line)
        if m and cur is not None:
            k, v = m.group(1), m.group(2).strip().strip("'").strip('"')
            cur[k] = v
if cur: blocks.append(cur)

resolved = [b for b in blocks if b.get("status") == "resolved" and b.get("mp3_url")]

# Index whisp transcripts by their source URL (read metadata.yaml)
whisp_index = {}
whisp_root = Path(whisp_dir)
if whisp_root.is_dir():
    for sub in whisp_root.iterdir():
        if not sub.is_dir(): continue
        meta = sub / "metadata.yaml"
        if not meta.exists(): continue
        try:
            content = meta.read_text()
            url_m = re.search(r"^url:\s*(.+)$", content, re.M)
            if url_m:
                whisp_index[url_m.group(1).strip()] = sub
        except Exception:
            continue

copied = 0
for r in resolved:
    sub = whisp_index.get(r["mp3_url"])
    if not sub:
        continue  # not transcribed yet
    show = r.get("show", "unknown")
    show_slug = re.sub(r"[^a-z0-9]+", "-", show.lower()).strip("-") or "unknown-show"
    slug = r.get("slug") or sub.name
    out_dir = Path(out_base) / show_slug
    out_dir.mkdir(parents=True, exist_ok=True)
    out_file = out_dir / f"{slug}.txt"
    if out_file.exists():
        continue
    txt_src = sub / "transcript.txt"
    if not txt_src.exists():
        continue
    body = txt_src.read_text(errors="replace")
    frontmatter = (
        "---\n"
        f"show: {json.dumps(show)}\n"
        f"episode_title: {json.dumps(r.get('episode_title', ''))}\n"
        f"apple_url: {r['apple_url']}\n"
        f"mp3_url: {r['mp3_url']}\n"
        f"feed_url: {r.get('feed_url', '')}\n"
        f"pub_date: {json.dumps(r.get('pub_date', ''))}\n"
        f"slug: {slug}\n"
        f"whisp_transcript_dir: {sub}\n"
        f"transcribed_at: {datetime.datetime.utcnow().isoformat()}Z\n"
        f"transcriber: whisp via whisp-worker daemon (kind=audio)\n"
        "---\n\n"
    )
    out_file.write_text(frontmatter + body)
    copied += 1

print(copied)
PY
)

echo
echo "[sal-podcasts] Copied ${copied} podcast transcript(s) into apple repo."

# 5. Commit + push the apple repo if anything new
if [[ "${SKIP_COMMIT}" -ne 1 && "${copied}" -gt 0 ]]; then
    cd "${APPLE_REPO}"
    git add sources/sal/transcripts/podcasts/ analysis/sal/apple-podcast-mp3-urls.yaml analysis/sal/apple-podcast-mp3-urls.txt 2>/dev/null || true
    if ! git diff --cached --quiet; then
        git commit -m "Sal Soghoian podcast transcripts (${copied} new) [auto: sal-transcribe-podcasts.sh]

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
        git push origin main
    fi
fi

# 6. Mandatory Discord summary via pakettibot inbox file-drop bridge.
#    Per-episode completion pings already fire via whisp-worker's events
#    bridge; this is the roll-up posted at the end of the run.
mkdir -p "${PAKETTIBOT_INBOX}"
queue_pending=$(ls "${WHISP_TRANSCRIPTS}/queue/pending"/*.url 2>/dev/null | wc -l | tr -d ' ')
queue_processing=$(ls "${WHISP_TRANSCRIPTS}/queue/processing"/*.url 2>/dev/null | wc -l | tr -d ' ')
queue_failed=$(ls "${WHISP_TRANSCRIPTS}/queue/failed"/*.url 2>/dev/null | wc -l | tr -d ' ')
summary_file="${PAKETTIBOT_INBOX}/sal-podcasts-summary-$(date +%s).cmd"
cat > "${summary_file}" <<EOF
ask "Sal Soghoian podcast transcription run finished. Newly synced into apple repo: ${copied}. Queue right now — pending: ${queue_pending}, processing: ${queue_processing}, failed: ${queue_failed}. Latest transcripts under apple/sources/sal/transcripts/podcasts/. Per-episode pings should already be appearing via the whisp events bridge; this is the orchestrator roll-up."
EOF
echo "[sal-podcasts] Discord summary dropped at: ${summary_file}"

exit 0
