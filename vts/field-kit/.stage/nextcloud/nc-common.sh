#!/bin/bash
# nc_install_v3 — shared helpers. Source from phase scripts:
#   source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/nc-common.sh"

NC_INSTALL_VERSION="3.0.0"
NC_WATCH_LOG="${NC_WATCH_LOG:-/tmp/watch.log}"

nc_log() { printf '[%s] %s\n' "$(date '+%F %T')" "$*" >&2; }

nc_watch_log() { echo "${NC_WATCH_LOG}"; }

nc_start_watcher() {
  local script_dir="${1:-$(nc_script_dir)}"
  local watcher="${script_dir}/watch-and-scan.sh"
  local log_file
  log_file="$(nc_watch_log)"

  [ -x "${watcher}" ] || return 1
  if pgrep -f "watch-and-scan.sh" >/dev/null 2>&1; then
    nc_log "Watcher already running"
    return 0
  fi
  nohup "${watcher}" > "${log_file}" 2>&1 &
  nc_log "Watcher started → ${log_file}"
}

# --- Debian-family detection ---

nc_is_debian_family() {
  local id="" id_like=""
  [ -f /etc/os-release ] || return 1
  # shellcheck source=/dev/null
  . /etc/os-release
  id="${ID:-}"
  id_like="${ID_LIKE:-}"
  case "${id}" in
    debian|ubuntu|linuxmint|pop|elementary|zorin|kali|raspbian) return 0 ;;
  esac
  case "${id_like}" in
    *debian*) return 0 ;;
  esac
  return 1
}

nc_os_codename() {
  [ -f /etc/os-release ] || return 0
  # shellcheck source=/dev/null
  . /etc/os-release
  echo "${VERSION_CODENAME:-}"
}

nc_os_id() {
  [ -f /etc/os-release ] || { echo "unknown"; return; }
  # shellcheck source=/dev/null
  . /etc/os-release
  echo "${ID:-unknown}"
}

# --- Download tools (curl preferred, wget fallback) ---

nc_ensure_download_tool() {
  if command -v curl >/dev/null 2>&1; then
    echo "curl"
    return 0
  fi
  if command -v wget >/dev/null 2>&1; then
    echo "wget"
    return 0
  fi
  nc_log "Installing curl and wget..."
  sudo apt update -y
  sudo apt install -y curl wget ca-certificates
  if command -v curl >/dev/null 2>&1; then
    echo "curl"
  else
    echo "wget"
  fi
}

nc_download() {
  local url="$1"
  local dest="$2"
  local tool
  tool="$(nc_ensure_download_tool)"
  case "${tool}" in
    curl)
      curl -fsSL --retry 3 --retry-delay 2 -o "${dest}" "${url}"
      ;;
    wget)
      wget -q --show-progress -O "${dest}" "${url}"
      ;;
    *)
      nc_log "ERROR: no download tool available"
      return 1
      ;;
  esac
}

# --- PHP / Nextcloud stack discovery ---

# Codenames where ondrej/php PPA has no suite (use native PHP only).
nc_php_ppa_blocked_codenames() {
  echo "resolute"
}

nc_php_ppa_blocked() {
  local codename="$1"
  local blocked
  for blocked in $(nc_php_ppa_blocked_codenames); do
    [ "${codename}" = "${blocked}" ] && return 0
  done
  return 1
}

nc_remove_broken_php_ppa() {
  local codename
  codename="$(nc_os_codename)"
  if nc_php_ppa_blocked "${codename}"; then
    sudo rm -f /etc/apt/sources.list.d/ondrej-ubuntu-php*.list 2>/dev/null || true
    sudo add-apt-repository --remove -y ppa:ondrej/php >/dev/null 2>&1 || true
  fi
}

nc_ensure_php_series_available() {
  local series="${1:-8.3}"
  if apt-cache show "php${series}-fpm" >/dev/null 2>&1; then
    return 0
  fi
  local codename
  codename="$(nc_os_codename)"
  if nc_php_ppa_blocked "${codename}"; then
    nc_log "ondrej/php has no suite for ${codename} — skip PPA"
    return 1
  fi
  nc_log "php${series} not in distro repos — adding ondrej/php PPA..."
  sudo apt install -y software-properties-common ca-certificates curl
  sudo add-apt-repository -y ppa:ondrej/php >/dev/null 2>&1
  sudo apt update -y
}

