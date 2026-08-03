#!/usr/bin/env bash
#
# configure-multiuser-hub.sh
# Idempotent: create Nextcloud users for each Linux seat on this host,
# outward-symlink real home folders, ACLs, admin group, Tailscale URL.
#
# Intended for household hubs (e.g. hickles) after a base field-kit install.
#
# Usage (on the hub, with sudo):
#   bash configure-multiuser-hub.sh
#   ADMIN_USER=joshua TS_HOST=hickles.taile52ad9.ts.net bash configure-multiuser-hub.sh
#   USERS="joshua alyssa nathon" bash configure-multiuser-hub.sh   # optional override
#
# Secrets: temp passwords written ONLY to TEMP_PASS_FILE (mode 600), never to git.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_DIR}/nc-common.sh" ]; then
  # shellcheck source=nc-common.sh
  source "${SCRIPT_DIR}/nc-common.sh"
fi

ADMIN_USER="${ADMIN_USER:-joshua}"
TS_HOST="${TS_HOST:-}"
WEB_ROOT="${WEB_ROOT:-/var/www/nextcloud}"
DATA_DIR="${DATA_DIR:-}"
PHP_BIN="${PHP_BIN:-}"
TEMP_PASS_FILE="${TEMP_PASS_FILE:-/root/nc-multiuser-temp-passwords.txt}"
SKIP_EXISTING_PASSWORDS="${SKIP_EXISTING_PASSWORDS:-1}" # 1 = do not reset passwords for users that already exist
DRY_RUN="${DRY_RUN:-0}"

FOLDERS=(Documents Pictures Music Videos Public Templates Downloads Desktop Backups Notes Projects)

log() { printf '[%s] %s\n' "$(date '+%F %T')" "$*"; }
die() { log "ERROR: $*"; exit 1; }

need_root() {
  if [ "$(id -u)" -ne 0 ]; then
    die "Run as root (sudo bash $0)"
  fi
}

detect_php() {
  if [ -n "${PHP_BIN}" ] && command -v "${PHP_BIN}" >/dev/null 2>&1; then
    return 0
  fi
  for c in php8.4 php8.3 php8.2 php8.1 php; do
    if command -v "${c}" >/dev/null 2>&1; then
      PHP_BIN="${c}"
      return 0
    fi
  done
  die "No PHP binary found"
}

detect_web_root() {
  if [ -f "${WEB_ROOT}/occ" ]; then
    return 0
  fi
  for d in /var/www/nextcloud /var/www/html/nextcloud /srv/nextcloud; do
    if [ -f "${d}/occ" ]; then
      WEB_ROOT="${d}"
      return 0
    fi
  done
  die "Nextcloud occ not found (set WEB_ROOT=...)"
}

occ() {
  sudo -u www-data "${PHP_BIN}" "${WEB_ROOT}/occ" "$@"
}

detect_data_dir() {
  if [ -n "${DATA_DIR}" ] && [ -d "${DATA_DIR}" ]; then
    return 0
  fi
  DATA_DIR="$(occ config:system:get datadirectory 2>/dev/null || true)"
  if [ -z "${DATA_DIR}" ] || [ ! -d "${DATA_DIR}" ]; then
    for d in /var/lib/nextcloud/data /var/www/nextcloud/data; do
      if [ -d "${d}" ]; then
        DATA_DIR="${d}"
        break
      fi
    done
  fi
  [ -d "${DATA_DIR}" ] || die "Could not detect Nextcloud data directory (set DATA_DIR=...)"
}

detect_ts_host() {
  if [ -n "${TS_HOST}" ]; then
    return 0
  fi
  if command -v tailscale >/dev/null 2>&1; then
    TS_HOST="$(tailscale status --json 2>/dev/null | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("Self",{}).get("DNSName","").rstrip("."))' 2>/dev/null || true)"
  fi
  if [ -z "${TS_HOST}" ]; then
    TS_HOST="$(hostname -s).taile52ad9.ts.net"
  fi
}

