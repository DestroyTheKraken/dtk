#!/usr/bin/env bash
# Rebuild USB as Ventoy stick labeled VTECHS and copy Valley Tech router kit.
# >>> YOU must run this in a real terminal (needs sudo password).
#
# Usage:
#   bash setup-vtechs-usb.sh /dev/sdX
# Example (confirm with lsblk first!):
#   bash setup-vtechs-usb.sh /dev/sde
set -euo pipefail

DISK="${1:-}"
if [[ -z "${DISK}" || ! -b "${DISK}" ]]; then
  echo "Usage: bash $0 /dev/sdX"
  echo "List USBs: lsblk -o NAME,SIZE,LABEL,MODEL,TRAN,MOUNTPOINT"
  exit 1
fi

# Refuse system disks
ROOT_SRC=$(findmnt -n -o SOURCE / | sed 's/[0-9]*$//')
if [[ "${DISK}" == "${ROOT_SRC}"* ]] || [[ "${DISK}" == /dev/nvme0n1* ]]; then
  echo "REFUSE: looks like system disk: ${DISK}"
  exit 1
fi

SIZE=$(lsblk -b -dn -o SIZE "${DISK}")
if [[ "${SIZE}" -lt 8000000000 ]]; then
  echo "REFUSE: disk smaller than 8GB"
  exit 1
fi

echo "About to DESTROY all data on ${DISK} and install Ventoy."
lsblk -o NAME,SIZE,LABEL,MODEL,MOUNTPOINT "${DISK}"
read -r -p "Type YES to continue: " CONF
[[ "${CONF}" == "YES" ]] || { echo "Aborted"; exit 1; }

# Unmount
while read -r m; do
  [[ -n "${m}" ]] && sudo umount "${m}" || true
done < <(lsblk -ln -o MOUNTPOINT "${DISK}" | grep -v '^$' || true)

VENTOY_VER="1.1.05"
VENTOY_DIR="/tmp/ventoy-${VENTOY_VER}"
if [[ ! -x "${VENTOY_DIR}/Ventoy2Disk.sh" ]]; then
  cd /tmp
  curl -fsSL -o ventoy.tar.gz \
    "https://github.com/ventoy/Ventoy/releases/download/v${VENTOY_VER}/ventoy-${VENTOY_VER}-linux.tar.gz"
  tar xzf ventoy.tar.gz
fi

cd "${VENTOY_DIR}"
# -I = force install (wipes disk)
sudo bash ./Ventoy2Disk.sh -I "${DISK}" -g

sleep 2
# Ventoy data partition is usually ${DISK}1
PART1="${DISK}1"
if [[ ! -b "${PART1}" ]]; then
  PART1="${DISK}p1"
fi

# Label data partition VTECHS (vfat)
if command -v fatlabel >/dev/null 2>&1; then
  sudo fatlabel "${PART1}" VTECHS || true
elif command -v dosfslabel >/dev/null 2>&1; then
  sudo dosfslabel "${PART1}" VTECHS || true
else
  echo "Install dosfstools for fatlabel, or rename in file manager to VTECHS"
fi

# Mount and copy kit
MNT="/run/media/${USER}/VTECHS"
sudo mkdir -p "${MNT}"
sudo mount "${PART1}" "${MNT}"
sudo chown "${USER}:${USER}" "${MNT}" || true

PKG="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${MNT}/valley-tech-router"
rm -rf "${DEST}"
mkdir -p "${DEST}"
rsync -a \
  --exclude 'dist/' \
  --exclude 'runtime/' \
  --exclude 'parent/runtime/' \
  --exclude 'secrets/netdata-stream.env' \
  --exclude 'generated/' \
  "${PKG}/" "${DEST}/"

mkdir -p "${MNT}/isos"
cat > "${MNT}/README-FIRST.txt" <<'EOF'
Valley Tech / VTECHS Ventoy stick
================================

1) Put official VyOS ISO into the isos/ folder (download from your VyOS account).
2) Boot target mini-PC from this USB → choose the VyOS ISO → install to disk.
3) After reboot into VyOS, mount this stick and:
     configure
     load /media/vyos/VTECHS/valley-tech-router/configs/config.boot.home
     # or config.boot.office
     commit
     save
     exit
4) Ports: eth0=WAN (built-in), eth2=LAN1 trusted, eth3=LAN2 guest+IoT (no eth1).
5) Change default password immediately.
6) See valley-tech-router/configs/PORTS.md and HOW-VYOS-CONFIG-WORKS.md
EOF

sync
echo ""
echo "Done. Stick mounted at ${MNT}"
echo ">>> YOU: copy VyOS ISO to ${MNT}/isos/"
echo ">>> YOU: eject safely when finished copying ISO"
ls -la "${MNT}"
