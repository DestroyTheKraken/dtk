# Valley Tech Support — Website Quickstart

> **Status:** Operational baseline (site 1 of 3). Visual polish and extra pages belong in a **separate refinement project** later.  
> **Live URL:** https://um690.taile52ad9.ts.net/vts/

---

## Find the site

| What | Where |
|------|-------|
| Public URL | https://um690.taile52ad9.ts.net/vts/ |
| Hugo source | `~/SovereignAid/k8s/websites/valley-tech-support/` |
| Content pages | `content/` (home, services, about, contact) |
| Layout / theme | `layouts/`, `assets/css/main.css` (Tokyo Night Storm) |
| k8s manifests | `k8s/` (nginx, ingress `/vts`) |
| Vault doc | [[phases/Phase-4-Valley-Tech-Website]] |

**Verify it's up:**
```bash
bash ~/SovereignAid/scripts/phase4/verify-phase4-valley-tech.sh
```

---

## Edit & redeploy

```bash
# Edit content
nano ~/SovereignAid/k8s/websites/valley-tech-support/content/contact.md
nano ~/SovereignAid/k8s/websites/valley-tech-support/hugo.toml   # phone, email params

# Rebuild + push to cluster
bash ~/SovereignAid/scripts/phase4/deploy-valley-tech.sh
```

`deploy-valley-tech.sh` runs the Hugo build automatically, then updates the k8s ConfigMap and rolls nginx.

---

## Add phone & email

**1. `hugo.toml`** — under `[params]`:
```toml
phone = "+1-XXX-XXX-XXXX"
email = "you@example.com"
```

**2. Contact page** — update `content/contact.md` (or wire params into the layout later in the refinement project).

**3. Bitwarden** — add/update entries in [[phases/Service-Credentials]] (CSV import block).

---

## Build only (no deploy)

```bash
bash ~/SovereignAid/scripts/phase4/build-valley-tech.sh
# Local preview:
cd ~/SovereignAid/k8s/websites/valley-tech-support
~/.local/bin/hugo server --baseURL http://localhost:1313/vts/
```

---

## Future refinement project (deferred)

- Logo, photos, Facebook link
- Pull live content from `~/Documents/valley-tech-support/overview/`
- Deeper Notus components (testimonials, pricing tables, maps)
- Sites 2–3 (additional paths on same MagicDNS host)
- Custom domain + DNS (when ready)

---

## Installer package

After script changes:
```bash
bash ~/SovereignAid/aide_installer_pkg/sync-from-repo.sh
```

#sovereignaid #phase4 #quickstart #valley-tech