#!/usr/bin/env bash
# vyos-verify-access.sh — Verify Grok can SSH to VyOS from um690
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SSH_OPTS=(-o BatchMode=yes -o ConnectTimeout=8 -o StrictHostKeyChecking=accept-new)
VYOS_OP="/opt/vyatta/bin/vyatta-op-cmd-wrapper"

ok=true
pass() { echo "  PASS: $*"; }
fail() { echo "  FAIL: $*" >&2; ok=false; }

echo "=== GrokOS VyOS Access Verification (from $(hostname -s)) ==="

for host in router-home router-lab; do
    if ssh "${SSH_OPTS[@]}" "${host}" "${VYOS_OP}" show version &>/dev/null; then
        VER=$(ssh "${SSH_OPTS[@]}" "${host}" "${VYOS_OP}" show version 2>/dev/null | head -1)
        pass "${host} SSH — ${VER}"
    else
        fail "${host} SSH — not reachable (apply vyos-enable-grok-mgmt.generated.conf on VyOS)"
    fi
done

echo ""
echo "=== Segmentation (unchanged expectation) ==="
bash "${SCRIPT_DIR}/audit-segmentation.sh" 2>/dev/null | tail -3 || true

echo ""
if $ok; then
    echo "=== GrokOS router access OK ==="
    exit 0
else
    echo "=== Router access not ready — apply VyOS config first ===" >&2
    exit 1
fi