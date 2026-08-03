#!/usr/bin/env bash
# run-phase2-traefik.sh — Phase 2 Traefik ingress (um690)
#
# Run: sudo bash ~/SovereignAid/scripts/phase2/run-phase2-traefik.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OWNER="${SUDO_USER:-kraken}"

[[ "$(id -u)" -eq 0 ]] || { echo "Run with: sudo bash $0" >&2; exit 1; }
[[ "$(hostname -s)" == "um690" ]] || { echo "Run from um690" >&2; exit 1; }

echo "=== Phase 2: Traefik Ingress ==="
bash "${SCRIPT_DIR}/deploy-traefik.sh"
echo ""
echo "=== Verify ==="
sudo -u "${OWNER}" -H bash "${SCRIPT_DIR}/verify-phase2-traefik.sh"