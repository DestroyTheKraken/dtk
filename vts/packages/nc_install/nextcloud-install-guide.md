# Nextcloud Laptop "Google Drive" Replacement - Installation Guide

**Follow this file.** It contains the complete, authoritative instructions.

This guide explains how to use the phase-based installer to set up a self-hosted Google Drive replacement on a Linux laptop (Ubuntu/Mint recommended).

## Core Architecture (What This Installs)

- **Real local folders** in your home directory (`~/Documents`, `~/Pictures`, `~/Downloads`, etc.).
- **Outward symlinks** inside Nextcloud so the web UI and phone apps see the same folders.
- Files created/saved on the laptop appear **nearly instantly** in the Nextcloud app on your phone (via inotify watcher + periodic scan).
- All data stays on your laptop's SSD (single copy).
- Access everything securely over Tailscale (no port forwarding or public exposure).
- Only standard user folders are included — no dot-directories (`.cache`, `.config`, etc.).

## Prerequisites on the Target Machine

- Linux desktop (Ubuntu 22.04/24.04 or Linux Mint 21/22 recommended)
- Non-root user account (the one you normally use day-to-day)
- `sudo` access
- Internet connection
- (Strongly recommended) Tailscale installed and logged in on the machine before starting
- At least 10–15 GB free space in `/var` and `/home`

## Step-by-Step Installation Order (Phase Pattern)

**You must follow these steps in exact order.**  
The installer uses a phase → output-document system where each phase reads the JSON file created by the previous phase.

**Full required sequence:**

1. Copy the `nc_install` folder to the target machine and `cd` into it as the normal user.
2. Run `phase-01-scan-host.sh`
3. Run `phase-02-prereqs.sh`
4. Run `phase-03-nextcloud-core.sh`
5. Run `phase-04-user-symlinks-acls.sh`
6. Run `phase-05-automation.sh`
7. **Immediately** start the watcher with the `nohup` command (see step 7 below).

**Do not stop after phase-05-automation.sh.** Step 7 is required for the near-instant sync behavior.

### 1. Copy the Installer to the Target Machine

```bash
# On your machine (or the target)
scp -r /path/to/nc_install user@target-machine:~
# or
rsync -av nc_install/ user@target-machine:~/nc_install/
```

Log in as the **normal desktop user** (not root).

```bash
cd ~/nc_install
```

### 2. Phase 1 – Scan the Host

```bash
bash phase-01-scan-host.sh
```

