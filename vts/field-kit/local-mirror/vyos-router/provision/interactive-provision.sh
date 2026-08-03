#!/usr/bin/env bash
# Interactive VyOS dual-LAN provisioner — run ON the router (VyOS shell or after install).
# Generates a .boot file of `set` commands from templates/dual-lan-dhcp.boot.tmpl
#
# Usage (from USB or repo):
#   bash interactive-provision.sh
#   bash interactive-provision.sh --apply   # also prints apply instructions
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMPL="${ROOT}/templates/dual-lan-dhcp.boot.tmpl"
OUT_DIR="${ROOT}/generated"
APPLY=0
[[ "${1:-}" == "--apply" ]] && APPLY=1

die() { echo "ERROR: $*" >&2; exit 1; }
[[ -f "${TMPL}" ]] || die "Missing template ${TMPL}"

echo "============================================"
echo " Valley Tech — VyOS dual-LAN provisioner"
echo " Segmentation is ON THIS ROUTER, not a PC."
echo "============================================"
echo ""

read -r -p "Site hostname [vt-router]: " HOSTNAME
HOSTNAME="${HOSTNAME:-vt-router}"

# Defaults match this appliance: built-in eth0 WAN; USB NICs eth2/eth3 (no eth1)
read -r -p "WAN interface  [eth0]: " WAN_IF
WAN_IF="${WAN_IF:-eth0}"
read -r -p "LAN1 Trusted   [eth2]: " LAN1_IF
LAN1_IF="${LAN1_IF:-eth2}"
read -r -p "LAN2 Guest/IoT [eth3]: " LAN2_IF
LAN2_IF="${LAN2_IF:-eth3}"

echo ""
echo "Subnet defaults (Enter to accept):"
read -r -p "  LAN1 subnet [192.168.10.0/24]: " LAN1_SUBNET
LAN1_SUBNET="${LAN1_SUBNET:-192.168.10.0/24}"
LAN1_GW="${LAN1_SUBNET%.*}.1"
# if subnet is a.b.c.0/24, gw is a.b.c.1
LAN1_PREFIX="${LAN1_SUBNET%.0/24}"
LAN1_GW="${LAN1_PREFIX}.1"
LAN1_DHCP_START="${LAN1_PREFIX}.100"
LAN1_DHCP_STOP="${LAN1_PREFIX}.200"

read -r -p "  LAN2 subnet [192.168.50.0/24]: " LAN2_SUBNET
LAN2_SUBNET="${LAN2_SUBNET:-192.168.50.0/24}"
LAN2_PREFIX="${LAN2_SUBNET%.0/24}"
LAN2_GW="${LAN2_PREFIX}.1"
LAN2_DHCP_START="${LAN2_PREFIX}.100"
LAN2_DHCP_STOP="${LAN2_PREFIX}.200"

mkdir -p "${OUT_DIR}"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="${OUT_DIR}/${HOSTNAME}-${STAMP}.boot"

sed \
  -e "s|__HOSTNAME__|${HOSTNAME}|g" \
  -e "s|__WAN_IF__|${WAN_IF}|g" \
  -e "s|__LAN1_IF__|${LAN1_IF}|g" \
  -e "s|__LAN2_IF__|${LAN2_IF}|g" \
  -e "s|__LAN1_SUBNET__|${LAN1_SUBNET}|g" \
  -e "s|__LAN1_GW__|${LAN1_GW}|g" \
  -e "s|__LAN1_DHCP_START__|${LAN1_DHCP_START}|g" \
  -e "s|__LAN1_DHCP_STOP__|${LAN1_DHCP_STOP}|g" \
  -e "s|__LAN2_SUBNET__|${LAN2_SUBNET}|g" \
  -e "s|__LAN2_GW__|${LAN2_GW}|g" \
  -e "s|__LAN2_DHCP_START__|${LAN2_DHCP_START}|g" \
  -e "s|__LAN2_DHCP_STOP__|${LAN2_DHCP_STOP}|g" \
  "${TMPL}" > "${OUT}"

# Drop comment-only lines that are not set commands for a clean paste file
grep -E '^set |^# ---' "${OUT}" > "${OUT}.sets" || true

cat > "${OUT_DIR}/${HOSTNAME}-${STAMP}.cabling.txt" <<EOF
Valley Tech — cable map for ${HOSTNAME}
Generated: ${STAMP}

  ISP/Starlink/modem  --->  ${WAN_IF}   (WAN, DHCP)
  Trusted switch/AP   --->  ${LAN1_IF}  (${LAN1_SUBNET}, gw ${LAN1_GW}, DHCP ${LAN1_DHCP_START}-${LAN1_DHCP_STOP})
  Guest/IoT switch/AP --->  ${LAN2_IF}  (${LAN2_SUBNET}, gw ${LAN2_GW}, DHCP ${LAN2_DHCP_START}-${LAN2_DHCP_STOP})

Policy: Guest/IoT (LAN2) cannot reach Trusted (LAN1).
Static IPs: not configured — add later per client if needed.
Monitoring: NOT included — optional add-on only.
EOF

echo ""
echo "Wrote:"
echo "  ${OUT}"
echo "  ${OUT}.sets"
echo "  ${OUT_DIR}/${HOSTNAME}-${STAMP}.cabling.txt"
echo ""
echo ">>> YOU on VyOS console (after OS install):"
echo "  configure"
echo "  # paste lines from ${OUT}.sets   OR:"
echo "  source ${OUT}    # if supported / load as needed"
echo "  commit"
echo "  save"
echo ""
echo "Then verify firewall isolation — see provision/firewall-dual-lan.md"
echo ""
cat "${OUT_DIR}/${HOSTNAME}-${STAMP}.cabling.txt"

if [[ "${APPLY}" -eq 1 ]]; then
  if command -v vyos-config-parser >/dev/null 2>&1 || [[ -f /config/config.boot ]]; then
    echo ""
    echo "This host looks like it may be VyOS. Auto-apply is NOT enabled by default"
    echo "(safety). Paste ${OUT}.sets manually after review."
  fi
fi
