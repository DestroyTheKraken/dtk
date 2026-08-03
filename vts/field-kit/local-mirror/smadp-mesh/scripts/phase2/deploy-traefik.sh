#!/usr/bin/env bash
# deploy-traefik.sh — Configure k3s Traefik + smoke-test ingress
#
# Run on um690: sudo bash ~/SovereignAid/scripts/phase2/deploy-traefik.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "${SCRIPT_DIR}/../.." && pwd)"
K8S_INGRESS="${REPO}/k8s/ingress"
MANIFESTS_DIR="/var/lib/rancher/k3s/server/manifests"

log() { echo "[traefik] $*"; }
die() { echo "[traefik] ERROR: $*" >&2; exit 1; }

[[ "$(id -u)" -eq 0 ]] || die "Run with sudo"
[[ "$(hostname -s)" == "um690" ]] || die "Run on um690 only"
[[ -d "${K8S_INGRESS}" ]] || die "Missing ${K8S_INGRESS}"

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

command -v k3s &>/dev/null || die "k3s not installed"
k3s kubectl get nodes | grep -q Ready || die "No Ready nodes"

# Persist HelmChartConfig on disk for k3s auto-reconcile after reinstall
if [[ -w "${MANIFESTS_DIR}" ]] || [[ "$(id -u)" -eq 0 ]]; then
    install -d "${MANIFESTS_DIR}"
    install -m 0644 "${K8S_INGRESS}/helmchartconfig-traefik.yaml" \
        "${MANIFESTS_DIR}/smadp-traefik-config.yaml"
    log "Installed HelmChartConfig → ${MANIFESTS_DIR}/smadp-traefik-config.yaml"
else
    log "WARN: run with sudo once to persist manifest under ${MANIFESTS_DIR}"
fi

k3s kubectl apply -f "${K8S_INGRESS}/helmchartconfig-traefik.yaml"
log "Applied HelmChartConfig (Traefik will reconcile)"

k3s kubectl apply -f "${K8S_INGRESS}/namespace.yaml"
k3s kubectl apply -f "${K8S_INGRESS}/whoami.yaml"
log "Applied ingress namespace + whoami smoke test"

log "Waiting for Traefik rollout..."
k3s kubectl rollout status deployment/traefik -n kube-system --timeout=180s

log "Waiting for whoami..."
k3s kubectl rollout status deployment/whoami -n ingress --timeout=120s

log "Traefik service:"
k3s kubectl get svc traefik -n kube-system
log "IngressClass:"
k3s kubectl get ingressclass
log "Ingress routes:"
k3s kubectl get ingress -A