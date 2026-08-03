#!/bin/bash
#
# Future distribution pattern (curl / git — like Tailscale install.sh).
# Prefer install-nc-hub.sh for published installs; USB tarball for offline field work.
#
# When published:
#   curl -fsSL https://YOUR_HOST/nc_install_v3.tar.gz | tar -xz
#   cd nc_install_v3 && bash install.sh
#
# Or single pipe (after hosting install.sh + tarball):
#   curl -fsSL https://YOUR_HOST/install-nc-hub.sh | bash
#
set -euo pipefail

NC_INSTALL_REPO_URL="${NC_INSTALL_REPO_URL:-}"
NC_INSTALL_TARBALL_URL="${NC_INSTALL_TARBALL_URL:-}"

if [ -z "${NC_INSTALL_TARBALL_URL}" ]; then
  cat <<EOF
nc_install_v3 fetch-and-install

Set NC_INSTALL_TARBALL_URL to a published tarball, then re-run:

  export NC_INSTALL_TARBALL_URL='https://example.com/nc_install_v3.tar.gz'
  curl -fsSL https://example.com/fetch-and-install.sh | bash

Current field SOP:
  1. Copy kit via USB or rsync: rsync -av ./nc-lin-cs/ user@host:~/nc-lin-cs/
  2. On target: cd ~/nc-lin-cs && bash install.sh

EOF
  exit 1
fi

WORKDIR="$(mktemp -d)"
trap 'rm -rf "${WORKDIR}"' EXIT

echo "Downloading ${NC_INSTALL_TARBALL_URL}..."
curl -fsSL "${NC_INSTALL_TARBALL_URL}" | tar -xz -C "${WORKDIR}"
cd "${WORKDIR}/nc_install_v3"
bash install.sh
