#!/opt/homebrew/bin/bash
# sal-transcribe-youtube.sh — submits the 16 Sal YouTube interviews to whisp
# and copies/links the resulting transcripts into the apple repo.
#
# Pipeline:
#   1. Submit URLs from analysis/sal/youtube-interviews-to-transcribe.txt to
#      ~/work/whisp-transcripts/whisp-submit (which enqueues into pending/)
#   2. The whisp-worker daemon (already running on CloudcityMacMini) picks up
#      each .url file, runs yt-dlp + whisper, writes transcripts under
#      ~/work/whisp-transcripts/transcripts/<date>_<slug>/
#   3. After all queued items have moved through the queue, copy the
#      transcript .txt into apple/sources/sal/transcripts/youtube/ with
#      a frontmatter wrapper.
#   4. Commit + push if anything new.
#
# Designed for CloudcityMacMini.local. No SSH; whisp-worker is already running.
#
# Env:
#   APPLE_REPO         default /Users/esaruoho/work/apple
#   WHISP_TRANSCRIPTS  default /Users/esaruoho/work/whisp-transcripts
#   POLL_TIMEOUT_SEC   max wall-clock seconds to wait for queue to drain (0 = no wait)
#   SKIP_COMMIT        set 1 to skip git commit + push

set -euo pipefail

APPLE_REPO="${APPLE_REPO:-/Users/esaruoho/work/apple}"
WHISP_TRANSCRIPTS="${WHISP_TRANSCRIPTS:-${HOME}/work/whisp-transcripts}"
POLL_TIMEOUT_SEC="${POLL_TIMEOUT_SEC:-0}"
SKIP_COMMIT="${SKIP_COMMIT:-0}"
PAKETTIBOT_INBOX="${PAKETTIBOT_INBOX:-${HOME}/work/comms/queue/pakettibot-inbox}"

URL_FILE="${APPLE_REPO}/analysis/sal/youtube-interviews-to-transcribe.txt"
OUT_DIR="${APPLE_REPO}/sources/sal/transcripts/youtube"

mkdir -p "${OUT_DIR}"

if [[ ! -f "${URL_FILE}" ]]; then
    echo "[sal-youtube] missing ${URL_FILE}" >&2
    exit 1
fi

if [[ ! -x "${WHISP_TRANSCRIPTS}/whisp-submit" ]]; then
    echo "[sal-youtube] whisp-submit not executable at ${WHISP_TRANSCRIPTS}/whisp-submit" >&2
    exit 1
fi

# 1. Submit batch (whisp-submit handles dedup against existing queue states)
echo "[sal-youtube] Submitting URLs from ${URL_FILE}..."
"${WHISP_TRANSCRIPTS}/whisp-submit" --no-push --file "${URL_FILE}" || true

