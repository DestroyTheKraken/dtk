# Valley Tech — VyOS Router Install Package (v2)

**One sentence:** This kit installs and provisions a **VyOS customer router** with a WAN and **two segmented DHCP LANs** (trusted + guest/IoT), usually **built in your lab** for onsite plug-and-play—not software you run on the client’s PC.

| Piece | Purpose |
|-------|---------|
| `provision/interactive-provision.sh` | Interactive dual-LAN config generator |
| `templates/dual-lan-dhcp.boot.tmpl` | WAN + LAN1 + LAN2 + DHCP |
| `lab/LAB-BUILD.md` | Pre-program appliance |
| `onsite/PLUG-AND-PLAY.md` | Cable-only delivery |
| `quote/` | Discovery → itemized quote (automation TBD) |
| `parent/` `child/` | Optional **monitoring add-on** only |

**Docs:** [[Documents/valley-tech-support/packages/valley-tech-network-install/DESIGN]] · [[INSTALL]]

**Defaults:** DHCP everywhere; static IPs manual later; monitoring not included in base.
