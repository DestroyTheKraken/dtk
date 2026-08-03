# Changelog

## 3.0.1 — 2026-06-21

- Security: credentials moved to `phase-docs/.install-credentials` (chmod 600)
- Security: anonymized test logs; removed personal ops scripts and host-specific data
- Security: expanded `.gitignore`; added `docs/SECURITY.md`
- `wipe-nextcloud-hub.sh` requires `NC_INSTALL_OWNER` when auto-detect fails

## 3.0.0 — 2026-06-20

- Unified discovery-driven installer (phase-1 `install_plan`)
- Debian-family auto PHP/NC pairing (8.3/30 on 24.04, 8.5/33 on Ubuntu 26.04)
- Single entry: `install.sh` (prompts, sudo cache, verify, watcher)
- NC33 flat `localstorage.allowsymlinks` + symlink guardian
- Field verified: Mint 24.04 reference, Ubuntu 26.04 phased + one-command + mobile sync
- Distribution: `package-release.sh`, `install-nc-hub.sh`
- Repo packaged as **nc-lin-cs**

## 2.x (legacy — DTK `nc_install`)

- Per-machine fix scripts; superseded by v3 phases
- Mint 24.04 production hub (PHP 8.3, NC 30)
