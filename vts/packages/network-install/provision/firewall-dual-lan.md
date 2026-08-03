# Dual-LAN firewall intent (VyOS)

Exact `set firewall ...` syntax differs between VyOS 1.3 / 1.4 / 1.5.  
**Policy is fixed; syntax is verified on your target image in lab.**

## Policy (always)

| Traffic | Action |
|---------|--------|
| LAN1 (trusted) → WAN | allow + NAT |
| LAN2 (guest/IoT) → WAN | allow + NAT |
| LAN2 → LAN1 | **drop** |
| LAN1 → LAN2 | **drop** (default; change only if a job needs printer sharing) |
| WAN → LAN1 or LAN2 | drop unsolicited; allow established/related |
| SSH management | listen on LAN1 gateway only (default) |

## Lab verification

After provision on M93p:

1. PC on LAN1: DHCP, internet works.  
2. PC on LAN2: DHCP, internet works.  
3. From LAN2: cannot ping LAN1 host (e.g. `192.168.10.100`).  
4. From LAN1: cannot ping LAN2 host (default).  

Document working `set` lines in `templates/firewall-verified-<vyos-version>.conf` after first successful dry-run.
