#!/usr/bin/env sh
# =============================================================================
# Sovereign Media Hub — one-line bootstrap (DTK installer host)
# =============================================================================
#
#   curl -fsSL https://www.destroythekraken.com/hickmedia.sh | sudo sh
#   curl -fsSL https://www.destroythekraken.com/hickmedia.sh | sudo sh -s -- --profile full-hub
#
# USB:
#   sudo sh /media/$USER/VENTOY/hickmedia/hickmedia.sh --profile full-hub --yes
#
# Payload resolution order:
#   1) --local TREE
#   2) USB / directory next to this script (payload/ or installer/)
#   3) https://www.destroythekraken.com/hickmedia/latest.tar.gz
#   4) GitHub Release (HM_GITHUB_REPO, default DestroyTheKraken/hickmedia)
#
# Env: HM_PROFILE HM_RELEASE_URL HM_GITHUB_REPO HM_INSTALL_ROOT HM_YES HM_RELEASE_SHA256
# =============================================================================

set -eu

# --- DTK public endpoints ----------------------------------------------------
DTK_SITE="${HM_DTK_SITE:-https://www.destroythekraken.com}"
DEFAULT_RELEASE_URL="${HM_RELEASE_URL:-${DTK_SITE}/hickmedia/latest.tar.gz}"
GITHUB_REPO="${HM_GITHUB_REPO:-DestroyTheKraken/hickmedia}"
# GitHub Releases asset name from pack-release.sh
GITHUB_ASSET="${HM_GITHUB_ASSET:-hickmedia-latest.tar.gz}"
DEFAULT_INSTALL_ROOT="${HM_INSTALL_ROOT:-/opt/mediahub}"
DEFAULT_PROFILE="${HM_PROFILE:-full-hub}"

log()  { printf '%s\n' "hickmedia: $*"; }
die()  { printf '%s\n' "hickmedia: ERROR: $*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "need command: $1"; }

PROFILE="$DEFAULT_PROFILE"
YES="${HM_YES:-0}"
OFFLINE=0
LOCAL_TREE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --profile) PROFILE="${2:-}"; shift 2 ;;
    --yes|-y) YES=1; shift ;;
    --offline) OFFLINE=1; shift ;;
    --local) LOCAL_TREE="${2:-}"; shift 2 ;;
    --os-help)
      cat <<'EOF'
Sovereign Media Hub (HickMedia) — base OS
  Ubuntu Desktop / Kubuntu / Ubuntu Studio 24.04 or 26.04 LTS
  Profiles: full-hub | media-client | media-server
  Pro audio (interface → speakers) is always installed.
EOF
      exit 0
      ;;
    -h|--help)
      cat <<EOF
hickmedia.sh — DestroyTheKraken bootstrap

  curl -fsSL ${DTK_SITE}/hickmedia.sh | sudo sh
  curl -fsSL ${DTK_SITE}/hickmedia.sh | sudo sh -s -- --profile media-server --yes

  sudo sh ./hickmedia.sh --local /path/to/HickMedia --profile full-hub --yes

Host: ${DTK_SITE}
GitHub fallback repo: ${GITHUB_REPO}
EOF
      exit 0
      ;;
    *) die "unknown arg: $1 (try --help)" ;;
  esac
done

case "$PROFILE" in
  full-hub|media-client|media-server) ;;
  *) die "invalid profile: $PROFILE" ;;
esac

if [ "$(id -u)" -ne 0 ]; then
  die "re-run with sudo (example: curl -fsSL ${DTK_SITE}/hickmedia.sh | sudo sh)"
fi

need curl
need tar
need gzip

INSTALL_ROOT="$DEFAULT_INSTALL_ROOT"
SRC_DIR="${INSTALL_ROOT}/src"
CACHE_DIR="${INSTALL_ROOT}/cache"
mkdir -p "$SRC_DIR" "$CACHE_DIR" /var/log/mediahub

download_ok() {
  # $1=url $2=dest
  curl -fsSL --connect-timeout 20 --retry 2 -o "$2.part" "$1" && mv "$2.part" "$2"
}

