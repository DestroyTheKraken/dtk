#!/bin/bash
#
# Phase 6: Daily hub backup cron.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NC_INSTALL_SCRIPT_DIR="${SCRIPT_DIR}"
# shellcheck source=nc-common.sh
source "${SCRIPT_DIR}/nc-common.sh"

DOCS_DIR="$(nc_docs_dir)"
OUTPUT_FILE="${DOCS_DIR}/06-backup.json"

if [ ! -f "${DOCS_DIR}/05-complete.json" ]; then
  echo "ERROR: Run phase-05 first."
  exit 1
fi

echo "=== Phase 6: Hub Backup Automation (nc_install v${NC_INSTALL_VERSION}) ==="
bash "${SCRIPT_DIR}/install-hub-backup-cron.sh"

python3 <<PY
import json
from datetime import datetime, timezone

out = {
  "phase": 6,
  "installer_version": "${NC_INSTALL_VERSION}",
  "timestamp": datetime.now().astimezone().isoformat(),
  "backup_script": "${SCRIPT_DIR}/backup-hub-to-staging.sh",
  "staging_dir": "$(eval echo "~$(whoami)")/Backups/nas-export",
  "cron_schedule": "15 2 * * *",
  "remote_pull_note": "Optional: rsync/scp ~/Backups/nas-export/ from hub to your backup server"
}
with open("${OUTPUT_FILE}", "w") as f:
    json.dump(out, f, indent=2)
PY

echo ""
echo "=== Phase 6 Complete ==="
echo "Test: sudo -n ${SCRIPT_DIR}/backup-hub-to-staging.sh"
echo "================================================================"
