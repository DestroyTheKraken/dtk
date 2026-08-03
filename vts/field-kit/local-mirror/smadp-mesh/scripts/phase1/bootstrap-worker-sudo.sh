#!/usr/bin/env bash
# bootstrap-worker-sudo.sh — Deploy + run passwordless-sudo setup on workers
#
# Run from um690 as kraken (NOT sudo). You will be prompted for each worker's sudo password.
#   bash ~/SovereignAid/scripts/phase1/bootstrap-worker-sudo.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PHASE0_DIR="$(dirname "${SCRIPT_DIR}")/phase0"
SSH_WORKER="${PHASE0_DIR}/ssh-worker.sh"

[[ -x "${SSH_WORKER}" ]] || { echo "Missing ${SSH_WORKER}" >&2; exit 1; }

resolve() {
    bash "${SSH_WORKER}" "$1" resolve
}

for worker in node1 node2; do
    host=$(resolve "${worker}") || { echo "Cannot resolve ${worker}" >&2; exit 1; }
    echo ""
    echo "=== ${worker} (${host}) — enter sudo password when prompted ==="
    scp -o ConnectTimeout=15 "${SCRIPT_DIR}/setup-worker-passwordless-sudo.sh" \
        "kraken@${host}:~/SovereignAid/scripts/phase1/"
    ssh -t -o ConnectTimeout=15 "kraken@${host}" \
        'sudo bash ~/SovereignAid/scripts/phase1/setup-worker-passwordless-sudo.sh'
done

echo ""
echo "Done. Re-run: sudo bash ~/SovereignAid/scripts/phase1/run-phase1.sh"