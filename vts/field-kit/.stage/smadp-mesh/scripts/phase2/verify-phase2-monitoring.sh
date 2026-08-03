#!/usr/bin/env bash
# verify-phase2-monitoring.sh — Basic health collector acceptance checks
set -euo pipefail

NAMESPACE="monitoring"
KC="${KUBECONFIG:-${HOME}/.kube/config}"
[[ -r "${KC}" ]] || KC=/etc/rancher/k3s/k3s.yaml
export KUBECONFIG="${KC}"

ok=true
pass() { echo "  PASS: $*"; }
fail() { echo "  FAIL: $*" >&2; ok=false; }

echo "=== Phase 2 Monitoring Verification ($(hostname -s)) ==="

if kubectl get namespace "${NAMESPACE}" &>/dev/null; then
    pass "namespace/${NAMESPACE}"
else
    fail "namespace/${NAMESPACE} missing"
fi

if kubectl get deployment health-collector -n "${NAMESPACE}" &>/dev/null \
    && kubectl rollout status deployment/health-collector -n "${NAMESPACE}" --timeout=30s &>/dev/null; then
    pass "deployment/health-collector Ready"
else
    fail "deployment/health-collector not Ready"
fi

READY=$(kubectl get pods -n "${NAMESPACE}" -l app.kubernetes.io/name=health-collector \
    -o jsonpath='{.items[?(@.metadata.labels.app\.kubernetes\.io/component=="collector")].status.phase}' 2>/dev/null || true)
if [[ "${READY}" == "Running" ]]; then
    pass "health-collector pod Running"
else
    fail "health-collector pod not Running (phase=${READY:-none})"
fi

if kubectl get cronjob health-snapshot -n "${NAMESPACE}" &>/dev/null; then
    pass "cronjob/health-snapshot"
else
    fail "cronjob/health-snapshot missing"
fi

if kubectl get clusterrolebinding smadp-health-collector &>/dev/null; then
    pass "RBAC smadp-health-collector"
else
    fail "RBAC missing"
fi

LOGS=$(kubectl logs -n "${NAMESPACE}" -l app.kubernetes.io/component=collector --tail=5 2>/dev/null || true)
if echo "${LOGS}" | grep -q 'health-collector'; then
    pass "Collector producing logs"
else
    fail "Collector logs empty — check pod"
fi

echo ""
if $ok; then
    echo "=== Phase 2 Monitoring OK ==="
    echo "  kubectl logs -n monitoring -l app.kubernetes.io/component=collector -f"
    exit 0
else
    echo "=== Phase 2 Monitoring incomplete ===" >&2
    exit 1
fi