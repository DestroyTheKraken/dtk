#!/usr/bin/env bash
# setup-nas-fstab.sh — Permanently mount systems_admin BTRFS NAS at /mnt/systems_admin
#
# SAFETY: This script does NOT format, partition, move, or delete any data.
#         It only adds fstab + udev entries, unmounts the udisks auto-mount,
#         and remounts the same BTRFS filesystem at a permanent path.
#
# Requires: sudo (one-time, for fstab/udev/mount)
# Run from: um690 control plane

set -euo pipefail

UUID="59f59772-7098-43f2-ab85-3c0794931a14"
LABEL="systems_admin"
DEVICE="/dev/disk/by-uuid/${UUID}"
MOUNT_POINT="/mnt/systems_admin"
FSTAB_ENTRY="UUID=${UUID} ${MOUNT_POINT} btrfs defaults,noatime,nofail,x-systemd.device-timeout=10 0 0"
UDEV_RULE="/etc/udev/rules.d/99-systems-admin-no-automount.rules"
CURRENT_MOUNT=""

log() { echo "[setup-nas] $*"; }
die() { echo "[setup-nas] ERROR: $*" >&2; exit 1; }

# --- Pre-flight checks ---
[[ "$(id -u)" -eq 0 ]] || die "Run with sudo: sudo bash $0"

[[ -b "${DEVICE}" ]] || die "Device ${DEVICE} not found. Is the NAS connected?"

FSTYPE=$(blkid -o value -s TYPE "${DEVICE}" 2>/dev/null || true)
[[ "${FSTYPE}" == "btrfs" ]] || die "Expected btrfs, got: ${FSTYPE}"

# Find current mount (udisks auto-mount or existing fstab mount)
if findmnt -n -o TARGET --source "${DEVICE}" &>/dev/null; then
    CURRENT_MOUNT=$(findmnt -n -o TARGET --source "${DEVICE}")
    log "Currently mounted at: ${CURRENT_MOUNT}"
else
    log "Device not currently mounted (will mount fresh at ${MOUNT_POINT})"
fi

# Inventory data before any changes
if [[ -n "${CURRENT_MOUNT}" && -d "${CURRENT_MOUNT}" ]]; then
    log "Pre-mount inventory:"
    ls -la "${CURRENT_MOUNT}/"
    FILE_COUNT=$(find "${CURRENT_MOUNT}" -xdev -type f 2>/dev/null | wc -l)
    DIR_COUNT=$(find "${CURRENT_MOUNT}" -xdev -type d 2>/dev/null | wc -l)
    USED=$(df -h --output=used "${CURRENT_MOUNT}" | tail -1 | tr -d ' ')
    log "  Files: ${FILE_COUNT}, Dirs: ${DIR_COUNT}, Used: ${USED}"
fi

# --- Create mount point ---
mkdir -p "${MOUNT_POINT}"
chown kraken:kraken "${MOUNT_POINT}"
log "Mount point ready: ${MOUNT_POINT}"

# --- Prevent udisks2 auto-mount conflict ---
cat > "${UDEV_RULE}" << 'UDEV'
# Prevent udisks2/GVFS from auto-mounting systems_admin NAS (managed by fstab)
ENV{ID_FS_UUID}=="59f59772-7098-43f2-ab85-3c0794931a14", ENV{UDISKS_IGNORE}="1"
UDEV
udevadm control --reload-rules
udevadm trigger --subsystem-match=block
log "Udev rule installed: ${UDEV_RULE}"

# --- Add fstab entry (idempotent) ---
cp -a /etc/fstab "/etc/fstab.bak.$(date +%Y%m%d%H%M%S)"
if grep -q "${UUID}" /etc/fstab; then
    log "fstab already contains UUID ${UUID} — skipping append"
else
    echo "" >> /etc/fstab
    echo "# systems_admin NAS (BTRFS) — SMADP secondary storage" >> /etc/fstab
    echo "${FSTAB_ENTRY}" >> /etc/fstab
    log "fstab entry added"
fi

# --- Remount at permanent location ---
# NOTE: findmnt --target returns the parent mount (/) for directories that are
# not themselves mount points. Use --source to detect if OUR device is mounted.
device_mount_target() {
    findmnt -n -o TARGET --source "${DEVICE}" 2>/dev/null || true
}

MOUNTED_AT=$(device_mount_target)

if [[ -n "${MOUNTED_AT}" && "${MOUNTED_AT}" != "${MOUNT_POINT}" ]]; then
    log "Unmounting ${MOUNTED_AT} (data remains on disk)..."
    umount "${DEVICE}"
    MOUNTED_AT=""
elif [[ "${MOUNTED_AT}" == "${MOUNT_POINT}" ]]; then
    log "Already mounted at ${MOUNT_POINT}"
fi

if [[ -z "${MOUNTED_AT}" ]]; then
    log "Mounting ${DEVICE} at ${MOUNT_POINT}..."
    if ! mount "${MOUNT_POINT}"; then
        die "mount failed — device is intact, run: sudo mount ${MOUNT_POINT}"
    fi
fi

# --- Verify data intact ---
log "Post-mount verification:"
ls -la "${MOUNT_POINT}/"

POST_FILES=$(find "${MOUNT_POINT}" -xdev -type f 2>/dev/null | wc -l)
POST_DIRS=$(find "${MOUNT_POINT}" -xdev -type d 2>/dev/null | wc -l)
POST_USED=$(df -h --output=used "${MOUNT_POINT}" | tail -1 | tr -d ' ')

log "  Files: ${POST_FILES}, Dirs: ${POST_DIRS}, Used: ${POST_USED}"

# Confirm expected directories exist
for dir in Backups HICKMAN_ROOT Pictures batocera_management .snapshots; do
    [[ -e "${MOUNT_POINT}/${dir}" ]] || die "Expected directory missing: ${dir}"
done
log "All expected data directories present."

# Verify counts match if we had a pre-mount inventory
if [[ -n "${CURRENT_MOUNT:-}" && -n "${FILE_COUNT:-}" ]]; then
    [[ "${POST_FILES}" -eq "${FILE_COUNT}" ]] || die "File count changed: ${FILE_COUNT} -> ${POST_FILES}"
    [[ "${POST_DIRS}" -eq "${DIR_COUNT}" ]] || die "Dir count changed: ${DIR_COUNT} -> ${POST_DIRS}"
    log "File/dir counts unchanged — no data loss."
fi

findmnt --source "${DEVICE}"
mountpoint -q "${MOUNT_POINT}" || die "${MOUNT_POINT} is not a mount point"
log "Done. NAS permanently mounted at ${MOUNT_POINT}"
log "Survives reboot via /etc/fstab (nofail if disk absent)."