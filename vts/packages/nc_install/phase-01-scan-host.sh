#!/bin/bash
#
# phase-01-scan-host.sh
# Phase 1: Comprehensive host discovery for Nextcloud Laptop Drive setup.
# Outputs: phase-docs/01-host-scan.json
# This document is consumed by all subsequent phase scripts.
#
# Run as the target non-root user who will own the folders.
# The script will use sudo where needed and prompt for password.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_DIR="$SCRIPT_DIR/phase-docs"
mkdir -p "$DOCS_DIR"

OUTPUT_FILE="$DOCS_DIR/01-host-scan.json"

echo "=== Phase 1: Scanning host for Nextcloud Laptop Drive setup ==="
echo "This will gather OS, user, services, disk, Tailscale, and folder info."
echo "Output will be written to $OUTPUT_FILE"
echo ""

# Basic user info
CURRENT_USER=$(whoami)
CURRENT_HOME=$(eval echo ~$CURRENT_USER)
USER_UID=$(id -u)
USER_GID=$(id -g)
USER_GROUPS=$(groups)

# OS detection
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID="$ID"
    OS_VERSION_ID="$VERSION_ID"
    OS_VERSION_CODENAME="${VERSION_CODENAME:-}"
    OS_PRETTY="$PRETTY_NAME"
else
    OS_ID="unknown"
    OS_VERSION_ID="unknown"
    OS_VERSION_CODENAME=""
    OS_PRETTY="Unknown Linux"
fi

# Architecture
ARCH=$(uname -m)

# Sudo check
if sudo -n true 2>/dev/null; then
    SUDO_CACHED="true"
else
    SUDO_CACHED="false (will prompt)"
fi

# Web server detection
WEB_SERVER="none"
if systemctl is-active --quiet apache2 2>/dev/null || command -v apache2 >/dev/null; then
    WEB_SERVER="apache2"
elif systemctl is-active --quiet nginx 2>/dev/null || command -v nginx >/dev/null; then
    WEB_SERVER="nginx"
fi

# PHP detection
PHP_VERSION=""
PHP_BINARY=""
if command -v php >/dev/null; then
    PHP_BINARY=$(command -v php)
    PHP_VERSION=$($PHP_BINARY -r 'echo PHP_VERSION;' 2>/dev/null || echo "unknown")
fi

PHP_FPM_SERVICE=""
if systemctl list-unit-files | grep -q php.*fpm; then
    PHP_FPM_SERVICE=$(systemctl list-unit-files | grep -o 'php[0-9.]*-fpm' | head -1 || echo "")
fi

# Database detection
DB_TYPE="none"
DB_VERSION=""
if command -v mariadb >/dev/null || command -v mysql >/dev/null; then
    if systemctl is-active --quiet mariadb 2>/dev/null || systemctl is-active --quiet mysql 2>/dev/null; then
        DB_TYPE="mariadb"
        DB_VERSION=$(mariadb --version 2>/dev/null | head -1 || mysql --version 2>/dev/null | head -1 || "unknown")
    fi
fi

# Redis
REDIS_STATUS="not running"
if systemctl is-active --quiet redis-server 2>/dev/null || systemctl is-active --quiet redis 2>/dev/null; then
    REDIS_STATUS="running"
fi

# Tailscale
TAILSCALE_INSTALLED="false"
TAILSCALE_STATUS="not running"
TAILSCALE_USER=""
TAILSCALE_IP=""
if command -v tailscale >/dev/null; then
    TAILSCALE_INSTALLED="true"
    if tailscale status --json 2>/dev/null | grep -q '"BackendState":"Running"'; then
        TAILSCALE_STATUS="running"
        TAILSCALE_USER=$(tailscale status --json 2>/dev/null | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("Self",{}).get("UserID","") or "unknown")' 2>/dev/null || echo "unknown")
        TAILSCALE_IP=$(tailscale ip -4 2>/dev/null | head -1 || echo "")
    fi
fi

