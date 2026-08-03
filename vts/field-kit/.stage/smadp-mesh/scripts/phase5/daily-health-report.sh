#!/usr/bin/env bash
# daily-health-report.sh — 8am cluster health report → BTRFS + Nextcloud /reports/
#
# Run on um690: bash ~/SovereignAid/scripts/phase5/daily-health-report.sh

set -euo pipefail

REPORT_DIR="/mnt/systems_admin/reports"
NC_REPORTS="reports"
DATE=$(date +%Y-%m-%d)
REPORT_FILE="${REPORT_DIR}/smadp-health-${DATE}.md"
HOST="um690.taile52ad9.ts.net"

log() { echo "[health-report $(date -Iseconds)] $*"; }

[[ "$(hostname -s)" == "um690" ]] || { log "ERROR: run on um690"; exit 1; }

export KUBECONFIG="${KUBECONFIG:-${HOME}/.kube/config}"
[[ -r "${KUBECONFIG}" ]] || KUBECONFIG=/etc/rancher/k3s/k3s.yaml

install -d "${REPORT_DIR}"

{
    echo "# SMADP Daily Health Report"
    echo ""
    echo "**Date:** $(date -Iseconds)"
    echo "**Host:** $(hostname -s)"
    echo ""
    echo "## Cluster nodes"
    echo '```'
    kubectl get nodes -o wide 2>/dev/null || echo "(kubectl unavailable)"
    echo '```'
    echo ""
    echo "## Problem pods"
    echo '```'
    kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded 2>/dev/null \
        | grep -v '^$' || echo "(none)"
    echo '```'
    echo ""
    echo "## Ingress"
    echo '```'
    kubectl get ingress -A 2>/dev/null || true
    echo '```'
    echo ""
    echo "## Key URLs"
    echo "- Nextcloud: https://${HOST}/"
    echo "- Valley Tech: https://${HOST}/vts/"
    echo "- Traefik dashboard: https://${HOST}/dashboard/"
    echo ""
    echo "## Delegation queue (um690)"
    for d in incoming processing completed failed; do
        c=$(find "/opt/sovereign/delegation/${d}" -maxdepth 1 -name '*.json' 2>/dev/null | wc -l)
        echo "- ${d}: ${c} task(s)"
    done
    echo ""
    echo "## Backup (restic)"
    RESTIC_ENV="${HOME}/.config/sovereign/restic.env"
    if [[ -f "${RESTIC_ENV}" ]]; then
        # shellcheck disable=SC1090
        source "${RESTIC_ENV}"
        if restic snapshots --latest 1 2>/dev/null; then
            true
        else
            echo "(restic not configured or repo unavailable)"
        fi
    else
        echo "(restic.env missing — run init-restic-repo.sh)"
    fi
    echo ""
    echo "## Disk (um690)"
    echo '```'
    df -h / /mnt/systems_admin 2>/dev/null || df -h /
    echo '```'
} > "${REPORT_FILE}"

log "Wrote ${REPORT_FILE}"

# Copy to Nextcloud admin files/reports/
POD=$(kubectl get pods -n nextcloud -l app.kubernetes.io/name=nextcloud -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
if [[ -n "${POD}" ]]; then
    kubectl exec -n nextcloud "${POD}" -- mkdir -p "/var/www/html/data/admin/files/${NC_REPORTS}" 2>/dev/null || true
    kubectl cp "${REPORT_FILE}" "nextcloud/${POD}:/var/www/html/data/admin/files/${NC_REPORTS}/$(basename "${REPORT_FILE}")" 2>/dev/null && \
        kubectl exec -n nextcloud "${POD}" -- chown www-data:www-data \
            "/var/www/html/data/admin/files/${NC_REPORTS}/$(basename "${REPORT_FILE}")" 2>/dev/null && \
        kubectl exec -n nextcloud "${POD}" -- su -s /bin/bash www-data -c \
            "php occ files:scan --path='admin/files/${NC_REPORTS}'" 2>/dev/null || true
    log "Uploaded to Nextcloud /${NC_REPORTS}/"
else
    log "WARN: Nextcloud pod not found — report only on BTRFS"
fi

log "Done"