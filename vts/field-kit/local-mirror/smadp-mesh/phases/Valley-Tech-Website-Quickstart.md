---
tags: [phase4, quickstart, hugo, valley-tech, grokos]
date: 2026-07-08
status: active
owner: Josh
---

# Valley Tech Website — Quickstart

> [!summary] TL;DR
> Site is **live and operational**. Refinement is a **future separate project**. This page is your restart guide.

> [!info] Live URL
> https://um690.taile52ad9.ts.net/vts/

---

## Verify operational

```bash
bash ~/SovereignAid/scripts/phase4/verify-phase4-valley-tech.sh
```

---

## Edit & redeploy

```bash
# Edit content
nano ~/SovereignAid/k8s/websites/valley-tech-support/content/contact.md
nano ~/SovereignAid/k8s/websites/valley-tech-support/hugo.toml   # phone, email params

# Rebuild + push
bash ~/SovereignAid/scripts/phase4/deploy-valley-tech.sh
```

Add phone and email in `hugo.toml` under `[params]` and in [[phases/Service-Credentials]] for Bitwarden.

---

## Key paths

| Item | Path |
|------|------|
| Full quickstart (repo) | `k8s/websites/valley-tech-support/QUICKSTART.md` |
| Content | `k8s/websites/valley-tech-support/content/` |
| Theme CSS | `k8s/websites/valley-tech-support/assets/css/main.css` |
| Phase doc | [[phases/Phase-4-Valley-Tech-Website]] |

---

## Deferred (refinement project)

- Visual polish, logo, social links
- Sites 2–3 per [[SovereignAid/user/DESIGN]]
- See `QUICKSTART.md` § Future refinement project

---

#sovereignaid #quickstart #valley-tech