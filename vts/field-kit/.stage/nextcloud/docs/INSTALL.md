# Field install SOP

Authoritative steps for **nc-lin-cs** on a client or household Linux machine.

## Before you start

- Debian-family desktop (Ubuntu, Mint, Debian, Pop, …)
- Normal user with `sudo`
- Tailscale installed and logged in (recommended)
- ~15 GB free in `/var` and `/home`

## Customer install (one command)

```bash
cd nc-lin-cs    # or extracted tarball / USB copy
bash install.sh
```

1. Enter **Nextcloud username** (default: Linux username)
2. Enter **login password** (or Enter to auto-generate — saved in `phase-docs/.install-credentials`)
3. Enter **sudo password** once

Install takes ~5 minutes. Watcher starts automatically. Log: `/tmp/watch.log`

## Debug install (phase by phase)

```bash
bash phase-01-scan-host.sh    # scan + install_plan
bash phase-02-prereqs.sh
bash phase-03-nextcloud-core.sh
bash phase-04-user-symlinks-acls.sh
bash phase-05-automation.sh
bash phase-06-backup-automation.sh
bash verify-install.sh
```

Re-run a single phase after fixes. Do not skip order on first install.

## Wipe and reinstall

```bash
sudo bash wipe-nextcloud-hub.sh
rm -rf phase-docs/
bash install.sh
```

## PHP / Nextcloud (auto — phase 1)

| OS class | PHP | Nextcloud |
|----------|-----|-----------|
| Ubuntu 24.04 / Mint 22 | 8.3 | 30.0.5 |
| Ubuntu 26.04 resolute | 8.5 | 33.0.5 (no ondrej PPA) |

## Post-install checks

```bash
bash verify-install.sh
curl -sI http://127.0.0.1:8080/status.php | head -1
tailscale serve status
tail -5 /tmp/watch.log
```

Phone: connect Nextcloud app to `https://<hostname>.<tailnet>.ts.net` — confirm Documents, Pictures, Templates.

## Build release tarball

```bash
bash package-release.sh
# → dist/nc-lin-cs-3.0.0.tar.gz
```

## Remove kit from hub (after success)

```bash
rm -rf ~/nc-lin-cs
```

Copy credentials from `phase-docs/.install-credentials` to your password manager first.
