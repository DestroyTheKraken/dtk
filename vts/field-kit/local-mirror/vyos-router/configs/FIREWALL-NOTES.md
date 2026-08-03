# Firewall isolation notes

Templates currently set **interfaces, DHCP, NAT, SSH** for **3 ports** (eth0 WAN, eth2 LAN1, eth3 LAN2).

**Intentional isolation** (LAN2 guest/IoT must not reach LAN1 trusted):

| From → To | Action |
|-----------|--------|
| LAN1 (Family/Staff) → WAN | allow |
| LAN2 (Guest+IoT) → WAN | allow |
| LAN2 → LAN1 | **drop** |
| LAN1 → LAN2 | **drop** (default; open only if a job needs it) |
| WAN → LAN1 or LAN2 | drop unsolicited |

Guest and IoT are **one LAN** on this product — no third LAN port for IoT-only.

Exact `firewall { ... }` syntax differs between **VyOS 1.4** and **1.5**.  
After first successful `load` on your image:

1. Add zone/forward rules in the lab  
2. `show configuration` → fold working isolation into the template  
3. From a LAN2 client: cannot ping `192.168.10.x`
