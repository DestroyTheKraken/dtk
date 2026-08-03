#!/usr/bin/env bash
# vyos-audit.sh — Full VyOS audit for GrokOS network admin (read-only)
#
# Run from um690: bash ~/SovereignAid/scripts/network/vyos-audit.sh
# Output: ~/SovereignAid/audit/vyos-YYYYMMDD-HHMMSS.txt

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${HOME}/SovereignAid"
OUT_DIR="${REPO}/audit"
STAMP=$(date +%Y%m%d-%H%M%S)
OUT="${OUT_DIR}/vyos-${STAMP}.txt"

install -d "${OUT_DIR}"

COMMANDS=(
    "show version"
    "show system uptime"
    "show interfaces"
    "show ip route"
    "show ipv6 route"
    "show nat source rules"
    "show nat destination rules"
    "show dhcp leases"
    "show dhcp server leases"
    "show dns forwarding nameservers"
    "show configuration commands"
)

{
    echo "# VyOS Audit — GrokOS"
    echo "# Host: $(hostname -s)"
    echo "# Date: $(date -Iseconds)"
    echo ""
} > "${OUT}"

for cmd in "${COMMANDS[@]}"; do
    {
        echo "================================================================"
        echo "# ${cmd}"
        echo "================================================================"
        bash "${SCRIPT_DIR}/vyos-run.sh" "${cmd}" 2>&1 || echo "  [command failed: ${cmd}]"
        echo ""
    } >> "${OUT}"
done

# Lab + home reachability from router
EXTRA=(
    "ping 192.168.20.100 count 3"
    "ping 192.168.20.101 count 3"
    "ping 192.168.20.102 count 3"
    "ping 192.168.10.2 count 2"
)
for cmd in "${EXTRA[@]}"; do
    {
        echo "================================================================"
        echo "# ${cmd}"
        echo "================================================================"
        bash "${SCRIPT_DIR}/vyos-run.sh" "${cmd}" 2>&1 || true
        echo ""
    } >> "${OUT}"
done

echo "Audit written: ${OUT}"
wc -l "${OUT}"