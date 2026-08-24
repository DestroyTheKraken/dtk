# DestroyTheKraken (DTK)

**Professional brand home** for Joshua Hickman: portfolio, projects, blog, **Valley Tech Support** service offerings, and product installers.

| Field | Value |
|-------|--------|
| **Public site** | Retired — use [DestroyTheKraken/homelab](https://github.com/DestroyTheKraken/homelab) |
| **Working tree** | `~/DTK` (this directory) |
| **NAS archive (full history)** | `/mnt/systems_admin/joshua/HICKMAN_ROOT/Joshua/Projects/DTK` |

## Layout

```
~/DTK/
  brand/                 # Brand SoT: Content_Master, About, methodology, guides
  site/                  # Public website (HTML + img) → Cloudflare tunnel
  products/
    media-hub → ~/HickMedia     # Sovereign Media Hub installer product
  vts → ~/Documents/valley-tech-support   # Valley Tech Support ops
  archive/               # Pointers to NAS archive (no secrets)
  docs/                  # How DTK is organized
```

### Brands under one roof

| Name | Role |
|------|------|
| **DestroyTheKraken (DTK)** | Public brand, website, portfolio, installers |
| **Valley Tech Support** | Local service line (packages, field kit, clients) — `vts/` |
| **Sovereign Media Hub** | Product / installer (HickMedia) — `products/media-hub/` |

## Website

```bash
# Publish site + media-hub installer artifacts to live hostPath
bash ~/DTK/site/publish.sh
```

Live files: `/home/kraken/www/destroythekraken/` (served via cloudflared + k8s nginx).

Stable installer URLs (do not move lightly):

- https://www.destroythekraken.com/hickmedia.sh  
- https://www.destroythekraken.com/hickmedia/latest.tar.gz  

## Brand copy (source of truth)

| File | Use |
|------|-----|
| `brand/Content_Master.md` | Client packages, pricing, hero language |
| `brand/DTK_About.md` | Full biography / “why the name” |
| `brand/BUILD_METHODOLOGY.md` | How you build |
| `site/img/` | Logo, headshot, mountain backgrounds |

## Day-to-day work

| Work | Directory |
|------|-----------|
| Website / brand | `~/DTK` |
| VTS field ops / packages | `~/DTK/vts` or `~/valley-tech-support` |
| Media hub installer code | `~/DTK/products/media-hub` or `~/HickMedia` |

## Secrets

Never copy `.env` or `.nc-hub-secrets` from the NAS archive into this tree. Bitwarden remains SoT for credentials.

## VTS integration (20260803)

Usable Valley Tech Support content lives in **`vts/`** (copied into DTK; not a symlink).
Large leftover media: `archive/vts-leftover-20260803/` + NAS `kraken/backups/vts-archive-20260803`.
