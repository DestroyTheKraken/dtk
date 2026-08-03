#!/usr/bin/env bash
# verify-ssh-mesh.sh — Test SSH connectivity across SMADP cluster
set -euo pipefail

HOSTNAME=$(hostname -s)
# When run with sudo, check the invoking user's config (not /root/.ssh)
VERIFY_USER="${SUDO_USER:-$USER}"
VERIFY_HOME=$(getent passwd "${VERIFY_USER}" | cut -d: -f6)
SSH_CONFIG="${VERIFY_HOME}/.ssh/config"
SSH_OPTS=(-o BatchMode=yes -o ConnectTimeout=10 -o GSSAPIAuthentication=no)

# Run ssh as the real user when script is invoked via sudo (root has no keys/config)
run_ssh() {
    if [[ $(id -u) -eq 0 && -n "${SUDO_USER:-}" ]]; then
        sudo -u "${VERIFY_USER}" -H ssh "$@"
    else
        ssh "$@"
    fi
}

ok=true
pass() { echo "  PASS: $*"; }
fail() { echo "  FAIL: $*" >&2; ok=false; }
warn() { echo "  WARN: $*"; }

echo "=== SSH Mesh Verification (from ${HOSTNAME}, user ${VERIFY_USER}) ==="

# Local ssh config (check real user even when script run via sudo)
if [[ -f "${SSH_CONFIG}" ]] && grep -q "SMADP Sovereign Mesh" "${SSH_CONFIG}" 2>/dev/null; then
    pass "~/.ssh/config installed (${VERIFY_USER})"
else
    fail "~/.ssh/config missing SMADP section for ${VERIFY_USER}"
fi

# sshd drop-in
if [[ -f /etc/ssh/sshd_config.d/99-smadp-mesh.conf ]]; then
    pass "sshd drop-in installed"
else
    fail "sshd drop-in missing — run setup-ssh-mesh.sh"
fi

# client drop-in
if [[ -f /etc/ssh/ssh_config.d/99-smadp-mesh.conf ]]; then
    pass "ssh client drop-in installed"
else
    fail "ssh client drop-in missing — run setup-ssh-mesh.sh"
fi

# ssh.service state
if systemctl is-enabled ssh.service &>/dev/null; then
    pass "ssh.service enabled"
else
    fail "ssh.service not enabled"
fi

if systemctl is-active ssh.service &>/dev/null; then
    pass "ssh.service active"
else
    fail "ssh.service not active"
fi

# ssh.socket should be disabled or masked
SOCKET_STATE=$(systemctl is-enabled ssh.socket 2>&1 | head -1 | tr -d '[:space:]' || true)
[[ -z "${SOCKET_STATE}" ]] && SOCKET_STATE="disabled"
case "${SOCKET_STATE}" in
    masked)
        pass "ssh.socket masked" ;;
    disabled|disabled-static|indirect|generated|transient)
        pass "ssh.socket disabled (${SOCKET_STATE})" ;;
    enabled|static|linked)
        fail "ssh.socket still enabled (${SOCKET_STATE}) — run setup-ssh-mesh.sh" ;;
    *)
        pass "ssh.socket not enabled (${SOCKET_STATE})" ;;
esac

if systemctl is-active ssh.socket &>/dev/null; then
    fail "ssh.socket still active (conflicts with ssh.service)"
fi

# Port 22 local
if ss -tlnp 2>/dev/null | grep -q ':22'; then
    pass "local port 22 listening"
else
    fail "local port 22 not listening"
fi

# GSSAPI check (use real user's ssh config)
if run_ssh -G node1 2>/dev/null | grep -qi 'gssapiauthentication yes'; then
    fail "GSSAPI still enabled for node1"
else
    pass "GSSAPI disabled for node1"
fi

# Connectivity matrix
echo ""
echo "=== Connectivity (LAN paths) ==="
declare -A LAN_IPS=(
    [um690]=192.168.20.100
    [node1]=192.168.20.101
    [node2]=192.168.20.102
)

for host in um690 node1 node2; do
    [[ "${host}" == "${HOSTNAME}" ]] && continue
    ip="${LAN_IPS[$host]}"
    start=$(date +%s%N)
    if run_ssh "${SSH_OPTS[@]}" "kraken@${host}" 'echo ok' &>/dev/null; then
        end=$(date +%s%N)
        ms=$(( (end - start) / 1000000 ))
        pass "${HOSTNAME} -> ${host} (${ip}) ${ms}ms"
    else
        fail "${HOSTNAME} -> ${host} (${ip})"
    fi
done

# Port 22 reachability
echo ""
echo "=== Port 22 probes ==="
for host in um690 node1 node2; do
    [[ "${host}" == "${HOSTNAME}" ]] && continue
    ip="${LAN_IPS[$host]}"
    if nc -zv -w 3 "${ip}" 22 &>/dev/null; then
        pass "tcp://${ip}:22 open"
    else
        fail "tcp://${ip}:22 closed/refused"
    fi
done

echo ""
if $ok; then
    echo "=== All SSH mesh checks passed ==="
    exit 0
else
    echo "=== Some checks failed ===" >&2
    exit 1
fi