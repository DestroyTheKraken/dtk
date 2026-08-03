#!/usr/bin/env bash
# deploy-ops-center.sh — Deploy SMADP Ops Command Center + Longhorn ingress
#
# Run on um690: bash ~/SovereignAid/scripts/phase6/deploy-ops-center.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "${SCRIPT_DIR}/../.." && pwd)"
STATIC="${REPO}/k8s/ops-center/static"
K8S="${REPO}/k8s/ops-center/k8s"
NAMESPACE="ops-center"
HOST="um690.taile52ad9.ts.net"

log() { echo "[deploy-ops] $*"; }
die() { echo "[deploy-ops] ERROR: $*" >&2; exit 1; }

[[ "$(hostname -s)" == "um690" ]] || die "Run on um690"
[[ -d "${STATIC}" ]] || die "Missing ${STATIC}"

if [[ -r "${HOME}/.kube/config" ]]; then
    export KUBECONFIG="${HOME}/.kube/config"
elif [[ -r /etc/rancher/k3s/k3s.yaml ]]; then
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
else
    die "kubeconfig not found"
fi

kubectl get namespace "${NAMESPACE}" &>/dev/null || kubectl create namespace "${NAMESPACE}"

log "Updating ConfigMap ops-center-static..."
kubectl delete configmap ops-center-static -n "${NAMESPACE}" --ignore-not-found
# kubectl --from-file=dir skips subdirs — include css/ explicitly
kubectl create configmap ops-center-static -n "${NAMESPACE}" \
    --from-file="${STATIC}/index.html" \
    --from-file="${STATIC}/bookmarks.html" \
    --from-file="${STATIC}/smadp-bookmarks.html" \
    --from-file="${STATIC}/main.css" \
    --from-file="${STATIC}/sw.js" \
    --from-file="${STATIC}/manifest.webmanifest" \
    --from-file="${STATIC}/icon.svg"

kubectl apply -f "${K8S}/middleware.yaml"
kubectl apply -f "${K8S}/deployment.yaml"
kubectl apply -f "${K8S}/ingress.yaml"
kubectl apply -f "${K8S}/longhorn-ingress.yaml"

log "Waiting for rollout..."
kubectl rollout status deployment/ops-center -n "${NAMESPACE}" --timeout=120s

CODE=$(curl -sk -o /dev/null -w '%{http_code}' --connect-timeout 10 "https://${HOST}/ops/")
LH=$(curl -sk -o /dev/null -w '%{http_code}' --connect-timeout 10 "https://${HOST}/longhorn/")
log "https://${HOST}/ops/ → HTTP ${CODE}"
log "https://${HOST}/longhorn/ → HTTP ${LH}"

echo ""
log "Ops Command Center: https://${HOST}/ops/"
log "PWA guide: ~/SovereignAid/user-guide/Firefox-PWA-Setup.md"
log "Verify: bash ~/SovereignAid/scripts/phase6/verify-phase6.sh"