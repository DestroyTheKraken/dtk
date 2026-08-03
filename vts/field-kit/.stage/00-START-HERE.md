# Valley Tech Field Kit — START HERE

This folder is your **onsite toolkit**: installers and configs you take on the Ventoy USB (or copy from um690).

## What’s inside

| Folder | Product | When you use it |
|--------|---------|-----------------|
| `nextcloud/` | Nextcloud hub (outward symlinks to real `/home` folders) | Client wants private cloud / phone sync |
| `vyos-router/` | VyOS configs + docs + provision helpers | Build/rebuild 3-port router (WAN + LAN1 + LAN2) |
| `smadp-mesh/` | Sovereign mesh scripts (k3s stack) | Your lab / advanced mesh only |
| `docs/` | Business + how-to | Quotes, agreement language, beginner guides |

## Boot media (same USB)

This stick is **Ventoy**. ISO files live at the **root** of the USB (or `isos/` if you move them):

- `vyos-*-generic-amd64.iso` — install VyOS on appliance  
- Ubuntu / Kubuntu / etc. — install client or lab OS  

**Boot:** plug USB → BIOS/boot menu → pick the ISO you need.

## Typical jobs

### A) New client router (lab first, then plug-and-play)

1. Boot appliance from **VyOS ISO** → install to disk  
2. Follow `vyos-router/APPLY-CONFIG.md` (load config file → commit → save)  
3. Cable: WAN / LAN1 trusted / LAN2 guest+IoT — see `vyos-router/configs/PORTS.md`  

### B) Nextcloud on a Linux laptop/desktop

1. Copy or open `nextcloud/` on the machine  
2. Follow `nextcloud/README.md` → `bash install.sh` (or phase scripts)  
3. Tailscale for phone access  

### C) Your lab mesh (advanced)

See `smadp-mesh/` and `~/SovereignAid` — not a default client SKU.

## Secrets

- Do **not** leave live passwords or stream API keys on the USB long-term.  
- Router golden export may contain lab SSH rules — sanitize before customer clones.

## Rebuild this kit onto USB

On um690, with Ventoy mounted:

```bash
bash ~/Documents/valley-tech-support/field-kit/assemble-to-usb.sh
```

Default mount: `/run/media/kraken/Ventoy`
