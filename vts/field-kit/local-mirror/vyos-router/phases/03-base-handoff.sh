#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHEET="${ROOT}/configs/handoff-sheet.md"

echo "=== Phase 03: Base handoff ==="
echo "Fill handoff sheet: ${SHEET}"
echo "Verify with client:"
echo "  [ ] Main WiFi works on 1–2 devices"
echo "  [ ] Guest WiFi works if configured"
echo "  [ ] Smart home / target apps work if in scope"
echo "  [ ] Client knows how to change WiFi password (or you documented it)"
echo ""
echo "If SKU is base only → STOP. Do not run phases 04–06."
echo "Phase 03 complete."
