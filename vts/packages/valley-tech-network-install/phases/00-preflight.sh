#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INV="${ROOT}/inventory.yaml"

echo "=== Phase 00: Preflight ==="
if [[ ! -f "${INV}" ]]; then
  echo "Missing inventory.yaml — copy inventory.example.yaml and fill it in."
  exit 1
fi
echo "Inventory present: ${INV}"
echo "Checklist:"
echo "  [ ] Service agreement signed if remote access or monitoring"
echo "  [ ] SKU known: base | base+monitoring | base+monitoring+appliance"
echo "  [ ] If monitoring: always-on host identified OR custom appliance sold"
echo "  [ ] If base only: do not install Netdata"
echo "Phase 00 complete (manual checklist items are on you)."
