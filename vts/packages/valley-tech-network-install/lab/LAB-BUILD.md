# Lab build — pre-programmed client router

**Goal:** Leave the lab with a labeled appliance that is **plug-and-play onsite**.

## Hardware

- Mini-PC / M93p Tiny / other x86 with **≥2–3 NICs** (USB NIC OK for third port)
- USB stick: Ventoy + official **VyOS amd64 ISO** + this `valley-tech-router` folder
- Keyboard + display (or serial) for first install

## Steps

1. **>>> YOU:** Download VyOS ISO from your VyOS account; copy to USB (`isos/` or Ventoy root).  
2. Boot appliance from USB → install VyOS to internal disk (interactive ISO installer).  
3. Reboot from disk; log in as `vyos`.  
4. Mount USB (or copy package via scp from um690).  
5. Run:

```bash
bash /path/to/valley-tech-network-install/provision/interactive-provision.sh
```

6. **>>> YOU:** In VyOS `configure`, paste generated `set` lines → `commit` → `save`.  
7. Verify DHCP + isolation (`provision/firewall-dual-lan.md`).  
8. Label chassis ports: **WAN | LAN1 Trusted | LAN2 Guest/IoT**.  
9. Optional add-on only: Tailscale + Netdata container.  
10. Pack unit + cabling printout from `generated/*.cabling.txt`.

## Onsite after lab build

See `onsite/PLUG-AND-PLAY.md` — no re-install unless disaster recovery.
