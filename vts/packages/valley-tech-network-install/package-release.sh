#!/usr/bin/env bash
# Build a USB-ready tarball (no secrets, no runtime keys).
# Output: dist/valley-tech-network-install-VERSION.tar.gz
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="$(tr -d '[:space:]' < "${ROOT}/VERSION")"
DIST="${ROOT}/dist"
STAGE="${DIST}/stage-valley-tech-network-install-${VERSION}"
NAME="valley-tech-network-install-${VERSION}"
OUT="${DIST}/${NAME}.tar.gz"

mkdir -p "${DIST}"
rm -rf "${STAGE}"
mkdir -p "${STAGE}"

# Optional: cache kickstart for offline-ish child installs (still needs packages online)
VENDOR="${ROOT}/vendor"
mkdir -p "${VENDOR}"
if [[ ! -f "${VENDOR}/kickstart.sh" ]]; then
  echo "Caching Netdata kickstart.sh into vendor/ (needs internet once)..."
  curl -fsSL https://get.netdata.cloud/kickstart.sh -o "${VENDOR}/kickstart.sh" || \
    echo "WARN: could not cache kickstart — child install will download on site"
fi

rsync -a \
  --exclude 'dist/' \
  --exclude 'runtime/' \
  --exclude '.git/' \
  --exclude 'secrets/' \
  --exclude 'inventory.yaml' \
  --exclude 'clients.yaml' \
  --exclude 'child/netdata-stream.env' \
  --exclude '*.tar.gz' \
  "${ROOT}/" "${STAGE}/${NAME}/"

# Empty secrets placeholder on stick
mkdir -p "${STAGE}/${NAME}/secrets"
cat > "${STAGE}/${NAME}/secrets/README.txt" <<'EOF'
Put netdata-stream.env here ONLY on the USB after generating it on the parent.
Never leave this stick lying around with live API keys after a client job.
EOF

# Field README at tarball root
cp "${ROOT}/USB-READY.md" "${STAGE}/${NAME}/" 2>/dev/null || true

# Bundle business pricing snapshot for field quotes
mkdir -p "${STAGE}/${NAME}/docs-snapshot"
for f in 03_Services_Overview.md 05_Monitoring_Retainer.md 04_Service_Agreement.md; do
  src="${ROOT}/../../overview/${f}"
  [[ -f "${src}" ]] && cp "${src}" "${STAGE}/${NAME}/docs-snapshot/" || true
done

# MANIFEST
( cd "${STAGE}/${NAME}" && find . -type f | sort > MANIFEST.txt )

tar -C "${STAGE}" -czf "${OUT}" "${NAME}"
rm -rf "${STAGE}"

# Also keep an exploded copy ready for rsync to USB
EXPLODED="${DIST}/${NAME}"
rm -rf "${EXPLODED}"
mkdir -p "${EXPLODED}"
tar -C "${EXPLODED}" -xzf "${OUT}"
# tarball extracts one top dir — flatten pointer
echo ""
echo "========================================"
echo "USB PACKAGE READY (not on stick yet)"
echo "  Tarball:  ${OUT}"
echo "  Exploded: ${EXPLODED}/${NAME}/"
echo "  Size:     $(du -h "${OUT}" | awk '{print $1}')"
echo ""
echo ">>> YOU: when USB is mounted, run:"
echo "  bash ${ROOT}/copy-to-usb.sh /path/to/usb/mount"
echo "  # example: bash ${ROOT}/copy-to-usb.sh /media/\$USER/VTECH"
echo "========================================"
