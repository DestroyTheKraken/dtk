#!/usr/bin/env bash
# setup-worker-passwordless-sudo.sh — Allow SovereignAid scripts over SSH (no TTY)
#
# Run ONCE on each worker (node1, node2) with interactive sudo:
#   sudo bash ~/SovereignAid/scripts/phase1/setup-worker-passwordless-sudo.sh
#
# Or from um690 (prompts for worker sudo password):
#   bash ~/SovereignAid/scripts/phase1/bootstrap-worker-sudo.sh

set -euo pipefail

[[ "$(id -u)" -eq 0 ]] || { echo "Run with: sudo bash $0" >&2; exit 1; }

TARGET_USER="${SUDO_USER:-kraken}"
DROPIN="/etc/sudoers.d/99-smadp-sovereign"
TMP=$(mktemp)

cat > "${TMP}" << EOF
# SovereignAid / GrokOS — managed by setup-worker-passwordless-sudo.sh
# Allows phase scripts from um690 over SSH without a TTY.
${TARGET_USER} ALL=(ALL) NOPASSWD: ALL
EOF

chmod 0440 "${TMP}"
visudo -cf "${TMP}"
install -m 0440 -o root -g root "${TMP}" "${DROPIN}"
rm -f "${TMP}"

echo "[smadp-sudo] Installed ${DROPIN} for user ${TARGET_USER} on $(hostname -s)"
sudo -u "${TARGET_USER}" sudo -n true
echo "[smadp-sudo] Passwordless sudo OK"