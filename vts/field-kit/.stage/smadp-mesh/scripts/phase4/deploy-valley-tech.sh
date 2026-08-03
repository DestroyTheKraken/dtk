#!/usr/bin/env bash
# deploy-valley-tech.sh — Build + deploy Valley Tech Support to k8s
#
# Run on um690: bash ~/SovereignAid/scripts/phase4/deploy-valley-tech.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SITE="${REPO}/k8s/websites/valley-tech-support"
K8S="${SITE}/k8s"
NAMESPACE="websites"
CM_STATIC="valley-tech-static"

log() { echo "[deploy-vts] $*"; }
die() { echo "[deploy-vts] ERROR: $*" >&2; exit 1; }

[[ "$(hostname -s)" == "um690" ]] || die "Run on um690"

if [[ -r "${HOME}/.kube/config" ]]; then
    export KUBECONFIG="${HOME}/.kube/config"
elif [[ -r /etc/rancher/k3s/k3s.yaml ]]; then
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
else
    die "kubeconfig not found"
fi

bash "${SCRIPT_DIR}/build-valley-tech.sh"

[[ -d "${SITE}/public" ]] || die "Run build first"

kubectl get namespace "${NAMESPACE}" &>/dev/null || kubectl create namespace "${NAMESPACE}"

log "Updating ConfigMap ${CM_STATIC} from public/..."
kubectl delete configmap "${CM_STATIC}" -n "${NAMESPACE}" --ignore-not-found
kubectl create configmap "${CM_STATIC}" -n "${NAMESPACE}" \
    --from-file="${SITE}/public"

kubectl apply -f "${K8S}/middleware.yaml"
kubectl apply -f "${K8S}/deployment.yaml"
kubectl apply -f "${K8S}/ingress.yaml"

log "Waiting for rollout..."
kubectl rollout status deployment/valley-tech-support -n "${NAMESPACE}" --timeout=120s

HOST="um690.taile52ad9.ts.net"
CODE=$(curl -sk -o /dev/null -w '%{http_code}' --connect-timeout 10 "https://${HOST}/vts/")
log "https://${HOST}/vts/ → HTTP ${CODE}"

echo ""
log "Site URL: https://${HOST}/vts/"
log "Verify: bash ~/SovereignAid/scripts/phase4/verify-phase4-valley-tech.sh"