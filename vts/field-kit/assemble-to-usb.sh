#!/usr/bin/env bash
# Assemble full Valley Tech field kit onto Ventoy USB (or any mount path).
#
# Usage:
#   bash assemble-to-usb.sh
#   bash assemble-to-usb.sh "/run/media/kraken/Ventoy"
#   bash assemble-to-usb.sh "/run/media/kraken/256GB PNY Drive"
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USB="${1:-/run/media/kraken/Ventoy}"

if [[ ! -d "${USB}" ]]; then
  echo "USB mount not found: ${USB}"
  echo "Plug in the Ventoy stick and wait for it to appear."
  echo "Then run: ls /run/media/kraken/"
  echo "Usage: bash $0 \"/run/media/kraken/YOUR_LABEL\""
  exit 1
fi

if [[ ! -w "${USB}" ]]; then
  echo "USB not writable: ${USB}"
  exit 1
fi

DEST="${USB}/field-kit"
echo "=== Assembling field kit → ${DEST} ==="

# Refresh local kit contents from sources
STAGE="${SRC_KIT}/.stage"
rm -rf "${STAGE}"
mkdir -p "${STAGE}/nextcloud" "${STAGE}/vyos-router" "${STAGE}/smadp-mesh" "${STAGE}/docs"

# Nextcloud: prefer full nc-lin-cs field kit, fall back to packages/nc_install
NC_SRC=""
if [[ -d "${HOME}/systems_admin/HICKMAN_ROOT/Joshua/Projects/nc-lin-cs" ]]; then
  NC_SRC="${HOME}/systems_admin/HICKMAN_ROOT/Joshua/Projects/nc-lin-cs"
elif [[ -d "${ROOT}/packages/nc_install" ]]; then
  NC_SRC="${ROOT}/packages/nc_install"
fi
if [[ -n "${NC_SRC}" ]]; then
  echo "Nextcloud from: ${NC_SRC}"
  rsync -a --delete \
    --exclude '.git/' \
    --exclude 'phase-docs/.install-credentials' \
    --exclude 'phase-docs/*credentials*' \
    "${NC_SRC}/" "${STAGE}/nextcloud/"
else
  echo "WARN: no Nextcloud installer source found"
fi

# VyOS router package (canonical network-install)
VYOS_SRC="${ROOT}/packages/network-install"
if [[ -d "${VYOS_SRC}" ]]; then
  echo "VyOS kit from: ${VYOS_SRC}"
  rsync -a --delete \
    --exclude 'dist/' \
    --exclude 'runtime/' \
    --exclude 'parent/runtime/' \
    --exclude 'secrets/netdata-stream.env' \
    --exclude '.stage/' \
    "${VYOS_SRC}/" "${STAGE}/vyos-router/"
else
  echo "WARN: network-install missing"
fi

# SMADP / mesh installer (optional advanced)
if [[ -d "${HOME}/SovereignAid/aide_installer_pkg" ]]; then
  echo "SMADP mesh from: aide_installer_pkg"
  rsync -a --delete \
    --exclude '.git/' \
    "${HOME}/SovereignAid/aide_installer_pkg/" "${STAGE}/smadp-mesh/"
fi

# Docs from overview + beginner guides
cp -a "${SRC_KIT}/00-START-HERE.md" "${STAGE}/" 2>/dev/null || true
cp -a "${SRC_KIT}/START.md" "${STAGE}/" 2>/dev/null || true
cp -a "${SRC_KIT}/START-OS.md" "${STAGE}/" 2>/dev/null || true
cp -a "${ROOT}/AGENT.md" "${STAGE}/AGENT.md" 2>/dev/null || true
mkdir -p "${STAGE}/docs"
cp -a "${SRC_KIT}/docs/." "${STAGE}/docs/" 2>/dev/null || true
# Per-installer START guides (overlay onto staged packages)
[[ -f "${SRC_KIT}/nextcloud/START.md" ]] && cp -f "${SRC_KIT}/nextcloud/START.md" "${STAGE}/nextcloud/START.md"
[[ -f "${SRC_KIT}/vyos-router/START.md" ]] && cp -f "${SRC_KIT}/vyos-router/START.md" "${STAGE}/vyos-router/START.md"
[[ -f "${SRC_KIT}/smadp-mesh/START.md" ]] && cp -f "${SRC_KIT}/smadp-mesh/START.md" "${STAGE}/smadp-mesh/START.md"
if [[ -d "${ROOT}/overview" ]]; then
  rsync -a "${ROOT}/overview/" "${STAGE}/docs/business/"
fi

# Index
cat > "${STAGE}/MANIFEST.txt" <<EOF
Valley Tech Field Kit
Built: $(date -Iseconds)
Host: $(hostname)
Nextcloud: ${NC_SRC:-none}
VyOS: ${VYOS_SRC:-none}
EOF

# Push to USB (FAT/exFAT has no symlinks — copy targets as real files)
mkdir -p "${DEST}"
rsync -a --delete --copy-links "${STAGE}/" "${DEST}/"

# Root pointer on USB
cat > "${USB}/VALLEY-TECH-FIELD-KIT.txt" <<EOF
Valley Tech Field Kit is in:

  field-kit/00-START-HERE.md

VyOS ISO (if present): look for vyos-*.iso on this Ventoy stick root.
Built: $(date -Iseconds)
EOF

sync
echo ""
echo "=== Done ==="
echo "Open on USB: ${DEST}/00-START-HERE.md"
df -h "${USB}" | tail -1
ls -la "${DEST}"