# 2. Optionally wait for queue to drain
if [[ "${POLL_TIMEOUT_SEC}" -gt 0 ]]; then
    echo "[sal-youtube] Waiting up to ${POLL_TIMEOUT_SEC}s for queue to drain..."
    deadline=$(( $(date +%s) + POLL_TIMEOUT_SEC ))
    while (( $(date +%s) < deadline )); do
        pending=$(ls "${WHISP_TRANSCRIPTS}/queue/pending"/*.url 2>/dev/null | wc -l | tr -d ' ')
        processing=$(ls "${WHISP_TRANSCRIPTS}/queue/processing"/*.url 2>/dev/null | wc -l | tr -d ' ')
        if [[ "${pending}" -eq 0 && "${processing}" -eq 0 ]]; then
            echo "[sal-youtube] Queue is empty."
            break
        fi
        echo "  pending=${pending}  processing=${processing}  (waiting...)"
        sleep 30
    done
fi

# 3. Sync transcripts from whisp-transcripts into apple repo
#    For each YouTube ID in our URL list, find any matching transcript dir
#    in whisp-transcripts/transcripts/*/ and copy the .txt across.
echo "[sal-youtube] Syncing transcripts into ${OUT_DIR}..."
copied=0
while IFS= read -r url; do
    [[ -z "${url}" || "${url}" == \#* ]] && continue
    # Extract YouTube video id
    vid=$(echo "${url}" | sed -nE 's|.*[?&]v=([a-zA-Z0-9_-]{11}).*|\1|p; s|.*youtu\.be/([a-zA-Z0-9_-]{11}).*|\1|p; s|.*shorts/([a-zA-Z0-9_-]{11}).*|\1|p' | head -1)
    [[ -z "${vid}" ]] && continue

    # Find matching transcript dir (whisp names them <date>_<slug>; metadata.yaml carries url:)
    match_dir=""
    while IFS= read -r meta; do
        if grep -q "${vid}" "${meta}" 2>/dev/null; then
            match_dir="$(dirname "${meta}")"
            break
        fi
    done < <(find "${WHISP_TRANSCRIPTS}/transcripts" -maxdepth 2 -name 'metadata.yaml' 2>/dev/null)

    if [[ -z "${match_dir}" ]]; then
        echo "  [pending] ${vid}: no transcript yet"
        continue
    fi

    txt_file="${match_dir}/transcript.txt"
    [[ -f "${txt_file}" ]] || txt_file=$(ls "${match_dir}"/*.txt 2>/dev/null | grep -v '\-segments\.txt$' | head -1 || true)
    [[ -z "${txt_file}" || ! -f "${txt_file}" ]] && { echo "  [skip] ${vid}: dir found but no transcript .txt"; continue; }

    base=$(basename "${match_dir}")
    out_file="${OUT_DIR}/${base}.txt"
    if [[ -f "${out_file}" ]]; then
        echo "  [skip] ${base}: already in apple repo"
        continue
    fi

    {
        echo "---"
        echo "video_id: ${vid}"
        echo "youtube_url: ${url}"
        echo "whisp_transcript_dir: ${match_dir}"
        echo "transcribed_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        echo "transcriber: whisp via whisp-worker daemon"
        echo "---"
        echo
        cat "${txt_file}"
    } > "${out_file}"
    echo "  [copied] ${out_file}"
    ((copied++))
done < "${URL_FILE}"

echo
echo "[sal-youtube] Copied ${copied} transcript(s) into apple repo."

# 4. Commit + push if anything new
if [[ "${SKIP_COMMIT}" -ne 1 && "${copied}" -gt 0 ]]; then
    cd "${APPLE_REPO}"
    git add sources/sal/transcripts/youtube/
    if ! git diff --cached --quiet; then
        git commit -m "Sal Soghoian YouTube transcripts (${copied} new) [auto: sal-transcribe-youtube.sh]

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
        git push origin main
    fi
fi

# 5. Mandatory Discord summary via pakettibot inbox file-drop bridge.
#    Per-episode completion pings already fire via whisp-worker's events
#    bridge; this is the roll-up posted at the end of the run.
mkdir -p "${PAKETTIBOT_INBOX}"
queue_pending=$(ls "${WHISP_TRANSCRIPTS}/queue/pending"/*.url 2>/dev/null | wc -l | tr -d ' ')
queue_processing=$(ls "${WHISP_TRANSCRIPTS}/queue/processing"/*.url 2>/dev/null | wc -l | tr -d ' ')
queue_failed=$(ls "${WHISP_TRANSCRIPTS}/queue/failed"/*.url 2>/dev/null | wc -l | tr -d ' ')
summary_file="${PAKETTIBOT_INBOX}/sal-youtube-summary-$(date +%s).cmd"
cat > "${summary_file}" <<EOF
ask "Sal Soghoian YouTube transcription run finished. Newly synced into apple repo: ${copied}. Queue right now — pending: ${queue_pending}, processing: ${queue_processing}, failed: ${queue_failed}. Latest transcripts under apple/sources/sal/transcripts/youtube/. Per-episode pings should already be appearing via the whisp events bridge; this is the orchestrator roll-up."
EOF
echo "[sal-youtube] Discord summary dropped at: ${summary_file}"

exit 0
