#!/usr/bin/env bash
# deploy-phase0-scripts.sh — Push all phase0 scripts to cluster nodes
# Run from um690: bash ~/SovereignAid/scripts/phase0/deploy-phase0-scripts.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOSTS=(node1 node2)

for host in "${HOSTS[@]}"; do
    echo "=== Deploying to ${host} ==="
    if ssh -o BatchMode=yes -o ConnectTimeout=10 "kraken@${host}" 'mkdir -p ~/SovereignAid/scripts/phase0 ~/SovereignAid/user-guide'; then
        scp -o BatchMode=yes "${SCRIPT_DIR}"/*.sh "${SCRIPT_DIR}"/ssh-config-template \
            "kraken@${host}:~/SovereignAid/scripts/phase0/"
        scp -o BatchMode=yes "${HOME}/SovereignAid/user-guide/README.md" \
            "kraken@${host}:~/SovereignAid/user-guide/" 2>/dev/null || true
        ssh -o BatchMode=yes "kraken@${host}" \
            'chmod +x ~/SovereignAid/scripts/phase0/*.sh; ls -la ~/SovereignAid/scripts/phase0/recover-ssh.sh'
        echo "  OK: ${host}"
    else
        echo "  SKIP: ${host} unreachable" >&2
    fi
done

echo ""
echo "Done. On um690 install user-guide: sudo install -m 755 ~/SovereignAid/scripts/user-guide /usr/local/bin/user-guide"
echo "Pull scripts on node1 console if SSH down:"
echo "  scp kraken@192.168.20.100:~/SovereignAid/scripts/phase0/* ~/SovereignAid/scripts/phase0/"