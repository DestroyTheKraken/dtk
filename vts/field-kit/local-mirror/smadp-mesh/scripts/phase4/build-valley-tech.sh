#!/usr/bin/env bash
# build-valley-tech.sh — Build Valley Tech Support Hugo site
#
# Run on um690: bash ~/SovereignAid/scripts/phase4/build-valley-tech.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SITE="${REPO}/k8s/websites/valley-tech-support"
HUGO_BIN="${HUGO_BIN:-${HOME}/.local/bin/hugo}"
HUGO_VERSION="${HUGO_VERSION:-0.139.4}"

log() { echo "[build-vts] $*"; }
die() { echo "[build-vts] ERROR: $*" >&2; exit 1; }

[[ -d "${SITE}" ]] || die "Missing ${SITE}"

install_hugo() {
    if [[ -x "${HUGO_BIN}" ]] && "${HUGO_BIN}" version &>/dev/null; then
        return 0
    fi
    log "Installing Hugo ${HUGO_VERSION}..."
    install -d "${HOME}/.local/bin"
    local arch os tarball url
    arch=$(uname -m)
    os=$(uname -s | tr '[:upper:]' '[:lower:]')
    [[ "${arch}" == "x86_64" ]] && arch=amd64
    tarball="hugo_extended_${HUGO_VERSION}_${os}-${arch}.tar.gz"
    url="https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/${tarball}"
    tmp=$(mktemp -d)
    curl -fsSL "${url}" -o "${tmp}/${tarball}"
    tar -xzf "${tmp}/${tarball}" -C "${tmp}" hugo
    install -m 0755 "${tmp}/hugo" "${HUGO_BIN}"
    rm -rf "${tmp}"
    log "Installed $("${HUGO_BIN}" version)"
}

install_hugo
command -v "${HUGO_BIN}" &>/dev/null || die "Hugo not available"

cd "${SITE}"
rm -rf public resources
"${HUGO_BIN}" --minify
[[ -f public/index.html ]] || die "Build failed — no public/index.html"

log "Built $(find public -type f | wc -l) files → ${SITE}/public/"
log "Preview: cd ${SITE} && ${HUGO_BIN} server --baseURL http://localhost:1313/vts/"