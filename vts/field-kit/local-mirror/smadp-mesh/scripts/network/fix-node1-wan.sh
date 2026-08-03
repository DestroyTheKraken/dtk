#!/usr/bin/env bash
# fix-node1-wan.sh — Fix intermittent slow WAN on node1 (broken IPv6 + DNS v6-first)
#
# Symptom: curl https://x.ai takes ~10s on node1 (IPv6 hang) vs ~0.1s on um690/node2
# Run on node1: sudo bash fix-node1-wan.sh

set -euo pipefail

log() { echo "[fix-node1-wan] $*"; }
die() { echo "[fix-node1-wan] ERROR: $*" >&2; exit 1; }

[[ "$(id -u)" -eq 0 ]] || die "Run with sudo"
[[ "$(hostname -s)" == "node1" ]] || die "Run on node1 only"

log "Applying IPv4-prefer + disable IPv6 on eno1 (no WAN v6 from VyOS)"

# Prefer IPv4 in getaddrinfo (Happy Eyeballs)
cat > /etc/gai.conf << 'EOF'
# SMADP — prefer IPv4; VyOS does not provide working IPv6 WAN to lab subnet
precedence ::ffff:0:0/96  100
precedence ::1/128          50
precedence ::/0             10
EOF

# Disable IPv6 on lab NIC (keep tailscale0 v6 if needed)
cat > /etc/sysctl.d/99-smadp-node1-ipv6.conf << 'EOF'
net.ipv6.conf.eno1.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 0
EOF
sysctl --system >/dev/null

# Faster DNS — match um690 (Cloudflare), drop broken v6 paths
mkdir -p /etc/systemd/resolved.conf.d
cat > /etc/systemd/resolved.conf.d/smadp-dns.conf << 'EOF'
[Resolve]
DNS=1.1.1.1 1.0.0.1
FallbackDNS=
DNSOverTLS=opportunistic
EOF
systemctl restart systemd-resolved

log "Verify:"
log "  curl -4 -w '%{time_total}s\n' -o /dev/null -s https://x.ai/"
curl -4 -o /dev/null -s -w "  x.ai v4: %{time_total}s\n" --connect-timeout 10 https://x.ai/ || true
log "Done"