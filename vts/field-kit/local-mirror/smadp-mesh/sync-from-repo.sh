#!/usr/bin/env bash
# sync-from-repo.sh — Refresh aide_installer_pkg from ~/SovereignAid (run after script changes)
#
# Usage: bash ~/SovereignAid/aide_installer_pkg/sync-from-repo.sh

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PKG="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { echo "[aide-sync] $*"; }

copy_tree() {
    local src=$1 dst=$2
    [[ -d "${src}" ]] || return 0
    mkdir -p "${dst}"
    rsync -a --delete "${src}/" "${dst}/"
    log "  ${src#${REPO}/} → ${dst#${PKG}/}"
}

log "Syncing from ${REPO} → ${PKG}"

mkdir -p "${PKG}/scripts" "${PKG}/k8s" "${PKG}/configs" "${PKG}/systemd" "${PKG}/delegation"

# Scripts (phase0–phase3 + network)
for phase in phase0 phase1 phase2 phase3 phase4 phase5 phase6 network delegation; do
    copy_tree "${REPO}/scripts/${phase}" "${PKG}/scripts/${phase}"
done

# Kubernetes manifests
for comp in ingress nextcloud monitoring websites ops-center; do
    copy_tree "${REPO}/k8s/${comp}" "${PKG}/k8s/${comp}"
done

# Network configs (no secrets)
if [[ -d "${REPO}/scripts/network" ]]; then
    mkdir -p "${PKG}/configs/network"
    rsync -a --include='*.conf' --include='*.md' --exclude='*' \
        "${REPO}/scripts/network/" "${PKG}/configs/network/" 2>/dev/null || true
    [[ -f "${REPO}/scripts/network/router" ]] && \
        install -m 0755 "${REPO}/scripts/network/router" "${PKG}/configs/network/router"
fi

# Delegation templates
copy_tree "${REPO}/delegation/templates" "${PKG}/delegation/templates"
copy_tree "${REPO}/scripts/backup" "${PKG}/scripts/backup"

# Systemd units shipped with repo
copy_tree "${REPO}/systemd" "${PKG}/systemd"

# User guide + key vault docs
copy_tree "${REPO}/user-guide" "${PKG}/user-guide"
mkdir -p "${PKG}/phases"
for doc in README.md Build-Complete.md Service-Credentials.md Phase-6-User-Experience.md Phase-5-Operations.md Valley-Tech-Website-Quickstart.md; do
    [[ -f "${REPO}/phases/${doc}" ]] && install -m 0644 "${REPO}/phases/${doc}" "${PKG}/phases/${doc}"
done
mkdir -p "${PKG}/specs"
install -m 0644 "${REPO}/DESIGN.md" "${PKG}/DESIGN.md"
install -m 0644 "${REPO}/specs/cluster.md" "${PKG}/specs/cluster.md"

# Installer docs (preserve local INSTALL.md if only syncing scripts — overwrite manifest)
MANIFEST="${PKG}/MANIFEST.txt"
{
    echo "# SMADP aide_installer_pkg — $(date -Iseconds)"
    find "${PKG}" -type f ! -path '*/sync-from-repo.sh' ! -name 'MANIFEST.txt' | sort
} > "${MANIFEST}"

log "Done. $(find "${PKG}" -type f | wc -l) files. See MANIFEST.txt"