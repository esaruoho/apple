#!/bin/bash
# One-time setup: create a self-signed code-signing certificate in the login
# keychain so AppleToolbox builds get a stable signing identity. Without this,
# every rebuild changes the binary's cdhash and TCC (Full Disk Access, Apple
# Events, etc.) treats the new binary as a different app — you have to re-grant
# every permission after every build.
#
# After this runs, build.sh signs with "AppleToolbox Local Signing" instead of
# ad-hoc. TCC then keys on the cert's designated requirement (CN + bundle ID),
# which stays stable across rebuilds.
#
# Safe to re-run — it's a no-op if the identity already exists.

set -e

NAME="AppleToolbox Local Signing"
KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"

if security find-identity -v -p codesigning "$KEYCHAIN" 2>/dev/null | grep -q "$NAME"; then
    echo "✅ Signing identity already exists: $NAME"
    security find-identity -v -p codesigning "$KEYCHAIN" | grep "$NAME"
    exit 0
fi

echo "==> Creating self-signed code-signing cert: $NAME"

WORKDIR=$(mktemp -d)
trap "rm -rf '$WORKDIR'" EXIT

cd "$WORKDIR"

# 1. Generate 2048-bit RSA key
openssl genrsa -out key.pem 2048 2>/dev/null

# 2. OpenSSL config — codeSigning EKU is the bit that matters
cat > openssl.cnf <<EOF
[req]
distinguished_name = dn
prompt = no
[dn]
CN = $NAME
O = AppleToolbox
[v3]
keyUsage = critical,digitalSignature
extendedKeyUsage = critical,codeSigning
basicConstraints = critical,CA:false
subjectKeyIdentifier = hash
EOF

# 3. Self-signed cert, 10-year validity
openssl req -new -x509 -days 3650 -key key.pem -out cert.pem \
    -config openssl.cnf -extensions v3 2>/dev/null

# 4. Bundle into PKCS#12 for keychain import
# -legacy flag forces 3DES/SHA1 encryption that macOS's `security` accepts.
# OpenSSL 3 defaults to AES which `security import` cannot decrypt.
openssl pkcs12 -export -legacy -inkey key.pem -in cert.pem -out cert.p12 \
    -name "$NAME" -passout pass:temp 2>/dev/null

# 5. Import into login keychain. -T flags allow codesign + security to access
#    the private key. -A would allow all apps but is broader than needed.
echo "==> Importing into login keychain..."
security import cert.p12 -k "$KEYCHAIN" -P temp \
    -T /usr/bin/codesign \
    -T /usr/bin/security \
    -T /usr/bin/productsign

# 6. Set partition list so codesign can use the key without per-invocation
#    password prompts. This step needs the keychain password — macOS will
#    prompt graphically. Click "Always Allow".
echo ""
echo "==> macOS will now prompt for your login keychain password."
echo "    Click 'Always Allow' to let codesign use the new cert."
echo ""
security set-key-partition-list -S apple-tool:,apple:,codesign: \
    -s -k "" "$KEYCHAIN" 2>/dev/null || {
    echo ""
    echo "ℹ️  Partition list may need manual approval the first time codesign runs."
    echo "    If you see a keychain prompt during build.sh, click 'Always Allow'."
}

echo ""
echo "✅ Done. Identity available:"
security find-identity -v -p codesigning "$KEYCHAIN" | grep "$NAME" || true
echo ""
echo "Next: rerun bash build.sh — it will auto-detect and use this identity."
