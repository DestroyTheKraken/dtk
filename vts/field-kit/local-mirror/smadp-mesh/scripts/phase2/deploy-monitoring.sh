#!/usr/bin/env bash
# deploy-monitoring.sh — Basic health collector (DESIGN Phase 2)
#
# Run on um690: bash ~/SovereignAid/scripts/phase2/deploy-monitoring.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "${SCRIPT_DIR}/../.." && pwd)"
K8S_MON="${REPO}/k8s/monitoring"
NAMESPACE="monitoring"

log() { echo "[monitoring] $*"; }
die() { echo "[monitoring] ERROR: $*" >&2; exit 1; }

[[ "$(hostname -s)" == "um690" ]] || die "Run on um690"

if [[ -r "${HOME}/.kube/config" ]]; then
    export KUBECONFIG="${HOME}/.kube/config"
elif [[ -r /etc/rancher/k3s/k3s.yaml ]]; then
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
else
    die "kubeconfig not found"
fi

kubectl get nodes | grep -q Ready || die "No Ready nodes"

kubectl get namespace "${NAMESPACE}" &>/dev/null \
    || kubectl create namespace "${NAMESPACE}"

log "Applying RBAC + collector manifests..."
kubectl apply -f "${K8S_MON}/rbac.yaml"
kubectl apply -f "${K8S_MON}/configmap.yaml"
kubectl apply -f "${K8S_MON}/deployment.yaml"
kubectl apply -f "${K8S_MON}/cronjob.yaml"

log "Waiting for health-collector deployment..."
kubectl rollout status deployment/health-collector -n "${NAMESPACE}" --timeout=120s

log "Monitoring deployed"
kubectl get pods,cronjob -n "${NAMESPACE}"