#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== Phase 01: Network assess ==="
echo "Record in inventory.yaml / notes:"
echo "  - WAN type (Starlink/etc) and rough speed"
echo "  - Gateway IP, mesh brand, admin access path"
echo "  - SSIDs (main / guest / IoT)"
echo "  - Client pain points"
echo "  - Photos (with permission) for portfolio if useful"
echo "Optional quick probes (run if you have LAN access):"
echo "  ip route; ip neigh; ping -c2 1.1.1.1"
echo "Phase 01 complete when notes are filled."
