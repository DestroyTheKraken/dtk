#!/bin/bash
#
# Remote one-liner bootstrap (Tailscale / curl style).
#
#   curl -fsSL https://raw.githubusercontent.com/DestroyTheKraken/nc-lin-cs/main/install-nc-hub.sh | bash
#
# Or pinned tarball from GitHub Releases:
#   NC_INSTALL_TARBALL_URL='https://github.com/DestroyTheKraken/nc-lin-cs/releases/download/v3.0.0/nc-lin-cs-3.0.0.tar.gz' \
#     curl -fsSL https://raw.githubusercontent.com/DestroyTheKraken/nc-lin-cs/main/install-nc-hub.sh | bash
#
set -euo pipefail

NC_INSTALL_VERSION="${NC_INSTALL_VERSION:-3.0.0}"
NC_INSTALL_TARBALL_URL="${NC_INSTALL_TARBALL_URL:-}"
NC_INSTALL_DIR="${NC_INSTALL_DIR:-${HOME}/nc-lin-cs}"

if [ -z "${NC_INSTALL_TARBALL_URL}" ]; then
  NC_INSTALL_TARBALL_URL="https://github.com/DestroyTheKraken/nc-lin-cs/archive/refs/heads/main.tar.gz"
  NC_INSTALL_EXTRACT_SUBDIR="nc-lin-cs-main"
else
  NC_INSTALL_EXTRACT_SUBDIR="nc-lin-cs"
fi

WORKDIR="$(mktemp -d)"
trap 'rm -rf "${WORKDIR}"' EXIT

echo "=== nc_install_v3 remote bootstrap v${NC_INSTALL_VERSION} ==="
echo "Downloading kit..."
curl -fsSL "${NC_INSTALL_TARBALL_URL}" | tar -xz -C "${WORKDIR}"

SRC="${WORKDIR}/${NC_INSTALL_EXTRACT_SUBDIR}"
if [ ! -d "${SRC}" ]; then
  echo "ERROR: expected ${SRC} in archive — set NC_INSTALL_TARBALL_URL to a nc-lin-cs tarball"
  exit 1
fi

rm -rf "${NC_INSTALL_DIR}"
cp -a "${SRC}" "${NC_INSTALL_DIR}"
cd "${NC_INSTALL_DIR}"
chmod +x ./*.sh

echo "Kit ready: ${NC_INSTALL_DIR}"
exec bash install.sh