#!/usr/bin/env bash
# setup-tailscale-https.sh — One-shot Tailscale HTTPS for Nextcloud (requires sudo)
#
# Run on um690:
#   sudo bash ~/SovereignAid/scripts/phase2/setup-tailscale-https.sh
#
# Prereq: Tailscale admin → DNS → HTTPS Certificates ENABLED

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

[[ "$(id -u)" -eq 0 ]] || { echo "Run with: sudo bash $0" >&2; exit 1; }
[[ "$(hostname -s)" == "um690" ]] || { echo "Run on um690" >&2; exit 1; }

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
OWNER="${SUDO_USER:-kraken}"

echo "=== Tailscale HTTPS for Nextcloud ==="

# Allow Traefik pod (uid 65532) to fetch certs via socket (optional resolver path)
tailscale set --operator=65532 2>/dev/null || true
tailscale set --operator=root 2>/dev/null || true

# Primary: sync Let's Encrypt cert from tailscaled → k8s TLS secret
bash "${SCRIPT_DIR}/sync-tailscale-tls-secret.sh"

# Apply Traefik + Nextcloud HTTPS config as cluster user
sudo -u "${OWNER}" -H bash "${SCRIPT_DIR}/configure-tailscale-https.sh" --skip-cert-sync

echo ""
echo "=== Done ==="
echo "  Phone/tablet URL: https://um690.taile52ad9.ts.net"
echo "  Verify: bash ~/SovereignAid/scripts/phase2/verify-phase2-https.sh"
echo "  TLS cron: sudo bash ~/SovereignAid/scripts/phase2/install-tailscale-tls-cron.sh"