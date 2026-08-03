#!/usr/bin/env bash
# Phase 05 — Netdata child. Prefer child/install-child.sh with stream env.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHILD="${ROOT}/child/install-child.sh"
ENV_CANDIDATES=(
  "${ROOT}/secrets/netdata-stream.env"
  "${ROOT}/child/netdata-stream.env"
  "${HOME}/.config/valley-tech/netdata-stream.env"
)

echo "=== Phase 05: Netdata child ==="

ENV_FILE=""
for e in "${ENV_CANDIDATES[@]}"; do
  if [[ -f "${e}" ]]; then
    ENV_FILE="${e}"
    break
  fi
done

if [[ -z "${ENV_FILE}" ]]; then
  echo "No netdata-stream.env found."
  echo ""
  echo ">>> YOU (on um690 parent, after install-parent.sh):"
  echo "  cat ~/.config/valley-tech/netdata-stream.env"
  echo ">>> YOU: copy that file onto this host (USB secrets/ or scp) as:"
  echo "  ${ROOT}/secrets/netdata-stream.env"
  echo "Then re-run: sudo bash $0"
  exit 1
fi

[[ "$(id -u)" -eq 0 ]] || { echo "Re-run with sudo"; exit 1; }
bash "${CHILD}" "${ENV_FILE}"
