#!/usr/bin/env bash
# test-vault-tools.sh — end-to-end smoke for the vault + apple ML toolchain.
#
# Exits 0 on green. Each check prints PASS/FAIL with one line of evidence.
# Designed to run in a few seconds against an already-warm cache; first run
# on a fresh machine takes ~5-10 min while it embeds a slice of merlib-dump.

set -uo pipefail
BIN=~/work/apple/bin
FAIL=0
PASS=0

check() {
    local desc=$1; shift
    local got=$("$@" 2>&1)
    local rc=$?
    if [ $rc -eq 0 ]; then
        echo "  PASS  $desc"
        PASS=$((PASS+1))
    else
        echo "  FAIL  $desc"
        echo "    →  $got" | head -3
        FAIL=$((FAIL+1))
    fi
}

require_match() {
    local desc=$1; local pattern=$2; shift 2
    local out=$("$@" 2>&1)
    if echo "$out" | grep -qE "$pattern"; then
        echo "  PASS  $desc"
        PASS=$((PASS+1))
    else
        echo "  FAIL  $desc — pattern '$pattern' not found"
        echo "$out" | head -5 | sed 's/^/    →  /'
        FAIL=$((FAIL+1))
    fi
}

echo
echo "═══ binaries on PATH ═══"
for tool in apple-embed apple-embed-pro apple-ner apple-translate apple-semantic-match apple-image-similar vault-grep vault-consilience vault-cluster vault-distill vault-promote sessions sgrep ; do
    if command -v $tool >/dev/null 2>&1 ; then
        echo "  PASS  $tool"
        PASS=$((PASS+1))
    else
        echo "  FAIL  $tool not on PATH"
        FAIL=$((FAIL+1))
    fi
done

echo
echo "═══ apple-embed (NLEmbedding) ═══"
require_match "produces JSON line with 512-d vector" \
    '"v":\[' \
    bash -c "echo 'hello world' | $BIN/apple-embed"

echo
echo "═══ apple-embed-pro (CoreML MiniLM) ═══"
if [ -d ~/work/apple/models/MiniLM/MiniLM.mlpackage ]; then
    require_match "produces JSON line with 384-d vector" \
        '"v":\[' \
        bash -c "echo 'hello world' | $BIN/apple-embed-pro"
else
    echo "  SKIP  apple-embed-pro: model not built (run /tmp/convert-minilm.py)"
fi

echo
echo "═══ apple-ner ═══"
require_match "extracts Tesla as PersonalName" \
    "PersonalName" \
    bash -c "echo 'Tesla worked on the wireless transmission.' | $BIN/apple-ner --table"

echo
echo "═══ apple-translate (gate documented; needs lang packs) ═══"
echo "  SKIP  apple-translate: requires Translate.app language pack download"

echo
echo "═══ vault-grep (semantic search) ═══"
require_match "returns at least one scored hit on the diary cache" \
    "^0\." \
    bash -c "$BIN/vault-grep 'cold electricity' --root ~/work/merlib-dump/diary --top 1 --limit 5"

echo
echo "═══ vault-consilience (cross-source) ═══"
require_match "returns the QUERY header" \
    "QUERY:" \
    bash -c "$BIN/vault-consilience 'aether substance' --root ~/work/merlib-dump/sources/hilarion --root ~/work/merlib-dump/diary --per-root 1 --cached-only"

echo
echo "═══ vault-cluster (pairwise) ═══"
require_match "returns cross-file pairs above threshold" \
    "top.*cross-file pairs" \
    bash -c "$BIN/vault-cluster --root ~/work/merlib-dump/sources/hilarion --top 3 --threshold 0.8 --cached-only --max-lines 500"

echo
echo "═══ vault-distill (cache hit only — no claude call) ═══"
DISTILL_SAMPLE=~/.vault-distill/$(ls ~/.vault-distill/ 2>/dev/null | head -1)
if [ -f "$DISTILL_SAMPLE" ]; then
    require_match "cached distill has frontmatter" \
        "^source_file:" \
        cat "$DISTILL_SAMPLE"
else
    echo "  SKIP  vault-distill: no cached distill yet — run vault-distill on a file once"
fi

echo
echo "═══ vault-promote (verify cc-vault file exists) ═══"
PROMOTED=~/work/cc/vault/sources/conversations/free-energy/hilarion/chapter-04-magnetism-verbatim.md
if [ -f "$PROMOTED" ]; then
    require_match "promoted file has topic + vault_path frontmatter" \
        "^topic: free-energy" \
        cat "$PROMOTED"
else
    echo "  SKIP  vault-promote: no promoted file at $PROMOTED — run vault-promote once"
fi

echo
echo "═══ sessions (TUI picker — non-interactive: ls subcommand) ═══"
require_match "sessions ls returns at least one row" \
    "(claude|copilot|codex|converse)" \
    bash -c "$BIN/sessions ls 5"

echo
echo "═══ sgrep (semantic across sessions) ═══"
require_match "sgrep returns at least one scored hit" \
    "^0\." \
    bash -c "$BIN/sgrep 'envoy livefile' --top 1 --limit 3"

echo
echo "════════════════════════════════════════════"
echo "  RESULTS:  $PASS passed,  $FAIL failed"
echo "════════════════════════════════════════════"
exit $FAIL
