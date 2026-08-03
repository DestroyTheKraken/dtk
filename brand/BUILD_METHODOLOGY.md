---
title: How I Build — Destroy the Kraken
date: 2026-06-18
tags:
  - dtk
  - methodology
  - portfolio
aliases:
  - Build Methodology
---

# How I Build

**The skill I showcase:** turning a realistic snapshot of what I know today into **deployed, documented systems** — and teaching others to do the same.

I am not claiming memorized full-stack web development. I am claiming **repeatable systems operations**: Linux fundamentals, cluster deployment, strict runbooks, vendor research, and **Grok Build** (plus other AI tools) to implement faster. I reference AI chat when I need it. I can **repeat this process** for clients.

---

## What I built myself

| Area | Evidence |
|------|----------|
| **Linux fundamentals** | LFCS study program, hands-on cluster ops, SSH, Docker Compose, networking |
| **Four-node production cluster** | um690 control plane + node1 (apps) + node2 (edge) + node3 (data) — live on Tailscale |
| **Deployed websites** | destroythekraken.com (portfolio), client landing page, verified health checks |
| **Runbooks & automation** | `biz-cluster-deploy.sh`, DTK guides, deployment verification |
| **Business launch** | Destroy The Kraken scoped to services I can document and reproduce |

---

## What AI helped design or implement

| Area | AI role |
|------|---------|
| **LFCS / AIOS learning program** | Daily schedule, study guides, automation scripts, tutor integration |
| **Career navigation** | Resume framing, industry research, target employer analysis |
| **DTK business packaging** | Service tiers, pricing structure, client-facing copy drafts |
| **Site & script generation** | Grok Build under strict prompts — layouts, HTML, compose files from my specs |
| **Gap-filling during builds** | Syntax, config templates, troubleshooting ideas — always verified on real hardware |

**Rule:** AI proposes; I research, deploy, test, and document. Nothing goes to production without a passing health check.

---

## Live cluster (what clients can get)

```
Visitor → Cloudflare DNS
       → biz-cloudflared (node2)
       → Traefik :80 (host routing)
       → backends on node1 / um690 / node3 (Tailscale)
```

| Node | Role | Key services |
|------|------|--------------|
| **um690** | Control plane | Grafana, Prometheus, Uptime Kuma, ops portal |
| **node1** | App worker | Nextcloud (ValleyHub), portfolio site, Redis |
| **node2** | Edge gateway | Traefik, Cloudflare tunnel, NATS |
| **node3** | Storage / data | PostgreSQL, MinIO |

Verified: `./automation/biz-cluster-deploy.sh --status` from um690.

---

## What I sell (honest scope)

| Offering | Who it's for | Price |
|----------|--------------|-------|
| **ValleyNet / ValleyHub / ValleyCare** | Rural homes & small offices | See [[Content_Master]] |
| **ValleyForge Production Cluster** | Homelab builders, small biz, career-changers who want this exact architecture | **$2,950** one-time labor |
| **ValleyForge Premium** | Same cluster + AI-augmented systems coaching (my full path) | **$3,850** one-time |

Hardware is client-provided or purchased separately with guided specs. Labor includes documentation, handoff training, and 30-day remote follow-up.

---

## Still learning (stated openly)

- LFCS exam domains — in active study, not claimed complete
- Nextcloud admin depth — learning on production ValleyHub to teach customers
- Hugo/front-end craft — I orchestrate and document; AI assists implementation

---

## Related

- [[DTK_About]] — full biography and career direction
- [[Content_Master]] — client pricing SSOT
- [destroythekraken.com/projects/destroythekraken-website/](https://destroythekraken.com/projects/destroythekraken-website/) — public walkthrough
- [github.com/DestroyTheKraken](https://github.com/DestroyTheKraken) — repos and runbooks