nc_php_series_available() {
  local series="${1}"
  apt-cache show "php${series}-fpm" >/dev/null 2>&1 \
    || dpkg -s "php${series}-fpm" >/dev/null 2>&1
}

nc_php_detection_order() {
  local codename
  codename="$(nc_os_codename)"
  if [ "${codename}" = "resolute" ]; then
    echo "8.5 8.4 8.3"
  else
    echo "8.3 8.5 8.4"
  fi
}

nc_detect_php_series() {
  local series="" order
  if [ -n "${NC_PHP_SERIES:-}" ] && nc_php_series_available "${NC_PHP_SERIES}"; then
    echo "${NC_PHP_SERIES}"
    return 0
  fi
  nc_remove_broken_php_ppa
  order="$(nc_php_detection_order)"
  for series in ${order}; do
    if nc_php_series_available "${series}"; then
      echo "${series}"
      return 0
    fi
  done
  local codename
  codename="$(nc_os_codename)"
  if ! nc_php_ppa_blocked "${codename}" \
    && nc_ensure_php_series_available 8.3 \
    && nc_php_series_available 8.3; then
    echo "8.3"
    return 0
  fi
  nc_log "ERROR: no supported php-fpm package found (tried ${order})"
  exit 1
}

nc_detect_nc_version() {
  local php_series="${1:-8.3}"
  if [ -n "${NC_VERSION:-}" ]; then
    echo "${NC_VERSION}"
    return 0
  fi
  case "${php_series}" in
    8.3) echo "30.0.5" ;;
    8.4) echo "31.0.0" ;;
    8.5) echo "33.0.5" ;;
    *) echo "30.0.5" ;;
  esac
}

nc_php_ppa_strategy() {
  local codename
  codename="$(nc_os_codename)"
  if nc_php_ppa_blocked "${codename}"; then
    echo "skip_native_only"
  else
    echo "use_ondrej_if_needed"
  fi
}

# Symlink config keys differ by NC major version.
nc_symlink_config_plan() {
  local nc_version="${1:-30.0.5}"
  local major
  major="${nc_version%%.*}"
  if [ "${major}" -ge 33 ] 2>/dev/null; then
    echo '["localstorage.allowsymlinks","follow_symlinks"]'
  elif [ "${major}" -ge 31 ] 2>/dev/null; then
    echo '["localstorage.allowsymlinks","follow_symlinks"]'
  else
    echo '["follow_symlinks"]'
  fi
}

# Build install plan from live system state (phase 1).
nc_build_install_plan() {
  local php_series nc_version codename ppa_strategy download_tool nc_url tarball
  php_series="$(nc_detect_php_series | awk 'NF { line=$0 } END { print line }' | tr -d '\r')"
  nc_version="$(nc_detect_nc_version "${php_series}" | awk 'NF { line=$0 } END { print line }' | tr -d '\r')"
  codename="$(nc_os_codename)"
  ppa_strategy="$(nc_php_ppa_strategy)"
  download_tool="$(nc_ensure_download_tool 2>/dev/null || echo "wget")"
  tarball="nextcloud-${nc_version}.tar.bz2"
  nc_url="https://download.nextcloud.com/server/releases/${tarball}"

  python3 -c "
import json
print(json.dumps({
  'installer_version': '${NC_INSTALL_VERSION}',
  'debian_family': $(nc_is_debian_family && echo True || echo False),
  'package_manager': 'apt',
  'os_codename': '${codename}',
  'php_series': '${php_series}',
  'php_detection_order': '$(nc_php_detection_order)'.split(),
  'nextcloud_version': '${nc_version}',
  'php_ppa_strategy': '${ppa_strategy}',
  'php_ppa_blocked_codenames': '$(nc_php_ppa_blocked_codenames)'.split(),
  'symlink_config': {
    'keys': json.loads('$(nc_symlink_config_plan "${nc_version}")'),
    'patch_config_php': True,
    'restart_php_fpm_after_patch': True
  },
  'apache': {
    'backend_host': '127.0.0.1',
    'backend_port': 8080,
    'vhost_name': 'nextcloud.conf'
  },
  'tailscale': {
    'serve_backend': 'http://127.0.0.1:8080',
    'require_installed': False
  },
  'download': {
    'tool': '${download_tool}',
    'nextcloud_tarball': '${tarball}',
    'nextcloud_url': '${nc_url}'
  },
  'required_apt_packages': [
    'apache2', 'mariadb-server', 'mariadb-client', 'redis-server',
    'unzip', 'bzip2', 'curl', 'wget', 'inotify-tools', 'acl',
    'software-properties-common', 'ca-certificates', 'jq', 'python3'
  ],
  'automation': {
    'sync_cron_minutes': 2,
    'symlink_guardian_minutes': 5,
    'backup_cron': '15 2 * * *'
  }
}, indent=2))
"
}

