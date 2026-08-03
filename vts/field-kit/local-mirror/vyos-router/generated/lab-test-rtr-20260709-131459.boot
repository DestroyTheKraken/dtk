# Valley Tech client router — dual LAN + DHCP defaults
# Placeholders replaced by interactive-provision.sh:
#   lab-test-rtr  eth0  eth1  eth2
#   192.168.10.0/24 192.168.10.1 192.168.10.100 192.168.10.200
#   192.168.50.0/24 192.168.50.1 192.168.50.100 192.168.50.200
#
# Defaults when not overridden:
#   LAN1 Trusted  192.168.10.0/24  gw 192.168.10.1  pool .100-.200
#   LAN2 GuestIoT 192.168.50.0/24  gw 192.168.50.1  pool .100-.200
#   WAN DHCP client
#
# Apply on VyOS:
#   configure
#   load /config/valley-tech/dual-lan-dhcp.boot   # or paste set commands
#   commit ; save

# --- System ---
set system host-name 'lab-test-rtr'
set system name-server '1.1.1.1'
set system name-server '1.0.0.1'
set system time-zone 'America/Los_Angeles'

# --- Interfaces ---
set interfaces ethernet eth0 address dhcp
set interfaces ethernet eth0 description 'WAN-ISP'
set interfaces ethernet eth1 address '192.168.10.1/24'
set interfaces ethernet eth1 description 'LAN1-Trusted'
set interfaces ethernet eth2 address '192.168.50.1/24'
set interfaces ethernet eth2 description 'LAN2-Guest-IoT'

# --- NAT (both LANs out WAN) ---
set nat source rule 100 description 'LAN1-to-WAN'
set nat source rule 100 outbound-interface name 'eth0'
set nat source rule 100 source address '192.168.10.0/24'
set nat source rule 100 translation address masquerade
set nat source rule 110 description 'LAN2-to-WAN'
set nat source rule 110 outbound-interface name 'eth0'
set nat source rule 110 source address '192.168.50.0/24'
set nat source rule 110 translation address masquerade

# --- DHCP LAN1 Trusted ---
set service dhcp-server shared-network-name TRUSTED authoritative
set service dhcp-server shared-network-name TRUSTED subnet 192.168.10.0/24 subnet-id 1
set service dhcp-server shared-network-name TRUSTED subnet 192.168.10.0/24 default-router '192.168.10.1'
set service dhcp-server shared-network-name TRUSTED subnet 192.168.10.0/24 name-server '1.1.1.1'
set service dhcp-server shared-network-name TRUSTED subnet 192.168.10.0/24 name-server '1.0.0.1'
set service dhcp-server shared-network-name TRUSTED subnet 192.168.10.0/24 lease '86400'
set service dhcp-server shared-network-name TRUSTED subnet 192.168.10.0/24 range 0 start '192.168.10.100'
set service dhcp-server shared-network-name TRUSTED subnet 192.168.10.0/24 range 0 stop '192.168.10.200'

# --- DHCP LAN2 Guest / IoT ---
set service dhcp-server shared-network-name GUESTIOT authoritative
set service dhcp-server shared-network-name GUESTIOT subnet 192.168.50.0/24 subnet-id 2
set service dhcp-server shared-network-name GUESTIOT subnet 192.168.50.0/24 default-router '192.168.50.1'
set service dhcp-server shared-network-name GUESTIOT subnet 192.168.50.0/24 name-server '1.1.1.1'
set service dhcp-server shared-network-name GUESTIOT subnet 192.168.50.0/24 name-server '1.0.0.1'
set service dhcp-server shared-network-name GUESTIOT subnet 192.168.50.0/24 lease '86400'
set service dhcp-server shared-network-name GUESTIOT subnet 192.168.50.0/24 range 0 start '192.168.50.100'
set service dhcp-server shared-network-name GUESTIOT subnet 192.168.50.0/24 range 0 stop '192.168.50.200'

# --- Firewall: zone-style isolation (nftables path varies by VyOS version;
#     use these as intent; interactive provisioner may adapt syntax after dry-run) ---
# Policy summary (implement with firewall ipv4 in apply script if set lines differ):
#   WAN local: allow established, DHCP, limited SSH if desired
#   LAN2 → LAN1: drop
#   LAN1 → LAN2: drop
#   LAN1/LAN2 → WAN: accept
# See provision/firewall-dual-lan.md for version-specific commands.

set service ssh port '22'
set service ssh listen-address '192.168.10.1'
