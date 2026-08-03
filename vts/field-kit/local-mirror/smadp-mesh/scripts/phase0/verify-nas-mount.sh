#!/usr/bin/env bash
# verify-nas-mount.sh — Verify systems_admin NAS is correctly mounted (no sudo needed)
set -euo pipefail

UUID="59f59772-7098-43f2-ab85-3c0794931a14"
MOUNT_POINT="/mnt/systems_admin"
EXPECTED_DIRS=(Backups HICKMAN_ROOT Pictures batocera_management .snapshots)

ok=true

check() {
    if "$@"; then echo "  OK: $*"
    else echo "  FAIL: $*" >&2; ok=false; fi
}

echo "=== NAS Mount Verification ==="

# fstab entry
if grep -q "${UUID}" /etc/fstab 2>/dev/null; then
    echo "  OK: fstab contains UUID ${UUID}"
    grep "${UUID}" /etc/fstab
else
    echo "  FAIL: fstab missing UUID ${UUID}" >&2
    ok=false
fi

# mounted at correct path (mountpoint -q, not findmnt --target which matches parent /)
if mountpoint -q "${MOUNT_POINT}"; then
    SRC=$(findmnt -n -o SOURCE --target "${MOUNT_POINT}" 2>/dev/null || true)
    if [[ "${SRC}" == *"${UUID}"* || "${SRC}" == "/dev/sda1" ]]; then
        echo "  OK: BTRFS NAS mounted at ${MOUNT_POINT}"
        findmnt --target "${MOUNT_POINT}"
    else
        echo "  FAIL: ${MOUNT_POINT} is a mountpoint but source is ${SRC}, not NAS" >&2
        ok=false
    fi
else
    echo "  FAIL: not mounted at ${MOUNT_POINT}" >&2
    ALT=$(findmnt -n -o TARGET --source "/dev/disk/by-uuid/${UUID}" 2>/dev/null || true)
    [[ -n "${ALT}" ]] && echo "  NOTE: NAS mounted at ${ALT} instead" >&2
    ok=false
fi

# data directories
for dir in "${EXPECTED_DIRS[@]}"; do
    if [[ -e "${MOUNT_POINT}/${dir}" ]]; then
        echo "  OK: ${dir}/ exists"
    else
        echo "  FAIL: ${dir}/ missing" >&2
        ok=false
    fi
done

# usage
if [[ -d "${MOUNT_POINT}" ]]; then
    df -h "${MOUNT_POINT}"
    echo "  Files: $(find "${MOUNT_POINT}" -xdev -type f 2>/dev/null | wc -l)"
fi

if $ok; then
    echo "=== All checks passed ==="
    exit 0
else
    echo "=== Some checks failed ===" >&2
    exit 1
fi