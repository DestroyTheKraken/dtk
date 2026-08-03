#!/bin/bash
#
# Phase 1: Host discovery + install plan for nc_install_v3.
# Outputs: phase-docs/01-host-scan.json (includes install_plan for all later phases)
#
# Run as the target non-root user who will own the folders.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NC_INSTALL_SCRIPT_DIR="${SCRIPT_DIR}"
# shellcheck source=nc-common.sh
source "${SCRIPT_DIR}/nc-common.sh"

DOCS_DIR="$SCRIPT_DIR/phase-docs"
mkdir -p "$DOCS_DIR"
OUTPUT_FILE="$DOCS_DIR/01-host-scan.json"

echo "=== Phase 1: Host scan + install plan (nc_install v${NC_INSTALL_VERSION}) ==="
echo "Output: $OUTPUT_FILE"
echo ""

CURRENT_USER=$(whoami)
CURRENT_HOME=$(eval echo ~"${CURRENT_USER}")
export CURRENT_USER CURRENT_HOME

echo "--- Account setup (stored in phase-docs) ---"
NC_USERNAME=$(nc_prompt_nc_username "${CURRENT_USER}")
export NC_USERNAME
NC_ADMIN_PASSWORD="$(nc_prompt_nc_password)"
NC_PASSWORD_MODE="auto"
[ -n "${NC_ADMIN_PASSWORD}" ] && NC_PASSWORD_MODE="provided"
echo "Nextcloud username: ${NC_USERNAME}"
echo "Password: $([ "${NC_PASSWORD_MODE}" = "provided" ] && echo "you chose" || echo "auto-generate in phase 3")"
echo ""

USER_UID=$(id -u)
USER_GID=$(id -g)
USER_GROUPS=$(groups)

if [ -f /etc/os-release ]; then
  # shellcheck source=/dev/null
  . /etc/os-release
  OS_ID="$ID"
  OS_VERSION_ID="$VERSION_ID"
  OS_VERSION_CODENAME="${VERSION_CODENAME:-}"
  OS_PRETTY="$PRETTY_NAME"
  OS_ID_LIKE="${ID_LIKE:-}"
else
  OS_ID="unknown"
  OS_VERSION_ID="unknown"
  OS_VERSION_CODENAME=""
  OS_PRETTY="Unknown Linux"
  OS_ID_LIKE=""
fi

ARCH=$(uname -m)
DEBIAN_FAMILY_PY="False"
if nc_is_debian_family; then DEBIAN_FAMILY_PY="True"; fi

if sudo -n true 2>/dev/null; then
  SUDO_CACHED_PY="True"
  SUDO_NOTE=""
else
  SUDO_CACHED_PY="False"
  SUDO_NOTE="will prompt for password"
fi

WEB_SERVER="none"
if systemctl is-active --quiet apache2 2>/dev/null || command -v apache2 >/dev/null; then
  WEB_SERVER="apache2"
elif systemctl is-active --quiet nginx 2>/dev/null || command -v nginx >/dev/null; then
  WEB_SERVER="nginx"
fi

PHP_VERSION=""
PHP_BINARY=""
if command -v php >/dev/null; then
  PHP_BINARY=$(command -v php)
  PHP_VERSION=$($PHP_BINARY -r 'echo PHP_VERSION;' 2>/dev/null || echo "unknown")
fi

PHP_FPM_SERVICE=""
if systemctl list-unit-files 2>/dev/null | grep -q php.*fpm; then
  PHP_FPM_SERVICE=$(systemctl list-unit-files 2>/dev/null | grep -o 'php[0-9.]*-fpm' | head -1 || echo "")
fi

DB_TYPE="none"
DB_VERSION=""
if command -v mariadb >/dev/null || command -v mysql >/dev/null; then
  if systemctl is-active --quiet mariadb 2>/dev/null || systemctl is-active --quiet mysql 2>/dev/null; then
    DB_TYPE="mariadb"
    DB_VERSION=$(mariadb --version 2>/dev/null | head -1 || mysql --version 2>/dev/null | head -1 || echo "unknown")
  fi
fi

REDIS_STATUS="not running"
if systemctl is-active --quiet redis-server 2>/dev/null || systemctl is-active --quiet redis 2>/dev/null; then
  REDIS_STATUS="running"
