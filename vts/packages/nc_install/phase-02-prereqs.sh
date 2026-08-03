#!/bin/bash
#
# phase-02-prereqs.sh
# Phase 2: Install system prerequisites based on Phase 1 scan.
# Reads: phase-docs/01-host-scan.json
# Outputs: phase-docs/02-prereqs.json
#
# Must be run after phase-01-scan-host.sh
# Will use sudo and prompt for password as needed.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_DIR="$SCRIPT_DIR/phase-docs"
INPUT_FILE="$DOCS_DIR/01-host-scan.json"
OUTPUT_FILE="$DOCS_DIR/02-prereqs.json"

if [ ! -f "$INPUT_FILE" ]; then
    echo "ERROR: $INPUT_FILE not found. Run phase-01-scan-host.sh first."
    exit 1
fi

# Parse scan with python (portable)
CURRENT_USER=$(python3 -c "import json,sys; print(json.load(open('$INPUT_FILE'))['current_user'])")
CURRENT_HOME=$(python3 -c "import json,sys; print(json.load(open('$INPUT_FILE'))['current_home'])")
OS_ID=$(python3 -c "import json,sys; print(json.load(open('$INPUT_FILE'))['os']['id'])")
WEB_SERVER=$(python3 -c "import json,sys; print(json.load(open('$INPUT_FILE'))['web_server'])")
PHP_VERSION=$(python3 -c "import json,sys; print(json.load(open('$INPUT_FILE'))['php']['version'])")

echo "=== Phase 2: Installing Prerequisites ==="
echo "Using info from $INPUT_FILE"
echo "Target user: $CURRENT_USER"
echo ""

if [ "$OS_ID" != "ubuntu" ] && [ "$OS_ID" != "linuxmint" ] && [ "$OS_ID" != "debian" ]; then
    echo "WARNING: This script is optimized for Ubuntu/Mint/Debian. Proceeding anyway..."
fi

echo "Updating package lists..."
sudo apt update -y

echo "Installing base packages (this may take a while)..."

# Core packages for Nextcloud on Ubuntu 24.04 / Mint 22
sudo apt install -y \
    apache2 \
    php8.3 php8.3-fpm php8.3-mysql php8.3-redis php8.3-apcu \
    php8.3-gd php8.3-curl php8.3-xml php8.3-zip php8.3-mbstring \
    php8.3-bcmath php8.3-intl php8.3-bz2 php8.3-imagick \
    mariadb-server mariadb-client \
    redis-server \
    unzip curl wget \
    inotify-tools \
    acl \
    libapache2-mod-php8.3

# Enable necessary modules
echo "Enabling Apache and PHP modules..."
sudo a2enmod rewrite headers env dir mime ssl
sudo a2enconf php8.3-fpm
sudo systemctl restart apache2 php8.3-fpm

# Enable and start services
echo "Enabling services..."
sudo systemctl enable --now apache2 mariadb redis-server php8.3-fpm

# Basic PHP tuning for Nextcloud
PHP_INI="/etc/php/8.3/fpm/php.ini"
if [ -f "$PHP_INI" ]; then
    sudo sed -i 's/^memory_limit = .*/memory_limit = 512M/' "$PHP_INI"
    sudo sed -i 's/^upload_max_filesize = .*/upload_max_filesize = 512M/' "$PHP_INI"
    sudo sed -i 's/^post_max_size = .*/post_max_size = 512M/' "$PHP_INI"
    sudo sed -i 's/^max_execution_time = .*/max_execution_time = 300/' "$PHP_INI"
    sudo sed -i 's/^;opcache.enable=.*/opcache.enable=1/' "$PHP_INI"
    sudo sed -i 's/^;opcache.memory_consumption=.*/opcache.memory_consumption=256/' "$PHP_INI"
    sudo systemctl restart php8.3-fpm
fi

# Secure MariaDB (non-interactive basic)
echo "Basic MariaDB setup (you may be prompted if root password not set)..."
sudo mysql -e "DELETE FROM mysql.user WHERE User='';" 2>/dev/null || true
sudo mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');" 2>/dev/null || true
sudo mysql -e "DROP DATABASE IF EXISTS test;" 2>/dev/null || true
sudo mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';" 2>/dev/null || true
sudo mysql -e "FLUSH PRIVILEGES;" 2>/dev/null || true

cat > "$OUTPUT_FILE" << EOF
{
  "phase": 2,
  "timestamp": "$(date -Iseconds)",
  "prereqs_installed": true,
  "packages": ["apache2", "php8.3-fpm", "mariadb-server", "redis-server", "inotify-tools", "acl"],
  "services": {
    "apache2": "enabled",
    "mariadb": "enabled",
    "redis": "enabled",
    "php8.3-fpm": "enabled"
  },
  "php_tuned": true,
  "next_phase_input": "$OUTPUT_FILE"
}
EOF

echo ""
echo "=== Phase 2 Complete ==="
echo "Prerequisites installed and basic services configured."
echo "Document: $OUTPUT_FILE"
echo ""
echo "Next: Run phase-03-nextcloud-core.sh"
echo "================================================================"