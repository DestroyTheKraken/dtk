#!/bin/bash
# Build distributable tarball for USB / curl install.
# Run on build machine: bash package-release.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=nc-common.sh
source "${SCRIPT_DIR}/nc-common.sh"

DTK_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
OUT_DIR="${NC_INSTALL_RELEASE_DIR:-${DTK_ROOT}/dist}"
ARCHIVE="${OUT_DIR}/nc-lin-cs-${NC_INSTALL_VERSION}.tar.gz"
STAGING="$(mktemp -d)"
trap 'rm -rf "${STAGING}"' EXIT

mkdir -p "${OUT_DIR}"
rsync -a \
  --exclude 'phase-docs/*' \
  --exclude 'dist' \
  --exclude '.git' \
  "${SCRIPT_DIR}/" "${STAGING}/nc-lin-cs/"

tar -czf "${ARCHIVE}" -C "${STAGING}" nc-lin-cs
sha256sum "${ARCHIVE}" > "${ARCHIVE}.sha256"

echo "Built: ${ARCHIVE}"
echo "SHA256: $(cut -d' ' -f1 "${ARCHIVE}.sha256")"
echo ""
echo "USB / manual:"
echo "  tar -xzf ${ARCHIVE} && cd nc-lin-cs && bash install.sh"
echo ""
echo "curl (after hosting tarball):"
echo "  curl -fsSL https://YOUR_HOST/nc-lin-cs-${NC_INSTALL_VERSION}.tar.gz | tar -xz"
echo "  cd nc-lin-cs && bash install.sh"
