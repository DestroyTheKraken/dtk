#!/usr/bin/env bash
# verify-phase2-https.sh — Tailscale HTTPS for Nextcloud
set -euo pipefail

HOST="um690.taile52ad9.ts.net"
KC="${KUBECONFIG:-${HOME}/.kube/config}"
[[ -r "${KC}" ]] || KC=/etc/rancher/k3s/k3s.yaml
export KUBECONFIG="${KC}"

ok=true
pass() { echo "  PASS: $*"; }
fail() { echo "  FAIL: $*" >&2; ok=false; }

echo "=== Phase 2 Tailscale HTTPS ($(hostname -s)) ==="

CR=$(kubectl get helmchartconfig traefik -n kube-system -o yaml 2>/dev/null || true)
if echo "${CR}" | grep -q 'tailscale:' && echo "${CR}" | grep -q 'tailscaled.sock'; then
    pass "Traefik Tailscale cert resolver + socket configured"
else
    fail "Traefik missing Tailscale TLS config — run configure-tailscale-https.sh"
fi

ING=$(kubectl get ingress nextcloud -n nextcloud -o yaml 2>/dev/null || true)
if echo "${ING}" | grep -q 'secretName: nextcloud-tailscale-tls'; then
    pass "Nextcloud ingress TLS secret nextcloud-tailscale-tls"
else
    fail "Nextcloud ingress missing TLS secretName"
fi

if kubectl get secret nextcloud-tailscale-tls -n nextcloud &>/dev/null; then
    pass "Secret nextcloud-tailscale-tls exists"
else
    fail "Secret missing — run: sudo bash scripts/phase2/setup-tailscale-https.sh"
fi

CODE=$(curl -sk -o /dev/null -w '%{http_code}' --connect-timeout 15 "https://${HOST}/login" 2>/dev/null || echo "000")
if [[ "${CODE}" =~ ^(200|302)$ ]]; then
    pass "https://${HOST}/login (${CODE})"
else
    fail "https://${HOST}/login (HTTP ${CODE})"
fi

ISSUER=$(echo | openssl s_client -connect "${HOST}:443" -servername "${HOST}" 2>/dev/null \
    | openssl x509 -noout -issuer 2>/dev/null || echo "")
if echo "${ISSUER}" | grep -qiE 'lets encrypt|let.s encrypt'; then
    pass "TLS certificate: ${ISSUER}"
elif echo "${ISSUER}" | grep -qi 'TRAEFIK DEFAULT'; then
    fail "Still using Traefik default cert — wait or check Tailscale HTTPS enabled in admin"
else
    fail "Unexpected TLS issuer: ${ISSUER:-none}"
fi

echo ""
if $ok; then
    echo "=== Tailscale HTTPS OK ==="
    echo "  https://${HOST}"
    exit 0
else
    echo "=== Tailscale HTTPS incomplete ===" >&2
    exit 1
fi