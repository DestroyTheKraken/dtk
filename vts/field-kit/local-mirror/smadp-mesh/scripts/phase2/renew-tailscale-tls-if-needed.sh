#!/usr/bin/env bash
# renew-tailscale-tls-if-needed.sh — Renew Tailscale TLS secret when <=30 days remain
#
# Run on um690 (root cron): sudo bash ~/SovereignAid/scripts/phase2/renew-tailscale-tls-if-needed.sh
# Installed by: sudo bash ~/SovereignAid/scripts/phase2/install-tailscale-tls-cron.sh

set -euo pipefail

HOST="um690.taile52ad9.ts.net"
NS="nextcloud"
SECRET="nextcloud-tailscale-tls"
CERT_DIR="/var/lib/smadp/tailscale-certs"
CERT_FILE="${CERT_DIR}/${HOST}.crt"
THRESHOLD_DAYS="${TLS_RENEW_THRESHOLD_DAYS:-30}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { echo "[tls-renew $(date -Iseconds)] $*"; }

[[ "$(hostname -s)" == "um690" ]] || { log "ERROR: run on um690"; exit 1; }

if [[ -r /etc/rancher/k3s/k3s.yaml ]]; then
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
elif [[ -r "${HOME}/.kube/config" ]]; then
    export KUBECONFIG="${HOME}/.kube/config"
fi

cert_pem() {
    if [[ -f "${CERT_FILE}" ]]; then
        cat "${CERT_FILE}"
        return 0
    fi
    if command -v kubectl &>/dev/null \
        && kubectl get secret "${SECRET}" -n "${NS}" &>/dev/null; then
        kubectl get secret "${SECRET}" -n "${NS}" \
            -o jsonpath='{.data.tls\.crt}' | base64 -d
        return 0
    fi
    echo | openssl s_client -connect "${HOST}:443" -servername "${HOST}" 2>/dev/null
}

end_epoch() {
    cert_pem | openssl x509 -noout -enddate 2>/dev/null \
        | sed 's/notAfter=//' | xargs -I{} date -d "{}" +%s
}

now_epoch=$(date +%s)
end=$(end_epoch) || { log "ERROR: cannot read certificate expiry"; exit 1; }
days_left=$(( (end - now_epoch) / 86400 ))

log "Certificate expires in ${days_left} day(s) (threshold: ${THRESHOLD_DAYS})"

if (( days_left > THRESHOLD_DAYS )); then
    log "No renewal needed"
    exit 0
fi

log "Renewing certificate (<= ${THRESHOLD_DAYS} days remaining)"
if [[ "$(id -u)" -eq 0 ]]; then
    bash "${SCRIPT_DIR}/sync-tailscale-tls-secret.sh"
else
    sudo bash "${SCRIPT_DIR}/sync-tailscale-tls-secret.sh"
fi

new_end=$(end_epoch)
new_days=$(( (new_end - now_epoch) / 86400 ))
log "Renewal complete — new expiry in ${new_days} day(s)"