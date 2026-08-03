#!/usr/bin/env bash
# deploy-nextcloud.sh — Nextcloud + MariaDB behind Traefik (Longhorn PVCs)
#
# Run on um690:
#   bash ~/SovereignAid/scripts/phase2/deploy-nextcloud.sh
# Or: sudo bash ... (optional — works as kraken with kubeconfig)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "${SCRIPT_DIR}/../.." && pwd)"
K8S_NC="${REPO}/k8s/nextcloud"
SECRET_DIR="${HOME}/.config/sovereign"
ENV_FILE="${SECRET_DIR}/nextcloud.env"
RELEASE="nextcloud"
NAMESPACE="nextcloud"
CHART="nextcloud/nextcloud"

log() { echo "[nextcloud] $*"; }
die() { echo "[nextcloud] ERROR: $*" >&2; exit 1; }

[[ "$(hostname -s)" == "um690" ]] || die "Run on um690"

if [[ -r "${HOME}/.kube/config" ]]; then
    export KUBECONFIG="${HOME}/.kube/config"
elif [[ -r /etc/rancher/k3s/k3s.yaml ]]; then
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
else
    die "kubeconfig not found"
fi

kubectl get nodes | grep -q Ready || die "No Ready nodes"
kubectl get storageclass longhorn &>/dev/null || die "Longhorn storageClass missing"
kubectl get ingressclass traefik &>/dev/null || die "Traefik IngressClass missing — run deploy-traefik.sh first"

# Helm
if ! command -v helm &>/dev/null; then
    log "Installing Helm..."
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi
helm repo add nextcloud https://nextcloud.github.io/helm/ 2>/dev/null || true
helm repo update nextcloud

# Secrets (never commit nextcloud.env)
install -d -m 0700 "${SECRET_DIR}"
if [[ ! -f "${ENV_FILE}" ]]; then
    log "Generating credentials → ${ENV_FILE}"
    NC_PASS=$(openssl rand -base64 24)
    DB_ROOT=$(openssl rand -base64 24)
    DB_PASS=$(openssl rand -base64 24)
    cat > "${ENV_FILE}" << EOF
# SovereignAid Nextcloud — generated $(date -Iseconds)
# Admin login for Nextcloud web UI
NEXTCLOUD_ADMIN_USER=admin
NEXTCLOUD_ADMIN_PASSWORD=${NC_PASS}
MARIADB_ROOT_PASSWORD=${DB_ROOT}
MARIADB_PASSWORD=${DB_PASS}
MARIADB_REPLICATION_PASSWORD=${DB_PASS}
EOF
    chmod 0600 "${ENV_FILE}"
    log "SAVE THESE — admin password in ${ENV_FILE}"
else
    log "Using existing ${ENV_FILE}"
fi

# shellcheck disable=SC1090
source "${ENV_FILE}"

kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic nextcloud-secrets \
    --namespace="${NAMESPACE}" \
    --from-literal=nextcloud-username="${NEXTCLOUD_ADMIN_USER:-admin}" \
    --from-literal=nextcloud-password="${NEXTCLOUD_ADMIN_PASSWORD}" \
    --from-literal=mariadb-root-password="${MARIADB_ROOT_PASSWORD}" \
    --from-literal=mariadb-password="${MARIADB_PASSWORD}" \
    --from-literal=mariadb-replication-password="${MARIADB_REPLICATION_PASSWORD:-${MARIADB_PASSWORD}}" \
    --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f "${K8S_NC}/middleware.yaml"

log "Installing Nextcloud Helm chart (may take several minutes)..."
SECRET_VALUES=$(mktemp)
trap 'rm -f "${SECRET_VALUES}"' EXIT
cat > "${SECRET_VALUES}" << EOF
mariadb:
  auth:
    rootPassword: "${MARIADB_ROOT_PASSWORD}"
    password: "${MARIADB_PASSWORD}"
    replicationPassword: "${MARIADB_REPLICATION_PASSWORD:-${MARIADB_PASSWORD}}"
EOF
helm upgrade --install "${RELEASE}" "${CHART}" \
    --namespace "${NAMESPACE}" \
    --values "${K8S_NC}/values.yaml" \
    --values "${SECRET_VALUES}" \
    --wait --timeout 15m

# Ensure init container secret matches MariaDB (chart may default db-password to changeme)
kubectl create secret generic nextcloud-db \
    --namespace="${NAMESPACE}" \
    --from-literal=db-username=nextcloud \
    --from-literal=db-password="${MARIADB_PASSWORD}" \
    --dry-run=client -o yaml | kubectl apply -f -

log "Waiting for Nextcloud deployment..."
kubectl rollout status deployment/"${RELEASE}" -n "${NAMESPACE}" --timeout=600s

log "Pods:"
kubectl get pods -n "${NAMESPACE}" -o wide
log "Ingress:"
kubectl get ingress -n "${NAMESPACE}"
log "PVCs:"
kubectl get pvc -n "${NAMESPACE}"

echo ""
log "Admin user: ${NEXTCLOUD_ADMIN_USER:-admin}"
log "Password file: ${ENV_FILE}"
log "URL: http://nextcloud.um690.taile52ad9.ts.net/"