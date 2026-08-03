#!/usr/bin/env bash
# configure-magicdns-ingress.sh — Point all ingress at Tailscale MagicDNS names
#
# MagicDNS only resolves {machine}.{tailnet} — NOT service subdomains.
# Run on um690: bash ~/SovereignAid/scripts/phase2/configure-magicdns-ingress.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SECRET_DIR="${HOME}/.config/sovereign"
ENV_FILE="${SECRET_DIR}/nextcloud.env"
CONTROL_HOST="um690.taile52ad9.ts.net"

log() { echo "[magicdns] $*"; }
die() { echo "[magicdns] ERROR: $*" >&2; exit 1; }

[[ "$(hostname -s)" == "um690" ]] || die "Run on um690"

if [[ -r "${HOME}/.kube/config" ]]; then
    export KUBECONFIG="${HOME}/.kube/config"
elif [[ -r /etc/rancher/k3s/k3s.yaml ]]; then
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
else
    die "kubeconfig not found"
fi

# DNS sanity
if ! getent hosts "${CONTROL_HOST}" &>/dev/null; then
    die "${CONTROL_HOST} does not resolve — enable MagicDNS in Tailscale admin"
fi
log "MagicDNS OK: ${CONTROL_HOST} → $(getent hosts "${CONTROL_HOST}" | awk '{print $1}')"

kubectl apply -f "${REPO}/k8s/ingress/helmchartconfig-traefik.yaml"
kubectl apply -f "${REPO}/k8s/ingress/whoami.yaml"

if [[ -f "${ENV_FILE}" ]]; then
    # shellcheck disable=SC1090
    source "${ENV_FILE}"
    SECRET_VALUES=$(mktemp)
    trap 'rm -f "${SECRET_VALUES}"' EXIT
    cat > "${SECRET_VALUES}" << EOF
mariadb:
  auth:
    rootPassword: "${MARIADB_ROOT_PASSWORD}"
    password: "${MARIADB_PASSWORD}"
    replicationPassword: "${MARIADB_REPLICATION_PASSWORD:-${MARIADB_PASSWORD}}"
EOF
    helm repo add nextcloud https://nextcloud.github.io/helm/ 2>/dev/null || true
    helm repo update nextcloud
    helm upgrade nextcloud nextcloud/nextcloud \
        --namespace nextcloud \
        --values "${REPO}/k8s/nextcloud/values.yaml" \
        --values "${SECRET_VALUES}" \
        --wait --timeout 10m
    kubectl create secret generic nextcloud-db \
        --namespace=nextcloud \
        --from-literal=db-username=nextcloud \
        --from-literal=db-password="${MARIADB_PASSWORD}" \
        --dry-run=client -o yaml | kubectl apply -f -
else
    log "WARN: ${ENV_FILE} missing — apply nextcloud values only via helm manually"
fi

kubectl rollout status deployment/nextcloud -n nextcloud --timeout=300s
kubectl rollout status deployment/traefik -n kube-system --timeout=120s

# Live trusted_domains update (helm configmap may not re-run install hooks)
POD=$(kubectl get pods -n nextcloud -l app.kubernetes.io/name=nextcloud -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n nextcloud "${POD}" -- su -s /bin/bash www-data -c \
    "php occ config:system:set trusted_domains 1 --value='${CONTROL_HOST}'" 2>/dev/null || true
kubectl exec -n nextcloud "${POD}" -- su -s /bin/bash www-data -c \
    "php occ config:system:set overwritehost --value='${CONTROL_HOST}'" 2>/dev/null || true
kubectl exec -n nextcloud "${POD}" -- su -s /bin/bash www-data -c \
    "php occ config:system:set overwrite.cli.url --value='http://${CONTROL_HOST}'" 2>/dev/null || true
kubectl exec -n nextcloud "${POD}" -- su -s /bin/bash www-data -c \
    "php occ config:system:set overwriteprotocol --value='http'" 2>/dev/null || true

log "Ingress hosts:"
kubectl get ingress -A -o custom-columns='NS:.metadata.namespace,NAME:.metadata.name,HOST:.spec.rules[0].host,PATH:.spec.rules[0].http.paths[0].path'

CODE=$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 5 "http://${CONTROL_HOST}/login")
log "Nextcloud http://${CONTROL_HOST}/login → HTTP ${CODE}"
[[ "${CODE}" =~ ^(200|302)$ ]] || die "Nextcloud not reachable on MagicDNS host"

echo ""
log "Android / tablet Nextcloud app URL:"
echo "  http://${CONTROL_HOST}"