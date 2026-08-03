---
tags: [guide, services, urls, reference, grokos]
date: 2026-07-08
status: active
---

# SMADP Services — URLs & Access

> [!summary] TL;DR
> All ingress on **https://um690.taile52ad9.ts.net** (Tailscale MagicDNS). **Tablet:** [[user-guide/Firefox-PWA-Setup]].

**Host:** `um690.taile52ad9.ts.net` · **Tailnet:** `taile52ad9.ts.net`

---

## Browser services (Tailscale required)

| Service | URL | Notes |
|---------|-----|-------|
| **Ops Command Center** | https://um690.taile52ad9.ts.net/ops/ | Start here — hub for all links |
| **Tap bookmarks (tablet)** | https://um690.taile52ad9.ts.net/ops/bookmarks.html | No HTML import needed |
| **Nextcloud** | https://um690.taile52ad9.ts.net/ | Files, health reports in `reports/` |
| **Valley Tech site** | https://um690.taile52ad9.ts.net/vts/ | Business landing page |
| **Longhorn** | https://um690.taile52ad9.ts.net/longhorn/ | Storage UI |
| **Traefik dashboard** | https://um690.taile52ad9.ts.net/dashboard/ | Ingress |
| **whoami (test)** | http://um690.taile52ad9.ts.net/whoami | Smoke test |

---

## Mobile apps

| App | URL / setting |
|-----|----------------|
| Nextcloud (phone/tablet) | `https://um690.taile52ad9.ts.net` in Nextcloud app |
| Tailscale | Connected before opening any URL above |

---

## External (not self-hosted)

| Service | URL |
|---------|-----|
| Tailscale admin | https://login.tailscale.com/admin/machines |
| xAI / Grok console | https://console.x.ai/ |

---

## SSH / CLI (um690)

| Target | Command |
|--------|---------|
| node1 | `node1` or `ssh node1` |
| node2 | `node2` |
| VyOS router | `router` (um690 only) |
| From workers → um690 | `control` |

---

## Credentials

→ [[phases/Service-Credentials]] · files in `~/.config/sovereign/*.env` on um690

---

## Desktop bookmark import

https://um690.taile52ad9.ts.net/ops/smadp-bookmarks.html (Firefox desktop only)

---

#sovereignaid #services #urls