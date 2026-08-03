---
tags: [phase6, ops-center, pwa, firefox, grokos, smadp]
date: 2026-07-08
status: complete
owner: Josh
---

# Phase 6 — User Experience Layer

> [!summary] TL;DR
> Notus-inspired Ops Command Center at `/ops/` + Firefox PWA guide + bookmarks.

---

## Ops Command Center

| Item | Value |
|------|-------|
| URL | https://um690.taile52ad9.ts.net/ops/ |
| Theme | Tokyo Night Storm + Tailwind (Notus-style cards) |
| PWA | `manifest.webmanifest` + `sw.js` |

---

## Deploy

```bash
bash ~/SovereignAid/scripts/phase6/deploy-ops-center.sh
bash ~/SovereignAid/scripts/phase6/verify-phase6.sh
```

---

## Firefox PWAs & bookmarks

→ [[user-guide/Firefox-PWA-Setup]]

**Tablet:** `/ops/bookmarks.html` (tap links) — no HTML import  
**Desktop:** `https://um690.taile52ad9.ts.net/ops/smadp-bookmarks.html`

---

## Longhorn UI

https://um690.taile52ad9.ts.net/longhorn/

---

## Files

| Path | Purpose |
|------|---------|
| `k8s/ops-center/static/` | Dashboard HTML + PWA assets |
| `k8s/ops-center/k8s/` | nginx, ingress, Longhorn ingress |
| `scripts/phase6/deploy-ops-center.sh` | Deploy |
| `scripts/phase6/verify-phase6.sh` | Gate check |
| `user-guide/Firefox-PWA-Setup.md` | PWA install steps |
| `user-guide/smadp-bookmarks.html` | Firefox bookmark import |

---

## Deferred

- Vaultwarden in k8s (optional per DESIGN)

---

#sovereignaid #phase6 #ops-center