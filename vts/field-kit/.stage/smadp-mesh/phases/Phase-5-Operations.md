---
tags: [phase5, backup, restic, health-report, grokos, smadp]
date: 2026-07-08
status: complete
owner: Josh
---

# Phase 5 — Operations & Reliability

> [!summary] TL;DR
> restic backups to BTRFS + daily 8am health report in Nextcloud `/reports/`.

> [!success] Done 8 Jul 2026
> First restic snapshot `b1c1de38`. Cron active. Verify passes.

---

## Goal

Per [[DESIGN]] §9 Phase 5 — backups and daily health reporting.

---

## Components

| Component | Script | Schedule |
|-----------|--------|----------|
| restic repo | `scripts/backup/init-restic-repo.sh` | Once |
| Backup | `scripts/backup/run-smadp-backup.sh` | Sun 03:00 PT (cron) |
| Health report | `scripts/phase5/daily-health-report.sh` | Daily 08:00 PT (cron) |
| Cron install | `scripts/phase5/install-phase5-cron.sh` | Once (sudo) |

---

## Setup (um690)

```bash
sudo bash ~/SovereignAid/scripts/backup/init-restic-repo.sh
# If backup fails permissions: sudo bash scripts/backup/fix-restic-permissions.sh
# If restic.env in /root: sudo bash scripts/backup/fix-restic-env.sh
bash ~/SovereignAid/scripts/phase5/daily-health-report.sh
bash ~/SovereignAid/scripts/backup/run-smadp-backup.sh
sudo bash ~/SovereignAid/scripts/phase5/install-phase5-cron.sh
bash ~/SovereignAid/scripts/phase5/verify-phase5.sh
```

Save `~/.config/sovereign/restic.env` password → [[phases/Service-Credentials]].

---

## Reports

| Location | Path |
|----------|------|
| BTRFS | `/mnt/systems_admin/reports/smadp-health-YYYY-MM-DD.md` |
| Nextcloud | Files → `reports/` (admin user) |

---

## Deferred

- rsync offsite target (weekly)
- Delegation failure alerting to Nextcloud

---

#sovereignaid #phase5 #backup #restic