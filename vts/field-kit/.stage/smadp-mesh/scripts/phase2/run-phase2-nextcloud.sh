#!/usr/bin/env bash
# run-phase2-nextcloud.sh — Deploy + verify Nextcloud on um690
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

[[ "$(hostname -s)" == "um690" ]] || { echo "Run from um690" >&2; exit 1; }

echo "=== Phase 2: Nextcloud + MariaDB ==="
bash "${SCRIPT_DIR}/deploy-nextcloud.sh"
echo ""
echo "=== Verify ==="
bash "${SCRIPT_DIR}/verify-phase2-nextcloud.sh"