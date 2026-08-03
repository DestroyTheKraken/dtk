#!/bin/bash
#
# phase-04-user-symlinks-acls.sh
# Phase 4: Create main user, set up outward symlinks, apply ACLs.
# Reads previous phase docs.
# Outputs: phase-docs/04-user-symlinks.json

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_DIR="$SCRIPT_DIR/phase-docs"
SCAN_FILE="$DOCS_DIR/01-host-scan.json"
CORE_FILE="$DOCS_DIR/03-nextcloud-core.json"

if [ ! -f "$SCAN_FILE" ] || [ ! -f "$CORE_FILE" ]; then
    echo "ERROR: Run previous phases first."
    exit 1
fi

CURRENT_USER=$(python3 -c "import json,sys; print(json.load(open('$SCAN_FILE'))['current_user'])")
CURRENT_HOME=$(python3 -c "import json,sys; print(json.load(open('$SCAN_FILE'))['current_home'])")
WEB_ROOT=$(python3 -c "import json,sys; print(json.load(open('$CORE_FILE'))['web_root'])")
DATA_DIR=$(python3 -c "import json,sys; print(json.load(open('$CORE_FILE'))['data_dir'])")

# Folders to set up (customize per user)
FOLDERS=(Documents Pictures Music Videos Public Templates Downloads Desktop Backups Notes Projects)

NC_FILES="$DATA_DIR/$CURRENT_USER/files"

OUTPUT_FILE="$DOCS_DIR/04-user-symlinks.json"

echo "=== Phase 4: User, Outward Symlinks & ACLs ==="
echo "User: $CURRENT_USER"
echo "Home: $CURRENT_HOME"
echo ""

# Ensure user exists in Nextcloud (create if needed)
if ! sudo -u www-data php "$WEB_ROOT/occ" user:list | grep -q "$CURRENT_USER"; then
    echo "Creating Nextcloud user $CURRENT_USER..."
    # Prompt for password interactively
    read -s -p "Enter password for Nextcloud user '$CURRENT_USER': " NC_PASS
    echo
    sudo -u www-data php "$WEB_ROOT/occ" user:add --display-name="$CURRENT_USER" --group=admin "$CURRENT_USER" --password-from-env <<< "$NC_PASS" || true
fi

# Create real local folders if missing
echo "Ensuring real local folders exist..."
for d in "${FOLDERS[@]}"; do
    mkdir -p "$CURRENT_HOME/$d"
done

# Create outward symlinks in Nextcloud
echo "Creating outward symlinks (Nextcloud -> real local folders)..."
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

# Photos alias (convenience)
if [ -d "$CURRENT_HOME/Pictures" ]; then
    sudo -u www-data ln -sfn "$CURRENT_HOME/Pictures" "$NC_FILES/Photos" 2>/dev/null || true
fi

# Apply ACLs so www-data can access real folders
echo "Applying ACLs..."
sudo setfacl -m u:www-data:rx "$CURRENT_HOME" || true

for d in "${FOLDERS[@]}"; do
    dir="$CURRENT_HOME/$d"
    if [ -d "$dir" ]; then
        sudo setfacl -R -m u:www-data:rwx,u:"$CURRENT_USER":rwx "$dir" || true
        sudo setfacl -d -R -m u:www-data:rwx,u:"$CURRENT_USER":rwx "$dir" || true
        sudo chgrp -R nextcloud-shared "$dir" 2>/dev/null || true
        sudo chmod -R g+rwX "$dir" 2>/dev/null || true
    fi
done

# Also make sure group nextcloud-shared exists
sudo groupadd -f nextcloud-shared || true
sudo usermod -aG nextcloud-shared "$CURRENT_USER" || true
sudo usermod -aG nextcloud-shared www-data || true

sudo -u www-data chown -h www-data:www-data "$NC_FILES"/* 2>/dev/null || true

cat > "$OUTPUT_FILE" << EOF
{
  "phase": 4,
  "timestamp": "$(date -Iseconds)",
  "main_user": "$CURRENT_USER",
  "real_folders": $(printf '%s\n' "${FOLDERS[@]}" | jq -R . | jq -s .),
  "symlinks_created": true,
  "acls_applied": true,
  "next_phase_input": "$OUTPUT_FILE"
}
EOF

echo ""
echo "=== Phase 4 Complete ==="
echo "Outward symlinks and ACLs configured."
echo ""
echo "Next: phase-05-automation.sh"
echo "================================================================"