nc_read_install_plan_field() {
  local field="$1"
  local scan="${2:-$(nc_docs_dir)/01-host-scan.json}"
  [ -f "${scan}" ] || return 1
  python3 -c "
import json, sys
d = json.load(open('${scan}'))
plan = d.get('install_plan', {})
keys = '${field}'.split('.')
v = plan
for k in keys:
    if isinstance(v, dict):
        v = v.get(k)
    else:
        v = None
        break
if v is None:
    sys.exit(1)
if isinstance(v, (dict, list)):
    print(json.dumps(v))
else:
    print(v)
" 2>/dev/null
}

# --- Outward symlink configuration (NC 29–33+) ---

nc_enable_outward_symlinks() {
  local web_root="${1:-/var/www/nextcloud}"
  local php_bin="${2:-php}"
  local nc_version="${3:-}"
  local major=30

  if [ -n "${nc_version}" ]; then
    major="${nc_version%%.*}"
  elif [ -f "${web_root}/version.php" ]; then
    major=$(grep -oP "OC_VersionString.*'\K[0-9]+" "${web_root}/version.php" 2>/dev/null || echo 30)
  fi

  if [ "${major}" -ge 31 ] 2>/dev/null; then
    sudo -u www-data "${php_bin}" "${web_root}/occ" config:system:set localstorage.allowsymlinks --value=true --type=boolean 2>/dev/null || true
  fi
  sudo -u www-data "${php_bin}" "${web_root}/occ" config:system:set follow_symlinks --value=true --type=boolean 2>/dev/null || true
  sudo -u www-data "${php_bin}" "${web_root}/occ" config:system:set filesystem_check_changes --value=1 --type=integer 2>/dev/null || true
}

nc_patch_config_allow_symlinks() {
  local config="${1:-/var/www/nextcloud/config/config.php}"
  python3 <<PY
import re
path = "${config}"
try:
    with open(path) as f:
        c = f.read()
except OSError:
    raise SystemExit(0)
changed = False
if not re.search(r"'localstorage\.allowsymlinks'\s*=>\s*true", c):
    if "'localstorage.allowsymlinks'" in c:
        c = re.sub(r"'localstorage\.allowsymlinks'\s*=>\s*false", "'localstorage.allowsymlinks' => true", c)
        changed = True
    else:
        c = re.sub(r"\n\);\s*$", "\n  'localstorage.allowsymlinks' => true,\n);\n", c, count=1)
        changed = True
if not re.search(r"'follow_symlinks'\s*=>\s*true", c):
    if "'follow_symlinks'" in c:
        c = re.sub(r"'follow_symlinks'\s*=>\s*false", "'follow_symlinks' => true", c)
        changed = True
    else:
        c = re.sub(r"\n\);\s*$", "\n  'follow_symlinks' => true,\n);\n", c, count=1)
        changed = True
if changed:
    with open(path, "w") as f:
        f.write(c)
PY
}

nc_wipe_nextcloud_data_dir() {
  local data_dir="${1:-/var/lib/nextcloud/data}"
  sudo rm -rf "${data_dir}"
  sudo mkdir -p "${data_dir}"
  sudo chown www-data:www-data "${data_dir}"
  sudo chmod 750 "${data_dir}"
}

nc_reset_nextcloud_database() {
  local db_name="${1:-nextcloud}"
  local db_user="${2:-nextcloud}"
  local db_pass="${3:?db password required}"
  sudo mysql -e "DROP DATABASE IF EXISTS \`${db_name}\`;"
  sudo mysql -e "DROP USER IF EXISTS '${db_user}'@'localhost';"
  sudo mysql -e "CREATE DATABASE \`${db_name}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
  sudo mysql -e "CREATE USER '${db_user}'@'localhost' IDENTIFIED BY '${db_pass}';"
  sudo mysql -e "GRANT ALL PRIVILEGES ON \`${db_name}\`.* TO '${db_user}'@'localhost';"
  sudo mysql -e "FLUSH PRIVILEGES;"
}

