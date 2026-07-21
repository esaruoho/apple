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

echo "== 3. nginx location block (idempotent) =="
if grep -qF "$LOC_MARKER" "$SITE"; then
  echo "   already present — leaving nginx config untouched."
else
  BACKUP="${SITE}.bak.$(date +%s)"
  cp -a "$SITE" "$BACKUP"
  echo "   backed up → $BACKUP"
  # insert the location block just before the final closing brace of the `listen 443` server block
  python3 - "$SITE" <<'PY'
import sys, re
path = sys.argv[1]
src = open(path).read()
block = """
    location /finances/ {
        alias /var/www/html/finances/;
        auth_basic "Finances — private";
        auth_basic_user_file /etc/nginx/.finances_htpasswd;
        index index.html;
        try_files $uri $uri/ =404;
    }
"""
# find the server block that contains `listen 443` and inject before its matching closing brace
m = re.search(r'server\s*\{', src)
# locate the 443 server block start
idx = src.find('listen 443')
assert idx != -1, "no `listen 443` server block found"
start = src.rfind('server', 0, idx)
# walk braces from the first { after start to find the matching }
i = src.find('{', start)
depth = 0
end = None
for j in range(i, len(src)):
    if src[j] == '{': depth += 1
    elif src[j] == '}':
        depth -= 1
        if depth == 0:
            end = j
            break
assert end is not None, "unbalanced braces"
src = src[:end] + block + src[end:]
open(path, 'w').write(src)
print("   injected location /finances/ into the 443 server block")
PY
fi

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
