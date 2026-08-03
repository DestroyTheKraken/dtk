#!/usr/bin/env bash
# install-k3s-server.sh — k3s control plane on um690
#
# Run on um690: sudo bash install-k3s-server.sh
# Verify: kubectl get nodes

set -euo pipefail

log() { echo "[k3s-server] $*"; }
die() { echo "[k3s-server] ERROR: $*" >&2; exit 1; }

[[ "$(id -u)" -eq 0 ]] || die "Run with sudo"
[[ "$(hostname -s)" == "um690" ]] || die "Run on um690 only"

LAN_IP="192.168.20.100"
TS_IP="100.120.232.39"
TS_DNS="um690.taile52ad9.ts.net"

if command -v k3s &>/dev/null; then
    log "k3s already installed: $(k3s --version)"
    exit 0
fi

log "Installing k3s server on um690 (LAN ${LAN_IP})"

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server \
    --write-kubeconfig-mode 644 \
    --node-ip ${LAN_IP} \
    --advertise-address ${LAN_IP} \
    --tls-san ${TS_DNS} \
    --tls-san ${TS_IP} \
    --tls-san ${LAN_IP} \
    --flannel-iface eno1" sh -

# kubeconfig for invoking user
OWNER="${SUDO_USER:-kraken}"
OWNER_HOME=$(getent passwd "${OWNER}" | cut -d: -f6)
install -d -m 0700 -o "${OWNER}" -g "${OWNER}" "${OWNER_HOME}/.kube"
cp /etc/rancher/k3s/k3s.yaml "${OWNER_HOME}/.kube/config"
chown "${OWNER}:${OWNER}" "${OWNER_HOME}/.kube/config"
chmod 600 "${OWNER_HOME}/.kube/config"

log "k3s server ready"
k3s kubectl get nodes
log "Join token: /var/lib/rancher/k3s/server/node-token"