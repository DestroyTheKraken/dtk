#!/usr/bin/env bash
# verify-phase5.sh — Phase 5 operations acceptance checks
set -euo pipefail

REPORT_DIR="/mnt/systems_admin/reports"
ENV_FILE="${SOVEREIGN_RESTIC_ENV:-${HOME}/.config/sovereign/restic.env}"
CRON_FILE="/etc/cron.d/smadp-phase5"

ok=true
pass() { echo "  PASS: $*"; }
fail() { echo "  FAIL: $*" >&2; ok=false; }

echo "=== Phase 5 Operations ($(hostname -s)) ==="

mountpoint -q /mnt/systems_admin && pass "BTRFS /mnt/systems_admin mounted" \
    || fail "/mnt/systems_admin not mounted"

if [[ -f "${ENV_FILE}" ]]; then
    pass "restic.env exists"
    # shellcheck disable=SC1090
    source "${ENV_FILE}"
    if restic snapshots &>/dev/null; then
        pass "restic repo accessible"
    else
        fail "restic repo not accessible — run init-restic-repo.sh"
    fi
else
    fail "restic.env missing — run: sudo bash scripts/backup/init-restic-repo.sh"
fi

if [[ -x "${HOME}/SovereignAid/scripts/phase5/daily-health-report.sh" ]]; then
    pass "daily-health-report.sh executable"
else
    fail "daily-health-report.sh missing"
fi

TODAY=$(date +%Y-%m-%d)
if [[ -f "${REPORT_DIR}/smadp-health-${TODAY}.md" ]]; then
    pass "Today's report on BTRFS (${REPORT_DIR})"
else
    fail "No report for ${TODAY} — run: bash scripts/phase5/daily-health-report.sh"
fi

if [[ -f "${CRON_FILE}" ]] && grep -q 'daily-health-report' "${CRON_FILE}"; then
    pass "cron.d smadp-phase5 installed"
else
    fail "Phase 5 cron missing — run: sudo bash scripts/phase5/install-phase5-cron.sh"
fi

echo ""
if $ok; then
    echo "=== Phase 5 Operations OK ==="
    exit 0
else
    echo "=== Phase 5 Operations incomplete ===" >&2
    exit 1
fi