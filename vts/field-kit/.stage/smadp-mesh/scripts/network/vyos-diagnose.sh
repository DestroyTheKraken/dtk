#!/usr/bin/env bash
# vyos-diagnose.sh — GrokOS network triage (lab + home + WAN)
#
# Run from um690: bash ~/SovereignAid/scripts/network/vyos-diagnose.sh
# Requires: VyOS SSH access (vyos-verify-access.sh passes)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

run() { bash "${SCRIPT_DIR}/vyos-run.sh" "$@" 2>/dev/null || echo "  [vyos unavailable]"; }

echo "=== GrokOS Network Diagnose ==="
echo "From: $(hostname -s) @ $(date)"
echo ""

# Local checks (always run)
bash "${SCRIPT_DIR}/audit-segmentation.sh" || true
echo ""
bash "${SCRIPT_DIR}/diagnose-node1-ssh.sh" || true
echo ""

echo "=== VyOS — DHCP leases (IP conflicts) ==="
run show dhcp leases
run show dhcp server leases
echo ""

echo "=== VyOS — NAT ==="
run show nat source rules
echo ""

echo "=== VyOS — Routes ==="
run show ip route
echo ""

echo "=== VyOS — ping lab nodes ==="
for ip in 192.168.20.100 192.168.20.101 192.168.20.102; do
    echo "--- ping ${ip} ---"
    run ping "${ip}" count 3
done
echo ""

echo "=== VyOS — ping home sample (segmentation) ==="
for ip in 192.168.10.2 192.168.10.50; do
    echo "--- ping ${ip} ---"
    run ping "${ip}" count 2
done
echo ""

echo "=== WAN from um690 ==="
curl -4 -s -o /dev/null -w "um690 → x.ai: %{time_total}s (http %{http_code})\n" --connect-timeout 15 https://x.ai/ || echo "  curl failed"
echo ""

echo "=== Recommendations ==="
echo "  node1 WAN fix:  ssh node1 'sudo bash ~/SovereignAid/scripts/network/fix-node1-wan.sh'"
echo "  Full audit:     bash ~/SovereignAid/scripts/network/vyos-audit.sh"
echo "  Verify access:  bash ~/SovereignAid/scripts/network/vyos-verify-access.sh"