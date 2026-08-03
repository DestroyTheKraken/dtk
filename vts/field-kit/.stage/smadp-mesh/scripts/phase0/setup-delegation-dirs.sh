#!/usr/bin/env bash
# setup-delegation-dirs.sh — Create host-level delegation queue on all SMADP nodes
#
# Run on EACH node: sudo bash setup-delegation-dirs.sh
# Verify: ls -la /opt/sovereign/delegation/

set -euo pipefail

log() { echo "[setup-delegation] $*"; }
die() { echo "[setup-delegation] ERROR: $*" >&2; exit 1; }

[[ "$(id -u)" -eq 0 ]] || die "Run with sudo"

BASE="/opt/sovereign/delegation"

# DELEGATION_OWNER overrides; nested sudo (ssh → sudo bash) often leaves SUDO_USER=root
if [[ -n "${DELEGATION_OWNER:-}" ]]; then
    OWNER="${DELEGATION_OWNER}"
elif [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    OWNER="${SUDO_USER}"
elif id kraken &>/dev/null; then
    OWNER=kraken
else
    OWNER="${SUDO_USER:-root}"
fi

log "Creating delegation dirs at ${BASE} (owner: ${OWNER})"

install -d -m 0755 -o root -g root /opt/sovereign

for subdir in incoming processing completed failed; do
    install -d -m 0775 -o "${OWNER}" -g "${OWNER}" "${BASE}/${subdir}"
    log "  ${BASE}/${subdir}"
done

log "Done. Verify: ls -la ${BASE}/"