# How VyOS configuration actually works

(Aligned with official docs: one unified config file, commit/save model.)

---

## Plain English (your mental model is right)

Enterprise gear often has **one main config file** you can backup, edit, restore.  
**VyOS is the same idea.**

| Concept | VyOS name | Where |
|---------|-----------|--------|
| The saved config file | **Saved / boot configuration** | `/config/config.boot` |
| What is live right now | **Active / running** | In memory after `commit` |
| Edits not yet live | **Working** | Config mode until `commit` |

**Format:** hierarchical braces (like Juniper-style), **not** JSON as the boot file.

You *can* **view** config as JSON (`show configuration json`), and automation can use JSON/API, but the file you edit and load for bare metal is almost always **`config.boot`**.

---

## What is *not* the source of truth

| Approach | Role |
|----------|------|
| Bash that prints `set ...` lines | Convenience generator only |
| Pasting CLI forever | Works, but not your desired workflow |
| Editing random Linux `/etc` files | **Wrong** — VyOS regenerates service configs from `config.boot` |

---

## Correct “edit a file, apply it” workflow

### Preferred (safe, official)

On the **router** after VyOS is installed:

```text
configure
load /path/to/config.boot.home
commit
save
exit
```

- `load` replaces working config from the file  
- `commit` makes it **live**  
- `save` writes `/config/config.boot` so it **survives reboot**

That is the CLI equivalent of “GUI Apply + Save.”

### Also valid (clone / imaging)

Copy a known-good `/config/config.boot` onto a machine **before** first network use, then boot — boot loader applies it. Still treat `load`/`commit`/`save` as the day-to-day method when the box is already running.

### Custom image (advanced)

VyOS Platform docs: **custom default configuration file** in a **custom build** (`vyos-build` + JSON *build* flavor). That is for baking a factory default into an ISO — optional later for Valley Tech golden images.

### Cloud / VM automation

**cloud-init** (official): inject config at first boot. Best for VMs/cloud; secondary for bare-metal USB appliance work.

---

## Home vs Office = two template files (3 ports only)

See **PORTS.md**. Physical: **WAN + LAN1 + LAN2** (not four ports).

| Profile | LAN1 (eth2) | LAN2 (eth3) |
|---------|-------------|-------------|
| **Home** `config.boot.home` | Family trusted `192.168.10.0/24` | Guest+IoT `192.168.50.0/24` |
| **Office** `config.boot.office` | Staff trusted `192.168.10.0/24` | Guest+IoT `192.168.50.0/24` |

| Port | This build’s name | Role |
|------|-------------------|------|
| Built-in | `eth0` | WAN (DHCP client) |
| USB NIC | `eth2` | LAN1 trusted |
| USB NIC | `eth3` | LAN2 guest/IoT |

`eth1` is **absent** on this hardware (kernel skipped it). Guest and IoT share **LAN2** (one segment).

Defaults: **DHCP** on both LANs. Statics: edit file later per client.

---

## JSON vs config.boot vs bash

| Format | Use when |
|--------|----------|
| **`config.boot` (braces)** | **Primary** — edit, version-control, `load` |
| **JSON** | Export/import tooling, API; not the usual boot file |
| **`set` command list** | Diff-friendly, generated from UI/docs |
| **Bash** | Only to *generate* or *deploy* the file; not the config itself |

**Your product:** maintain `config.boot.home` / `config.boot.office` (and per-client copies). Install OS from ISO → `load` the right file → `commit` → `save`.

---

## Marketing pages vs operator docs

- [VyOS Platform](https://vyos.io/vyos-platform): customizable images, open API, automation story  
- [Universal Router](https://vyos.io/vyos-universal-router): product positioning, Terraform/Ansible/cloud-init/API  

Day-to-day bare metal: **config.boot + load/commit/save** (docs: Configuration Overview).
