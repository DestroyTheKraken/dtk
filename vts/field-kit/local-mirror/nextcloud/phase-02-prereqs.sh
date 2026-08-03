#!/bin/bash
#
# Phase 2: Install prerequisites using install_plan from Phase 1.
# Reads: phase-docs/01-host-scan.json
# Outputs: phase-docs/02-prereqs.json

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NC_INSTALL_SCRIPT_DIR="${SCRIPT_DIR}"
# shellcheck source=nc-common.sh
source "${SCRIPT_DIR}/nc-common.sh"

DOCS_DIR="$SCRIPT_DIR/phase-docs"
INPUT_FILE="$DOCS_DIR/01-host-scan.json"
OUTPUT_FILE="$DOCS_DIR/02-prereqs.json"

if [ ! -f "$INPUT_FILE" ]; then
  echo "ERROR: $INPUT_FILE not found. Run phase-01-scan-host.sh first."
  exit 1
fi

CURRENT_USER=$(python3 -c "import json; print(json.load(open('$INPUT_FILE'))['current_user'])")
OS_ID=$(python3 -c "import json; print(json.load(open('$INPUT_FILE'))['os']['id'])")
DEBIAN_FAMILY=$(python3 -c "import json; print(json.load(open('$INPUT_FILE'))['os']['debian_family'])")
PHP_SERIES=$(python3 -c "import json; print(json.load(open('$INPUT_FILE'))['install_plan']['php_series'])")
NC_VERSION=$(python3 -c "import json; print(json.load(open('$INPUT_FILE'))['install_plan']['nextcloud_version'])")
PPA_STRATEGY=$(python3 -c "import json; print(json.load(open('$INPUT_FILE'))['install_plan']['php_ppa_strategy'])")

echo "=== Phase 2: Prerequisites (nc_install v${NC_INSTALL_VERSION}) ==="
echo "Target user: $CURRENT_USER"
echo "Install plan: PHP ${PHP_SERIES} + Nextcloud ${NC_VERSION} (PPA: ${PPA_STRATEGY})"
echo ""

if [ "${DEBIAN_FAMILY}" != "True" ] && [ "${DEBIAN_FAMILY}" != "true" ]; then
  echo "WARNING: Not a recognized Debian-family OS (${OS_ID}). Proceeding with apt — verify manually."
fi

nc_remove_broken_php_ppa

echo "Ensuring curl/wget for downloads..."
nc_ensure_download_tool >/dev/null

echo "Updating package lists..."
sudo apt update -y

# Re-validate PHP series is installable; use PPA only when plan allows.
if ! nc_php_series_available "${PHP_SERIES}"; then
  if [ "${PPA_STRATEGY}" = "use_ondrej_if_needed" ]; then
    nc_ensure_php_series_available "${PHP_SERIES}"
  else
    echo "ERROR: php${PHP_SERIES}-fpm not available and PPA strategy is ${PPA_STRATEGY}"
    exit 1
  fi
fi

PHP_FPM="php${PHP_SERIES}-fpm"
echo "Installing packages for PHP ${PHP_SERIES}..."

sudo apt install -y \
  apache2 \
  "php${PHP_SERIES}" "${PHP_FPM}" "php${PHP_SERIES}-mysql" "php${PHP_SERIES}-redis" "php${PHP_SERIES}-apcu" \
  "php${PHP_SERIES}-gd" "php${PHP_SERIES}-curl" "php${PHP_SERIES}-xml" "php${PHP_SERIES}-zip" "php${PHP_SERIES}-mbstring" \
  "php${PHP_SERIES}-bcmath" "php${PHP_SERIES}-intl" "php${PHP_SERIES}-bz2" "php${PHP_SERIES}-imagick" \
  mariadb-server mariadb-client \
  redis-server \
  unzip bzip2 curl wget jq python3 \
  inotify-tools \
  acl \
  "libapache2-mod-php${PHP_SERIES}"

echo "Configuring Apache for PHP ${PHP_SERIES}..."
nc_configure_apache_php "${PHP_SERIES}"

echo "Enabling services..."
sudo systemctl enable --now apache2 mariadb redis-server "${PHP_FPM}"

PHP_INI="/etc/php/${PHP_SERIES}/fpm/php.ini"
if [ -f "$PHP_INI" ]; then
  sudo sed -i 's/^memory_limit = .*/memory_limit = 512M/' "$PHP_INI"
  sudo sed -i 's/^upload_max_filesize = .*/upload_max_filesize = 512M/' "$PHP_INI"
  sudo sed -i 's/^post_max_size = .*/post_max_size = 512M/' "$PHP_INI"
  sudo sed -i 's/^max_execution_time = .*/max_execution_time = 300/' "$PHP_INI"
  sudo sed -i 's/^;opcache.enable=.*/opcache.enable=1/' "$PHP_INI"
  sudo sed -i 's/^;opcache.memory_consumption=.*/opcache.memory_consumption=256/' "$PHP_INI"
  sudo systemctl restart "${PHP_FPM}"
fi

echo "Basic MariaDB hardening..."
sudo mysql -e "DELETE FROM mysql.user WHERE User='';" 2>/dev/null || true
sudo mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');" 2>/dev/null || true
sudo mysql -e "DROP DATABASE IF EXISTS test;" 2>/dev/null || true
sudo mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';" 2>/dev/null || true
sudo mysql -e "FLUSH PRIVILEGES;" 2>/dev/null || true

python3 <<PY
import json
from datetime import datetime, timezone

out = {
  "phase": 2,
  "installer_version": "${NC_INSTALL_VERSION}",
  "timestamp": datetime.now().astimezone().isoformat(),
  "prereqs_installed": True,
  "php_series": "${PHP_SERIES}",
  "nextcloud_version": "${NC_VERSION}",
  "php_ppa_strategy": "${PPA_STRATEGY}",
  "packages": ["apache2", "${PHP_FPM}", "mariadb-server", "redis-server", "inotify-tools", "acl", "bzip2", "curl", "wget"],
  "services": {
    "apache2": "enabled",
    "mariadb": "enabled",
    "redis": "enabled",
    "${PHP_FPM}": "enabled"
  },
  "php_tuned": True,
  "next_phase_input": "${OUTPUT_FILE}"
}
with open("${OUTPUT_FILE}", "w") as f:
    json.dump(out, f, indent=2)
PY

echo ""
echo "=== Phase 2 Complete ==="
echo "Document: $OUTPUT_FILE"
echo "Next: bash phase-03-nextcloud-core.sh"
echo "================================================================"