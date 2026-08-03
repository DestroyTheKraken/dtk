#!/usr/bin/env bash
# verify-phase2-dhcp.sh — Validate VyOS LABNET static DHCP + node1 ARP
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST="${ROUTER_HOST:-router-lab}"

ok=true
pass() { echo "  PASS: $*"; }
fail() { echo "  FAIL: $*" >&2; ok=false; }
warn() { echo "  WARN: $*"; }

declare -A EXPECT=(
    [um690]="192.168.20.100|58:47:ca:70:aa:02"
    [node1]="192.168.20.101|d8:cb:8a:01:7a:89"
    [node2]="192.168.20.102|44:8a:5b:dd:a0:c5"
)

echo "=== Phase 2 VyOS DHCP Verification (from $(hostname -s)) ==="

# Router SSH gate
if ! bash "${SCRIPT_DIR}/vyos-verify-access.sh" &>/dev/null; then
    fail "VyOS SSH not ready — run vyos-verify-access.sh first"
    echo "=== Phase 2 DHCP incomplete ===" >&2
    exit 1
fi

CONFIG=$(bash "${SCRIPT_DIR}/vyos-run.sh" --host "${HOST}" show configuration commands 2>/dev/null || true)

for name in um690 node1 node2; do
    IFS='|' read -r ip mac <<< "${EXPECT[$name]}"
    if echo "${CONFIG}" | grep -Eq "static-mapping ${name} ip-address '?${ip}'?" \
        && echo "${CONFIG}" | grep -Fq "static-mapping ${name} mac '${mac}'"; then
        pass "VyOS static-mapping ${name} → ${ip} (${mac})"
    else
        fail "VyOS static-mapping ${name} missing — run apply-vyos-phase2-dhcp.sh"
    fi
done

if echo "${CONFIG}" | grep -Fq 'shared-network-name LABNET subnet 192.168.20.0/24'; then
    pass "LABNET subnet 192.168.20.0/24 present"
else
    fail "LABNET subnet not found in VyOS config"
fi

echo ""
echo "=== DHCP leases (LABNET cluster IPs) ==="
LEASES=$(bash "${SCRIPT_DIR}/vyos-run.sh" --host "${HOST}" show dhcp server leases 2>/dev/null || true)
for name in um690 node1 node2; do
    IFS='|' read -r ip mac <<< "${EXPECT[$name]}"
    LINE=$(echo "${LEASES}" | grep "${ip}" || true)
    if [[ -z "${LINE}" ]]; then
        warn "No active lease for ${ip} (${name}) — may need DHCP renew"
        continue
    fi
    LEASE_MAC=$(echo "${LINE}" | awk '{print $2}')
    if [[ "${LEASE_MAC}" == "${mac}" ]]; then
        pass "Lease ${ip} → ${LEASE_MAC} (${name})"
    else
        fail "Lease ${ip} → ${LEASE_MAC} (expected ${mac} for ${name})"
    fi
done

echo ""
echo "=== node1 ARP + SSH flap ==="
NODE_IP="192.168.20.101"
EXPECTED_MAC="d8:cb:8a:01:7a:89"
ping -c 1 -W 1 "${NODE_IP}" &>/dev/null || true
ARP_MAC=$(ip neigh show "${NODE_IP}" 2>/dev/null | awk '{print $5}' || echo "unknown")
if [[ "${ARP_MAC}" == "${EXPECTED_MAC}" ]]; then
    pass "ARP ${NODE_IP} → ${ARP_MAC}"
else
    fail "ARP ${NODE_IP} → ${ARP_MAC} (expected ${EXPECTED_MAC})"
fi

OPEN=0
CLOSED=0
for _ in $(seq 1 20); do
    if nc -zv -w 1 "${NODE_IP}" 22 &>/dev/null; then
        OPEN=$((OPEN + 1))
    else
        CLOSED=$((CLOSED + 1))
    fi
    sleep 0.15
done
if [[ "${CLOSED}" -eq 0 ]]; then
    pass "node1 SSH port 22 stable (${OPEN}/20 open)"
elif [[ "${OPEN}" -ge 15 ]]; then
    warn "node1 SSH mostly open (${OPEN}/20) — monitor"
else
    fail "node1 SSH flaky (${OPEN}/20 open, ${CLOSED} closed)"
fi

echo ""
if $ok; then
    echo "=== Phase 2 VyOS DHCP OK ==="
    exit 0
else
    echo "=== Phase 2 VyOS DHCP incomplete ===" >&2
    exit 1
fi