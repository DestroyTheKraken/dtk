---
tags: [phases, index, grokos, smadp]
date: 2026-07-08
status: active
---

# SMADP Implementation Phases

> [!summary] TL;DR
> **Phases 0–6 complete** (8 Jul 2026). Daily use: [[user-guide/README]] · [[phases/Build-Complete]]

---

## Status

| Phase | Doc | Status |
|-------|-----|--------|
| 0 — Foundation | [[phases/Phase-0-Foundation]] | **Complete** |
| 1 — k3s + Longhorn | [[phases/Phase-1-Kubernetes-Base]] | **Complete** |
| 2 — VyOS DHCP | [[phases/Phase-2-VyOS-DHCP]] | **Complete** |
| 2 — Traefik ingress | [[phases/Phase-2-Platform-Traefik]] | **Complete** |
| 2 — Nextcloud + HTTPS | [[phases/Phase-2-Platform-Nextcloud]] | **Complete** |
| 2 — Monitoring | [[phases/Phase-2-Platform-Monitoring]] | **Complete** |
| 2 — Summary | [[phases/Phase-2-Complete]] | **Complete** |
| 3 — Grok Delegation | [[phases/Phase-3-Grok-Delegation]] | **Complete** |
| 4 — Valley Tech site | [[phases/Phase-4-Valley-Tech-Website]] | **Operational** ([[phases/Valley-Tech-Website-Quickstart]]) |
| 5 — Ops & backups | [[phases/Phase-5-Operations]] | **Complete** |
| 6 — UX / Ops Center | [[phases/Phase-6-User-Experience]] | **Complete** |
| — | [[phases/Service-Credentials]] | Active |
| — | [[phases/Build-Complete]] | **Summary** |
| — | [[user-guide/Services]] | URLs |
| — | [[aide_installer_pkg/INSTALL]] | Maintainer |

> [!note] Two "Phase 2" names
> **VyOS DHCP** (network) is done. **DESIGN Phase 2** = Nextcloud/Traefik after k3s.

---

## Verify commands

```bash
bash scripts/phase0/verify-phase0.sh
bash scripts/network/verify-phase2-dhcp.sh
bash scripts/phase1/verify-phase1.sh
bash scripts/phase2/verify-phase2-traefik.sh
bash scripts/phase2/verify-phase2-nextcloud.sh
bash scripts/phase2/verify-phase2-https.sh
bash scripts/phase2/verify-phase2-monitoring.sh
bash scripts/phase3/verify-phase3-delegation.sh
bash scripts/phase4/verify-phase4-valley-tech.sh
bash scripts/phase5/verify-phase5.sh
bash scripts/phase6/verify-phase6.sh
bash aide_installer_pkg/sync-from-repo.sh   # after script changes
```

---

#sovereignaid #phases