nc_php_bin() {
  local series="${1:-}"
  if [ -z "${series}" ]; then
    series="$(nc_read_install_plan_field php_series 2>/dev/null || nc_detect_php_series 2>/dev/null || echo 8.3)"
  fi
  if [ -x "/usr/bin/php${series}" ]; then
    echo "/usr/bin/php${series}"
  else
    echo "php"
  fi
}

nc_configure_apache_php() {
  local series="${1}"
  local other=""
  sudo a2enmod rewrite headers env dir mime ssl
  sudo a2enconf "php${series}-fpm"
  for other in 8.5 8.4 8.3 8.2; do
    if [ "${other}" != "${series}" ] && [ -f "/etc/apache2/conf-available/php${other}-fpm.conf" ]; then
      sudo a2disconf "php${other}-fpm" 2>/dev/null || true
    fi
  done
  if [ -x "/usr/bin/php${series}" ]; then
    sudo update-alternatives --set php "/usr/bin/php${series}" 2>/dev/null || true
  fi
  sudo systemctl restart "php${series}-fpm" apache2
}

nc_configure_apache_nextcloud_vhost() {
  local web_root="${1:-/var/www/nextcloud}"
  local php_series="${2:-8.3}"
  local backend_host="${3:-127.0.0.1}"
  local backend_port="${4:-8080}"
  local fpm_sock="/run/php/php${php_series}-fpm.sock"
  local site_file="/etc/apache2/sites-available/nextcloud.conf"

  nc_log "Apache vhost ${backend_host}:${backend_port} (PHP ${php_series})"
  sudo apt install -y apache2 >/dev/null 2>&1 || true
  sudo a2enmod rewrite headers env dir mime ssl proxy_fcgi setenvif >/dev/null 2>&1 || true

  if ! grep -q "Listen ${backend_host}:${backend_port}" /etc/apache2/ports.conf 2>/dev/null; then
    echo "Listen ${backend_host}:${backend_port}" | sudo tee -a /etc/apache2/ports.conf >/dev/null
  fi

  sudo tee "${site_file}" >/dev/null <<EOF
<VirtualHost ${backend_host}:${backend_port}>
    DocumentRoot ${web_root}/
    ServerName ${backend_host}

    <Directory ${web_root}/>
        Require all granted
        AllowOverride All
        Options FollowSymLinks MultiViews

        <IfModule mod_dav.c>
            Dav off
        </IfModule>
    </Directory>

    <FilesMatch "\.php$">
        SetHandler "proxy:unix:${fpm_sock}|fcgi://localhost"
    </FilesMatch>

    ErrorLog \${APACHE_LOG_DIR}/nextcloud-error.log
    CustomLog \${APACHE_LOG_DIR}/nextcloud-access.log combined
</VirtualHost>
EOF

  sudo a2ensite nextcloud.conf >/dev/null 2>&1 || true
  sudo a2dissite 000-default.conf >/dev/null 2>&1 || true
  nc_configure_apache_php "${php_series}"
  sudo systemctl reload apache2
}

nc_configure_tailscale_serve() {
  local web_root="${1:-/var/www/nextcloud}"
  local php_bin="${2:-php}"
  local current_user="${3:-$(whoami)}"
  local backend="${4:-http://127.0.0.1:8080}"
  local ts_host

  command -v tailscale >/dev/null || { nc_log "Tailscale not installed — skip serve"; return 0; }

  ts_host="$(tailscale status --json 2>/dev/null | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("Self",{}).get("DNSName","").rstrip("."))' 2>/dev/null || true)"
  if [ -z "${ts_host}" ]; then
    ts_host="$(hostname -s).$(tailscale status --json 2>/dev/null | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("MagicDNSSuffix",""))' 2>/dev/null || echo '')"
  fi

  nc_log "Tailscale host: ${ts_host:-unknown}"
  sudo tailscale set --operator="${current_user}" 2>/dev/null || true
  tailscale serve --bg "${backend}"

  if [ -n "${ts_host}" ] && [ -f "${web_root}/occ" ]; then
    sudo -u www-data "${php_bin}" "${web_root}/occ" config:system:set trusted_domains 2 --value="${ts_host}"
    sudo -u www-data "${php_bin}" "${web_root}/occ" config:system:set overwrite.cli.url --value="https://${ts_host}"
    sudo -u www-data "${php_bin}" "${web_root}/occ" config:system:set overwriteprotocol --value="https"
    sudo -u www-data "${php_bin}" "${web_root}/occ" config:system:set overwritehost --value="${ts_host}"
  fi
  tailscale serve status 2>/dev/null | head -3 || true
}

