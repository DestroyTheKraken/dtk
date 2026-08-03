#!/bin/bash
# Remove temporary install sudoers (run after verify).
set -euo pipefail

USER="${1:-$(whoami)}"
FILE="/etc/sudoers.d/nc-install-temp-${USER}"

if [ -f "${FILE}" ]; then
  sudo rm -f "${FILE}"
  echo "Removed ${FILE}"
fi