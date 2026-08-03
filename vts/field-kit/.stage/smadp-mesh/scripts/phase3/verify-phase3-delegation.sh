#!/usr/bin/env bash
# verify-phase3-delegation.sh — Phase 3 delegation acceptance checks
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PHASE0_DIR="${REPO}/scripts/phase0"
SSH_WORKER="${PHASE0_DIR}/ssh-worker.sh"
CREATE_TASK="${REPO}/scripts/delegation/create-task.sh"
HOSTNAME="$(hostname -s)"

ok=true
pass() { echo "  PASS: $*"; }
fail() { echo "  FAIL: $*" >&2; ok=false; }

check_local() {
    local node=$1

    if systemctl is-active --quiet sovereign-delegation-watcher.service 2>/dev/null; then
        pass "${node}: sovereign-delegation-watcher active"
    else
        fail "${node}: watcher not active"
    fi

    if export PATH="${HOME}/.grok/bin:${PATH}" && grok --version &>/dev/null; then
        ver=$(export PATH="${HOME}/.grok/bin:${PATH}"; grok --version 2>/dev/null)
        pass "${node}: Grok CLI (${ver})"
    else
        fail "${node}: Grok CLI missing — run install-grok-cli-workers.sh"
    fi

    for d in incoming processing completed failed; do
        if [[ -d "/opt/sovereign/delegation/${d}" ]]; then
            pass "${node}: /opt/sovereign/delegation/${d}"
        else
            fail "${node}: missing delegation/${d}"
        fi
    done

    if [[ -w /opt/sovereign/delegation/incoming ]]; then
        pass "${node}: incoming writable by $(whoami)"
    else
        fail "${node}: incoming not writable — run: sudo bash scripts/phase3/fix-delegation-permissions.sh"
    fi
}

check_remote() {
    local node=$1
    local host=$2

    if ssh -o BatchMode=yes -o ConnectTimeout=15 "kraken@${host}" \
        'systemctl is-active --quiet sovereign-delegation-watcher.service'; then
        pass "${node}: sovereign-delegation-watcher active"
    else
        fail "${node}: watcher not active"
    fi

    if ssh -o BatchMode=yes "kraken@${host}" \
        'export PATH="$HOME/.grok/bin:$PATH"; grok --version' &>/dev/null; then
        ver=$(ssh -o BatchMode=yes "kraken@${host}" \
            'export PATH="$HOME/.grok/bin:$PATH"; grok --version' 2>/dev/null)
        pass "${node}: Grok CLI (${ver})"
    else
        fail "${node}: Grok CLI missing — run install-grok-cli-workers.sh"
    fi

    for d in incoming processing completed failed; do
        if ssh -o BatchMode=yes "kraken@${host}" "test -d /opt/sovereign/delegation/${d}"; then
            pass "${node}: /opt/sovereign/delegation/${d}"
        else
            fail "${node}: missing delegation/${d}"
        fi
    done

    if ssh -o BatchMode=yes "kraken@${host}" 'test -w /opt/sovereign/delegation/incoming'; then
        pass "${node}: incoming writable by kraken"
    else
        fail "${node}: incoming not writable — run fix-delegation-permissions.sh"
    fi
}

echo "=== Phase 3 Delegation Verification (${HOSTNAME}) ==="

[[ -x "${CREATE_TASK}" ]] || fail "create-task.sh missing"
[[ -x "${CREATE_TASK}" ]] && pass "scripts/delegation/create-task.sh"

if [[ "${HOSTNAME}" == "um690" ]]; then
    check_local um690
    for worker in node1 node2; do
        host=$(bash "${SSH_WORKER}" "${worker}" resolve 2>/dev/null || true)
        [[ -n "${host}" ]] && check_remote "${worker}" "${host}" || fail "Cannot resolve ${worker}"
    done

    MARKER="smadp-phase3-verify-$(date +%s)"
    task_out=$(bash "${CREATE_TASK}" \
        --target node1 \
        --title "Phase 3 e2e verify" \
        --command "echo '${MARKER}' > /tmp/${MARKER}.txt" \
        --verify "grep -q '${MARKER}' /tmp/${MARKER}.txt" \
        --timeout 60 \
        --retries 1 2>&1) || task_out=""

    TASK_ID=$(echo "${task_out}" | sed -n 's/^Task \([^ ]*\) →.*/\1/p')
    if [[ -n "${TASK_ID}" ]]; then
        pass "create-task dispatched to node1 (${TASK_ID})"
    else
        fail "create-task failed: ${task_out:-unknown error}"
        TASK_ID=""
    fi

    if [[ -n "${TASK_ID}" ]]; then
        host=$(bash "${SSH_WORKER}" node1 resolve)
        found=false
        for _ in $(seq 1 20); do
            if ssh -o BatchMode=yes "kraken@${host}" \
                "test -f /opt/sovereign/delegation/completed/${TASK_ID}.result.json" \
                && ssh -o BatchMode=yes "kraken@${host}" \
                "jq -e '.status == \"completed\"' /opt/sovereign/delegation/completed/${TASK_ID}.result.json" &>/dev/null; then
                found=true
                break
            fi
            sleep 3
        done
        if $found; then
            pass "e2e task completed on node1"
        else
            fail "e2e task not completed on node1 after 60s (id=${TASK_ID})"
        fi
    fi
else
    check_local "${HOSTNAME}"
fi

echo ""
if $ok; then
    echo "=== Phase 3 Delegation OK ==="
    exit 0
else
    echo "=== Phase 3 Delegation incomplete ===" >&2
    exit 1
fi