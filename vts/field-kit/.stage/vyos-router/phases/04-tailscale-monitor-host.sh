#!/usr/bin/env bash
# Phase 04 — Tailscale on the monitor host (M93p tiny, appliance, client PC).
# Run ON the child host (or from USB after copy).
set -euo pipefail

echo "=== Phase 04: Tailscale on monitor host ==="

if command -v tailscale >/dev/null 2>&1 && tailscale status >/dev/null 2>&1; then
  echo "Tailscale already installed and status OK:"
  tailscale status | head -5
  echo "Phase 04 complete if this host is in YOUR tailnet and um690 can: tailscale ping $(hostname -s)"
  exit 0
fi

echo ""
echo ">>> YOU must complete authentication (browser or auth key) <<<"
echo ""
if ! command -v tailscale >/dev/null 2>&1; then
  echo "Installing Tailscale (needs internet)..."
  curl -fsSL https://tailscale.com/install.sh | sh
fi

echo "Run:"
echo "  sudo tailscale up"
echo "Then from um690:"
echo "  tailscale ping <this-hostname>"
echo "Phase 04 is DONE when that ping works."
