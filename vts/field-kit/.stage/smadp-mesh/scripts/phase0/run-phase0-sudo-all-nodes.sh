#!/usr/bin/env bash
# run-phase0-sudo-all-nodes.sh — Run sudo Phase 0 tasks on all cluster nodes
#
# Requires: passwordless sudo OR interactive terminal on each node.
# Run from um690: bash ~/SovereignAid/scripts/phase0/run-phase0-sudo-all-nodes.sh
#
# Tasks: UFW + delegation dirs + phase0 verify

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOSTS=(um690 node1 node2)
CURRENT=$(hostname -s)

run_local() {
    echo "=== ${CURRENT} (local) ==="
    sudo bash "${SCRIPT_DIR}/setup-ufw.sh"
    sudo bash "${SCRIPT_DIR}/setup-delegation-dirs.sh"
    bash "${SCRIPT_DIR}/verify-phase0.sh" || true
}

run_remote() {
    local host=$1
    echo "=== ${host} (remote) ==="
    ssh -o BatchMode=yes -o ConnectTimeout=15 "kraken@${host}" bash -s <<EOF
set -euo pipefail
sudo bash ~/SovereignAid/scripts/phase0/setup-ufw.sh
sudo bash ~/SovereignAid/scripts/phase0/setup-delegation-dirs.sh
bash ~/SovereignAid/scripts/phase0/verify-phase0.sh || true
EOF
}

# Deploy scripts first
bash "${SCRIPT_DIR}/deploy-phase0-scripts.sh"

for host in "${HOSTS[@]}"; do
    if [[ "${host}" == "${CURRENT}" ]]; then
        run_local
    else
        run_remote "${host}" || echo "  SKIP: ${host} failed" >&2
    fi
done

echo ""
echo "Done. Re-run verify: bash ~/SovereignAid/scripts/phase0/verify-phase0.sh (per node)"