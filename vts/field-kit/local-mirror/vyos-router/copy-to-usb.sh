#!/usr/bin/env bash
# Copy the pre-built package onto a mounted USB drive.
# Usage: bash copy-to-usb.sh /media/kraken/LABEL
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="$(tr -d '[:space:]' < "${ROOT}/VERSION")"
NAME="valley-tech-network-install-${VERSION}"
DIST="${ROOT}/dist"
TAR="${DIST}/${NAME}.tar.gz"
SRC_DIR="${DIST}/${NAME}/${NAME}"

MOUNT="${1:-}"
if [[ -z "${MOUNT}" ]]; then
  echo "Usage: bash copy-to-usb.sh /path/to/usb/mountpoint"
  echo ""
  echo ">>> YOU: plug in the USB, mount it, then re-run with the mount path."
  echo "List mounts: lsblk -o NAME,SIZE,MOUNTPOINT,LABEL"
  exit 1
fi

[[ -d "${MOUNT}" ]] || { echo "ERROR: not a directory: ${MOUNT}"; exit 1; }
[[ -w "${MOUNT}" ]] || { echo "ERROR: not writable: ${MOUNT}"; exit 1; }

if [[ ! -f "${TAR}" ]]; then
  echo "No release tarball yet — building..."
  bash "${ROOT}/package-release.sh"
fi

# Prefer exploded tree
if [[ ! -d "${SRC_DIR}" ]]; then
  mkdir -p "${DIST}/${NAME}"
  tar -C "${DIST}/${NAME}" -xzf "${TAR}"
fi

DEST="${MOUNT}/valley-tech-network-install"
rm -rf "${DEST}"
mkdir -p "${DEST}"
rsync -a --delete "${SRC_DIR}/" "${DEST}/"
cp -f "${TAR}" "${MOUNT}/" 2>/dev/null || true

sync
echo ""
echo "Copied to: ${DEST}"
echo "Tarball:   ${MOUNT}/$(basename "${TAR}")"
echo ">>> YOU: safely eject the USB when done (umount / eject)."
echo ">>> YOU: do NOT put netdata-stream.env on the stick until parent is installed,"
echo "         then copy secrets only for the test day and wipe after."