list_linux_users() {
  if [ -n "${USERS:-}" ]; then
    # shellcheck disable=SC2206
    echo ${USERS}
    return 0
  fi
  getent passwd | awk -F: '
    $3 >= 1000 && $3 < 65534 && $7 !~ /(nologin|false)$/ && $6 ~ /^\/home\// {
      print $1
    }'
}

gen_password() {
  # 20 chars alphanumeric
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -base64 18 | tr -d '/+=' | head -c 20
  else
    tr -dc 'A-Za-z0-9' </dev/urandom | head -c 20
  fi
  echo
}

ensure_folders() {
  local home="$1"
  local u="$2"
  local d
  for d in "${FOLDERS[@]}"; do
    mkdir -p "${home}/${d}"
    chown "${u}:${u}" "${home}/${d}" 2>/dev/null || chown "${u}" "${home}/${d}" || true
  done
}

apply_acls() {
  local home="$1"
  local u="$2"
  local d dir
  groupadd -f nextcloud-shared || true
  usermod -aG nextcloud-shared "${u}" 2>/dev/null || true
  usermod -aG nextcloud-shared www-data 2>/dev/null || true
  setfacl -m u:www-data:rx "${home}" || true
  for d in "${FOLDERS[@]}"; do
    dir="${home}/${d}"
    [ -d "${dir}" ] || continue
    setfacl -R -m "u:www-data:rwx,u:${u}:rwx" "${dir}" || true
    setfacl -d -R -m "u:www-data:rwx,u:${u}:rwx" "${dir}" || true
    chgrp -R nextcloud-shared "${dir}" 2>/dev/null || true
    chmod -R g+rwX "${dir}" 2>/dev/null || true
  done
}

