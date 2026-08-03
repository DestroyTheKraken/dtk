#!/bin/bash
#
# Phase 4: Outward symlinks + ACLs. Symlink config driven by install_plan.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NC_INSTALL_SCRIPT_DIR="${SCRIPT_DIR}"
# shellcheck source=nc-common.sh
source "${SCRIPT_DIR}/nc-common.sh"

DOCS_DIR="$SCRIPT_DIR/phase-docs"
SCAN_FILE="$DOCS_DIR/01-host-scan.json"
CORE_FILE="$DOCS_DIR/03-nextcloud-core.json"

if [ ! -f "$SCAN_FILE" ] || [ ! -f "$CORE_FILE" ]; then
  echo "ERROR: Run previous phases first."
  exit 1
fi

CURRENT_USER=$(python3 -c "import json; print(json.load(open('$SCAN_FILE'))['current_user'])")
NC_USERNAME=$(python3 -c "import json; d=json.load(open('$SCAN_FILE')); print(d.get('nc_username', d['current_user']))")
CURRENT_HOME=$(python3 -c "import json; print(json.load(open('$SCAN_FILE'))['current_home'])")
WEB_ROOT=$(python3 -c "import json; print(json.load(open('$CORE_FILE'))['web_root'])")
DATA_DIR=$(python3 -c "import json; print(json.load(open('$CORE_FILE'))['data_dir'])")
PHP_SERIES=$(python3 -c "import json; d=json.load(open('$SCAN_FILE')); print(d['install_plan']['php_series'])")
NC_VERSION=$(python3 -c "import json; d=json.load(open('$SCAN_FILE')); print(d['install_plan']['nextcloud_version'])")

FOLDERS=(Documents Pictures Music Videos Public Templates Downloads Desktop Backups Notes Projects)
OUTPUT_FILE="$DOCS_DIR/04-user-symlinks.json"
NC_FILES="$DATA_DIR/${NC_USERNAME}/files"
PHP_BIN=$(nc_php_bin "${PHP_SERIES}")

echo "=== Phase 4: Outward Symlinks & ACLs (nc_install v${NC_INSTALL_VERSION}) ==="
echo "Desktop: ${CURRENT_USER} | NC user: ${NC_USERNAME}"
echo "Symlink keys: $(nc_symlink_config_plan "${NC_VERSION}")"
echo ""

if ! sudo -u www-data "${PHP_BIN}" "$WEB_ROOT/occ" user:list 2>/dev/null | grep -qE "(^|\s)${NC_USERNAME}(:|\s)"; then
  echo "Nextcloud user '${NC_USERNAME}' not found — creating..."
  read -s -p "Enter password for Nextcloud user '${NC_USERNAME}': " NC_PASS
  echo
  OC_PASS="${NC_PASS}" sudo -E -u www-data "${PHP_BIN}" "$WEB_ROOT/occ" user:add \
    --display-name="${NC_USERNAME}" "${NC_USERNAME}" --password-from-env || true
fi

echo "Ensuring real local folders..."
for d in "${FOLDERS[@]}"; do
  mkdir -p "$CURRENT_HOME/$d"
done

echo "Creating outward symlinks..."
sudo -u www-data mkdir -p "$NC_FILES"
sudo -u www-data touch "$NC_FILES/.ocdata" || true

for d in "${FOLDERS[@]}"; do
  target="$CURRENT_HOME/$d"
  link="$NC_FILES/$d"
  if [ -e "$link" ] || [ -L "$link" ]; then
    sudo -u www-data rm -rf "$link"
  fi
  sudo -u www-data ln -s "$target" "$link"
  echo "  Linked $d"
done

if [ -d "$CURRENT_HOME/Pictures" ]; then
  sudo -u www-data ln -sfn "$CURRENT_HOME/Pictures" "$NC_FILES/Photos" 2>/dev/null || true
  ln -sfn "$NC_FILES/Photos" "$CURRENT_HOME/.Photos" 2>/dev/null || true
fi

echo "Applying ACLs..."
sudo setfacl -m u:www-data:rx "$CURRENT_HOME" || true
sudo groupadd -f nextcloud-shared || true
sudo usermod -aG nextcloud-shared "$CURRENT_USER" || true
sudo usermod -aG nextcloud-shared www-data || true

for d in "${FOLDERS[@]}"; do
  dir="$CURRENT_HOME/$d"
  if [ -d "$dir" ]; then
    sudo setfacl -R -m u:www-data:rwx,u:"$CURRENT_USER":rwx "$dir" || true
    sudo setfacl -d -R -m u:www-data:rwx,u:"$CURRENT_USER":rwx "$dir" || true
    sudo chgrp -R nextcloud-shared "$dir" 2>/dev/null || true
    sudo chmod -R g+rwX "$dir" 2>/dev/null || true
  fi
done

sudo -u www-data chown -h www-data:www-data "$NC_FILES"/* 2>/dev/null || true

echo "Enabling outward symlinks per install plan..."
nc_enable_outward_symlinks "${WEB_ROOT}" "${PHP_BIN}" "${NC_VERSION}"
nc_patch_config_allow_symlinks "${WEB_ROOT}/config/config.php"
sudo systemctl restart "php${PHP_SERIES}-fpm" 2>/dev/null || true
sudo -u www-data "${PHP_BIN}" "${WEB_ROOT}/occ" files:scan "${NC_USERNAME}" || true

python3 <<PY
import json
from datetime import datetime, timezone

out = {
  "phase": 4,
  "installer_version": "${NC_INSTALL_VERSION}",
  "timestamp": datetime.now().astimezone().isoformat(),
  "desktop_user": "${CURRENT_USER}",
  "nc_username": "${NC_USERNAME}",
  "symlink_keys_applied": json.loads('$(nc_symlink_config_plan "${NC_VERSION}")'),
  "real_folders": $(printf '%s\n' "${FOLDERS[@]}" | jq -R . | jq -s .),
  "symlinks_created": True,
  "acls_applied": True,
  "next_phase_input": "${OUTPUT_FILE}"
}
with open("${OUTPUT_FILE}", "w") as f:
    json.dump(out, f, indent=2)
PY

echo ""
echo "=== Phase 4 Complete ==="
echo "Next: bash phase-05-automation.sh"
echo "================================================================"