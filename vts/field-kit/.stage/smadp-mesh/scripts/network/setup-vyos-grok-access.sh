#!/usr/bin/env bash
# setup-vyos-grok-access.sh — Configure um690 for GrokOS VyOS network admin
#
# Run on um690: bash ~/SovereignAid/scripts/network/setup-vyos-grok-access.sh
#
# After this script: apply vyos-enable-grok-mgmt.conf on VyOS (see printed steps).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${HOME}/SovereignAid"
SSH_DIR="${HOME}/.ssh"
VYOS_KEY="${SSH_DIR}/id_ed25519_vyos"
ROUTER_HOSTS=(router router-lab router-home)

log() { echo "[vyos-setup] $*"; }

# Dedicated key for router (optional but recommended)
if [[ ! -f "${VYOS_KEY}" ]]; then
    log "Generating router SSH key: ${VYOS_KEY}"
    ssh-keygen -t ed25519 -f "${VYOS_KEY}" -N "" -C "grokos-vyos-um690"
fi

PUBKEY=$(cat "${VYOS_KEY}.pub")
KEY_BLOB=$(awk '{print $2}' "${VYOS_KEY}.pub")
log "Router public key: ${PUBKEY}"
log "VyOS key blob (paste this part only): ${KEY_BLOB}"

# Personalized VyOS config with key blob only (VyOS rejects full ssh-ed25519 line)
VYOS_CONF_OUT="${REPO}/scripts/network/vyos-enable-grok-mgmt.generated.conf"
sed "s|GROK_SSH_KEY_BLOB_ONLY|${KEY_BLOB}|" \
    "${SCRIPT_DIR}/vyos-enable-grok-mgmt.conf" > "${VYOS_CONF_OUT}"
chmod 600 "${VYOS_CONF_OUT}"
log "Wrote ${VYOS_CONF_OUT}"

# SSH config block
MARKER_BEGIN="# >>> GrokOS VyOS router >>>"
MARKER_END="# <<< GrokOS VyOS router <<<"
CONFIG="${SSH_DIR}/config"

if [[ -f "${CONFIG}" ]] && grep -q "GrokOS VyOS router" "${CONFIG}" 2>/dev/null; then
    log "SSH config already has GrokOS VyOS section"
else
    cat >> "${CONFIG}" << EOF

${MARKER_BEGIN}
Host router router-home
    HostName 192.168.10.1
    User vyos
    IdentityFile ${VYOS_KEY}
    IdentitiesOnly yes
    ConnectTimeout 10
    StrictHostKeyChecking accept-new

Host router-lab
    HostName 192.168.20.1
    User vyos
    IdentityFile ${VYOS_KEY}
    IdentitiesOnly yes
    ConnectTimeout 10
    StrictHostKeyChecking accept-new
${MARKER_END}
EOF
    chmod 600 "${CONFIG}"
    log "Appended VyOS hosts to ~/.ssh/config (router, router-lab, router-home)"
fi

# Local bin: router command
install -d "${HOME}/.local/bin"
install -m 755 "${SCRIPT_DIR}/router" "${HOME}/.local/bin/router"
log "Installed ~/.local/bin/router"

# Secrets hint (do not store VyOS password in repo)
SECRETS_DIR="${HOME}/.config/sovereign"
install -d -m 700 "${SECRETS_DIR}"
if [[ ! -f "${SECRETS_DIR}/vyos.env" ]]; then
    cat > "${SECRETS_DIR}/vyos.env" << 'EOF'
# VyOS credentials — local only, never commit
# VYOS_USER=vyos
# VYOS_HOST=192.168.10.1
# VYOS_PASSWORD=   # only if key auth not yet configured
EOF
    chmod 600 "${SECRETS_DIR}/vyos.env"
    log "Created ${SECRETS_DIR}/vyos.env (edit if needed)"
fi

echo ""
echo "=== Next: enable access on VyOS ==="
echo ""
echo "1. Open step-by-step guide:"
echo "   less ~/SovereignAid/scripts/network/VYOS-SETUP-GUIDE.md"
echo ""
echo "2. Phase 1 only (SSH): paste vyos-phase1-ssh-only.conf on VyOS console"
echo "   cat ~/SovereignAid/scripts/network/vyos-phase1-ssh-only.conf"
echo ""
echo "3. Verify from um690:"
echo "   bash ${SCRIPT_DIR}/vyos-verify-access.sh"
echo "   bash ${SCRIPT_DIR}/vyos-audit.sh"
echo ""