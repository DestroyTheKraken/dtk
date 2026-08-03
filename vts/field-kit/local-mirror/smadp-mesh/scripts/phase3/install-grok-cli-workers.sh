#!/usr/bin/env bash
# install-grok-cli-workers.sh — Install Grok Build CLI on node1 + node2
#
# Run from um690: bash ~/SovereignAid/scripts/phase3/install-grok-cli-workers.sh
# Docs: https://docs.x.ai/build/overview

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PHASE0_DIR="$(dirname "${SCRIPT_DIR}")/phase0"
SSH_WORKER="${PHASE0_DIR}/ssh-worker.sh"
INSTALL_CMD='curl -fsSL https://x.ai/cli/install.sh | bash'

log() { echo "[grok-install] $*"; }
die() { echo "[grok-install] ERROR: $*" >&2; exit 1; }

[[ "$(hostname -s)" == "um690" ]] || die "Run from um690"
[[ -x "${SSH_WORKER}" ]] || die "Missing ${SSH_WORKER}"

install_on() {
    local worker=$1
    local host
    host=$(bash "${SSH_WORKER}" "${worker}" resolve) || die "Cannot reach ${worker}"

    if ssh -o BatchMode=yes -o ConnectTimeout=20 "kraken@${host}" \
        'export PATH="$HOME/.grok/bin:$PATH"; grok --version' &>/dev/null; then
        ver=$(ssh -o BatchMode=yes "kraken@${host}" \
            'export PATH="$HOME/.grok/bin:$PATH"; grok --version' 2>/dev/null)
        log "${worker}: already installed (${ver})"
        return 0
    fi

    log "${worker}: installing via x.ai/cli..."
    ssh -o BatchMode=yes -o ConnectTimeout=60 "kraken@${host}" \
        "bash -c '${INSTALL_CMD}'"

    ver=$(ssh -o BatchMode=yes "kraken@${host}" \
        'export PATH="$HOME/.grok/bin:$PATH"; grok --version' 2>/dev/null) \
        || die "${worker}: install failed"
    log "${worker}: ${ver}"
}

for worker in node1 node2; do
    install_on "${worker}"
done

log "Done. Workers need xAI auth: ssh node1 'grok' (interactive login once per node)"