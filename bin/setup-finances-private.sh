#!/usr/bin/env bash
# setup-finances-private.sh — ONE-TIME setup of a private, password-protected
# https://esaruoho.org/finances/ that only Esa + his wife can open (HTTP Basic Auth
# over HTTPS). Run this ON lackluster.org, with sudo. After this, publishing is just
# `convey finances report --publish` (no sudo — esa owns the content dir).
#
#   ssh -t esa@lackluster.org 'sudo bash -s <USER> <PASSWORD>' < bin/setup-finances-private.sh
# or copy it over and:  sudo bash setup-finances-private.sh <USER> <PASSWORD>
#
# Idempotent. Backs up the nginx site, gates on `nginx -t`, auto-restores on failure.
set -euo pipefail

USER_NAME="${1:-esa}"
PASSWORD="${2:-}"
if [ -z "$PASSWORD" ]; then
  # prompt (no echo) so the password never lands in shell history
  read -rsp "Set the finances password (share this with your wife): " PASSWORD; echo
  read -rsp "Confirm password: " PASSWORD2; echo
  [ "$PASSWORD" = "$PASSWORD2" ] || { echo "passwords didn't match, aborting" >&2; exit 1; }
  [ -z "$PASSWORD" ] && { echo "empty password, aborting" >&2; exit 1; }
fi

SITE="/etc/nginx/sites-available/www.esaruoho.org"
HTPASSWD="/etc/nginx/.finances_htpasswd"
CONTENT_DIR="/var/www/html/finances"
LOC_MARKER="location /finances/"

echo "== 1. content dir (esa-owned, so rsync/publish needs no sudo) =="
mkdir -p "$CONTENT_DIR"
chown esa:esa "$CONTENT_DIR"
# a placeholder so the URL resolves before the first publish
[ -f "$CONTENT_DIR/index.html" ] || echo '<!doctype html><meta charset=utf-8><title>Finances</title><p>Run <code>convey finances report --publish</code> to populate this.</p>' > "$CONTENT_DIR/index.html"
chown esa:esa "$CONTENT_DIR/index.html"

echo "== 2. credentials (openssl apr1 — no apache2-utils needed) =="
HASH="$(openssl passwd -apr1 "$PASSWORD")"
printf '%s:%s\n' "$USER_NAME" "$HASH" > "$HTPASSWD"
chown root:www-data "$HTPASSWD"
chmod 640 "$HTPASSWD"
echo "   wrote $HTPASSWD (user: $USER_NAME)"

echo "== 3. nginx location block (self-correcting) =="
BACKUP="${SITE}.bak.$(date +%s)"
cp -a "$SITE" "$BACKUP"
echo "   backed up -> $BACKUP"
# Remove any existing (possibly misplaced) /finances/ location, then inject a correct one
# into the server block that actually contains `listen 443`. Brace-aware; no substring traps.
python3 - "$SITE" <<'PY'
import sys, re
path = sys.argv[1]
src = open(path).read()

def match_brace(s, open_idx):
    depth = 0
    for j in range(open_idx, len(s)):
        if s[j] == '{': depth += 1
        elif s[j] == '}':
            depth -= 1
            if depth == 0:
                return j
    raise AssertionError("unbalanced braces")

# 1) strip every existing /finances location (with or without slash / redirect) — self-heals
while True:
    m = re.search(r'\n[ \t]*location\s+(=\s+)?/finances/?\s*\{', src)
    if not m:
        break
    brace = src.index('{', m.start())
    end = match_brace(src, brace)
    # swallow a trailing newline for tidiness
    tail = end + 1
    if tail < len(src) and src[tail] == '\n':
        tail += 1
    src = src[:m.start()+1] + src[tail:]

# 2) find the ENCLOSING server block of `listen 443` (scan back for the unmatched `{`)
pos = src.find('listen 443')
assert pos != -1, "no `listen 443` found"
depth = 0
open_idx = None
for k in range(pos, -1, -1):
    c = src[k]
    if c == '}':
        depth += 1
    elif c == '{':
        if depth == 0:
            open_idx = k
            break
        depth -= 1
assert open_idx is not None, "could not find enclosing server block for listen 443"
close_idx = match_brace(src, open_idx)

block = """
    location = /finances { return 301 /finances/; }
    location /finances/ {
        alias /var/www/html/finances/;
        auth_basic "Finances (private)";
        auth_basic_user_file /etc/nginx/.finances_htpasswd;
        index index.html;
    }
"""
src = src[:close_idx] + block + src[close_idx:]
open(path, 'w').write(src)
print("   injected location /finances/ into the listen-443 server block (try_files removed)")
PY

echo "== 4. test + reload (auto-rollback on failure) =="
if nginx -t; then
  systemctl reload nginx
  echo "== DONE =="
  echo "   Private URL: https://esaruoho.org/finances/"
  echo "   Login:       $USER_NAME / (the password you passed)"
  echo "   Publish:     convey finances report --publish"
else
  echo "!! nginx -t FAILED — restoring the backup and aborting." >&2
  if ls "${SITE}.bak."* >/dev/null 2>&1; then
    NEWEST="$(ls -t "${SITE}.bak."* | head -1)"
    cp -a "$NEWEST" "$SITE"
    echo "   restored $SITE from $NEWEST" >&2
  fi
  exit 1
fi
