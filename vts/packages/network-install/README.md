# Valley Tech — VyOS Router Install Package (v2)

**One sentence:** This kit provisions a **3-port VyOS router** (WAN + LAN1 trusted + LAN2 guest/IoT, DHCP), usually **built in your lab** for onsite plug-and-play—using `config.boot` files, not client PCs.

| Piece | Purpose |
|-------|---------|
| `provision/interactive-provision.sh` | Interactive dual-LAN config generator |
| `configs/config.boot.home` / `.office` | Real config files (eth0/eth2/eth3) |
| `lab/LAB-BUILD.md` | Pre-program appliance |
| `onsite/PLUG-AND-PLAY.md` | Cable-only delivery |
| `quote/` | Discovery → itemized quote (automation TBD) |
| `parent/` `child/` | Optional **monitoring add-on** only |

**Docs:** [[Documents/valley-tech-support/packages/network-install/DESIGN]] · [[INSTALL]]

**Defaults:** DHCP everywhere; static IPs manual later; monitoring not included in base.
