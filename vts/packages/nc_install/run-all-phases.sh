#!/bin/bash
# Convenience runner for all phases in sequence.
# Still respects the phase > output-doc pattern.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Running all phases for Nextcloud Laptop Drive..."
echo ""

bash "$SCRIPT_DIR/phase-01-scan-host.sh"
bash "$SCRIPT_DIR/phase-02-prereqs.sh"
bash "$SCRIPT_DIR/phase-03-nextcloud-core.sh"
bash "$SCRIPT_DIR/phase-04-user-symlinks-acls.sh"
bash "$SCRIPT_DIR/phase-05-automation.sh"

echo ""
echo "All phases completed. See phase-docs/05-complete.json"
echo "Start watcher manually if desired:"
echo "  nohup $SCRIPT_DIR/watch-and-scan.sh > /tmp/nextcloud-watch.log 2>&1 &"