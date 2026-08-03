#!/bin/bash
# Wipe Nextcloud hub install for clean retest. Must run as root.
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root: sudo bash wipe-nextcloud-hub.sh"
  exit 1
fi

DESKTOP_USER="${NC_INSTALL_OWNER:-$(logname 2>/dev/null || echo "${SUDO_USER:-}")}"
if [ -z "${DESKTOP_USER}" ] || [ "${DESKTOP_USER}" = "root" ]; then
  echo "Set NC_INSTALL_OWNER to the desktop username (e.g. NC_INSTALL_OWNER=myuser sudo bash wipe-nextcloud-hub.sh)"
  exit 1
fi
DESKTOP_HOME="$(getent passwd "${DESKTOP_USER}" | cut -d: -f6)"

log() { printf '[%s] %s\n' "$(date '+%F %T')" "$*"; }

# Enable temp sudo first (before removing backup sudoers) for remote automated retests.
if [ "${NC_INSTALL_TEMP_SUDO:-0}" = "1" ]; then
  log "Enabling temporary passwordless sudo for ${DESKTOP_USER}"
  tee "/etc/sudoers.d/nc-install-temp-${DESKTOP_USER}" >/dev/null <<EOF
# nc_install_v3 fresh test — remove after verify-install.sh
${DESKTOP_USER} ALL=(ALL) NOPASSWD: ALL
EOF
  chmod 440 "/etc/sudoers.d/nc-install-temp-${DESKTOP_USER}"
  visudo -cf "/etc/sudoers.d/nc-install-temp-${DESKTOP_USER}"
fi

log "Wiping Nextcloud hub for user ${DESKTOP_USER}..."

pkill -f 'watch-and-scan' 2>/dev/null || true
pkill -f inotifywait 2>/dev/null || true

if id "${DESKTOP_USER}" &>/dev/null; then
  ( crontab -u "${DESKTOP_USER}" -l 2>/dev/null \
    | grep -v 'files:scan' \
    | grep -v 'symlink-guardian' \
    | grep -v 'backup-hub-to-staging' \
    || true ) | crontab -u "${DESKTOP_USER}" - 2>/dev/null || true
fi

command -v tailscale &>/dev/null && tailscale serve reset 2>/dev/null || true

rm -f /etc/sudoers.d/nextcloud-occ-scan-"${DESKTOP_USER}"
rm -f /etc/sudoers.d/nextcloud-hub-backup-"${DESKTOP_USER}"
rm -f /etc/sudoers.d/nextcloud-symlink-guardian-"${DESKTOP_USER}"
rm -f /etc/sudoers.d/nextcloud-symlink-guardian-root

a2dissite nextcloud.conf 2>/dev/null || true
rm -f /etc/apache2/sites-available/nextcloud.conf
sed -i '/Listen 127.0.0.1:8080/d' /etc/apache2/ports.conf 2>/dev/null || true
a2ensite 000-default.conf 2>/dev/null || true
systemctl reload apache2 2>/dev/null || true

mysql -e "DROP DATABASE IF EXISTS \`nextcloud\`;" 2>/dev/null || true
mysql -e "DROP USER IF EXISTS 'nextcloud'@'localhost';" 2>/dev/null || true
mysql -e "FLUSH PRIVILEGES;" 2>/dev/null || true

rm -rf /var/www/nextcloud
rm -rf /var/lib/nextcloud

if [ -n "${DESKTOP_HOME}" ] && [ -d "${DESKTOP_HOME}" ]; then
  rm -f "${DESKTOP_HOME}/.Photos"
  for d in Documents Pictures Music Videos Public Templates Downloads Desktop Backups Notes Projects; do
    # Only remove NC convenience symlinks in home if they point into nextcloud data
    if [ -L "${DESKTOP_HOME}/${d}" ]; then
      target="$(readlink "${DESKTOP_HOME}/${d}")"
      case "${target}" in
        */nextcloud/data/*) rm -f "${DESKTOP_HOME}/${d}" ;;
      esac
    fi
  done
fi

rm -f /tmp/watch.log /tmp/nextcloud-watch.log /tmp/nextcloud-symlink-guardian.log

log "Wipe complete."
