#!/usr/bin/env bash
# verify-phase4-valley-tech.sh — Valley Tech Support Hugo site acceptance checks
set -euo pipefail

NAMESPACE="websites"
APP="valley-tech-support"
HOST="um690.taile52ad9.ts.net"
BASE_URL="https://${HOST}/vts"

KC="${KUBECONFIG:-${HOME}/.kube/config}"
[[ -r "${KC}" ]] || KC=/etc/rancher/k3s/k3s.yaml
export KUBECONFIG="${KC}"

ok=true
pass() { echo "  PASS: $*"; }
fail() { echo "  FAIL: $*" >&2; ok=false; }

echo "=== Phase 4 Valley Tech Support ($(hostname -s)) ==="

if kubectl get deployment "${APP}" -n "${NAMESPACE}" &>/dev/null \
    && kubectl rollout status deployment/"${APP}" -n "${NAMESPACE}" --timeout=30s &>/dev/null; then
    pass "deployment/${APP} Ready"
else
    fail "deployment/${APP} not Ready"
fi

if kubectl get configmap valley-tech-static -n "${NAMESPACE}" &>/dev/null; then
    pass "configmap/valley-tech-static"
else
    fail "configmap/valley-tech-static missing"
fi

if kubectl get ingress "${APP}" -n "${NAMESPACE}" -o yaml | grep -q '/vts'; then
    pass "ingress path /vts"
else
    fail "ingress missing /vts path"
fi

for path in "/" "/services/" "/about/" "/contact/"; do
    CODE=$(curl -sk -o /dev/null -w '%{http_code}' --connect-timeout 15 "${BASE_URL}${path}")
    if [[ "${CODE}" =~ ^(200|301|302)$ ]]; then
        pass "${BASE_URL}${path} (${CODE})"
    else
        fail "${BASE_URL}${path} (HTTP ${CODE})"
    fi
done

BODY=$(curl -sk --connect-timeout 15 "${BASE_URL}/" 2>/dev/null || true)
if echo "${BODY}" | grep -qi 'rural IT'; then
    pass "homepage contains expected content"
else
    fail "homepage content unexpected"
fi

if echo "${BODY}" | grep -q 'tailwindcss.com'; then
    pass "Notus-style Tailwind CDN loaded"
else
    fail "Tailwind CDN not in page"
fi

echo ""
if $ok; then
    echo "=== Phase 4 Valley Tech Support OK ==="
    echo "  ${BASE_URL}/"
    exit 0
else
    echo "=== Phase 4 Valley Tech Support incomplete ===" >&2
    exit 1
fi