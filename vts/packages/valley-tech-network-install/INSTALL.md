# INSTALL — Valley Tech VyOS Router (v2)

**This installer provisions a router appliance — not the customer’s PC.**

---

## End state

| Port | Network | DHCP |
|------|---------|------|
| WAN | ISP (Starlink/modem) | Client (gets address from ISP) |
| LAN1 | Trusted `192.168.10.0/24` | Server on router (default) |
| LAN2 | Guest/IoT `192.168.50.0/24` | Server on router (default) |

Isolation: LAN2 cannot reach LAN1.  
Statics: add later per client if needed.  
Monitoring: optional add-on only.

---

## Preferred path — lab then onsite

### Lab (you)

1. **>>> YOU:** Put official **VyOS ISO** on USB (Ventoy recommended).  
2. **>>> YOU:** Copy this package folder onto the same USB.  
3. Boot **router hardware** from USB → install VyOS to disk (ISO wizard).  
4. Run `bash provision/interactive-provision.sh`  
5. **>>> YOU:** On VyOS: `configure` → paste generated `set` lines → `commit` → `save`  
6. Verify dual DHCP + isolation (`provision/firewall-dual-lan.md`)  
7. Label ports; print `generated/*.cabling.txt`  

Full checklist: `lab/LAB-BUILD.md`

### Onsite (you)

1. Cable WAN / LAN1 / LAN2 only.  
2. Smoke test.  
3. No ISO reinstall.  

Checklist: `onsite/PLUG-AND-PLAY.md`

---

## Alternate — full install onsite

Same as lab steps 3–6 performed at the customer site. Longer visit; same USB.

---

## Quote automation

- Capture site facts in `quote/discovery.example.json` shape.  
- Fill `quote/quote-template.md` (scripted fill later).  
- Monitoring lines only if sold as add-on.

---

## What about the old “phases on a PC” scripts?

| Path | Role now |
|------|----------|
| `provision/`, `templates/`, `lab/`, `onsite/`, `quote/` | **Primary product** |
| `parent/`, `child/`, Netdata phases | **Optional monitoring add-on only** |
| Old assess/segment-on-PC wording | **Superseded** by this document |

---

## USB rebuild

After package updates:

```bash
bash package-release.sh
bash copy-to-usb.sh /run/media/kraken/INSTALLERS
```

**>>> YOU:** Also place the VyOS `.iso` on the stick (not redistributed by us without your license).
