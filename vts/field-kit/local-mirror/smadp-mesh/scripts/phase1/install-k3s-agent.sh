#!/usr/bin/env bash
# install-k3s-agent.sh — Join worker node to um690 k3s cluster
#
# Run on worker: sudo bash install-k3s-agent.sh
# Requires: K3S_TOKEN env or /opt/sovereign/k3s/node-token on um690 (copied here)

set -euo pipefail

log() { echo "[k3s-agent] $*"; }
die() { echo "[k3s-agent] ERROR: $*" >&2; exit 1; }

[[ "$(id -u)" -eq 0 ]] || die "Run with sudo"

HOSTNAME=$(hostname -s)
case "${HOSTNAME}" in
    node1) NODE_IP="192.168.20.101" ;;
    node2) NODE_IP="192.168.20.102" ;;
    *) die "Unknown worker hostname: ${HOSTNAME}" ;;
esac

K3S_URL="${K3S_URL:-https://192.168.20.100:6443}"
TOKEN_FILE="/opt/sovereign/k3s/node-token"

if [[ -z "${K3S_TOKEN:-}" ]]; then
    [[ -f "${TOKEN_FILE}" ]] || die "K3S_TOKEN not set and ${TOKEN_FILE} missing"
    K3S_TOKEN=$(<"${TOKEN_FILE}")
fi

if command -v k3s &>/dev/null; then
    log "k3s agent already installed on ${HOSTNAME}"
    exit 0
fi

log "Joining ${HOSTNAME} (${NODE_IP}) to ${K3S_URL}"

curl -sfL https://get.k3s.io | \
    K3S_URL="${K3S_URL}" \
    K3S_TOKEN="${K3S_TOKEN}" \
    INSTALL_K3S_EXEC="agent --node-ip ${NODE_IP} --flannel-iface eno1" sh -

log "k3s agent installed on ${HOSTNAME}"