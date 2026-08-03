#!/bin/bash
#
# Phase 3: Download, extract, database setup, initial Nextcloud install.
# Reads install_plan from phase-docs/01-host-scan.json

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NC_INSTALL_SCRIPT_DIR="${SCRIPT_DIR}"
# shellcheck source=nc-common.sh
source "${SCRIPT_DIR}/nc-common.sh"

DOCS_DIR="$SCRIPT_DIR/phase-docs"
SCAN_FILE="$DOCS_DIR/01-host-scan.json"
PREREQS_FILE="$DOCS_DIR/02-prereqs.json"

if [ ! -f "$SCAN_FILE" ]; then
  echo "ERROR: Run phase-01 first."
  exit 1
fi

CURRENT_USER=$(python3 -c "import json; d=json.load(open('$SCAN_FILE')); print(d['current_user'])")
NC_USERNAME=$(python3 -c "import json; d=json.load(open('$SCAN_FILE')); print(d.get('nc_username', d['current_user']))")
CURRENT_HOME=$(python3 -c "import json; d=json.load(open('$SCAN_FILE')); print(d['current_home'])")
RECOMMENDED_DATA=$(python3 -c "import json; d=json.load(open('$SCAN_FILE')); print(d['recommendations']['data_dir'])")
RECOMMENDED_WEB=$(python3 -c "import json; d=json.load(open('$SCAN_FILE')); print(d['recommendations']['web_root'])")

read -r PHP_SERIES NC_VERSION NC_URL NC_TARBALL DOWNLOAD_TOOL < <(
  python3 -c "
import json
s = json.load(open('${SCAN_FILE}'))
p = s['install_plan']
print(p['php_series'], p['nextcloud_version'], p['download']['nextcloud_url'], p['download']['nextcloud_tarball'], p['download']['tool'])
"
)

PHP_SERIES="${NC_PHP_SERIES:-${PHP_SERIES}}"
NC_VERSION="${NC_VERSION:-$(nc_detect_nc_version "${PHP_SERIES}")}"

WEB_ROOT="${WEB_ROOT:-$RECOMMENDED_WEB}"
DATA_DIR="${DATA_DIR:-$RECOMMENDED_DATA}"
DB_NAME="nextcloud"
DB_USER="nextcloud"
DB_PASS=$(openssl rand -base64 24 | tr -d '=+/' | cut -c1-20)
ADMIN_PASS="$(nc_read_install_credential nc_admin_password)"
if [ -z "${ADMIN_PASS}" ]; then
  ADMIN_PASS=$(openssl rand -base64 16 | tr -d '=+/' | cut -c1-16)
  ADMIN_PASS_SOURCE="auto-generated"
else
  ADMIN_PASS_SOURCE="provided-in-phase-1"
fi
OUTPUT_FILE="$DOCS_DIR/03-nextcloud-core.json"

echo "=== Phase 3: Nextcloud Core (nc_install v${NC_INSTALL_VERSION}) ==="
echo "Desktop user: $CURRENT_USER | Nextcloud user: $NC_USERNAME"
echo "Stack: PHP ${PHP_SERIES} + Nextcloud ${NC_VERSION}"
echo "Download: ${DOWNLOAD_TOOL} → ${NC_TARBALL}"
echo ""

if ! command -v bzip2 >/dev/null; then
  sudo apt install -y bzip2
fi

