#!/usr/bin/env bash
# audit-segmentation.sh — Test 192.168.20 vs 192.168.10 isolation from current host
# Run from um690: bash ~/SovereignAid/scripts/network/audit-segmentation.sh

set -euo pipefail

HOSTNAME=$(hostname -s)
PASS=0
FAIL=0
WARN=0

ok()   { echo "  PASS: $*"; PASS=$((PASS + 1)); }
bad()  { echo "  FAIL: $*"; FAIL=$((FAIL + 1)); }
warn() { echo "  WARN: $*"; WARN=$((WARN + 1)); }

echo "=== Segmentation Audit (${HOSTNAME}) ==="
echo ""

# Local subnet identity
LAN_IP=$(ip -4 -o addr show scope global | awk '{print $4}' | head -1)
echo "Local IPv4: ${LAN_IP:-unknown}"

echo ""
echo "=== Gateway reachability ==="
for gw in 192.168.20.1 192.168.10.1; do
    if ping -c 1 -W 2 "${gw}" &>/dev/null; then
        ok "ping ${gw}"
    else
        bad "ping ${gw}"
    fi
done

echo ""
echo "=== Cross-subnet probes (should NOT reach remote hosts) ==="
# .10 hosts from .20 — should fail if segmented
if [[ "${LAN_IP}" == 192.168.20.* ]]; then
    for target in 192.168.10.2 192.168.10.50 192.168.10.100; do
        if ping -c 1 -W 2 "${target}" &>/dev/null; then
            bad "192.168.20 host can ping ${target} — segmentation leak"
        else
            ok "blocked/unreachable ${target}"
        fi
    done
    # Router .10 interface may be reachable (same router, different SVI)
    if ping -c 1 -W 2 192.168.10.1 &>/dev/null; then
        warn "192.168.10.1 reachable from .20 (router mgmt IF — verify firewall blocks forward)"
    fi
fi

echo ""
echo "=== Router management ports (from this subnet) ==="
for gw in 192.168.20.1 192.168.10.1; do
    if nc -zv -w 2 "${gw}" 22 &>/dev/null; then
        warn "${gw}:22 SSH open from ${LAN_IP}"
    else
        ok "${gw}:22 closed/refused from ${LAN_IP}"
    fi
done

echo ""
echo "=== node1 ARP sanity (IP conflict check) ==="
if command -v ip &>/dev/null && ip neigh show 192.168.20.101 &>/dev/null; then
    ARP_MAC=$(ip neigh show 192.168.20.101 | awk '{print $5}')
    warn "um690 ARP for .101 → ${ARP_MAC} (expect node1 eno1 d8:cb:8a:01:7a:89)"
    if [[ "${ARP_MAC}" != "d8:cb:8a:01:7a:89" ]]; then
        bad "ARP MAC mismatch — possible IP conflict at 192.168.20.101"
    else
        ok "ARP MAC matches node1 hardware"
    fi
fi

echo ""
echo "=== Summary: ${PASS} pass, ${FAIL} fail, ${WARN} warn ==="
[[ "${FAIL}" -eq 0 ]] || exit 1