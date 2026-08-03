# DESIGN — Valley Tech VyOS Router Installer

**Date:** 2026-07-09  
**Status:** corrected product model (v2)  
**Owner:** Joshua / Valley Tech Support  

---

## 1. What this product is

A **USB + lab kit to install and provision a customer router appliance** running **VyOS**, with:

| Interface role | This build | Purpose | Default addressing |
|----------------|------------|---------|-------------------|
| **WAN** | `eth0` built-in | Modem / Starlink / ISP | DHCP client |
| **LAN1 — Trusted** | `eth2` USB-NIC | Family (home) or Staff (office) | `192.168.10.0/24`, gw `.1`, **DHCP** |
| **LAN2 — Guest+IoT** | `eth3` USB-NIC | Guests and smart home **together** | `192.168.50.0/24`, gw `.1`, **DHCP** |

**Three ports only.** Kernel may skip `eth1` (USB adapters often appear as eth2/eth3); templates follow that naming.

**Segmentation lives on the router**, not on a person’s Windows/Mac/PC.  
Client devices only get an IP via DHCP (or a rare static you set later by hand).

**Onsite goal:** plug-and-play — cable WAN + two LAN switches/APs, power on, done.  
**Where the real work happens:** **your lab** (install OS + apply config on the M93p/mini-PC *before* the truck roll), or a full USB interactive install if you build the appliance onsite.

---

## 2. What this product is not

| Wrong model (v1 kit) | Correct model (v2) |
|----------------------|--------------------|
| Run install scripts on the customer’s PC | Run install on **router hardware only** |
| “Assess / segment / handoff” as vague PC phases | **Provision VyOS**: WAN + 2 isolated LANs + DHCP |
| Segmentation checklist on mesh UI as primary | **Firewall zones on VyOS** (LAN2 ↛ LAN1) |
| Netdata child on random PC as core install | Netdata = **optional add-on** (container on router later) |

---

## 3. Two delivery modes

### Mode A — Lab build → onsite plug-and-play (**default / preferred**)

1. In lab: boot USB → install VyOS on appliance (M93p Tiny, etc.).  
2. In lab: run **interactive provisioner** → dual-LAN DHCP config committed.  
3. Optional: monitoring add-on (Netdata container + Tailscale).  
4. Label ports: WAN / LAN1 / LAN2.  
5. Onsite: connect cables only; smoke-test phones get DHCP on correct SSID/VLAN/AP uplink.

### Mode B — Onsite full install (same USB)

1. Boot appliance from USB (VyOS ISO via Ventoy or hybrid stick).  
2. Interactive VyOS OS install to disk.  
3. Reboot from disk, mount USB again, run provisioner.  
4. Same dual-LAN outcome as Mode A.

> Full “one ISO that is only our product” (custom branded automator) is a later packaging step.  
> **v2 delivers:** official VyOS ISO + our **provision templates + interactive script** on the same USB (e.g. Ventoy).

---

## 4. Default network design (client sites)

```
                    [ ISP / Starlink ]
                           |
                   eth0 WAN (built-in, DHCP)
                           |
                    +------+------+
                    |    VyOS     |
                    +------+------+
                     |          |
           eth2 LAN1          eth3 LAN2
        192.168.10.0/24    192.168.50.0/24
        Trusted+DHCP       Guest+IoT+DHCP
                     |          |
              [switch/AP]  [guest/IoT AP]
```

**Firewall policy (default):**

- LAN1 → WAN: allow (NAT)  
- LAN2 → WAN: allow (NAT)  
- LAN2 → LAN1: **drop**  
- LAN1 → LAN2: **drop** (unless a job needs otherwise)  
- WAN → LANs: drop unsolicited  

**Static IPs:** not in default install — add later per client.

**Interface names on this appliance:** eth0 / eth2 / eth3 (no eth1). Remap only if `show interfaces` differs on another box.

---

## 5. Interactive provision questions (minimal)

1. Site / hostname  
2. Admin password (vyos user)  
3. Map interfaces: WAN, LAN1, LAN2  
4. Accept defaults for subnets/DHCP pools? (Y/n)  
5. Enable optional Tailscale/monitoring? (N by default — add-on)

Then: generate `set` commands → `commit` → `save` → print cable diagram.

---

## 6. Automated quote (assessment data → itemized quote)

**Your correction:** discovery can drive a **detailed itemized quote**, not only notes.

| Input (from site or remote) | Output |
|----------------------------|--------|
| Inventory / scan (devices, SSIDs, modem type, cable count) | Line items: base router appliance, onsite install hours, AP count, monitoring add-on, cabling, etc. |
| SKU flags | Base network **without** monitoring; optional Netdata retainer |

v2: schema + quote template (`quote/`).  
v2.1: script that fills quote from `discovery.json`.

Assessment is **sales/discovery**, not “run segmentation on the PC.”

---

## 7. Monitoring (unchanged policy)

- **Not** in base router install.  
- Add-on: Netdata parent (your mesh) + child/container on **this router** if sold.  
- Alerts: Telegram.  
- If client declines monitoring and declines custom router → **no Netdata**, no always-on debate.

---

## 8. USB layout (target)

```
INSTALLERS/   (or Ventoy stick)
├── isos/
│   └── vyos-*-generic-amd64.iso     # YOU download official ISO (license/account)
├── valley-tech-router/              # this package (renamed content)
│   ├── DESIGN.md
│   ├── INSTALL.md
│   ├── README.md
│   ├── provision/
│   │   ├── interactive-provision.sh # asks questions → applies config
│   │   └── apply-config.sh          # load a generated .boot file
│   ├── templates/
│   │   └── dual-lan-dhcp.boot.tmpl  # WAN + 2 LANs + DHCP + firewall
│   ├── quote/
│   │   ├── discovery.example.json
│   │   └── quote-template.md
│   ├── lab/
│   │   └── LAB-BUILD.md             # pre-program in lab checklist
│   ├── onsite/
│   │   └── PLUG-AND-PLAY.md         # cable-only visit
│   └── monitoring/                  # optional add-on only
│       └── (parent/child refs)
```

---

## 9. Implementation order

1. Dual-LAN DHCP + firewall **template** (this commit)  
2. Interactive provisioner (bash) generating VyOS `set` commands  
3. Lab + onsite checklists  
4. Quote schema + template  
5. USB rebuild (Ventoy instructions; ISO obtained by you)  
6. Dry-run on spare M93p in lab  
7. Optional: Netdata container recipe on VyOS  

---

## 10. Success criteria

- [ ] From USB + hardware, produce a router with WAN + two DHCP LANs  
- [ ] Guest/IoT network cannot reach trusted LAN hosts  
- [ ] Lab-built unit deploys onsite with cable-only steps  
- [ ] Base job quote does not include monitoring unless add-on selected  
- [ ] Static IPs remain manual, post-install, per client  

---

#valley-tech-support #vyos #design
