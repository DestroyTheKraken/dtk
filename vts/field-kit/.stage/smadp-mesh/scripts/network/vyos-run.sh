#!/usr/bin/env bash
# vyos-run.sh — Run operational command(s) on VyOS via SSH
#
# Usage:
#   bash vyos-run.sh show version
#   bash vyos-run.sh "show dhcp leases"
#   bash vyos-run.sh --host router-lab show interfaces

set -euo pipefail

HOST="router-home"
SSH_OPTS=(-o BatchMode=yes -o ConnectTimeout=15 -o StrictHostKeyChecking=accept-new)
VYOS_OP="/opt/vyatta/bin/vyatta-op-cmd-wrapper"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --host)
            HOST="$2"
            shift 2
            ;;
        *)
            break
            ;;
    esac
done

[[ $# -gt 0 ]] || { echo "Usage: vyos-run.sh [--host router-home|router-lab] <vyos-command...>" >&2; exit 1; }

# VyOS rejects bare remote argv (Invalid command: [show]); use op-cmd wrapper
ssh "${SSH_OPTS[@]}" "${HOST}" "${VYOS_OP}" "$@"