#!/usr/bin/env bash
# verify-phase2-traefik.sh — Phase 2 Traefik acceptance checks
set -euo pipefail

HOSTNAME=$(hostname -s)
KC="${KUBECONFIG:-${HOME}/.kube/config}"
[[ -r "${KC}" ]] || KC=/etc/rancher/k3s/k3s.yaml
export KUBECONFIG="${KC}"

LAN_IP="${SMADP_LAN_IP:-192.168.20.100}"
CONTROL_HOST="um690.taile52ad9.ts.net"

ok=true
pass() { echo "  PASS: $*"; }
fail() { echo "  FAIL: $*" >&2; ok=false; }
warn() { echo "  WARN: $*"; }

echo "=== Phase 2 Traefik Verification (${HOSTNAME}) ==="

if kubectl get ingressclass traefik &>/dev/null; then
    pass "IngressClass traefik"
else
    fail "IngressClass traefik missing"
fi

if kubectl get deployment traefik -n kube-system &>/dev/null \
    && kubectl get pods -n kube-system -l app.kubernetes.io/name=traefik \
        --field-selector=status.phase=Running -o name 2>/dev/null | grep -q pod; then
    pass "Traefik pod Running (kube-system)"
else
    fail "Traefik not Running"
fi

if kubectl get helmchartconfig traefik -n kube-system &>/dev/null; then
    pass "HelmChartConfig traefik (SMADP config)"
else
    fail "HelmChartConfig traefik missing — run deploy-traefik.sh"
fi

if kubectl get namespace ingress &>/dev/null; then
    pass "namespace/ingress"
else
    fail "namespace/ingress missing"
fi

if kubectl get deployment whoami -n ingress &>/dev/null \
    && kubectl get pods -n ingress -l app=whoami --field-selector=status.phase=Running -o name 2>/dev/null | grep -q pod; then
    pass "whoami smoke-test Running"
else
    fail "whoami deployment not Running"
fi

if kubectl get ingress whoami -n ingress &>/dev/null; then
    pass "Ingress whoami"
else
    fail "Ingress whoami missing"
fi

echo ""
echo "=== HTTP routing (Host header via LAN) ==="
BODY=$(curl -sf --connect-timeout 5 "http://${CONTROL_HOST}/whoami" 2>/dev/null || true)
if echo "${BODY}" | grep -qi 'Hostname'; then
    pass "whoami http://${CONTROL_HOST}/whoami"
else
    fail "whoami not routing at http://${CONTROL_HOST}/whoami"
fi

CODE=$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 5 \
    "http://${CONTROL_HOST}/dashboard/" 2>/dev/null || echo "000")
if [[ "${CODE}" =~ ^(200|301|302)$ ]]; then
    pass "Traefik dashboard http://${CONTROL_HOST}/dashboard/ (${CODE})"
else
    warn "Dashboard HTTP ${CODE} — may need HelmChartConfig reconcile (retry in 1 min)"
fi

echo ""
if $ok; then
    echo "=== Phase 2 Traefik OK ==="
    echo ""
    echo "URLs (Tailscale MagicDNS):"
    echo "  http://${CONTROL_HOST}/whoami"
    echo "  http://${CONTROL_HOST}/dashboard/"
    exit 0
else
    echo "=== Phase 2 Traefik incomplete ===" >&2
    exit 1
fi