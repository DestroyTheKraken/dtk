#!/usr/bin/env bash
# deploy-longhorn.sh — Install Longhorn via Helm on um690
#
# Run on um690: sudo bash deploy-longhorn.sh
# Verify: kubectl get pods -n longhorn-system

set -euo pipefail

log() { echo "[longhorn] $*"; }
die() { echo "[longhorn] ERROR: $*" >&2; exit 1; }

[[ "$(id -u)" -eq 0 ]] || die "Run with sudo"
[[ "$(hostname -s)" == "um690" ]] || die "Run on um690 only"

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

command -v k3s &>/dev/null || die "k3s not installed"
k3s kubectl get nodes | grep -q Ready || die "No Ready nodes — install k3s first"

# Secondary disk path on um690 (NAS — create dir only, never delete existing data)
SECONDARY="/mnt/systems_admin/longhorn"
if mountpoint -q /mnt/systems_admin; then
    install -d -m 0755 "${SECONDARY}"
    log "Secondary Longhorn path ready: ${SECONDARY}"
else
    log "WARN: /mnt/systems_admin not mounted — skipping secondary path"
fi

# Helm
if ! command -v helm &>/dev/null; then
    log "Installing Helm..."
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

helm repo add longhorn https://charts.longhorn.io 2>/dev/null || true
helm repo update

if helm list -n longhorn-system 2>/dev/null | grep -q longhorn; then
    log "Longhorn already installed"
else
    log "Installing Longhorn..."
    helm install longhorn longhorn/longhorn \
        --namespace longhorn-system \
        --create-namespace \
        --set defaultSettings.defaultReplicaCount=2 \
        --set defaultSettings.storageMinimalAvailablePercentage=10 \
        --wait --timeout 10m
fi

log "Longhorn pods:"
k3s kubectl get pods -n longhorn-system

log "Nodes:"
k3s kubectl get nodes -o wide