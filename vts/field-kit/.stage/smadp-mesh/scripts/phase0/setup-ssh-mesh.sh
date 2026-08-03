#!/usr/bin/env bash
# setup-ssh-mesh.sh — Fix SSH mesh delays and intermittent hangs on SMADP cluster
#
# SAFETY: Starts ssh.service BEFORE stopping ssh.socket to avoid losing SSH access.
#         Creates /run/sshd (required after disabling ssh.socket).
#
# Requires: sudo on each node
# Run on EACH node: sudo bash setup-ssh-mesh.sh

set -euo pipefail

log() { echo "[setup-ssh] $*"; }
die() { echo "[setup-ssh] ERROR: $*" >&2; exit 1; }

[[ "$(id -u)" -eq 0 ]] || die "Run with sudo"

HOSTNAME=$(hostname -s)
log "Configuring SSH mesh on ${HOSTNAME}"

# --- Privilege separation directory (ssh.socket used to manage this) ---
ensure_sshd_run_dir() {
    install -d -m 0755 -o root -g root /run/sshd
    log "/run/sshd ready"
}

# Persist /run/sshd across reboots
TMPFILES="/etc/tmpfiles.d/sshd-smadp.conf"
echo 'd /run/sshd 0755 root root -' > "${TMPFILES}"
log "Wrote ${TMPFILES}"

ensure_sshd_run_dir

# --- sshd hardening drop-in ---
SSHD_DROPIN="/etc/ssh/sshd_config.d/99-smadp-mesh.conf"
cat > "${SSHD_DROPIN}" << 'EOF'
# SMADP Sovereign Mesh — reduce login delays
UseDNS no
LoginGraceTime 30
EOF
log "Wrote ${SSHD_DROPIN}"

# --- client defaults drop-in ---
SSH_DROPIN="/etc/ssh/ssh_config.d/99-smadp-mesh.conf"
cat > "${SSH_DROPIN}" << 'EOF'
# SMADP Sovereign Mesh — reduce connection delays
Host um690 control node1 node2 um690-ts node1-ts node2-ts
    GSSAPIAuthentication no
    ConnectTimeout 10
    ServerAliveInterval 30
    ServerAliveCountMax 3
    TCPKeepAlive yes
    IPQoS throughput
EOF
log "Wrote ${SSH_DROPIN}"

# --- Validate config BEFORE touching services ---
sshd -t || die "sshd config invalid — services not changed"
log "sshd config valid (pre-restart)"

systemctl daemon-reload
log "systemd daemon-reload complete"

# --- SAFE ORDER: start service FIRST, then remove socket ---
log "Enabling and starting ssh.service..."
systemctl enable ssh.service
systemctl start ssh.service

# Wait for port 22
for i in $(seq 1 10); do
    if ss -tlnp | grep -q ':22'; then
        log "sshd listening on port 22"
        break
    fi
    sleep 0.5
    [[ $i -eq 10 ]] && die "sshd not listening after start"
done

# Now safe to remove socket activation
if systemctl is-active ssh.socket &>/dev/null; then
    log "Stopping ssh.socket..."
    systemctl stop ssh.socket
fi
if systemctl is-enabled ssh.socket &>/dev/null; then
    log "Disabling and masking ssh.socket..."
    systemctl disable ssh.socket
    systemctl mask ssh.socket
fi

# ssh.socket removal deletes /run/sshd — recreate before validation
ensure_sshd_run_dir

# Restart service to ensure clean state after socket mask
systemctl restart ssh.service

for i in $(seq 1 10); do
    if ss -tlnp | grep -q ':22'; then
        break
    fi
    sleep 0.5
    [[ $i -eq 10 ]] && die "sshd not listening after restart"
done

# Final validation
sshd -t || die "sshd config invalid after restart"
systemctl is-active ssh.service &>/dev/null || die "ssh.service not active"
ss -tlnp | grep -q ':22' || die "port 22 not listening"

log "Done on ${HOSTNAME}"
log "  ssh.service: $(systemctl is-active ssh.service) / $(systemctl is-enabled ssh.service)"
log "  ssh.socket:  $(systemctl is-active ssh.socket 2>/dev/null || echo inactive) / $(systemctl is-enabled ssh.socket 2>/dev/null || echo disabled)"