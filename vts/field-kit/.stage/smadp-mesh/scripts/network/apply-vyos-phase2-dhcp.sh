#!/usr/bin/env bash
# apply-vyos-phase2-dhcp.sh — Apply LABNET static DHCP mappings on VyOS
#
# Run from um690: bash ~/SovereignAid/scripts/network/apply-vyos-phase2-dhcp.sh
# Requires: vyos-verify-access.sh passes

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="${SCRIPT_DIR}/vyos-phase2-dhcp-static.conf"
HOST="${ROUTER_HOST:-router-lab}"
SSH_OPTS=(-o BatchMode=yes -o ConnectTimeout=15 -o StrictHostKeyChecking=accept-new)

[[ -f "${CONF}" ]] || { echo "Missing ${CONF}" >&2; exit 1; }

echo "=== Apply VyOS Phase 2 DHCP (${HOST}) ==="
echo "Config: ${CONF}"
echo ""

# Build configure session from conf file (skip comments/blanks)
mapfile -t LINES < <(grep -v '^[[:space:]]*#' "${CONF}" | grep -v '^[[:space:]]*$' || true)
[[ ${#LINES[@]} -gt 0 ]] || { echo "No set lines in ${CONF}" >&2; exit 1; }

{
    echo "source /opt/vyatta/etc/functions/script-template"
    echo "configure"
    for line in "${LINES[@]}"; do
        echo "${line}"
    done
    echo "commit"
    echo "save"
    echo "exit"
} | ssh "${SSH_OPTS[@]}" "${HOST}" vbash -s

# Clear stale .101 lease if wrong MAC (Samsung conflict)
LEASE_LINE=$(bash "${SCRIPT_DIR}/vyos-run.sh" --host "${HOST}" show dhcp server leases 2>/dev/null \
    | grep '192.168.20.101' || true)
if [[ -n "${LEASE_LINE}" ]] && ! echo "${LEASE_LINE}" | grep -q 'd8:cb:8a:01:7a:89'; then
    echo "Clearing conflicting lease for 192.168.20.101 ..."
    bash "${SCRIPT_DIR}/vyos-run.sh" --host "${HOST}" clear dhcp-server lease 192.168.20.101 2>/dev/null || true
fi

echo ""
echo "=== Applied. Run verify-phase2-dhcp.sh ==="