extract_tarball() {
  tarball="$1"
  if [ -n "${HM_RELEASE_SHA256:-}" ]; then
    need sha256sum
    echo "${HM_RELEASE_SHA256}  $tarball" | sha256sum -c - || die "SHA256 mismatch"
  fi
  rm -rf "${SRC_DIR}.new"
  mkdir -p "${SRC_DIR}.new"
  tar -xzf "$tarball" -C "${SRC_DIR}.new"
  if [ -f "${SRC_DIR}.new/installer/install.sh" ]; then
    rm -rf "$SRC_DIR"
    mv "${SRC_DIR}.new" "$SRC_DIR"
    echo "$SRC_DIR"
    return
  fi
  if [ -f "${SRC_DIR}.new/HickMedia/installer/install.sh" ]; then
    rm -rf "$SRC_DIR"
    mv "${SRC_DIR}.new/HickMedia" "$SRC_DIR"
    rm -rf "${SRC_DIR}.new"
    echo "$SRC_DIR"
    return
  fi
  top=$(find "${SRC_DIR}.new" -mindepth 1 -maxdepth 1 -type d | head -1)
  if [ -n "$top" ] && [ -f "$top/installer/install.sh" ]; then
    rm -rf "$SRC_DIR"
    mv "$top" "$SRC_DIR"
    rm -rf "${SRC_DIR}.new"
    echo "$SRC_DIR"
    return
  fi
  die "tarball layout unknown (need installer/install.sh inside)"
}

resolve_tree() {
  if [ -n "$LOCAL_TREE" ]; then
    [ -f "$LOCAL_TREE/installer/install.sh" ] || die "--local missing installer/install.sh: $LOCAL_TREE"
    echo "$LOCAL_TREE"
    return
  fi

  script_path="$0"
  case "$script_path" in
    /*|./*|../*)
      if [ -f "$script_path" ]; then
        script_dir=$(CDPATH= cd -- "$(dirname "$script_path")" && pwd)
        if [ -f "$script_dir/installer/install.sh" ]; then
          echo "$script_dir"
          return
        fi
        if [ -f "$script_dir/HickMedia/installer/install.sh" ]; then
          echo "$script_dir/HickMedia"
          return
        fi
        if [ -f "$script_dir/payload/installer/install.sh" ]; then
          echo "$script_dir/payload"
          return
        fi
      fi
      ;;
  esac

  if [ "$OFFLINE" -eq 1 ]; then
    die "offline mode but no local tree (use USB pack or --local)"
  fi

  tarball="$CACHE_DIR/hickmedia-latest.tar.gz"
  # 1) Official DTK site
  log "trying DTK site: $DEFAULT_RELEASE_URL"
  if download_ok "$DEFAULT_RELEASE_URL" "$tarball"; then
    extract_tarball "$tarball"
    return
  fi
  log "DTK site payload failed — trying GitHub Releases (${GITHUB_REPO})"

  # 2) GitHub latest release asset
  gh_url="https://github.com/${GITHUB_REPO}/releases/latest/download/${GITHUB_ASSET}"
  if download_ok "$gh_url" "$tarball"; then
    extract_tarball "$tarball"
    return
  fi

  die "could not download release from:
  - ${DEFAULT_RELEASE_URL}
  - ${gh_url}
Publish with: bash site/publish.sh
Or use USB: bash installer/pack-release.sh --out /media/.../hickmedia"
}

TREE=$(resolve_tree)
log "using tree: $TREE"
log "profile: $PROFILE"

mkdir -p "$INSTALL_ROOT"
printf '%s\n' "$TREE" >"$INSTALL_ROOT/CURRENT_TREE"
printf '%s\n' "$PROFILE" >"$INSTALL_ROOT/LAST_PROFILE"
date -Is >"$INSTALL_ROOT/LAST_BOOTSTRAP" 2>/dev/null || date >"$INSTALL_ROOT/LAST_BOOTSTRAP"

export HM_YES="$YES"
[ -f "$TREE/installer/install.sh" ] || die "missing $TREE/installer/install.sh"
chmod +x "$TREE/installer/install.sh" 2>/dev/null || true

log "running installer (pro audio essential)..."
need bash
bash "$TREE/installer/install.sh" --profile "$PROFILE" --yes

mkdir -p "$INSTALL_ROOT/bin"
cat >"$INSTALL_ROOT/bin/mediahub-update" <<UPD
#!/usr/bin/env sh
set -eu
URL="\${HM_BOOTSTRAP_URL:-${DTK_SITE}/hickmedia.sh}"
PROF="\${HM_PROFILE:-\$(cat ${INSTALL_ROOT}/LAST_PROFILE 2>/dev/null || echo full-hub)}"
printf '%s\\n' "mediahub-update: bootstrap \$URL profile=\$PROF"
curl -fsSL "\$URL" | sudo sh -s -- --profile "\$PROF" --yes
UPD
chmod +x "$INSTALL_ROOT/bin/mediahub-update"
ln -sfn "$INSTALL_ROOT/bin/mediahub-update" /usr/local/bin/mediahub-update 2>/dev/null || true

log "done. tree=$TREE profile=$PROFILE"
log "update: mediahub-update   OR   curl -fsSL ${DTK_SITE}/hickmedia.sh | sudo sh"
