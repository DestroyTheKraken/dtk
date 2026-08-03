#!/usr/bin/env bash
# run-smadp-backup.sh — SMADP config + k3s snapshot backup via restic
#
# Run on um690: bash ~/SovereignAid/scripts/backup/run-smadp-backup.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAGING="/mnt/systems_admin/restic/staging"
ENV_FILE="${SOVEREIGN_RESTIC_ENV:-${HOME}/.config/sovereign/restic.env}"
STAMP=$(date +%Y%m%d-%H%M%S)
WORKDIR="${STAGING}/${STAMP}"

log() { echo "[smadp-backup $(date -Iseconds)] $*"; }
die() { echo "[smadp-backup] ERROR: $*" >&2; exit 1; }

[[ "$(hostname -s)" == "um690" ]] || die "Run on um690"
[[ -f "${ENV_FILE}" ]] || die "Run init-restic-repo.sh first"
mountpoint -q /mnt/systems_admin || die "/mnt/systems_admin not mounted"

# shellcheck disable=SC1090
source "${ENV_FILE}"
command -v restic &>/dev/null || die "restic not installed"

if [[ ! -w "${STAGING}" ]] 2>/dev/null || [[ ! -r "${RESTIC_REPOSITORY:-}" ]] 2>/dev/null; then
    die "restic paths not writable — run: sudo bash scripts/backup/fix-restic-permissions.sh"
fi

export KUBECONFIG="${KUBECONFIG:-${HOME}/.kube/config}"
[[ -r "${KUBECONFIG}" ]] || KUBECONFIG=/etc/rancher/k3s/k3s.yaml

rm -rf "${WORKDIR}"
install -d "${WORKDIR}"/{sovereignaid,k3s,manifests}

log "Staging SovereignAid repo (no secrets, no hugo public/)..."
tar -C "${HOME}" -cf "${WORKDIR}/sovereignaid/repo.tar" \
    --exclude='SovereignAid/k8s/websites/*/public' \
    --exclude='SovereignAid/.git' \
    --exclude='SovereignAid/**/node_modules' \
    SovereignAid 2>/dev/null || \
    tar -C "${HOME}" -cf "${WORKDIR}/sovereignaid/repo.tar" SovereignAid

if [[ -d /etc/rancher/k3s ]]; then
    log "Staging k3s config..."
    sudo tar -cf "${WORKDIR}/k3s/etc-rancher-k3s.tar" -C / etc/rancher/k3s 2>/dev/null || true
fi

if command -v k3s &>/dev/null; then
    log "k3s etcd snapshot..."
    sudo k3s etcd-snapshot save -name "smadp-${STAMP}" 2>/dev/null || \
        log "WARN: etcd-snapshot skipped (may need sudo)"
    if [[ -d /var/lib/rancher/k3s/server/db/snapshots ]]; then
        sudo cp -a /var/lib/rancher/k3s/server/db/snapshots/. "${WORKDIR}/k3s/" 2>/dev/null || true
    fi
fi

if command -v kubectl &>/dev/null; then
    log "Exporting cluster manifests..."
    kubectl get all,ingress,pvc,configmap,secret -A -o yaml > "${WORKDIR}/manifests/cluster-export.yaml" 2>/dev/null || true
fi

log "restic backup..."
restic backup "${WORKDIR}" --tag smadp --tag "host-$(hostname -s)" --tag "${STAMP}"
restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune

rm -rf "${WORKDIR}"
log "Latest snapshots:"
restic snapshots --latest 3
log "Backup complete"