# Onsite — plug-and-play (lab-built router)

You already provisioned dual-LAN DHCP in the lab. Onsite work is physical.

## Cable

1. Modem/Starlink **LAN** → router **WAN**  
2. Trusted switch / main AP uplink → **LAN1**  
3. Guest or IoT AP/switch → **LAN2**  
4. Power on router  

## Smoke test (10 minutes)

- [ ] Phone on trusted Wi‑Fi: gets `192.168.10.x`, internet works  
- [ ] Phone on guest Wi‑Fi: gets `192.168.50.x`, internet works  
- [ ] Guest cannot open a trusted PC’s share or ping trusted LAN host  
- [ ] Leave cabling sheet with client  

## Not onsite (unless sold)

- Netdata / Telegram monitoring  
- Custom static IPs (do later if requested)  
- Re-running full ISO install  

## If something fails

- Wrong port mapping → swap cables or re-map interfaces in lab config  
- Only two NICs → confirm lab design (VLAN-aware switch or extra USB NIC)  
