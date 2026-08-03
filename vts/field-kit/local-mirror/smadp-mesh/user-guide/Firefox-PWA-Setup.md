---
tags: [guide, pwa, firefox, phase6, grokos, tablet]
date: 2026-07-08
status: active
---

# Firefox PWA Setup — SMADP

> [!summary] TL;DR
> **Laptop:** Firefox PWAs + HTML bookmark import. **Tablet/phone:** Ops Center home screen + tap bookmarks (no file import).

**Prerequisite:** Tailscale connected on the device.

---

## Tablet & phone (recommended — no file import)

The bookmark HTML file lives on um690 — you **cannot** import it from a tablet path like `~/SovereignAid/...`.

**Instead:**

1. Open **https://um690.taile52ad9.ts.net/ops/** in your tablet browser (Tailscale on).
2. **Add to Home screen** / **Install**:
   - **Android Chrome:** ⋮ menu → *Add to Home screen* or *Install app*
   - **Firefox Android:** ⋮ → *Install* (if offered)
   - **iPad Safari:** Share → *Add to Home Screen*
3. Open **https://um690.taile52ad9.ts.net/ops/bookmarks.html** — tap any service (Nextcloud, Longhorn, etc.).
4. **Nextcloud files:** use the **Nextcloud Android app** (not the browser bookmark import).

One home-screen icon for Ops Center gives you every service link.

---

## Director laptop (Firefox desktop)

### 1. Ops Command Center

1. Open **https://um690.taile52ad9.ts.net/ops/**
2. Firefox menu (☰) → **Install** or **Install page as app**
3. Name: `SMADP Ops`

### 2. Nextcloud & Longhorn PWAs

- **Nextcloud:** https://um690.taile52ad9.ts.net/ → Install
- **Longhorn:** https://um690.taile52ad9.ts.net/longhorn/ → Install

### 3. Import bookmarks (desktop only)

**Option A — download from cluster:**
1. Open **https://um690.taile52ad9.ts.net/ops/smadp-bookmarks.html**
2. Save the page, or use Firefox → Manage bookmarks → Import HTML (after downloading the file)

**Option B — from um690:**
```text
~/SovereignAid/user-guide/smadp-bookmarks.html
```

---

## All service URLs

| App | URL |
|-----|-----|
| Ops Center | https://um690.taile52ad9.ts.net/ops/ |
| Tap bookmarks (mobile) | https://um690.taile52ad9.ts.net/ops/bookmarks.html |
| Nextcloud | https://um690.taile52ad9.ts.net/ |
| Valley Tech | https://um690.taile52ad9.ts.net/vts/ |
| Longhorn | https://um690.taile52ad9.ts.net/longhorn/ |
| Traefik | https://um690.taile52ad9.ts.net/dashboard/ |
| Tailscale Admin | https://login.tailscale.com/admin/machines |

---

## Verify (on um690)

```bash
bash ~/SovereignAid/scripts/phase6/verify-phase6.sh
```

---

#sovereignaid #pwa #firefox #tablet #phase6