#!/usr/bin/env bash
# fix-delegation-permissions.sh — Ensure delegation queue dirs owned by kraken (writable for create-task)
#
# Run from um690: sudo bash ~/SovereignAid/scripts/phase3/fix-delegation-permissions.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PHASE0_DIR="${REPO}/scripts/phase0"
SSH_WORKER="${PHASE0_DIR}/ssh-worker.sh"
SETUP="${REPO}/scripts/phase0/setup-delegation-dirs.sh"
OWNER="${SUDO_USER:-kraken}"

[[ "$(id -u)" -eq 0 ]] || { echo "Run with: sudo bash $0" >&2; exit 1; }
[[ "$(hostname -s)" == "um690" ]] || { echo "Run from um690" >&2; exit 1; }

fix_local() {
    DELEGATION_OWNER="${OWNER}" bash "${SETUP}"
}

fix_remote() {
    local worker=$1
    local host
    host=$(sudo -u "${OWNER}" -H bash "${SSH_WORKER}" "${worker}" resolve)
    sudo -u "${OWNER}" -H ssh -o BatchMode=yes "kraken@${host}" \
        "sudo DELEGATION_OWNER=kraken bash -s" < "${SETUP}"
}

echo "[fix-delegation] Fixing ownership on all nodes..."
fix_local
fix_remote node1
fix_remote node2
echo "[fix-delegation] Done. Verify: bash scripts/phase3/verify-phase3-delegation.sh"