# --- Username / paths ---

nc_prompt_nc_username() {
  local desktop_user="${1:-$(whoami)}"
  local input=""

  if [ -n "${NC_USERNAME:-}" ]; then
    echo "${NC_USERNAME}"
    return 0
  fi

  echo "Desktop Linux user: ${desktop_user} (owns ~/Documents, etc.)" >&2

  while true; do
    read -rp "Nextcloud username [${desktop_user}]: " input
    input="${input:-${desktop_user}}"

    if [[ ! "${input}" =~ ^[a-zA-Z0-9._-]+$ ]]; then
      echo "  Use only letters, numbers, dots, dashes, or underscores." >&2
      continue
    fi
    echo "${input}"
    return 0
  done
}

# Optional login password. Empty = phase 3 auto-generates and saves to .install-credentials.
nc_prompt_nc_password() {
  local input="" confirm=""

  if [ -n "${NC_ADMIN_PASSWORD:-}" ]; then
    echo "${NC_ADMIN_PASSWORD}"
    return 0
  fi

  echo "" >&2
  echo "Nextcloud login password (for phone app and web UI)." >&2
  while true; do
    read -s -rp "  Password [Enter = auto-generate]: " input
    echo "" >&2
    if [ -z "${input}" ]; then
      return 0
    fi
    if [ "${#input}" -lt 8 ]; then
      echo "  Use at least 8 characters, or press Enter to auto-generate." >&2
      continue
    fi
    read -s -rp "  Confirm password: " confirm
    echo "" >&2
    if [ "${input}" != "${confirm}" ]; then
      echo "  Passwords do not match." >&2
      continue
    fi
    echo "${input}"
    return 0
  done
}

nc_read_scan_nc_username() {
  local docs_dir="${1:-$(nc_docs_dir)}"
  local scan="${docs_dir}/01-host-scan.json"
  if [ -f "${scan}" ]; then
    python3 -c "import json; d=json.load(open('${scan}')); print(d.get('nc_username') or d.get('current_user',''))" 2>/dev/null
  else
    whoami
  fi
}

nc_script_dir() {
  local src="${NC_INSTALL_SCRIPT_DIR:-${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}}"
  cd "$(dirname "${src}")" && pwd
}

nc_docs_dir() {
  if [ -n "${NC_INSTALL_SCRIPT_DIR:-}" ]; then
    echo "${NC_INSTALL_SCRIPT_DIR}/phase-docs"
  else
    echo "$(nc_script_dir)/phase-docs"
  fi
}

nc_creds_file() {
  echo "$(nc_docs_dir)/.install-credentials"
}

nc_merge_install_credentials() {
  local merge_json="$1"
  local creds_file
  creds_file="$(nc_creds_file)"
  mkdir -p "$(nc_docs_dir)"
  NC_CREDS_PATH="${creds_file}" NC_CREDS_MERGE_JSON="${merge_json}" python3 <<'PY'
import json, os
path = os.environ["NC_CREDS_PATH"]
merge = json.loads(os.environ["NC_CREDS_MERGE_JSON"])
data = {}
if os.path.isfile(path):
    with open(path) as f:
        data = json.load(f)
data.update(merge)
with open(path, "w") as f:
    json.dump(data, f, indent=2)
os.chmod(path, 0o600)
PY
}

nc_read_install_credential() {
  local key="$1"
  local creds_file
  creds_file="$(nc_creds_file)"
  NC_CREDS_PATH="${creds_file}" NC_CREDS_KEY="${key}" python3 <<'PY'
import json, os, sys
path = os.environ["NC_CREDS_PATH"]
key = os.environ["NC_CREDS_KEY"]
try:
    with open(path) as f:
        d = json.load(f)
    sys.stdout.write(str(d.get(key, "")))
except (FileNotFoundError, json.JSONDecodeError, OSError):
    pass
PY
}

