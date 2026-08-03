# Valley Tech Support — Ops home

**Brand umbrella:** [DestroyTheKraken (DTK)](https://www.destroythekraken.com) — professional site + portfolio.  
**This tree:** service ops, field kit, packages, clients. Also linked as **`~/DTK/vts`**.

| Field | Value |
|-------|--------|
| **Working root (canon)** | `~/valley-tech-support` → `~/Documents/valley-tech-support` |
| **Unified brand tree** | `~/DTK` (site + brand + `vts` + media-hub) |
| **Public site** | https://www.destroythekraken.com |
| **Who works here** | **`kraken` on um690** with **one Grok account** (no separate vtech Grok login for now) |
| **Focus** | Products, services, field work, client delivery — **not** lab reorg |
| **Updated** | 2026-07-21 |

## How to work (simple)

```bash
# Always start here as kraken
cd ~/valley-tech-support
grok          # same paid Grok account as platform work
```

Platform / cluster stays in `~/SovereignAid` when you truly need it. Day-to-day VTS business lives **here**.

## Layout

| Path | Purpose |
|------|---------|
| `overview/` | Business overview, services, agreements, startup checklist |
| `packages/` | Deliverable packages (network install, Nextcloud install, …) |
| `services/` | Service tooling / vendor bits (large ISOs stay out of git) |
| `field-kit/` | Onsite USB kit + assemble scripts |
| `clients/` | Per-client notes / jobs (create subfolders as needed) |
| `web/` | Web/content notes (public site deploy still under SovereignAid `/vts/`) |
| `AGENT.md` / `AGENTS.md` | How Grok behaves on VTS work |

## What is *not* required right now

| Skip | Why |
|------|-----|
| Logging in as Linux user `vtech` | Optional isolation; single Grok account → stay on **kraken** |
| Installing Grok under `/home/vtech` | Same reason |
| Nextcloud users per seat | Optional later |
| More desktop/cluster reorganization | Frozen until VTS products ship |

## Durable backup note

NAS mirror (read-only for kraken today):  
`/mnt/systems_admin/vtech/valley-tech-support/`

Working canon with git: **this tree**. Sync to NAS later when convenient — do not block product work on dual-write.

## Public site

Live: https://um690.taile52ad9.ts.net/vts/  
Deploy tree (platform): `~/SovereignAid/k8s/websites/valley-tech-support/`

## Customer rule

Any customer SSH or remote automation: **site name + ticket/job ID** must be stated first.
