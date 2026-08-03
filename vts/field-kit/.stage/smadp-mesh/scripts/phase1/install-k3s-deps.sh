#!/usr/bin/env bash
# install-k3s-deps.sh — Prerequisites for k3s + Longhorn on SMADP nodes
# Run on EACH node: sudo bash install-k3s-deps.sh

set -euo pipefail

log() { echo "[k3s-deps] $*"; }
die() { echo "[k3s-deps] ERROR: $*" >&2; exit 1; }

[[ "$(id -u)" -eq 0 ]] || die "Run with sudo"

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq curl open-iscsi nfs-common

systemctl enable iscsid
systemctl start iscsid

log "Dependencies installed on $(hostname -s)"
systemctl is-active iscsid