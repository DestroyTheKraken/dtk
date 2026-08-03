#!/usr/bin/env bash
# processor.sh — Execute one delegation task JSON (DESIGN §8)
set -euo pipefail

TASK_FILE="${1:?task json path required}"
BASE="${DELEGATION_BASE:-/opt/sovereign/delegation}"
HOST="$(hostname -s)"
LOG_TAG="[delegation-processor]"

log() { echo "${LOG_TAG} $*"; }
die() { echo "${LOG_TAG} ERROR: $*" >&2; exit 1; }

command -v jq &>/dev/null || die "jq required — install: sudo apt install -y jq"

[[ -f "${TASK_FILE}" ]] || die "Task file not found: ${TASK_FILE}"

task_id=$(jq -r '.id // empty' "${TASK_FILE}")
target=$(jq -r '.target // empty' "${TASK_FILE}")
title=$(jq -r '.title // "untitled"' "${TASK_FILE}")
cmd=$(jq -r '.command // empty' "${TASK_FILE}")
verify_cmd=$(jq -r '.verify // empty' "${TASK_FILE}")
timeout_sec=$(jq -r '.timeout_sec // 3600' "${TASK_FILE}")
retries=$(jq -r '.retries // 0' "${TASK_FILE}")

[[ -n "${cmd}" ]] || die "Task ${task_id:-unknown}: missing command"

if [[ -n "${target}" && "${target}" != "${HOST}" ]]; then
    log "Skip ${task_id:-file}: target=${target} this=${HOST}"
    exit 0
fi

basename=$(basename "${TASK_FILE}")
processing="${BASE}/processing/${basename}"
completed_dir="${BASE}/completed"
failed_dir="${BASE}/failed"
stdout_file="${processing%.json}.stdout"
stderr_file="${processing%.json}.stderr"
result_file="${processing%.json}.result.json"

mkdir -p "${BASE}/processing" "${completed_dir}" "${failed_dir}"

# Atomic claim
if [[ "${TASK_FILE}" != "${processing}" ]]; then
    if ! mv -n "${TASK_FILE}" "${processing}" 2>/dev/null; then
        log "Already claimed: ${basename}"
        exit 0
    fi
    TASK_FILE="${processing}"
fi

log "Running ${title} (${task_id:-no-id}) on ${HOST}"

set +e
timeout "${timeout_sec}" bash -c "${cmd}" >"${stdout_file}" 2>"${stderr_file}"
cmd_exit=$?
set -e

verify_exit=0
if [[ -n "${verify_cmd}" ]]; then
    set +e
    timeout 120 bash -c "${verify_cmd}" >/dev/null 2>&1
    verify_exit=$?
    set -e
fi

finished=$(date -Iseconds)
status="failed"
if [[ ${cmd_exit} -eq 0 && ${verify_exit} -eq 0 ]]; then
    status="completed"
fi

jq -n \
    --arg id "${task_id}" \
    --arg finished "${finished}" \
    --arg status "${status}" \
    --argjson cmd_exit "${cmd_exit}" \
    --argjson verify_exit "${verify_exit}" \
    --argjson attempt "$(( retries >= 0 ? 1 : 1 ))" \
    --arg stdout_file "${stdout_file}" \
    --arg stderr_file "${stderr_file}" \
    '{
      task_id: $id,
      finished: $finished,
      status: $status,
      command_exit: $cmd_exit,
      verify_exit: $verify_exit,
      attempt: $attempt,
      stdout_file: $stdout_file,
      stderr_file: $stderr_file
    }' > "${result_file}"

if [[ "${status}" == "completed" ]]; then
    mv "${processing}" "${completed_dir}/"
    mv "${stdout_file}" "${completed_dir}/" 2>/dev/null || true
    mv "${stderr_file}" "${completed_dir}/" 2>/dev/null || true
    mv "${result_file}" "${completed_dir}/"
    log "Completed ${task_id:-${basename}}"
    exit 0
fi

log "Failed ${task_id:-${basename}} cmd=${cmd_exit} verify=${verify_exit} retries_left=${retries}"

if [[ "${retries}" =~ ^[0-9]+$ ]] && (( retries > 0 )); then
    new_retries=$((retries - 1))
    jq --argjson r "${new_retries}" '.retries = $r' "${processing}" > "${BASE}/incoming/${basename}"
    rm -f "${processing}" "${stdout_file}" "${stderr_file}" "${result_file}"
    log "Re-queued ${basename} (${new_retries} retries left)"
    exit 1
fi

mv "${processing}" "${failed_dir}/"
mv "${stdout_file}" "${failed_dir}/" 2>/dev/null || true
mv "${stderr_file}" "${failed_dir}/" 2>/dev/null || true
mv "${result_file}" "${failed_dir}/"
exit 1