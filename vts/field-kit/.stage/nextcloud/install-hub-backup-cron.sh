#!/bin/bash
# Install daily hub backup cron (phase 6 or standalone).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NC_INSTALL_SCRIPT_DIR="${SCRIPT_DIR}"
# shellcheck source=nc-common.sh
source "${SCRIPT_DIR}/nc-common.sh"

CURRENT_USER="$(whoami)"
OWNER_HOME="$(eval echo "~${CURRENT_USER}")"
BACKUP_SCRIPT="${SCRIPT_DIR}/backup-hub-to-staging.sh"

nc_install_hub_backup_sudoers "${CURRENT_USER}" "${BACKUP_SCRIPT}"
nc_install_hub_backup_cron "${CURRENT_USER}" "${BACKUP_SCRIPT}" "${OWNER_HOME}"

echo "Hub backup cron installed (02:15 daily)"
crontab -l | grep backup-hub-to-staging || true