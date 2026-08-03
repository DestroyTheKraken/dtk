#!/usr/bin/env bash
# run-phase1.sh — Full Phase 1: k3s cluster + Longhorn + namespaces
#
# Run from um690 (interactive sudo): sudo bash ~/SovereignAid/scripts/phase1/run-phase1.sh
#
# node1 LAN SSH can flap — uses ssh-worker.sh (LAN → Tailscale fallback + recover)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PHASE0_DIR="$(dirname "${SCRIPT_DIR}")/phase0"
SSH_WORKER="${PHASE0_DIR}/ssh-worker.sh"
CURRENT=$(hostname -s)

[[ "$(id -u)" -eq 0 ]] || { echo "Run with: sudo bash $0" >&2; exit 1; }
[[ "${CURRENT}" == "um690" ]] || { echo "Run from um690" >&2; exit 1; }
[[ -x "${SSH_WORKER}" ]] || { echo "Missing ${SSH_WORKER}" >&2; exit 1; }

OWNER="${SUDO_USER:-kraken}"
SSH_OPTS=(-o BatchMode=yes -o ConnectTimeout=20 -o GSSAPIAuthentication=no)

log() { echo ""; echo "=== $* ==="; }
die() { echo "[phase1] ERROR: $*" >&2; exit 1; }

worker_host() {
    sudo -u "${OWNER}" -H bash "${SSH_WORKER}" "${1}" resolve
}

remote() {
    local worker=$1
    shift
    local host
    host=$(worker_host "${worker}") || die "Cannot SSH to ${worker}"
    sudo -u "${OWNER}" -H ssh "${SSH_OPTS[@]}" "kraken@${host}" "$@"
}

check_worker_sudo() {
    local worker=$1
    local host
    host=$(worker_host "${worker}") || die "Cannot SSH to ${worker}"
    if sudo -u "${OWNER}" -H ssh "${SSH_OPTS[@]}" "kraken@${host}" 'sudo -n true' 2>/dev/null; then
        return 0
    fi
    die "${worker}: passwordless sudo required. Run: bash ~/SovereignAid/scripts/phase1/bootstrap-worker-sudo.sh"
}

remote_scp_to() {
    local worker=$1
    local src=$2
    local dst=$3
    local host
    host=$(worker_host "${worker}") || die "Cannot SCP to ${worker}"
    sudo -u "${OWNER}" -H scp "${SSH_OPTS[@]}" "${src}" "kraken@${host}:${dst}"
}

# Deploy scripts to workers
log "Deploy phase1 + ssh-worker scripts to workers"
for worker in node1 node2; do
    remote "${worker}" 'mkdir -p ~/SovereignAid/scripts/phase1 ~/SovereignAid/scripts/phase0'
    remote_scp_to "${worker}" "${SCRIPT_DIR}"/*.sh \
        '~/SovereignAid/scripts/phase1/'
    remote_scp_to "${worker}" "${SCRIPT_DIR}/setup-worker-passwordless-sudo.sh" \
        '~/SovereignAid/scripts/phase1/' 2>/dev/null || true
    remote_scp_to "${worker}" "${PHASE0_DIR}/ssh-worker.sh" \
        '~/SovereignAid/scripts/phase0/'
    remote_scp_to "${worker}" "${PHASE0_DIR}/recover-node1-ssh.sh" \
        '~/SovereignAid/scripts/phase0/'
    remote "${worker}" 'chmod +x ~/SovereignAid/scripts/phase1/*.sh ~/SovereignAid/scripts/phase0/ssh-worker.sh ~/SovereignAid/scripts/phase0/recover-node1-ssh.sh'
    echo "  OK: ${worker} via $(worker_host "${worker}")"
done

# Preflight: workers need passwordless sudo for non-interactive SSH
log "Preflight: worker passwordless sudo"
for worker in node1 node2; do
    check_worker_sudo "${worker}"
    echo "  OK: ${worker}"
done

# 1. Dependencies on all nodes
log "k3s dependencies (all nodes)"
bash "${SCRIPT_DIR}/install-k3s-deps.sh"
for worker in node1 node2; do
    remote "${worker}" 'sudo bash ~/SovereignAid/scripts/phase1/install-k3s-deps.sh'
done

# 2. k3s server
log "k3s server (um690)"
bash "${SCRIPT_DIR}/install-k3s-server.sh"

# 3. Distribute token
install -d -m 0755 /opt/sovereign/k3s
cp /var/lib/rancher/k3s/server/node-token /opt/sovereign/k3s/node-token
chmod 0644 /opt/sovereign/k3s/node-token

for worker in node1 node2; do
    remote "${worker}" 'sudo mkdir -p /opt/sovereign/k3s'
    remote_scp_to "${worker}" /opt/sovereign/k3s/node-token /tmp/k3s-node-token
    remote "${worker}" 'sudo mv /tmp/k3s-node-token /opt/sovereign/k3s/node-token && sudo chmod 0644 /opt/sovereign/k3s/node-token'
done

# 4. k3s agents
log "k3s agents (node1, node2)"
for worker in node1 node2; do
    remote "${worker}" 'sudo bash ~/SovereignAid/scripts/phase1/install-k3s-agent.sh'
done

# Wait for nodes Ready
log "Waiting for nodes Ready"
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
for i in $(seq 1 36); do
    READY=$(k3s kubectl get nodes --no-headers 2>/dev/null | grep -c Ready || true)
    [[ "${READY}" -ge 3 ]] && break
    sleep 5
done
k3s kubectl get nodes -o wide

# 5. Longhorn + namespaces
log "Longhorn + namespaces"
bash "${SCRIPT_DIR}/deploy-longhorn.sh"
bash "${SCRIPT_DIR}/create-namespaces.sh"

# 6. Verify
log "Phase 1 verification"
sudo -u "${OWNER}" -H bash "${SCRIPT_DIR}/verify-phase1.sh" || true

echo ""
echo "Phase 1 complete. UI: kubectl port-forward -n longhorn-system svc/longhorn-frontend 8080:80"