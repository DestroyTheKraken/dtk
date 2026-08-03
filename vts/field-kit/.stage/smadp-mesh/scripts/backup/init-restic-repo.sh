#!/usr/bin/env bash
# init-restic-repo.sh — Initialize encrypted restic repo on BTRFS (Phase 5)
#
# Run on um690: sudo bash ~/SovereignAid/scripts/backup/init-restic-repo.sh

set -euo pipefail

REPO_PATH="/mnt/systems_admin/restic/smadp"
OWNER="${SUDO_USER:-${USER:-kraken}}"
ENV_FILE="/home/${OWNER}/.config/sovereign/restic.env"
RESTIC="${RESTIC_BIN:-restic}"

log() { echo "[restic-init] $*"; }
die() { echo "[restic-init] ERROR: $*" >&2; exit 1; }

[[ "$(hostname -s)" == "um690" ]] || die "Run on um690"
mountpoint -q /mnt/systems_admin || die "/mnt/systems_admin not mounted"

if ! command -v "${RESTIC}" &>/dev/null; then
    log "Installing restic..."
    apt-get update -qq && apt-get install -y restic
fi

install -d -m 0700 -o "${OWNER}" -g "${OWNER}" "$(dirname "${ENV_FILE}")"

# Migrate if sudo previously wrote to /root/.config/sovereign/restic.env
if [[ ! -f "${ENV_FILE}" && -f /root/.config/sovereign/restic.env ]]; then
    install -m 0600 -o "${OWNER}" -g "${OWNER}" /root/.config/sovereign/restic.env "${ENV_FILE}"
    log "Migrated restic.env from /root → ${ENV_FILE}"
fi

if [[ ! -f "${ENV_FILE}" ]]; then
    pass=$(openssl rand -base64 32)
    cat > "${ENV_FILE}" << EOF
# SMADP restic — generated $(date -Iseconds)
export RESTIC_REPOSITORY="${REPO_PATH}"
export RESTIC_PASSWORD="${pass}"
EOF
    chown "${OWNER}:${OWNER}" "${ENV_FILE}"
    chmod 0600 "${ENV_FILE}"
    log "Created ${ENV_FILE} — SAVE PASSWORD (also add to Bitwarden)"
else
    chown "${OWNER}:${OWNER}" "${ENV_FILE}" 2>/dev/null || true
    chmod 0600 "${ENV_FILE}"
    log "Using existing ${ENV_FILE}"
fi

# shellcheck disable=SC1090
source "${ENV_FILE}"

install -d -m 0700 "${REPO_PATH}"
if restic snapshots &>/dev/null; then
    log "Repository already initialized at ${REPO_PATH}"
else
    restic init
    log "Initialized restic repo at ${REPO_PATH}"
fi

# kraken runs backups — repo must not stay root-only after sudo init
install -d -m 0750 -o "${OWNER}" -g "${OWNER}" /mnt/systems_admin/restic/staging
chown -R "${OWNER}:${OWNER}" /mnt/systems_admin/restic
chmod 700 "${REPO_PATH}"

restic snapshots | head -5
log "Done. Run backup: bash ~/SovereignAid/scripts/backup/run-smadp-backup.sh"