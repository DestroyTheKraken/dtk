# Multi-user Nextcloud hub (household seats)

Configure one Nextcloud instance so **each Linux login** on the machine is a Nextcloud user, with **outward symlinks** into real home folders (same model as the field-kit single-user install).

## Phone access (important)

| Field | Value |
|-------|--------|
| **Server URL (everyone)** | `https://<hostname>.<tailnet>.ts.net` |
| **Username** | Same as Linux login (e.g. `joshua`) |
| **Password** | Temp at create → **change after first login** |

Nextcloud does **not** use a path like `https://host/username` as a per-user server. The app has **one** server field + separate username.

**hickles example**

```text
Server:   https://hickles.taile52ad9.ts.net
Username: joshua   (admin)
Username: <other seat names>
```

Require: Tailscale app logged into the same tailnet (**HickmaNet**).

## Prerequisites

- Base Nextcloud already installed (field-kit `install.sh` / phases 01–05).
- Admin Linux account with sudo.
- Tailscale up; MagicDNS name known.

## One-shot on the hub

```bash
cd /path/to/field-kit/local-mirror/nextcloud   # or copy of nc_install
sudo ADMIN_USER=joshua bash configure-multiuser-hub.sh
```

Optional overrides:

```bash
sudo ADMIN_USER=joshua \
  TS_HOST=hickles.taile52ad9.ts.net \
  WEB_ROOT=/var/www/nextcloud \
  USERS="joshua alyssa nathon" \
  bash configure-multiuser-hub.sh
```

### What it does

1. Discovers Linux seats (`uid ≥ 1000`, home under `/home`, real shell) — or uses `USERS=…`.
2. For each seat: create NC user if missing, home folders, outward symlinks, ACLs, `files:scan`.
3. Puts **ADMIN_USER** in Nextcloud group `admin`; removes others from `admin` if present.
4. Writes **temp passwords for newly created users only** to `/root/nc-multiuser-temp-passwords.txt` (mode 600).
5. Sets trusted domain + `overwrite.cli.url` to the Tailscale HTTPS name.
6. Installs multi-user **scan-all** cron + **symlink guardian** cron; writes `watch-and-scan-multi.sh`.

### After run

```bash
# Start multi-folder watcher (near-instant sync)
sudo pkill -f watch-and-scan || true
nohup sudo bash ./watch-and-scan-multi.sh > /tmp/nextcloud-watch-multi.log 2>&1 &

# Verify
sudo -u www-data php /var/www/nextcloud/occ user:list
sudo -u www-data php /var/www/nextcloud/occ group:list
```

Copy temp passwords into **Bitwarden**, hand each person their card, then:

```bash
sudo shred -u /root/nc-multiuser-temp-passwords.txt
```

Existing users keep their passwords (`SKIP_EXISTING_PASSWORDS=1` default). To force new temps for everyone:

```bash
sudo SKIP_EXISTING_PASSWORDS=0 bash configure-multiuser-hub.sh
```

## SSH from um690 (so Grok can operate)

On **hickles** (Termius once), as the admin Linux user:

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHe6CfaLOfmYw43kVcw0gDY450A3MMNIDmoZW0GYthcz um690 - control plane' >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

Confirm which username you used (`whoami`), then on um690:

```bash
ssh -i ~/.ssh/id_ed25519 <that-user>@100.92.254.81 'hostname; whoami; ls /home'
```

## Operator checklist (hickles)

- [ ] SSH from um690 works  
- [ ] Six Linux seats listed under `/home`  
- [ ] Script run; `occ user:list` shows 6  
- [ ] Joshua (or `ADMIN_USER`) in `admin`  
- [ ] `https://hickles.taile52ad9.ts.net` opens login  
- [ ] Temp passwords in Bitwarden; root file deleted  
- [ ] Each phone: Tailscale + Nextcloud app with base URL + username  

## Related

- Single-user install: `field-kit/nextcloud/START.md`, `packages/nc_install/`
- Symlink model: `phase-04-user-symlinks-acls.sh`
