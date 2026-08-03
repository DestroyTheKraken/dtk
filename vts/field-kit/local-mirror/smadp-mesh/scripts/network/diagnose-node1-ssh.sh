#!/usr/bin/env bash
# diagnose-node1-ssh.sh — Diagnose node1 intermittent SSH (run from um690)
set -euo pipefail

NODE_IP="192.168.20.101"
EXPECTED_MAC="d8:cb:8a:01:7a:89"

echo "=== node1 SSH / ARP Diagnostic (from $(hostname -s)) ==="
echo ""

ARP_MAC=$(ip neigh show "${NODE_IP}" 2>/dev/null | awk '{print $5}' || echo "unknown")
echo "ARP ${NODE_IP} → ${ARP_MAC}"
echo "Expected node1 eno1 → ${EXPECTED_MAC}"

if [[ "${ARP_MAC}" != "${EXPECTED_MAC}" ]]; then
    echo ""
    echo "  *** IP CONFLICT SUSPECTED ***"
    echo "  Another device may be claiming ${NODE_IP} with MAC ${ARP_MAC}"
    echo "  Check VyOS DHCP leases + static reservations for duplicate .101"
fi

echo ""
echo "=== Port 22 flap test (30 samples) ==="
OPEN=0
CLOSED=0
for _ in $(seq 1 30); do
    if nc -zv -w 1 "${NODE_IP}" 22 &>/dev/null; then
        OPEN=$((OPEN + 1))
    else
        CLOSED=$((CLOSED + 1))
    fi
    sleep 0.2
done
echo "  open: ${OPEN}  closed/timeout: ${CLOSED}"

echo ""
echo "=== Ping ==="
ping -c 5 -W 1 "${NODE_IP}" | tail -2

if [[ -x "$(dirname "$0")/../phase0/ssh-worker.sh" ]]; then
    echo ""
    echo "=== ssh-worker resolve ==="
    "$(dirname "$0")/../phase0/ssh-worker.sh" node1 resolve 2>&1 || true
fi