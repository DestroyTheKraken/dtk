#!/usr/bin/env bash
# verify-phase0.sh — Verify Phase 0 acceptance criteria on current node
set -euo pipefail

HOSTNAME=$(hostname -s)
ok=true
pass() { echo "  PASS: $*"; }
fail() { echo "  FAIL: $*" >&2; ok=false; }

echo "=== Phase 0 Verification (${HOSTNAME}) ==="

# UFW (no sudo required — checks config + systemd)
if grep -q '^ENABLED=yes' /etc/ufw/ufw.conf 2>/dev/null \
    && systemctl is-active ufw &>/dev/null; then
    pass "UFW active"
else
    fail "UFW not active (run: sudo bash setup-ufw.sh)"
fi

# Grok CLI
if command -v grok &>/dev/null; then
    pass "Grok CLI: $(grok --version 2>/dev/null | head -1)"
else
    if [[ -x "${HOME}/.grok/bin/grok" ]]; then
        pass "Grok CLI at ~/.grok/bin/grok (add to PATH)"
    else
        fail "Grok CLI not installed"
    fi
fi

# Delegation dirs
for subdir in incoming processing completed failed; do
    if [[ -d "/opt/sovereign/delegation/${subdir}" ]]; then
        pass "/opt/sovereign/delegation/${subdir}"
    else
        fail "/opt/sovereign/delegation/${subdir} missing"
    fi
done

# NAS (um690 only)
if [[ "${HOSTNAME}" == "um690" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if bash "${SCRIPT_DIR}/verify-nas-mount.sh" &>/dev/null; then
        pass "NAS mount"
    else
        fail "NAS mount"
    fi
fi

echo ""
if $ok; then
    echo "=== Phase 0 checks passed on ${HOSTNAME} ==="
    exit 0
else
    echo "=== Phase 0 incomplete on ${HOSTNAME} ===" >&2
    exit 1
fi