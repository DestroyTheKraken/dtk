# Nextcloud Laptop Drive — Installation Guide (v3)

**Follow this file.** Authoritative instructions for `nc_install_v3`.

## Architecture

- Real folders in `~/Documents`, `~/Pictures`, etc.
- **Outward symlinks** into Nextcloud data
- **Phase 1 `install_plan`** drives PHP version, Nextcloud version, PPA strategy, symlink keys, Apache/Tailscale backends
- **Tailscale serve** → `http://127.0.0.1:8080` (tailnet HTTPS only)
- **inotify watcher** + 2-min cron + 5-min symlink guardian

## Prerequisites

- Debian-family Linux (Ubuntu, Mint, Debian, Pop, etc.)
- Non-root desktop user with `sudo`
- Internet connection
- Tailscale installed and logged in (strongly recommended)
- 10–15 GB free in `/var` and `/home`

## Installation sequence

```bash
# Copy kit to target (USB or rsync from build machine)
rsync -av ./nc-lin-cs/ user@target:~/nc-lin-cs/
cd ~/nc-lin-cs

bash phase-01-scan-host.sh    # discovery + install_plan
bash phase-02-prereqs.sh        # apt packages per plan
bash phase-03-nextcloud-core.sh
bash phase-04-user-symlinks-acls.sh
bash phase-05-automation.sh     # Apache :8080, Tailscale, cron, guardian
bash phase-06-backup-automation.sh

bash install.sh
```

`install.sh` runs all phases, verifies, and starts the watcher (`/tmp/watch.log`).

Debug: run `phase-*.sh` individually.

## Phase 1 — what `install_plan` contains

Written to `phase-docs/01-host-scan.json`:

| Field | Purpose |
|-------|---------|
| `php_series` | 8.3 / 8.4 / 8.5 auto-detected |
| `nextcloud_version` | Paired release (30.0.5 / 31.0.0 / 33.0.5) |
| `php_ppa_strategy` | `use_ondrej_if_needed` or `skip_native_only` (Ubuntu 26.04) |
| `symlink_config.keys` | `follow_symlinks` and/or `localstorage.allowsymlinks` |
| `apache.backend_port` | 8080 |
| `download.tool` | curl or wget |

Subsequent phases **only read this plan** — no per-machine fix scripts.

## PHP / Nextcloud matrix

| Distro | PHP | Nextcloud | PPA |
|--------|-----|-----------|-----|
| Ubuntu 24.04 / Mint 22 | 8.3 | 30.0.5 | ondrej if needed |
| Ubuntu 26.04 resolute | 8.5 | 33.0.5 | **skip** (no suite) |

## NC 33 symlink note

NC 33 requires flat key in `config.php`:

```php
'localstorage.allowsymlinks' => true,
```

Phase 4 sets this via `occ` + direct `config.php` patch + php-fpm restart.

## Test history

Documented in `tests/TEST_LOG.md` and `tests/host-*.json` (anonymized profiles).

## Post-install

- URL: `https://<hostname>.<tailnet>.ts.net`
- Credentials: `phase-docs/.install-credentials` (chmod 600)
- Remove `~/nc-lin-cs` from client machines when done (keep on USB / build machine)

## Maintenance

```bash
sudo -u www-data php /var/www/nextcloud/occ files:scan YOUR_USER
tail -f /tmp/watch.log
tail -f /tmp/nextcloud-symlink-guardian.log
bash verify-install.sh   # appends to tests/TEST_LOG.md
```

## Remote backup pull

Hub writes daily archives to `~/Backups/nas-export/`. Pull to your backup server with rsync/scp — configure paths locally, not in this repo.