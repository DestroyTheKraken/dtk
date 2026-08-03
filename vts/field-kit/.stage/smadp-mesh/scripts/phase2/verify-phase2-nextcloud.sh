#!/usr/bin/env bash
# verify-phase2-nextcloud.sh — Nextcloud + MariaDB acceptance checks
set -euo pipefail

NAMESPACE="nextcloud"
HOST="um690.taile52ad9.ts.net"
LAN_IP="${SMADP_LAN_IP:-192.168.20.100}"
TS_IP="${SMADP_TS_IP:-100.120.232.39}"
KC="${KUBECONFIG:-${HOME}/.kube/config}"
[[ -r "${KC}" ]] || KC=/etc/rancher/k3s/k3s.yaml
export KUBECONFIG="${KC}"

ok=true
pass() { echo "  PASS: $*"; }
fail() { echo "  FAIL: $*" >&2; ok=false; }
warn() { echo "  WARN: $*"; }

echo "=== Phase 2 Nextcloud Verification ($(hostname -s)) ==="

if kubectl get namespace "${NAMESPACE}" &>/dev/null; then
    pass "namespace/${NAMESPACE}"
else
    fail "namespace/${NAMESPACE} missing"
fi

if helm list -n "${NAMESPACE}" 2>/dev/null | grep -q nextcloud; then
    pass "Helm release nextcloud"
else
    fail "Helm release nextcloud missing"
fi

for dep in nextcloud; do
    if kubectl get deployment "${dep}" -n "${NAMESPACE}" &>/dev/null \
        && kubectl rollout status deployment/"${dep}" -n "${NAMESPACE}" --timeout=10s &>/dev/null; then
        pass "deployment/${dep} Ready"
    else
        fail "deployment/${dep} not Ready"
    fi
done

if kubectl get statefulset -n "${NAMESPACE}" -l app.kubernetes.io/name=mariadb -o name 2>/dev/null | grep -q statefulset; then
    STS=$(kubectl get statefulset -n "${NAMESPACE}" -l app.kubernetes.io/name=mariadb -o jsonpath='{.items[0].metadata.name}')
    if kubectl rollout status statefulset/"${STS}" -n "${NAMESPACE}" --timeout=10s &>/dev/null; then
        pass "MariaDB statefulset/${STS} Ready"
    else
        fail "MariaDB not Ready"
    fi
else
    fail "MariaDB statefulset missing"
fi

PVC_COUNT=$(kubectl get pvc -n "${NAMESPACE}" --no-headers 2>/dev/null | wc -l)
if [[ "${PVC_COUNT}" -ge 2 ]]; then
    pass "PVCs bound (${PVC_COUNT})"
else
    fail "Expected ≥2 PVCs (nextcloud + mariadb), got ${PVC_COUNT}"
fi

if kubectl get ingress -n "${NAMESPACE}" -o name 2>/dev/null | grep -q ingress; then
    pass "Ingress resource"
else
    fail "Ingress missing"
fi

echo ""
echo "=== MagicDNS ==="
if getent hosts "${HOST}" &>/dev/null; then
    pass "${HOST} resolves"
else
    fail "${HOST} does not resolve (enable Tailscale MagicDNS)"
fi

echo ""
echo "=== HTTP via Traefik (MagicDNS — no custom Host header) ==="
CODE=$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 15 "http://${HOST}/login" 2>/dev/null || echo "000")
if [[ "${CODE}" =~ ^(200|302)$ ]]; then
    pass "Nextcloud http://${HOST}/login (${CODE})"
else
    fail "Nextcloud http://${HOST}/login (HTTP ${CODE})"
fi
# Tailscale IP works only with correct Host header (same as Android app using MagicDNS URL)
CODE_IP=$(curl -s -o /dev/null -w '%{http_code}' -H "Host: ${HOST}" \
    --connect-timeout 15 "http://${TS_IP}/login" 2>/dev/null || echo "000")
if [[ "${CODE_IP}" =~ ^(200|302)$ ]]; then
    pass "Nextcloud via Tailscale IP + Host ${HOST} (${CODE_IP})"
else
    warn "Tailscale IP without Host header will 404 — use MagicDNS URL in apps"
fi

echo ""
if $ok; then
    echo "=== Phase 2 Nextcloud OK ==="
    echo ""
    echo "  http://${HOST}/"
    echo "  Credentials: ~/.config/sovereign/nextcloud.env"
    exit 0
else
    echo "=== Phase 2 Nextcloud incomplete ===" >&2
    exit 1
fi