link_outward() {
  local u="$1"
  local home="$2"
  local nc_files="${DATA_DIR}/${u}/files"
  local d target link

  mkdir -p "${nc_files}"
  touch "${nc_files}/.ocdata" 2>/dev/null || true
  chown -R www-data:www-data "${DATA_DIR}/${u}" 2>/dev/null || true

  for d in "${FOLDERS[@]}"; do
    target="${home}/${d}"
    link="${nc_files}/${d}"
    mkdir -p "${target}"
    if [ -e "${link}" ] || [ -L "${link}" ]; then
      rm -rf "${link}"
    fi
    sudo -u www-data ln -s "${target}" "${link}"
    log "  link ${u}: ${d} → ${target}"
  done

  if [ -d "${home}/Pictures" ]; then
    rm -rf "${nc_files}/Photos" 2>/dev/null || true
    sudo -u www-data ln -sfn "${home}/Pictures" "${nc_files}/Photos"
  fi

  chown -h www-data:www-data "${nc_files}"/* 2>/dev/null || true
}

nc_user_exists() {
  local u="$1"
  occ user:list 2>/dev/null | grep -qE "(^|[[:space:]])${u}(:|[[:space:]]|$)"
}

create_or_update_user() {
  local u="$1"
  local home="$2"
  local exists=0
  local pass=""

  if nc_user_exists "${u}"; then
    exists=1
    log "Nextcloud user exists: ${u}"
  else
    log "Creating Nextcloud user: ${u}"
    pass="$(gen_password | tr -d '\n')"
    if [ "${DRY_RUN}" = "1" ]; then
      log "DRY_RUN: would create ${u}"
      return 0
    fi
    OC_PASS="${pass}" sudo -E -u www-data "${PHP_BIN}" "${WEB_ROOT}/occ" user:add \
      --display-name="${u}" --password-from-env "${u}" \
      || die "user:add failed for ${u}"
    {
      echo "user=${u}"
      echo "temp_password=${pass}"
      echo "server=https://${TS_HOST}"
      echo "note=Change password after first login (Personal settings → Security)"
      echo "---"
    } >> "${TEMP_PASS_FILE}"
    chmod 600 "${TEMP_PASS_FILE}"
    # Best-effort force password change (version-dependent)
    occ user:setting "${u}" core force_password_change 1 2>/dev/null || true
  fi

  if [ "${exists}" = "1" ] && [ "${SKIP_EXISTING_PASSWORDS}" != "1" ]; then
    pass="$(gen_password | tr -d '\n')"
    OC_PASS="${pass}" sudo -E -u www-data "${PHP_BIN}" "${WEB_ROOT}/occ" user:resetpassword \
      --password-from-env "${u}" || true
    {
      echo "user=${u}"
      echo "temp_password=${pass}"
      echo "server=https://${TS_HOST}"
      echo "note=RESET — change after login"
      echo "---"
    } >> "${TEMP_PASS_FILE}"
    chmod 600 "${TEMP_PASS_FILE}"
  fi

  ensure_folders "${home}" "${u}"
  apply_acls "${home}" "${u}"
  link_outward "${u}" "${home}"
  occ files:scan "${u}" 2>/dev/null || true
}

set_admin() {
  local u="$1"
  if [ "${u}" = "${ADMIN_USER}" ]; then
    occ group:adduser admin "${u}" 2>/dev/null || true
    log "Admin group: ${u}"
  else
    # Ensure non-admins are not in admin (if they were accidentally added)
    occ group:removeuser admin "${u}" 2>/dev/null || true
  fi
}

enable_symlinks() {
  if type nc_enable_outward_symlinks >/dev/null 2>&1; then
    nc_enable_outward_symlinks "${WEB_ROOT}" "${PHP_BIN}" "" || true
  else
    occ config:system:set localstorage.allowsymlinks --value=true --type=boolean 2>/dev/null || true
    occ config:system:set follow_symlinks --value=true --type=boolean 2>/dev/null || true
    occ config:system:set filesystem_check_changes --value=1 --type=integer 2>/dev/null || true
  fi
  if type nc_patch_config_allow_symlinks >/dev/null 2>&1; then
    nc_patch_config_allow_symlinks "${WEB_ROOT}/config/config.php" || true
  fi
}

configure_tailscale_url() {
  log "Trusted domain / overwrite URL → https://${TS_HOST}"
  occ config:system:set trusted_domains 0 --value="localhost" 2>/dev/null || true
  occ config:system:set trusted_domains 1 --value="127.0.0.1" 2>/dev/null || true
  occ config:system:set trusted_domains 2 --value="${TS_HOST}" 2>/dev/null || true
  occ config:system:set overwrite.cli.url --value="https://${TS_HOST}" 2>/dev/null || true
  occ config:system:set overwriteprotocol --value="https" 2>/dev/null || true
  occ config:system:set overwritehost --value="${TS_HOST}" 2>/dev/null || true

  if command -v tailscale >/dev/null 2>&1; then
    # Prefer existing serve; try common backends
    if ! tailscale serve status 2>/dev/null | grep -q .; then
      tailscale serve --bg http://127.0.0.1:8080 2>/dev/null \
        || tailscale serve --bg http://127.0.0.1:80 2>/dev/null \
        || true
    fi
    tailscale serve status 2>/dev/null | head -5 || true
  fi
}

install_multi_watcher() {
  local out="${SCRIPT_DIR}/watch-and-scan-multi.sh"
  local homes=()
  local u home

  while read -r u; do
    [ -n "${u}" ] || continue
    home="$(getent passwd "${u}" | cut -d: -f6)"
    [ -d "${home}" ] && homes+=("${home}")
  done < <(list_linux_users)

  cat > "${out}" <<'WATCHER_HDR'
#!/usr/bin/env bash
# Multi-user inotify watcher — generated by configure-multiuser-hub.sh
set -euo pipefail
WATCHER_HDR
  cat >> "${out}" <<WATCHER
WEB_ROOT="${WEB_ROOT}"
PHP_BIN="${PHP_BIN}"
FOLDERS=(Documents Pictures Music Videos Public Templates Downloads Desktop Backups Notes Projects)
HOMES=(${homes[*]+"${homes[*]}"})

log() { echo "[\$(date '+%F %T')] \$*"; }
command -v inotifywait >/dev/null || { log "Install inotify-tools"; exit 1; }

WATCH_PATHS=()
for home in "\${HOMES[@]}"; do
  for d in "\${FOLDERS[@]}"; do
    p="\${home}/\${d}"
    [ -d "\${p}" ] && WATCH_PATHS+=("\${p}")
  done
done
[ "\${#WATCH_PATHS[@]}" -gt 0 ] || { log "No folders to watch"; exit 1; }

user_for_path() {
  local path="\$1" home u
  for home in "\${HOMES[@]}"; do
    if [[ "\${path}" == "\${home}/"* ]]; then
      u="\$(basename "\${home}")"
      # resolve via getent if basename wrong for non-matching home name
      u="\$(getent passwd | awk -F: -v h="\${home}" '\$6==h {print \$1; exit}')"
      echo "\${u}"
      return 0
    fi
  done
  return 1
}

log "multi-user watcher — \${#WATCH_PATHS[@]} paths"
inotifywait -m -r -e create,modify,delete,move,close_write --format '%w%f %e' "\${WATCH_PATHS[@]}" |
while read -r path event; do
  u="\$(user_for_path "\${path}" || true)"
  [ -n "\${u}" ] || continue
  for d in "\${FOLDERS[@]}"; do
    if [[ "\${path}" == *"/\$d"* ]] || [[ "\${path}" == *"/\$d/"* ]]; then
      log "\${u} change in \${d}: \${event}"
      sudo -n -u www-data "\${PHP_BIN}" "\${WEB_ROOT}/occ" files:scan "\${u}" --path="/\${d}" --quiet 2>/dev/null || true
      break
    fi
  done
done
WATCHER
  chmod +x "${out}"
  log "Wrote multi watcher: ${out}"
  log "Start with: nohup ${out} > /tmp/nextcloud-watch-multi.log 2>&1 &"

  # Safety scan-all cron every 2 minutes for root
  local cron_line="*/2 * * * * www-data ${PHP_BIN} ${WEB_ROOT}/occ files:scan --all --quiet"
  # Install via /etc/cron.d for multi-user
  echo "*/2 * * * * www-data ${PHP_BIN} ${WEB_ROOT}/occ files:scan --all --quiet" > /etc/cron.d/nextcloud-scan-all
  chmod 644 /etc/cron.d/nextcloud-scan-all
  log "Installed /etc/cron.d/nextcloud-scan-all"
}

