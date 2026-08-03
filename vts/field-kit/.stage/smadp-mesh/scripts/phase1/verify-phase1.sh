#!/usr/bin/env bash
# verify-phase1.sh — Phase 1 acceptance criteria
set -euo pipefail

HOSTNAME=$(hostname -s)
ok=true
pass() { echo "  PASS: $*"; }
fail() { echo "  FAIL: $*" >&2; ok=false; }

echo "=== Phase 1 Verification (${HOSTNAME}) ==="

# open-iscsi
if systemctl is-active iscsid &>/dev/null; then
    pass "iscsid active"
else
    fail "iscsid not active (run: sudo bash install-k3s-deps.sh)"
fi

# k3s binary
if command -v k3s &>/dev/null; then
    pass "k3s installed: $(k3s --version 2>/dev/null | head -1)"
else
    fail "k3s not installed"
fi

# Control plane checks (um690 only)
if [[ "${HOSTNAME}" == "um690" ]]; then
    if [[ -f "${HOME}/.kube/config" ]]; then
        KC="${HOME}/.kube/config"
    elif [[ -r /etc/rancher/k3s/k3s.yaml ]]; then
        KC=/etc/rancher/k3s/k3s.yaml
    else
        KC=""
    fi

    if [[ -n "${KC}" ]]; then
        export KUBECONFIG="${KC}"
        if kubectl get nodes --no-headers 2>/dev/null | grep -q Ready; then
            pass "kubectl get nodes"
            kubectl get nodes --no-headers 2>/dev/null | while read -r line; do
                pass "  ${line}"
            done
        else
            fail "no Ready nodes"
        fi

        if kubectl get pods -n longhorn-system --no-headers 2>/dev/null | grep -q Running; then
            pass "Longhorn pods Running"
        else
            fail "Longhorn not running"
        fi

        for ns in nextcloud websites monitoring ops-center; do
            if kubectl get namespace "${ns}" &>/dev/null; then
                pass "namespace/${ns}"
            else
                fail "namespace/${ns} missing"
            fi
        done
    else
        fail "kubeconfig not found"
    fi
fi

echo ""
if $ok; then
    echo "=== Phase 1 checks passed on ${HOSTNAME} ==="
    exit 0
else
    echo "=== Phase 1 incomplete on ${HOSTNAME} ===" >&2
    exit 1
fi