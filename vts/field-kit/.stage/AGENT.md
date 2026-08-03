# AGENT.md — How Grok should work on Valley Tech / Sovereign Aid

**Audience:** Joshua is building skills while delivering real work. Treat “I don’t know this CLI yet” as the default, not the exception.

---

## Response style (required)

### 1. Research before instructing

- Look up the **exact** command for the OS/tool (VyOS op-mode wrapper, Ubuntu path, etc.).
- Prefer **doing it from um690 over SSH** when access already exists, instead of sending Josh to the console.
- If a step cannot be automated, write a **full walkthrough**, not a jargon label.

### 2. Never assume jargon is understood

| Bad (do not do this) | Good (do this) |
|----------------------|----------------|
| “Save the config to disk” | Explain: this creates a file *on the router*; then give the exact command and what success looks like |
| “Copy off the box via SCP” | Explain what SCP is in one sentence; give full `scp ...` with real hostnames/paths; or offer a USB file-manager path with screenshots-level steps |
| “Mount the USB” | Give `lsblk` → find LABEL → full path like `/run/media/kraken/Ventoy` |
| “In operational mode” | “Log in so you see `vyos@hostname:~$` (dollar sign). Do **not** type `configure` yet.” |

### 3. Instruction template (use every time)

For each human step:

1. **Goal** — one sentence: what this step achieves  
2. **Where** — which machine (um690 / router / client laptop)  
3. **Commands** — copy-pasteable blocks, real paths  
4. **What you should see** — success output or UI cue  
5. **If it fails** — one recovery hint  

### 4. Prefer “Grok does it” over “Josh does it”

When SSH keys and network already work (e.g. `router-lab` → `192.168.20.1`):

- Retrieve configs, status, and files **from um690 via SSH**
- Save results under the project tree
- Tell Josh **what was done** and **where the files are**

Only ask Josh for: physical cables, BIOS boot order, passwords Grok must not store, Telegram bot creation, sudo password on his desktop session.

### 5. Teaching moments stay short

- Define a term once in plain English, then use it.
- Optional “Why this works” in a short note — not a textbook.

### 6. Field kit awareness

Canonical field kit lives at:

- Project: `~/Documents/valley-tech-support/field-kit/`
- USB (Ventoy stick): `/run/media/kraken/Ventoy/field-kit/` (when mounted)

Always update **both** when changing installers (or run `field-kit/assemble-to-usb.sh`).

---

## Project vocabulary (use consistently)

| Term | Meaning |
|------|---------|
| **um690** | Your main control PC / lab workstation |
| **Router / VyOS** | The Lenovo appliance firewall; LAN IPs `192.168.10.1` (home) and `192.168.20.1` (lab) |
| **config.boot** | VyOS’s main settings file (like the whole router config in one file) |
| **Ventoy USB** | Stick that boots ISOs; currently often labeled `Ventoy` |
| **Field kit** | Folder of all installers + configs for onsite work |
| **Nextcloud outward symlinks** | Real files stay in `/home/user/...`; Nextcloud links to them |
| **load / commit / save** | VyOS: load a config file → make it live → write so it survives reboot |

---

## Example: how to teach “get router config” (canonical)

**Do not** say only: save on router then SCP.

**Do** either:

**A (preferred):** Grok on um690:

```bash
ssh router-lab '/opt/vyatta/bin/vyatta-op-cmd-wrapper show configuration' \
  > ~/Documents/valley-tech-support/packages/network-install/configs/config.boot.from-router-LATEST
```

**B (if Josh must do it):** full steps with “you will see…” for each command, including how to open the file on um690 afterward.

---

#valley-tech-support #agent
