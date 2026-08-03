# Phase guide (what each step does)

Run in order. One command: `bash install.sh` runs all of these.

| Phase | Script | What it does |
|-------|--------|----------------|
| **01** | `phase-01-scan-host.sh` | Scans this PC (OS, user, disk, Tailscale). Writes `01-host-scan.json`. |
| **02** | `phase-02-prereqs.sh` | Installs packages (PHP, DB, etc.) needed for Nextcloud. |
| **03** | `phase-03-nextcloud-core.sh` | Installs Nextcloud + database; creates admin user. |
| **04** | `phase-04-user-symlinks-acls.sh` | Links real `~/Documents`, `~/Pictures`, … into Nextcloud (outward symlinks). |
| **05** | `phase-05-automation.sh` | Watcher/cron so phone sync stays fresh. |
| **06** | `phase-06-backup-automation.sh` | Optional backup automation hooks. |
| **Check** | `verify-install.sh` | Confirms install looks healthy. |
| **Multi-user** | `configure-multiuser-hub.sh` | Optional: one NC user per Linux seat + phone handoff (see `docs/MULTIUSER-HUB.md`). |

**Your steps for a normal job:** only `bash install.sh` (see `../START.md`).  
Use individual phases only when debugging.
