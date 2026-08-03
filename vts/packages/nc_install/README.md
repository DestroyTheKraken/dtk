# Nextcloud Laptop Drive - Portable Automated Installer

This is a portable, phase-based installer for the "local Google Drive replacement" setup using Nextcloud on a Linux laptop/desktop.

**Core Model (Outward Symlinks)**
- Your real folders stay in `/home/you/Documents`, `/home/you/Pictures`, etc.
- Nextcloud sees them via symlinks in its data directory.
- You get normal local access + instant visibility in the Nextcloud app on phones via Tailscale.
- Single copy of data on your SSD.
- No dot-directories are touched.

## Phase > Output-Doc Pattern

Run phases in order. Each phase produces a JSON document in `phase-docs/` that the next phase consumes.

1. `phase-01-scan-host.sh`  
   → `phase-docs/01-host-scan.json` (OS, user, services, Tailscale, existing folders, disk, etc.)

2. `phase-02-prereqs.sh`  
   → `phase-docs/02-prereqs.json`

3. `phase-03-nextcloud-core.sh`  
   → `phase-docs/03-nextcloud-core.json` (DB creds, paths, version)

4. `phase-04-user-symlinks-acls.sh`  
   → `phase-docs/04-user-symlinks.json`

5. `phase-05-automation.sh`  
   → `phase-docs/05-complete.json`

## Usage on a fresh machine

See `nextcloud-install-guide.md` for the complete, authoritative instructions, including the exact recommended order of operations and the phase → output-document workflow.

Quick start (after copying the `nc_install` directory to the target machine and `cd`ing into it):

```bash
bash phase-01-scan-host.sh
bash phase-02-prereqs.sh
bash phase-03-nextcloud-core.sh
bash phase-04-user-symlinks-acls.sh
bash phase-05-automation.sh
```

Or for a single command (still runs phases in correct order):

```bash
bash run-all-phases.sh
```

All scripts are interactive where they need passwords or confirmation.

## After Installation

- Start the watcher for near-instant sync:
  ```bash
  nohup ./watch-and-scan.sh > /tmp/nextcloud-watch.log 2>&1 &
  ```

- Access via Tailscale: `https://your-hostname.tailnet` (run `tailscale serve --bg http://127.0.0.1:8080` if not already)

- Cron runs every 2 minutes as safety net.

## Requirements / Assumptions
- Debian/Ubuntu/Mint family (apt)
- Non-root user who owns the folders
- Tailscale installed and logged in (or will be prompted)
- Reasonable disk space in /var and /home

## Cleanup on this development machine
This `nc_install` directory (containing the guide and scripts) can be copied to target users.
On the development laptop, the old `Nextcloud-config/` directory and related automation have been removed. The working Nextcloud installation is left in place for personal use.

## Remote Maintenance
The owner of this package can SSH or use Tailscale to the user's machine and re-run specific phases or the watcher script if issues arise.

## Files in this package
- `nextcloud-install-guide.md` ← **Primary instructions** (read this first)
- phase-*.sh
- run-all-phases.sh
- watch-and-scan.sh (will be customized during Phase 5)
- phase-docs/ (generated during installation)
- README.md (short pointer to the guide)

Tested model on Mint 22.3 / Ubuntu 24.04 class machines.