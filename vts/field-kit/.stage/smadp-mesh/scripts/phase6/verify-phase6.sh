#!/usr/bin/env bash
# verify-phase6.sh — Phase 6 Ops Command Center acceptance checks
set -euo pipefail

NAMESPACE="ops-center"
HOST="um690.taile52ad9.ts.net"
BASE="https://${HOST}"

KC="${KUBECONFIG:-${HOME}/.kube/config}"
[[ -r "${KC}" ]] || KC=/etc/rancher/k3s/k3s.yaml
export KUBECONFIG="${KC}"

ok=true
pass() { echo "  PASS: $*"; }
fail() { echo "  FAIL: $*" >&2; ok=false; }

echo "=== Phase 6 User Experience ($(hostname -s)) ==="

if kubectl get deployment ops-center -n "${NAMESPACE}" &>/dev/null \
    && kubectl rollout status deployment/ops-center -n "${NAMESPACE}" --timeout=30s &>/dev/null; then
    pass "deployment/ops-center Ready"
else
    fail "deployment/ops-center not Ready"
fi

if kubectl get ingress ops-center -n "${NAMESPACE}" -o yaml | grep -q '/ops'; then
    pass "ingress /ops"
else
    fail "ops ingress missing"
fi

if kubectl get ingress longhorn-ui -n longhorn-system &>/dev/null; then
    pass "ingress /longhorn"
else
    fail "longhorn ingress missing"
fi

for path in "/ops/" "/ops/bookmarks.html" "/longhorn/"; do
    CODE=$(curl -sk -o /dev/null -w '%{http_code}' --connect-timeout 15 "${BASE}${path}")
    if [[ "${CODE}" =~ ^(200|301|302)$ ]]; then
        pass "${BASE}${path} (${CODE})"
    else
        fail "${BASE}${path} (HTTP ${CODE})"
    fi
done

BODY=$(curl -sk --connect-timeout 15 "${BASE}/ops/" 2>/dev/null || true)
if echo "${BODY}" | grep -qi 'Ops Command Center'; then
    pass "ops dashboard content"
else
    fail "ops dashboard content missing"
fi

if echo "${BODY}" | grep -q 'manifest.webmanifest'; then
    pass "PWA manifest linked"
else
    fail "PWA manifest not linked"
fi

if [[ -f "${HOME}/SovereignAid/user-guide/Firefox-PWA-Setup.md" ]]; then
    pass "Firefox PWA guide exists"
else
    fail "Firefox PWA guide missing"
fi

if [[ -f "${HOME}/SovereignAid/user-guide/smadp-bookmarks.html" ]]; then
    pass "smadp-bookmarks.html exists"
else
    fail "bookmarks file missing"
fi

echo ""
if $ok; then
    echo "=== Phase 6 User Experience OK ==="
    echo "  ${BASE}/ops/"
    exit 0
else
    echo "=== Phase 6 User Experience incomplete ===" >&2
    exit 1
fi