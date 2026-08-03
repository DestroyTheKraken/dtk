# Security

How to keep **nc-lin-cs** safe for you and your clients.

## Repository visibility

- **Recommended:** GitHub repo set to **Private**.
- If public read-only: never commit host-specific test logs, tailnet names, or credentials.
- Disable Issues unless you want a personal scratch pad.

## Never commit

| Item | Why |
|------|-----|
| `phase-docs/` | Per-host scan data, install state |
| `phase-docs/.install-credentials` | NC admin password, MariaDB password |
| GitHub PATs / API tokens | Full account access |
| SSH private keys | Remote access |
| Client hostnames, Tailscale IPs, tailnet DNS | Operational privacy |
| Real usernames tied to households | Privacy |

`.gitignore` excludes `phase-docs/` and `.install-credentials`. Verify before every push:

```bash
git status
git diff --cached
```

## Credentials on disk (target machine)

After install, secrets live only in:

```
phase-docs/.install-credentials   # chmod 600
```

Phase JSON files (`01-host-scan.json`, `03-nextcloud-core.json`, etc.) **do not** store passwords.

Copy credentials to a password manager, then optionally remove the kit directory from the hub.

## PAT hygiene

- Use fine-grained tokens scoped to **this repo only** with **Contents: Read and write**.
- Never paste tokens in chat, issues, or commit messages.
- Rotate immediately if exposed.

## Distribution

| Method | Risk |
|--------|------|
| USB tarball from your build machine | Lowest — you control the bits |
| GitHub Release + SHA256 checksum | Good for clients who verify checksum |
| `curl \| bash` from `main` | Convenient; pin release URL + checksum for production |

Prefer tagged releases (`v3.0.0`) over floating `main` for client installs.

## Field kit on client laptops

- Remove `~/nc-lin-cs` after successful install unless actively debugging.
- `wipe-nextcloud-hub.sh` requires explicit `NC_INSTALL_OWNER` if auto-detect fails.
- Temporary passwordless sudo (`NC_INSTALL_TEMP_SUDO=1`) is for lab retests only — removed by `verify-install.sh`.

## Backup staging

`backup-hub-to-staging.sh` writes to `~/Backups/nas-export/` on the hub. Pull archives to your own backup server with rsync/scp — do not embed NAS paths or family names in this repo.

## Reporting problems

If you find committed secrets in history, rotate credentials, force-push a sanitized tree, or use GitHub secret scanning. Do not open public issues with log excerpts containing passwords.
