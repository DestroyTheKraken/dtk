#!/usr/bin/env bash
# recover-ssh.sh — Emergency SSH recovery (missing /run/sshd or dead ssh.service)
#
# Run locally: sudo bash recover-ssh.sh

set -euo pipefail

log() { echo "[recover-ssh] $*"; }
die() { echo "[recover-ssh] ERROR: $*" >&2; exit 1; }

[[ "$(id -u)" -eq 0 ]] || die "Run with sudo"

log "Recovering SSH on $(hostname -s)..."

install -d -m 0755 -o root -g root /run/sshd
echo 'd /run/sshd 0755 root root -' > /etc/tmpfiles.d/sshd-smadp.conf

# Ensure drop-in exists
if [[ ! -f /etc/ssh/sshd_config.d/99-smadp-mesh.conf ]]; then
    cat > /etc/ssh/sshd_config.d/99-smadp-mesh.conf << 'EOF'
# SMADP Sovereign Mesh — reduce login delays
UseDNS no
LoginGraceTime 30
EOF
fi

sshd -t || die "sshd config invalid"

systemctl daemon-reload
systemctl unmask ssh.service 2>/dev/null || true
systemctl enable ssh.service
systemctl restart ssh.service

for i in $(seq 1 10); do
    ss -tlnp | grep -q ':22' && break
    sleep 0.5
    [[ $i -eq 10 ]] && die "port 22 not listening"
done

log "SSH recovered — port 22 listening"
systemctl status ssh.service --no-pager | head -6