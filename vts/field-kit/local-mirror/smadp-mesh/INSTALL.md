# Sovereign Aide — Fast Install Guide

> One-line steps. Run scripts from `~/SovereignAid` (or copy `aide_installer_pkg/` to each machine).  
> Refresh package: `bash aide_installer_pkg/sync-from-repo.sh`

---

## Prerequisites (all nodes: um690, node1, node2)

1. Install **Ubuntu Server 26.04 LTS** (or latest LTS) on all machines; hostname = `um690`, `node1`, `node2`.
2. Create user **`kraken`** (or your admin user) with sudo on every node.
3. Set static LAN IPs on **192.168.20.0/24** (um690 `.100`, node1 `.101`, node2 `.102`) — or use VyOS DHCP statics later.
4. **SSH key-only auth**: copy your public key to each node; disable password login when mesh works.
5. **SSH mesh** on um690: `bash scripts/phase0/setup-ssh-mesh.sh` then `bash scripts/phase0/verify-ssh-mesh.sh`.
6. Install **Tailscale** on all nodes; join tailnet; enable **MagicDNS** + **HTTPS certificates** in admin.
7. Install **Grok Build CLI** on all nodes: `curl -fsSL https://x.ai/cli/install.sh | bash` — [docs](https://docs.x.ai/build/overview).
8. Create project folder: `mkdir -p ~/SovereignAid && cd ~/SovereignAid`.
9. Copy or clone this repo into `~/SovereignAid` (include `aide_installer_pkg/`).
10. Open **Grok Build** in `~/SovereignAid` and paste the bootstrap prompt from `aide_installer_pkg/PROMPT.md`.

---

## Phase 0 — Foundation (all nodes)

11. Mount NAS (um690): `sudo bash scripts/phase0/setup-nas-fstab.sh` → `bash scripts/phase0/verify-nas-mount.sh`.
12. UFW + delegation dirs (each node): `sudo bash scripts/phase0/run-phase0-sudo-all-nodes.sh` or per-node sudo scripts.
13. Deploy phase0 scripts to workers: `bash scripts/phase0/deploy-phase0-scripts.sh`.
14. **Gate**: `bash scripts/phase0/verify-phase0.sh` on all three nodes.

---

## Network — VyOS (um690 only, optional but recommended)

15. Configure VyOS SSH for Grok: `bash scripts/network/setup-vyos-grok-access.sh`.
16. Apply Phase 2 DHCP statics: `bash scripts/network/apply-vyos-phase2-dhcp.sh`.
17. **Gate**: `bash scripts/network/verify-phase2-dhcp.sh`.

---

## Phase 1 — Kubernetes (um690 only)

18. Worker passwordless sudo (from um690): `bash scripts/phase1/bootstrap-worker-sudo.sh`.
19. Full k3s + Longhorn: `sudo bash scripts/phase1/run-phase1.sh`.
20. **Gate**: `bash scripts/phase1/verify-phase1.sh`.

---

## Phase 2 — Platform (um690)

21. Traefik ingress: `sudo bash scripts/phase2/deploy-traefik.sh` → `bash scripts/phase2/verify-phase2-traefik.sh`.
22. MagicDNS hostnames: `bash scripts/phase2/configure-magicdns-ingress.sh`.
23. Nextcloud + MariaDB: `bash scripts/phase2/deploy-nextcloud.sh` → `bash scripts/phase2/verify-phase2-nextcloud.sh`.
24. Tailscale HTTPS: `sudo bash scripts/phase2/setup-tailscale-https.sh` → `bash scripts/phase2/verify-phase2-https.sh`.
25. TLS renewal cron: `sudo bash scripts/phase2/install-tailscale-tls-cron.sh`.
26. Monitoring: `bash scripts/phase2/deploy-monitoring.sh` → `bash scripts/phase2/verify-phase2-monitoring.sh`.
27. **Gate**: all `scripts/phase2/verify-*.sh` pass; phone/tablet at `https://um690.taile52ad9.ts.net`.

---

## Phase 3 — Grok Delegation (all nodes)

28. Install Grok CLI on workers (if missing): `bash scripts/phase3/install-grok-cli-workers.sh`.
29. Deploy delegation watcher: `sudo bash scripts/phase3/deploy-delegation.sh`.
30. Fix queue permissions if needed: `sudo bash scripts/phase3/fix-delegation-permissions.sh`.
31. **Gate**: `bash scripts/phase3/verify-phase3-delegation.sh` (test task um690 → node1).

---

## Phase 4 — Hugo Websites (um690)

32. Build Valley Tech site: `bash scripts/phase4/build-valley-tech.sh`.
33. Deploy to k8s: `bash scripts/phase4/deploy-valley-tech.sh`.
34. **Gate**: `bash scripts/phase4/verify-phase4-valley-tech.sh` → `https://um690.taile52ad9.ts.net/vts/`.

Quickstart for future edits: `phases/Valley-Tech-Website-Quickstart.md` (in repo or `aide_installer_pkg/phases/` after sync).

Daily operations after build: `user-guide/README.md` · `user-guide/Services.md`

---

## Phase 5 — Operations (um690)

35. Init restic: `sudo bash scripts/backup/init-restic-repo.sh` (save `restic.env` password).
36. Test report: `bash scripts/phase5/daily-health-report.sh`.
37. Test backup: `bash scripts/backup/run-smadp-backup.sh`.
38. Cron: `sudo bash scripts/phase5/install-phase5-cron.sh`.
39. **Gate**: `bash scripts/phase5/verify-phase5.sh`.

---

## Phase 6 — User Experience (um690 + Firefox)

40. Deploy Ops Center: `bash scripts/phase6/deploy-ops-center.sh`.
41. Import bookmarks: Firefox → `user-guide/smadp-bookmarks.html`.
42. Install PWAs: [[user-guide/Firefox-PWA-Setup]] (Ops, Nextcloud, Longhorn).
43. **Gate**: `bash scripts/phase6/verify-phase6.sh` → `https://um690.taile52ad9.ts.net/ops/`.

---

## Secrets (never commit)

| File | Purpose |
|------|---------|
| `~/.config/sovereign/nextcloud.env` | Nextcloud + MariaDB passwords |
| `~/.config/sovereign/vyos.env` | VyOS SSH (optional) |
| `~/.grok/auth.json` | Grok / xAI API session |

See [[phases/Service-Credentials]] for Bitwarden export template and password rotation links.

---

## After each build session

```bash
bash ~/SovereignAid/aide_installer_pkg/sync-from-repo.sh
```

---

#sovereignaid #install #aide-installer-pkg