nc_store_install_credentials_env() {
  local creds_file
  creds_file="$(nc_creds_file)"
  mkdir -p "$(nc_docs_dir)"
  NC_CREDS_PATH="${creds_file}" python3 <<'PY'
import json, os
path = os.environ["NC_CREDS_PATH"]
merge = {}
for key in (
    "nc_admin_password", "nc_username", "admin_password", "admin_password_source",
    "db_name", "db_user", "db_pass",
):
    env_key = f"NC_CRED_{key.upper()}"
    if env_key in os.environ and os.environ[env_key]:
        merge[key] = os.environ[env_key]
data = {}
if os.path.isfile(path):
    with open(path) as f:
        data = json.load(f)
data.update(merge)
with open(path, "w") as f:
    json.dump(data, f, indent=2)
os.chmod(path, 0o600)
PY
}

nc_resolve_nc_user() {
  local default_user="${1:-$(whoami)}"
  local data_dir="${2:-/var/lib/nextcloud/data}"
  local docs_dir="${3:-$(nc_docs_dir)}"
  local web_root="${4:-/var/www/nextcloud}"
  local from_json=""
  local from_data=""

  if [ -f "${docs_dir}/01-host-scan.json" ]; then
    from_json=$(python3 -c "import json; d=json.load(open('${docs_dir}/01-host-scan.json')); print(d.get('nc_username') or '')" 2>/dev/null || true)
    if [ -n "${from_json}" ]; then
      echo "${from_json}"
      return 0
    fi
  fi

  if [ -f "${docs_dir}/04-user-symlinks.json" ]; then
    from_json=$(python3 -c "import json,sys; d=json.load(open('${docs_dir}/04-user-symlinks.json')); print(d.get('nc_username',''))" 2>/dev/null || true)
    if [ -n "${from_json}" ]; then
      echo "${from_json}"
      return 0
    fi
  fi

  local home_dir="${NC_INSTALL_OWNER_HOME:-${HOME:-$(eval echo "~${default_user}")}}"
  if [ -L "${home_dir}/.Photos" ]; then
    local from_link
    from_link=$(readlink "${home_dir}/.Photos" | sed -n 's|.*/data/\([^/]*\)/files/.*|\1|p' || true)
    if [ -n "${from_link}" ]; then
      echo "${from_link}"
      return 0
    fi
  fi

  if [ -f "${docs_dir}/05-complete.json" ]; then
    from_json=$(python3 -c "import json; print(json.load(open('${docs_dir}/05-complete.json')).get('nc_username',''))" 2>/dev/null || true)
    if [ -n "${from_json}" ]; then
      echo "${from_json}"
      return 0
    fi
  fi

  if [ -d "${data_dir}" ]; then
    from_data=$(sudo -n ls "${data_dir}" 2>/dev/null | grep -v '^appdata' | head -1 || true)
    if [ -n "${from_data}" ]; then
      echo "${from_data}"
      return 0
    fi
    from_data=$(find "${data_dir}" -mindepth 1 -maxdepth 1 -type d ! -name 'appdata_*' -printf '%f\n' 2>/dev/null | head -1 || true)
    if [ -n "${from_data}" ]; then
      echo "${from_data}"
      return 0
    fi
  fi

  echo "${default_user}"
}

nc_read_scan_field() {
  local field="$1"
  local docs_dir="${2:-$(nc_docs_dir)}"
  local scan="${docs_dir}/01-host-scan.json"
  [ -f "${scan}" ] || return 1
  python3 -c "import json,sys; print(json.load(open('${scan}'))['${field}'])" 2>/dev/null
}

# --- Cron / sudoers ---