# Disk space (important paths)
DISK_ROOT=$(df -h / | awk 'NR==2 {print $4}')
DISK_VAR=$(df -h /var 2>/dev/null | awk 'NR==2 {print $4}' || echo "N/A")
DISK_HOME=$(df -h /home 2>/dev/null | awk 'NR==2 {print $4}' || echo "N/A")

# Memory
MEM_TOTAL=$(free -h | awk '/Mem:/ {print $2}')
MEM_AVAIL=$(free -h | awk '/Mem:/ {print $7}')

# Existing Nextcloud detection
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

# Current user standard folders (XDG + common)
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

# Apache/PHP config hints
APACHE_CONF_DIR="/etc/apache2"
if [ -d "$APACHE_CONF_DIR" ]; then
    APACHE_USER=$(grep -oP '(?<=^User ).*' "$APACHE_CONF_DIR/apache2.conf" 2>/dev/null || echo "www-data")
else
    APACHE_USER="www-data"
fi

# Generate JSON output document
cat > "$OUTPUT_FILE" << EOF
{
  "scan_timestamp": "$(date -Iseconds)",
  "current_user": "$CURRENT_USER",
  "current_home": "$CURRENT_HOME",
  "user_uid": $USER_UID,
  "user_gid": $USER_GID,
  "user_groups": "$USER_GROUPS",
  "os": {
    "id": "$OS_ID",
    "version_id": "$OS_VERSION_ID",
    "codename": "$OS_VERSION_CODENAME",
    "pretty_name": "$OS_PRETTY",
    "arch": "$ARCH"
  },
  "sudo": {
    "cached": $SUDO_CACHED
  },
  "web_server": "$WEB_SERVER",
  "php": {
    "version": "$PHP_VERSION",
    "binary": "$PHP_BINARY",
    "fpm_service": "$PHP_FPM_SERVICE"
  },
  "database": {
    "type": "$DB_TYPE",
    "version": "$DB_VERSION"
  },
  "redis": {
    "status": "$REDIS_STATUS"
  },
  "tailscale": {
    "installed": $TAILSCALE_INSTALLED,
    "status": "$TAILSCALE_STATUS",
    "user": "$TAILSCALE_USER",
    "ipv4": "$TAILSCALE_IP"
  },
  "disk": {
    "root_avail": "$DISK_ROOT",
    "var_avail": "$DISK_VAR",
    "home_avail": "$DISK_HOME"
  },
  "memory": {
    "total": "$MEM_TOTAL",
    "available": "$MEM_AVAIL"
  },
  "nextcloud_existing": {
    "web_root": "$NEXTCLOUD_WEB_ROOT",
    "data_dir": "$NEXTCLOUD_DATA_DIR",
    "version": "$NEXTCLOUD_VERSION"
  },
  "apache": {
    "user": "$APACHE_USER",
    "conf_dir": "$APACHE_CONF_DIR"
  },
  "existing_user_folders": $(printf '%s\n' "${EXISTING_FOLDERS[@]}" | jq -R . | jq -s .),
  "folder_sizes": $(printf '%s\n' "${FOLDER_SIZES[@]}" | jq -R . | jq -s .),
  "recommendations": {
    "data_dir": "/var/lib/nextcloud/data",
    "web_root": "/var/www/nextcloud",
    "default_folders": ["Documents", "Pictures", "Music", "Videos", "Public", "Templates", "Downloads", "Desktop", "Backups", "Notes", "Projects"]
  }
}
EOF

echo ""
echo "=== Phase 1 Complete ==="
echo "Host scan document generated: $OUTPUT_FILE"
echo ""
echo "Key findings:"
echo "  User: $CURRENT_USER (home: $CURRENT_HOME)"
echo "  OS: $OS_PRETTY ($ARCH)"
echo "  Web server: $WEB_SERVER | PHP: $PHP_VERSION"
echo "  DB: $DB_TYPE | Redis: $REDIS_STATUS"
echo "  Tailscale: $TAILSCALE_STATUS (installed=$TAILSCALE_INSTALLED)"
echo "  Existing folders found: ${#EXISTING_FOLDERS[@]}"
echo ""
echo "Next: Run phase-02-prereqs.sh (it will read this document)"
echo "================================================================"