# Beginner guide: get a copy of the VyOS router config onto um690

**Goal:** Have a file on your main PC (um690) that is a full snapshot of the router settings.

**You do not need to understand SCP first.** Prefer the automatic method.

---

## Method A — Grok / um690 does it (easiest)

**Where:** um690 terminal (or ask Grok to run this).

**What it does:** Logs into the router over the network and prints the config into a file on um690.

```bash
# 1) Create destination folder (if needed)
mkdir -p ~/Documents/valley-tech-support/packages/network-install/configs

# 2) Pull config from router at 192.168.20.1 (lab side IP)
ssh router-lab '/opt/vyatta/bin/vyatta-op-cmd-wrapper show configuration' \
  > ~/Documents/valley-tech-support/packages/network-install/configs/config.boot.from-router-LATEST

# 3) Confirm the file has content (should be many lines, not empty)
wc -l ~/Documents/valley-tech-support/packages/network-install/configs/config.boot.from-router-LATEST
```

**What you should see:** A number like `200` or higher (line count).  
**If SSH fails:** From um690 run `ping -c 2 192.168.20.1`. If ping works but SSH fails, say so to Grok (key/user problem).

**Open the file later:**  
Files app → Documents → valley-tech-support → packages → network-install → configs  
Or: `less ~/Documents/valley-tech-support/packages/network-install/configs/config.boot.from-router-LATEST`

---

## Method B — On the router console (if you are at keyboard+monitor)

**Where:** Screen plugged into the router.

1. Log in as user `vyos` (password you set).  
2. You should see a prompt ending in `$` (not `#`). That means “operational mode” — good for viewing, not editing.  
3. Display the config:

```text
show configuration
```

4. To write a file **on the router’s own storage** (this is “save a copy on the router disk”):

```text
show configuration | cat > /config/my-backup.config
```

   Or in config mode after changes, the normal save is:

```text
configure
save
exit
```

   That writes the live settings to `/config/config.boot` on the router.

5. To get that file to um690 without learning SCP yet:  
   - **Easiest:** use Method A from um690 instead.  
   - **USB:** plug USB into router (if mounts), copy with file tools — advanced; Method A is preferred.

---

## Method C — SCP (only when you want to learn it)

**What SCP is:** “secure copy” — copy a file over the network using SSH login.

**Where:** um690 terminal.

```bash
# Copy the router’s main config file to your Documents folder
scp -i ~/.ssh/id_ed25519_vyos \
  vyos@192.168.20.1:/config/config.boot \
  ~/Documents/valley-tech-support/packages/network-install/configs/config.boot.from-scp
```

**What you should see:** A progress line, then a file appears in that folder.  
**If permission denied:** the `vyos` user may need `sudo cat` on the router; use Method A instead (it does not need to read the raw file as root).

---

## Words decoded

| Phrase | Plain meaning |
|--------|----------------|
| Operational mode | Logged in, prompt `$`, can run `show ...` |
| Configuration mode | Typed `configure`, prompt `#`, can change settings |
| config.boot | The main settings file VyOS loads at boot |
| “On the router’s disk” | Stored inside the router hardware, not on um690 yet |
| SCP | Network copy of a file using SSH |