nc_install_occ_scan_sudoers() {
  local current_user="$1"
  local web_root="${2:-/var/www/nextcloud}"
  local sudoers_file="/etc/sudoers.d/nextcloud-occ-scan-${current_user}"

  sudo tee "${sudoers_file}" >/dev/null <<EOF
# nc_install_v3: passwordless occ files:scan for ${current_user}
${current_user} ALL=(www-data) NOPASSWD: /usr/bin/php ${web_root}/occ files\:scan *
${current_user} ALL=(www-data) NOPASSWD: /usr/bin/php8.3 ${web_root}/occ files\:scan *
${current_user} ALL=(www-data) NOPASSWD: /usr/bin/php8.4 ${web_root}/occ files\:scan *
${current_user} ALL=(www-data) NOPASSWD: /usr/bin/php8.5 ${web_root}/occ files\:scan *
EOF
  sudo chmod 440 "${sudoers_file}"
  sudo visudo -cf "${sudoers_file}"
}

nc_install_sync_cron() {
  local current_user="$1"
  local nc_user="$2"
  local web_root="${3:-/var/www/nextcloud}"
  local interval="${4:-2}"
  local cron_line="*/${interval} * * * * sudo -n -u www-data php ${web_root}/occ files:scan ${nc_user} --quiet 2>/dev/null || true"

  ( crontab -l 2>/dev/null | grep -v "files:scan ${nc_user}" || true
    echo "${cron_line}"
  ) | crontab -
}

nc_install_symlink_guardian_cron() {
  local current_user="$1"
  local guardian_script="$2"
  local interval="${3:-5}"
  local sudoers_file="/etc/sudoers.d/nextcloud-symlink-guardian-${current_user}"
  local guardian_resolved
  guardian_resolved="$(readlink -f "${guardian_script}")"

  chmod +x "${guardian_resolved}"
  sudo tee "${sudoers_file}" >/dev/null <<EOF
# nc_install_v3: auto-repair outward symlinks if removed from mobile app
${current_user} ALL=(root) NOPASSWD: ${guardian_resolved}
EOF
  sudo chmod 440 "${sudoers_file}"
  sudo visudo -cf "${sudoers_file}"

  ( crontab -l 2>/dev/null | grep -v symlink-guardian || true
    echo "*/${interval} * * * * sudo -n ${guardian_resolved} >/dev/null 2>&1"
  ) | crontab -
}

nc_install_hub_backup_sudoers() {
  local current_user="$1"
  local backup_script="$2"
  local sudoers_file="/etc/sudoers.d/nextcloud-hub-backup-${current_user}"
  local backup_script_resolved
  backup_script_resolved="$(readlink -f "${backup_script}")"

  sudo tee "${sudoers_file}" >/dev/null <<EOF
${current_user} ALL=(root) NOPASSWD: ${backup_script_resolved}
EOF
  sudo chmod 440 "${sudoers_file}"
  sudo visudo -cf "${sudoers_file}"
}

nc_install_hub_backup_cron() {
  local current_user="$1"
  local backup_script="$2"
  local owner_home="$3"
  local backup_script_resolved
  backup_script_resolved="$(readlink -f "${backup_script}")"
  local cron_line="15 2 * * * sudo -n ${backup_script_resolved} >> ${owner_home}/Backups/nas-export/backup.log 2>&1"

  mkdir -p "${owner_home}/Backups/nas-export"
  ( crontab -l 2>/dev/null | grep -v "backup-hub-to-staging" || true
    echo "${cron_line}"
  ) | crontab -
}

# Record test iteration (called manually or by verify script).
nc_record_test_iteration() {
  local host_id="$1"
  local status="$2"
  local notes="${3:-}"
  local tests_dir="${NC_INSTALL_SCRIPT_DIR:-$(nc_script_dir)}/tests"
  local log_file="${tests_dir}/TEST_LOG.md"
  local json_file="${tests_dir}/${host_id}.json"
  local ts
  ts="$(date -Iseconds)"

  mkdir -p "${tests_dir}"
  python3 <<PY
import json, os
from datetime import datetime, timezone
path = "${json_file}"
data = {"host_id": "${host_id}", "iterations": []}
if os.path.isfile(path):
    with open(path) as f:
        data = json.load(f)
data["iterations"].append({
    "timestamp": "${ts}",
    "installer_version": "${NC_INSTALL_VERSION}",
    "status": "${status}",
    "notes": """${notes}"""
})
with open(path, "w") as f:
    json.dump(data, f, indent=2)
PY

  {
    echo ""
    echo "### ${host_id} — ${ts}"
    echo "- **Version:** ${NC_INSTALL_VERSION}"
    echo "- **Status:** ${status}"
    echo "- **Notes:** ${notes}"
  } >> "${log_file}"
}