- This script gathers OS version, current user, home directory, Tailscale status, disk space, existing folders, web server/PHP status, etc.
- It creates `phase-docs/01-host-scan.json`.
- Review the JSON if you want (it's human-readable).

**Continue only after this completes successfully.**

### 3. Phase 2 – Install Prerequisites

```bash
bash phase-02-prereqs.sh
```

- Installs Apache, PHP 8.3 + required modules, MariaDB, Redis, inotify-tools, acl, etc.
- Enables and starts services.
- Creates `phase-docs/02-prereqs.json`.

### 4. Phase 3 – Nextcloud Core Installation

```bash
bash phase-03-nextcloud-core.sh
```

- Downloads and extracts Nextcloud.
- Creates the database and database user (random secure password is generated and recorded).
- Runs the initial `occ maintenance:install`.
- Applies Redis + APCu configuration.
- Creates `phase-docs/03-nextcloud-core.json` (contains the database password — keep this file safe or delete it after installation).

### 5. Phase 4 – User, Outward Symlinks & ACLs

```bash
bash phase-04-user-symlinks-acls.sh
```

- Ensures the main user exists in Nextcloud (prompts for password if creating).
- Creates real local folders if they don't exist.
- Creates **outward symlinks** from Nextcloud into your real home folders.
- Applies proper ACLs so `www-data` (the web server) can read and write your files.
- Creates `phase-docs/04-user-symlinks.json`.

### 6. Phase 5 – Automation (Watcher, Cron, Tailscale Serve)

```bash
bash phase-05-automation.sh
```

This phase:
- Deploys the customized `watch-and-scan.sh` script.
- Adds the safety cron job (every 2 minutes).
- Configures `tailscale serve`.
- Runs a final full scan.
- Creates `phase-docs/05-complete.json`.

**Do not stop here.** Phase 5 only prepares everything.

### 7. Start the Near-Real-Time Watcher (MANDATORY – do this immediately after Phase 5)

Phase 5 **only deploys** the watcher script and the cron job.  
You **must** manually start the watcher process right after Phase 5 for the near-instant sync to work.

Run these exact commands in order:

```bash
cd ~/nc_install
nohup ./watch-and-scan.sh > /tmp/nextcloud-watch.log 2>&1 &
```

- The `nohup` command starts the inotify watcher in the background.
- It watches your real local folders and triggers immediate scans when files change.
- The cron (set in Phase 5) is only a backup that runs every 2 minutes.

To stop the watcher later (if needed):

```bash
pkill -f watch-and-scan.sh
```

**Do not skip step 7.** Without running the `nohup` command, you will only get the slower cron-based updates.

### Access Nextcloud

Make sure Tailscale is connected on both the laptop and your phone.

1. On the laptop, get your Tailscale hostname:
   ```bash
   tailscale status
   ```
2. Open in a browser (laptop or phone):
   ```
   https://your-laptop-hostname.tailnet-name.ts.net
   ```
3. Log in as the user you created during Phase 4.

### Verify Everything Works

1. On the laptop, create or save a file in `~/Documents/test-sync.txt`.
2. Wait a few seconds (the watcher should pick it up).
3. Check in the Nextcloud web UI or phone app — the file should appear.
4. Create a file from the phone app inside Documents → it should appear on the laptop almost immediately.

## Useful Maintenance Commands

```bash
# Full manual rescan
sudo -u www-data php /var/www/nextcloud/occ files:scan your-username

# Targeted scan (faster)
sudo -u www-data php /var/www/nextcloud/occ files:scan your-username --path=/Documents

# Check what Nextcloud can actually see
sudo -u www-data ls /var/lib/nextcloud/data/your-username/files/Documents/ | head

# View watcher log
tail -f /tmp/nextcloud-watch.log
```

## Re-running Phases

You can safely re-run individual phases. They are mostly idempotent.

Example: If you only want to re-apply ACLs and rescan after adding a new folder:

```bash
bash phase-04-user-symlinks-acls.sh
bash phase-05-automation.sh
```

## Important Notes

- **Do not** delete the `phase-docs/` directory if you want to re-run phases later.
- The database password is only stored in `03-nextcloud-core.json`. Delete this file after installation if you want (you can reset the DB user password via MariaDB if needed).
- The watcher script is customized per machine during Phase 5. If you copy it manually to another machine, you must edit the placeholders or re-run Phase 5.
- Tailscale serve configuration is applied in Phase 5. You may need to run this once manually on the target machine:
  ```bash
  tailscale set --operator=$USER
  tailscale serve --bg http://127.0.0.1:8080
  ```

## Directory Structure After Installation

```
/home/your-user/nc_install/
├── phase-01-scan-host.sh
├── phase-02-prereqs.sh
├── phase-03-nextcloud-core.sh
├── phase-04-user-symlinks-acls.sh
├── phase-05-automation.sh
├── run-all-phases.sh
├── watch-and-scan.sh
├── nextcloud-install-guide.md
└── phase-docs/
    ├── 01-host-scan.json
    ├── 02-prereqs.json
    ├── 03-nextcloud-core.json
    ├── 04-user-symlinks.json
    └── 05-complete.json
```

## One-Command Option (for experienced users)

```bash
bash run-all-phases.sh
```

This runs all phases in order. You will still be prompted where necessary.

---

You now have a clean, reproducible installer that can be copied to any compatible Linux laptop.

Test on another machine and report any issues. The generated JSON documents in `phase-docs/` contain all the machine-specific decisions, making remote troubleshooting easier.