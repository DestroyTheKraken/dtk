#!/usr/bin/env bash
# watcher.sh — Poll delegation incoming/ every 30s (DESIGN §8)
set -euo pipefail

BASE="${DELEGATION_BASE:-/opt/sovereign/delegation}"
INTERVAL="${DELEGATION_POLL_SEC:-30}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROCESSOR="${SCRIPT_DIR}/processor.sh"

log() { echo "[delegation-watcher $(date -Iseconds)] $*"; }

[[ -x "${PROCESSOR}" ]] || { echo "Missing processor: ${PROCESSOR}" >&2; exit 1; }
[[ -d "${BASE}/incoming" ]] || { echo "Missing ${BASE}/incoming" >&2; exit 1; }

log "Watching ${BASE}/incoming every ${INTERVAL}s on $(hostname -s)"

while true; do
    shopt -s nullglob
    for task in "${BASE}/incoming/"*.json; do
        "${PROCESSOR}" "${task}" || true
    done
    shopt -u nullglob
    sleep "${INTERVAL}"
done