fi

TAILSCALE_INSTALLED_PY="False"
TAILSCALE_STATUS="not running"
TAILSCALE_USER=""
TAILSCALE_IP=""
TAILSCALE_DNS=""
HAS_CURL_PY="False"
HAS_WGET_PY="False"
if command -v curl >/dev/null; then HAS_CURL_PY="True"; fi
if command -v wget >/dev/null; then HAS_WGET_PY="True"; fi

if command -v tailscale >/dev/null; then
  TAILSCALE_INSTALLED_PY="True"
  if tailscale status --json 2>/dev/null | grep -q '"BackendState":"Running"'; then
    TAILSCALE_STATUS="running"
    TAILSCALE_USER=$(tailscale status --json 2>/dev/null | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("Self",{}).get("UserID","") or "unknown")' 2>/dev/null || echo "unknown")
    TAILSCALE_IP=$(tailscale ip -4 2>/dev/null | head -1 || echo "")
    TAILSCALE_DNS=$(tailscale status --json 2>/dev/null | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("Self",{}).get("DNSName","").rstrip("."))' 2>/dev/null || echo "")
  fi
fi

DOWNLOAD_TOOL="none"
if command -v curl >/dev/null; then DOWNLOAD_TOOL="curl"
elif command -v wget >/dev/null; then DOWNLOAD_TOOL="wget"
fi

DISK_ROOT=$(df -h / | awk 'NR==2 {print $4}')
DISK_VAR=$(df -h /var 2>/dev/null | awk 'NR==2 {print $4}' || echo "N/A")
DISK_HOME=$(df -h /home 2>/dev/null | awk 'NR==2 {print $4}' || echo "N/A")
MEM_TOTAL=$(free -h | awk '/Mem:/ {print $2}')
MEM_AVAIL=$(free -h | awk '/Mem:/ {print $7}')

NEXTCLOUD_WEB_ROOT=""
NEXTCLOUD_DATA_DIR=""
NEXTCLOUD_VERSION=""
if [ -f /var/www/nextcloud/version.php ]; then
  NEXTCLOUD_WEB_ROOT="/var/www/nextcloud"
  NEXTCLOUD_VERSION=$(grep "OC_VersionString" /var/www/nextcloud/version.php | cut -d"'" -f2 || echo "unknown")
fi
if [ -d /var/lib/nextcloud/data ]; then
  NEXTCLOUD_DATA_DIR="/var/lib/nextcloud/data"
fi

STANDARD_FOLDERS=(Documents Pictures Music Videos Public Templates Downloads Desktop Backups Notes Projects)
EXISTING_FOLDERS=()
FOLDER_SIZES=()
for folder in "${STANDARD_FOLDERS[@]}"; do
  path="$CURRENT_HOME/$folder"
  if [ -d "$path" ]; then
    size=$(du -sh "$path" 2>/dev/null | cut -f1 || echo "0")
    EXISTING_FOLDERS+=("$folder")
    FOLDER_SIZES+=("$folder:$size")
  fi
done

APACHE_CONF_DIR="/etc/apache2"
if [ -d "$APACHE_CONF_DIR" ]; then
  APACHE_USER=$(grep -oP '(?<=^User ).*' "$APACHE_CONF_DIR/apache2.conf" 2>/dev/null || echo "www-data")
else
  APACHE_USER="www-data"
fi

echo "Building install plan from discovery..."
INSTALL_PLAN=$(nc_build_install_plan)

export NC_PASSWORD_MODE
export NC_USERNAME

if [ -n "${NC_ADMIN_PASSWORD}" ]; then
  NC_CRED_NC_ADMIN_PASSWORD="${NC_ADMIN_PASSWORD}" nc_store_install_credentials_env
fi

python3 <<PY
import json, os

