#!/usr/bin/env bash
# ssh-worker.sh — Resolve worker SSH target (LAN first, Tailscale fallback, retries)
#
# Usage:
#   eval "$(bash ssh-worker.sh node1)"   # sets SSH_WORKER_HOST
#   bash ssh-worker.sh node1 scp        # prints best host for scp/ssh
#   bash ssh-worker.sh node1 probe      # test connectivity, exit 0/1
#   bash ssh-worker.sh node1 recover    # attempt recover-node1-ssh.sh via any path

set -euo pipefail

WORKER="${1:?worker name required (node1|node2)}"
MODE="${2:-resolve}"

declare -A LAN_IPS=([node1]=192.168.20.101 [node2]=192.168.20.102)
declare -A TS_HOSTS=([node1]="node1-ts 100.69.243.112" [node2]="node2-ts 100.82.68.92")

[[ -n "${LAN_IPS[$WORKER]:-}" ]] || { echo "Unknown worker: ${WORKER}" >&2; exit 1; }

CANDIDATES=("${WORKER}" ${TS_HOSTS[$WORKER]})
LAN_IP="${LAN_IPS[$WORKER]}"
SSH_OPTS=(-o BatchMode=yes -o ConnectTimeout=8 -o GSSAPIAuthentication=no)

probe_host() {
    local host=$1
    ssh "${SSH_OPTS[@]}" "kraken@${host}" 'echo ok' &>/dev/null
}

probe_lan_port() {
    nc -zv -w 3 "${LAN_IP}" 22 &>/dev/null
}

recover_node1() {
    [[ "${WORKER}" == "node1" ]] || return 1
    local host
    for host in "${CANDIDATES[@]}"; do
        if ssh "${SSH_OPTS[@]}" "kraken@${host}" \
            'sudo bash ~/SovereignAid/scripts/phase0/recover-node1-ssh.sh' &>/dev/null; then
            sleep 2
            probe_lan_port && return 0
            probe_host "${WORKER}" && return 0
        fi
    done
    return 1
}

resolve_host() {
    local host attempt
    for attempt in 1 2 3 4 5; do
        for host in "${CANDIDATES[@]}"; do
            if probe_host "${host}"; then
                echo "${host}"
                return 0
            fi
        done
        [[ "${WORKER}" == "node1" && "${attempt}" -eq 2 ]] && recover_node1 || true
        sleep 3
    done
    return 1
}

case "${MODE}" in
    resolve|scp|ssh)
        HOST=$(resolve_host) || { echo "Cannot reach ${WORKER} (tried: ${CANDIDATES[*]})" >&2; exit 1; }
        if [[ "${HOST}" != "${WORKER}" ]]; then
            echo "[ssh-worker] ${WORKER}: using fallback ${HOST}" >&2
        fi
        echo "${HOST}"
        ;;
    probe)
        resolve_host >/dev/null
        ;;
    recover)
        recover_node1
        ;;
    export)
        HOST=$(resolve_host) || exit 1
        echo "SSH_WORKER_HOST=${HOST}"
        ;;
    *)
        echo "Unknown mode: ${MODE}" >&2
        exit 1
        ;;
esac