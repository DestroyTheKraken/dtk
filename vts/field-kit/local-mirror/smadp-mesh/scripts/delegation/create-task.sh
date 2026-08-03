#!/usr/bin/env bash
# create-task.sh — Create delegation task on target node (run from um690)
#
# Usage:
#   bash scripts/delegation/create-task.sh --target node1 --title "Test" \
#     --command "hostname" --verify "true"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PHASE0_DIR="$(dirname "${SCRIPT_DIR}")/phase0"
SSH_WORKER="${PHASE0_DIR}/ssh-worker.sh"
SOURCE="$(hostname -s)"
TARGET=""
TITLE=""
COMMAND=""
VERIFY=""
TIMEOUT_SEC=3600
RETRIES=2
NOTIFY="nextcloud://reports/delegation/"

usage() {
    cat <<'EOF'
Usage: create-task.sh --target NODE --title TEXT --command CMD [--verify CMD]
       [--timeout SEC] [--retries N] [--notify URI]
EOF
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target) TARGET="$2"; shift 2 ;;
        --title) TITLE="$2"; shift 2 ;;
        --command) COMMAND="$2"; shift 2 ;;
        --verify) VERIFY="$2"; shift 2 ;;
        --timeout) TIMEOUT_SEC="$2"; shift 2 ;;
        --retries) RETRIES="$2"; shift 2 ;;
        --notify) NOTIFY="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "Unknown arg: $1" >&2; usage ;;
    esac
done

[[ -n "${TARGET}" && -n "${TITLE}" && -n "${COMMAND}" ]] || usage
[[ "${SOURCE}" == "um690" ]] || { echo "Run from um690 (control plane)" >&2; exit 1; }
[[ -x "${SSH_WORKER}" ]] || { echo "Missing ${SSH_WORKER}" >&2; exit 1; }

TASK_ID=$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid)
CREATED=$(date -Iseconds)
BASENAME="${TASK_ID}.json"
LOCAL="/tmp/${BASENAME}"

jq -n \
    --arg id "${TASK_ID}" \
    --arg created "${CREATED}" \
    --arg source "${SOURCE}" \
    --arg target "${TARGET}" \
    --arg title "${TITLE}" \
    --arg command "${COMMAND}" \
    --arg verify "${VERIFY}" \
    --argjson timeout_sec "${TIMEOUT_SEC}" \
    --argjson retries "${RETRIES}" \
    --arg notify "${NOTIFY}" \
    '{
      id: $id,
      version: "1.0",
      created: $created,
      source: $source,
      target: $target,
      title: $title,
      command: $command,
      verify: $verify,
      timeout_sec: $timeout_sec,
      retries: $retries,
      notify: $notify
    }' > "${LOCAL}"

HOST=$(bash "${SSH_WORKER}" "${TARGET}" resolve)
REMOTE="/opt/sovereign/delegation/incoming/${BASENAME}"

scp -o BatchMode=yes -o ConnectTimeout=20 "${LOCAL}" "kraken@${HOST}:${REMOTE}.partial"
ssh -o BatchMode=yes -o ConnectTimeout=20 "kraken@${HOST}" "mv '${REMOTE}.partial' '${REMOTE}'"

rm -f "${LOCAL}"
echo "Task ${TASK_ID} → ${TARGET}:${REMOTE}"
echo "  title: ${TITLE}"