install_multi_guardian() {
  local out="${SCRIPT_DIR}/symlink-guardian-multi.sh"
  cat > "${out}" <<GUARDIAN
#!/usr/bin/env bash
# Multi-user symlink guardian — generated by configure-multiuser-hub.sh
set -euo pipefail
[ "\$(id -u)" -eq 0 ] || exit 0
WEB_ROOT="${WEB_ROOT}"
DATA_DIR="${DATA_DIR}"
PHP_BIN="${PHP_BIN}"
FOLDERS=(Documents Pictures Music Videos Public Templates Downloads Desktop Backups Notes Projects)
LOG="/tmp/nextcloud-symlink-guardian-multi.log"
log() { echo "[\$(date '+%F %T')] \$*" >> "\${LOG}"; }

getent passwd | awk -F: '\$3>=1000 && \$3<65534 && \$7 !~ /(nologin|false)\$/ && \$6 ~ /^\\/home\\// {print \$1,\$6}' |
while read -r u home; do
  [ -d "\${home}" ] || continue
  nc_files="\${DATA_DIR}/\${u}/files"
  mkdir -p "\${nc_files}"
  touch "\${nc_files}/.ocdata" 2>/dev/null || true
  chown www-data:www-data "\${nc_files}" "\${nc_files}/.ocdata" 2>/dev/null || true
  changed=0
  for d in "\${FOLDERS[@]}"; do
    target="\${home}/\${d}"
    link="\${nc_files}/\${d}"
    mkdir -p "\${target}"
    if [ -L "\${link}" ] && [ "\$(readlink "\${link}")" = "\${target}" ]; then
      continue
    fi
    rm -rf "\${link}"
    sudo -u www-data ln -s "\${target}" "\${link}"
    log "relinked \${u}/\${d}"
    changed=1
  done
  if [ -d "\${home}/Pictures" ]; then
    if [ ! -L "\${nc_files}/Photos" ] || [ "\$(readlink "\${nc_files}/Photos")" != "\${home}/Pictures" ]; then
      rm -rf "\${nc_files}/Photos"
      sudo -u www-data ln -sfn "\${home}/Pictures" "\${nc_files}/Photos"
      changed=1
    fi
  fi
  if [ "\${changed}" -eq 1 ]; then
    sudo -u www-data "\${PHP_BIN}" "\${WEB_ROOT}/occ" files:scan "\${u}" >> "\${LOG}" 2>&1 || true
  fi
done
GUARDIAN
  chmod +x "${out}"
  echo "*/5 * * * * root ${out}" > /etc/cron.d/nextcloud-symlink-guardian-multi
  chmod 644 /etc/cron.d/nextcloud-symlink-guardian-multi
  log "Installed multi guardian cron: ${out}"
}

