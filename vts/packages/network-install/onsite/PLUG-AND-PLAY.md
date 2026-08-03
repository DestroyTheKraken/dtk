# Onsite — plug-and-play (lab-built router)

You already provisioned dual-LAN DHCP in the lab. Onsite work is physical.

## Cable (3 ports only)

1. Modem/Starlink **LAN** → router **WAN** (`eth0` built-in)  
2. Trusted switch / main AP → **LAN1** (`eth2` USB) — Family or Staff  
3. Guest **and** IoT AP/switch → **LAN2** (`eth3` USB) — shared segment  
4. Power on router  

## Smoke test (10 minutes)

- [ ] Phone on trusted Wi‑Fi: gets `192.168.10.x`, internet works  
- [ ] Phone on guest Wi‑Fi: gets `192.168.50.x`, internet works  
- [ ] Guest/IoT cannot open a trusted PC’s share or ping `192.168.10.x`  
- [ ] Leave cabling sheet with client  

## Not onsite (unless sold)

- Netdata / Telegram monitoring  
- Custom static IPs (do later if requested)  
- Re-running full ISO install  

## If something fails

- Wrong port mapping → swap cables or re-map interfaces in lab config  
- Only two NICs → confirm lab design (VLAN-aware switch or extra USB NIC)  
