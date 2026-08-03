#!/usr/bin/env bash
# configure-tailscale-https.sh — Tailscale TLS for Nextcloud via Traefik cert resolver
#
# Prereqs: Tailscale admin → DNS → HTTPS Certificates ENABLED
# Run on um690: bash ~/SovereignAid/scripts/phase2/configure-tailscale-https.sh

set -euo pipefail

SKIP_CERT_SYNC=false
[[ "${1:-}" == "--skip-cert-sync" ]] && SKIP_CERT_SYNC=true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "${SCRIPT_DIR}/../.." && pwd)"
ENV_FILE="${HOME}/.config/sovereign/nextcloud.env"
HOST="um690.taile52ad9.ts.net"

log() { echo "[tailscale-https] $*"; }
die() { echo "[tailscale-https] ERROR: $*" >&2; exit 1; }

[[ "$(hostname -s)" == "um690" ]] || die "Run on um690"
[[ -S /var/run/tailscale/tailscaled.sock ]] || die "tailscaled.sock missing — is Tailscale running?"

if [[ -r "${HOME}/.kube/config" ]]; then
    export KUBECONFIG="${HOME}/.kube/config"
else
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
fi

if ! $SKIP_CERT_SYNC && [[ "$(id -u)" -eq 0 ]]; then
    bash "${SCRIPT_DIR}/sync-tailscale-tls-secret.sh"
fi

log "Applying Traefik + Nextcloud HTTPS config..."
kubectl apply -f "${REPO}/k8s/ingress/helmchartconfig-traefik.yaml"
kubectl apply -f "${REPO}/k8s/nextcloud/middleware.yaml"

log "Waiting for Traefik rollout..."
kubectl rollout status deployment/traefik -n kube-system --timeout=180s

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
fi

kubectl rollout status deployment/nextcloud -n nextcloud --timeout=300s

POD=$(kubectl get pods -n nextcloud -l app.kubernetes.io/name=nextcloud -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n nextcloud "${POD}" -- su -s /bin/bash www-data -c \
    "php occ config:system:set overwriteprotocol --value='https'" 2>/dev/null || true
kubectl exec -n nextcloud "${POD}" -- su -s /bin/bash www-data -c \
    "php occ config:system:set overwrite.cli.url --value='https://${HOST}'" 2>/dev/null || true

log "Waiting for Tailscale certificate (first request triggers ACME)..."
sleep 5
for i in $(seq 1 12); do
    CODE=$(curl -sk -o /dev/null -w '%{http_code}' --connect-timeout 10 "https://${HOST}/login" 2>/dev/null || echo "000")
    ISSUER=$(echo | openssl s_client -connect "${HOST}:443" -servername "${HOST}" 2>/dev/null \
        | openssl x509 -noout -issuer 2>/dev/null || true)
    if [[ "${CODE}" =~ ^(200|302)$ ]] && echo "${ISSUER}" | grep -qi 'lets encrypt'; then
        log "HTTPS OK — issuer: ${ISSUER}"
        break
    fi
    log "  attempt ${i}/12: HTTP ${CODE}, issuer=${ISSUER:-pending}"
    sleep 10
done

CODE=$(curl -sk -o /dev/null -w '%{http_code}' "https://${HOST}/login")
ISSUER=$(echo | openssl s_client -connect "${HOST}:443" -servername "${HOST}" 2>/dev/null \
    | openssl x509 -noout -issuer 2>/dev/null || echo "unknown")

echo ""
log "Nextcloud app URL (phone / tablet):"
echo "  https://${HOST}"
echo "  TLS issuer: ${ISSUER}"
echo "  Login page: HTTP ${CODE}"

[[ "${CODE}" =~ ^(200|302)$ ]] || die "HTTPS not ready — run: sudo bash scripts/phase2/setup-tailscale-https.sh"
if ! echo "${ISSUER}" | grep -qiE 'lets encrypt|let.s encrypt'; then
    die "TLS cert not from Let's Encrypt yet — run: sudo bash scripts/phase2/setup-tailscale-https.sh"
fi