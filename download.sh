#!/bin/bash
# Run once to download and verify the anon binary and signing key.
# After this, all builds are fully offline.
set -eo pipefail

#ANON_VERSION="0.4.9.13-live-1~d12.bookworm+1" 
#ANON_DEB="anon_${ANON_VERSION}_amd64.deb"
#ANON_URL="https://deb.en.anyone.tech/pool/main/a/anon/${ANON_DEB}"
ANON_URL="https://github.com/anyone-protocol/ator-protocol/releases/download/v0.4.10.2/anon_0.4.10.2-live-1.d12.bookworm+1_amd64.deb"
ANON_SHA256="7e6a17523956e2b2771306bb96b5ad4ce38b1a02e18469b6f1acae77229083bb"
ANON_SHA256="2073a0eee48aa2bfe7fd7594c19869b722517e6a2971a8be2295a1efd81001fa"
SIGNING_KEY_URL="https://deb.en.anyone.tech/anon.asc"
EXPECTED_KEY_ID="DC73B31AA1F797B180A87CBC7571AA42A0CBEFE9"

echo "==> Downloading Anyone Protocol signing key"
wget -q --show-progress -O anon.asc "$SIGNING_KEY_URL"

echo "==> Verifying signing key ID"
KEY_ID=$(gpg --show-keys --with-fingerprint --with-colons anon.asc 2>/dev/null | grep -i "$EXPECTED_KEY_ID" || true)
if [ -z "$KEY_ID" ]; then
    echo "ERROR: GPG key ID mismatch — expected $EXPECTED_KEY_ID"
    echo "       Deleting anon.asc — do NOT use this key."
    rm -f anon.asc
    exit 1
fi
echo "    Key ID verified: $EXPECTED_KEY_ID"

echo "==> Downloading anon binary: $ANON_DEB"
wget -q --show-progress -O anon.deb "$ANON_URL"

echo "==> Verifying SHA256"
echo "$ANON_SHA256 anon.deb" | sha256sum -c - || {
    echo "ERROR: SHA256 mismatch — deleting binary."
    rm -f "$ANON_DEB"
    exit 1
}
echo "    SHA256 verified."
