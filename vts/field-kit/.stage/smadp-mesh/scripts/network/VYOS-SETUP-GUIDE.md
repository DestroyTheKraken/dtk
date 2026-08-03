---
tags: [guide, vyos, network, phase0]
status: active
date: 2026-07-07
---

# VyOS Setup Guide — GrokOS Router Access

> [!summary] TL;DR
> **Phase 1** (15 min): VyOS console → paste 17 lines → `commit` → test `router` from um690.  
> **Phase 2** (optional): Fix node1 IP conflict via DHCP statics.

---

## Before you start

| You need | Detail |
|----------|--------|
| Physical access | Keyboard + monitor on VyOS, **or** serial, **or** existing VyOS session |
| Login | User `vyos` + your VyOS password |
| um690 | Left on and reachable at `192.168.20.100` |
| Time | ~15 minutes |

SSH from um690 to the router **does not work yet** — that is what this guide fixes.

---

## Phase 1 — Enable Grok SSH (minimal — no firewall lines)

> [!warning] Firewall lines removed
> Your VyOS rejected `firewall ipv4 input filter` rules. Phase 1 uses **SSH + key only**. Grok adds firewall rules after `router show configuration commands | match firewall`.

## Phase 1 — Enable Grok SSH (do this first)

### Step 1: Open the VyOS console

Use **one** of these:

1. **Keyboard + monitor** plugged into the VyOS machine (most common)
2. **Serial console** (USB-serial adapter to VyOS console port)
3. **Proxmox/VM console** if VyOS runs as a VM

You should see a `vyos@vyos:~$` or `vyos@vyos#` prompt after login.

### Step 2: Log in

```
login: vyos
password: <your VyOS password>
```

### Step 3: Enter configuration mode

Type exactly:

```
configure
```

Prompt changes to `[edit]`.

### Step 4: Paste the Phase 1 commands

**Option A — copy from um690 terminal (recommended)**

On **um690**, run:

```bash
cat ~/SovereignAid/scripts/network/vyos-phase1-minimal.conf
```

Select and copy **all 5 lines** (every line starts with `set`).

On the **VyOS console**, paste into the `[edit]` session.

**Option B — type/paste this block directly**

```
set service ssh port 22
set service ssh listen-address 192.168.10.1
set service ssh listen-address 192.168.20.1
set system login user vyos authentication public-keys grokos key AAAAC3NzaC1lZDI1NTE5AAAAIIuNIxDK5nTIAUxHJ20/VLIGIpWl8AsQxcHW0YFOMc5x
set system login user vyos authentication public-keys grokos type ssh-ed25519
```

### Step 5: Apply and save

VyOS does **not** use `commit check` on all versions. Just:

```
commit
save
exit
```

If `commit` fails, see **Troubleshooting** below.

### Step 7: Verify from um690

On **um690** (not VyOS), run:

```bash
router show version
```

**Pass:** you see VyOS version text.  
**Fail:** see **Troubleshooting B** below.

Also run:

```bash
bash ~/SovereignAid/scripts/network/vyos-verify-access.sh
```

---

## Phase 2 — Fix node1 IP conflict (after Phase 1 works)

### Step 1: Check your DHCP config path on VyOS

```
router
show configuration commands | match dhcp
```

Look for a line like:

```
set service dhcp-server shared-network-name LAB subnet 192.168.20.0/24 ...
```

- Josh's router uses `shared-network-name LABNET` — file is pre-edited for that.
- VyOS uses `mac` (not `mac-address`) for static mappings.

### Step 2: Apply DHCP static reservations

On VyOS:

```
configure
```

On um690, copy:

```bash
cat ~/SovereignAid/scripts/network/vyos-phase2-dhcp-static.conf
```

Paste into VyOS `[edit]`, then:

```
commit check
commit
save
exit
```

### Step 3: Verify node1

On um690:

```bash
router show dhcp leases
bash ~/SovereignAid/scripts/network/diagnose-node1-ssh.sh
```

ARP for `.101` should show `d8:cb:8a:01:7a:89`.

---

## Troubleshooting

### A — `commit` fails with `Rule action must be defined`

You have **broken firewall lines** in the pending config. Still in `[edit]`:

```
delete firewall ipv4 input filter rule 10
delete firewall ipv4 input filter rule 11
delete firewall ipv4 input filter rule 100
```

If those delete commands also fail, run:

```
show configuration commands | match firewall
```

Paste that output to Grok. Then use **only** the 5-line minimal block (no firewall), and `commit` again.

### B — Your VyOS uses zone-policy firewall

Skip all `firewall ipv4 input filter` lines. After SSH works from um690, Grok will write rules matching your syntax.

### B — `router show version` fails from um690

| Symptom | Try |
|---------|-----|
| `Connection refused` | Re-check Step 6 `commit`/`save`; run `show service ssh` on VyOS |
| `Permission denied` | Key not installed — re-paste the `set system login user vyos...` line |
| `Connection timed out` | Ping `192.168.10.1` from um690; check cable/VyOS up |

Manual SSH test:

```bash
ssh -i ~/.ssh/id_ed25519_vyos vyos@192.168.10.1 show version
```

### C — Phase 2 DHCP lines fail

Skip Phase 2 for now. Grok can still manage the router. Fix DHCP manually in VyOS GUI/CLI later.

---

## What this does NOT change

- Lab `.20` still cannot reach home `.10` **hosts**
- Only **um690** can SSH to the **router**
- No NAS or cluster data is touched

---

## After both phases

Tell Grok: **"VyOS setup done"** — it will run `vyos-diagnose.sh` and fix node1 WAN slowness.

#sovereignaid #vyos #guide