#!/usr/bin/env bash
# setup-ufw.sh — Tailscale-friendly UFW for SMADP cluster nodes
#
# Allows: SSH (22), Tailscale (tailscale0), k3s API (6443) on control plane only.
# Default deny incoming; allow all outgoing.
#
# Run on EACH node: sudo bash setup-ufw.sh
# Verify: sudo ufw status verbose

set -euo pipefail

log() { echo "[setup-ufw] $*"; }
die() { echo "[setup-ufw] ERROR: $*" >&2; exit 1; }

[[ "$(id -u)" -eq 0 ]] || die "Run with sudo"

HOSTNAME=$(hostname -s)
log "Configuring UFW on ${HOSTNAME}"

# Reset to known baseline (non-interactive)
ufw --force reset

ufw default deny incoming
ufw default allow outgoing

# SSH — LAN and Tailscale
ufw allow OpenSSH comment 'SSH'

# Tailscale mesh — allow all traffic on tailscale0
ufw allow in on tailscale0 comment 'Tailscale mesh'

# k3s API — control plane only (agents connect outbound)
if [[ "${HOSTNAME}" == "um690" ]]; then
    ufw allow 6443/tcp comment 'k3s API server'
fi

# k3s flannel VXLAN + kubelet (workers + server)
ufw allow 8472/udp comment 'k3s flannel VXLAN'
ufw allow 10250/tcp comment 'kubelet'

# Longhorn manager/webhook (Phase 1)
ufw allow 9500/tcp comment 'Longhorn manager'
ufw allow 9501/tcp comment 'Longhorn conversion webhook'
ufw allow 9502/tcp comment 'Longhorn admission webhook'
ufw allow 9503/tcp comment 'Longhorn recovery backend'

ufw --force enable

log "UFW active on ${HOSTNAME}"
ufw status verbose