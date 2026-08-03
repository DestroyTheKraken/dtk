#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 06: Verify monitoring + Telegram ==="
echo ""
echo "A) On PARENT (um690) UI http://127.0.0.1:19999 — child hostname visible?"
echo "B) Force failure on THIS host:"
echo "     sudo systemctl stop netdata"
echo "     # OR: sudo tailscale down"
echo "C) >>> YOU: confirm Telegram alert on your phone <<<"
echo "D) Restore:"
echo "     sudo systemctl start netdata"
echo "     # OR: sudo tailscale up"
echo "E) Add private clients.yaml entry on your laptop/um690 (not on USB for production keys)"
echo ""
echo "Phase 06 complete only after YOU confirm Telegram fired."
