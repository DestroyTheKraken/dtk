#!/bin/bash
#
# phase-03-nextcloud-core.sh
# Phase 3: Download, extract, database setup, and initial Nextcloud install.
# Reads: phase-docs/01-host-scan.json and 02-prereqs.json
# Outputs: phase-docs/03-nextcloud-core.json
#
# Uses values from scan for user, home, paths.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_DIR="$SCRIPT_DIR/phase-docs"
SCAN_FILE="$DOCS_DIR/01-host-scan.json"
PREREQS_FILE="$DOCS_DIR/02-prereqs.json"

if [ ! -f "$SCAN_FILE" ]; then
    echo "ERROR: Run phase-01 first."
    exit 1
fi

# Read machine specific info
CURRENT_USER=$(python3 -c "import json,sys; d=json.load(open('$SCAN_FILE')); print(d['current_user'])")
CURRENT_HOME=$(python3 -c "import json,sys; d=json.load(open('$SCAN_FILE')); print(d['current_home'])")
RECOMMENDED_DATA=$(python3 -c "import json,sys; d=json.load(open('$SCAN_FILE')); print(d['recommendations']['data_dir'])")
RECOMMENDED_WEB=$(python3 -c "import json,sys; d=json.load(open('$SCAN_FILE')); print(d['recommendations']['web_root'])")

# Defaults (overrideable via env or later phases)
NC_VERSION="29.0.0"   # Pin a known good version; update as needed
NC_TARBALL="nextcloud-${NC_VERSION}.tar.bz2"
NC_URL="https://download.nextcloud.com/server/releases/${NC_TARBALL}"
WEB_ROOT="${WEB_ROOT:-$RECOMMENDED_WEB}"
DATA_DIR="${DATA_DIR:-$RECOMMENDED_DATA}"
DB_NAME="nextcloud"
DB_USER="nextcloud"
DB_PASS=$(openssl rand -base64 24 | tr -d '=+/' | cut -c1-20)   # random

OUTPUT_FILE="$DOCS_DIR/03-nextcloud-core.json"

echo "=== Phase 3: Nextcloud Core Installation ==="
echo "User: $CURRENT_USER"
echo "Web root: $WEB_ROOT"
echo "Data dir: $DATA_DIR"
echo ""

# Create directories
sudo mkdir -p "$WEB_ROOT" "$DATA_DIR"
sudo chown -R www-data:www-data "$DATA_DIR"

# Download Nextcloud
cd /tmp
if [ ! -f "$NC_TARBALL" ]; then
    echo "Downloading Nextcloud $NC_VERSION..."
    wget -q --show-progress "$NC_URL"
fi

echo "Extracting..."
sudo tar -xjf "$NC_TARBALL" -C /var/www/
sudo chown -R www-data:www-data "$WEB_ROOT"

# MariaDB setup (idempotent)
echo "Setting up database..."
sudo mysql -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
sudo mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
sudo mysql -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Initial occ install (non-interactive)
echo "Running initial Nextcloud installation..."
sudo -u www-data php "$WEB_ROOT/occ" maintenance:install \
    --database="mysql" \
    --database-name="$DB_NAME" \
    --database-host="localhost" \
    --database-user="$DB_USER" \
    --database-pass="$DB_PASS" \
    --admin-user="$CURRENT_USER" \
    --admin-pass="$(openssl rand -base64 16 | tr -d '=+/' | cut -c1-16)" \
    --data-dir="$DATA_DIR" || echo "Install may have already been run or will continue."

# Basic config.php hardening
sudo -u www-data php "$WEB_ROOT/occ" config:system:set trusted_domains 0 --value="localhost"
sudo -u www-data php "$WEB_ROOT/occ" config:system:set trusted_domains 1 --value="127.0.0.1"
# Will be updated with tailscale hostname later

# Redis + APCu config
sudo -u www-data php "$WEB_ROOT/occ" config:system:set memcache.local --value='\OC\Memcache\APCu'
sudo -u www-data php "$WEB_ROOT/occ" config:system:set memcache.distributed --value='\OC\Memcache\Redis'
sudo -u www-data php "$WEB_ROOT/occ" config:system:set memcache.locking --value='\OC\Memcache\Redis'
sudo -u www-data php "$WEB_ROOT/occ" config:system:set redis host --value=127.0.0.1
sudo -u www-data php "$WEB_ROOT/occ" config:system:set redis port --value=6379
sudo -u www-data php "$WEB_ROOT/occ" config:system:set redis timeout --value=0.0

# Datadirectory already set during install

cat > "$OUTPUT_FILE" << EOF
{
  "phase": 3,
  "timestamp": "$(date -Iseconds)",
  "web_root": "$WEB_ROOT",
  "data_dir": "$DATA_DIR",
  "db": {
    "name": "$DB_NAME",
    "user": "$DB_USER",
    "pass": "$DB_PASS"
  },
  "admin_user": "$CURRENT_USER",
  "nextcloud_version": "$NC_VERSION",
  "config_applied": ["redis", "apcu", "trusted_domains"],
  "next_phase_input": "$OUTPUT_FILE"
}
EOF

echo ""
echo "=== Phase 3 Complete ==="
echo "Nextcloud core installed."
echo "DB credentials saved in $OUTPUT_FILE (keep secure!)"
echo ""
echo "Next: phase-04-user-symlinks-acls.sh"
echo "================================================================"