scan = {
  "scan_timestamp": "$(date -Iseconds)",
  "installer_version": "${NC_INSTALL_VERSION}",
  "current_user": os.environ.get("CURRENT_USER", "$(whoami)"),
  "nc_username": os.environ.get("NC_USERNAME", ""),
  "nc_password_mode": os.environ.get("NC_PASSWORD_MODE", "auto"),
  "current_home": os.environ.get("CURRENT_HOME", ""),
  "user_uid": ${USER_UID},
  "user_gid": ${USER_GID},
  "user_groups": "${USER_GROUPS}",
  "os": {
    "id": "${OS_ID}",
    "id_like": "${OS_ID_LIKE}",
    "version_id": "${OS_VERSION_ID}",
    "codename": "${OS_VERSION_CODENAME}",
    "pretty_name": "${OS_PRETTY}",
    "arch": "${ARCH}",
    "debian_family": ${DEBIAN_FAMILY_PY}
  },
  "sudo": {
    "cached": ${SUDO_CACHED_PY},
    "note": "${SUDO_NOTE}"
  },
  "web_server": "${WEB_SERVER}",
  "php": {
    "version": "${PHP_VERSION}",
    "binary": "${PHP_BINARY}",
    "fpm_service": "${PHP_FPM_SERVICE}"
  },
  "database": {
    "type": "${DB_TYPE}",
    "version": "${DB_VERSION}"
  },
  "redis": {
    "status": "${REDIS_STATUS}"
  },
  "tailscale": {
    "installed": ${TAILSCALE_INSTALLED_PY},
    "status": "${TAILSCALE_STATUS}",
    "user": "${TAILSCALE_USER}",
    "ipv4": "${TAILSCALE_IP}",
    "dns_name": "${TAILSCALE_DNS}"
  },
  "download_tools": {
    "curl": ${HAS_CURL_PY},
    "wget": ${HAS_WGET_PY},
    "preferred": "${DOWNLOAD_TOOL}"
  },
  "disk": {
    "root_avail": "${DISK_ROOT}",
    "var_avail": "${DISK_VAR}",
    "home_avail": "${DISK_HOME}"
  },
  "memory": {
    "total": "${MEM_TOTAL}",
    "available": "${MEM_AVAIL}"
  },
  "nextcloud_existing": {
    "web_root": "${NEXTCLOUD_WEB_ROOT}",
    "data_dir": "${NEXTCLOUD_DATA_DIR}",
    "version": "${NEXTCLOUD_VERSION}"
  },
  "apache": {
    "user": "${APACHE_USER}",
    "conf_dir": "${APACHE_CONF_DIR}"
  },
  "existing_user_folders": $(printf '%s\n' "${EXISTING_FOLDERS[@]}" | jq -R . | jq -s .),
  "folder_sizes": $(printf '%s\n' "${FOLDER_SIZES[@]}" | jq -R . | jq -s .),
  "recommendations": {
    "data_dir": "/var/lib/nextcloud/data",
    "web_root": "/var/www/nextcloud",
    "default_folders": ["Documents", "Pictures", "Music", "Videos", "Public", "Templates", "Downloads", "Desktop", "Backups", "Notes", "Projects"]
  },
  "install_plan": json.loads('''${INSTALL_PLAN}''')
}

with open("${OUTPUT_FILE}", "w") as f:
    json.dump(scan, f, indent=2)
PY

unset NC_ADMIN_PASSWORD

PHP_PLAN=$(echo "${INSTALL_PLAN}" | python3 -c "import sys,json; print(json.load(sys.stdin)['php_series'])")
NC_PLAN=$(echo "${INSTALL_PLAN}" | python3 -c "import sys,json; print(json.load(sys.stdin)['nextcloud_version'])")
PPA_PLAN=$(echo "${INSTALL_PLAN}" | python3 -c "import sys,json; print(json.load(sys.stdin)['php_ppa_strategy'])")

echo ""
echo "=== Phase 1 Complete ==="
echo "  Desktop user: ${CURRENT_USER} | NC user: ${NC_USERNAME}"
echo "  OS: ${OS_PRETTY} (${OS_VERSION_CODENAME}) — debian_family=${DEBIAN_FAMILY_PY}"
echo "  Install plan: PHP ${PHP_PLAN} + Nextcloud ${NC_PLAN}"
echo "  PPA strategy: ${PPA_PLAN}"
echo "  Tailscale: ${TAILSCALE_STATUS}"
echo ""
echo "Document: ${OUTPUT_FILE}"
echo "Next: bash phase-02-prereqs.sh"
echo "================================================================"