print_summary() {
  log "========== SUMMARY =========="
  log "Web root:  ${WEB_ROOT}"
  log "Data dir:  ${DATA_DIR}"
  log "PHP:       ${PHP_BIN}"
  log "TS host:   ${TS_HOST}"
  log "Admin:     ${ADMIN_USER}"
  log "Users:"
  occ user:list 2>/dev/null || true
  log "Groups:"
  occ group:list 2>/dev/null || true
  if [ -f "${TEMP_PASS_FILE}" ]; then
    log "Temp passwords: ${TEMP_PASS_FILE} (mode 600) — copy to Bitwarden, then delete"
  else
    log "No new temp passwords file (all users already existed or dry-run)"
  fi
  log "Phone setup:"
  log "  Server:   https://${TS_HOST}"
  log "  Username: <linux username>"
  log "  Password: temp (change after first login)"
  log "  Require:  Tailscale connected"
}

main() {
  need_root
  detect_php
  detect_web_root
  detect_data_dir
  detect_ts_host

  log "=== Multi-user Nextcloud hub ==="
  log "WEB_ROOT=${WEB_ROOT} DATA_DIR=${DATA_DIR} ADMIN=${ADMIN_USER} TS=${TS_HOST}"

  # Fresh temp password file only if we will create users
  if [ -f "${TEMP_PASS_FILE}" ]; then
    log "Note: appending to existing ${TEMP_PASS_FILE}"
  else
    : > "${TEMP_PASS_FILE}"
    chmod 600 "${TEMP_PASS_FILE}"
  fi

  enable_symlinks
  configure_tailscale_url

  local u home count=0
  while read -r u; do
    [ -n "${u}" ] || continue
    home="$(getent passwd "${u}" | cut -d: -f6)"
    if [ -z "${home}" ] || [ ! -d "${home}" ]; then
      log "SKIP ${u}: no home directory"
      continue
    fi
    log "--- seat: ${u} (${home}) ---"
    if [ "${DRY_RUN}" = "1" ]; then
      log "DRY_RUN seat ${u}"
      count=$((count + 1))
      continue
    fi
    create_or_update_user "${u}" "${home}"
    set_admin "${u}"
    count=$((count + 1))
  done < <(list_linux_users)

  [ "${count}" -gt 0 ] || die "No Linux seats found (uid>=1000 under /home)"

  if [ "${DRY_RUN}" != "1" ]; then
    install_multi_watcher
    install_multi_guardian
  fi

  print_summary
  log "Done. Start multi watcher if not already running."
}

main "$@"