PHP_BIN=$(nc_php_bin "${PHP_SERIES}")
PHP_VER=$("${PHP_BIN}" -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
echo "Using PHP ${PHP_VER} (${PHP_BIN})"

sudo mkdir -p "$WEB_ROOT" "$DATA_DIR"
sudo chown -R www-data:www-data "$DATA_DIR"

cd /tmp
if [ ! -f "$NC_TARBALL" ]; then
  echo "Downloading Nextcloud ${NC_VERSION}..."
  nc_download "${NC_URL}" "${NC_TARBALL}"
fi

echo "Extracting (clean web root to avoid mixed NC versions)..."
sudo rm -rf "${WEB_ROOT}"
sudo tar -xjf "$NC_TARBALL" -C /var/www/
sudo chown -R www-data:www-data "$WEB_ROOT"

echo "Setting up database..."
nc_reset_nextcloud_database "${DB_NAME}" "${DB_USER}" "${DB_PASS}"
nc_wipe_nextcloud_data_dir "${DATA_DIR}"

if [ -f "${DATA_DIR}/config.php" ]; then
  echo "Nextcloud already installed — skipping maintenance:install"
else
  echo "Running maintenance:install for user: ${NC_USERNAME}..."
  sudo -u www-data "${PHP_BIN}" "$WEB_ROOT/occ" maintenance:install \
    --database="mysql" \
    --database-name="$DB_NAME" \
    --database-host="localhost" \
    --database-user="$DB_USER" \
    --database-pass="$DB_PASS" \
    --admin-user="$NC_USERNAME" \
    --admin-pass="${ADMIN_PASS}" \
    --data-dir="$DATA_DIR"
fi

sudo -u www-data "${PHP_BIN}" "$WEB_ROOT/occ" config:system:set trusted_domains 0 --value="localhost"
sudo -u www-data "${PHP_BIN}" "$WEB_ROOT/occ" config:system:set trusted_domains 1 --value="127.0.0.1"

sudo -u www-data "${PHP_BIN}" "$WEB_ROOT/occ" config:system:set memcache.local --value='\OC\Memcache\APCu'
sudo -u www-data "${PHP_BIN}" "$WEB_ROOT/occ" config:system:set memcache.distributed --value='\OC\Memcache\Redis'
sudo -u www-data "${PHP_BIN}" "$WEB_ROOT/occ" config:system:set memcache.locking --value='\OC\Memcache\Redis'
sudo -u www-data "${PHP_BIN}" "$WEB_ROOT/occ" config:system:set redis host --value=127.0.0.1
sudo -u www-data "${PHP_BIN}" "$WEB_ROOT/occ" config:system:set redis port --value=6379
sudo -u www-data "${PHP_BIN}" "$WEB_ROOT/occ" config:system:set redis timeout --value=0.0

CREDS_FILE="$(nc_creds_file)"

python3 <<PY
import json
from datetime import datetime, timezone

out = {
  "phase": 3,
  "installer_version": "${NC_INSTALL_VERSION}",
  "timestamp": datetime.now().astimezone().isoformat(),
  "web_root": "${WEB_ROOT}",
  "data_dir": "${DATA_DIR}",
  "db": {"name": "${DB_NAME}", "user": "${DB_USER}"},
  "desktop_user": "${CURRENT_USER}",
  "nc_username": "${NC_USERNAME}",
  "admin_password_source": "${ADMIN_PASS_SOURCE}",
  "credentials_file": "${CREDS_FILE}",
  "php_series": "${PHP_SERIES}",
  "nextcloud_version": "${NC_VERSION}",
  "download_tool": "${DOWNLOAD_TOOL}",
  "config_applied": ["redis", "apcu", "trusted_domains"],
  "next_phase_input": "${OUTPUT_FILE}"
}
with open("${OUTPUT_FILE}", "w") as f:
    json.dump(out, f, indent=2)
PY

NC_CRED_NC_USERNAME="${NC_USERNAME}" \
NC_CRED_ADMIN_PASSWORD="${ADMIN_PASS}" \
NC_CRED_ADMIN_PASSWORD_SOURCE="${ADMIN_PASS_SOURCE}" \
NC_CRED_DB_NAME="${DB_NAME}" \
NC_CRED_DB_USER="${DB_USER}" \
NC_CRED_DB_PASS="${DB_PASS}" \
nc_store_install_credentials_env

echo ""
echo "=== Phase 3 Complete ==="
echo "Credentials: $(nc_creds_file) (chmod 600 — copy to password manager)"
echo "Login: ${NC_USERNAME} / (see admin_password in credentials file)"
echo "Next: bash phase-04-user-symlinks-acls.sh"
echo "================================================================"