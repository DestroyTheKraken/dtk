#!/usr/bin/env bash
# recover-node1-ssh.sh — Emergency SSH recovery for node1
#
# Run LOCALLY on node1 console (SSH is down):
#   sudo bash recover-node1-ssh.sh
#
# Or copy to USB and run on node1 if no console access.

set -euo pipefail

log() { echo "[recover-ssh] $*"; }
die() { echo "[recover-ssh] ERROR: $*" >&2; exit 1; }

[[ "$(id -u)" -eq 0 ]] || die "Run with sudo"
[[ "$(hostname -s)" == "node1" ]] || log "WARNING: not running on node1 (hostname=$(hostname -s))"

log "Recovering SSH on node1..."

install -d -m 0755 -o root -g root /run/sshd
echo 'd /run/sshd 0755 root root -' > /etc/tmpfiles.d/sshd-smadp.conf

# Write sshd drop-in (no GSSAPIAuthentication — deprecated in sshd on some versions)
cat > /etc/ssh/sshd_config.d/99-smadp-mesh.conf << 'EOF'
# SMADP Sovereign Mesh — reduce login delays
UseDNS no
LoginGraceTime 30
EOF

sshd -t || die "sshd config invalid"

systemctl daemon-reload

# Start persistent service FIRST
systemctl unmask ssh.service 2>/dev/null || true
systemctl enable ssh.service
systemctl start ssh.service

for i in $(seq 1 10); do
    ss -tlnp | grep -q ':22' && break
    sleep 0.5
    [[ $i -eq 10 ]] && die "sshd failed to bind port 22"
done
log "sshd listening on port 22"

# Remove socket activation
systemctl stop ssh.socket 2>/dev/null || true
systemctl disable ssh.socket 2>/dev/null || true
systemctl mask ssh.socket 2>/dev/null || true

install -d -m 0755 -o root -g root /run/sshd
systemctl restart ssh.service

log "Recovery complete"
systemctl status ssh.service --no-pager | head -8
ss -tlnp | grep :22
log "Test from um690: ssh kraken@node1"