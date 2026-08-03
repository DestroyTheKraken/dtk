# nc-lin-cs

**Nextcloud installer — Linux client/server hub** (laptop-as-cloud)

Phase-based Bash installer for a sovereign Nextcloud hub on Debian-family Linux: real home folders, outward symlinks, Tailscale HTTPS, phone sync. Built for **ValleyForge / ValleyHub field installs** and household hubs.

**Version:** 3.0.0 · **Status:** Field-tested (Mint 24.04, Ubuntu 26.04) · **Install:** one command

---

## Quick start

```bash
bash install.sh
```

Prompts: Nextcloud username · login password · sudo once. Runs phases 1–6, verifies, starts watcher (`/tmp/watch.log`).

**Remote bootstrap:**

```bash
curl -fsSL https://raw.githubusercontent.com/DestroyTheKraken/nc-lin-cs/main/install-nc-hub.sh | bash
```

**USB / tarball:**

```bash
tar -xzf nc-lin-cs-3.0.0.tar.gz && cd nc-lin-cs && bash install.sh
```

---

## What this installs

| Piece | Detail |
|-------|--------|
| Model | Real `~/Documents`, etc. → outward symlinks into NC data |
| Access | Tailscale serve → `https://<host>.<tailnet>.ts.net` |
| Sync | inotify watcher + 2-min cron + 5-min symlink guardian |
| Backup | Daily cron → `~/Backups/nas-export/` |
| Stack | Auto-paired PHP + Nextcloud per OS (see `docs/INSTALL.md`) |

---

## Repo layout

| Path | Purpose |
|------|---------|
| `install.sh` | **Canonical entry** — customer / field SOP |
| `phase-0*.sh` | Debug one phase at a time |
| `wipe-nextcloud-hub.sh` | Clean reinstall (sudo) |
| `package-release.sh` | Build release tarball |
| `tests/` | Anonymized iteration log |
| `docs/` | Install guide, naming, security, GrokBuild notes |

---

## Verified profiles

| Profile | OS | Stack | Mobile |
|---------|-----|-------|--------|
| host-mint24 | Mint / 24.04 | PHP 8.3 · NC 30.0.5 | verified |
| host-ubuntu26 | Ubuntu 26.04 | PHP 8.5 · NC 33.0.5 | verified |

Full history: `tests/TEST_LOG.md`

---

## Field kit policy

- **Source of truth:** this repo + USB copy for on-site work
- **Client hubs:** remove kit after install unless mid-debug
- **Credentials:** `phase-docs/.install-credentials` only — never commit `phase-docs/`

---

## Docs

- [Field install SOP](docs/INSTALL.md)
- [Security](docs/SECURITY.md)
- [Repo purpose](docs/REPO.md)
- [Installer family naming](docs/NAMING.md)
- [GrokBuild — how this was built](docs/GROKBUILD.md)
- [Changelog](CHANGELOG.md)

---

## Product context

Sells as **Sovereign Nextcloud Private Hub** ($450–$650 field install). Managed tiers live on DTK cluster (ValleyHub). This repo is the **repeatable USB/field kit**, not the multi-tenant server product.

---

## Repository

**https://github.com/DestroyTheKraken/nc-lin-cs** — personal/professional field kit (see [docs/REPO.md](docs/REPO.md)). Not soliciting community contributions.

*GrokBuild project — [docs/GROKBUILD.md](docs/GROKBUILD.md)*
