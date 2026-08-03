#!/usr/bin/env bash
# deploy-delegation.sh — Install delegation watcher on all SMADP nodes
#
# Run from um690: sudo bash ~/SovereignAid/scripts/phase3/deploy-delegation.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PHASE0_DIR="${REPO}/scripts/phase0"
SSH_WORKER="${PHASE0_DIR}/ssh-worker.sh"
DELEGATION_SCRIPTS="${REPO}/scripts/delegation"
SYSTEMD_UNIT="${REPO}/systemd/sovereign-delegation-watcher.service"
BIN_DIR="/opt/sovereign/bin"
UNIT_PATH="/etc/systemd/system/sovereign-delegation-watcher.service"

log() { echo "[deploy-delegation] $*"; }
die() { echo "[deploy-delegation] ERROR: $*" >&2; exit 1; }

[[ "$(id -u)" -eq 0 ]] || die "Run with: sudo bash $0"
[[ "$(hostname -s)" == "um690" ]] || die "Run from um690"
[[ -d "${DELEGATION_SCRIPTS}" ]] || die "Missing ${DELEGATION_SCRIPTS}"

OWNER="${SUDO_USER:-kraken}"

local_install() {
    local node=$1
    log "Local install on ${node}"

    apt-get install -y jq >/dev/null 2>&1 || true
    command -v jq &>/dev/null || die "jq not installed on ${node}"

    DELEGATION_OWNER="${OWNER}" bash "${REPO}/scripts/phase0/setup-delegation-dirs.sh"

    install -d -m 0755 "${BIN_DIR}"
    install -m 0755 "${DELEGATION_SCRIPTS}/processor.sh" "${BIN_DIR}/delegation-processor.sh"
    sed "s|\${SCRIPT_DIR}/processor.sh|${BIN_DIR}/delegation-processor.sh|" \
        "${DELEGATION_SCRIPTS}/watcher.sh" > "${BIN_DIR}/delegation-watcher.sh"
    chmod 0755 "${BIN_DIR}/delegation-watcher.sh"

    install -m 0644 "${SYSTEMD_UNIT}" "${UNIT_PATH}"
    systemctl daemon-reload
    systemctl enable sovereign-delegation-watcher.service
    systemctl restart sovereign-delegation-watcher.service
    systemctl is-active --quiet sovereign-delegation-watcher.service \
        || die "watcher not active on ${node}"
    log "  ${node}: sovereign-delegation-watcher active"
}

remote_install() {
    local worker=$1
    local host
    host=$(sudo -u "${OWNER}" -H bash "${SSH_WORKER}" "${worker}" resolve) \
        || die "Cannot SSH to ${worker}"

    log "Deploying to ${worker} (${host})"

    sudo -u "${OWNER}" -H ssh -o BatchMode=yes -o ConnectTimeout=20 "kraken@${host}" \
        "mkdir -p ~/SovereignAid/scripts/delegation ~/SovereignAid/scripts/phase0 ~/SovereignAid/systemd"

    sudo -u "${OWNER}" -H scp -o BatchMode=yes \
        "${DELEGATION_SCRIPTS}/"*.sh \
        "kraken@${host}:~/SovereignAid/scripts/delegation/"
    sudo -u "${OWNER}" -H scp -o BatchMode=yes \
        "${REPO}/scripts/phase0/setup-delegation-dirs.sh" \
        "kraken@${host}:~/SovereignAid/scripts/phase0/"
    sudo -u "${OWNER}" -H scp -o BatchMode=yes \
        "${SYSTEMD_UNIT}" \
        "kraken@${host}:~/SovereignAid/systemd/"

    sudo -u "${OWNER}" -H ssh -o BatchMode=yes "kraken@${host}" \
        'chmod +x ~/SovereignAid/scripts/delegation/*.sh ~/SovereignAid/scripts/phase0/setup-delegation-dirs.sh'

    sudo -u "${OWNER}" -H ssh -o BatchMode=yes -t "kraken@${host}" \
        "sudo DELEGATION_REPO=~/SovereignAid bash -s" <<'REMOTE'
set -euo pipefail
REPO="${DELEGATION_REPO:-$HOME/SovereignAid}"
BIN_DIR="/opt/sovereign/bin"
UNIT_PATH="/etc/systemd/system/sovereign-delegation-watcher.service"

apt-get install -y jq >/dev/null 2>&1 || true
command -v jq >/dev/null || { echo "jq install failed"; exit 1; }

sudo DELEGATION_OWNER=kraken bash "${REPO}/scripts/phase0/setup-delegation-dirs.sh"

sudo install -d -m 0755 "${BIN_DIR}"
sudo install -m 0755 "${REPO}/scripts/delegation/processor.sh" "${BIN_DIR}/delegation-processor.sh"
sed "s|\${SCRIPT_DIR}/processor.sh|${BIN_DIR}/delegation-processor.sh|" \
    "${REPO}/scripts/delegation/watcher.sh" | sudo tee "${BIN_DIR}/delegation-watcher.sh" >/dev/null
sudo chmod 0755 "${BIN_DIR}/delegation-watcher.sh"

sudo install -m 0644 "${REPO}/systemd/sovereign-delegation-watcher.service" "${UNIT_PATH}"
sudo systemctl daemon-reload
sudo systemctl enable sovereign-delegation-watcher.service
sudo systemctl restart sovereign-delegation-watcher.service
sudo systemctl is-active --quiet sovereign-delegation-watcher.service
REMOTE

    log "  ${worker}: sovereign-delegation-watcher active"
}

log "=== Phase 3: Delegation deploy ==="
local_install "$(hostname -s)"
remote_install node1
remote_install node2

log "Done. Verify: bash ~/SovereignAid/scripts/phase3/verify-phase3-delegation.sh"