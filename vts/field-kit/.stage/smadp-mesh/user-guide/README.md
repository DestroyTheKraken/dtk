---
tags: [guide, daily, reference, grokos]
date: 2026-07-08
status: active
---

# SovereignAid User Guide

> [!summary] TL;DR
> **Phases 0–6 complete.** Ops hub: https://um690.taile52ad9.ts.net/ops/ · Jump: `node1` `node2` `control` `router`

**Josh** · Control plane **um690** · Tailnet `taile52ad9.ts.net`

---

## Start here (any device)

| Device | What to do |
|--------|------------|
| **Tablet / phone** | Open [[user-guide/Services]] → Ops Center → [[user-guide/Firefox-PWA-Setup]] |
| **Laptop** | Ops Center PWA + optional bookmark import |
| **Terminal (um690)** | Verify commands below · `user-guide` command |

---

## Service URLs

Full table: [[user-guide/Services]]

| Service | URL |
|---------|-----|
| Ops Center | https://um690.taile52ad9.ts.net/ops/ |
| Nextcloud | https://um690.taile52ad9.ts.net/ |
| Valley Tech | https://um690.taile52ad9.ts.net/vts/ |
| Longhorn | https://um690.taile52ad9.ts.net/longhorn/ |

---

## Cluster

| Node | Role | LAN | Tailscale |
|------|------|-----|-----------|
| um690 | Control + k3s server | .100 | um690.taile52ad9.ts.net |
| node1 | Worker | .101 | node1.taile52ad9.ts.net |
| node2 | Worker | .102 | node2.taile52ad9.ts.net |

```bash
node1          # worker 1
node2          # worker 2
control        # from workers → um690
router         # VyOS (um690 only)
```

---

## Verify (run on um690)

```bash
bash ~/SovereignAid/scripts/phase0/verify-phase0.sh
bash ~/SovereignAid/scripts/phase1/verify-phase1.sh
bash ~/SovereignAid/scripts/phase2/verify-phase2-https.sh
bash ~/SovereignAid/scripts/phase2/verify-phase2-nextcloud.sh
bash ~/SovereignAid/scripts/phase3/verify-phase3-delegation.sh
bash ~/SovereignAid/scripts/phase4/verify-phase4-valley-tech.sh
bash ~/SovereignAid/scripts/phase5/verify-phase5.sh
bash ~/SovereignAid/scripts/phase6/verify-phase6.sh
```

Index: [[phases/README]]

---

## Common operations

### Nextcloud (phone / tablet)

- **App URL:** `https://um690.taile52ad9.ts.net`
- Tailscale must be connected
- Password: `grep NEXTCLOUD_ADMIN_PASSWORD ~/.config/sovereign/nextcloud.env`

### Valley Tech website (edit & redeploy)

→ [[phases/Valley-Tech-Website-Quickstart]]

```bash
nano ~/SovereignAid/k8s/websites/valley-tech-support/content/contact.md
bash ~/SovereignAid/scripts/phase4/deploy-valley-tech.sh
```

### Backups & health reports

```bash
bash ~/SovereignAid/scripts/backup/run-smadp-backup.sh      # manual backup
bash ~/SovereignAid/scripts/phase5/daily-health-report.sh   # manual report
```

- Reports: Nextcloud `reports/` + `/mnt/systems_admin/reports/`
- Cron: daily 8am PT report · Sunday 3am PT backup

### Delegation (um690 → workers)

```bash
bash ~/SovereignAid/scripts/delegation/create-task.sh \
  --target node1 --title "Test" --command "hostname" --verify "true"
bash ~/SovereignAid/scripts/phase3/verify-phase3-delegation.sh
```

### Network (VyOS)

```bash
bash ~/SovereignAid/scripts/network/vyos-diagnose.sh
bash ~/SovereignAid/scripts/network/verify-phase2-dhcp.sh
router show dhcp leases
```

### NAS / restic

| What | Where |
|------|-------|
| BTRFS mount | `/mnt/systems_admin` |
| restic repo | `/mnt/systems_admin/restic/smadp` |
| restic password | `~/.config/sovereign/restic.env` |

---

## Key paths

| Path | What |
|------|------|
| [[DESIGN]] | Platform plan |
| [[phases/README]] | Phase index (0–6 complete) |
| [[specs/cluster]] | Hardware |
| [[phases/Service-Credentials]] | Logins + Bitwarden |
| [[aide_installer_pkg/INSTALL]] | Rebuild from scratch |
| `aide_installer_pkg/sync-from-repo.sh` | Refresh installer package |
| `k8s/ops-center/static/` | Ops dashboard source |
| `Weekday/` | Session prompts |

---

## Build status (8 Jul 2026)

| Phase | Status |
|-------|--------|
| 0 Foundation | Complete |
| 1 k3s + Longhorn | Complete |
| 2 Platform (Traefik, Nextcloud, HTTPS, monitoring) | Complete |
| 3 Grok delegation | Complete |
| 4 Valley Tech website | Operational |
| 5 Backups + daily reports | Complete |
| 6 Ops Center + PWA guide | Complete |

---

## `user-guide` command

```bash
user-guide              # full guide
user-guide services     # URLs
user-guide pwa          # tablet / Firefox setup
user-guide verify       # verify scripts
user-guide ssh          # mesh jumps
user-guide help
```

---

## Troubleshooting

> [!warning] node1 SSH flaky
> `bash ~/SovereignAid/scripts/phase0/ssh-worker.sh node1 recover`

> [!note] Tablet cannot import bookmarks
> Use https://um690.taile52ad9.ts.net/ops/bookmarks.html — see [[user-guide/Firefox-PWA-Setup]]

> [!note] restic backup permission denied
> `sudo bash ~/SovereignAid/scripts/backup/fix-restic-permissions.sh`

---

#sovereignaid #guide