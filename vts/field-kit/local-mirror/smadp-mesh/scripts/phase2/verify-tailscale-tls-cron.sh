#!/usr/bin/env bash
# verify-tailscale-tls-cron.sh — Tailscale TLS cron + renewal readiness
set -euo pipefail

HOST="um690.taile52ad9.ts.net"
CRON_FILE="/etc/cron.d/smadp-tailscale-tls-renew"
RENEW_SCRIPT="$HOME/SovereignAid/scripts/phase2/renew-tailscale-tls-if-needed.sh"

ok=true
pass() { echo "  PASS: $*"; }
fail() { echo "  FAIL: $*" >&2; ok=false; }

echo "=== Tailscale TLS Cron ($(hostname -s)) ==="

if [[ -f "${CRON_FILE}" ]] && grep -q 'renew-tailscale-tls-if-needed' "${CRON_FILE}"; then
    pass "cron.d smadp-tailscale-tls-renew installed"
else
    fail "cron missing — run: sudo bash scripts/phase2/install-tailscale-tls-cron.sh"
fi

if [[ -x "${RENEW_SCRIPT}" ]]; then
    pass "renew-tailscale-tls-if-needed.sh executable"
else
    fail "renew script missing or not executable"
fi

end=$(echo | openssl s_client -connect "${HOST}:443" -servername "${HOST}" 2>/dev/null \
    | openssl x509 -noout -enddate 2>/dev/null | sed 's/notAfter=//')
if [[ -n "${end}" ]]; then
    days=$(( ($(date -d "${end}" +%s) - $(date +%s)) / 86400 ))
    pass "Certificate valid ${days} more day(s) (expires ${end})"
else
    fail "Cannot read certificate expiry"
fi

echo ""
if $ok; then
    echo "=== Tailscale TLS cron OK ==="
    exit 0
else
    echo "=== Tailscale TLS cron incomplete ===" >&2
    exit 1
fi