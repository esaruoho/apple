#!/opt/homebrew/bin/bash
# sal-transcribe-podcasts.sh — orchestrator for Sal Soghoian Apple Podcasts.
#
# Pipeline:
#   1. Run bin/sal-resolve-podcast-mp3s.py to refresh apple-podcast-mp3-urls.yaml
#   2. For each resolved episode:
#        - download MP3 to /tmp/sal-podcasts/<slug>.mp3
#        - run ~/work/whisp/whisp <file> with proper-noun bias
#        - move resulting transcript .txt + .json to
#          sources/sal/transcripts/podcasts/<show-slug>/<slug>.txt
#        - delete the MP3 to save space
#   3. Commit + push apple repo if anything was added
#   4. Optionally drop a Discord summary into the pakettibot inbox bridge
#
# Designed for CloudcityMacMini.local — but portable, no SSH, no daemon.
# Skips episodes whose transcript already exists.
#
# Env:
#   APPLE_REPO        default: /Users/esaruoho/work/apple
#   WHISP_BIN         default: /Users/esaruoho/work/whisp/whisp
#   STAGING_DIR       default: /tmp/sal-podcasts
#   SKIP_COMMIT       set to 1 to skip git commit + push
#   POST_DISCORD      set to 1 to drop a summary into pakettibot inbox

set -euo pipefail

APPLE_REPO="${APPLE_REPO:-/Users/esaruoho/work/apple}"
WHISP_BIN="${WHISP_BIN:-/Users/esaruoho/work/whisp/whisp}"
STAGING_DIR="${STAGING_DIR:-/tmp/sal-podcasts}"
SKIP_COMMIT="${SKIP_COMMIT:-0}"
POST_DISCORD="${POST_DISCORD:-0}"
PAKETTIBOT_INBOX="${HOME}/work/comms/queue/pakettibot-inbox"

YAML="${APPLE_REPO}/analysis/sal/apple-podcast-mp3-urls.yaml"
TRANSCRIPTS_BASE="${APPLE_REPO}/sources/sal/transcripts/podcasts"

echo "[sal-podcasts] APPLE_REPO=${APPLE_REPO}"
echo "[sal-podcasts] WHISP_BIN=${WHISP_BIN}"
echo "[sal-podcasts] STAGING_DIR=${STAGING_DIR}"

mkdir -p "${STAGING_DIR}" "${TRANSCRIPTS_BASE}"

# 1. Refresh the resolved MP3 URL list
echo "[sal-podcasts] Refreshing resolved MP3 URLs..."
python3 "${APPLE_REPO}/bin/sal-resolve-podcast-mp3s.py" || {
    echo "[sal-podcasts] resolver failed" >&2
    exit 1
}

# 2. Iterate resolved entries via a tiny inline Python that emits TSV
mapfile -t entries < <(python3 - "${YAML}" <<'PY'
import sys, re, yaml as _yaml
# stdlib has no yaml; do a minimal manual parse since we control the format
text = open(sys.argv[1]).read()
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
for b in blocks:
    if b.get("status") == "resolved":
        # TSV: slug \t show \t episode_title \t mp3_url \t pub_date
        print("\t".join([
            b.get("slug", ""),
            b.get("show", ""),
            b.get("episode_title", ""),
            b.get("mp3_url", ""),
            b.get("pub_date", ""),
        ]))
PY
)

if [[ ${#entries[@]} -eq 0 ]]; then
    echo "[sal-podcasts] No resolved episodes to transcribe."
    exit 0
fi

echo "[sal-podcasts] Will process ${#entries[@]} episode(s)"

processed=0
skipped=0
failed=0

for entry in "${entries[@]}"; do
    IFS=$'\t' read -r slug show episode_title mp3_url pub_date <<<"${entry}"
    show_slug=$(echo "${show}" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')
    [[ -z "${show_slug}" ]] && show_slug="unknown-show"
    out_dir="${TRANSCRIPTS_BASE}/${show_slug}"
    out_txt="${out_dir}/${slug}.txt"

    if [[ -f "${out_txt}" ]]; then
        echo "  [skip] already transcribed: ${slug}"
        ((skipped++))
        continue
    fi

    mkdir -p "${out_dir}"
    mp3_local="${STAGING_DIR}/${slug}.mp3"

    echo "[fetch] ${show} — ${episode_title}"
    if ! curl -fL --retry 2 -A 'Mozilla/5.0' -o "${mp3_local}" "${mp3_url}"; then
        echo "  [fail] download failed for ${slug}"
        ((failed++))
        rm -f "${mp3_local}"
        continue
    fi

    echo "[whisp] ${slug}"
    if ! "${WHISP_BIN}" --en --out "${STAGING_DIR}" "${mp3_local}"; then
        echo "  [fail] whisp failed for ${slug}"
        ((failed++))
        rm -f "${mp3_local}"
        continue
    fi

    # whisp writes <name>.txt next to the input
    whisp_txt="${STAGING_DIR}/${slug}.txt"
    if [[ ! -f "${whisp_txt}" ]]; then
        # Fallback: any .txt newer than the mp3 in staging
        whisp_txt=$(ls -t "${STAGING_DIR}"/*.txt 2>/dev/null | head -1 || true)
    fi
    if [[ -z "${whisp_txt}" || ! -f "${whisp_txt}" ]]; then
        echo "  [fail] no transcript file for ${slug}"
        ((failed++))
        rm -f "${mp3_local}"
        continue
    fi

    # Prepend frontmatter
    {
        echo "---"
        echo "show: $(printf '%q' "${show}")"
        echo "episode_title: $(printf '%q' "${episode_title}")"
        echo "mp3_url: ${mp3_url}"
        echo "pub_date: ${pub_date}"
        echo "slug: ${slug}"
        echo "transcribed_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        echo "transcriber: whisp (Whisper turbo)"
        echo "---"
        echo
        cat "${whisp_txt}"
    } > "${out_txt}"

    rm -f "${mp3_local}" "${whisp_txt}"
    ((processed++))
    echo "  [done] ${out_txt}"
done

echo
echo "[sal-podcasts] processed=${processed}  skipped=${skipped}  failed=${failed}"

# 3. Commit + push if anything new
if [[ "${SKIP_COMMIT}" -ne 1 && "${processed}" -gt 0 ]]; then
    cd "${APPLE_REPO}"
    git add sources/sal/transcripts/podcasts/ analysis/sal/apple-podcast-mp3-urls.yaml analysis/sal/apple-podcast-mp3-urls.txt 2>/dev/null || true
    if ! git diff --cached --quiet; then
        git commit -m "Sal Soghoian podcast transcripts (${processed} new) [auto: sal-transcribe-podcasts.sh]

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
        git push origin main
    fi
fi

# 4. Optionally drop a Discord summary
if [[ "${POST_DISCORD}" -eq 1 && -d "${PAKETTIBOT_INBOX}" ]]; then
    summary_file="${PAKETTIBOT_INBOX}/sal-transcribe-$(date +%s).cmd"
    cat > "${summary_file}" <<EOF
ask "Sal podcast transcription run finished. Processed: ${processed}, skipped: ${skipped}, failed: ${failed}. Latest transcripts under apple/sources/sal/transcripts/podcasts/."
EOF
    echo "[sal-podcasts] Posted Discord summary to pakettibot inbox: ${summary_file}"
fi

exit 0
